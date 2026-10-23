extends SceneTree
var checks := 0
var failures: Array[String] = []
var view
var static_draws := 0
var moving_draws := 0
func _initialize() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func key(code: Key, pressed := true) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func wheel(up: bool, point: Vector2, factor := 1.0) -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN; event.position = point; event.global_position = point; event.factor = factor; event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func settle() -> void:
	for i in range(180): view._process(1.0 / 120)
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame; await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/cam037"))
	root.get_texture().get_image().save_png("res://artifacts/cam037/" + label + ".png")
func mask() -> Array:
	var result := []
	for chunk in view.chunk_nodes: result.append(chunk.visible)
	return result
func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("CAMERA CHECKS: native window required; run this suite without --headless")
		quit(); return
	view = load("res://representative_sector.gd").new(); root.add_child(view)
	await process_frame; await process_frame
	view.paused = true; view.set_process(false)
	var generation: int = view.generation_count
	var fingerprint: String = view.layout.fingerprint
	var nodes: int = view.get_child_count()
	var time: float = view.elapsed
	var people := []
	for person in view.people: people.append(person.position)
	var center := Vector2(700, 400) * 32
	view.camera.position = center; view.set_mode("local"); await capture("01_local_current_center")
	view.set_mode("tactical"); await capture("02_tactical_same_center")
	for point in [center, Vector2(2, 2) * 32, Vector2(1535, 1023) * 32]:
		view.camera.position = point
		for code in [KEY_1, KEY_2, KEY_3]:
			key(code); key(code, false)
			expect(view.camera.position.is_equal_approx(point), "Preset retains look point including map edges")
	view.camera.position = center; view.set_mode("local")
	var cursor: Vector2 = view.get_viewport_rect().size * 0.5 + Vector2(180, 120)
	var offset: Vector2 = cursor - view.get_viewport_rect().size * 0.5
	var anchored: Vector2 = center + offset / view.camera.zoom.x
	wheel(true, cursor)
	expect(is_equal_approx(view.camera.zoom.x, 0.3125) and view.zoom_target > 0.3125, "Wheel target changes without immediate teleport")
	view._process(1.0 / 120)
	expect(view.camera.zoom.x > 0.3125 and view.camera.zoom.x < view.zoom_target, "Wheel interpolates smoothly")
	settle()
	expect((view.camera.position + offset / view.camera.zoom.x).distance_to(anchored) < 0.03, "Wheel preserves geographic cursor anchor")
	await capture("03_wheel_cursor_anchor")
	wheel(false, cursor); settle()
	expect(is_equal_approx(view.camera.zoom.x, 0.3125) and view.camera.position.distance_to(center) < 0.03, "Opposite wheel step returns same view")
	wheel(true, cursor, 100); settle()
	expect(is_equal_approx(view.camera.zoom.x, view.MAX_ZOOM), "Wheel maximum bounded")
	wheel(false, cursor, 100); settle()
	expect(is_equal_approx(view.camera.zoom.x, view.sector_zoom()), "Wheel minimum is sector fit")
	for zoom in [0.02, 0.1, 0.3125, 2.0]:
		view.camera.position = center; view.camera.zoom = Vector2.ONE * zoom; view._zoom_active = false
		key(KEY_D); view._process(0.1); key(KEY_D, false)
		expect(absf((view.camera.position - center).length() * zoom - 60) < 0.02, "Pan remains 600 screen pixels per second at every zoom")
	view.camera.position = center
	key(KEY_RIGHT); key(KEY_DOWN); view._process(0.1); key(KEY_RIGHT, false); key(KEY_DOWN, false)
	expect(absf((view.camera.position - center).length() * view.camera.zoom.x - 60) < 0.02, "Arrow diagonal movement is normalized")
	view.camera.position = center; view.set_mode("local"); wheel(true, view.get_viewport_rect().size * 0.5)
	key(KEY_D); view._process(0.1); key(KEY_D, false)
	expect(view.camera.position.x > center.x and view.camera.zoom.x > 0.3125, "Pan and zoom work simultaneously")
	settle()
	var matches := true
	for zoom in [view.sector_zoom(), 0.1, 0.3125, 2.0]:
		for point in [Vector2.ZERO, center, Vector2(256, 512) * 32, view.Layout.SIZE * 32]:
			view.camera.position = point; view.camera.zoom = Vector2.ONE * zoom; view.update_activation()
			var size: Vector2 = view.get_viewport_rect().size / zoom / 32
			var region := Rect2(point / 32 - size * 0.5, size).grow(32)
			for i in range(view.chunk_nodes.size()): matches = matches and view.chunk_nodes[i].visible == region.intersects(view.Layout.bounds(view.layout.chunks[i].key))
	expect(matches, "Cached chunk mask matches original geometric culling at all sampled edges and zooms")
	view.camera.position = center; view.set_mode("local")
	var revision: int = view.activation_revision
	for i in range(100): view.update_activation()
	expect(view.activation_revision == revision, "Unchanged chunk range skips visibility work")
	var original_mask := mask()
	view.camera.position = Vector2.ZERO; view.set_mode("sector"); view.camera.position = center; view.set_mode("local")
	expect(mask() == original_mask, "Returning to same view returns identical visibility")
	view.toggle_debug()
	await capture("04_debug_cached_geometry")
	view.overlay.draw.connect(func(): static_draws += 1)
	view.moving_overlay.draw.connect(func(): moving_draws += 1)
	await process_frame; await process_frame
	var draws_before := static_draws
	view.advance_models(0)
	view.camera.position.x += 10; view.update_activation()
	await process_frame; await process_frame
	expect(static_draws == draws_before and moving_draws > 0, "Static debug geometry stays cached while moving truck marker redraws")
	view.toggle_debug()
	view.camera.position = center; view.set_mode("local")
	await process_frame; await process_frame
	expect(view.camera.get_screen_center_position().distance_to(center) < 0.03, "Rendered camera catches current look point without forced per-frame scroll")
	expect(view.generation_count == generation and view.layout.fingerprint == fingerprint and view.get_child_count() == nodes, "Camera operations preserve generation, composition and node count")
	var unchanged: bool = is_equal_approx(time, view.elapsed)
	for i in range(people.size()): unchanged = unchanged and people[i] == view.people[i].position
	expect(unchanged, "Paused camera interaction does not advance model time or soldiers")
	key(KEY_SPACE); key(KEY_SPACE, false); expect(not view.paused, "Space still toggles model pause"); view.paused = true
	key(KEY_N); key(KEY_N, false)
	expect(view.layout.seed_value == view.Layout.ALTERNATE_SEED and view.camera.position.is_equal_approx(center), "N toggles seed while retaining look point")
	print("CAMERA CHECKS ", checks, " failures: ", failures, " baseline fingerprint: ", fingerprint)
	view.free(); quit(0 if failures.is_empty() else 1)
