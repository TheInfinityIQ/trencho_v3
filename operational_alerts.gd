extends RefCounted

const Situation = preload("res://situation.gd")
const LIMIT := 8
var entries: Array[Dictionary] = []
var next_id := 1
var previous_block := ""
var completed_order := ""
var previous_authorization := ""
var delivered := 0
var contact_observations: Dictionary = {}
var previous_result := "ACTIVE"

func _init(world) -> void:
	# Attaching presentation to an existing world establishes a baseline. It does
	# not replay settled history as live events, including after a future load.
	var status: Dictionary = Situation.build(world)
	previous_block = blocked_key(status.work.order)
	if not status.work.order.is_empty() and status.work.order.status == "COMPLETED":
		completed_order = status.work.order.id
	previous_authorization = authorization_key(status)
	delivered = status.need.delivered
	previous_result = world.battle_state
	for row in status.contacts:
		contact_observations[row.report.get("contact_id", row.report.report_id)] = row.report.observation_time

func blocked_key(order: Dictionary) -> String:
	if order.is_empty() or not order.status.begins_with("BLOCKED"):
		return ""
	return order.id + ":" + order.reason

func authorization_key(status: Dictionary) -> String:
	if status.need.remaining <= 0:
		return ""
	if status.chain.stage == "WITHHELD — LOCKED":
		return "LOCKED"
	if status.chain.stage == "WITHHELD — RESERVE FLOOR":
		return "RESERVE FLOOR"
	return ""

func emit_alert(type: String, now: float, text: String, source: String, area: String, provenance: Array = []) -> void:
	entries.append({"id": "OperationalAlert-%03d" % next_id, "type": type, "time": now,
		"text": text, "acknowledged": false, "source": source, "area": area, "provenance": provenance.duplicate(true)})
	next_id += 1
	if entries.size() > LIMIT:
		entries.pop_front()

func update(world) -> void:
	if world.information.reconstructing:
		return
	var status: Dictionary = Situation.build(world)
	var order: Dictionary = status.work.order
	var block := blocked_key(order)
	# Explicit type sequence gives stable ordering for simultaneous boundaries.
	if not block.is_empty() and block != previous_block:
		var reason: String = {"MISSING_METAL": "Metal required", "MISSING_WORKBENCH": "workstation unavailable",
			"MISSING_CAPABILITY": "production capability unavailable", "WORKER_UNAVAILABLE": "Worker unavailable"}.get(order.reason, "requirement unavailable")
		emit_alert("PRODUCTION_BLOCKED", world.elapsed, "Production blocked — " + reason, order.id, "REAR")
	previous_block = block
	if not order.is_empty() and order.status == "COMPLETED" and order.id != completed_order:
		emit_alert("PRODUCTION_COMPLETED", world.elapsed, "Production order complete — %d rounds produced" % (order.completed * 8), order.id, "REAR")
		completed_order = order.id
	var authorization := authorization_key(status)
	if not authorization.is_empty() and authorization != previous_authorization:
		emit_alert("STOCK_AUTHORIZATION", world.elapsed, "%d rounds ready, but military draw is %s" % [status.stock.uncommitted, authorization], "Rear stock policy / unresolved request", "REAR")
	previous_authorization = authorization
	if status.need.delivered >= world.supply.REQUEST_QUANTITY and delivered < world.supply.REQUEST_QUANTITY:
		var ready: bool = world.supply.carried() >= world.supply.READY_THRESHOLD and world.supply.squad.mission_execution_available()
		emit_alert("SHIPMENT_DELIVERED", world.elapsed, "Ammunition delivered — " + ("formation readiness restored" if ready else "request supplied; formation still constrained"), "Physical Soldier handoff ledger", "BATTLEFIELD")
	delivered = status.need.delivered
	var reports: Array = status.contacts.map(func(row): return row.report)
	reports.sort_custom(func(a, b): return a.report_id < b.report_id)
	var received: Array = []
	for report in reports:
		var identity: String = report.get("contact_id", report.report_id)
		if report.observation_time > contact_observations.get(identity, -1.0):
			received.append(report.duplicate(true))
			contact_observations[identity] = report.observation_time
	if not received.is_empty():
		# Collapse same-tick Company receipts into one information-available alert.
		emit_alert("COMPANY_CONTACT", world.elapsed, "New Company contact report received", "Delivered Company knowledge", "BATTLEFIELD", received)
	if world.battle_state != previous_result and not world.battle_active():
		emit_alert("BATTLE_RESULT", world.battle.terminal_time, "Battle ended — " + ("victory" if world.battle_state == "ENDED_FRIENDLY_VICTORY" else "defeat"), "Established battle result", "NONE")
	previous_result = world.battle_state

func acknowledge(identity: String) -> bool:
	for entry in entries:
		if entry.id == identity:
			entry.acknowledged = true
			return true
	return false

func unread_count() -> int:
	return entries.filter(func(entry): return not entry.acknowledged).size()

func newest_unread() -> Dictionary:
	for index in range(entries.size() - 1, -1, -1):
		if not entries[index].acknowledged:
			return entries[index].duplicate(true)
	return {}

func recent() -> Array[Dictionary]:
	return entries.duplicate(true)
