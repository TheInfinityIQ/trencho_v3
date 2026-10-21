extends SceneTree

const Operations = preload("res://operations.gd")
const Inspector = preload("res://active_checkpoint.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func state(ops) -> String:
	var inspector = Inspector.new()
	var graph: Dictionary = inspector.graph(ops.world)
	inspector.release_mapping()
	return JSON.stringify(inspector.exact_pack(graph), "", true, true)

func run() -> void:
	var ops = Operations.new()
	var world = ops.world
	expect(world.elapsed == 0 and ops.campaign_capabilities.BoltActionAmmoProduction and world.rear.capability_unlocked and world.rear.metal == 4 and world.rear.ammunition == 0 and world.rear.policy == "LOCKED" and not world.rear.placed, "Playable scenario starts with explicit ammo capability, finite Metal4, no finished ammo/bench and LOCKED policy")
	expect(world.supply.carried() == 9 and world.supply.READY_THRESHOLD == 16 and world.supply.depot.inventory.BoltActionRifleAmmo == 0 and world.supply.truck.inventory.BoltActionRifleAmmo == 0, "Initial shortage is genuine carried inventory against unchanged accepted readiness threshold")
	expect(world.information.query(Vector2(264, 634)).is_empty() and ops.visible_contacts().is_empty(), "Initial player inquiry and delivered contact presentation reveal no hidden enemy truth")
	ops.step(4)
	expect(world.combat.first_contact >= 0 and world.information.contact_knowledge.Company.is_empty() and ops.visible_contacts().is_empty(), "Physical contact is locally observed before Company/player contact record arrives")
	ops.step(116)
	expect(ops.friendly_shots().size() == 1 and world.supply.carried() == 8 and world.supply.phase == "Hold: ammunition shortage" and world.supply.requested_at >= 0, "Ordinary detected contact consumes actual ammo9->8, then actual shortage/request persists")
	expect(world.battle_active() and not world.secured and world.artillery.missions.is_empty() and world.rear.metal == 4 and world.rear.produced == 0 and world.rear.ammunition == 0 and world.rear.committed == 0 and world.rear.shipment.state == "None", "Two-minute inaction creates no production/export/secret readiness or HQ outcome")
	var contacts: Array = ops.visible_contacts()
	var record_before := JSON.stringify(contacts)
	world.combat.defenders.soldiers[0].position = Vector2(601, 200)
	expect(JSON.stringify(ops.visible_contacts()) == record_before and contacts[0].observed_position == Vector2(600, 200), "Displayed enemy contact is delivered historical record, not live enemy position")
	var report: Array = world.information.query(world.information.world_event.location)
	expect(report.size() == 1 and report[0].facts == ["explosion", "friendly casualty"] and not report[0].has("hidden_source_id") and not report[0].has("cause") and report[0].received_at == 8, "Playable inquiry retains54radius,provenance/latency and no hidden source")
	expect(world.information.query(world.information.world_event.location + Vector2(55, 0)).is_empty(), "Inquiry radius remains accepted54units")
	expect(not world.rear.start_job("Avatar", world.elapsed) and world.rear.metal == 4, "Manufacturing still requires physical workbench")
	expect(world.rear.place_workbench(Vector2(380, 480)) and world.rear.start_job("Avatar", world.elapsed) and world.rear.metal == 3 and world.rear.ammunition == 0, "Real nearby player labor charges Metal1 and starts existing4second job")
	ops.step(3.983333333333)
	expect(world.rear.ammunition == 0 and world.supply.carried() == 8, "Neither finished stock nor military readiness exists before work completes")
	ops.step(1.0 / 60.0)
	ops.step(10)
	expect(world.rear.ammunition == 8 and world.rear.produced == 8 and world.rear.metal == 3 and world.rear.policy == "LOCKED" and world.rear.committed == 0 and world.supply.delivered_at < 0 and world.supply.carried() == 8, "Produced8 stays rear-owned while LOCKED; request/readiness remain unsatisfied")
	world.rear.set_policy("RESERVE", 8)
	ops.step(1)
	expect(world.rear.ammunition == 8 and world.rear.committed == 0 and world.rear.eligible() == 0, "Reserve8 also withholds sole8round batch through ordinary policy")
	world.rear.set_policy("AVAILABLE")
	var conserved := true
	var custody := {"commitment": false, "shipment": false, "receiving": false, "truck": false, "delivered": false}
	while world.battle_active() and world.elapsed < 240:
		ops.advance(1.0 / 60.0)
		conserved = conserved and world.total_ammunition() + world.combat.shots.size() == ops.initial_ammo + world.rear.produced
		custody.commitment = custody.commitment or world.rear.committed == 8
		custody.shipment = custody.shipment or (world.rear.shipment.cargo == 8 and world.rear.shipment.owner == "military" and world.rear.ammunition == 0)
		custody.receiving = custody.receiving or world.supply.depot.inventory.BoltActionRifleAmmo == 8
		custody.truck = custody.truck or world.supply.truck.inventory.BoltActionRifleAmmo == 8
		custody.delivered = custody.delivered or world.supply.delivered_at >= 0
		if world.supply.delivered_at < 0:
			conserved = conserved and world.supply.resumed_at < 0 and world.supply.carried() == 8
	expect(conserved and custody.values().all(func(value): return value), "Every physical custody stage observed and ammo conserved every tick; no assumed delivery/readiness")
	expect(world.supply.delivered_at >= 0 and world.supply.resumed_at >= world.supply.delivered_at and world.supply.phase == "Final approach", "Physical soldier delivery satisfies normal readiness and resumes mission autonomously")
	var delivered_ids: Array = []
	for transfer in world.supply.transactions:
		if transfer.reason == "Physical delivery at staging" and transfer.destination != "P1-A.1":
			delivered_ids.append(transfer.destination)
	expect(ops.friendly_shots().any(func(shot): return shot.time > world.supply.delivered_at and shot.shooter in delivered_ids), "Previously empty recipients spend newly delivered ammunition through ordinary combat")
	expect(world.secured and ops.objective_release_at > world.supply.resumed_at and world.artillery.missions.size() == 2 and world.artillery.fired_count == 2 and world.artillery.inventory.MortarShell == 0, "Actual autonomous objective completion precedes two real Company/HQ artillery missions")
	expect(world.battle_state == "ENDED_FRIENDLY_VICTORY" and world.battle.hqs["Enemy-HQ"].state == "DESTROYED" and world.battle.hqs["Enemy-HQ"].integrity == 0 and world.battle.history.filter(func(event): return event.event == "HQ destroyed").size() == 1, "Victory comes only from actual physical primary HQ destruction")
	var frozen := state(ops)
	ops.step(100)
	expect(state(ops) == frozen, "Terminal result freezes all authoritative subsystems and world time")
	var stalled = Operations.new()
	stalled.step(8)
	stalled.world.rear.place_workbench(Vector2(380, 480))
	stalled.world.rear.start_job("Avatar", stalled.world.elapsed)
	stalled.world.rear.set_policy("AVAILABLE")
	while stalled.world.supply.delivered_at < 0 and stalled.world.elapsed < 60:
		stalled.advance(1.0 / 60.0)
	stalled.world.squads[0].soldiers[0].speed = 0
	stalled.step(60)
	expect(stalled.world.supply.delivered_at >= 0 and stalled.world.supply.phase == "Final approach" and not stalled.world.secured and stalled.world.battle_active() and stalled.world.artillery.missions.is_empty(), "Delivery cannot hard-code victory: blocked physical mission prevents objective/fire-task release")
	var view = load("res://operations.tscn").instantiate()
	expect(view.get_script() != null, "Player-facing operations scene loads independently of proof main")
	var player_methods: Array = view.get_script().get_script_method_list().map(func(method): return method.name)
	expect(["order_move", "order_attack", "fire_weapon", "target_artillery", "resume_attack", "damage_hq", "complete_objective"].all(func(method): return method not in player_methods), "Player-facing method surface has logistics/observation controls and no tactical order methods")
	view.free()
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/operations_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "starting_ammo": ops.initial_ammo, "final_ammo": world.total_ammunition(), "shots": world.combat.shots, "custody_observed": custody, "production": world.rear.production_history, "rear_ledger": world.rear.ledger, "supply_ledger": world.supply.transactions, "delivery_time": world.supply.delivered_at, "resume_time": world.supply.resumed_at, "objective_time": ops.objective_release_at, "terminal_time": world.battle.terminal_time, "battle_history": world.battle.history}, "\t", true, true))
	output.close()
	print("OPERATIONS CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

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
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/operations_" + name + ".png")

func visual_run() -> void:
	var view = load("res://operations.tscn").instantiate()
	root.add_child(view)
	while view.model.supply.requested_at < 0 and view.model.elapsed < 10:
		await create_timer(0.1).timeout
	await capture("01_real_battlefield_shortage")
	view.set_physics_process(false)
	var before := state(view.operations)
	click(view.model.squads[0].soldiers[0].position)
	click(Vector2(800, 350))
	key(KEY_E)
	key(KEY_F)
	key(KEY_1)
	await process_frame
	expect(state(view.operations) == before and not view.model.rear.worker.assigned, "Battlefield clicks and rear-only hotkeys issue no tactical orders or remote production/authorization")
	key(KEY_B)
	await process_frame
	click(Vector2(264, 634))
	await process_frame
	view.queue_redraw()
	await capture("02_early_inquiry_no_hq_knowledge")
	expect(view.queried and view.query_result.is_empty(), "Actual arbitrary-location early inquiry cannot expose undelivered report")
	view.set_physics_process(true)
	key(KEY_TAB)
	await process_frame
	await capture("03_protected_rear_stock_zero")
	var origin: Vector2 = view.model.rear.avatar
	key(KEY_D)
	await create_timer(0.3).timeout
	key(KEY_D, false)
	expect(view.model.rear.avatar.x > origin.x, "Actual WASD controls move protected rear avatar")
	key(KEY_P)
	await process_frame
	click(Vector2(425, 480))
	await process_frame
	key(KEY_E)
	await create_timer(1).timeout
	await capture("04_actual_work_metal_consumed")
	expect(view.model.rear.placed and view.model.rear.metal == 3 and view.model.rear.produced == 0 and not view.model.rear.job.is_empty(), "Actual placement/nearby Ework creates genuine timed labor with input, no immediate rounds")
	while view.model.rear.produced < 8 and view.model.elapsed < 20:
		await create_timer(0.1).timeout
	await create_timer(1).timeout
	await capture("05_finished_eight_but_locked")
	expect(view.model.rear.ammunition == 8 and view.model.rear.policy == "LOCKED" and view.model.rear.committed == 0 and view.model.supply.carried() == 8, "Actual finished LOCKED stock leaves military shortage unresolved")
	key(KEY_2)
	await create_timer(0.2).timeout
	expect(view.model.rear.policy == "RESERVE" and view.model.rear.reserve == 8 and view.model.rear.committed == 0, "Actual Reserve8 policy protects sole batch")
	key(KEY_1)
	await create_timer(0.2).timeout
	await capture("06_player_authorization_commits_stock")
	expect(view.model.rear.committed == 8 and view.model.rear.ammunition == 8 and view.model.supply.carried() == 8, "Player AVAILABLE control commits ordinary onhand stock without false Soldier delivery")
	while view.model.rear.shipment.state != "Inter-map transit" and view.model.elapsed < 25:
		await create_timer(0.1).timeout
	await capture("07_shipment_in_physical_transit")
	expect(view.model.rear.shipment.cargo == 8 and view.model.rear.ammunition == 0 and view.model.supply.delivered_at < 0, "Actual departure transfers custody to travelling military shipment")
	key(KEY_TAB)
	while view.model.supply.truck.inventory.BoltActionRifleAmmo == 0 and view.model.elapsed < 30:
		await create_timer(0.1).timeout
	await capture("08_military_truck_carries_eight")
	expect(view.model.supply.truck.inventory.BoltActionRifleAmmo == 8 and view.model.supply.carried() == 8, "Real truck custody remains unavailable to Soldiers before arrival")
	key(KEY_B)
	await process_frame
	click(Vector2(264, 634))
	await process_frame
	key(KEY_R)
	await create_timer(0.1).timeout
	var paused_time: float = view.model.elapsed
	await create_timer(0.1).timeout
	await capture("09_known_report_reconstruction_pauses_world")
	expect(view.model.information.reconstructing and view.model.elapsed == paused_time and view.query_result.size() == 1 and not view.query_result[0].has("hidden_source_id"), "Actual knowledge-bound historical reconstruction pauses single world clock and reveals no hidden source")
	key(KEY_ESCAPE)
	while view.model.supply.resumed_at < 0 and view.model.elapsed < 60:
		await create_timer(0.1).timeout
	await capture("10_delivered_readiness_autonomous_resume")
	expect(view.model.supply.delivered_at >= 0 and view.model.supply.resumed_at >= view.model.supply.delivered_at and view.model.supply.carried() == 16 and view.model.battle_active(), "Actual physical delivery, not a player attack command, restores16round readiness and autonomous continuation")
	while view.operations.friendly_shots().size() < 2 and view.model.elapsed < 70:
		await create_timer(0.1).timeout
	await capture("11_delivered_rounds_used_in_combat")
	expect(view.operations.friendly_shots().size() > 1 and view.model.supply.carried() < 16, "Autonomous combat consumes the delivered physical rounds")
	while view.model.battle_active() and view.model.elapsed < 95:
		await create_timer(0.1).timeout
	await capture("12_physical_hq_victory_frozen")
	expect(view.model.battle_state == "ENDED_FRIENDLY_VICTORY" and view.model.secured and view.model.battle.hqs["Enemy-HQ"].state == "DESTROYED", "Player-facing complete run reaches real HQ terminal victory with persistent aftermath")
	before = state(view.operations)
	key(KEY_TAB)
	await process_frame
	key(KEY_E)
	key(KEY_P)
	key(KEY_1)
	await create_timer(0.2).timeout
	expect(state(view.operations) == before, "Terminal player production/authorization/placement inputs and time cannot mutate frozen world")
