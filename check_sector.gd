extends SceneTree
const Layout = preload("res://sector_layout.gd")
const Person = preload("res://soldier.gd")
const OUT := "res://artifacts/map035/"
var checks := 0
var failures: Array[String] = []
var evidence: Array = []
var native_complete := false

func _initialize() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/a1_rev5/docs/metadata.json"))
	expect(PackedFloat64Array(metadata.roads.straight.connections[0].center_px) == PackedFloat64Array([128, 0]) and PackedFloat64Array(metadata.roads.straight.connections[1].center_px) == PackedFloat64Array([128, 255]) and PackedFloat64Array(metadata.roads.corner_90.centerline_definition.center_px) == PackedFloat64Array([511, 511]) and metadata.roads.corner_90.centerline_definition.radius_px == 311 and PackedFloat64Array(metadata.roads.corner_90.connections[0].center_px) == PackedFloat64Array([200, 511]) and PackedFloat64Array(metadata.roads.corner_90.connections[1].center_px) == PackedFloat64Array([511, 200]) and metadata.roads.straight.paved_width_px == 192, "Generator constants pinned to immutable artist road-port/arc contract")
	expect(PackedFloat64Array(metadata.house.authoritative_footprint_rect_px) == PackedFloat64Array([32, 26, 288, 410]) and PackedFloat64Array(metadata.house.entrance_point_px) == PackedFloat64Array([160, 404]) and PackedFloat64Array(metadata.tree.trunk_collision_center_px) == PackedFloat64Array([96, 96]) and metadata.tree.trunk_collision_radius_px == 12 and PackedFloat64Array(metadata.truck.authoritative_footprint_rect_px) == PackedFloat64Array([90, 32, 167, 224]), "Rendering pivots/footprints pinned to source metadata")
	for seed_value in [Layout.DEFAULT_SEED, Layout.ALTERNATE_SEED]:
		var layout = Layout.new(); layout.generate(seed_value)
		var repeat = Layout.new(); repeat.generate(seed_value)
		expect(layout.fingerprint == repeat.fingerprint, "Same seed/version reproduces complete terrain/object/spawn data")
		expect(layout.chunks.size() == 24 and Layout.SIZE == Vector2(1536, 1024), "6x4 full256m logical chunks")
		expect(layout.houses.size() >= 8 and layout.houses.size() <= 16 and layout.trees.size() >= 100 and layout.trees.size() <= 300 and layout.spawns.size() == 16, "Bounded settlement/vegetation/real-model spawns")
		var indexed := {"roads":0, "houses":0, "trees":0, "spawns":0}
		var ownership := true
		for chunk in layout.chunks:
			ownership = ownership and chunk.variants.size() == 1024 and chunk.rotations.size() == 1024
			for kind in indexed:
				for index in chunk[kind]:
					var item: Dictionary = layout.get(kind)[index]
					ownership = ownership and item.owner == chunk.key and Layout.bounds(chunk.key).has_point(item.position) and Layout.owner(item.position) == chunk.key
					indexed[kind] += 1
		for kind in indexed: ownership = ownership and indexed[kind] == layout.get(kind).size()
		expect(ownership, "Every source object owned/indexed once; compact1024tile arrays perchunk")
		var connects := true
		var truck_clear := true
		var corners := 0
		for i in range(layout.roads.size()):
			var road: Dictionary = layout.roads[i]
			if road.kind == "corner": corners += 1
			if i > 0:
				var previous: Dictionary = layout.roads[i - 1]
				connects = connects and previous.exit.distance_to(road.entry) < 0.0001 and layout.sample_segment(previous, previous.length).direction.distance_to(layout.sample_segment(road, 0).direction) < 0.0001
			for fraction in [0.0, 0.2, 0.5, 0.8, 1.0]:
				var sample: Dictionary = layout.sample_segment(road, road.length * fraction)
				if sample.position.x < 4 or sample.position.x > Layout.SIZE.x - 4: continue
				var forward: Vector2 = sample.direction
				var lateral := Vector2(-forward.y, forward.x)
				for side in [-38.0 / 32, 39.0 / 32]:
					for end in [-1, 1]: truck_clear = truck_clear and layout.road_distance(sample.position + forward * end * 3 + lateral * side) <= 3.01
		expect(connects and corners == 2 and layout.roads.front().entry.x == 0 and layout.roads.back().exit.x >= Layout.SIZE.x, "Two metadata-derived tangent-continuous bends and connected through-road")
		expect(truck_clear, "6x2.4m truck footprint stays inside6m pavement across sampled straights and curves")
		var houses_clear := true
		var doors_face := true
		for i in range(layout.houses.size()):
			var house: Dictionary = layout.houses[i]
			for j in range(i): houses_clear = houses_clear and not house.footprint.intersects(layout.houses[j].footprint)
			for corner in [house.footprint.position, house.footprint.end, house.footprint.position + Vector2(8, 0), house.footprint.position + Vector2(0, 12)]: houses_clear = houses_clear and layout.road_distance(corner) >= 8
			doors_face = doors_face and Layout.turn(Vector2.DOWN, house.turns).dot(Vector2(0, layout.village.y - house.position.y)) > 0
		expect(houses_clear and doors_face, "Authoritative8x12m house footprints nonoverlap, setback and entrances toward road")
		var vegetation_clear := true
		for i in range(layout.trees.size()):
			var tree: Dictionary = layout.trees[i]
			vegetation_clear = vegetation_clear and layout.road_distance(tree.position) >= 7 and tree.trunk_radius == 0.375 and tree.canopy_radius == 3
			for house in layout.houses: vegetation_clear = vegetation_clear and not house.footprint.grow(4).has_point(tree.position)
			for j in range(i): vegetation_clear = vegetation_clear and tree.position.distance_to(layout.trees[j].position) >= 1.25
		expect(vegetation_clear, "Cluster trees respect pavement/buildings and separated trunks while allowing canopy overlap")
		var routes_clear := true
		for spawn in layout.spawns:
			var person = Person.new("check", spawn.position, spawn.speed); person.path.assign(spawn.route); person.advance(1)
			routes_clear = routes_clear and is_equal_approx(person.travelled, 1.4) and layout.road_distance(person.position) > 3
			for step in range(21):
				var p: Vector2 = spawn.position.lerp(spawn.route[0], step / 20.0)
				for house in layout.houses: routes_clear = routes_clear and not house.footprint.grow(0.5).has_point(p)
				for tree in layout.trees: routes_clear = routes_clear and p.distance_to(tree.position) >= 2
		expect(routes_clear, "Existing Soldier.advance walks1.4m/s on generated unobstructed routes")
		evidence.append({"seed":seed_value, "fingerprint":layout.fingerprint, "road_modules":layout.roads.size(), "road_length_m":layout.route_length, "houses":layout.houses.size(), "trees":layout.trees.size(), "grass_modules":24576, "village_m":Layout.canonical(layout.village)})
	expect(evidence[0].fingerprint != evidence[1].fingerprint and evidence[0].village_m != evidence[1].village_m, "Alternate seed changes composition")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
		expect(native_complete, "Native run reaches completion after all captures/input/performance checks")
	var file := FileAccess.open(OUT + "checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks, "failures":failures, "evidence":evidence}, "\t")); file.close()
	print("MAP035 CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true; Input.parse_input_event(event)
	event = InputEventKey.new(); event.keycode = code; event.pressed = false; Input.parse_input_event(event)

func capture(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func visual_run() -> void:
	var view = load("res://representative_sector.tscn").instantiate(); root.add_child(view)
	await process_frame; await process_frame
	view.paused = true
	expect(not view.debug_enabled and not view.overlay.visible and view.people.size() == 16 and view.visuals.size() == 16, "Clean default scene uses16actual model-bound adapters")
	await capture("local_default")
	var fingerprints: String = view.layout.fingerprint
	var generations: int = view.generation_count
	var node_count := count_nodes(view)
	var active_local: int = view.active_chunks
	var before: Vector2 = view.people[0].position
	var distance_before: float = view.truck_distance
	view.advance_models(1)
	expect(is_equal_approx(view.people[0].position.distance_to(before), 1.4) and is_equal_approx(view.truck_distance - distance_before, 12), "Native real models and presentation truck use1.4/12m/s")
	expect(view.visuals[0].position.distance_to(view.people[0].position * 32) < 0.001 and view.visuals[0].clip_name == "standing_walk", "Accepted adapter reads actual moving model in32world/m")
	await capture("local_walking")
	for road in view.layout.roads:
		if road.kind != "corner": continue
		view.elapsed = (road.distance + road.length * 0.5 - view.layout.village_distance + 30) / 12
		view.advance_models(0)
		view.camera.position = view.truck.position; view.clamp_camera(); view.update_activation()
		await capture("local_truck_bend")
		break
	view.set_mode("local")
	var pan_before: Vector2 = view.camera.position
	var pan := InputEventKey.new(); pan.physical_keycode = KEY_RIGHT; pan.keycode = KEY_RIGHT; pan.pressed = true; Input.parse_input_event(pan)
	for frame in range(4): await process_frame
	pan = InputEventKey.new(); pan.physical_keycode = KEY_RIGHT; pan.keycode = KEY_RIGHT; pan.pressed = false; Input.parse_input_event(pan)
	expect(view.camera.position.x > pan_before.x, "Physical right-arrow input pans the real camera")
	key(KEY_2); await process_frame
	expect(view.mode == "tactical" and view.camera.zoom == Vector2.ONE * 0.1, "Tactical keyboard input")
	await capture("tactical_settlement")
	key(KEY_F3); await process_frame
	expect(view.debug_enabled and view.overlay.visible, "Details toggle exposes chunks/footprints/routes")
	await capture("tactical_debug")
	key(KEY_3); await process_frame
	await capture("sector_debug")
	key(KEY_F3); await process_frame
	await capture("sector_clean")
	expect(view.active_chunks == 24 and active_local < 24 and view.generation_count == generations and view.layout.fingerprint == fingerprints and count_nodes(view) == node_count, "Camera activation changes visible groups without regeneration/node churn")
	for point in [Vector2.ZERO, Layout.SIZE * 32, Vector2(49152, 0), Vector2(0, 32768)]:
		view.set_mode("local"); view.camera.position = point; view.clamp_camera(); view.update_activation()
		expect(view.camera.position.is_finite() and view.active_chunks > 0, "Stable camera and activation at sector corner")
	await capture("far_corner_local")
	view.set_mode("local")
	for mode in ["local", "tactical"]:
		view.set_mode(mode); view.paused = false
		for warmup in range(30): await process_frame
		var intervals := []; var updates := []; var previous := Time.get_ticks_usec()
		for sample in range(120):
			await process_frame
			var now := Time.get_ticks_usec(); intervals.append((now - previous) / 1000.0); previous = now; updates.append(view.update_us / 1000.0)
		intervals.sort(); updates.sort()
		evidence.append({"mode":mode, "active_chunks":view.active_chunks, "frame_interval_p50_ms":intervals[60], "frame_interval_p95_ms":intervals[114], "model_adapter_update_p50_ms":updates[60], "model_adapter_update_p95_ms":updates[114]})
	view.paused = true
	evidence.append({"nodes":node_count, "process_nodes":count_processing(view), "batches":view.batch_count, "generation_ms":view.generation_ms, "live_soldiers":16})
	key(KEY_N); await process_frame; view.paused = true
	expect(view.layout.seed_value == Layout.ALTERNATE_SEED and view.layout.fingerprint != fingerprints and view.generation_count == generations + 1, "Seed input explicitly rebuilds deterministic alternate")
	view.set_mode("tactical"); await capture("alternate_tactical")
	view.set_mode("sector"); await capture("alternate_sector")
	view.free(); await process_frame
	native_complete = true

func count_nodes(node: Node) -> int:
	var result := 1
	for child in node.get_children(): result += count_nodes(child)
	return result

func count_processing(node: Node) -> int:
	var result := 1 if node.is_processing() or node.is_physics_processing() else 0
	for child in node.get_children(): result += count_processing(child)
	return result
