extends SceneTree
const Session = preload("res://game_session.gd")
var host
var checks := 0
var failures: Array[String] = []
var captures := []
var performance := []
func _initialize() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func key(code: Key, down := true) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down
	Input.parse_input_event(event); Input.flush_buffered_events()
func click(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new(); event.position = point; event.global_position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		Input.parse_input_event(event); Input.flush_buffered_events()
func frames(count: int) -> void:
	for i in range(count): await process_frame
func capture(name: String) -> void:
	host.refresh(); await process_frame; await RenderingServer.frame_post_draw
	var path := "res://artifacts/ses041/" + name + ".png"
	root.get_texture().get_image().save_png(path)
	captures.append({"file":name + ".png","view":host.session.view,"time":host.session.elapsed,"rate":host.session.rate,"rear_ammo":host.session.rear.ammunition,"rear_metal":host.session.rear.metal,"job":host.session.rear.job.duplicate(true),"shots":host.session.battlefield.combat.shots.size(),"avatar":host.session.rear.avatar})
func until_world(target: float) -> void:
	while host.session.elapsed < target: await process_frame
func profile(label: String, duration := 2.0) -> void:
	var intervals := []; var last := Time.get_ticks_usec(); var start := last
	while Time.get_ticks_usec() - start < duration * 1000000:
		await process_frame
		var now := Time.get_ticks_usec(); intervals.append((now - last) / 1000.0); last = now
	intervals.sort()
	performance.append({"case":label,"frames":intervals.size(),"p50_ms":intervals[int(intervals.size() * 0.5)],"p95_ms":intervals[int(intervals.size() * 0.95)],"max_ms":intervals.back()})
func run() -> void:
	if DisplayServer.get_name() == "headless": print("Native window required"); quit(1); return
	root.size = Vector2i(1280,800)
	# Load the real configured boot scene, not a hand-built alternative entry.
	host = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate(); root.add_child(host)
	await frames(3)
	# Harness-only60FPS for comparable evidence; product retains CAM037 cap.
	var product_cap := Engine.max_fps; Engine.max_fps = 60
	expect(host.session.view == "REAR" and host.rear_layer.visible and not host.battlefield_view.visible, "Configured boot reaches protected rear")
	await capture("01_boot_rear")
	var avatar: Vector2 = host.session.rear.avatar
	key(KEY_D); await until_world(host.session.elapsed + 0.3); key(KEY_D,false)
	expect(host.session.rear.avatar.distance_to(avatar) > 30, "Real input moves rear avatar")
	await capture("02_avatar_near_bench")
	key(KEY_E); key(KEY_E,false)
	expect(not host.session.rear.job.is_empty() and host.session.rear.metal == 3, "E starts actual timed manual job")
	var finish: float = host.session.rear.job.finishes_at
	await capture("03_rear_work_started")
	var battlefield_id: int = host.session.battlefield.get_instance_id(); var rear_id: int = host.session.rear.get_instance_id()
	var generation: int = host.battlefield_view.generation_count
	key(KEY_TAB); key(KEY_TAB,false); await frames(2)
	expect(host.session.view == "BATTLEFIELD" and host.battlefield_view.visible and not host.rear_layer.visible, "Tab deliberately switches to representative battlefield")
	await capture("04_battlefield_work_continues")
	var p: Vector2 = host.session.battlefield.squads[0].soldiers[0].position
	await until_world(finish + 0.1)
	expect(host.session.rear.ammunition == 8 and host.session.battlefield.squads[0].soldiers[0].position != p, "Rear batch and autonomous formation both progress while battlefield displayed")
	key(KEY_TAB); key(KEY_TAB,false); await frames(2)
	await capture("05_return_rear_work_complete")
	expect(host.session.view == "REAR" and host.session.rear.ammunition == 8, "Returning rear exposes real completed stock")
	key(KEY_F); key(KEY_F,false); await until_world(host.session.elapsed + 0.6)
	key(KEY_SPACE); key(KEY_SPACE,false); await frames(2)
	var time: float = host.session.elapsed; var worker: Vector2 = host.session.rear.worker.position
	var job: Dictionary = host.session.rear.job.duplicate(true)
	await frames(25)
	expect(host.session.rate == 0 and host.session.elapsed == time and host.session.rear.worker.position == worker and host.session.rear.job == job, "Space pauses clock and rear activity")
	await capture("06_paused_rear")
	key(KEY_TAB); key(KEY_TAB,false); await frames(20)
	expect(host.session.rate == 0 and host.session.elapsed == time, "Switching paused preserves time and rate without double-toggle")
	key(KEY_SPACE); key(KEY_SPACE,false); await frames(2)
	expect(host.session.rate == 1, "Space in battlefield resumes once through session owner")
	# Ordinary GUI button hit-testing, no direct rate mutation.
	click(Vector2(1137,27)); await frames(2)
	expect(host.session.rate == 4, "Fast-forward HUD button uses shared4x clock")
	await capture("07_fast_battlefield")
	var before: float = host.session.elapsed
	await create_timer(1.0).timeout
	expect(host.session.elapsed - before > 3.8 and host.session.elapsed - before < 4.3, "One wall second at4x advances one shared clock by about four seconds")
	var world_before: float = host.session.battlefield.elapsed
	key(KEY_TAB); key(KEY_TAB,false); await until_world(host.session.elapsed + 8)
	await until_world(host.session.elapsed + 1)
	expect(host.session.rear.production_order.status == "COMPLETED" and host.session.rear.ammunition == 32, "Finite Worker order completes with real stock under shared fast time")
	await capture("08_worker_finished_during_fast_time")
	expect(host.session.battlefield.elapsed > world_before + 7.9, "Battlefield progresses off-view during rear activity")
	key(KEY_TAB); key(KEY_TAB,false); await frames(2)
	expect(host.session.battlefield.get_instance_id() == battlefield_id and host.session.rear.get_instance_id() == rear_id and host.battlefield_view.generation_count == generation, "All view returns retain original simulation and generation")
	# View-only seed regeneration is unavailable in the session.
	key(KEY_N); key(KEY_N,false); await frames(2)
	expect(host.battlefield_view.generation_count == 1, "Legacy N seed reset cannot reset unified session")
	expect(not host.battlefield_view.debug_enabled and not host.battlefield_view.status.visible and host.battlefield_view.knowledge_label.visible, "Clean battlefield shows delivered knowledge, hides debug truth")
	var enemy_hidden := true
	for i in range(host.battlefield_view.people.size()):
		if host.battlefield_view.people[i].faction == "enemy": enemy_hidden = enemy_hidden and not host.battlefield_view.visuals[i].visible
	expect(enemy_hidden, "Clean session never renders hidden live enemies")
	key(KEY_SPACE); key(KEY_SPACE,false)
	var center: Vector2 = host.battlefield_view.camera.position
	key(KEY_2); key(KEY_2,false); await frames(2)
	expect(host.battlefield_view.camera.position.distance_to(center) < 1, "Zoom preset retains current battlefield center")
	key(KEY_1); key(KEY_1,false); await frames(2)
	var wheel := InputEventMouseButton.new(); wheel.button_index = MOUSE_BUTTON_WHEEL_UP; wheel.position = Vector2(640,400); wheel.pressed = true
	Input.parse_input_event(wheel); Input.flush_buffered_events(); await frames(20)
	expect(host.battlefield_view.camera.zoom.x > 0.3125, "Mouse wheel zoom remains available in unified battlefield")
	var camera_before: Vector2 = host.battlefield_view.camera.position
	key(KEY_D); await frames(12); key(KEY_D,false)
	expect(host.battlefield_view.camera.position.x > camera_before.x and is_equal_approx(host.session.elapsed,host.session.battlefield.elapsed), "Battlefield camera pans while simulation paused")
	key(KEY_SPACE); key(KEY_SPACE,false)
	await until_world(65)
	await capture("09_clean_contact_battlefield")
	expect(host.session.battlefield.combat.shots.size() > 0 and not host.session.battlefield.company_contacts().is_empty(), "Real session reaches current contact and reports")
	click(Vector2(989,27)); await frames(2)
	await profile("battlefield_normal")
	key(KEY_TAB); key(KEY_TAB,false); await profile("rear_normal")
	click(Vector2(1137,27)); await profile("rear_fast4x")
	key(KEY_TAB); key(KEY_TAB,false); await profile("battlefield_fast4x")
	var switches := []
	for i in range(12):
		var start := Time.get_ticks_usec(); host.change_view("REAR" if host.session.view == "BATTLEFIELD" else "BATTLEFIELD"); switches.append((Time.get_ticks_usec()-start)/1000.0)
	performance.append({"case":"switch_handlers","samples_ms":switches,"generation_count":host.battlefield_view.generation_count,"product_fps_cap":product_cap,"harness_fps_cap":60})
	var file := FileAccess.open("res://artifacts/ses041/native.json",FileAccess.WRITE); file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"performance":performance},"  ")); file.close()
	print("SESSION NATIVE CHECKS ",checks," FAILURES ",failures)
	host.queue_free(); await frames(2); quit(0 if failures.is_empty() else 1)
