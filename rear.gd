extends RefCounted

const CATEGORY := "BoltActionRifleAmmo"
const MAP := Rect2(24, 105, 888, 645)
const RAW_STORE := Rect2(80, 150, 150, 100)
const DISPATCH := Rect2(730, 200, 100, 100)
const JOB_DURATION := 4.0
const LOADING_DELAY := 2.0
const TRANSIT_DELAY := 3.0
var avatar := Vector2(330, 500)
var worker := {"id": "Worker-01", "position": Vector2(300, 400), "assigned": false, "batches_remaining": 0}
var workbench := Vector2.ZERO
var placed := false
var capability_unlocked := true
var metal := 4
var ammunition := 0
var produced := 0
var job: Dictionary = {}
var next_job_id := 1
var production_history: Array[Dictionary] = []
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
	if producer == worker.id and (not worker.assigned or worker.position.distance_to(workbench) > 35):
		return false
	metal -= 1
	job = {"id": "RearProduction-%02d" % next_job_id, "producer": producer, "started_at": now, "finishes_at": now + JOB_DURATION, "input_metal": 1}
	next_job_id += 1
	message = producer + " producing one eight-round batch."
	return true

func assign_worker() -> bool:
	if not placed or worker.assigned or not job.is_empty():
		return false
	worker.assigned = true
	# One explicit batch work order proves automation without silently spending
	# all four starting inputs. Worker identity/assignment remains persistent.
	worker.batches_remaining = 1
	message = "Worker-01 assigned one automatic batch."
	return true

func move_avatar(direction: Vector2, delta: float) -> void:
	if not job.is_empty() and job.producer == "Avatar":
		return
	avatar += direction.limit_length() * 150 * delta
	avatar = avatar.clamp(MAP.position + Vector2(12, 12), MAP.end - Vector2(12, 12))

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
	if quantity <= 0 or eligible() < quantity or committed > 0 or shipment.state != "None":
		return false
	committed = quantity
	commitment_time = now
	ledger.append({"time": now, "source": "rear-uncommitted", "destination": "rear-committed", "quantity": quantity, "ownership_before": "rear", "ownership_after": "rear", "reason": "Eligible demand committed; remains subset of rear on-hand"})
	return true

func advance(delta: float, now: float, supply) -> void:
	if not job.is_empty() and now + 0.000001 >= job.finishes_at:
		ammunition += 8
		produced += 8
		production_history.append({"producer": job.producer, "started_at": job.started_at, "completed_at": job.finishes_at, "metal_consumed": 1, "ammo_produced": 8, "source": "rear-Metal", "destination": "rear-finished-ammo", "ownership_before": "rear", "ownership_after": "rear", "reason": "One Metal transformed into eight rounds by timed labor"})
		if job.producer == worker.id:
			worker.batches_remaining -= 1
		job.clear()
		message = "Batch complete: eight rear-owned rounds."
	if worker.assigned and worker.batches_remaining > 0:
		worker.position = worker.position.move_toward(workbench + Vector2(-22, 0), 90 * delta)
		if job.is_empty() and worker.position.distance_to(workbench) <= 35:
			start_job(worker.id, now)
	if supply.requested_at >= 0 and committed == 0 and shipment.state == "None":
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
	if shipment.state == "Inter-map transit" and now + 0.000001 >= shipment.arrives_at:
		var quantity: int = shipment.cargo
		supply.depot.inventory[CATEGORY] += quantity
		shipment.cargo = 0
		shipment.state = "Arrived at battlefield receiving point"
		ledger.append({"time": shipment.arrives_at, "source": shipment.id, "destination": supply.depot.id, "quantity": quantity, "ownership_before": "military", "ownership_after": "military", "reason": "Physical receiving after three-second map transit"})
