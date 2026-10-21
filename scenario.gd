extends RefCounted

const Squad = preload("res://squad.gd")
const Information = preload("res://information.gd")
const Supply = preload("res://supply.gd")
const Rear = preload("res://rear.gd")
const Recovery = preload("res://recovery.gd")
const Combat = preload("res://combat.gd")
const VehicleRoutes = preload("res://vehicle_routes.gd")
const Artillery = preload("res://artillery.gd")
const Person = preload("res://soldier.gd")
const Engineering = preload("res://engineering.gd")
const Medical = preload("res://medical.gd")
const Battle = preload("res://battle.gd")
const OBSTACLE := Rect2(410, 245, 155, 225)
const OBJECTIVE := Vector2(815, 345)
var elapsed := 0.0
var trace: Array[Dictionary] = []
var squads: Array = []
var platoons: Array[Dictionary] = []
var secured := false
var information = Information.new()
var supply
var rear
var integrated_rear := false
var recovery
var combat
var vehicles
var artillery
var engineering
var medical
var battle
var battle_state: String:
	get:
		return battle.state if battle != null else "ACTIVE"

func battle_active() -> bool:
	return battle_state == "ACTIVE"

func _init(with_rear := false, with_combat := false, with_vehicles := false, with_artillery := false, with_engineering := false, with_infrastructure := false, with_medical := false, with_battle := false) -> void:
	integrated_rear = with_rear
	squads = [Squad.new("P1-A", Vector2(155, 300)), Squad.new("P1-B", Vector2(165, 420)),
		Squad.new("P2-A", Vector2(140, 610)), Squad.new("P2-B", Vector2(240, 610))]
	platoons = [{"id": "P1", "squads": [squads[0], squads[1]], "assignment": "Unassigned", "leader": Person.new("P1-PL", Vector2(130, 280), 47), "follow_signature": ""},
		{"id": "P2", "squads": [squads[2], squads[3]], "assignment": "Unassigned", "leader": Person.new("P2-PL", Vector2(110, 590), 47), "follow_signature": ""}]
	for platoon in platoons:
		platoon.leader.formal_rank = "LIEUTENANT"
		platoon.leader.normal_role = "PlatoonLeader"
	for squad in squads:
		squad.terrain = OBSTACLE
	operational_decide()
	supply = Supply.new(squads[0], with_rear)
	if with_rear:
		rear = Rear.new()
	recovery = Recovery.new(squads[3].soldiers[3])
	if with_combat:
		combat = Combat.new(self)
	if with_vehicles:
		vehicles = VehicleRoutes.new(supply)
	if with_medical and combat != null:
		medical = Medical.new(self)
	if with_engineering:
		engineering = Engineering.new(not with_infrastructure)
	if with_infrastructure and vehicles != null and engineering != null:
		vehicles.configure_infrastructure()
		engineering.infrastructure_owner = weakref(vehicles)
		engineering.stockpile.inventory.BuildingMaterial = 4
		engineering.people[0].position = Vector2(130, 330)
		engineering.people[0].origin = engineering.people[0].position
	if with_artillery and combat != null:
		artillery = Artillery.new()
		# This explicit artillery fixture seed keeps the exposed comparison actors
		# alive until the blast; the independently accepted rifle fixture stays13.
		combat.friendly_random.seed = 4
		combat.solid_cover.append(Artillery.BLAST_WALL)
		var positions := [Vector2(790, 420), Vector2(825, 440), Vector2(790, 445), Vector2(855, 440)]
		for index in range(4):
			combat.defenders.soldiers[index].position = positions[index]
			combat.defenders.soldiers[index].origin = positions[index]
	if with_battle:
		battle = Battle.new(self)
		if artillery != null:
			artillery.battle_boundary = weakref(battle)

func blast_entities() -> Array:
	var result: Array = []
	for squad in squads + ([combat.defenders] if combat != null else []):
		for person in squad.soldiers:
			result.append({"person": person, "squad": squad})
	for platoon in platoons:
		result.append({"person": platoon.leader, "squad": null})
	if vehicles != null:
		for person in vehicles.drivers:
			result.append({"person": person, "squad": null})
	if artillery != null:
		result.append({"person": artillery.gunner, "squad": null})
	if engineering != null:
		for person in engineering.people:
			result.append({"person": person, "squad": null})
	if medical != null:
		result.append({"person": medical.medic, "squad": null})
	return result

func total_ammunition() -> int:
	var total: int = supply.depot.inventory[Supply.CATEGORY] + supply.truck.inventory[Supply.CATEGORY] + supply.captured.inventory[Supply.CATEGORY] + recovery.inventory[Supply.CATEGORY]
	for squad in squads:
		for soldier in squad.soldiers:
			total += int(soldier.inventory.get(Supply.CATEGORY, 0))
	for platoon in platoons:
		total += int(platoon.leader.inventory[Supply.CATEGORY])
	if integrated_rear:
		total += rear.ammunition + rear.shipment.cargo
	if combat != null:
		for soldier in combat.defenders.soldiers:
			total += int(soldier.inventory[Supply.CATEGORY])
	if vehicles != null:
		total += int(vehicles.tracked.inventory[Supply.CATEGORY])
		for driver in vehicles.drivers:
			total += int(driver.inventory[Supply.CATEGORY])
	if artillery != null:
		total += int(artillery.gunner.inventory[Supply.CATEGORY])
	if engineering != null:
		for person in engineering.people:
			total += int(person.inventory[Supply.CATEGORY])
	if medical != null:
		total += int(medical.medic.inventory[Supply.CATEGORY])
	return total

func record(echelon: String, actor: String, intent: String, choice: String, reason: String) -> void:
	trace.append({"echelon": echelon, "actor": actor, "intent": intent, "choice": choice, "reason": reason})

func operational_decide() -> void:
	record("Operational", "HQ", "Scenario objective set", "Secure Objective A", "Only strategic site supplied in this proof")
	company_receive("Secure Objective A", OBJECTIVE)

func company_receive(intent: String, target: Vector2) -> void:
	# Company chooses its closest platoon as main effort; preserves another force.
	var main_index := 0
	if platoons[1].squads[0].center().distance_to(target) < platoons[0].squads[0].center().distance_to(target):
		main_index = 1
	for index in range(platoons.size()):
		var assignment := "Main effort" if index == main_index else "Reserve"
		platoons[index].assignment = assignment
		record("Company", "C1", intent, "%s: %s" % [platoons[index].id, assignment], "Nearest platoon advances; retain staged capacity")
		platoon_receive(platoons[index], target)

func platoon_receive(platoon: Dictionary, target: Vector2) -> void:
	if not platoon.leader.active:
		return
	if platoon.assignment == "Reserve":
		record("Platoon", platoon.id, "Remain staged", "Both squads hold current positions", "Company retained this platoon; no release received")
		for squad in platoon.squads:
			squad.task = "Hold reserve"
		return
	var support := Vector2(335, 520)
	var jobs := ["Seize Objective A", "Stage in support"]
	var targets := [target, support]
	for index in range(2):
		var squad = platoon.squads[index]
		record("Platoon", platoon.id, "Main effort", "%s: %s" % [squad.id, jobs[index]], "Separate seizure and nearby support responsibilities")
		var local_decision: Dictionary = squad.assign(jobs[index], targets[index], OBSTACLE)
		if not local_decision.is_empty():
			trace.append(local_decision)
		for soldier in squad.soldiers:
			record("Soldier", soldier.id, jobs[index], "Execute own %d-point path" % soldier.path.size(), "Own position, speed and waypoint progress under squad intent")

func advance(delta: float) -> void:
	if information.reconstructing or not battle_active():
		return
	elapsed += delta
	for squad in squads:
		squad.update_leadership(elapsed)
		if squad.routing_state == "PENDING_COMMAND" and squad.command_available():
			squad.begin_routing(elapsed)
		while not squad.leader_reports.is_empty():
			information.queue_leader_report(squad.leader_reports.pop_front())
		squad.advance(delta)
	advance_platoon_people(delta)
	information.advance(elapsed, squads[3].soldiers[3])
	supply.advance(delta, elapsed)
	if integrated_rear:
		rear.advance(delta, elapsed, supply)
	recovery.advance(delta, elapsed)
	if combat != null:
		combat.advance(elapsed)
	if engineering != null:
		engineering.advance(delta, elapsed)
	if artillery != null:
		if battle != null:
			battle.advance(elapsed)
		artillery.advance_fire_control(elapsed, information.company_contact_snapshot())
		artillery.resolve_impacts(elapsed, blast_entities(), combat.solid_cover, combat)
	if not battle_active():
		return
	if medical != null:
		medical.advance(delta, elapsed)
	for squad in squads:
		squad.decay_suppression(elapsed)
		squad.update_morale(elapsed)
		while not squad.morale_reports.is_empty():
			information.queue_morale_report(squad.morale_reports.pop_front())
	var objective_reached: bool = squads[0].complete() and squads[0].center().distance_to(OBJECTIVE) < 50
	if not secured and supply.phase == "Final approach" and objective_reached and squads[0].mission_execution_available():
		secured = true
		record("Squad", squads[0].id, "Seize Objective A", "Objective reached by surviving soldiers", "Each active individual completed its own route")

func advance_platoon_people(delta: float) -> void:
	for platoon in platoons:
		var person = platoon.leader
		if not person.active:
			continue
		var group = platoon.squads[0]
		# Locomotion follows nearby troop movement, never acting-appointment data.
		# Formal higher-command knowledge is updated solely by the delayed report.
		var nearby: Array = group.soldiers.filter(func(member): return member.active)
		if nearby.is_empty():
			continue
		nearby.sort_custom(func(a, b): return person.position.distance_squared_to(a.position) < person.position.distance_squared_to(b.position))
		var anchor = nearby[0]
		var signature: String = anchor.id + str(anchor.path) + str(anchor.waypoint)
		if signature != platoon.follow_signature:
			platoon.follow_signature = signature
			person.route_origin = person.position
			person.path.assign(anchor.path.slice(anchor.waypoint))
			if person.path.is_empty():
				person.path.append(anchor.position)
			person.waypoint = 0
			person.arrived = false
		if person.position.distance_to(anchor.position) > 45:
			person.advance(delta)
