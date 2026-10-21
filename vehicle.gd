extends RefCounted

var id: String
var position: Vector2
var mobility_class: String
var faction := "friendly"
var inventory := {"BoltActionRifleAmmo": 0}
var driver
var state := "At depot"
var route_state := "NOT_STARTED"
var route: Array[String] = []
var route_index := 0
var destination := "resupply"
var current_node: String
var known_blocked: Dictionary = {}
var blocked_reason := ""
var blocked_location := Vector2.ZERO
var blocked_at := -1.0
var replanning_at := -1.0
var speed := 48.0

func route_is_legal(network) -> bool:
	for index in range(route.size() - 1):
		var edge: Dictionary = network.edge_between(route[index], route[index + 1])
		if edge.is_empty() or not network.edge_allowed(edge, mobility_class) or edge.blocked:
			return false
	return not route.is_empty()

func _init(identity: String, mobility: String, start_node: String, location: Vector2, person) -> void:
	id = identity
	mobility_class = mobility
	current_node = start_node
	position = location
	driver = person
	driver.assigned_vehicle_id = id
	driver.position = position

func start(network, now: float) -> void:
	route.assign(network.plan(current_node, destination, mobility_class, known_blocked))
	route_index = 0
	route_state = "MOVING" if route.size() > 1 else "NO_LEGAL_ROUTE"
	network.record(self, now, "Evaluate primary route", route_state)

func advance(delta: float, now: float, network) -> void:
	if not driver.active or driver.assigned_vehicle_id != id:
		if route_state != "NO_DRIVER":
			route_state = "NO_DRIVER"
			network.record(self, now, "Active assigned driver unavailable; cargo retained", route_state)
		return
	if route_state == "NOT_STARTED":
		start(network, now)
	if route_state == "BLOCKED":
		if now >= blocked_at + 1:
			route_state = "REPLANNING"
			replanning_at = now
			network.record(self, now, "Replan within mobility permissions", route_state)
		return
	if route_state == "REPLANNING":
		if now >= replanning_at + 1:
			route.assign(network.plan(current_node, destination, mobility_class, known_blocked))
			route_index = 0
			route_state = "MOVING" if route.size() > 1 else "NO_LEGAL_ROUTE"
			network.record(self, now, "Follow legal alternate route", route_state)
		return
	if route_state != "MOVING":
		return
	var next_node: String = route[route_index + 1]
	var edge: Dictionary = network.edge_between(current_node, next_node)
	if edge.blocked:
		known_blocked[edge.id] = true
		blocked_reason = "Static crossing blocked: " + edge.id
		blocked_location = position
		blocked_at = now
		route_state = "BLOCKED"
		network.record(self, now, blocked_reason, route_state)
		return
	if not network.edge_allowed(edge, mobility_class):
		route_state = "NO_LEGAL_ROUTE"
		return
	position = position.move_toward(network.points[next_node], speed * delta)
	driver.position = position
	if position == network.points[next_node]:
		current_node = next_node
		route_index += 1
		if route_index == route.size() - 1:
			route_state = "ARRIVED"
			network.record(self, now, "Destination physically reached", route_state)
