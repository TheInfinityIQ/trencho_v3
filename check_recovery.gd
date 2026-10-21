extends SceneTree

const Scenario = preload("res://scenario.gd")
var failures: Array[String] = []
var checks := 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func step(model, duration: float) -> void:
	var remaining := duration
	while remaining > 0.000001:
		var delta := minf(remaining, 1.0 / 60.0)
		model.advance(delta)
		remaining -= delta

func _initialize() -> void:
	run.call_deferred()

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.keycode = code
	Input.parse_input_event(release)

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventMouseButton.new()
	release.position = point
	release.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(release)

func capture(name: String) -> void:
	await create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/recovery_" + name + ".png")

func run() -> void:
	var model = Scenario.new(false)
	var casualty = model.recovery.casualty
	expect(casualty.active and casualty.inventory.BoltActionRifleAmmo == 3 and not casualty.body_present, "Three rounds already carried before casualty; no body yet")
	expect(model.total_ammunition() == 27, "Scenario includes extra three-round casualty fixture")
	step(model, 5)
	expect(not casualty.active and casualty.body_present and casualty.inventory.BoltActionRifleAmmo == 3, "Death retains person and item custody in one physical body")
	expect(model.squads[3].carried_ammunition("BoltActionRifleAmmo") == 0, "Dead member excluded from living readiness")
	expect(model.squads[3].soldiers[2].inventory.BoltActionRifleAmmo == 0, "No automatic nearby looting")
	expect(model.information.query(casualty.position).is_empty(), "Pre-HQ query remains unknown")
	var death_location: Vector2 = casualty.position
	step(model, 9.999)
	expect(casualty.body_present and casualty.position == death_location and casualty.inventory.BoltActionRifleAmmo == 3, "Body/inventory persist through time, movement and report propagation")
	var known: Array[Dictionary] = model.information.query(death_location)
	expect(known.size() == 1 and known[0].observation_time == 5, "HQ knows original event before cleanup")
	var history := JSON.stringify(model.information.world_event)
	var knowledge := JSON.stringify(model.information.knowledge)
	step(model, 0.001)
	expect(model.recovery.dispatched_at == 15 and casualty.body_present, "Dispatch does not remove body")
	expect(model.recovery.position.distance_to(death_location) > 300, "Recovery team must physically travel")
	while model.recovery.started_at < 0 and model.elapsed < 25:
		step(model, 0.05)
	expect(model.recovery.started_at >= 0 and model.recovery.position.distance_to(death_location) <= 24 and casualty.body_present, "Recovery starts only within24-unit interaction range")
	var deadline: float = model.recovery.started_at + 2
	step(model, deadline - model.elapsed - 0.001)
	expect(casualty.body_present and model.recovery.inventory.BoltActionRifleAmmo == 0, "No premature removal or custody transfer before2s")
	step(model, 0.001)
	expect(not casualty.body_present and not casualty.active and casualty.id == "P2-B.4", "Recovery removes body while preserving inactive person identity")
	expect(casualty.inventory.BoltActionRifleAmmo == 0 and model.recovery.inventory.BoltActionRifleAmmo == 3, "Exactly three rounds move from body to team custody")
	expect(model.total_ammunition() == 27 and model.recovery.ledger.size() == 1, "Recovery conserves ammo exactly once")
	expect(JSON.stringify(model.information.world_event) == history and JSON.stringify(model.information.knowledge) == knowledge, "Cleanup alters neither historical event nor military knowledge")
	known = model.information.query(death_location)
	expect(known.size() == 1 and known[0].observation_time == 5 and not JSON.stringify(known).contains("enemy"), "Post-cleanup inquiry preserves original partial incident without hidden source")
	expect(model.information.begin_reconstruction(known), "Historical reconstruction remains available after cleanup")
	model.advance(10)
	expect(not casualty.body_present and model.recovery.inventory.BoltActionRifleAmmo == 3, "Reconstruction does not respawn current body or equipment")
	model.information.end_reconstruction()
	step(model, 3)
	expect(not casualty.body_present and model.recovery.ledger.size() == 1 and model.total_ammunition() == 27, "Exiting reconstruction leaves cleaned world and no duplicate recovery")
	var integrated = Scenario.new(true)
	step(integrated, 5)
	integrated.rear.place_workbench(Vector2(380, 480))
	integrated.rear.start_job("Avatar", integrated.elapsed)
	step(integrated, 4)
	expect(integrated.recovery.casualty.body_present and integrated.rear.produced == 8 and integrated.total_ammunition() == 19, "Unrelated rear production preserves body and accounts separate recipe source")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/recovery_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "body_present": casualty.body_present, "person_id": casualty.id, "team_inventory": model.recovery.inventory, "ledger": model.recovery.ledger, "historical_event": model.information.world_event, "HQ": model.information.knowledge.HQ}, "\t"))
	output.close()
	print("RECOVERY CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Graphical scene script loads")
	if view.get_script() == null:
		view.free()
		return
	view.view_mode = "battlefield"
	root.add_child(view)
	await create_timer(5.2).timeout
	key(KEY_B)
	await process_frame
	click(Vector2(264, 634))
	await capture("body_unknown")
	expect(view.model.recovery.casualty.body_present and view.query_result.is_empty(), "Visible body exists before HQ established history")
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	key(KEY_E)
	await create_timer(2.0).timeout
	await capture("rear_activity_body_persists")
	expect(view.model.recovery.casualty.body_present and not view.model.rear.job.is_empty(), "Body persists while rear map and job active")
	key(KEY_TAB)
	await create_timer(2.5).timeout
	click(Vector2(264, 634))
	await capture("body_known")
	expect(view.model.recovery.casualty.body_present and view.query_result.size() == 1, "Known incident and persistent body coexist")
	while view.model.elapsed < 16.0:
		await create_timer(0.1).timeout
	await capture("team_approaching")
	expect(view.model.recovery.casualty.body_present and view.model.recovery.started_at < 0, "Rendered team travels before recovery action")
	var waited := 0
	while view.model.recovery.casualty.body_present and waited < 100:
		await create_timer(0.1).timeout
		waited += 1
	click(Vector2(264, 634))
	await capture("cleaned_history")
	expect(not view.model.recovery.casualty.body_present and view.query_result.size() == 1, "Cleaned location retains same established history")
	key(KEY_R)
	await capture("historical_reconstruction")
	expect(view.model.information.reconstructing and not view.model.recovery.casualty.body_present, "Historical ghost appears without current corpse")
	key(KEY_ESCAPE)
	await capture("exit_stays_clean")
	expect(not view.model.recovery.casualty.body_present and view.model.recovery.inventory.BoltActionRifleAmmo == 3, "Exiting reconstruction leaves current cleanup intact")
