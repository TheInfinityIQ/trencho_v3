extends "res://squad.gd"
## Geography-aware specialization of the accepted Squad, retaining real Soldiers.
var navigation
var movement_state := "HOLDING"
var movement_history: Array[Dictionary] = []
var formation_reference := Vector2.ZERO
var formation_route: Array[Vector2] = []
var formation_waypoint := 0
var route_revision := 0
var command_time := 0.0
const SPACING := 2.2
const SPEED := 1.4

func _init(identity: String, start: Vector2, router) -> void:
	super._init(identity, start)
	navigation = router
	formation_reference = start
	for i in range(soldiers.size()):
		var person = soldiers[i]
		person.position = start + slot(i); person.origin = person.position; person.route_origin = person.position
		person.speed = SPEED

func slot(index: int) -> Vector2:
	return Vector2((index % 2) - 0.5, floori(index / 2.0) - 0.5) * SPACING

func change_state(value: String) -> void:
	if movement_state == value: return
	movement_state = value
	movement_history.append({"time":command_time, "state":value, "task":task, "destination":destination, "route_revision":route_revision})

func hold(local_task: String) -> void:
	task = local_task
	destination = formation_reference
	formation_route.clear(); formation_waypoint = 0
	for person in soldiers: person.path.clear(); person.arrived = false
	change_state("HOLDING")

func assign(local_task: String, target: Vector2, _obstacle := Rect2()) -> Dictionary:
	if not mission_execution_available(): return {}
	if route_revision > 0 and target.is_equal_approx(destination) and local_task == task: return decision
	var reassigned := route_revision > 0
	task = local_task; destination = target
	formation_route = navigation.route(formation_reference, target)
	formation_waypoint = 0; route_revision += 1
	for person in soldiers: person.route_origin = person.position; person.waypoint = 0; person.arrived = false
	change_state("REASSIGNED" if reassigned else "MOVING_TO_OBJECTIVE")
	if formation_route.is_empty(): change_state("HOLDING")
	decision = {"echelon":"Squad", "actor":id, "intent":task, "commander_person":current_leader().id, "choice":"Geography route revision %d with %d waypoints" % [route_revision, formation_route.size()], "reason":"Squad selects bounded road/open-ground route avoiding presentation envelopes"}
	return decision

func advance(delta: float) -> void:
	command_time += delta
	if not command_available() or movement_state in ["HOLDING", "ARRIVED"]: return
	if movement_state == "REASSIGNED": change_state("MOVING_TO_OBJECTIVE")
	# Pause the reference for a separated member to catch up at ordinary speed.
	# Positions are never regenerated from a Squad token or teleported for cohesion.
	var coherent := true
	for i in range(soldiers.size()):
		if soldiers[i].position.distance_to(formation_reference + slot(i)) > 0.15: coherent = false
	var budget := SPEED * delta if coherent else 0.0
	while budget > 0 and formation_waypoint < formation_route.size():
		var target := formation_route[formation_waypoint]
		var distance := formation_reference.distance_to(target)
		var step := minf(distance, budget)
		formation_reference = formation_reference.move_toward(target, step); budget -= step
		if distance <= step: formation_waypoint += 1
	var arrived := formation_waypoint == formation_route.size()
	for i in range(soldiers.size()):
		var person = soldiers[i]
		person.path.assign([formation_reference + slot(i)]); person.waypoint = 0
		person.advance(delta)
		arrived = arrived and person.arrived
		if formation_waypoint < formation_route.size(): person.arrived = false
	if arrived: change_state("ARRIVED")
