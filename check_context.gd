extends SceneTree

const Ops = preload("res://priority_operations.gd")
const Codec = preload("res://checkpoint.gd")
var checks := 0
var failures: Array[String] = []
var evidence: Array = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func request(ops, identity: String) -> Dictionary:
	return ops.world.rear.requests.filter(func(item): return item.id == identity)[0]

func packets(ops) -> Array:
	return ops.situation().requests.map(func(item): return item.context)

func signature(ops) -> String:
	var world = ops.world
	var people: Array = world.all_people().map(func(person): return {"id": person.id, "position": person.position, "path": person.path, "waypoint": person.waypoint, "inventory": person.inventory, "active": person.active, "medical": person.medical_state})
	var chains: Array = [world.supply] + world.additional_supplies
	return JSON.stringify({"time": world.elapsed, "people": people, "command": world.trace, "squads": world.squads.map(func(squad): return {"id": squad.id, "task": squad.task, "destination": squad.destination, "decision": squad.decision}),
		"rear": [world.rear.metal, world.rear.ammunition, world.rear.committed, world.rear.shipment, world.rear.job, world.rear.production_order, world.rear.requests, world.rear.request_context],
		"chains": chains.map(func(chain): return {"id": chain.request_id, "carried": chain.carried(), "phase": chain.phase, "requested_at": chain.requested_at, "transactions": chain.transactions, "truck": [chain.truck.position, chain.truck.inventory, chain.truck.route, chain.truck.route_state]}),
		"random": [world.combat.friendly_random.seed, world.combat.friendly_random.state, world.combat.enemy_random.seed, world.combat.enemy_random.state], "shots": world.combat.shots, "missions": world.artillery.missions}, "", true, true)

func initial():
	var ops = Ops.new()
	ops.step(12)
	ops.world.rear.place_workbench(Vector2(380, 480))
	ops.world.rear.assign_worker(2)
	while ops.world.rear.produced < 8 and ops.world.elapsed < 20:
		ops.advance(1.0 / 60.0)
	return ops

func branch(identity: String) -> Dictionary:
	var ops = initial()
	var baseline := signature(ops)
	var a: Dictionary = request(ops, "Request-A")
	var b: Dictionary = request(ops, "Request-B")
	var chosen: Dictionary = a if identity == a.id else b
	var other: Dictionary = b if identity == a.id else a
	var index := 0 if identity == a.id else 1
	var original_task: String = ops.world.squads[index].task
	ops.set_priority(identity)
	ops.world.rear.set_policy("AVAILABLE")
	var conserved := true
	while chosen.delivered < 8 and ops.world.elapsed < 60:
		ops.advance(1.0 / 60.0)
		conserved = conserved and ops.world.total_ammunition() == ops.initial_ammo + ops.world.rear.produced - ops.world.combat.shots.size()
	ops.advance(1.0 / 60.0)
	expect(chosen.delivered == 8 and chosen.ready and other.delivered == 0 and not other.ready, "Selected " + identity + " physically becomes ready first; other is still genuinely short")
	var first_ready: float = ops.world.supply.resumed_at if index == 0 else ops.world.additional_supplies[0].resumed_at
	var start: Vector2 = ops.world.squads[index].center()
	var other_start: Vector2 = ops.world.squads[1 - index].center()
	var remaining_before: float = start.distance_to(ops.world.squads[index].destination)
	ops.step(2)
	var progressed: float = remaining_before - ops.world.squads[index].center().distance_to(ops.world.squads[index].destination)
	expect(progressed > 20 and ops.world.squads[index].task == original_task and ops.world.squads[1 - index].center().distance_to(other_start) < 0.001 and other.delivered == 0, "Ordinary " + identity + " mission progresses earlier while unsupplied formation holds; priority issued no new task")
	while (a.delivered < 8 or b.delivered < 8) and ops.world.elapsed < 85 and ops.world.battle_active():
		ops.advance(1.0 / 60.0)
		conserved = conserved and ops.world.total_ammunition() == ops.initial_ammo + ops.world.rear.produced - ops.world.combat.shots.size()
	ops.advance(1.0 / 60.0)
	expect(a.delivered == 8 and b.delivered == 8 and ops.world.rear.produced == 16 and conserved, "Later second finite batch supplies remaining demand and conserves ammunition in " + identity + " branch")
	return {"choice": identity, "initial": baseline, "first_ready": first_ready, "A_ready": ops.world.supply.resumed_at, "B_ready": ops.world.additional_supplies[0].resumed_at,
		"earlier_progress": progressed, "initial_center": start, "contexts": packets(ops), "requests": ops.world.rear.requests.duplicate(true), "ledger": ops.world.rear.ledger.duplicate(true)}

func run() -> void:
	var ops = initial()
	var context: Array = packets(ops)
	var a: Dictionary = context[0]
	var b: Dictionary = context[1]
	expect(a.request_id == "Request-A" and a.formation_id == "P1-A" and b.request_id == "Request-B" and b.formation_id == "P1-B", "Context attaches to stable logical demand and formation identity")
	expect(a.command_role == "MAIN EFFORT" and b.command_role == "SUPPORT" and a.mission_id == b.mission_id and a.mission_id == "HQ-Objective-A", "Established hierarchy distinguishes MAIN EFFORT/SUPPORT under one authored HQ mission")
	expect(a.task_summary == ops.world.squads[0].task and b.task_summary == ops.world.squads[1].task and ops.world.trace[a.source_sequence].choice == "P1-A: " + a.task_summary and ops.world.trace[b.source_sequence].choice == "P1-B: " + b.task_summary, "Task summaries come from actual friendly Platoon assignment records")
	expect(a.carried == 8 and b.carried == 8 and a.readiness_required == 16 and a.requested == 8 and b.remaining == 8 and a.supply_reason == "Ammunition 8 / readiness requirement 16", "Readiness/deficit context reflects actual logistics, without invented enemy rationale")
	expect(a.request_created_at == ops.world.supply.requested_at and b.request_created_at == ops.world.additional_supplies[0].requested_at and a.request_age == ops.world.elapsed - a.request_created_at and a.supply_record_time == ops.world.elapsed and a.supply_age == 0, "Creation age and effective direct-Supply time come from authoritative world/logistics clocks")
	expect(a.command_record_time == 0 and a.command_provenance.contains("Platoon P1") and a.supply_provenance.contains("physical logistics record"), "Static established assignment and direct friendly logistics have separate explicit provenance/timing")
	var before := signature(ops)
	context[0].task_summary = "changed diagnostic copy"
	for sample in range(20):
		ops.situation()
	expect(signature(ops) == before and packets(ops)[0].task_summary == "Seize Objective A", "Read-only context projection/copy changes cannot mutate actual world or allocation")
	var codec = Codec.new()
	expect(codec.values_only(packets(ops)) and codec.unpack(JSON.parse_string(JSON.stringify(codec.pack(packets(ops)), "", true, true))) == packets(ops), "Request context is serializable plain values with no tactical callable/control object")
	var allowed := ["request_id", "formation_id", "mission_id", "command_role", "task_summary", "command_provenance", "command_record_time", "source_sequence", "request_created_at", "request_age", "requested", "remaining", "delivered", "carried", "readiness_required", "supply_reason", "supply_provenance", "supply_record_time", "supply_age"]
	expect(packets(ops).all(func(packet): return packet.keys().all(func(key): return key in allowed)), "Whitelisted packet has no enemy/threat/recommendation/score/best-choice or tactical action field")
	var hidden_before := JSON.stringify(packets(ops), "", true, true)
	var alert_before := JSON.stringify(ops.alerts.recent(), "", true, true)
	var enemy = ops.world.combat.defenders.soldiers[0]
	enemy.position = Vector2(900, 700)
	enemy.active = false
	enemy.medical_state = "DEAD"
	enemy.inventory.BoltActionRifleAmmo = 99
	expect(JSON.stringify(packets(ops), "", true, true) == hidden_before and JSON.stringify(ops.alerts.recent(), "", true, true) == alert_before, "Unreported enemy location/health/ammunition changes cannot alter request context, alert rationale or recommendation")
	var retained_task: String = packets(ops)[0].task_summary
	ops.world.squads[0].task = "Unestablished local edit"
	ops.step(1)
	expect(packets(ops)[0].task_summary == retained_task and packets(ops)[0].command_record_time == 0 and packets(ops)[0].supply_record_time > a.supply_record_time, "Old established assignment is retained while only actual friendly Supply facts/time refresh")
	ops.world.company_receive("Secure Objective A", Vector2(140, 610))
	ops.advance(1.0 / 60.0)
	expect(packets(ops)[0].command_role == "RESERVE" and packets(ops)[1].command_role == "RESERVE" and packets(ops)[0].task_summary == "Hold reserve" and packets(ops)[0].command_record_time > 0 and ops.world.trace[packets(ops)[0].source_sequence].intent == "Remain staged", "A genuine existing friendly hierarchy reassignment updates context from its actual record")
	var left: Dictionary = branch("Request-A")
	var right: Dictionary = branch("Request-B")
	expect(left.initial == right.initial, "A-first/B-first branches share identical initial actor/path/stock/request/command/vehicle and RNG seed/state snapshot")
	expect(left.A_ready < left.B_ready and right.B_ready < right.A_ready and left.A_ready < right.A_ready and right.B_ready < left.B_ready, "Either choice changes actual timing/order of friendly readiness and autonomous action without forcing different final outcomes")
	var guidance = initial()
	var wording := JSON.stringify(guidance.alerts.recent())
	expect(guidance.alerts.primary().type == "STOCK_AUTHORIZATION" and guidance.alerts.primary().text.contains("choose logistics priority") and guidance.world.rear.requests.all(func(item): return item.priority == "NORMAL") and not wording.contains("Choose MAIN EFFORT") and not wording.contains("best choice"), "Actual competing-request alert surfaces choice without MAIN EFFORT recommendation or automatic selection")
	evidence.append(left)
	evidence.append(right)
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/context_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "branches": evidence}, "\t", true, true))
	print("CONTEXT CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
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
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/context_" + name + ".png")

func visual_run() -> void:
	for identity in ["Request-A", "Request-B"]:
		var branch_name: String = "A" if identity == "Request-A" else "B"
		var view = load("res://priority_operations.tscn").instantiate()
		root.add_child(view)
		while not view.model.rear.requests.all(func(item): return item.requested == 8) and view.model.elapsed < 12:
			await create_timer(0.1).timeout
		key(KEY_TAB)
		await process_frame
		key(KEY_P)
		await process_frame
		click(Vector2(380, 480))
		await process_frame
		click(Vector2(1226, 673))
		await process_frame
		key(KEY_F)
		while view.model.rear.produced < 8 and view.model.elapsed < 20:
			await create_timer(0.05).timeout
		key(KEY_C)
		await process_frame
		await capture(branch_name + "_01_two_requests_command_logistics_provenance")
		expect(view.context_panel.visible and view.context_headers[0].text.contains("MAIN EFFORT") and view.context_headers[1].text.contains("SUPPORT") and view.context_bodies[0].text.contains("Source:") and view.context_bodies[1].text.contains("Assignment established T0.0"), "Normal comparison control shows both established tasks/roles and separately timed direct Supply provenance")
		expect(view.context_panel.find_children("*", "Button", true, false).is_empty() and view.view_mode == "rear", "Comparison contains facts only and does not switch map or add tactical controls")
		click(Vector2(150, 305 if identity == "Request-A" else 345))
		await process_frame
		await capture(branch_name + "_02_player_selects_either_logistics_priority")
		var selected: Dictionary = request(view.operations, identity)
		var other: Dictionary = request(view.operations, "Request-B" if identity == "Request-A" else "Request-A")
		expect(selected.priority == "PRIORITY" and other.priority == "NORMAL" and view.model.rear.policy == "LOCKED" and view.model.rear.committed == 0, "Either MAIN EFFORT or SUPPORT remains selectable; context neither chooses nor authorizes")
		key(KEY_1)
		key(KEY_C)
		key(KEY_TAB)
		await process_frame
		while selected.delivered < 8 and view.model.elapsed < 55:
			await create_timer(0.1).timeout
		var index := 0 if identity == "Request-A" else 1
		var before: Vector2 = view.model.squads[index].center()
		await create_timer(2).timeout
		await capture(branch_name + "_03_physical_readiness_autonomous_progress_first")
		expect(selected.delivered == 8 and selected.ready and other.delivered == 0 and view.model.squads[index].center().distance_to(before) > 20, "Actual " + identity + " delivery releases its existing autonomous task earlier while other formation stays short")
		key(KEY_C)
		await process_frame
		await capture(branch_name + "_04_direct_supply_context_reflects_actual_consequence")
		expect(view.view_mode == "battlefield" and packets(view.operations)[index].carried == 16 and packets(view.operations)[1 - index].carried == 8 and packets(view.operations)[index].command_record_time == 0, "Comparison on chosen field view updates physical supply facts without re-stamping established command or forcing navigation")
		if identity == "Request-B":
			view.set_physics_process(false)
			var before_hidden := JSON.stringify(packets(view.operations), "", true, true)
			var enemy = view.model.combat.defenders.soldiers[0]
			enemy.position = Vector2(900, 700)
			enemy.active = false
			enemy.medical_state = "DEAD"
			enemy.inventory.BoltActionRifleAmmo = 99
			view.refresh()
			await capture("B_05_unreported_enemy_change_no_context_leak")
			expect(JSON.stringify(packets(view.operations), "", true, true) == before_hidden and view.context_headers[0].text.contains("MAIN EFFORT") and view.context_headers[1].text.contains("SUPPORT"), "Isolated unreported enemy change leaves actual comparison/roles/priority facts identical, no threat/recommendation leak")
		evidence.append({"renderer_choice": identity, "requests": view.model.rear.requests.duplicate(true), "contexts": packets(view.operations), "time": view.model.elapsed})
		view.queue_free()
		await process_frame
