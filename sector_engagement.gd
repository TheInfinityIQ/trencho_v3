extends "res://sector_scenario.gd"
## Physical opposing force + genuine contact, using accepted command/report owners.
const SectorCombat = preload("res://sector_combat.gd")
var enemy_platoon := {}
var enemy_objective := Vector2.ZERO
var initial_ammunition := 0

func _init(layout, environment, seed_value := 38038) -> void:
	super._init(layout, environment, seed_value)
	information.fixture_enabled = false
	var sample: Dictionary = layout.sample_route(layout.village_distance)
	var forward: Vector2 = sample.direction.normalized()
	var normal := Vector2(-forward.y, forward.x)
	var staging: Vector2 = navigation.safe_position(layout.village + forward * 360 + normal * 60)
	var enemy_squads := []
	enemy_objective = navigation.safe_position(anchors.SUPPORT + forward * 20)
	for i in range(2):
		var start: Vector2 = navigation.safe_position(staging + normal * (i * 16 - 8))
		var squad = SectorSquad.new("E1-%s" % ("A" if i == 0 else "B"), start, navigation)
		for person in squad.soldiers: person.faction = "enemy"
		enemy_squads.append(squad)
	var leader = Person.new("E1-PL", enemy_squads[0].formation_reference + forward * 3, 1.4)
	leader.faction = "enemy"; leader.formal_rank = "LIEUTENANT"; leader.normal_role = "PlatoonLeader"
	enemy_platoon = {"id":"E1","squads":enemy_squads,"assignment":"Approach generated settlement/support area","leader":leader,"staging":staging,"objective":enemy_objective}
	record("Operational", "Opposing intent", "Approach settlement", "E1 receives generated geography objective", "Initial high-level mission only; contact/fire require local detection")
	for i in range(2):
		var squad = enemy_squads[i]
		record("Platoon", "E1", enemy_platoon.assignment, squad.id + ": approach", "Squad computes route through the same geography graph")
		trace.append(squad.assign("Approach settlement", navigation.safe_position(enemy_objective + normal * i * 12)).duplicate(true))
	for squad in squads + enemy_squads:
		squad.morale_enabled = false
		for person in squad.soldiers: person.inventory.BoltActionRifleAmmo = 12
	initial_ammunition = ammunition_remaining()
	combat = SectorCombat.new(self)

func friendly_people() -> Array:
	# Legacy Scenario.all_people also appends Combat.defenders. This adapter owns
	# a whole opposing Platoon, so enumerate friendly ownership without that alias.
	var people := []
	for squad in squads: people.append_array(squad.soldiers)
	for platoon in platoons: people.append(platoon.leader)
	return people

func enemy_people() -> Array:
	if enemy_platoon.is_empty(): return []
	var people := []
	for squad in enemy_platoon.squads: people.append_array(squad.soldiers)
	people.append(enemy_platoon.leader)
	return people

func all_people() -> Array:
	return friendly_people() + enemy_people()

func ammunition_remaining() -> int:
	var total := 0
	for person in all_people(): total += int(person.inventory.get("BoltActionRifleAmmo",0))
	return total

func advance(delta: float) -> void:
	super.advance(delta)
	combat.advance(elapsed)
	# Same accepted1second local->Platoon->Company relay; no authoredT5 incident.
	information.advance(elapsed, null)

func advance_movement(delta: float) -> void:
	if not enemy_platoon.is_empty():
		for squad in squads + enemy_platoon.squads:
			squad.update_leadership(elapsed)
			while not squad.leader_reports.is_empty():
				var report: Dictionary = squad.leader_reports.pop_front()
				if squad in squads: information.queue_leader_report(report)
	# Preserve the accepted friendly Company/reassignment path.
	super.advance_movement(delta)
	if enemy_platoon.is_empty(): return
	for squad in enemy_platoon.squads: squad.advance(delta)
	var leader = enemy_platoon.leader
	if leader.active:
		leader.path.assign([enemy_platoon.squads[0].formation_reference + Vector2(3,0)]); leader.waypoint = 0
		leader.advance(delta)
		if enemy_platoon.squads[0].movement_state == "MOVING_TO_OBJECTIVE": leader.arrived = false

func company_contacts() -> Array[Dictionary]:
	var newest := {}
	for report in information.company_contact_snapshot():
		if not newest.has(report.contact_id) or report.observation_time > newest[report.contact_id].observation_time: newest[report.contact_id] = report
	var result: Array[Dictionary] = []
	for id in newest:
		var report: Dictionary = newest[id].duplicate(true)
		report.knowledge_state = "LAST_KNOWN" if elapsed - report.observation_time <= 5.0 else "STALE"
		result.append(report)
	result.sort_custom(func(a,b):return a.contact_id < b.contact_id)
	return result

func player_observation() -> Array[Dictionary]:
	# Direct friendly firing effects only; never return an unseen target endpoint.
	var effects: Array[Dictionary] = []
	for i in range(combat.shots.size()-1,-1,-1):
		var shot: Dictionary = combat.shots[i]
		if elapsed - shot.time > 0.12: break
		if shot.faction == "friendly": effects.append({"person":shot.shooter,"position":shot.shooter_position,"time":shot.time,"effect":"rifle_fire"})
	return effects
