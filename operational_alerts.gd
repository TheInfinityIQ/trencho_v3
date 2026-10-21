extends RefCounted

const Situation = preload("res://situation.gd")
const LIMIT := 8
var entries: Array[Dictionary] = []
var next_id := 1
var previous_block := ""
var completed_order := ""
var previous_authorization := ""
var delivered := 0
var delivered_requests: Dictionary = {}
var contact_observations: Dictionary = {}
var previous_result := "ACTIVE"
const CLASSES := {"PRODUCTION_BLOCKED": "ACTION_REQUIRED", "STOCK_AUTHORIZATION": "ACTION_REQUIRED",
	"PRODUCTION_COMPLETED": "INFORMATION", "SHIPMENT_DELIVERED": "INFORMATION",
	"COMPANY_CONTACT": "INFORMATION", "BATTLE_RESULT": "RESULT"}

func _init(world) -> void:
	# Attaching presentation to an existing world establishes a baseline. It does
	# not replay settled history as live events, including after a future load.
	var status: Dictionary = Situation.build(world)
	previous_block = blocked_key(status.work.order)
	if not status.work.order.is_empty() and status.work.order.status == "COMPLETED":
		completed_order = status.work.order.id
	previous_authorization = authorization_key(status)
	delivered = status.need.delivered
	for request in status.get("requests", []):
		delivered_requests[request.id] = request.delivered
	previous_result = world.battle_state
	for row in status.contacts:
		contact_observations[row.report.get("contact_id", row.report.report_id)] = row.report.observation_time

func blocked_key(order: Dictionary) -> String:
	if order.is_empty() or not order.status.begins_with("BLOCKED"):
		return ""
	return order.id

func authorization_key(status: Dictionary) -> String:
	if status.need.remaining <= 0:
		return ""
	if status.chain.stage == "WITHHELD — LOCKED":
		return "LOCKED"
	if status.chain.stage == "WITHHELD — RESERVE FLOOR":
		return "RESERVE FLOOR"
	return ""

func emit_alert(type: String, now: float, text: String, source: String, area: String, provenance: Array = [], condition := "") -> void:
	entries.append({"id": "OperationalAlert-%03d" % next_id, "type": type, "time": now,
		"text": text, "acknowledged": false, "source": source, "area": area, "provenance": provenance.duplicate(true),
		"class": CLASSES[type], "state": "OPEN" if CLASSES[type] == "ACTION_REQUIRED" else "EVENT",
		"condition": condition, "sequence": next_id, "first_time": now, "update_count": 1,
		"resolved_at": -1.0, "resolution": "", "updated_at": now})
	next_id += 1
	trim_history()

func protected(entry: Dictionary) -> bool:
	return (entry["class"] == "ACTION_REQUIRED" and entry.state == "OPEN") or (entry["class"] == "RESULT" and (not entry.acknowledged or previous_result != "ACTIVE"))

func newer(a: Dictionary, b: Dictionary) -> bool:
	return a.time > b.time if a.time != b.time else a.sequence > b.sequence

func history_count() -> int:
	return entries.filter(func(entry): return not protected(entry)).size()

func trim_history() -> void:
	var history: Array = entries.filter(func(entry): return not protected(entry))
	# A just-resolved action enters bounded history as a current presentation
	# change, retaining its original alert time and separate resolution time.
	history.sort_custom(func(a, b):
		var a_time: float = maxf(a.time, a.resolved_at)
		var b_time: float = maxf(b.time, b.resolved_at)
		return a_time > b_time if a_time != b_time else a.sequence > b.sequence)
	var retained: Array = history.slice(0, LIMIT).map(func(entry): return entry.id)
	entries.assign(entries.filter(func(entry): return protected(entry) or entry.id in retained))

func resolve_condition(type: String, current: String, now: float, explanation: String) -> void:
	for entry in entries:
		if entry.type == type and entry.state == "OPEN" and entry.condition != current:
			entry.state = "RESOLVED"
			entry.resolved_at = now
			entry.resolution = "RESOLVED — " + explanation

func refresh_open(type: String, condition: String, text: String, now: float) -> void:
	for entry in entries:
		if entry.type == type and entry.state == "OPEN" and entry.condition == condition and entry.text != text:
			entry.text = text
			entry.updated_at = now

func company_report(report: Dictionary, now: float) -> void:
	var identity: String = report.get("contact_id", report.report_id)
	for entry in entries:
		if entry.type == "COMPANY_CONTACT" and not entry.acknowledged and entry.get("contact_id", "") == identity:
			entry.time = now
			entry.update_count += 1
			entry.provenance = [report.duplicate(true)]
			entry.source = "Company / " + report.observer
			entry.text = "Contact update ×%d — observed T%.1f / Company T%.1f" % [entry.update_count, report.observation_time, report.received_at]
			return
	emit_alert("COMPANY_CONTACT", now, "New Company contact report received", "Company / " + report.observer, "BATTLEFIELD", [report])
	entries[-1]["contact_id"] = identity

func update(world) -> void:
	if world.information.reconstructing:
		return
	var status: Dictionary = Situation.build(world)
	var order: Dictionary = status.work.order
	var block := blocked_key(order)
	var resolution := "Production no longer blocked"
	if not order.is_empty():
		resolution = {"ACTIVE": "Production resumed", "QUEUED": "Production resumed", "COMPLETED": "Production order completed", "STOPPED": "Production stopped"}.get(order.status, resolution)
	resolve_condition("PRODUCTION_BLOCKED", block, world.elapsed, resolution)
	# Explicit type sequence gives stable ordering for simultaneous boundaries.
	if not block.is_empty():
		var reason: String = {"MISSING_METAL": "Metal required", "MISSING_WORKBENCH": "workstation unavailable",
			"MISSING_CAPABILITY": "production capability unavailable", "WORKER_UNAVAILABLE": "Worker unavailable"}.get(order.reason, "requirement unavailable")
		if block != previous_block:
			emit_alert("PRODUCTION_BLOCKED", world.elapsed, "Production blocked — " + reason, order.id, "REAR", [], block)
		else:
			refresh_open("PRODUCTION_BLOCKED", block, "Production blocked — " + reason, world.elapsed)
	previous_block = block
	if not order.is_empty() and order.status == "COMPLETED" and order.id != completed_order:
		emit_alert("PRODUCTION_COMPLETED", world.elapsed, "Production order complete — %d rounds produced" % (order.completed * 8), order.id, "REAR")
		completed_order = order.id
	var authorization := authorization_key(status)
	resolve_condition("STOCK_AUTHORIZATION", "AUTHORIZATION_BLOCK" if not authorization.is_empty() else "", world.elapsed, "Request supplied" if status.need.remaining == 0 else ("Stock authorization eligible" if status.stock.eligible > 0 else "Previous stock/request block cleared"))
	if not authorization.is_empty():
		var text := "%d rounds ready, but military draw is %s" % [status.stock.uncommitted, authorization]
		var competing: Array = status.get("requests", []).filter(func(request): return request.state == "WAITING")
		if competing.size() > 1:
			var chosen: Array = competing.filter(func(request): return request.priority == "PRIORITY")
			text = "%d ammunition requests waiting — %s / draw %s" % [competing.size(), "choose logistics priority" if chosen.is_empty() else chosen[0].id + " PRIORITY", authorization]
		if previous_authorization.is_empty():
			emit_alert("STOCK_AUTHORIZATION", world.elapsed, text, "Rear stock policy / unresolved request", "REAR", [], "AUTHORIZATION_BLOCK")
		else:
			refresh_open("STOCK_AUTHORIZATION", "AUTHORIZATION_BLOCK", text, world.elapsed)
	previous_authorization = authorization
	if not status.get("requests", []).is_empty():
		for request in status.requests:
			if request.requested > 0 and request.delivered >= request.requested and delivered_requests.get(request.id, 0) < request.requested:
				emit_alert("SHIPMENT_DELIVERED", world.elapsed, "%s ammunition delivered — %s" % [request.id, "formation readiness restored" if request.ready else "request supplied; formation still constrained"], "Physical Soldier handoff / " + request.id, "BATTLEFIELD", [request])
			delivered_requests[request.id] = request.delivered
	elif status.need.delivered >= world.supply.REQUEST_QUANTITY and delivered < world.supply.REQUEST_QUANTITY:
		var ready: bool = world.supply.carried() >= world.supply.READY_THRESHOLD and world.supply.squad.mission_execution_available()
		emit_alert("SHIPMENT_DELIVERED", world.elapsed, "Ammunition delivered — " + ("formation readiness restored" if ready else "request supplied; formation still constrained"), "Physical Soldier handoff ledger", "BATTLEFIELD")
	delivered = status.need.delivered
	var reports: Array = status.contacts.map(func(row): return row.report)
	reports.sort_custom(func(a, b): return a.report_id < b.report_id)
	for report in reports:
		var identity: String = report.get("contact_id", report.report_id)
		if report.observation_time > contact_observations.get(identity, -1.0):
			company_report(report, world.elapsed)
			contact_observations[identity] = report.observation_time
	if world.battle_state != previous_result and not world.battle_active():
		emit_alert("BATTLE_RESULT", world.battle.terminal_time, "Battle ended — " + ("victory" if world.battle_state == "ENDED_FRIENDLY_VICTORY" else "defeat"), "Established battle result", "NONE")
	previous_result = world.battle_state
	trim_history()

func acknowledge(identity: String) -> bool:
	for entry in entries:
		if entry.id == identity:
			entry.acknowledged = true
			trim_history()
			return true
	return false

func unread_count() -> int:
	return entries.filter(func(entry): return not entry.acknowledged).size()

func newest_unread() -> Dictionary:
	var unread: Array = entries.filter(func(entry): return not entry.acknowledged)
	unread.sort_custom(newer)
	if not unread.is_empty():
		return unread[0].duplicate(true)
	return {}

func recent() -> Array[Dictionary]:
	return entries.duplicate(true)

func ranked() -> Array[Dictionary]:
	var result := recent()
	var rank := {"RESULT": 3, "ACTION_REQUIRED": 2, "INFORMATION": 1}
	result.sort_custom(func(a, b): return rank[a["class"]] > rank[b["class"]] if a["class"] != b["class"] else newer(a, b))
	return result

func primary() -> Dictionary:
	var ordered := ranked()
	# At battle end, acknowledging the result clears its badge, not the latched
	# terminal context. Frozen operational problems cannot become the headline.
	if previous_result != "ACTIVE":
		for entry in ordered:
			if entry["class"] == "RESULT":
				return entry
	var unread: Array = ordered.filter(func(entry): return not entry.acknowledged)
	for entry in unread:
		if entry["class"] == "RESULT" or (entry["class"] == "ACTION_REQUIRED" and entry.state == "OPEN"):
			return entry
	for entry in unread:
		if entry["class"] == "INFORMATION":
			return entry
	return {} if unread.is_empty() else unread[0]

func counts() -> Dictionary:
	return {"action_open": entries.filter(func(entry): return entry["class"] == "ACTION_REQUIRED" and entry.state == "OPEN").size(),
		"action_unread": entries.filter(func(entry): return entry["class"] == "ACTION_REQUIRED" and entry.state == "OPEN" and not entry.acknowledged).size(),
		"information_unread": entries.filter(func(entry): return entry["class"] == "INFORMATION" and not entry.acknowledged).size(),
		"result_unread": entries.filter(func(entry): return entry["class"] == "RESULT" and not entry.acknowledged).size()}
