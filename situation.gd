extends RefCounted

static func freshness(age: float) -> String:
	return "RECENT" if age <= 5 else ("AGING" if age <= 15 else "STALE")

static func latest_contacts(world) -> Array:
	var latest := {}
	for report in world.information.company_contact_snapshot():
		var identity: String = report.get("contact_id", report.report_id)
		if not latest.has(identity) or report.observation_time > latest[identity].observation_time:
			latest[identity] = report.duplicate(true)
	return latest.values()

static func contacts(world) -> Array:
	var result: Array = []
	for report in latest_contacts(world):
		var age: float = maxf(0, world.elapsed - report.observation_time)
		result.append({"report": report, "age": age, "freshness": freshness(age), "label": "LAST KNOWN", "provenance": "Company / " + report.observer})
	return result

static func inquiry(records: Array, queried: bool) -> String:
	if not queried:
		return "NOT INSPECTED"
	if records.is_empty():
		return "UNKNOWN — no established HQ report"
	if records.any(func(record): return record.get("facts", []) == ["explosion", "friendly casualty"]):
		return "CONFIRMED HISTORY — source unknown"
	return "PARTIAL / LAST KNOWN — limited report"

static func build(world) -> Dictionary:
	var rear = world.rear
	var supply = world.supply
	var requested: int = supply.REQUEST_QUANTITY if supply.requested_at >= 0 else 0
	var delivered := 0
	for event in supply.transactions:
		if event.reason == "Physical delivery at staging":
			delivered += int(event.quantity)
	delivered = mini(requested, delivered)
	var request_state := "AWAITING REQUEST" if requested == 0 else ("SATISFIED" if delivered >= requested else ("PARTLY SUPPLIED" if delivered > 0 else "UNRESOLVED"))
	var uncommitted: int = maxi(0, rear.ammunition - rear.committed)
	var eligible: int = rear.eligible()
	var policy_text: String = "AVAILABLE — uncommitted stock may be drawn"
	if rear.policy == "LOCKED":
		policy_text = "LOCKED — military draw disabled"
	elif rear.policy == "RESERVE":
		policy_text = "RESERVE %d — %d protected; %d eligible" % [rear.reserve, mini(rear.reserve, uncommitted), eligible]
	var stage := "NO STOCK"
	var waiting := "No finished ammunition is available."
	var prompt := "Place a workbench in the protected rear."
	if rear.placed:
		prompt = "Start one ammunition batch in the rear."
	if rear.worker.assigned and rear.worker.batches_remaining > 0:
		prompt = "Worker assigned one batch — no player action required."
	if not rear.job.is_empty():
		prompt = "Production working — no player action required."
	if rear.metal < 1 and rear.job.is_empty() and rear.ammunition == 0:
		prompt = "No Metal for another batch — inspect existing supply."
	if rear.ammunition > 0:
		stage = "AVAILABLE FOR COMMITMENT"
		waiting = "Stock is eligible for the military request."
		prompt = "Stock available — observe the supply chain."
		if rear.policy == "LOCKED":
			stage = "WITHHELD — LOCKED"
			waiting = "Finished stock exists; military draw is disabled."
			prompt = "Rounds ready but LOCKED — authorize stock in the rear."
		elif rear.policy == "RESERVE" and eligible == 0 and rear.committed == 0:
			stage = "WITHHELD — RESERVE FLOOR"
			waiting = "Reserve protects the stock; 0 rounds eligible to commit."
			prompt = "Reserve protects all stock — review rear authorization."
	if rear.committed > 0:
		var loading_elapsed: float = maxf(0, world.elapsed - rear.commitment_time)
		stage = "COMMITTED" if loading_elapsed <= 0.000001 else "LOADING"
		waiting = "Loading %.1fs / 2s — stock remains rear-owned." % loading_elapsed
		prompt = "Shipment loading — no player action required."
	if rear.shipment.cargo > 0:
		stage = "IN TRANSIT"
		waiting = "Military shipment travelling to receiving."
		prompt = "Shipment in transit — observe the battlefield."
	if supply.depot.inventory.BoltActionRifleAmmo > 0:
		stage = "AT RECEIVING DEPOT"
		waiting = "Received by military; normal truck loading follows."
		prompt = "Supply at receiving — no player action required."
	if supply.truck.inventory.BoltActionRifleAmmo > 0:
		stage = "ON TRUCK"
		waiting = "Truck: " + supply.truck.route_state + ". Cargo is not yet Soldier supply."
		prompt = "Truck delivery in progress — observe the battlefield."
	if requested > 0 and delivered >= requested:
		stage = "DELIVERED"
		waiting = "Physical Soldier handoff completed."
		prompt = "Supply delivered — formation continuing autonomously."
	if not world.battle_active():
		prompt = "Battle ended — inspect the frozen aftermath."
	var work := "IDLE — no batch running"
	var progress := 0.0
	if not rear.job.is_empty():
		progress = clampf(world.elapsed - rear.job.started_at, 0, rear.JOB_DURATION)
		work = ("MANUAL" if rear.job.producer == "Avatar" else "WORKER") + " %.1f / 4s" % progress
	elif rear.worker.assigned and rear.worker.batches_remaining > 0:
		work = "WORKER BATCH WAITING / APPROACHING"
	elif not rear.production_history.is_empty():
		work = "BATCH COMPLETE — no further work scheduled"
	var worker := "UNASSIGNED"
	if rear.worker.assigned:
		if rear.worker.batches_remaining == 0:
			worker = "ONE BATCH COMPLETE — none scheduled"
		elif not rear.job.is_empty() and rear.job.producer == rear.worker.id:
			worker = "ONE BATCH ACTIVE"
		else:
			worker = "ONE BATCH ASSIGNED — approaching/waiting"
	var reports := contacts(world)
	var receipt_time := -1.0
	for report in world.information.company_contact_snapshot():
		receipt_time = maxf(receipt_time, report.received_at)
	var report_activity := "Company: no contact report received yet"
	if receipt_time >= 0:
		report_activity = "Company knowledge updated T%.1f" % receipt_time if world.elapsed - receipt_time <= 1 else "Company: last receipt T%.1f; no newer report received" % receipt_time
	return {"need": {"requested": requested, "delivered": delivered, "remaining": maxi(0, requested - delivered), "state": request_state, "carried": supply.carried(), "readiness": supply.phase},
		"stock": {"finished": rear.ammunition, "uncommitted": uncommitted, "eligible": eligible, "committed": rear.committed, "policy": rear.policy, "reserve": rear.reserve, "explanation": policy_text},
		"chain": {"stage": stage, "explanation": waiting}, "work": {"bench": rear.placed, "state": work, "progress": progress, "worker": worker},
		"contacts": reports, "report_activity": report_activity, "prompt": prompt}
