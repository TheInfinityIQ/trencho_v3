extends RefCounted

var id: String
var position: Vector2
var origin: Vector2
var route_origin: Vector2
var path: Array[Vector2] = []
var speed: float
var travelled := 0.0
var arrived := false
var waypoint := 0
var active := true
var body_present := false
var inventory := {"BoltActionRifleAmmo": 0}
var weapon_category := "BoltActionRifle"
var faction := "friendly"
var detected: Array[String] = []
var assigned_vehicle_id := ""
var assigned_equipment_id := ""
var formal_rank := "PRIVATE"
var normal_role := "Rifleman"
var squad_command_qualified := false
var acting_appointment := ""
var squad_id := ""
var rifle_proficiency := 0.5
var engineer_qualified := false
var medic_qualified := false
var medical_state := "FIT"
var on_battlefield := true
var bleed_out_at := -1.0
var wound_source := ""
var wound_episode_id := ""
var personal_history: Array[Dictionary] = []
var appointment_history: Array[Dictionary] = []
var permanent_history: Array[Dictionary] = []

func is_alive() -> bool:
	return medical_state != "DEAD"

func is_physical_target() -> bool:
	return on_battlefield and medical_state not in ["DEAD", "EVACUATED"] and (active or medical_state in ["WOUNDED", "STABILIZED"])

func _init(identity: String, start: Vector2, pace: float) -> void:
	id = identity
	position = start
	origin = start
	route_origin = start
	speed = pace

func advance(delta: float) -> void:
	if not active or medical_state != "FIT" or not on_battlefield:
		return
	var budget := speed * delta
	while budget > 0.0 and waypoint < path.size():
		var distance := position.distance_to(path[waypoint])
		var step := minf(distance, budget)
		position = position.move_toward(path[waypoint], step)
		travelled += step
		budget -= step
		if distance <= step:
			waypoint += 1
	arrived = not path.is_empty() and waypoint == path.size()
