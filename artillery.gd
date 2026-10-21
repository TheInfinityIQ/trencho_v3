extends RefCounted

const Person = preload("res://soldier.gd")
const BLAST_WALL := Rect2(800, 425, 12, 30)
const RADIUS := 90.0
const LETHAL_RADIUS := 45.0
const PREPARATION := 1.0
const FLIGHT := 2.0
var id := "Mortar-01"
var position := Vector2(850, 650)
var inventory := {"MortarShell": 2}
var gunner = Person.new("Gunner-01", position, 0)
var state := "Awaiting Company contact knowledge"
var missions: Array[Dictionary] = []
var history: Array[Dictionary] = []
var auto_mission_created := false
var auto_contact_enabled := true
var fired_count := 0
var battle_boundary

func terminal() -> bool:
	return battle_boundary != null and battle_boundary.get_ref() != null and not battle_boundary.get_ref().is_active()

func _init() -> void:
	gunner.assigned_equipment_id = id

func create_mission(company_report: Dictionary, now: float) -> bool:
	if terminal():
		return false
	if company_report.get("kind", "") not in ["ENEMY_POSITION_OBSERVED", "STATIC_HQ_LOCATION"] or company_report.get("source_echelon", "") != "Company":
		return false
	if not company_report.get("observed_position") is Vector2 or float(company_report.get("received_at", INF)) > now + 0.000001:
		return false
	if float(company_report.get("observation_time", INF)) < 0 or float(company_report.get("observation_time", INF)) > float(company_report.get("received_at", -1)):
		return false
	if str(company_report.get("report_id", "")).is_empty() or str(company_report.get("observer", "")).is_empty():
		return false
	# Whitelist copied values. This object contains no target entity or live pointer.
	var mission_id := id + ":mission:" + str(missions.size() + 1)
	missions.append({"id": mission_id, "shell_id": mission_id + ":shell", "weapon": id, "target": company_report.observed_position, "report_id": company_report.report_id, "observer": company_report.observer, "observation_time": company_report.observation_time, "company_receipt": company_report.received_at, "created_at": now, "ready_at": now + PREPARATION, "state": "PREPARING"})
	state = "Preparing from Company report"
	print("COMPANY FIRE MISSION: ", JSON.stringify(missions.back()))
	return true

func advance_fire_control(now: float, company_records: Array[Dictionary]) -> void:
	if terminal():
		return
	# Fire control receives only restricted delivered records, never battlefield
	# entities or actual current enemy positions. Impact physics is a separate call.
	if auto_contact_enabled and not auto_mission_created and missions.is_empty() and not company_records.is_empty():
		auto_mission_created = create_mission(company_records[0], now)
	for mission in missions:
		if mission.state != "PREPARING" or now + 0.000001 < mission.ready_at:
			continue
		if not gunner.active or gunner.assigned_equipment_id != id:
			state = "Operator unavailable"
			continue
		if inventory.MortarShell <= 0:
			state = "No shells"
			continue
		inventory.MortarShell -= 1
		fired_count += 1
		mission.state = "IN_FLIGHT"
		mission.fired_at = now
		mission.impact_at = now + FLIGHT
		state = "Shell in flight"
		print("MORTAR FIRE: ", JSON.stringify(mission))

func blast(point: Vector2, now: float, actors: Array, solids: Array[Rect2], combat) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if not combat.model.get_ref().battle_active():
		return effects
	var obstructions: Array[Rect2] = solids.duplicate()
	obstructions.append_array(combat.constructed_blast_solids())
	for entry in actors:
		var soldier = entry.person
		if not soldier.is_physical_target():
			continue
		var distance := point.distance_to(soldier.position)
		if distance > RADIUS:
			continue
		var blocked := false
		for solid in obstructions:
			blocked = blocked or combat.crosses_rect(point, soldier.position, solid)
		var effect := "suppressed"
		var added_suppression := 1 if blocked else 2
		if distance <= LETHAL_RADIUS and not blocked:
			combat.kill(soldier, self, now)
			effect = "dead"
			added_suppression = 0
		elif entry.squad != null:
			if entry.squad == combat.model.get_ref().squads[0]:
				combat.add_suppression(added_suppression, now, "Spatial blast against a living member")
			else:
				entry.squad.receive_suppression(added_suppression, now)
		effects.append({"person": soldier.id, "position": soldier.position, "distance": distance, "solid_obstruction": blocked, "effect": effect, "suppression_added": added_suppression})
	# Each impact freezes its protection geometry above, resolves occupants first,
	# then changes structures. The next impact sees the resulting lifecycle state.
	var engineering = combat.model.get_ref().engineering
	if engineering != null:
		engineering.apply_blast_damage(point, now, id)
	var vehicles = combat.model.get_ref().vehicles
	if vehicles != null:
		var interrupted: Array[String] = vehicles.apply_blast_damage(point, now, id)
		if engineering != null:
			for identity in interrupted:
				engineering.interrupt_bridge_rebuild(identity, now)
	var battle = combat.model.get_ref().battle
	if battle != null:
		battle.apply_blast_damage(point, now, id)
	return effects

func resolve_impacts(now: float, actors: Array, solids: Array[Rect2], combat) -> void:
	if terminal():
		return
	for mission in missions:
		if mission.state != "IN_FLIGHT" or now + 0.000001 < mission.impact_at:
			continue
		var effects := blast(mission.target, mission.impact_at, actors, solids, combat)
		mission.state = "IMPACTED"
		history.append({"weapon": id, "impact": mission.target, "impact_time": mission.impact_at, "source_report": mission.report_id, "report_observation_time": mission.observation_time, "effects": effects})
		state = "Impact recorded / one mission complete"
		print("ARTILLERY WORLD IMPACT: ", JSON.stringify(history.back()))
		if terminal():
			break
