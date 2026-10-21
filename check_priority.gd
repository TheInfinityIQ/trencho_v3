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

func tactical(world) -> String:
	return JSON.stringify({"people": world.all_people().map(func(person): return {"id": person.id, "position": person.position, "path": person.path, "waypoint": person.waypoint, "inventory": person.inventory, "active": person.active}),
		"squads": world.squads.map(func(squad): return {"id": squad.id, "task": squad.task, "destination": squad.destination, "decision": squad.decision}),
		"command": world.trace, "combat": [world.combat.shots, world.combat.decisions, world.combat.next_fire, world.combat.tactical_state],
		"artillery": world.artillery.missions, "time": world.elapsed}, "", true, true)

func scarce():
	var ops = Ops.new()
	ops.step(12)
	ops.world.rear.place_workbench(Vector2(380, 480))
	ops.world.rear.assign_worker(1)
	ops.step(6)
	return ops

func run() -> void:
	var ops = Ops.new()
	expect(ops.world.rear.requests.size() == 2 and request(ops, "Request-A").requested == 0 and request(ops, "Request-B").requested == 0, "Stable logical requests are registered without fabricating demand before physical staging")
	var before_priority := tactical(ops.world)
	expect(not ops.set_priority("Request-B") and not ops.set_priority("Missing") and not ops.set_priority("Request-A", "HIGH"), "Unknown/non-outstanding/unsupported priority changes reject")
	expect(tactical(ops.world) == before_priority, "Rejected priority controls have no tactical/resource side effects")
	ops.step(12)
	var a: Dictionary = request(ops, "Request-A")
	var b: Dictionary = request(ops, "Request-B")
	expect(a.requested == 8 and b.requested == 8 and a.remaining == 8 and b.remaining == 8 and a.state == "WAITING" and b.state == "WAITING", "Two simultaneous8round requests arise from ordinary physical Supply staging")
	expect(ops.world.supply.carried() == 8 and ops.world.additional_supplies[0].carried() == 8 and ops.world.supply.phase == "Hold: ammunition shortage" and ops.world.additional_supplies[0].phase == "Hold: ammunition shortage", "Both formations genuinely carry8 below16 readiness, not a UI-only shortage")
	expect(a.created_at == ops.world.supply.requested_at and b.created_at == ops.world.additional_supplies[0].requested_at and a.created_at <= b.created_at, "Request creation time/order reflects actual Supply events")
	before_priority = tactical(ops.world)
	expect(ops.set_priority("Request-A") and ops.set_priority("Request-B") and a.priority == "NORMAL" and b.priority == "PRIORITY", "Pre-commit switch changes one explicit priority, returning other demand to NORMAL")
	expect(tactical(ops.world) == before_priority and ops.world.rear.ammunition == 0 and ops.world.rear.committed == 0, "Setting logistics priority without stock changes no position/path/target/mission/command/ammunition")
	var codec = Codec.new()
	expect(codec.values_only(ops.world.rear.requests) and codec.unpack(JSON.parse_string(JSON.stringify(codec.pack(ops.world.rear.requests), "", true, true))) == ops.world.rear.requests, "Request IDs/priority/allocation state are plain serializable values")
	ops.world.rear.place_workbench(Vector2(380, 480))
	ops.world.rear.assign_worker(1)
	ops.step(6)
	expect(ops.world.rear.produced == 8 and ops.world.rear.ammunition == 8 and ops.world.rear.committed == 0 and a.allocated == 0 and b.allocated == 0, "LOCKED outranks B PRIORITY and cannot double-allocate the one produced batch")
	var allocation_alerts: Array = ops.alerts.entries.filter(func(entry): return entry.type == "STOCK_AUTHORIZATION")
	expect(allocation_alerts.size() == 1 and allocation_alerts[0]["class"] == "ACTION_REQUIRED" and allocation_alerts[0].text.contains("2 ammunition requests") and ops.alerts.primary().id == allocation_alerts[0].id, "Existing protected action category surfaces multi-request allocation without seventh event type or tactical advice")
	ops.world.rear.set_policy("RESERVE", 8)
	ops.step(0.5)
	expect(ops.world.rear.eligible() == 0 and a.allocated == 0 and b.allocated == 0 and ops.alerts.primary().text.contains("RESERVE FLOOR"), "Reserve8 protects8 before priority selection")
	ops.world.rear.set_policy("RESERVE", 4)
	ops.step(0.5)
	expect(ops.world.rear.eligible() == 4 and ops.world.rear.committed == 0 and a.allocated == 0 and b.allocated == 0, "Fewer than8 eligible rounds waits without partial commitments")
	ops.world.rear.set_policy("AVAILABLE")
	ops.advance(1.0 / 60.0)
	var shipment_id: String = ops.world.rear.shipment.id
	expect(ops.world.rear.committed == 8 and ops.world.rear.ammunition == 8 and ops.world.rear.eligible() == 0 and b.allocated == 8 and a.allocated == 0 and ops.world.rear.commitment_request_id == "Request-B", "Eligible scarce8 commits exactly once to current PRIORITY B, remains rear on-hand subset")
	expect(a.state == "WAITING" and b.state == "COMMITTED" and a.delivered == 0 and b.delivered == 0 and not b.ready, "Commitment owns request identity but cannot fake delivery/readiness")
	before_priority = tactical(ops.world)
	expect(ops.set_priority("Request-A") and a.priority == "PRIORITY" and b.priority == "NORMAL" and b.allocated_priority == "PRIORITY", "Post-commit priority changes current preference but preserves recorded commitment decision")
	expect(ops.world.rear.shipment.id == shipment_id and ops.world.rear.shipment.request_id == "Request-B" and ops.world.rear.commitment_request_id == "Request-B" and b.allocated == 8 and a.allocated == 0 and tactical(ops.world) == before_priority, "Later A priority cannot steal B commitment or change tactics")
	var conserved := true
	var observed_transit := false
	while b.delivered < 8 and ops.world.elapsed < 65:
		ops.advance(1.0 / 60.0)
		conserved = conserved and ops.world.total_ammunition() == ops.initial_ammo + ops.world.rear.produced - ops.world.combat.shots.size()
		observed_transit = observed_transit or ops.world.rear.shipment.cargo == 8
		if ops.world.rear.shipment.cargo > 0:
			conserved = conserved and ops.world.rear.shipment.request_id == "Request-B" and b.delivered == 0
	expect(conserved and observed_transit and b.delivered == 8 and a.delivered == 0, "Actual shipment/receiving/truck/Soldier path supplies B only and conserves all ammo each tick")
	ops.step(0.1)
	expect(ops.world.additional_supplies[0].phase == "Final approach" and ops.world.additional_supplies[0].resumed_at >= 0 and b.ready and ops.world.additional_supplies[0].carried() == 16 and ops.world.supply.phase == "Hold: ammunition shortage" and ops.world.supply.carried() == 8, "Physical B delivery alone restores ordinary readiness/support movement while A genuinely remains short")
	expect(not ops.set_priority("Request-B") and b.state == "SATISFIED", "Satisfied request no longer participates in allocation priority")
	expect(ops.alerts.entries.any(func(entry): return entry.type == "SHIPMENT_DELIVERED" and entry.source.contains("Request-B") and entry.text.contains("readiness restored")), "Delivery alert belongs to actually supplied B and reflects its real readiness")
	ops.world.rear.assign_worker(1, ops.world.elapsed)
	var second_started := false
	while a.delivered < 8 and ops.world.elapsed < 105 and ops.world.battle_active():
		ops.advance(1.0 / 60.0)
		second_started = second_started or ops.world.rear.produced == 16
		conserved = conserved and ops.world.total_ammunition() == ops.initial_ammo + ops.world.rear.produced - ops.world.combat.shots.size()
	expect(second_started and a.delivered == 8 and b.delivered == 8 and a.state == "SATISFIED" and b.state == "SATISFIED", "Second legitimate Worker batch reaches remaining A through its own ordinary physical chain")
	ops.step(0.1)
	expect(ops.world.supply.phase == "Final approach" and ops.world.supply.resumed_at > ops.world.additional_supplies[0].resumed_at and ops.world.rear.metal == 2 and ops.world.rear.produced == 16 and conserved, "B resumes first, A later; two Metal produce16 with global ammo conservation")
	var commitments: Array = ops.world.rear.ledger.filter(func(entry): return entry.reason == "Eligible demand committed; remains subset of rear on-hand")
	expect(commitments.size() == 2 and commitments[0].request_id == "Request-B" and commitments[1].request_id == "Request-A" and commitments[0].quantity == 8 and commitments[1].quantity == 8, "Commitment ledger retains unique B-then-A whole8 allocations")
	var status: Dictionary = ops.situation()
	expect(status.requests.size() == 2 and status.need.requested == 16 and status.need.delivered == 16 and status.requests[0].id == "Request-A" and status.requests[1].id == "Request-B" and status.requests.all(func(item): return item.remaining == 0), "Situation retains individual demand identity/state even when showing totals")
	status.requests[0].priority = "MODIFIED COPY"
	expect(a.priority == "PRIORITY", "Multi-demand projection is detached and cannot change allocation authority")
	evidence.append({"requests": ops.world.rear.requests.duplicate(true), "rear_ledger": ops.world.rear.ledger.duplicate(true), "supply_A": ops.world.supply.transactions.duplicate(true), "supply_B": ops.world.additional_supplies[0].transactions.duplicate(true), "initial_ammo": ops.initial_ammo, "final_ammo": ops.world.total_ammunition(), "produced": ops.world.rear.produced, "shots": ops.world.combat.shots.size()})
	var normal = scarce()
	normal.world.rear.requests.reverse()
	normal.world.rear.set_policy("AVAILABLE")
	expect(not normal.world.rear.commit(8, normal.world.elapsed), "Multi-demand direct commitment cannot bypass named request ownership")
	normal.advance(1.0 / 60.0)
	expect(request(normal, "Request-A").priority == "NORMAL" and request(normal, "Request-B").priority == "NORMAL" and normal.world.rear.commitment_request_id == "Request-A", "Equal NORMAL uses stable oldest real request creation order")
	var tie = scarce()
	request(tie, "Request-B").created_at = request(tie, "Request-A").created_at
	tie.world.rear.requests.reverse()
	tie.world.rear.set_policy("AVAILABLE")
	tie.advance(1.0 / 60.0)
	expect(tie.world.rear.commitment_request_id == "Request-A", "Equal-time NORMAL unit fixture uses stable creation sequence even with reversed record storage")
	var reserve = scarce()
	reserve.set_priority("Request-B")
	reserve.world.rear.set_policy("RESERVE", 8)
	reserve.world.rear.assign_worker(1)
	reserve.step(5)
	expect(reserve.world.rear.produced == 16 and reserve.world.rear.committed == 8 and reserve.world.rear.ammunition == 16 and reserve.world.rear.eligible() == 0 and request(reserve, "Request-B").allocated == 8 and request(reserve, "Request-A").allocated == 0, "Later production above Reserve8 permits priority allocation of eligible8 only")
	var finite = Ops.new()
	finite.step(12)
	finite.world.rear.place_workbench(Vector2(380, 480))
	finite.world.rear.assign_worker(2)
	finite.set_priority("Request-B")
	finite.world.rear.set_policy("AVAILABLE")
	finite.step(45)
	expect(finite.world.rear.produced == 16 and request(finite, "Request-A").delivered == 8 and request(finite, "Request-B").delivered == 8 and finite.world.rear.requests.all(func(item): return item.allocated == 8), "Existing finite2batch order can satisfy both demands without double allocation/repeat")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var file := FileAccess.open("res://artifacts/priority_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "evidence": evidence}, "\t", true, true))
	print("PRIORITY CHECKS: ", checks, " failures: ", failures)
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
	root.get_texture().get_image().save_png("res://artifacts/priority_" + name + ".png")

func visual_run() -> void:
	var view = load("res://priority_operations.tscn").instantiate()
	root.add_child(view)
	while not view.model.rear.requests.all(func(item): return item.requested == 8) and view.model.elapsed < 12:
		await create_timer(0.1).timeout
	await capture("01_two_genuine_requests")
	var a: Dictionary = request(view.operations, "Request-A")
	var b: Dictionary = request(view.operations, "Request-B")
	expect(a.requested == 8 and b.requested == 8 and a.remaining == 8 and b.remaining == 8, "Player-facing variant shows two genuine independent requests before work/priority")
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	key(KEY_F)
	while view.model.rear.ammunition < 8 and view.model.elapsed < 20:
		await create_timer(0.1).timeout
	await capture("02_one_batch_locked_two_waiting")
	expect(view.model.rear.ammunition == 8 and view.model.rear.committed == 0 and a.allocated == 0 and b.allocated == 0 and view.operations.alerts.primary().text.contains("choose logistics priority"), "One actual finite batch stays locked while multi-demand action suggests only logistics priority")
	click(Vector2(150, 345))
	await process_frame
	await capture("03_player_prioritizes_B_locked")
	expect(b.priority == "PRIORITY" and a.priority == "NORMAL" and view.model.rear.policy == "LOCKED" and view.model.rear.committed == 0, "Actual rear-only B priority control leaves global authorization authoritative")
	key(KEY_1)
	await create_timer(0.1).timeout
	await capture("04_available_commits_B_only")
	var assigned_shipment: String = view.model.rear.shipment.id
	expect(view.model.rear.committed == 8 and b.state == "COMMITTED" and a.state == "WAITING" and a.allocated == 0 and b.allocated == 8 and view.model.rear.commitment_request_id == "Request-B", "Actual AVAILABLE input commits exactly one batch to B without granting readiness")
	click(Vector2(150, 305))
	await process_frame
	await capture("05_A_priority_cannot_steal_B_commitment")
	expect(a.priority == "PRIORITY" and b.priority == "NORMAL" and view.model.rear.shipment.id == assigned_shipment and view.model.rear.shipment.request_id == "Request-B" and b.state == "COMMITTED", "Actual post-commit A priority click cannot reassign B's existing stock")
	while view.model.rear.shipment.cargo == 0 and view.model.elapsed < 25:
		await create_timer(0.05).timeout
	await capture("06_B_shipment_transit_A_waiting")
	expect(view.model.rear.shipment.cargo == 8 and b.state == "IN TRANSIT" and b.delivered == 0 and a.state == "WAITING", "B's assigned physical cargo travels while A remains honestly unresolved")
	key(KEY_TAB)
	await process_frame
	await capture("07_observe_physical_B_truck")
	while b.delivered < 8 and view.model.elapsed < 50:
		await create_timer(0.1).timeout
	await capture("08_B_delivered_A_still_short")
	expect(b.delivered == 8 and b.ready and view.model.additional_supplies[0].phase == "Final approach" and a.delivered == 0 and a.remaining == 8 and view.model.supply.carried() == 8, "Normal physical B handoff releases only B through ordinary readiness while A stays short")
	key(KEY_TAB)
	await process_frame
	key(KEY_F)
	await create_timer(0.2).timeout
	await capture("09_second_real_worker_batch")
	expect(not view.model.rear.job.is_empty() and view.model.rear.produced == 8 and view.model.rear.metal == 2 and a.allocated == 0, "Explicit later ordinary Worker batch consumes its own second Metal before any A allocation")
	while view.model.rear.produced < 16 and view.model.elapsed < 60:
		await create_timer(0.1).timeout
	await capture("10_second_batch_assigned_A")
	expect(view.model.rear.produced == 16 and a.allocated == 8 and a.state == "COMMITTED" and b.state == "SATISFIED" and view.model.rear.commitment_request_id == "Request-A", "Second real output commits to remaining A, preserving B's fulfilled request identity")
	key(KEY_TAB)
	await process_frame
	while a.delivered < 8 and view.model.elapsed < 85:
		await create_timer(0.1).timeout
	await capture("11_A_physical_delivery_both_fulfilled")
	expect(a.delivered == 8 and b.delivered == 8 and view.model.supply.phase == "Final approach" and view.model.supply.resumed_at > view.model.additional_supplies[0].resumed_at, "A later receives real physical supply and autonomously resumes after B")
	key(KEY_TAB)
	await process_frame
	await capture("12_fulfilled_identity_conservation")
	expect(view.model.total_ammunition() == view.operations.initial_ammo + view.model.rear.produced - view.model.combat.shots.size() and view.model.rear.metal == 2 and a.state == "SATISFIED" and b.state == "SATISFIED", "Actual-input final view retains both fulfilled requests and conservative16-round production accounting")
	evidence.append({"renderer_requests": view.model.rear.requests.duplicate(true), "ledger": view.model.rear.ledger.duplicate(true), "priority_history": view.model.rear.priority_history.duplicate(true)})
