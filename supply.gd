extends RefCounted

const CATEGORY := "BoltActionRifleAmmo"
const SHARE_RADIUS := 42.0
const READY_THRESHOLD := 16
const REQUEST_QUANTITY := 8
const DELIVERY_RADIUS := 70.0
const DEPOT_POSITION := Vector2(100, 125)
const RESUPPLY_POSITION := Vector2(350, 200)
const CAPTURE_POSITION := Vector2(735, 290)
var squad
var depot := {"id": "military-depot", "inventory": {CATEGORY: 12}}
var truck = {"id": "military-truck", "inventory": {CATEGORY: 0}, "position": DEPOT_POSITION, "state": "At depot"}
var captured := {"id": "enemy-ammo-container", "owner": "enemy", "inventory": {CATEGORY: 4}}
var phase := "Approach staging"
var transactions: Array[Dictionary] = []
var events: Array[Dictionary] = []
var shared := false
var requested_at := -1.0
var delivered_at := -1.0
var resumed_at := -1.0
var captured_at := -1.0
var now := 0.0
var requires_rear := false
var vehicle_controller
var request_id := ""

func _init(advancing_squad, rear_required := false, stage_at_receiving := false) -> void:
	squad = advancing_squad
	requires_rear = rear_required
	if requires_rear:
		depot.inventory[CATEGORY] = 0
		captured.inventory[CATEGORY] = 0
	var initial := [0, 6, 1, 1]
	for index in range(4):
		squad.soldiers[index].inventory[CATEGORY] = initial[index]
	if stage_at_receiving:
		# A newly authored receiving formation stages at the actual truck handoff
		# point, retaining its existing mission path for ordinary readiness release.
		for index in range(squad.soldiers.size()):
			squad.soldiers[index].path.push_front(RESUPPLY_POSITION + Vector2((index % 2) * 23 - 12, (index / 2) * 23 - 12))
	squad.stage_for_supply()

func carried() -> int:
	return squad.carried_ammunition(CATEGORY)

func total_accounted() -> int:
	var total: int = depot.inventory[CATEGORY] + truck.inventory[CATEGORY] + captured.inventory[CATEGORY]
	for soldier in squad.soldiers:
		total += int(soldier.inventory.get(CATEGORY, 0))
	return total

func compatible(soldier, category: String) -> bool:
	return soldier.weapon_category == "BoltActionRifle" and category == CATEGORY

func transfer(source_id: String, source: Dictionary, recipient_id: String, recipient: Dictionary, quantity: int, reason: String) -> int:
	if quantity <= 0 or int(source.get(CATEGORY, 0)) < quantity:
		return 0
	source[CATEGORY] -= quantity
	recipient[CATEGORY] = int(recipient.get(CATEGORY, 0)) + quantity
	transactions.append({"source": source_id, "quantity": quantity, "destination": recipient_id, "time": now, "category": CATEGORY, "ownership_before": "enemy" if source_id == captured.id else "military", "ownership_after": "military", "reason": reason})
	print("SUPPLY TRANSFER: ", JSON.stringify(transactions.back()))
	return quantity

func share(donor, recipient) -> bool:
	if not donor.active or not recipient.active or donor.position.distance_to(recipient.position) > SHARE_RADIUS:
		return false
	if not compatible(recipient, CATEGORY) or not compatible(donor, CATEGORY):
		return false
	if recipient.inventory[CATEGORY] != 0 or donor.inventory[CATEGORY] < 4:
		return false
	return transfer(donor.id, donor.inventory, recipient.id, recipient.inventory, 2, "Nearby squadmate sharing") == 2

func record(choice: String, reason: String) -> void:
	events.append({"time": now, "actor": squad.id, "choice": choice, "reason": reason, "carried": carried()})
	print("SUPPLY DECISION: ", JSON.stringify(events.back()))

func advance(delta: float, time: float) -> void:
	now = time
	if not shared and now >= 1:
		shared = share(squad.soldiers[1], squad.soldiers[0])
	if phase == "Approach staging" and squad.complete():
		phase = "Hold: ammunition shortage"
		record("Hold final approach", "Carried ammunition below sixteen-round fixture threshold")
	if phase == "Hold: ammunition shortage":
		if carried() >= READY_THRESHOLD and squad.mission_execution_available():
			phase = "Final approach"
			resumed_at = now
			squad.resume_final_approach()
			record("Resume final approach", "Readiness satisfied by ammunition in actual member inventories")
		elif requested_at < 0 and carried() < READY_THRESHOLD:
			requested_at = now
			record("Request eight rounds", "After local sharing, only eight rounds physically carried")
			if requires_rear:
				record("Forward request to rear", "Receiving point empty; player authorization and physical export required")
			else:
				record("Company approves allocation", "Finite military depot can supply eight; approval does not transfer custody")
	if requested_at >= 0 and now >= requested_at + 1 and truck.state == "At depot":
		if transfer(depot.id, depot.inventory, truck.id, truck.inventory, REQUEST_QUANTITY, "Load approved military shipment") == REQUEST_QUANTITY:
			truck.state = "In transit"
	if truck.state == "In transit":
		if vehicle_controller != null:
			vehicle_controller.get_ref().advance(delta, now)
		else:
			truck.position = truck.position.move_toward(RESUPPLY_POSITION, 48 * delta)
		var physical_arrival: bool = truck.position == RESUPPLY_POSITION
		if vehicle_controller != null:
			physical_arrival = physical_arrival and truck.route_state == "ARRIVED"
		if physical_arrival:
			truck.state = "At staging"
	if truck.state == "At staging":
		for unit in range(truck.inventory[CATEGORY]):
			var recipient = null
			for soldier in squad.soldiers:
				if soldier.active and compatible(soldier, CATEGORY) and soldier.position.distance_to(truck.position) <= DELIVERY_RADIUS:
					if recipient == null or soldier.inventory[CATEGORY] < recipient.inventory[CATEGORY]:
						recipient = soldier
			if recipient == null:
				break
			transfer(truck.id, truck.inventory, recipient.id, recipient.inventory, 1, "Physical delivery at staging")
		if truck.inventory[CATEGORY] == 0:
			truck.state = "Delivered"
			delivered_at = now
	if captured.inventory[CATEGORY] > 0 and phase == "Final approach":
		for soldier in squad.soldiers:
			if soldier.active and compatible(soldier, CATEGORY) and soldier.position.distance_to(CAPTURE_POSITION) <= 40:
				transfer(captured.id, captured.inventory, soldier.id, soldier.inventory, captured.inventory[CATEGORY], "Secured nearby enemy ammunition recovered without conversion")
				captured.owner = "friendly (empty recovered container)"
				captured_at = now
				break
