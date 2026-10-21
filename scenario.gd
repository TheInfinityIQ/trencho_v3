extends RefCounted

const Squad = preload("res://squad.gd")
const Information = preload("res://information.gd")
const Supply = preload("res://supply.gd")
const Rear = preload("res://rear.gd")
const Recovery = preload("res://recovery.gd")
const Combat = preload("res://combat.gd")
const VehicleRoutes = preload("res://vehicle_routes.gd")
const Artillery = preload("res://artillery.gd")
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

func _init(with_rear := false, with_combat := false, with_vehicles := false, with_artillery := false) -> void:
	integrated_rear = with_rear
	squads = [Squad.new("P1-A", Vector2(155, 300)), Squad.new("P1-B", Vector2(165, 420)),
		Squad.new("P2-A", Vector2(140, 610)), Squad.new("P2-B", Vector2(240, 610))]
	platoons = [{"id": "P1", "squads": [squads[0], squads[1]], "assignment": "Unassigned"},
		{"id": "P2", "squads": [squads[2], squads[3]], "assignment": "Unassigned"}]
	operational_decide()
	supply = Supply.new(squads[0], with_rear)
	if with_rear:
		rear = Rear.new()
	recovery = Recovery.new(squads[3].soldiers[3])
	if with_combat:
		combat = Combat.new(self)
	if with_vehicles:
		vehicles = VehicleRoutes.new(supply)
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

func blast_entities() -> Array:
	var result: Array = []
	for squad in squads + ([combat.defenders] if combat != null else []):
		for person in squad.soldiers:
			result.append({"person": person, "squad": squad})
	if vehicles != null:
		for person in vehicles.drivers:
			result.append({"person": person, "squad": null})
	if artillery != null:
		result.append({"person": artillery.gunner, "squad": null})
	return result

func total_ammunition() -> int:
	var total: int = supply.depot.inventory[Supply.CATEGORY] + supply.truck.inventory[Supply.CATEGORY] + supply.captured.inventory[Supply.CATEGORY] + recovery.inventory[Supply.CATEGORY]
	for squad in squads:
		for soldier in squad.soldiers:
			total += int(soldier.inventory.get(Supply.CATEGORY, 0))
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
		trace.append(squad.assign(jobs[index], targets[index], OBSTACLE))
		for soldier in squad.soldiers:
			record("Soldier", soldier.id, jobs[index], "Execute own %d-point path" % soldier.path.size(), "Own position, speed and waypoint progress under squad intent")

func advance(delta: float) -> void:
	if information.reconstructing:
		return
	elapsed += delta
	for squad in squads:
		squad.advance(delta)
	information.advance(elapsed, squads[3].soldiers[3])
	supply.advance(delta, elapsed)
	if integrated_rear:
		rear.advance(delta, elapsed, supply)
	recovery.advance(delta, elapsed)
	if combat != null:
		combat.advance(elapsed)
	if artillery != null:
		artillery.advance_fire_control(elapsed, information.company_contact_snapshot())
		artillery.resolve_impacts(elapsed, blast_entities(), combat.solid_cover, combat)
	var objective_reached: bool = squads[0].complete() and squads[0].center().distance_to(OBJECTIVE) < 50
	if not secured and supply.phase == "Final approach" and objective_reached:
		secured = true
		record("Squad", squads[0].id, "Seize Objective A", "Objective reached by all four soldiers", "Each individual completed its own route")
