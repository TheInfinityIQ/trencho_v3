extends RefCounted

const Scenario = preload("res://scenario.gd")
const Person = preload("res://soldier.gd")
const ROSTER := ["P1-A.1", "P1-B.1", "P1-A.2", "P1-A.3", "P1-A.4", "P1-PL"]
const NEXT_SQUAD := ["P1-B.1", "P1-A.2", "P1-A.3", "P1-A.4"]

# Only this detached value tree is campaign state. Runtime worlds are held
# separately by this proof session so archived-instance independence is testable.
var data := {"campaign_id": "Campaign-Proof-01", "battle_index": 1, "campaign_active": true,
	"person_registry": {}, "organizational_history": [], "capabilities": {"BoltActionAmmoProduction": true}, "completed_battles": []}
var world
var archived_worlds: Array = []
var transition_reason := ""
var fixture_events := {"second_batch": false, "leader_loss": false, "hq_strike": false, "third_batch": false, "late_fire": false}

func _init(with_ammo_capability := true, campaign_id := "Campaign-Proof-01", restored_values: Dictionary = {}) -> void:
	if not restored_values.is_empty():
		data = restored_values.duplicate(true)
		world = null
		return
	data.campaign_id = campaign_id
	data.capabilities.BoltActionAmmoProduction = with_ammo_capability
	world = Scenario.new(true, true, true, true, true, true, true, true)
	world.battle.auto_strike = false
	world.combat.encounter_over = true
	bind_capabilities(world)
	for identity in ROSTER:
		var person = find_person(world, identity)
		person.personal_history.append({"event": "campaign enrolled", "campaign": data.campaign_id, "battle": 1, "time": 0.0})
		person.permanent_history.append({"event": "initial formal assignment", "battle": 1, "time": 0.0, "rank": person.formal_rank, "normal_role": person.normal_role})
		data.person_registry[identity] = profile(person, 1)
	world.rear.place_workbench(Vector2(380, 480))
	world.rear.start_job("Avatar", 0)
	world.rear.set_policy("RESERVE", 8)
	world.engineering.assign("BasicFoxhole", world.engineering.people[1], "Dig Site A", 0)

func find_person(battle_world, identity: String):
	for person in battle_world.all_people():
		if person.id == identity:
			return person
	return null

func bind_capabilities(battle_world) -> void:
	if battle_world.rear != null:
		battle_world.rear.capability_unlocked = bool(data.capabilities.get("BoltActionAmmoProduction", false))

func clean_history(records: Array, battle_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in records:
		var copy: Dictionary = record.duplicate(true)
		for physical_field in ["inventory", "body_inventory", "carried_inventory"]:
			copy.erase(physical_field)
		if not copy.has("battle"):
			copy.battle = battle_index
		result.append(copy)
	return result

func profile(person, battle_index: int) -> Dictionary:
	return {"id": person.id, "formal_rank": person.formal_rank, "normal_role": person.normal_role,
		"squad_command_qualified": person.squad_command_qualified, "engineer_qualified": person.engineer_qualified,
		"medic_qualified": person.medic_qualified, "rifle_proficiency": person.rifle_proficiency,
		"medical_state": person.medical_state, "fit_survivor": person.medical_state == "FIT" and person.active and person.on_battlefield,
		"personal_history": clean_history(person.personal_history, battle_index),
		"appointment_history": clean_history(person.appointment_history, battle_index),
		"permanent_history": clean_history(person.permanent_history, battle_index)}

func fresh_person(record: Dictionary, position: Vector2, speed: float, battle_index := 2):
	var person = Person.new(record.id, position, speed)
	for field in ["formal_rank", "normal_role", "squad_command_qualified", "engineer_qualified", "medic_qualified", "rifle_proficiency"]:
		person.set(field, record[field])
	person.personal_history.assign(record.personal_history.duplicate(true))
	person.appointment_history.assign(record.appointment_history.duplicate(true))
	person.permanent_history.assign(record.permanent_history.duplicate(true))
	person.personal_history.append({"event": "battle entered", "battle": battle_index, "time": 0.0})
	# Medical eligibility was checked before construction; all physical/tactical
	# state is deliberately fresh rather than copied from the archived actor.
	person.acting_appointment = ""
	return person

func archive_snapshot(battle_world, battle_index := 1) -> Dictionary:
	var people: Array = []
	for person in battle_world.all_people():
		people.append({"id": person.id, "position": person.position, "rank": person.formal_rank, "role": person.normal_role,
			"medical_state": person.medical_state, "active": person.active, "present": person.on_battlefield, "body": person.body_present,
			"inventory": person.inventory.duplicate(true), "personal_history": person.personal_history.duplicate(true), "appointment_history": person.appointment_history.duplicate(true)})
	return {"battle_index": battle_index, "outcome": battle_world.battle_state, "terminal_time": battle_world.battle.terminal_time,
		"world_time": battle_world.elapsed, "hqs": battle_world.battle.hqs.duplicate(true), "hq_history": battle_world.battle.history.duplicate(true),
		"people": people, "structures": battle_world.engineering.structures.duplicate(true), "construction_jobs": battle_world.engineering.jobs.duplicate(true),
		"construction_stock": battle_world.engineering.stockpile.duplicate(true), "infrastructure": battle_world.vehicles.infrastructure.duplicate(true),
		"vehicle_cargo": {"truck": battle_world.vehicles.truck.inventory.duplicate(true), "tracked": battle_world.vehicles.tracked.inventory.duplicate(true)},
		"rear": {"workbench": battle_world.rear.workbench, "metal": battle_world.rear.metal, "ammo": battle_world.rear.ammunition,
			"worker": battle_world.rear.worker.duplicate(true), "job": battle_world.rear.job.duplicate(true), "committed": battle_world.rear.committed,
			"shipment": battle_world.rear.shipment.duplicate(true)},
		"knowledge": battle_world.information.knowledge.duplicate(true), "leader_knowledge": battle_world.information.leader_knowledge.duplicate(true),
		"combat_history": battle_world.combat.history.duplicate(true), "trace": battle_world.trace.duplicate(true)}

func transition() -> bool:
	if world == null:
		transition_reason = "NO_ACTIVE_BATTLE_TO_TRANSITION"
		return false
	if world.battle_active():
		transition_reason = "ACTIVE_BATTLE_CANNOT_TRANSITION"
		return false
	if world.battle_state != "ENDED_FRIENDLY_VICTORY":
		transition_reason = "CAMPAIGN_DEFEAT_POLICY_DEFERRED"
		return false
	if data.battle_index != 1:
		transition_reason = "Only the Battle1-to-Battle2 proof is defined"
		return false
	var registry: Dictionary = data.person_registry.duplicate(true)
	for identity in ROSTER:
		var person = find_person(world, identity)
		if person != null:
			registry[identity] = profile(person, 1)
	for identity in NEXT_SQUAD + ["P1-PL"]:
		if not registry[identity].fit_survivor:
			transition_reason = "UNSUPPORTED_NONFIT_ROSTER: " + identity
			return false
	var members: Array = []
	for index in range(NEXT_SQUAD.size()):
		members.append(fresh_person(registry[NEXT_SQUAD[index]], Vector2.ZERO, 43.0 + index * 1.2))
	var leader = fresh_person(registry["P1-PL"], Vector2(130, 280), 47)
	var next_world = Scenario.new(true, true, true, true, true, true, true, true,
		{"main_members": members, "platoon_leader": leader, "fresh_prefix": "B2-"})
	next_world.battle.auto_strike = false
	next_world.combat.encounter_over = true
	bind_capabilities(next_world)
	var archive := archive_snapshot(world)
	var survivors: Array[String] = []
	var dead: Array[String] = []
	for identity in ROSTER:
		if registry[identity].fit_survivor:
			survivors.append(identity)
		elif registry[identity].medical_state == "DEAD":
			dead.append(identity)
	var local_history: Array = []
	for squad in world.squads:
		local_history.append({"squad": squad.id, "leadership": squad.leadership_log.duplicate(true), "morale": squad.morale_log.duplicate(true)})
	data.organizational_history.append({"battle_index": 1, "outcome": world.battle_state, "surviving_person_ids": survivors,
		"dead_person_ids": dead, "terminal_hq_event": world.battle.history.filter(func(event): return event.event == "HQ destroyed")[0].duplicate(true),
		"notable_local_events": local_history})
	data.completed_battles.append(archive)
	data.person_registry = registry
	archived_worlds.append(world)
	world = next_world
	data.battle_index = 2
	data.organizational_history.append({"battle_index": 2, "event": "battle entered", "time": 0.0, "persistent_person_ids": survivors.duplicate()})
	transition_reason = ""
	return true

func advance(delta: float) -> void:
	if not data.campaign_active or world == null:
		return
	world.advance(delta)
	if data.battle_index != 1 or not world.battle_active():
		return
	if world.elapsed >= 4 and not fixture_events.second_batch:
		fixture_events.second_batch = world.rear.start_job("Avatar", world.elapsed)
	if world.elapsed >= 13 and not fixture_events.leader_loss:
		var source = world.combat.defenders.soldiers[0]
		var person = world.squads[0].formal_leader
		source.position = person.position + Vector2(0, -100)
		world.combat.detect(source, [person])
		fixture_events.leader_loss = world.combat.attempt_shot(source, person, world.elapsed, 0)
	if world.elapsed >= 14 and not fixture_events.hq_strike:
		world.battle.auto_strike = true
		fixture_events.hq_strike = true
	if world.elapsed >= 20 and not fixture_events.third_batch:
		fixture_events.third_batch = world.rear.start_job("Avatar", world.elapsed)
	if world.elapsed >= 21 and not fixture_events.late_fire:
		var source = world.combat.defenders.soldiers[0]
		var target = world.squads[0].soldiers[1]
		source.position = target.position + Vector2(0, -100)
		world.combat.detect(source, [target])
		fixture_events.late_fire = world.combat.attempt_shot(source, target, world.elapsed, 0.99)
