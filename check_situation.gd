extends SceneTree

const Ops = preload("res://operations.gd")
const Situation = preload("res://situation.gd")
const Information = preload("res://information.gd")
const Person = preload("res://soldier.gd")
const Inspector = preload("res://active_checkpoint.gd")
var checks := 0
var failures: Array[String] = []
var prompts: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func record_prompt(status: Dictionary) -> void:
	prompts.append(status.prompt)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var ops = Ops.new()
	var world = ops.world
	var status: Dictionary = ops.situation()
	record_prompt(status)
	expect(status.need.requested == 0 and status.need.state == "AWAITING REQUEST" and status.chain.stage == "NO STOCK" and status.prompt.begins_with("Place a workbench"), "Initial status derives actual absence of request/stock/bench and useful rear action")
	ops.step(8)
	status = ops.situation()
	expect(status.need.requested == world.supply.REQUEST_QUANTITY and status.need.remaining == 8 and status.need.delivered == 0 and status.need.state == "UNRESOLVED" and status.need.carried == 8, "Need uses authoritative request quantity, actual delivery ledger and readiness state")
	var partial = Ops.new()
	partial.step(8)
	# Authored physical partial-handoff unit fixture: real source inventory and
	# ordinary transfer ledger, not a separate UI fulfillment counter.
	partial.world.supply.truck.position = partial.world.squads[0].soldiers[0].position
	partial.world.supply.truck.inventory.BoltActionRifleAmmo = 4
	partial.world.supply.transfer(partial.world.supply.truck.id, partial.world.supply.truck.inventory, partial.world.squads[0].soldiers[0].id, partial.world.squads[0].soldiers[0].inventory, 4, "Physical delivery at staging")
	expect(partial.situation().need.state == "PARTLY SUPPLIED" and partial.situation().need.delivered == 4 and partial.situation().need.remaining == 4, "Partial fulfillment is derived from actual custody transfer history, not UI-only state")
	expect(status.report_activity.begins_with("Company") and status.contacts.size() == 1 and status.contacts[0].provenance.begins_with("Company"), "Report activity and provenance come only from delivered Company knowledge")
	var inspector = Inspector.new()
	var before_projection := JSON.stringify(inspector.exact_pack(inspector.graph(world)), "", true, true)
	inspector.release_mapping()
	var mutable_copy: Dictionary = ops.situation()
	mutable_copy.stock.finished = 999
	mutable_copy.contacts[0].report.observed_position = Vector2.ZERO
	for sample in range(20):
		ops.situation()
	var after_projection := JSON.stringify(inspector.exact_pack(inspector.graph(world)), "", true, true)
	inspector.release_mapping()
	expect(before_projection == after_projection, "Status/prompt evaluation and modified diagnostic copies never mutate world/policy/custody/knowledge")
	world.rear.place_workbench(Vector2(380, 480))
	status = ops.situation()
	record_prompt(status)
	expect(status.work.bench and status.work.worker == "UNASSIGNED" and status.prompt.begins_with("Start one ammunition batch"), "Available bench, idle work and unassigned Worker are distinct")
	world.rear.start_job("Avatar", world.elapsed)
	ops.step(1)
	status = ops.situation()
	record_prompt(status)
	expect(status.work.state.begins_with("MANUAL") and absf(status.work.progress - 1) < 0.000001 and world.rear.ammunition == 0 and status.prompt.contains("no player action required"), "Production progress is actual world-time job progress, not fake supply percent")
	ops.step(3)
	status = ops.situation()
	record_prompt(status)
	expect(status.stock.finished == 8 and status.stock.uncommitted == 8 and status.stock.committed == 0 and status.stock.eligible == 0 and status.chain.stage == "WITHHELD — LOCKED" and status.stock.explanation == "LOCKED — military draw disabled", "Finished LOCKED stock visibly distinguishes ownership, free stock and policy blockage")
	expect(status.need.state == "UNRESOLVED" and status.prompt.contains("LOCKED") and status.work.state.contains("COMPLETE"), "Blocked request and useful authorization prompt do not pretend a completed batch was delivered")
	world.rear.set_policy("RESERVE", 8)
	status = ops.situation()
	record_prompt(status)
	expect(status.chain.stage == "WITHHELD — RESERVE FLOOR" and status.stock.eligible == 0 and status.stock.explanation.contains("8 protected; 0 eligible") and status.need.remaining == 8, "Reserve8/stock8 explicitly explains zero releasable stock without changing request/policy")
	world.rear.set_policy("AVAILABLE")
	status = ops.situation()
	record_prompt(status)
	expect(status.chain.stage == "AVAILABLE FOR COMMITMENT" and status.stock.eligible == 8, "Authorized but unallocated stock is not mistaken for commitment or delivery")
	ops.advance(1.0 / 60.0)
	status = ops.situation()
	record_prompt(status)
	expect(status.chain.stage == "COMMITTED" and status.stock.committed == 8 and status.stock.finished == 8 and status.need.delivered == 0, "Actual allocation instant reports COMMITTED, remains rear-owned and not delivered")
	ops.advance(1.0 / 60.0)
	status = ops.situation()
	record_prompt(status)
	expect(status.chain.stage == "LOADING" and status.chain.explanation.contains("stock remains rear-owned") and status.prompt.contains("no player action required"), "Loading waiting state explains process/ownership/action requirement")
	var stages: Array[String] = []
	var one_stale_seen := false
	var newer_company_seen := false
	var latest_times := {}
	while world.battle_active() and world.elapsed < 95:
		ops.advance(1.0 / 60.0)
		status = ops.situation()
		record_prompt(status)
		if status.chain.stage not in stages:
			stages.append(status.chain.stage)
		for row in status.contacts:
			var identity: String = row.report.contact_id
			if latest_times.has(identity) and row.report.observation_time > latest_times[identity]:
				newer_company_seen = true
			latest_times[identity] = row.report.observation_time
			one_stale_seen = one_stale_seen or row.freshness == "STALE"
	expect(["IN TRANSIT", "AT RECEIVING DEPOT", "ON TRUCK", "DELIVERED"].all(func(stage): return stage in stages), "Derived stages follow real shipment/receiving/truck/Soldier custody without a fake percent")
	expect(status.need.state == "SATISFIED" and status.need.delivered == 8 and status.need.remaining == 0 and world.supply.carried() < 16, "Request stays historically satisfied after ordinary combat consumes delivered rounds")
	expect(one_stale_seen and newer_company_seen and status.contacts.size() > 1, "Ordinary local observations create newer same-contact Company reports while old stale evidence remains")
	expect(status.prompt.begins_with("Battle ended"), "Terminal prompt reflects frozen aftermath rather than further production or tactical orders")
	var worker_ops = Ops.new()
	worker_ops.world.rear.place_workbench(Vector2(380, 480))
	worker_ops.world.rear.assign_worker()
	var worker_status: Dictionary = worker_ops.situation()
	record_prompt(worker_status)
	expect(worker_status.work.worker.begins_with("ONE BATCH ASSIGNED") and worker_status.work.state.contains("APPROACHING") and worker_status.prompt.contains("no player action required"), "Assigned one-batch Worker is visibly approaching/waiting before any job begins")
	while worker_ops.world.rear.job.is_empty() and worker_ops.world.elapsed < 5:
		worker_ops.advance(1.0 / 60.0)
	worker_status = worker_ops.situation()
	expect(worker_status.work.worker == "ONE BATCH ACTIVE" and worker_status.work.state.begins_with("WORKER"), "Actual Worker job is distinguished from mere assignment")
	worker_ops.step(5)
	worker_status = worker_ops.situation()
	expect(worker_status.work.worker == "ONE BATCH COMPLETE — none scheduled" and worker_ops.world.rear.produced == 8, "Worker completion clearly states no subsequent automatic batch")
	worker_ops.step(10)
	expect(worker_ops.world.rear.produced == 8 and worker_ops.situation().work.worker.contains("none scheduled"), "Worker clarity does not introduce continuous production")
	expect(Situation.freshness(5) == "RECENT" and Situation.freshness(5.001) == "AGING" and Situation.freshness(15) == "AGING" and Situation.freshness(15.001) == "STALE", "Provisional5/15worldsecond freshness bands honor exact boundaries")
	var isolated = Ops.new()
	var info = Information.new()
	isolated.world.information = info
	var casualty = Person.new("ReportTest", Vector2.ZERO, 0)
	var observer = isolated.world.squads[0].soldiers[1]
	var observed_enemy = isolated.world.combat.defenders.soldiers[0]
	observer.position = Vector2(500, 200)
	isolated.world.combat.detect(observer, [observed_enemy])
	assert(isolated.world.combat.can_detect(observer, observed_enemy))
	info.observe_contact(observer.id, observed_enemy.id, observed_enemy.position, 0, 0.1)
	info.advance(1.99, casualty)
	isolated.world.elapsed = 1.99
	expect(isolated.situation().contacts.is_empty() and isolated.situation().report_activity == "Company: no contact report received yet", "Local/pending report existence and contents do not appear as Company knowledge")
	info.advance(2, casualty)
	isolated.world.elapsed = 2
	var first: Dictionary = isolated.situation().contacts[0]
	expect(first.report.observed_position == Vector2(600, 200) and first.age == 2 and first.report.received_at == 2 and first.provenance == "Company / " + observer.id, "First marker appears only after actual two-hop receipt with age/provenance")
	isolated.world.elapsed = 2.25
	observed_enemy.position = Vector2(620, 220)
	isolated.world.combat.detect(observer, [observed_enemy])
	assert(isolated.world.combat.can_detect(observer, observed_enemy))
	info.observe_contact(observer.id, observed_enemy.id, observed_enemy.position, isolated.world.elapsed, 0.1)
	expect(isolated.situation().contacts[0].report.observed_position == Vector2(600, 200), "New local observation cannot prematurely snap old Company marker")
	info.advance(3.25, casualty)
	isolated.world.elapsed = 3.25
	expect(isolated.situation().contacts[0].report.observation_time == 0 and info.contact_knowledge.Platoon.size() == 2, "New Platoon receipt still does not leak updated position to Company-facing marker")
	info.advance(4.25, casualty)
	isolated.world.elapsed = 4.25
	var updated: Dictionary = isolated.situation().contacts[0]
	expect(isolated.situation().contacts.size() == 1 and updated.report.observed_position == Vector2(620, 220) and updated.report.observation_time == 2.25 and updated.age == 2 and info.contact_deliveries.size() == 4, "Legitimately newer Company report replaces latest marker once, preserving hop latency")
	isolated.world.combat.defenders.soldiers[0].active = false
	isolated.world.combat.defenders.soldiers[0].medical_state = "DEAD"
	isolated.world.combat.defenders.soldiers[0].position = Vector2(900, 700)
	isolated.world.elapsed = 30
	var stale: Dictionary = isolated.situation().contacts[0]
	expect(stale.label == "LAST KNOWN" and stale.freshness == "STALE" and stale.report.observed_position == Vector2(620, 220) and stale.age == 27.75, "Unreported enemy movement/death never removes or corrects stale evidence from World State")
	expect(Situation.inquiry([], true).begins_with("UNKNOWN") and Situation.inquiry([{"facts": ["explosion"]}], true).begins_with("PARTIAL / LAST KNOWN") and Situation.inquiry([{"facts": ["explosion", "friendly casualty"]}], true).begins_with("CONFIRMED HISTORY"), "Inquiry distinguishes unknown, partial/last-known and confirmed history without claiming hidden source")
	var tactical := RegEx.new()
	tactical.compile("(?i)\\b(attack|fire artillery|reposition|seize|move squad|order advance|withdraw squad)\\b")
	expect(prompts.all(func(prompt): return tactical.search(prompt) == null), "All observed context prompts stay within rear/logistics/observation agency")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/situation_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "stages": stages, "final_status": status, "worker": worker_status, "newer_company_report_observed": newer_company_seen, "prompts": Array(prompts.reduce(func(unique, prompt):
		if prompt not in unique:
			unique.append(prompt)
		return unique, []))}, "\t", true, true))
	output.close()
	print("SITUATION CHECKS: ", checks, " failures: ", failures)
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
	root.get_texture().get_image().save_png("res://artifacts/situation_" + name + ".png")

func visual_run() -> void:
	var view = load("res://operations.tscn").instantiate()
	root.add_child(view)
	while view.model.supply.requested_at < 0 and view.model.elapsed < 10:
		await create_timer(0.1).timeout
	await capture("01_need_unresolved_useful_prompt")
	expect(view.operations.situation().need.state == "UNRESOLVED" and view.operations.situation().prompt.begins_with("Place a workbench"), "Actual operations entry clearly exposes request and useful rear action")
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	key(KEY_F)
	await process_frame
	await capture("02_worker_one_batch_assigned")
	expect(view.operations.situation().work.worker.begins_with("ONE BATCH ASSIGNED"), "Actual Worker control distinguishes queued one-batch assignment")
	while view.model.rear.job.is_empty() and view.model.elapsed < 12:
		await create_timer(0.1).timeout
	await capture("03_worker_active_job_progress")
	expect(view.operations.situation().work.worker == "ONE BATCH ACTIVE" and view.operations.situation().work.progress > 0, "Actual Worker arrival and job progress appear from ordinary rear state")
	while view.model.rear.produced < 8 and view.model.elapsed < 18:
		await create_timer(0.1).timeout
	await capture("04_stock_locked_worker_complete")
	expect(view.operations.situation().chain.stage == "WITHHELD — LOCKED" and view.operations.situation().stock.eligible == 0 and view.operations.situation().work.worker.contains("none scheduled"), "Actual finished stock explains LOCKED blockage and one-batch completion")
	key(KEY_2)
	await create_timer(0.1).timeout
	await capture("05_reserve_eight_explains_zero_free")
	expect(view.operations.situation().chain.stage == "WITHHELD — RESERVE FLOOR" and view.operations.situation().stock.explanation.contains("8 protected; 0 eligible"), "Actual Reserve8 input explains why all first-batch stock remains withheld")
	while view.model.elapsed < 20:
		await create_timer(0.1).timeout
	key(KEY_TAB)
	await process_frame
	await capture("06_stale_last_known_marker_retained")
	var age: float = view.operations.situation().contacts[0].age
	expect(view.operations.situation().contacts[0].freshness == "STALE" and view.operations.situation().contacts[0].report.observed_position == Vector2(600, 200), "Actual old contact remains last-known/stale after unreported guard death")
	key(KEY_TAB)
	await create_timer(0.2).timeout
	key(KEY_TAB)
	await process_frame
	expect(view.operations.situation().contacts[0].age > age and view.model.rear.policy == "RESERVE", "Map switching preserves authoritative report age and authorization policy")
	key(KEY_B)
	await process_frame
	click(Vector2(500, 600))
	await process_frame
	await capture("07_unknown_inquiry_not_live_truth")
	expect(Situation.inquiry(view.query_result, view.queried).begins_with("UNKNOWN"), "Actual unreported arbitrary location displays UNKNOWN")
	click(Vector2(264, 634))
	await process_frame
	key(KEY_R)
	await create_timer(0.1).timeout
	await capture("08_confirmed_historical_reconstruction")
	expect(view.model.information.reconstructing and Situation.inquiry(view.query_result, view.queried).begins_with("CONFIRMED HISTORY"), "Actual reconstruction is explicitly established history with unknown source")
	key(KEY_ESCAPE)
	key(KEY_TAB)
	await process_frame
	key(KEY_1)
	await create_timer(0.1).timeout
	await capture("09_loading_no_player_action_required")
	expect(view.operations.situation().chain.stage in ["COMMITTED", "LOADING"] and view.operations.situation().stock.committed == 8 and view.operations.situation().prompt.contains("no player action required"), "Actual authorization shows commitment/loading without confusing it with delivery")
	while view.model.rear.shipment.cargo == 0 and view.model.elapsed < 30:
		await create_timer(0.1).timeout
	await capture("10_transit_active_waiting_state")
	expect(view.operations.situation().chain.stage == "IN TRANSIT" and view.operations.situation().prompt.contains("observe"), "Actual inter-map custody shows useful transit/observation waiting state")
	key(KEY_TAB)
	while view.model.supply.truck.inventory.BoltActionRifleAmmo == 0 and view.model.elapsed < 35:
		await create_timer(0.1).timeout
	await capture("11_truck_custody_not_soldier_delivery")
	expect(view.operations.situation().chain.stage == "ON TRUCK" and view.operations.situation().need.remaining == 8, "Actual truck stage retains unresolved request until physical Soldier handoff")
	while view.model.supply.resumed_at < 0 and view.model.elapsed < 65:
		await create_timer(0.1).timeout
	await capture("12_delivered_need_satisfied")
	expect(view.operations.situation().chain.stage == "DELIVERED" and view.operations.situation().need.state == "SATISFIED", "Actual delivery status is satisfied and formation resumes without tactical prompt")
	var prior_times := {}
	var updated := false
	while not updated and view.model.battle_active() and view.model.elapsed < 90:
		for row in view.operations.situation().contacts:
			var identity: String = row.report.contact_id
			if prior_times.has(identity) and row.report.observation_time > prior_times[identity]:
				updated = true
			prior_times[identity] = row.report.observation_time
		await create_timer(0.1).timeout
	await capture("13_newer_company_report_updates_marker")
	expect(updated and view.operations.situation().contacts.any(func(row): return row.freshness == "RECENT") and view.operations.situation().contacts.any(func(row): return row.freshness == "STALE"), "Real locally observed newer same-contact report updates only after Company receipt; stale old evidence remains")
	while view.model.battle_active() and view.model.elapsed < 95:
		await create_timer(0.1).timeout
	await capture("14_terminal_aftermath_status")
	expect(view.model.battle_state == "ENDED_FRIENDLY_VICTORY" and view.model.rear.produced == 8 and view.model.rear.policy == "AVAILABLE", "Improved feedback preserves ordinary autonomous outcome, single Worker batch and explicit player policy")
