extends SceneTree
var view
var report := {"samples":[]}
var visibility_changes := 0
var tag := "before"
const Probe = preload("camera_probe.gd")

func _initialize() -> void: run.call_deferred()

func held(code: Key, down: bool) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down; Input.parse_input_event(event)

func count_visibility() -> void: visibility_changes += 1

func sample_case(label: String, zoom: float, pan: bool, sweep := false, wheel := false) -> void:
	if "_zoom_active" in view: view._zoom_active = false
	view.camera.zoom = Vector2.ONE * zoom
	if "zoom_target" in view: view.zoom_target = zoom
	view.camera.position = Vector2(455 if zoom > 1 else (350 if zoom > 0.2 else 220), 481) * 32 if not sweep else Vector2(768, 512) * 32
	view.clamp_camera(); view.update_activation()
	for warmup in range(60): await process_frame
	visibility_changes = 0
	if pan: held(KEY_D, true)
	var intervals := []
	var cpu := []
	var gpu := []
	var draw_calls := []
	var camera_us := []
	var debug_us := []
	var debug_before: int = view.debug_draw_count
	var last_debug_count: int = view.debug_draw_count
	var activations_before: int = view.activation_calls
	var generations_before: int = view.generation_count
	var nodes_before := count_nodes(view)
	var frames_drawn_start := Engine.get_frames_drawn()
	var previous := Time.get_ticks_usec()
	var center_error := 0.0
	var range_before: int = view.activation_revision if "activation_revision" in view else 0
	var active_min: int = view.active_chunks
	var active_max: int = view.active_chunks
	var batches_max := 0
	for i in range(240):
		if wheel and i % 12 == 0:
			var event := InputEventMouseButton.new(); event.pressed = true; event.position = Vector2(820, 500); event.factor = 2
			event.button_index = MOUSE_BUTTON_WHEEL_UP if i % 120 < 60 else MOUSE_BUTTON_WHEEL_DOWN
			Input.parse_input_event(event); Input.flush_buffered_events()
		if sweep:
			var fraction := float(i) / 239
			var phase := 1.0 - absf(fraction * 2 - 1)
			view.camera.zoom = Vector2.ONE * exp(lerpf(log(0.0202), log(2.0), phase))
			if "zoom_target" in view: view.zoom_target = view.camera.zoom.x
			view.clamp_camera(); view.update_activation()
		await process_frame
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		intervals.append((now - previous) / 1000.0); previous = now
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		camera_us.append(view.get("camera_update_us") if "camera_update_us" in view else 0)
		debug_us.append(view.debug_draw_us if view.debug_enabled and view.debug_draw_count != last_debug_count else 0)
		last_debug_count = view.debug_draw_count
		var actual: Vector2 = view.camera.get_screen_center_position()
		center_error = maxf(center_error, actual.distance_to(view.camera.position))
		active_min = mini(active_min, view.active_chunks); active_max = maxi(active_max, view.active_chunks)
		var batches := 0
		for chunk in view.chunk_nodes:
			if chunk.visible: batches += chunk.get_child_count()
		batches_max = maxi(batches_max, batches)
	if pan: held(KEY_D, false)
	intervals.sort(); cpu.sort(); gpu.sort(); draw_calls.sort(); camera_us.sort(); debug_us.sort()
	var over_8 := 0; var over_16 := 0; var over_33 := 0
	for ms in intervals:
		if ms > 8.34: over_8 += 1
		if ms > 16.67: over_16 += 1
		if ms > 33.34: over_33 += 1
	report.samples.append({"case":label, "frame_count":intervals.size(), "rendered_frames":Engine.get_frames_drawn()-frames_drawn_start, "frame_ms_p50":intervals[120], "frame_ms_p95":intervals[228], "frame_ms_p99":intervals[237], "frame_ms_max":intervals.back(), "frames_over16ms":over_16, "frames_over33ms":over_33, "reported_process_ms_p95":cpu[228], "gpu_render_ms_p95":gpu[228], "draw_calls_max":draw_calls.back(), "camera_update_us_p95":camera_us[228], "static_debug_draw_us_p95":debug_us[228], "static_debug_draws":view.debug_draw_count-debug_before, "activation_calls":view.activation_calls-activations_before, "visibility_changes":visibility_changes, "camera_screen_center_error_world":center_error, "active_chunks":view.active_chunks, "nodes":nodes_before, "node_delta":count_nodes(view)-nodes_before, "generation_delta":view.generation_count-generations_before})
	print(JSON.stringify(report.samples.back()))
	report.samples.back()["active_chunks_min"] = active_min
	report.samples.back()["active_chunks_max"] = active_max
	report.samples.back()["visible_static_batches_max"] = batches_max
	report.samples.back()["activation_revisions"] = view.activation_revision - range_before if "activation_revision" in view else -1

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="): tag = arg.trim_prefix("--tag=")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Engine.max_fps = 120
	view = Probe.new(); root.add_child(view)
	await process_frame; await process_frame
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	for chunk in view.chunk_nodes: chunk.visibility_changed.connect(count_visibility)
	if "debug" in tag: view.toggle_debug()
	report["engine"] = Engine.get_version_info().string
	report["vsync_mode"] = DisplayServer.window_get_vsync_mode()
	report["screen_hz"] = DisplayServer.screen_get_refresh_rate()
	report["tag"] = tag
	report["controlled_max_fps"] = 120
	await sample_case("idle_local", 0.3125, false)
	await sample_case("idle_tactical", 0.1, false)
	await sample_case("pan_local", 0.3125, true)
	await sample_case("pan_tactical", 0.1, true)
	await sample_case("pan_close", 2.0, true)
	await sample_case("zoom_sweep", 0.0202, false, true)
	await sample_case("pan_zoom", 0.0202, true, true)
	if "zoom_target" in view:
		await sample_case("input_wheel", 0.1, false, false, true)
		await sample_case("input_pan_wheel", 0.1, true, false, true)
	var out := "res://artifacts/cam037/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var file := FileAccess.open(out + tag + "_profile.json", FileAccess.WRITE); file.store_string(JSON.stringify(report, "\t")); file.close()
	view.free(); await process_frame
	print("CAMERA PROFILE COMPLETE ", tag)
	quit()

func count_nodes(node: Node) -> int:
	var result := 1
	for child in node.get_children(): result += count_nodes(child)
	return result
