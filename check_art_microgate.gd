extends SceneTree
const Space = preload("res://representative_space.gd")
const OUT := "res://artifacts/vis031/"
var checks := 0
var failures: Array[String] = []
var evidence: Array = []

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func key(code: Key) -> void:
	var input := InputEventKey.new()
	input.keycode = code
	input.pressed = true
	Input.parse_input_event(input)
	input = InputEventKey.new()
	input.keycode = code
	Input.parse_input_event(input)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var view = load("res://art_microgate.tscn").instantiate()
	root.add_child(view)
	await process_frame
	view.set_physics_process(false)
	var hashes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(view.ROOT + "docs/file_hashes.json")).files
	var source_unchanged := true
	for file in hashes:
		source_unchanged = source_unchanged and FileAccess.get_sha256(view.ROOT + file) == hashes[file].sha256
	expect(source_unchanged, "Every artist-listed file hash matches unchanged delivered bytes")
	var grass_hashes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(view.GRASS_ROOT + "docs/file_hashes.json"))
	var grass_unchanged := true
	for file in grass_hashes:
		grass_unchanged = grass_unchanged and FileAccess.get_sha256(view.GRASS_ROOT + file) == grass_hashes[file].sha256
	for file in view.metadata.terrain.files:
		grass_unchanged = grass_unchanged and view.textures[file].resource_path == view.GRASS_ROOT + file
	expect(grass_unchanged, "Rev6 patch files match delivered hashes and only grass texture paths override Rev5")
	expect(view.textures.size() == 18 and is_equal_approx(view.source_ratio, 1), "All18runtime textures loaded with unified32px/m32world/m ratio")
	view.apply_sample(1)
	var start: Vector2 = view.rifle.position
	view.apply_sample(2)
	expect(absf(Space.world_to_meters(start.distance_to(view.rifle.position)) - 1.4) < 0.001, "Real actor transform moves1.4m over one walking second")
	var frames := {}
	for tick in range(80):
		view.apply_sample(tick * view.WALK_LOOP_SECONDS / 80.0)
		frames[view.frame_index] = true
	expect(frames.size() == 8 and not frames.has(0) and is_equal_approx(view.WALK_LOOP_SECONDS, 0.85), "All8actual walk PNGs play within0.85second loop")
	view.apply_sample(8.0 / 1.4 + 0.25)
	expect(view.frame_index == 0 and not view.actor_moving, "Documented idle frame displays during stopped turn")
	var ring_ok := true
	var headings_ok := true
	var muzzle_ok := true
	for i in range(4):
		view.pose_case = i
		view.apply_sample(0)
		var ring: Vector2 = view.hull.to_global(view.source_vec(view.metadata.tank.turret_ring_center_on_hull_px) - view.source_vec(view.metadata.tank.hull_pivot_px))
		ring_ok = ring_ok and view.turret.global_position.distance_to(ring) < 0.001
		var expected := [0.0, 45.0, 0.0, 225.0]
		headings_ok = headings_ok and absf(wrapf(view.turret.global_rotation - deg_to_rad(expected[i]), -PI, PI)) < 0.00001
		muzzle_ok = muzzle_ok and absf(view.tank_muzzle_world().distance_to(ring) - 187 * view.source_ratio) < 0.02
	expect(ring_ok and headings_ok and muzzle_ok, "Four independent hull/turret headings preserve ring and muzzle attachment")
	view.pose_case = -1
	var radius: float = view.metadata.roads.corner_90.centerline_definition.radius_px
	var inner := radius - 96
	var outer := radius + 96
	var center: Vector2 = view.corner_origin + view.source_vec(view.metadata.roads.corner_90.centerline_definition.center_px) * view.source_ratio
	var corridor_ok := true
	for i in range(21):
		var distance := 257.0 + radius * PI / 2 * (i + 0.001) / 21.002
		view.apply_sample(distance / 32.0 / view.TRUCK_DEMO_METERS_PER_SECOND)
		for source_point in [Vector2(90, 32), Vector2(167, 32), Vector2(167, 224), Vector2(90, 224)]:
			var point: Vector2 = view.truck.to_global(source_point - Vector2(128, 128))
			var radial: float = point.distance_to(center) / view.source_ratio
			corridor_ok = corridor_ok and radial >= inner and radial <= outer
	expect(corridor_ok, "Correctly scaled truck footprint stays within authored6m curve corridor at21poses")
	expect(view.house_pivot_source == Vector2(160, 218) and view.tree.position == Space.point_to_world(Vector2(86, 36)), "House footprint center and separate tree trunk use documented transforms")
	var imported := true
	for file in view.textures:
		var config := ConfigFile.new()
		var source_root: String = view.GRASS_ROOT if file in view.metadata.terrain.files else view.ROOT
		imported = imported and config.load(source_root + file + ".import") == OK and config.get_value("params", "mipmaps/generate", false) and config.get_value("params", "compress/mode", -1) == 0
	expect(imported, "All18local texture sidecars use mipmaps and lossless compression without global changes")
	if "--visual" in OS.get_cmdline_user_args(): await visual(view)
	var file := FileAccess.open(OUT + "checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "evidence": evidence}, "\t"))
	file.close()
	print("VIS031 CHECKS: ", checks, " failures: ", failures)
	view.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture(view, name: String) -> void:
	view.queue_redraw()
	view.world_overlay.queue_redraw()
	view.hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	evidence.append({"capture": name, "zoom": view.camera.zoom.x, "filter": view.FILTER_NAMES[view.filter_index], "elapsed": view.elapsed, "overlays": view.diagnostic_overlays, "frame": view.frame_index})

func visual(view) -> void:
	view.apply_sample(4)
	key(KEY_D)
	key(KEY_W)
	key(KEY_4)
	await process_frame
	expect(not view.diagnostic_overlays and view.focus == "context" and view.camera.zoom.x == Space.ZOOMS.local, "Actual context/zoom/overlay controls select representative view")
	await capture(view, "context_gameplay")
	key(KEY_G)
	await process_frame
	for pair in [[KEY_1, "grass_close"], [KEY_2, "grass_half"], [KEY_3, "grass_quarter"], [KEY_4, "grass_gameplay"]]:
		key(pair[0])
		await process_frame
		view.camera.position = Space.point_to_world(Vector2(20, 15))
		view.camera.force_update_scroll()
		await capture(view, pair[1])
	for i in range(3):
		key(KEY_F)
		await process_frame
		await capture(view, "grass_filter_" + view.FILTER_NAMES[view.filter_index].replace("+", "_"))
	expect(view.filter_index == 2, "Actual filter control cycles nearest/linear/mipmaps and returns to local default")
	var pan := InputEventKey.new()
	pan.keycode = KEY_RIGHT
	pan.pressed = true
	Input.parse_input_event(pan)
	for i in range(8):
		await create_timer(0.04).timeout
		await capture(view, "grass_pan_%02d" % i)
	pan = InputEventKey.new()
	pan.keycode = KEY_RIGHT
	Input.parse_input_event(pan)
	await process_frame
	key(KEY_R)
	key(KEY_1)
	await process_frame
	await capture(view, "road_close")
	key(KEY_4)
	await process_frame
	await capture(view, "road_gameplay")
	key(KEY_H)
	key(KEY_1)
	await process_frame
	view.apply_sample(1)
	await capture(view, "house_close")
	key(KEY_4)
	key(KEY_W)
	await process_frame
	await capture(view, "house_context")
	key(KEY_1)
	key(KEY_D)
	await process_frame
	view.camera.position = Space.point_to_world(Vector2(82, 48))
	view.camera.force_update_scroll()
	for i in range(4):
		key(KEY_K)
		await process_frame
		view.apply_sample(0)
		await capture(view, "tank_pose_%d" % i)
	view.camera.position = Space.point_to_world(Vector2(60, 49))
	view.camera.force_update_scroll()
	for pair in [[1.0, "rifle_walk"], [6.1, "rifle_idle_turn"]]:
		view.apply_sample(pair[0])
		await capture(view, pair[1])
	view.camera.position = Space.point_to_world(Vector2(86, 33))
	view.camera.force_update_scroll()
	await capture(view, "tree_trunk_canopy")
	var image: Image = view.textures["terrain/terrain_grass_01.png"].get_image()
	expect(image != null and image.has_mipmaps(), "Real imported GPU texture retains generated mip levels")
