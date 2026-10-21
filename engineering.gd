extends RefCounted

const Person = preload("res://soldier.gd")
const WORK_RADIUS := 24.0
const STRUCTURE_HIT_RADIUS := 24.0
const ACTIVITIES := {
	"BasicFoxhole": {"tool": "BasicShovel", "qualified": false, "material": 0, "labor": 3.0, "result": "Foxhole"},
	"ReinforcedPosition": {"tool": "EngineerToolkit", "qualified": true, "material": 4, "labor": 5.0, "result": "ReinforcedPosition"},
	"RepairReinforced": {"tool": "EngineerToolkit", "qualified": true, "material": 2, "labor": 4.0, "result": ""}}
var people: Array = []
var tools: Array[Dictionary] = []
var stockpile := {"id": "MilitaryConstructionStock-01", "owner": "military", "position": Vector2(200, 550), "inventory": {"BuildingMaterial": 8}}
var reservations: Dictionary = {}
var consumed := 0
var ledger: Array[Dictionary] = []
var jobs: Array[Dictionary] = []
var structures: Array[Dictionary] = []
var lifecycle_history: Array[Dictionary] = []
var sites := {"Dig Site A": Vector2(320, 250), "Reinforced Site B": Vector2(650, 580)}
var failures: Array[Dictionary] = []
var proof_comparison := "Combat comparison not run"
var proof_effects: Array[Dictionary] = []
var proof_blast_point := Vector2.ZERO

func _init(assign_work := true) -> void:
	var engineer = Person.new("Engineer-01", Vector2(170, 610), 65)
	engineer.engineer_qualified = true
	var rifleman = Person.new("Rifleman-01", Vector2(150, 180), 65)
	people.assign([engineer, rifleman])
	tools.assign([{"id": "Shovel-01", "category": "BasicShovel", "holder": rifleman.id},
		{"id": "Toolkit-01", "category": "EngineerToolkit", "holder": engineer.id}])
	if assign_work:
		assign("BasicFoxhole", rifleman, "Dig Site A", 0)
		assign("ReinforcedPosition", engineer, "Reinforced Site B", 0)

func tool_position(item: Dictionary) -> Vector2:
	for person in people:
		if item.holder == person.id:
			return person.position
	return stockpile.position

func has_tool(person, category: String) -> bool:
	return tools.any(func(item): return item.holder == person.id and item.category == category)

func reserved_material() -> int:
	var total := 0
	for value in reservations.values():
		total += int(value)
	return total

func reserve_material(job_id: String, amount: int, now: float) -> bool:
	if amount <= 0 or reservations.has(job_id) or stockpile.inventory.BuildingMaterial < amount:
		return false
	stockpile.inventory.BuildingMaterial -= amount
	reservations[job_id] = amount
	ledger.append({"source": stockpile.id, "amount": amount, "destination": "reservation:" + job_id, "action": "reserve", "time": now, "job": job_id, "resource": "BuildingMaterial"})
	return true

func eligibility(activity: String, person) -> String:
	if not ACTIVITIES.has(activity):
		return "Unknown construction activity"
	if person not in people or not person.active:
		return "Active assigned military person required"
	var rule: Dictionary = ACTIVITIES[activity]
	if rule.qualified and not person.engineer_qualified:
		return "Engineer qualification required"
	if not has_tool(person, rule.tool):
		return "Missing tool: " + rule.tool
	return ""

func assign(activity: String, person, site: String, now: float) -> Dictionary:
	var reason := eligibility(activity, person)
	if activity == "RepairReinforced":
		reason = "Use damaged-structure repair assignment"
	if reason.is_empty() and not sites.has(site):
		reason = "Authored work site required"
	if reason.is_empty() and jobs.any(func(job): return (job.person == person.id and job.state != "COMPLETE") or job.site == site):
		reason = "Person or site already assigned"
	if reason.is_empty() and stockpile.inventory.BuildingMaterial < int(ACTIVITIES[activity].material):
		reason = "Insufficient uncommitted BuildingMaterial"
	if not reason.is_empty():
		failures.append({"time": now, "person": person.id, "activity": activity, "site": site, "reason": reason})
		return {}
	return create_job(activity, person, site, sites[site], now)

func structure_by_id(identity: String) -> Dictionary:
	for structure in structures:
		if structure.id == identity:
			return structure
	return {}

func repair_reason(person, structure: Dictionary) -> String:
	if structure.is_empty() or structure.type != "ReinforcedPosition":
		return "Reinforced structure required"
	if structure.state == "DESTROYED":
		return "REQUIRES_REBUILD"
	if structure.state != "DAMAGED":
		return "Repair unnecessary: structure is INTACT"
	return eligibility("RepairReinforced", person)

func assign_repair(person, identity: String, now: float) -> Dictionary:
	var structure := structure_by_id(identity)
	var reason := repair_reason(person, structure)
	if reason.is_empty() and jobs.any(func(job): return job.state != "COMPLETE" and (job.person == person.id or job.get("target_structure", "") == identity)):
		reason = "Person or repair target already assigned"
	if reason.is_empty() and stockpile.inventory.BuildingMaterial < 2:
		reason = "Insufficient uncommitted BuildingMaterial"
	if not reason.is_empty():
		failures.append({"time": now, "person": person.id, "activity": "RepairReinforced", "structure": identity, "reason": reason})
		return {}
	return create_job("RepairReinforced", person, structure.id, structure.position, now, identity)

func create_job(activity: String, person, site: String, position: Vector2, now: float, target_structure := "") -> Dictionary:
	var rule: Dictionary = ACTIVITIES[activity]
	var identity := "Construction-%02d" % (jobs.size() + 1)
	if rule.material > 0 and not reserve_material(identity, rule.material, now):
		return {}
	var job := {"id": identity, "person": person.id, "activity": activity, "site": site, "position": position, "required_tool": rule.tool, "target_structure": target_structure,
		"required_material": rule.material, "duration": rule.labor, "progress": 0.0, "state": "TRAVELING", "failure_reason": "Outside work radius",
		"assigned_at": now, "labor_started_at": -1.0, "completed_at": -1.0, "structure": ""}
	jobs.append(job)
	person.route_origin = person.position
	person.path.assign([position])
	person.waypoint = 0
	person.arrived = false
	return job

func complete(job: Dictionary, now: float) -> void:
	if job.required_material > 0:
		var amount := int(reservations[job.id])
		reservations.erase(job.id)
		consumed += amount
		ledger.append({"source": "reservation:" + job.id, "amount": amount, "destination": job.target_structure if not job.target_structure.is_empty() else "Structure-" + job.id, "action": "consume", "time": now, "job": job.id, "resource": "BuildingMaterial"})
	if job.activity == "RepairReinforced":
		var repaired := structure_by_id(job.target_structure)
		set_integrity(repaired, 2)
		lifecycle_event(repaired, "repaired", now, job.person, job.id)
		job.structure = repaired.id
		job.progress = job.duration
		job.completed_at = now
		job.state = "COMPLETE"
		job.failure_reason = ""
		return
	var reinforced: bool = job.activity == "ReinforcedPosition"
	var structure := {"id": "Structure-" + job.id, "type": ACTIVITIES[job.activity].result, "position": job.position,
		"protection": Rect2(job.position + Vector2(8, -24), Vector2(36, 48)) if reinforced else Rect2(job.position - Vector2(24, 24), Vector2(48, 48)),
		"geometry": Rect2(job.position + Vector2(-4, -28), Vector2(8, 56)) if reinforced else Rect2(job.position - Vector2(18, 18), Vector2(36, 36)),
		"small_arms_cover": true, "solid_blast": reinforced, "blocks_los": false, "completed_at": now, "job": job.id,
		"state": "INTACT", "integrity": 2 if reinforced else -1, "damage_point": job.position}
	structures.append(structure)
	lifecycle_event(structure, "constructed", now, job.person, job.id)
	job.structure = structure.id
	job.progress = job.duration
	job.completed_at = now
	job.state = "COMPLETE"
	job.failure_reason = ""
	print("CONSTRUCTION COMPLETE: ", JSON.stringify(structure))

func provides_small_arms_cover(structure: Dictionary) -> bool:
	return structure.type == "Foxhole" or structure.state != "DESTROYED"

func provides_blast_obstruction(structure: Dictionary) -> bool:
	return structure.type == "ReinforcedPosition" and structure.state == "INTACT"

func set_integrity(structure: Dictionary, value: int) -> void:
	structure.integrity = clampi(value, 0, 2)
	structure.state = "INTACT" if value >= 2 else ("DAMAGED" if value == 1 else "DESTROYED")
	# Diagnostic classifications are refreshed together; combat derives its actual
	# answer from current lifecycle state rather than caching these flags.
	structure.small_arms_cover = provides_small_arms_cover(structure)
	structure.solid_blast = provides_blast_obstruction(structure)

func lifecycle_event(structure: Dictionary, event: String, now: float, source: String, cause: String) -> void:
	lifecycle_history.append({"structure": structure.id, "event": event, "time": now, "source": source, "cause": cause, "integrity": structure.integrity, "state": structure.state, "position": structure.position})
	print("FORTIFICATION LIFECYCLE: ", JSON.stringify(lifecycle_history.back()))

func apply_blast_damage(point: Vector2, now: float, source: String) -> void:
	for structure in structures:
		if structure.type != "ReinforcedPosition" or structure.state == "DESTROYED" or point.distance_to(structure.damage_point) > STRUCTURE_HIT_RADIUS:
			continue
		set_integrity(structure, structure.integrity - 1)
		lifecycle_event(structure, "destroyed" if structure.state == "DESTROYED" else "damaged", now, source, "Spatial blast within24units")

func advance(delta: float, now: float) -> void:
	for person in people:
		var before: Vector2 = person.position
		person.advance(delta)
		for job in jobs:
			if job.person != person.id or job.state == "COMPLETE":
				continue
			var reason := eligibility(job.activity, person)
			if reason.is_empty() and job.activity == "RepairReinforced":
				reason = repair_reason(person, structure_by_id(job.target_structure))
			if reason.is_empty() and (before.distance_to(job.position) > WORK_RADIUS or person.position.distance_to(job.position) > WORK_RADIUS):
				reason = "Outside work radius"
			if reason.is_empty() and job.required_material > 0 and int(reservations.get(job.id, 0)) != job.required_material:
				reason = "BuildingMaterial reservation unavailable"
			job.failure_reason = reason
			if not reason.is_empty():
				job.state = "PAUSED"
				continue
			job.state = "WORKING"
			if job.labor_started_at < 0:
				job.labor_started_at = now - delta
			job.progress = minf(job.duration, job.progress + delta)
			if job.progress + 0.000001 >= job.duration:
				complete(job, now)
