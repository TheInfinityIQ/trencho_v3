extends SceneTree

const Ops = preload("res://operations.gd")
const Alerts = preload("res://operational_alerts.gd")
const Information = preload("res://information.gd")
const Person = preload("res://soldier.gd")
const Inspector = preload("res://active_checkpoint.gd")
const Codec = preload("res://checkpoint.gd")
var checks := 0
var failures: Array[String] = []
var samples: Array = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func count_type(alerts, type: String) -> int:
	return alerts.entries.filter(func(entry): return entry.type == type).size()

func exact_world(world) -> String:
	var inspector = Inspector.new()
	var result := JSON.stringify(inspector.exact_pack(inspector.graph(world)), "", true, true)
	inspector.release_mapping()
	return result

func make_order(count := 3, metal := 4):
	var ops = Ops.new()
	ops.world.rear.metal = metal
	ops.world.rear.place_workbench(Vector2(380, 480))
	ops.world.rear.assign_worker(count, ops.world.elapsed)
	return ops

func run() -> void:
	var idle = Ops.new()
	expect(idle.alerts.entries.is_empty() and idle.alerts.newest_unread().is_empty(), "Fresh operations has no fabricated initial alerts")
	var blocked = make_order(3, 1)
	blocked.step(8)
	expect(count_type(blocked.alerts, "PRODUCTION_BLOCKED") == 1 and blocked.alerts.entries.any(func(entry): return entry.type == "PRODUCTION_BLOCKED" and entry.text == "Production blocked — Metal required" and entry.area == "REAR"), "Real queued/progressing order enters actionable input block once")
	var next_id: int = blocked.alerts.next_id
	blocked.step(3)
	expect(blocked.alerts.next_id == next_id, "Unchanged shortage/policy block produces no per-tick or periodic spam")
	var delivery := {"id": "FiniteMetalCrate-01", "owner": "rear", "position": Vector2(175, 230), "inventory": {"Metal": 2}}
	blocked.world.rear.receive_metal(delivery, 2, blocked.world.elapsed)
	blocked.step(10)
	expect(count_type(blocked.alerts, "PRODUCTION_COMPLETED") == 1 and blocked.alerts.entries.any(func(entry): return entry.type == "PRODUCTION_COMPLETED" and entry.text == "Production order complete — 24 rounds produced"), "Same resumed finite order emits one completion using actual24 output")
	var completion_id: int = blocked.alerts.next_id
	blocked.step(10)
	expect(blocked.alerts.next_id == completion_id and blocked.world.rear.produced == 24, "Settled completion and persistent LOCKED do not repeat")
	samples.append_array(blocked.alerts.recent())
	var gated = make_order()
	gated.world.rear.capability_unlocked = false
	gated.step(1)
	expect(count_type(gated.alerts, "PRODUCTION_BLOCKED") == 1, "Missing production capability is a distinct known block")
	gated.world.rear.capability_unlocked = true
	gated.step(1)
	gated.world.rear.capability_unlocked = false
	gated.step(5)
	expect(count_type(gated.alerts, "PRODUCTION_BLOCKED") == 2 and gated.world.rear.production_order.completed == 1, "Genuine resume then reblock emits again for same retained order")
	var policy = make_order(1)
	policy.step(8)
	expect(count_type(policy.alerts, "STOCK_AUTHORIZATION") == 1 and policy.alerts.entries.any(func(entry): return entry.text == "8 rounds ready, but military draw is LOCKED"), "Stock plus real unresolved request alerts truthful LOCKED reason")
	policy.world.rear.set_policy("RESERVE", 8)
	policy.alerts.update(policy.world)
	expect(count_type(policy.alerts, "STOCK_AUTHORIZATION") == 2 and policy.alerts.newest_unread().text.contains("RESERVE FLOOR"), "Reserve floor is distinguished from LOCKED")
	policy.alerts.update(policy.world)
	expect(count_type(policy.alerts, "STOCK_AUTHORIZATION") == 2, "Unchanged reserve floor deduplicates")
	policy.world.rear.set_policy("AVAILABLE")
	policy.alerts.update(policy.world)
	policy.world.rear.set_policy("LOCKED")
	policy.alerts.update(policy.world)
	expect(count_type(policy.alerts, "STOCK_AUTHORIZATION") == 3, "Cleared authorization block can meaningfully recur")
	var untouched := exact_world(policy.world)
	policy.alerts.update(policy.world)
	var newest: Dictionary = policy.alerts.newest_unread()
	var unread: int = policy.alerts.unread_count()
	expect(policy.alerts.acknowledge(newest.id) and policy.alerts.unread_count() == unread - 1 and not policy.alerts.acknowledge("missing"), "Acknowledgement affects only selected presentation item")
	expect(exact_world(policy.world) == untouched, "Projection/alert generation/ack cannot mutate production/policy/custody/commands/knowledge/RNG")
	var detached: Array = policy.alerts.recent()
	detached[0].text = "modified diagnostic copy"
	expect(not policy.alerts.entries.any(func(entry): return entry.text == "modified diagnostic copy"), "Returned recent alert values are detached copies")
	var no_request = make_order(1)
	no_request.step(5)
	expect(no_request.world.rear.ammunition == 8 and count_type(no_request.alerts, "STOCK_AUTHORIZATION") == 0, "Finished stock before a genuine military request does not demand authorization")
	var timed = make_order(1)
	timed.step(8)
	timed.world.rear.set_policy("AVAILABLE")
	timed.step(0.5)
	expect(timed.world.rear.committed == 8 and count_type(timed.alerts, "SHIPMENT_DELIVERED") == 0, "Commit/loading is not delivery")
	timed.step(2)
	expect(timed.world.rear.shipment.cargo == 8 and count_type(timed.alerts, "SHIPMENT_DELIVERED") == 0, "Departure/inter-map transit is not delivery")
	while timed.world.supply.truck.inventory.BoltActionRifleAmmo == 0 and timed.world.elapsed < 25:
		timed.advance(1.0 / 60.0)
	expect(timed.world.supply.truck.inventory.BoltActionRifleAmmo == 8 and count_type(timed.alerts, "SHIPMENT_DELIVERED") == 0, "Truck cargo is not Soldier delivery")
	while timed.situation().need.delivered < 8 and timed.world.elapsed < 50:
		timed.advance(1.0 / 60.0)
	var delivered_alerts: Array = timed.alerts.entries.filter(func(entry): return entry.type == "SHIPMENT_DELIVERED")
	expect(delivered_alerts.size() == 1 and delivered_alerts[0].text == "Ammunition delivered — formation readiness restored" and delivered_alerts[0].time == timed.world.supply.delivered_at and timed.world.supply.carried() >= 16, "Delivery alert requires real complete physical Soldier handoff and truthful readiness")
	var delivered_counter: int = timed.alerts.next_id
	timed.alerts.update(timed.world)
	expect(timed.alerts.next_id == delivered_counter, "Already supplied request cannot alert repeatedly")
	samples.append_array(delivered_alerts)
	var partial = Ops.new()
	partial.step(8)
	partial.world.supply.truck.inventory.BoltActionRifleAmmo = 4
	partial.world.supply.transfer(partial.world.supply.truck.id, partial.world.supply.truck.inventory, partial.world.squads[0].soldiers[0].id, partial.world.squads[0].soldiers[0].inventory, 4, "Physical delivery at staging")
	partial.alerts.update(partial.world)
	expect(partial.situation().need.delivered == 4 and count_type(partial.alerts, "SHIPMENT_DELIVERED") == 0, "Partial delivery cannot falsely claim shipment/readiness complete")
	var isolated = Ops.new()
	isolated.world.information = Information.new()
	isolated.alerts = Alerts.new(isolated.world)
	var info = isolated.world.information
	var observer = isolated.world.squads[0].soldiers[1]
	var enemy = isolated.world.combat.defenders.soldiers[0]
	observer.position = Vector2(500, 200)
	isolated.world.combat.detect(observer, [enemy])
	expect(isolated.world.combat.can_detect(observer, enemy), "Contact fixture uses legitimate local range/LOS detection")
	info.observe_contact(observer.id, enemy.id, enemy.position, 0, 0.1)
	isolated.alerts.update(isolated.world)
	expect(count_type(isolated.alerts, "COMPANY_CONTACT") == 0, "Local observation is not player Company knowledge")
	var casualty = Person.new("Unused", Vector2.ZERO, 0)
	info.advance(1.99, casualty)
	isolated.world.elapsed = 1.99
	isolated.alerts.update(isolated.world)
	expect(info.contact_knowledge.Platoon.size() == 1 and count_type(isolated.alerts, "COMPANY_CONTACT") == 0, "Platoon receipt/pending Company message does not alert early")
	info.advance(2, casualty)
	isolated.world.elapsed = 2
	isolated.alerts.update(isolated.world)
	var first: Dictionary = isolated.alerts.newest_unread()
	expect(first.type == "COMPANY_CONTACT" and first.time == 2 and first.provenance[0].observed_position == Vector2(600, 200) and first.provenance[0].received_at == 2 and first.area == "BATTLEFIELD", "Only legitimate Company receipt creates alert with authorized provenance/world time")
	enemy.position = Vector2(620, 220)
	isolated.world.elapsed = 3
	isolated.alerts.update(isolated.world)
	expect(count_type(isolated.alerts, "COMPANY_CONTACT") == 1 and isolated.situation().contacts[0].report.observed_position == Vector2(600, 200), "Unreported enemy movement cannot alert or correct last-known marker")
	isolated.world.combat.detect(observer, [enemy])
	info.observe_contact(observer.id, enemy.id, enemy.position, 3, 0.1)
	info.advance(4, casualty)
	isolated.world.elapsed = 4
	isolated.alerts.update(isolated.world)
	expect(count_type(isolated.alerts, "COMPANY_CONTACT") == 1, "Genuine newer local/Platoon evidence still waits for Company hop")
	info.advance(5, casualty)
	isolated.world.elapsed = 5
	isolated.alerts.update(isolated.world)
	expect(count_type(isolated.alerts, "COMPANY_CONTACT") == 2 and isolated.alerts.newest_unread().provenance[0].observation_time == 3, "Legitimate newer report can earn a second Company alert after latency")
	enemy.active = false
	enemy.medical_state = "DEAD"
	isolated.world.elapsed = 30
	isolated.alerts.update(isolated.world)
	expect(count_type(isolated.alerts, "COMPANY_CONTACT") == 2 and isolated.situation().contacts[0].freshness == "STALE" and isolated.situation().contacts[0].report.observed_position == Vector2(620, 220), "Unreported death creates no alert and leaves stale knowledge intact")
	samples.append_array(isolated.alerts.recent())
	var paused = make_order(2)
	paused.step(8)
	paused.world.information.begin_reconstruction(paused.world.information.query(Vector2(264, 634)))
	var before_history := JSON.stringify(paused.alerts.recent())
	var history_time: float = paused.world.elapsed
	paused.step(10)
	expect(paused.world.information.reconstructing and paused.world.elapsed == history_time and JSON.stringify(paused.alerts.recent()) == before_history, "Reconstruction keeps alert list/time unchanged and never replays history into live stream")
	paused.world.information.end_reconstruction()
	paused.alerts.update(paused.world)
	expect(JSON.stringify(paused.alerts.recent()) == before_history, "Exiting reconstruction does not duplicate settled alerts")
	for target in ["Enemy-HQ", "Friendly-HQ"]:
		var terminal = Ops.new()
		terminal.world.battle.apply_blast_damage(terminal.world.battle.hqs[target].position, 0, "focused-test")
		terminal.world.battle.apply_blast_damage(terminal.world.battle.hqs[target].position, 0, "focused-test")
		terminal.alerts.update(terminal.world)
		terminal.step(10)
		expect(count_type(terminal.alerts, "BATTLE_RESULT") == 1 and terminal.alerts.newest_unread().text == ("Battle ended — victory" if target == "Enemy-HQ" else "Battle ended — defeat") and terminal.alerts.newest_unread().time == terminal.world.battle.terminal_time, "Victory/defeat terminal result alerts exactly once at authoritative time")
		samples.append_array(terminal.alerts.recent())
		var attached = Alerts.new(terminal.world)
		attached.update(terminal.world)
		expect(attached.entries.is_empty(), "Attaching presentation to settled/loaded terminal world does not replay result")
	var left = make_order(1)
	var right = make_order(1)
	left.step(8)
	right.step(8)
	expect(JSON.stringify(left.alerts.recent(), "", true, true) == JSON.stringify(right.alerts.recent(), "", true, true), "Identical event sequence yields identical alert IDs/values/order")
	var simultaneous = Ops.new()
	simultaneous.step(8)
	simultaneous.world.rear.place_workbench(Vector2(380, 480))
	simultaneous.world.rear.assign_worker(1)
	simultaneous.step(6)
	var last: Array = simultaneous.alerts.recent().slice(-2)
	expect(last.size() == 2 and last[0].type == "PRODUCTION_COMPLETED" and last[1].type == "STOCK_AUTHORIZATION" and last[0].time == last[1].time, "Same-time completion and authorization use stable explicit type ordering")
	for index in range(12):
		policy.world.rear.set_policy("AVAILABLE")
		policy.alerts.update(policy.world)
		policy.world.rear.set_policy("LOCKED")
		policy.alerts.update(policy.world)
	expect(policy.alerts.entries.size() == 8 and policy.alerts.entries[0].id != "OperationalAlert-001" and policy.alerts.entries[-1].id > policy.alerts.entries[0].id, "Recent presentation retains only8 with stable IDs as older items roll off")
	var codec = Codec.new()
	expect(codec.values_only(policy.alerts.recent()) and codec.unpack(JSON.parse_string(JSON.stringify(codec.pack(policy.alerts.recent()), "", true, true))) == policy.alerts.recent(), "Inbox/history/ack metadata are serializable plain values, no live scene refs")
	var tactical := RegEx.new()
	tactical.compile("(?i)\\b(attack|retreat|move squad|fire mortar|target enemy|seize objective)\\b")
	expect(samples.all(func(entry): return tactical.search(entry.text) == null) and ["PRODUCTION_BLOCKED", "PRODUCTION_COMPLETED", "STOCK_AUTHORIZATION", "SHIPMENT_DELIVERED", "COMPANY_CONTACT", "BATTLE_RESULT"].all(func(type): return samples.any(func(entry): return entry.type == type)), "All six categories covered with no tactical language/action surface")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var file := FileAccess.open("res://artifacts/alerts_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "samples": samples}, "\t", true, true))
	print("ALERT CHECKS: ", checks, " failures: ", failures)
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
	root.get_texture().get_image().save_png("res://artifacts/alerts_" + name + ".png")

func visual_run() -> void:
	var view = load("res://operations.tscn").instantiate()
	root.add_child(view)
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	click(Vector2(1030, 680))
	await process_frame
	key(KEY_TAB)
	await create_timer(1).timeout
	await capture("01_worker_order_observe_field")
	expect(view.view_mode == "battlefield" and view.model.rear.production_order.requested == 3 and not view.model.rear.job.is_empty(), "Normal3batch assignment releases attention to field on same clock")
	while count_type(view.operations.alerts, "STOCK_AUTHORIZATION") == 0 and view.model.elapsed < 10:
		await create_timer(0.025).timeout
	await capture("02_rear_attention_alert_on_field")
	expect(view.view_mode == "battlefield" and count_type(view.operations.alerts, "STOCK_AUTHORIZATION") == 1 and view.model.rear.policy == "LOCKED", "Actionable rear stock alert appears on field without forced switch or auto authorization")
	key(KEY_TAB)
	await process_frame
	await capture("03_player_chooses_rear")
	expect(view.view_mode == "rear", "Only player input switches attention back to rear")
	key(KEY_1)
	await create_timer(0.2).timeout
	await capture("04_authorized_normal_loading")
	expect(view.model.rear.policy == "AVAILABLE" and view.model.rear.committed == 8 and view.operations.alerts.entries.filter(func(entry): return entry.type == "STOCK_AUTHORIZATION").size() == 1, "Explicit response clears policy block while normal production/logistics continues without repeated alert")
	key(KEY_H)
	await process_frame
	var list_time: float = view.model.elapsed
	await create_timer(0.4).timeout
	expect(view.alert_panel.visible and view.model.elapsed > list_time + 0.3, "History expands without pausing live world or automatically acknowledging")
	key(KEY_H)
	await process_frame
	while view.operations.situation().need.delivered < 8 and view.model.elapsed < 50:
		await create_timer(0.05).timeout
	await capture("05_actual_soldier_delivery")
	expect(view.view_mode == "rear" and count_type(view.operations.alerts, "SHIPMENT_DELIVERED") == 1 and view.operations.alerts.newest_unread().type == "SHIPMENT_DELIVERED", "Actual delivery earns Battlefield attention suggestion while player stays rear")
	var known_time := 0.0
	for entry in view.operations.alerts.entries:
		if entry.type == "COMPANY_CONTACT":
			for report in entry.provenance:
				known_time = maxf(known_time, report.observation_time)
	var newer := false
	while not newer and view.model.battle_active() and view.model.elapsed < 65:
		for entry in view.operations.alerts.entries:
			if entry.type == "COMPANY_CONTACT":
				newer = newer or entry.provenance.any(func(report): return report.observation_time > known_time)
		await create_timer(0.05).timeout
	await capture("06_new_company_report_while_rear")
	expect(newer and view.view_mode == "rear" and view.operations.alerts.newest_unread().type == "COMPANY_CONTACT", "Legitimate newer Company report asks for attention without moving player from rear")
	key(KEY_TAB)
	await process_frame
	await capture("07_player_chooses_battlefield_information")
	expect(view.view_mode == "battlefield", "Player chooses response to information-available alert")
	key(KEY_B)
	await process_frame
	click(Vector2(264, 634))
	await process_frame
	key(KEY_R)
	await process_frame
	var paused_time: float = view.model.elapsed
	var history_before := JSON.stringify(view.operations.alerts.recent())
	await create_timer(0.3).timeout
	expect(view.model.information.reconstructing and view.model.elapsed == paused_time and JSON.stringify(view.operations.alerts.recent()) == history_before, "Normal historical reconstruction creates no false live alerts")
	key(KEY_ESCAPE)
	await process_frame
	while view.model.battle_active() and view.model.elapsed < 75:
		await create_timer(0.1).timeout
	await capture("08_terminal_result_once")
	expect(not view.model.battle_active() and count_type(view.operations.alerts, "BATTLE_RESULT") == 1 and view.operations.alerts.newest_unread().type == "BATTLE_RESULT", "Normal autonomous terminal battle produces one final result alert")
	var world_before_ack := exact_world(view.model)
	var unread_before: int = view.operations.alerts.unread_count()
	click(Vector2(1000, 775))
	await process_frame
	expect(view.operations.alerts.unread_count() == unread_before - 1 and exact_world(view.model) == world_before_ack, "Actual acknowledgement control affects only presentation, remains usable in frozen aftermath")
	key(KEY_H)
	await process_frame
	await capture("09_recent_eight_acknowledged_result")
	expect(view.alert_panel.visible and view.operations.alerts.entries.size() <= 8 and view.operations.alerts.entries[-1].acknowledged, "Actual history shows bounded recent stream and acknowledgement state")
	var row_unread: int = view.operations.alerts.unread_count()
	click(Vector2(400, 240))
	await process_frame
	expect(view.operations.alerts.unread_count() == row_unread - 1 and exact_world(view.model) == world_before_ack, "Individual history-row click acknowledges only selected alert with no simulation action")
	samples.append_array(view.operations.alerts.recent())
	view.queue_free()
	await process_frame
	var variant = load("res://operations.tscn").instantiate()
	variant.model.rear.metal = 1
	var delivery := {"id": "FiniteMetalCrate-01", "owner": "rear", "position": Vector2(175, 230), "inventory": {"Metal": 2}}
	root.add_child(variant)
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	click(Vector2(1030, 680))
	await process_frame
	key(KEY_TAB)
	while count_type(variant.operations.alerts, "PRODUCTION_BLOCKED") == 0 and variant.model.elapsed < 8:
		await create_timer(0.025).timeout
	await capture("10_worker_block_while_field")
	expect(variant.view_mode == "battlefield" and count_type(variant.operations.alerts, "PRODUCTION_BLOCKED") == 1, "Focused finite-input block alerts player on field without forcing attention")
	key(KEY_K)
	await process_frame
	await create_timer(1).timeout
	expect(count_type(variant.operations.alerts, "PRODUCTION_BLOCKED") == 1, "Acknowledged but unchanged Worker block does not alert again")
	key(KEY_TAB)
	await process_frame
	while variant.model.elapsed < 10:
		await create_timer(0.05).timeout
	variant.model.rear.receive_metal(delivery, 2, variant.model.elapsed)
	await create_timer(0.1).timeout
	await capture("11_legitimate_receipt_resumes_without_block_spam")
	expect(variant.model.rear.production_order.status == "ACTIVE" and count_type(variant.operations.alerts, "PRODUCTION_BLOCKED") == 1, "Existing finite-crate receipt clears shortage and ordinary order resumes, no alert-driven action")
	while variant.model.rear.production_order.status != "COMPLETED" and variant.model.elapsed < 24:
		await create_timer(0.1).timeout
	key(KEY_H)
	await process_frame
	await capture("12_block_resume_completion_history")
	expect(count_type(variant.operations.alerts, "PRODUCTION_COMPLETED") == 1 and variant.model.rear.produced == 24 and variant.model.rear.policy == "LOCKED" and variant.model.rear.committed == 0, "Completion alert does not resolve still-LOCKED authorization or alter production output")
	samples.append_array(variant.operations.alerts.recent())
