extends RefCounted

const Person = preload("res://soldier.gd")
const RANGE := 24.0
const TREATMENT := 2.0
const PICKUP := 2.0
const BLEED_OUT := 8.0
var model
var medic = Person.new("Medic-01", Vector2(360, 150), 65)
var wound_target_ids: Dictionary = {}
var casualty
var treatment_progress := 0.0
var treatment_reason := "No casualty assigned"
var history: Array[Dictionary] = []
var ledger: Array[Dictionary] = []
var evac := {"id": "EvacTeam-01", "position": Vector2(760, 160), "state": "IDLE", "mission": "", "pickup_progress": 0.0, "inventory": {}}

func _init(scenario) -> void:
	model = weakref(scenario)
	medic.medic_qualified = true
	medic.normal_role = "Medic"
	medic.inventory.Medkit = 2

func record(person, event: String, now: float, source: String) -> void:
	history.append({"person": person.id, "event": event, "time": now, "source": source, "position": person.position, "medical_state": person.medical_state, "on_battlefield": person.on_battlefield})
	print("MEDICAL WORLD EVENT: ", JSON.stringify(history.back()))

func wound(person, shooter, now: float) -> void:
	if not person.active or person.medical_state != "FIT":
		return
	person.medical_state = "WOUNDED"
	person.active = false
	person.body_present = false
	person.bleed_out_at = now + BLEED_OUT
	person.wound_source = shooter.id
	casualty = person
	wound_target_ids.erase(person.id)
	for squad in model.get_ref().squads:
		if person in squad.soldiers:
			squad.recognize_leader_loss(now)
			squad.combat_casualty(person, now)
	medic.route_origin = medic.position
	medic.path.assign([person.position])
	medic.waypoint = 0
	medic.arrived = false
	treatment_progress = 0
	treatment_reason = "Assigned; physical approach required"
	model.get_ref().combat.history.append({"event": "combat wound", "person": person.id, "location": person.position, "time": now, "world_source": shooter.id, "carried_inventory": person.inventory.duplicate(true)})
	record(person, "wounded", now, shooter.id)

func treatment_eligibility(person) -> String:
	if person == null or person.medical_state != "WOUNDED":
		return "WOUNDED casualty required"
	if not medic.active or medic.medical_state != "FIT":
		return "Active FIT Medic required"
	if not medic.medic_qualified:
		return "Medic qualification required"
	if int(medic.inventory.get("Medkit", 0)) < 1:
		return "Medkit required in Medic custody"
	return ""

func assign_evac(person) -> bool:
	if person == null or person.medical_state != "STABILIZED" or not person.on_battlefield or evac.state != "IDLE":
		return false
	evac.mission = person.id
	evac.state = "APPROACHING"
	return true

func advance(delta: float, now: float) -> void:
	# The deadline is authoritative: a still-unstabilized casualty expires before
	# any treatment completion at that exact timestamp can reverse the outcome.
	for squad in model.get_ref().squads:
		for person in squad.soldiers:
			if person.medical_state == "WOUNDED" and now + 0.000001 >= person.bleed_out_at:
				var death_time: float = person.bleed_out_at
				model.get_ref().combat.kill(person, {"id": person.wound_source}, death_time)
				record(person, "died from wounds", death_time, person.wound_source)
	var before: Vector2 = medic.position
	if casualty == null or medic.position.distance_to(casualty.position) > RANGE:
		medic.advance(delta)
	treatment_reason = treatment_eligibility(casualty)
	if casualty != null and casualty.medical_state in ["STABILIZED", "EVACUATED"]:
		treatment_reason = "Treatment complete"
	elif casualty != null and casualty.medical_state == "DEAD":
		treatment_reason = "Casualty deceased; no treatment"
	if treatment_reason.is_empty():
		if before.distance_to(casualty.position) > RANGE or medic.position.distance_to(casualty.position) > RANGE:
			treatment_reason = "Outside treatment range"
		else:
			treatment_progress = minf(TREATMENT, treatment_progress + delta)
			if treatment_progress + 0.000001 >= TREATMENT:
				medic.inventory.Medkit -= 1
				casualty.medical_state = "STABILIZED"
				casualty.bleed_out_at = -1
				ledger.append({"source": medic.id, "quantity": 1, "category": "Medkit", "destination": "stabilization:" + casualty.id, "time": now})
				record(casualty, "stabilized", now, medic.id)
				assign_evac(casualty)
	if casualty == null or casualty.medical_state != "STABILIZED" or evac.mission != casualty.id or evac.state == "COMPLETE":
		return
	var evac_before: Vector2 = evac.position
	if evac_before.distance_to(casualty.position) > RANGE:
		evac.position = evac.position.move_toward(casualty.position, 80 * delta)
	if evac_before.distance_to(casualty.position) > RANGE or evac.position.distance_to(casualty.position) > RANGE:
		evac.state = "APPROACHING"
		return
	evac.state = "PICKUP"
	evac.pickup_progress = minf(PICKUP, evac.pickup_progress + delta)
	if evac.pickup_progress + 0.000001 >= PICKUP:
		casualty.medical_state = "EVACUATED"
		casualty.on_battlefield = false
		casualty.body_present = false
		evac.state = "COMPLETE"
		record(casualty, "evacuated", now, evac.id)
