extends SceneTree
const Space = preload("res://representative_space.gd")
var checks := 0
var failures: Array[String] = []
var evidence: Array = []
const OUT := "res://artifacts/scale032/"

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	expect(Space.point_to_world(Space.MAP_METERS) == Vector2(192000, 256000), "6x8km envelope converts exactly to192000x256000 world units")
	expect(Space.meters_to_world(1.4) == 44.8 and Space.km_to_world(2) == 64000 and Space.world_to_meters(3200) == 100, "Explicit scalar meter/world/km helpers")
	expect(Space.DISTRICT_METERS.size == Vector2(400, 400) and Space.CHUNK_COUNT == Vector2i(24, 32), "400m district and768 logical chunks")
	expect(Space.chunk_for_world(Vector2.ZERO) == Vector2i.ZERO, "Origin belongs to chunk0,0")
	expect(Space.chunk_for_world(Space.point_to_world(Vector2(-0.01, -0.01))) == Vector2i(-1, -1), "Negative position floors rather than truncates or clamps")
	expect(Space.chunk_for_world(Space.point_to_world(Vector2(5888, 7936))) == Vector2i(23, 31), "Exact distant chunk boundary belongs to new chunk")
	expect(Space.chunk_for_world(Space.point_to_world(Vector2(5887.999, 7935.999))) == Vector2i(22, 30), "Position immediately before distant boundary remains in prior chunk")
	expect(Space.chunk_origin_world(Vector2i(23, 31)) == Vector2(188416, 253952), "Far chunk origin converts back exactly")
	expect(Space.chunk_bounds_meters(Vector2i(23, 31)) == Rect2(5888, 7936, 112, 64), "Last chunk clipped to112x64m")
	expect(not Space.chunk_bounds_meters(Vector2i(24, 32)).has_area() and not Space.chunk_bounds_meters(Vector2i(-1, 0)).has_area(), "Outside chunk bounds are empty")
	expect(Space.contains_meters(Vector2(5999.99, 7999.99)) and not Space.contains_meters(Vector2(6000, 8000)), "Map membership uses half-open edges independently of chunk index")
	var state: Dictionary = Space.positions_at(10)
	expect(is_equal_approx(state.walk_m, 14) and state.soldier.distance_to(Space.SITE_METERS + Vector2(14, 4)) < 0.001, "Soldier travels14m after10simulation seconds")
	expect(is_equal_approx(Space.ROUTE_METERS / Space.WALK_METERS_PER_SECOND, 71.4285714286), "Uninterrupted100m walk takes71.43seconds")
	expect(is_equal_approx(Space.positions_at(100.0 / 12.0).truck_m, 100) and is_equal_approx(100.0 / Space.TRUCK_METERS_PER_SECOND, 8.3333333333), "Truck travels100m in8.33seconds at provisional12m/s")
	expect(Space.positions_at(1000).walk_m == 100 and Space.positions_at(-2).walk_m == 0, "Diagnostic route stops at endpoints without extrapolation")
	expect(Space.TRUCK_SIZE_METERS == Vector2(6, 2.4) and Space.ROAD_WIDTH_METERS == 6, "Truck and pavement share explicit physical dimensions")
	var precision := 0.0
	for point in [Vector2.ZERO, Vector2(3000.001, 4000.001), Vector2(5999.99, 7999.99), Vector2(5888.001, 7936.001)]:
		precision = maxf(precision, Space.point_to_meters(Space.point_to_world(point)).distance_to(point))
	expect(precision < 0.002, "Sampled large-coordinate roundtrip error below2mm")
	for name in Space.ZOOMS:
		var visible: Vector2 = Space.visible_meters(Vector2(1280, 800), Space.ZOOMS[name])
		evidence.append({"preset": name, "zoom": Space.ZOOMS[name], "visible_m": [visible.x, visible.y]})
		expect(visible.x > 0 and Space.ruler_meters(visible.x) <= visible.x / 6, "Derived ruler fits " + name)
	evidence.append({"sampled_roundtrip_error_m": precision})
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var file := FileAccess.open(OUT + "checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "evidence": evidence}, "\t"))
	file.close()
	print("SCL032 CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)

func capture(view, name: String) -> int:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OUT + name + ".png")
	var visible: Vector2 = Space.visible_meters(root.size, view.camera.zoom.x)
	var center: Vector2 = Space.point_to_meters(view.camera.position)
	evidence.append({"capture": name, "center_m": [center.x, center.y], "zoom": view.camera.zoom.x, "visible_m": [visible.x, visible.y], "simulation_time": view.elapsed})
	return hash(image.get_data())

func node_count(node: Node) -> int:
	var count := 1
	for child in node.get_children(): count += node_count(child)
	return count

func visual_run() -> void:
	var view = load("res://representative_scale.tscn").instantiate()
	root.add_child(view)
	await process_frame
	view.set_physics_process(false) # Only this diagnostic clock freezes for evidence.
	view.elapsed = 0
	for tick in range(600): view._physics_process(1.0 / 60.0)
	expect(absf(view.elapsed - 10) < 0.00001 and is_equal_approx(Space.positions_at(view.elapsed).walk_m, 14), "Actual scene physics clock advances10s and14m")
	key(KEY_SPACE)
	await process_frame
	var frozen: float = view.elapsed
	view._physics_process(1)
	expect(view.paused and view.elapsed == frozen, "Actual pause input freezes diagnostic time")
	key(KEY_SPACE)
	key(KEY_X)
	await process_frame
	view._physics_process(0.1)
	expect(view.time_scale == 10 and absf(view.elapsed - frozen - 1) < 0.00001, "Accelerated clock adds simulation time without redefining physical speed")
	key(KEY_X)
	key(KEY_R)
	await process_frame
	expect(view.elapsed == 0 and view.time_scale == 1, "Actual reset/rate controls restore time0 and clockx1")
	view.elapsed = 10
	for pair in [[KEY_4, "operation"], [KEY_2, "district"], [KEY_1, "local"], [KEY_3, "tactical"]]:
		key(pair[0])
		await process_frame
		expect(view.preset == pair[1], "Actual camera preset input " + pair[1])
		await capture(view, pair[1])
	for pair in [[KEY_5, "origin"], [KEY_6, "center"], [KEY_7, "far"], [KEY_8, "chunk"]]:
		key(pair[0])
		await process_frame
		if pair[1] == "chunk": view.elapsed = 35
		var first: int = await capture(view, pair[1])
		expect(view.camera.zoom == Vector2.ONE * Space.ZOOMS.local, "Large-coordinate anchor keeps local camera calibration " + pair[1])
		if pair[1] == "far":
			var repeated: int = await capture(view, "far_repeat")
			expect(first == repeated, "Two far-coordinate frozen frames are pixel-identical (limited stationary jitter check)")
			var before: Vector2 = view.camera.position
			var pan := InputEventKey.new()
			pan.keycode = KEY_RIGHT
			pan.pressed = true
			Input.parse_input_event(pan)
			await create_timer(0.12).timeout
			pan = InputEventKey.new()
			pan.keycode = KEY_RIGHT
			Input.parse_input_event(pan)
			await process_frame
			expect(view.camera.position.x > before.x and view.camera.position.y == before.y, "Actual arrow pan updates camera at far coordinates without changing y")
			await capture(view, "far_pan")
		if pair[1] == "chunk":
			var soldier: Vector2 = Space.positions_at(view.elapsed, view.origin_m).soldier
			expect(Space.chunk_for_world(Space.point_to_world(soldier)) == Vector2i(23, 31), "Moving marker crosses actual far xchunk boundary at35s")
	var nodes := node_count(view)
	expect(nodes < 40, "Map extent does not instantiate chunk/cell nodes")
	evidence.append({"diagnostic_scene_node_count": nodes, "logical_chunk_count": 768, "stationary_frame_scope": "Diagnostic simulation clock frozen; no gameplay or moving-camera precision claim"})
	view.queue_free()
	await process_frame
