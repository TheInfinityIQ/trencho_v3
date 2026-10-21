extends SceneTree

const Scenario = preload("res://scenario.gd")
const Rear = preload("res://rear.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func step(model, duration: float) -> void:
	var remaining := duration
	while remaining > 0.000001:
		var delta := minf(remaining, 1.0 / 60.0)
		model.advance(delta)
		remaining -= delta

func key(code: Key, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	if pressed and code != KEY_D:
		key(code, false)

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
	root.get_texture().get_image().save_png("res://artifacts/rear_" + name + ".png")

func run() -> void:
	var model = Scenario.new(true)
	var rear = model.rear
	expect(model.supply.depot.inventory[rear.CATEGORY] == 0 and model.supply.captured.inventory[rear.CATEGORY] == 0, "Integrated scenario has no unexplained battlefield resupply")
	expect(not rear.place_workbench(Vector2(150, 190)), "Storage overlap rejected")
	expect(not rear.place_workbench(Vector2(30, 120)), "Map edge placement rejected")
	expect(rear.place_workbench(Vector2(380, 480)), "First arbitrary placement valid")
	var other = Rear.new()
	expect(other.place_workbench(Vector2(540, 580)), "Different arbitrary position valid, no lot requirement")
	expect(not rear.place_workbench(Vector2(600, 550)), "Second simultaneous bench rejected for one-bench proof")
	expect(rear.start_job("Avatar", model.elapsed), "Avatar near bench starts manual batch")
	expect(rear.metal == 3 and rear.ammunition == 0, "Input consumed once before output")
	expect(not rear.start_job("Avatar", model.elapsed) and not rear.assign_worker(), "Exclusive producer prevents duplicate labor")
	var initial_avatar: Vector2 = rear.avatar
	rear.move_avatar(Vector2.RIGHT, 1)
	expect(rear.avatar == initial_avatar, "Manual producer remains occupied")
	step(model, 3.999)
	expect(rear.ammunition == 0, "No production before four-second deadline")
	step(model, 0.001)
	expect(rear.ammunition == 8 and rear.metal == 3 and rear.job.is_empty(), "Manual batch completes exact recipe")
	expect(rear.assign_worker(), "One persistent worker assigned")
	expect(not rear.assign_worker(), "Repeated assignment does not duplicate worker")
	step(model, 2)
	expect(not rear.job.is_empty() and rear.job.producer == "Worker-01", "Worker physically approaches and independently starts job")
	var worker_started: float = rear.job.started_at
	step(model, 2)
	expect(model.elapsed - worker_started >= 2 and model.elapsed - worker_started < 4 and rear.ammunition == 8, "Worker uses authoritative clock and no early output")
	step(model, 2)
	expect(rear.ammunition == 16 and rear.metal == 2 and rear.production_history.size() == 2, "Second batch produces sixteen total with two Metal remaining")
	expect(rear.committed == 0 and model.supply.carried() == 8, "Locked stock leaves demand unsatisfied")
	rear.set_policy("RESERVE", 8)
	expect(rear.eligible() == 8, "Reserve eight exposes exactly eight of sixteen")
	step(model, 1.0 / 60.0)
	expect(rear.ammunition == 16 and rear.committed == 8 and rear.eligible() == 0, "Commitment remains rear-owned subset, no double counting")
	expect(not rear.commit(8, model.elapsed), "Existing commitment cannot satisfy second allocation")
	rear.set_policy("RESERVE", 100)
	expect(rear.committed == 8 and rear.eligible() == 0, "Raised reserve governs new draw without revoking commitment")
	rear.set_policy("LOCKED")
	expect(rear.committed == 8 and rear.eligible() == 0, "Later lock honors commitment and prevents new draw")
	step(model, 2)
	expect(rear.ammunition == 8 and rear.committed == 0 and rear.shipment.cargo == 8 and rear.shipment.owner == "military", "Departure changes custody exactly once")
	expect(rear.shipment.state == "Inter-map transit" and model.supply.carried() == 8, "Military cargo not yet available to soldiers")
	step(model, 2.9)
	expect(model.supply.depot.inventory[rear.CATEGORY] == 0 and rear.shipment.cargo == 8, "No early inter-map arrival")
	step(model, 0.1)
	expect(rear.shipment.cargo == 0 and model.supply.depot.inventory[rear.CATEGORY] == 8 and model.supply.carried() == 8, "Three-second arrival changes receiving custody only")
	var conserved := true
	var in_transit := false
	for tick in range(1800):
		model.advance(1.0 / 60.0)
		conserved = conserved and rear.ammunition + rear.shipment.cargo + model.supply.total_accounted() == 8 + rear.produced
		if model.supply.truck.state == "In transit":
			in_transit = true
			conserved = conserved and model.supply.carried() == 8
	expect(conserved and in_transit, "Complete physical chain conserves production and keeps transit unavailable")
	expect(model.secured and model.supply.carried() == 16, "Rear production ultimately changes soldier readiness and secures objective")
	expect(rear.ammunition == 8 and rear.metal == 2 and model.supply.total_accounted() == 16, "End ledger: Metal2, rear ammo8, soldiers16, no duplicated cargo")
	var available = Rear.new()
	available.ammunition = 16
	available.set_policy("AVAILABLE")
	expect(available.eligible() == 16 and available.commit(8, 0) and available.eligible() == 8, "Available policy exposes uncommitted stock")
	var unavailable = Rear.new()
	unavailable.place_workbench(Vector2(380, 480))
	unavailable.metal = 0
	expect(not unavailable.start_job("Avatar", 0), "No production without inputs")
	unavailable.metal = 4
	unavailable.capability_unlocked = false
	expect(not unavailable.start_job("Avatar", 0), "Capability is separate from input availability")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/rear_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "production": rear.production_history, "boundary_ledger": rear.ledger, "rear_ammo": rear.ammunition, "soldier_ammo": model.supply.carried(), "metal": rear.metal}, "\t"))
	output.close()
	print("REAR CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Main scene script loaded for graphical validation")
	if view.get_script() == null:
		view.free()
		return
	view.model = Scenario.new(true, false)
	root.add_child(view)
	await create_timer(0.2).timeout
	var initial: Vector2 = view.model.rear.avatar
	key(KEY_D)
	await create_timer(0.3).timeout
	key(KEY_D, false)
	expect(view.model.rear.avatar.x > initial.x, "WASD input moves real rear avatar")
	key(KEY_P)
	await process_frame
	click(Vector2(425, 480))
	await process_frame
	expect(view.model.rear.placed, "Real player click freely places workstation")
	key(KEY_E)
	await create_timer(0.5).timeout
	expect(not view.model.rear.job.is_empty(), "Real avatar interaction starts timed manual job")
	await capture("manual_work")
	await create_timer(4.0).timeout
	expect(view.model.rear.ammunition == 8, "Manual runtime output eight rounds")
	await capture("manual_complete_locked")
	key(KEY_F)
	var wait_limit := 0
	while view.model.rear.job.is_empty() and wait_limit < 40:
		await create_timer(0.1).timeout
		wait_limit += 1
	expect(not view.model.rear.job.is_empty(), "Worker starts job after assignment without player labor")
	var worker_start: float = view.model.rear.job.get("started_at", -1)
	key(KEY_TAB)
	await create_timer(2.0).timeout
	expect(view.view_mode == "battlefield" and view.model.elapsed - worker_start >= 2, "View switch keeps worker on same world clock")
	await capture("worker_while_battlefield")
	key(KEY_TAB)
	await capture("worker_progress_return")
	await create_timer(2.1).timeout
	expect(view.model.rear.ammunition == 16 and view.model.rear.metal == 2, "Worker completes second batch while changing views")
	expect(view.model.rear.committed == 0 and view.model.supply.carried() == 8, "Locked runtime stock cannot satisfy battlefield demand")
	await capture("locked_sixteen")
	key(KEY_2)
	await create_timer(0.2).timeout
	expect(view.model.rear.committed == 8 and view.model.rear.ammunition == 16, "Reserve8 real input commits eight as rear subset")
	await capture("committed")
	key(KEY_3)
	await create_timer(2.0).timeout
	expect(view.model.rear.shipment.cargo == 8 and view.model.rear.ammunition == 8, "Later lock does not cancel runtime departure")
	await capture("intermap_transit")
	key(KEY_TAB)
	await create_timer(4.0).timeout
	await capture("battlefield_truck")
	var finish_wait := 0
	while not view.model.secured and finish_wait < 250:
		await create_timer(0.1).timeout
		finish_wait += 1
	expect(view.model.supply.carried() == 16 and view.model.secured, "Real integrated run ends in physical resupply and autonomous objective completion")
	await capture("soldiers_resupplied")
