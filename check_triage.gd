extends SceneTree

const Ops = preload("res://operations.gd")
const Alerts = preload("res://operational_alerts.gd")
const Info = preload("res://information.gd")
const Person = preload("res://soldier.gd")
const Inspector = preload("res://active_checkpoint.gd")
var checks := 0
var failures: Array[String] = []
var evidence: Array = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func exact_world(world) -> String:
	var inspector = Inspector.new()
	var result := JSON.stringify(inspector.exact_pack(inspector.graph(world)), "", true, true)
	inspector.release_mapping()
	return result

func blocked_fixture():
	var ops = Ops.new()
	ops.world.information = Info.new()
	ops.alerts = Alerts.new(ops.world)
	ops.world.rear.metal = 0
	ops.world.rear.place_workbench(Vector2(380, 480))
	ops.world.rear.assign_worker(3)
	ops.advance(1.0 / 60.0)
	return ops

func observe(ops, enemy) -> void:
	var observer = ops.world.squads[0].soldiers[1]
	observer.position = Vector2(500, 200)
	ops.world.combat.detect(observer, [enemy])
	expect(ops.world.combat.can_detect(observer, enemy), "Stress Company report has actual eligible local range/LOS observer")
	var observed: float = ops.world.elapsed + 3
	ops.world.information.observe_contact(observer.id, enemy.id, enemy.position, observed, 0.1)
	var before := JSON.stringify(ops.alerts.recent())
	var casualty = Person.new("Unused", Vector2.ZERO, 0)
	ops.world.information.advance(observed + 1, casualty)
	ops.world.elapsed = observed + 1
	ops.alerts.update(ops.world)
	expect(JSON.stringify(ops.alerts.recent()) == before, "Triage/coalescing cannot see local/Platoon update before Company delivery")
	ops.world.information.advance(observed + 2, casualty)
	ops.world.elapsed = observed + 2
	ops.alerts.update(ops.world)

func run() -> void:
	var ops = blocked_fixture()
	var alerts = ops.alerts
	var action_id: String = alerts.primary().id
	expect(alerts.primary()["class"] == "ACTION_REQUIRED" and alerts.primary().state == "OPEN", "Worker blockage is an open action-required alert")
	var expected := {"PRODUCTION_BLOCKED": "ACTION_REQUIRED", "STOCK_AUTHORIZATION": "ACTION_REQUIRED", "PRODUCTION_COMPLETED": "INFORMATION", "SHIPMENT_DELIVERED": "INFORMATION", "COMPANY_CONTACT": "INFORMATION", "BATTLE_RESULT": "RESULT"}
	expect(Alerts.CLASSES == expected, "All six existing categories map to required presentation classes")
	var enemy = ops.world.combat.defenders.soldiers[0]
	for index in range(12):
		observe(ops, enemy)
		var info: Dictionary = alerts.newest_unread()
		expect(info.type == "COMPANY_CONTACT" and alerts.primary().id == action_id, "Newer Company information cannot displace older actionable primary")
		alerts.acknowledge(info.id)
	expect(alerts.entries.size() == 9 and alerts.history_count() == 8 and alerts.entries.any(func(entry): return entry.id == action_id and not entry.acknowledged), "More than8 genuine information events cannot evict protected unread/open action")
	expect(alerts.counts() == {"action_open": 1, "action_unread": 1, "information_unread": 0, "result_unread": 0}, "Open/unread action, unread information and unread result counts are distinct")
	var old_unread = blocked_fixture()
	for index in range(12):
		old_unread.alerts.emit_alert("PRODUCTION_COMPLETED", index + 1, "Capacity sample", "focused-presentation", "NONE")
	var old_unread_id: String = old_unread.alerts.primary().id
	old_unread.world.elapsed = 13
	old_unread.world.rear.stop_worker(13)
	old_unread.alerts.update(old_unread.world)
	var retained_resolution: Array = old_unread.alerts.entries.filter(func(entry): return entry.id == old_unread_id)
	expect(retained_resolution.size() == 1 and retained_resolution[0].state == "RESOLVED" and not retained_resolution[0].acknowledged and retained_resolution[0].time < retained_resolution[0].resolved_at, "Old unread action remains represented when it resolves into full history, with separate original/resolution times")
	var before_world := exact_world(ops.world)
	var before_order := JSON.stringify(ops.world.rear.production_order)
	alerts.acknowledge(action_id)
	for sample in range(20):
		alerts.update(ops.world)
	expect(exact_world(ops.world) == before_world and JSON.stringify(ops.world.rear.production_order) == before_order and ops.world.rear.production_order.status == "BLOCKED_INPUT", "Acknowledging open action and evaluating priority never solves/mutates underlying work")
	expect(alerts.entries.filter(func(entry): return entry.type == "PRODUCTION_BLOCKED").size() == 1 and alerts.counts().action_open == 1 and alerts.counts().action_unread == 0, "Acknowledged continuous blockage stays silent but visible as an open condition")
	ops.world.rear.capability_unlocked = false
	ops.advance(1.0 / 60.0)
	var changed_reason: Dictionary = alerts.entries.filter(func(entry): return entry.id == action_id)[0]
	expect(changed_reason.state == "OPEN" and changed_reason.acknowledged and changed_reason.text.contains("capability") and alerts.entries.filter(func(entry): return entry.type == "PRODUCTION_BLOCKED").size() == 1, "A different cause within continuous acknowledged order blockage updates reason without fake resolution or repeat alert")
	ops.world.rear.capability_unlocked = true
	ops.advance(1.0 / 60.0)
	ops.world.rear.stop_worker(ops.world.elapsed)
	alerts.update(ops.world)
	var resolved: Array = alerts.entries.filter(func(entry): return entry.id == action_id)
	expect(alerts.counts().action_open == 0 and (resolved.is_empty() or (resolved[0].state == "RESOLVED" and resolved[0].acknowledged and resolved[0].resolution == "RESOLVED — Production stopped")), "Real stop resolves action separately from acknowledgement; older acknowledged history may roll off")
	ops.world.rear.assign_worker(3, ops.world.elapsed)
	ops.advance(1.0 / 60.0)
	expect(alerts.primary().type == "PRODUCTION_BLOCKED" and alerts.primary().id != action_id and alerts.counts().action_unread == 1, "Genuine clear then explicit later blocked order earns new actionable alert")
	var protected_id: String = alerts.primary().id
	observe(ops, enemy)
	var first_info: Dictionary = alerts.newest_unread()
	var first_time: float = first_info.first_time
	observe(ops, enemy)
	observe(ops, enemy)
	var coalesced: Dictionary = alerts.entries.filter(func(entry): return entry.id == first_info.id)[0]
	expect(coalesced.update_count == 3 and coalesced.first_time == first_time and coalesced.time > first_time and coalesced.provenance.size() == 1 and coalesced.provenance[0].observation_time == ops.world.elapsed - 2, "Three delivered same-contact updates coalesce one unread row with original/latest time and latest provenance")
	expect(alerts.entries.filter(func(entry): return entry.type == "COMPANY_CONTACT" and not entry.acknowledged and entry.contact_id == enemy.id).size() == 1 and alerts.primary().id == protected_id, "Coalescing reduces rows without taking actionable salience")
	var other = ops.world.combat.defenders.soldiers[1]
	other.position = Vector2(620, 220)
	observe(ops, other)
	expect(alerts.entries.filter(func(entry): return entry.type == "COMPANY_CONTACT" and not entry.acknowledged).size() == 2, "Different stable contact identities never merge")
	alerts.acknowledge(first_info.id)
	observe(ops, enemy)
	var after_ack: Dictionary = alerts.newest_unread()
	expect(after_ack.id != first_info.id and after_ack.contact_id == enemy.id and after_ack.update_count == 1, "After acknowledgement a genuinely newer report may create a new row")
	var before_hidden := JSON.stringify(alerts.recent())
	var old_position: Vector2 = after_ack.provenance[0].observed_position
	enemy.position = Vector2(900, 700)
	enemy.active = false
	enemy.medical_state = "DEAD"
	ops.world.elapsed += 20
	alerts.update(ops.world)
	expect(JSON.stringify(alerts.recent()) == before_hidden and ops.situation().contacts.any(func(row): return row.report.get("contact_id", "") == enemy.id and row.report.observed_position == old_position and row.freshness == "STALE"), "Hidden enemy movement/death cannot coalesce, alert, resolve or correct stale knowledge")
	var history_records: Array[Dictionary] = [{"location": Vector2(264, 634), "observation_time": 5.0, "soldier_id": "Known", "received_at": 8.0, "facts": ["explosion"]}]
	ops.world.information.begin_reconstruction(history_records)
	var paused := JSON.stringify(alerts.recent())
	ops.world.rear.capability_unlocked = false
	alerts.update(ops.world)
	expect(JSON.stringify(alerts.recent()) == paused, "Historical reconstruction cannot resolve/reorder/coalesce/create live triage state")
	ops.world.rear.capability_unlocked = true
	ops.world.information.end_reconstruction()
	var delivery := {"id": "FiniteMetalCrate-01", "owner": "rear", "position": Vector2(175, 230), "inventory": {"Metal": 2}}
	ops.world.rear.receive_metal(delivery, 2, ops.world.elapsed)
	ops.advance(1.0 / 60.0)
	var resumed: Dictionary = alerts.entries.filter(func(entry): return entry.id == protected_id)[0]
	expect(resumed.state == "RESOLVED" and not resumed.acknowledged and resumed.resolution == "RESOLVED — Production resumed", "Actual eligible input/ordinary batch resumption resolves unread action without acknowledging/deleting evidence")
	for tick in range(600):
		ops.advance(1.0 / 60.0)
	expect(ops.world.rear.production_order.status == "BLOCKED_INPUT" and alerts.primary().type == "PRODUCTION_BLOCKED" and alerts.primary().id != protected_id, "Same order can genuinely resume then exhaust input and produce a new block alert")
	var terminal_action: String = alerts.primary().id
	ops.world.battle.apply_blast_damage(ops.world.battle.hqs["Enemy-HQ"].position, ops.world.elapsed, "stress-proof")
	ops.world.battle.apply_blast_damage(ops.world.battle.hqs["Enemy-HQ"].position, ops.world.elapsed, "stress-proof")
	alerts.update(ops.world)
	expect(alerts.primary()["class"] == "RESULT" and alerts.counts().result_unread == 1 and alerts.entries.any(func(entry): return entry.id == terminal_action and entry.state == "OPEN"), "Terminal RESULT overrides primary while operational action remains in history")
	for index in range(12):
		alerts.emit_alert("PRODUCTION_COMPLETED", ops.world.elapsed, "Focused presentation capacity sample", "unit-capacity", "NONE")
	expect(alerts.primary()["class"] == "RESULT" and alerts.history_count() == 8 and alerts.entries.any(func(entry): return entry.id == terminal_action), "Information capacity cannot evict unread result or open action")
	var event_order: Array = alerts.recent().map(func(entry): return entry.id)
	var world_before_rank := exact_world(ops.world)
	var ranked: Array = alerts.ranked()
	expect(ranked[0]["class"] == "RESULT" and ranked[1]["class"] == "ACTION_REQUIRED" and alerts.recent().map(func(entry): return entry.id) == event_order and exact_world(ops.world) == world_before_rank, "Visual priority changes neither event storage order nor simulation state")
	var same_time: Array = ranked.filter(func(entry): return entry["class"] == "INFORMATION")
	expect(same_time[0].sequence > same_time[-1].sequence and same_time.all(func(entry): return entry.time == same_time[0].time), "Same-class same-time ties use stable event sequence rather than object addresses")
	alerts.acknowledge(alerts.primary().id)
	expect(alerts.primary()["class"] == "RESULT" and alerts.primary().acknowledged and alerts.counts().result_unread == 0 and alerts.entries.any(func(entry): return entry.id == terminal_action and entry.state == "OPEN"), "Acknowledged terminal result remains latched context; frozen open work cannot become primary")
	evidence.append(alerts.recent())
	var authorization = Ops.new()
	authorization.step(8)
	authorization.world.rear.place_workbench(Vector2(380, 480))
	authorization.world.rear.assign_worker(1)
	authorization.step(6)
	var auth: Dictionary = authorization.alerts.primary()
	expect(auth.type == "STOCK_AUTHORIZATION" and auth.state == "OPEN", "Real unresolved request with locked produced stock is actionable")
	authorization.alerts.acknowledge(auth.id)
	authorization.world.rear.set_policy("RESERVE", 8)
	authorization.alerts.update(authorization.world)
	var still_blocked: Dictionary = authorization.alerts.entries.filter(func(entry): return entry.id == auth.id)[0]
	expect(still_blocked.state == "OPEN" and still_blocked.acknowledged and still_blocked.text.contains("RESERVE FLOOR") and authorization.alerts.entries.filter(func(entry): return entry.type == "STOCK_AUTHORIZATION").size() == 1, "LOCKED to fully protecting reserve is still one unresolved acknowledged policy block, not a false clear")
	authorization.world.rear.set_policy("AVAILABLE")
	authorization.alerts.update(authorization.world)
	var auth_after: Dictionary = authorization.alerts.entries.filter(func(entry): return entry.id == auth.id)[0]
	expect(auth_after.state == "RESOLVED" and auth_after.acknowledged and auth_after.resolution.contains("eligible"), "Real authorization eligibility resolves separately from acknowledgement")
	authorization.world.rear.set_policy("RESERVE", 8)
	authorization.alerts.update(authorization.world)
	expect(authorization.alerts.primary().type == "STOCK_AUTHORIZATION" and authorization.alerts.primary().text.contains("RESERVE FLOOR") and authorization.alerts.primary().id != auth.id, "Later different genuine policy block creates truthful new action")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var file := FileAccess.open("res://artifacts/triage_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "stress": evidence}, "\t", true, true))
	print("TRIAGE CHECKS: ", checks, " failures: ", failures)
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
	root.get_texture().get_image().save_png("res://artifacts/triage_" + name + ".png")

func visual_run() -> void:
	var view = load("res://operations.tscn").instantiate()
	# Focused stress variant: same ordinary observation path, finite empty rifle
	# inventories keep the contact alive/observable; no extra combat event surface.
	view.model.rear.metal = 1
	for person in view.model.squads[0].soldiers + view.model.combat.defenders.soldiers:
		person.inventory.BoltActionRifleAmmo = 0
	var delivery := {"id": "FiniteMetalCrate-01", "owner": "rear", "position": Vector2(175, 230), "inventory": {"Metal": 2}}
	root.add_child(view)
	var overlay := Node2D.new()
	view.add_child(overlay)
	overlay.draw.connect(func():
		overlay.draw_string(ThemeDB.fallback_font, Vector2(28, 98), "STRESS PROOF: sustained observed contact / finite input crate / authored Company release T30", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("dac28e")))
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
	key(KEY_1)
	key(KEY_TAB)
	await process_frame
	while view.model.rear.production_order.status != "BLOCKED_INPUT" and view.model.elapsed < 8:
		await create_timer(0.025).timeout
	await capture("01_action_required_on_field")
	var first_action: String = view.operations.alerts.primary().id
	expect(view.view_mode == "battlefield" and view.operations.alerts.primary()["class"] == "ACTION_REQUIRED", "Normal finite order leaves player on field with real action-required block")
	while view.model.elapsed < 15:
		await create_timer(0.1).timeout
	await capture("02_action_survives_newer_company_information")
	var company: Array = view.operations.alerts.entries.filter(func(entry): return entry.type == "COMPANY_CONTACT" and not entry.acknowledged)
	expect(view.operations.alerts.primary().id == first_action and view.view_mode == "battlefield" and company.size() == 1 and company[0].update_count >= 3, "Several genuinely newer delivered reports coalesce one contact while older action remains primary without forced map switch")
	key(KEY_H)
	await process_frame
	await capture("03_coalesced_company_row_and_action")
	expect(view.alert_panel.visible and view.alert_rows[0].text.contains("ACTION_REQUIRED") and view.alert_rows[1].text.contains("Contact update"), "Actual history visibly separates primary action and per-contact update count")
	key(KEY_H)
	key(KEY_K)
	await process_frame
	await capture("04_acknowledged_still_blocked")
	expect(view.model.rear.production_order.status == "BLOCKED_INPUT" and view.operations.alerts.counts().action_open == 1 and view.operations.alerts.counts().action_unread == 0 and view.operations.alerts.primary()["class"] == "INFORMATION", "Normal ACK PRIMARY suppresses notification without resolving blocked work; open/unread badges differ")
	await create_timer(0.8).timeout
	await capture("05_no_spam_after_acknowledgement")
	expect(view.operations.alerts.entries.filter(func(entry): return entry.type == "PRODUCTION_BLOCKED").size() == 1, "Acknowledged persistent condition does not regenerate during continued reports/world time")
	key(KEY_TAB)
	await process_frame
	key(KEY_X)
	await create_timer(0.1).timeout
	key(KEY_H)
	await process_frame
	await capture("06_actual_stop_resolves_old_action")
	var stopped: Dictionary = view.operations.alerts.entries.filter(func(entry): return entry.id == first_action)[0]
	expect(view.model.rear.production_order.status == "STOPPED" and stopped.state == "RESOLVED" and stopped.acknowledged and stopped.resolution.contains("stopped"), "Player stop is real state-derived resolution separate from acknowledgement")
	key(KEY_H)
	key(KEY_F)
	await create_timer(0.1).timeout
	await capture("07_explicit_later_order_reblocks")
	var second_action: String = view.operations.alerts.primary().id
	expect(second_action != first_action and view.model.rear.production_order.status == "BLOCKED_INPUT", "Explicit later finite order can genuinely create a new actionable block")
	while view.model.elapsed < 18:
		await create_timer(0.05).timeout
	view.model.rear.receive_metal(delivery, 2, view.model.elapsed)
	await create_timer(0.1).timeout
	key(KEY_H)
	await process_frame
	await capture("08_real_input_resumption_resolves_unread_action")
	var resumed: Dictionary = view.operations.alerts.entries.filter(func(entry): return entry.id == second_action)[0]
	expect(view.model.rear.production_order.status == "ACTIVE" and resumed.state == "RESOLVED" and not resumed.acknowledged and resumed.resolution.contains("resumed"), "Legitimate finite input automatically resumes ordinary order and retains resolved unread action evidence")
	key(KEY_H)
	while view.model.rear.production_order.status != "BLOCKED_INPUT" and view.model.elapsed < 30:
		await create_timer(0.05).timeout
	key(KEY_TAB)
	await process_frame
	await capture("09_same_order_exhaustion_new_action")
	expect(view.model.rear.production_order.completed == 2 and view.model.rear.produced == 24 and view.operations.alerts.primary().id != second_action and view.operations.alerts.primary()["class"] == "ACTION_REQUIRED", "Same real order resumes then exhausts finite2 input, earning new block above newer information")
	while view.model.elapsed < 30:
		await create_timer(0.05).timeout
	# Authored stress-fixture strategic release uses existing Company director,
	# actual finite mortar shells, flight/impact and HQ damage; no player command.
	view.model.battle.auto_strike = true
	while view.model.battle_active() and view.model.elapsed < 43:
		await create_timer(0.1).timeout
	await capture("10_terminal_result_supersedes_open_action")
	expect(not view.model.battle_active() and view.operations.alerts.primary()["class"] == "RESULT" and view.operations.alerts.counts().result_unread == 1 and view.operations.alerts.counts().action_unread == 1, "Actual autonomous strategic result supersedes, but does not erase, unread operational action")
	key(KEY_H)
	await process_frame
	await capture("11_priority_history_retains_open_action")
	expect(view.alert_rows[0].text.contains("RESULT") and view.operations.alerts.history_count() <= 8 and view.operations.alerts.entries.size() <= 11, "Final rendered priority list remains bounded and preserves result/action classification")
	evidence.append(view.operations.alerts.recent())
