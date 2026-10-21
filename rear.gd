extends RefCounted

const CATEGORY := "BoltActionRifleAmmo"
const MAP := Rect2(24, 105, 888, 645)
const RAW_STORE := Rect2(80, 150, 150, 100)
const DISPATCH := Rect2(730, 200, 100, 100)
const JOB_DURATION := 4.0
const LOADING_DELAY := 2.0
const TRANSIT_DELAY := 3.0
var avatar := Vector2(330, 500)
var worker := {"id": "Worker-01", "position": Vector2(300, 400), "assigned": false, "eligible": true, "batches_remaining": 0}
var workbench := Vector2.ZERO
var placed := false
var capability_unlocked := true
var metal := 4
var ammunition := 0
var produced := 0
var job: Dictionary = {}
var next_job_id := 1
var production_history: Array[Dictionary] = []
var production_order: Dictionary = {}
var order_history: Array[Dictionary] = []
var next_order_id := 1
var world_time := 0.0
var multi_enabled := false
var requests: Array[Dictionary] = []
var request_context: Dictionary = {}
var priority_history: Array[Dictionary] = []
var commitment_request_id := ""
var next_shipment_id := 1
var policy := "LOCKED"
var reserve := 8
var committed := 0
var commitment_time := -1.0
var shipment := {"id": "rear-export-1", "cargo": 0, "owner": "none", "state": "None", "departed_at": -1.0, "arrives_at": -1.0}
var ledger: Array[Dictionary] = []
var consumable_receipts: Dictionary = {}
var message := "Press P, then click to place a workbench."

func place_workbench(point: Vector2) -> bool:
	if placed or not MAP.grow(-32).has_point(point) or RAW_STORE.grow(32).has_point(point) or DISPATCH.grow(32).has_point(point):
		message = "Invalid placement: keep clear of storage and map edges."
		return false
	if point.distance_to(avatar) < 28 or point.distance_to(worker.position) < 28:
		message = "Keep the workstation clear of people."
		return false
	workbench = point
	placed = true
	message = "Walk near the bench. E: manual batch; F: assign Worker-01."
	return true

func receive_consumable_grant(instance_id: String, card_id: String, quantity: int, now: float) -> bool:
	if instance_id.is_empty() or card_id.is_empty() or quantity <= 0 or consumable_receipts.has(instance_id):
		return false
	ammunition += quantity
	consumable_receipts[instance_id] = {"card": card_id, "quantity": quantity, "time": now}
	ledger.append({"time": now, "source": "campaign-consumable:" + card_id, "instance": instance_id,
		"destination": "rear-finished-stock", "quantity": quantity, "resource": CATEGORY,
		"ownership_before": "campaign-consumable", "ownership_after": "rear", "reason": "One-time consumable resource windfall"})
	return true

func start_job(producer: String, now: float) -> bool:
	if not capability_unlocked:
		message = "MISSING_CAPABILITY: BoltActionAmmoProduction"
		return false
	if not placed:
		message = "MISSING_WORKBENCH"
		return false
	if metal < 1:
		message = "MISSING_METAL"
		return false
	if not job.is_empty():
		message = "PRODUCTION_ALREADY_ACTIVE"
		return false
	if producer == "Avatar" and (avatar.distance_to(workbench) > 60 or worker.assigned):
		message = "Manual work needs proximity and an unassigned bench."
		return false
	if producer != "Avatar" and producer != worker.id:
		return false
	if producer == worker.id and (not worker.assigned or not worker.eligible or worker.batches_remaining <= 0 or worker.position.distance_to(workbench) > 35):
		return false
	metal -= 1
	job = {"id": "RearProduction-%02d" % next_job_id, "producer": producer, "started_at": now, "finishes_at": now + JOB_DURATION, "input_metal": 1}
	next_job_id += 1
	message = producer + " producing one eight-round batch."
	return true

func assign_worker(batch_count := 1, now := -1.0) -> bool:
	if batch_count not in [1, 2, 3] or not placed or worker.assigned or not job.is_empty():
		return false
	worker.assigned = true
	worker.batches_remaining = batch_count
	production_order = {"id": "WorkerOrder-%02d" % next_order_id, "recipe": "Metal1_to_Ammo8",
		"requested": batch_count, "completed": 0, "status": "QUEUED", "reason": "Approaching workbench",
		"assigned_worker": worker.id, "assigned_workstation": "AmmoWorkbench-01",
		"created_at": world_time if now < 0 else now, "stop_requested": false}
	next_order_id += 1
	record_order(world_time if now < 0 else now)
	message = "Worker-01 assigned %d finite batch(es)." % batch_count
	return true

func record_order(now: float) -> void:
	var event := production_order.duplicate(true)
	event["time"] = now
	order_history.append(event)

func order_status(status: String, reason: String, now: float) -> void:
	if production_order.status == status and production_order.reason == reason:
		return
	production_order.status = status
	production_order.reason = reason
	record_order(now)

func stop_worker(now := -1.0) -> bool:
	if production_order.is_empty() or production_order.status in ["COMPLETED", "STOPPED"]:
		return false
	production_order.stop_requested = true
	if not job.is_empty() and job.producer == worker.id:
		order_status("STOPPING", "Current batch finishes; no later batch", world_time if now < 0 else now)
	else:
		finish_order("STOPPED", world_time if now < 0 else now)
	return true

func finish_order(status: String, now: float) -> void:
	worker.assigned = false
	worker.batches_remaining = 0
	order_status(status, "No further batches scheduled", now)
	message = "Worker order %s: %d/%d complete; none scheduled." % [status, production_order.completed, production_order.requested]

func worker_requirement() -> String:
	if not capability_unlocked:
		return "MISSING_CAPABILITY"
	if not placed or production_order.assigned_workstation != "AmmoWorkbench-01":
		return "MISSING_WORKBENCH"
	if not worker.eligible or not worker.assigned or production_order.assigned_worker != worker.id:
		return "WORKER_UNAVAILABLE"
	return ""

func receive_metal(crate: Dictionary, quantity: int, now: float) -> bool:
	# Bounded delivery receipt: nearby cargo is ineligible until actual custody transfer.
	if quantity <= 0 or crate.get("owner", "") != "rear" or not RAW_STORE.has_point(crate.get("position", Vector2.ZERO)):
		return false
	if not crate.has("id") or not crate.has("inventory") or crate.inventory.get("Metal", 0) < quantity:
		return false
	crate.inventory.Metal -= quantity
	metal += quantity
	ledger.append({"time": now, "source": crate.id, "destination": "rear-raw-stock", "quantity": quantity,
		"resource": "Metal", "ownership_before": "rear", "ownership_after": "rear", "reason": "Physical raw-storage receipt"})
	return true

func move_avatar(direction: Vector2, delta: float) -> void:
	if not job.is_empty() and job.producer == "Avatar":
		return
	avatar += direction.limit_length() * 150 * delta
	avatar = avatar.clamp(MAP.position + Vector2(12, 12), MAP.end - Vector2(12, 12))

func register_request(identity: String, formation: String) -> void:
	if requests.any(func(request): return request.id == identity):
		return
	requests.append({"id": identity, "formation": formation, "created_at": -1.0, "sequence": requests.size(),
		"requested": 0, "delivered": 0, "remaining": 0, "priority": "NORMAL", "state": "AWAITING REQUEST",
		"allocated": 0, "allocated_priority": "", "committed_at": -1.0, "shipment_id": "", "carried": 0,
		"readiness": "", "ready": false})

func set_request_priority(identity: String, value := "PRIORITY") -> bool:
	if not multi_enabled or value not in ["NORMAL", "PRIORITY"]:
		return false
	var matches: Array = requests.filter(func(request): return request.id == identity and request.requested > request.delivered)
	if matches.is_empty() and not (identity.is_empty() and value == "NORMAL"):
		return false
	for request in requests:
		if request.requested <= request.delivered:
			continue
		if value == "PRIORITY" or identity.is_empty() or request.id == identity:
			request.priority = "PRIORITY" if value == "PRIORITY" and request.id == identity else "NORMAL"
	priority_history.append({"time": world_time, "request": identity, "priority": value})
	return true

func sync_requests(supplies: Array) -> void:
	for request in requests:
		for chain in supplies:
			if chain.request_id != request.id:
				continue
			if chain.requested_at >= 0 and request.created_at < 0:
				request.created_at = chain.requested_at
				request.requested = chain.REQUEST_QUANTITY
			var delivered := 0
			for event in chain.transactions:
				if event.reason == "Physical delivery at staging":
					delivered += int(event.quantity)
			request.delivered = mini(request.requested, delivered)
			request.remaining = maxi(0, request.requested - request.delivered)
			request.carried = chain.carried()
			request["supply_record_time"] = world_time
			request.readiness = chain.phase
			request.ready = chain.carried() >= chain.READY_THRESHOLD and chain.squad.mission_execution_available()
			if request.requested == 0:
				request.state = "AWAITING REQUEST"
			elif request.remaining == 0:
				request.state = "SATISFIED"
			elif request.allocated > 0:
				request.state = "COMMITTED" if committed > 0 and commitment_request_id == request.id else "IN TRANSIT"
			else:
				request.state = "WAITING"

func allocate_request(now: float) -> void:
	if committed > 0 or shipment.state not in ["None", "Arrived at battlefield receiving point"] or eligible() < 8:
		return
	var waiting: Array = requests.filter(func(request): return request.requested == 8 and request.remaining > 0 and request.allocated == 0)
	waiting.sort_custom(func(a, b):
		if a.priority != b.priority:
			return a.priority == "PRIORITY"
		return a.created_at < b.created_at if a.created_at != b.created_at else a.sequence < b.sequence)
	if waiting.is_empty():
		return
	var selected: Dictionary = waiting[0]
	# A serial export slot can be reused only after its prior cargo physically
	# reaches that request's receiving inventory. The request retains its allocation.
	shipment = {"id": "rear-export-%d" % next_shipment_id, "cargo": 0, "owner": "none", "state": "None", "departed_at": -1.0, "arrives_at": -1.0, "request_id": selected.id}
	next_shipment_id += 1
	if commit(8, now):
		commitment_request_id = selected.id
		selected.allocated = 8
		selected.allocated_priority = selected.priority
		selected.committed_at = now
		selected.shipment_id = shipment.id
		selected.state = "COMMITTED"
		ledger[-1]["request_id"] = selected.id

func set_policy(next_policy: String, floor_value := 8) -> void:
	if next_policy not in ["AVAILABLE", "RESERVE", "LOCKED"] or floor_value < 0:
		return
	policy = next_policy
	reserve = floor_value

func eligible() -> int:
	if policy == "LOCKED":
		return 0
	return maxi(0, ammunition - committed - (reserve if policy == "RESERVE" else 0))

func commit(quantity: int, now: float) -> bool:
	if multi_enabled and not requests.any(func(request): return request.id == shipment.get("request_id", "") and request.requested == quantity and request.remaining > 0 and request.allocated == 0):
		return false
	if quantity <= 0 or eligible() < quantity or committed > 0 or shipment.state != "None":
		return false
	committed = quantity
	commitment_time = now
	ledger.append({"time": now, "source": "rear-uncommitted", "destination": "rear-committed", "quantity": quantity, "ownership_before": "rear", "ownership_after": "rear", "reason": "Eligible demand committed; remains subset of rear on-hand"})
	return true

func advance(delta: float, now: float, supply, supplies: Array = []) -> void:
	world_time = now
	var completed_worker_batch := false
	if not job.is_empty() and now + 0.000001 >= job.finishes_at:
		ammunition += 8
		produced += 8
		production_history.append({"producer": job.producer, "started_at": job.started_at, "completed_at": job.finishes_at, "metal_consumed": 1, "ammo_produced": 8, "source": "rear-Metal", "destination": "rear-finished-ammo", "ownership_before": "rear", "ownership_after": "rear", "reason": "One Metal transformed into eight rounds by timed labor"})
		if job.producer == worker.id:
			worker.batches_remaining -= 1
			production_order.completed += 1
			completed_worker_batch = true
		job.clear()
		message = "Batch complete: eight rear-owned rounds."
		if completed_worker_batch:
			if production_order.stop_requested:
				finish_order("STOPPED", now)
			elif production_order.completed >= production_order.requested:
				finish_order("COMPLETED", now)
			else:
				order_status("QUEUED", "Next batch scheduled", now)
	# One world-tick boundary after completion allows an explicit between-batch stop.
	if worker.assigned and worker.batches_remaining > 0 and job.is_empty() and not completed_worker_batch:
		var requirement := worker_requirement()
		if not requirement.is_empty():
			order_status("BLOCKED_REQUIREMENT", requirement, now)
		elif metal < 1:
			order_status("BLOCKED_INPUT", "MISSING_METAL", now)
		else:
			worker.position = worker.position.move_toward(workbench + Vector2(-22, 0), 90 * delta)
			if worker.position.distance_to(workbench) <= 35 and start_job(worker.id, now):
				order_status("ACTIVE", "Current batch running", now)
			else:
				order_status("QUEUED", "Approaching workbench", now)
	if multi_enabled:
		sync_requests(supplies)
		allocate_request(now)
		for chain in supplies:
			if chain.request_id == shipment.get("request_id", ""):
				supply = chain
	elif supply.requested_at >= 0 and committed == 0 and shipment.state == "None":
		commit(8, now)
	if committed > 0 and now + 0.000001 >= commitment_time + LOADING_DELAY:
		var quantity := committed
		ammunition -= quantity
		committed = 0
		shipment.cargo = quantity
		shipment.owner = "military"
		shipment.state = "Inter-map transit"
		shipment.departed_at = commitment_time + LOADING_DELAY
		shipment.arrives_at = shipment.departed_at + TRANSIT_DELAY
		ledger.append({"time": shipment.departed_at, "source": "rear-finished-stock", "destination": shipment.id, "quantity": quantity, "ownership_before": "rear", "ownership_after": "military", "reason": "Departure across protected rear boundary"})
		if multi_enabled:
			ledger[-1]["request_id"] = shipment.request_id
	if shipment.state == "Inter-map transit" and now + 0.000001 >= shipment.arrives_at:
		var quantity: int = shipment.cargo
		supply.depot.inventory[CATEGORY] += quantity
		shipment.cargo = 0
		shipment.state = "Arrived at battlefield receiving point"
		ledger.append({"time": shipment.arrives_at, "source": shipment.id, "destination": supply.depot.id, "quantity": quantity, "ownership_before": "military", "ownership_after": "military", "reason": "Physical receiving after three-second map transit"})
		if multi_enabled:
			ledger[-1]["request_id"] = shipment.request_id
	if multi_enabled:
		sync_requests(supplies)
