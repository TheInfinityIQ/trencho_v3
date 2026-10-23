extends SceneTree
var view
var tag := "off"
var scene_source := "res://representative_sector.gd"
func _initialize() -> void: run.call_deferred()
func held(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = pressed
	Input.parse_input_event(event); Input.flush_buffered_events()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="): tag = arg.trim_prefix("--tag=")
		if arg.begins_with("--source="): scene_source = arg.trim_prefix("--source=")
	view = load(scene_source).new(); root.add_child(view)
	await process_frame; await process_frame
	# Isolate this synthetic workload from focus changes / concurrent keyboard use.
	view.set_process_unhandled_input(false); view.set_process_unhandled_key_input(false)
	if "details" in tag: view.toggle_debug()
	if "passive" not in tag: RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	print("CONFIG ", JSON.stringify({"tag":tag,"max_fps":Engine.max_fps,"vsync":DisplayServer.window_get_vsync_mode(),"size":root.size,"hz":DisplayServer.screen_get_refresh_rate()}))
	var results := []
	for cycle in range(3):
		view.camera.position = view.layout.village * 32; view.set_mode("local")
		var event := InputEventMouseButton.new(); event.pressed = true; event.position = Vector2(900,400); event.factor = 30; event.button_index = MOUSE_BUTTON_WHEEL_UP
		view._unhandled_input(event)
		held(KEY_D,true)
		var start := Time.get_ticks_usec(); var previous := start
		var point: Vector2 = view.camera.position
		var deltas := []; var distance := 0.0; var frames := 0; var gpu_max := 0.0
		var center_error := 0.0; var stuck_frames := 0; var actual_distance := 0.0
		var actual_previous: Vector2 = view.camera.get_screen_center_position()
		while Time.get_ticks_usec() - start < 8000000:
			await process_frame
			for code in [KEY_W, KEY_A, KEY_S, KEY_LEFT, KEY_UP, KEY_DOWN]: held(code, false)
			held(KEY_D, true)
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec(); var ms := (now-previous)/1000.0; previous=now
			deltas.append(ms); frames+=1
			distance += view.camera.position.distance_to(point) * view.camera.zoom.x; point=view.camera.position
			var actual: Vector2 = view.camera.get_screen_center_position()
			center_error=maxf(center_error, actual.distance_to(point))
			if actual == actual_previous: stuck_frames+=1
			actual_distance+=actual.distance_to(actual_previous)*view.camera.zoom.x; actual_previous=actual
			if "passive" not in tag: gpu_max=maxf(gpu_max,RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		held(KEY_D,false)
		deltas.sort()
		var report := {"cycle":cycle,"frames":frames,"seconds":(previous-start)/1000000.0,"p50":deltas[int(frames*.5)],"p95":deltas[int(frames*.95)],"max_ms":deltas.back(),"gpu_max":gpu_max,"screen_distance":distance,"actual_screen_distance":actual_distance,"center_error_world_max":center_error,"stuck_frames":stuck_frames,"position":view.camera.position,"generation":view.generation_count}
		results.append(report); print("RESULT ",JSON.stringify(report))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/cam038"))
	var file:=FileAccess.open("res://artifacts/cam038/"+tag+".json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"\t"));file.close()
	view.free();quit()
