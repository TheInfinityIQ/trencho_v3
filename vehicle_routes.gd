extends RefCounted

const Vehicle = preload("res://vehicle.gd")
const Person = preload("res://soldier.gd")
const ROAD_HALF_WIDTH := 16.0
const BLOCKAGE := Rect2(245, 150, 30, 30)
var points := {"depot": Vector2(100, 125), "carrier_start": Vector2(100, 150), "junction": Vector2(220, 150), "crossing_exit": Vector2(300, 175), "resupply": Vector2(350, 200), "road_southwest": Vector2(220, 300), "road_southeast": Vector2(350, 300), "offroad_west": Vector2(220, 210), "offroad_east": Vector2(300, 210)}
var edges: Array[Dictionary] = []
var drivers: Array = []
var truck
var tracked
var events: Array[Dictionary] = []
var infrastructure: Dictionary = {}
var infrastructure_history: Array[Dictionary] = []
var revision := 0
const DAMAGED_SPEED := 0.30
const INFRASTRUCTURE_HIT_RADIUS := 24.0

func configure_infrastructure() -> void:
	edge_between("junction", "crossing_exit").blocked = false
	infrastructure = {
		"RoadSegment-A": {"id": "RoadSegment-A", "type": "RoadSegment", "state": "INTACT", "edge": "depot-junction", "position": (points.depot + points.junction) / 2, "start": points.depot, "end": points.junction},
		"Bridge-A": {"id": "Bridge-A", "type": "Bridge", "state": "INTACT", "edge": "blocked-crossing", "position": (points.junction + points.crossing_exit) / 2, "start": points.junction, "end": points.crossing_exit}}
	for edge in edges:
		edge.infrastructure = "RoadSegment-A" if edge.id == "depot-junction" else ("Bridge-A" if edge.id == "blocked-crossing" else "")

func edge_infrastructure(edge: Dictionary) -> Dictionary:
	return infrastructure.get(edge.get("infrastructure", ""), {})

func edge_speed_multiplier(edge: Dictionary, _mobility: String) -> float:
	var item := edge_infrastructure(edge)
	return DAMAGED_SPEED if not item.is_empty() and item.type == "RoadSegment" and item.state == "DAMAGED" else 1.0

func edge_cost(edge: Dictionary, mobility: String) -> float:
	return points[edge.a].distance_to(points[edge.b]) / edge_speed_multiplier(edge, mobility) if edge_allowed(edge, mobility) else INF

func edge_diagnostics(mobility: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for edge in edges:
		result.append({"edge": edge.id, "terrain": edge.terrain, "infrastructure": edge.get("infrastructure", ""), "legal": edge_allowed(edge, mobility) and not edge.blocked, "speed_multiplier": edge_speed_multiplier(edge, mobility), "cost": edge_cost(edge, mobility) if edge_allowed(edge, mobility) else "IMPASSABLE"})
	return result

func infrastructure_event(item: Dictionary, event: String, now: float, source: String, cause: String) -> void:
	revision += 1
	infrastructure_history.append({"infrastructure": item.id, "event": event, "time": now, "source": source, "cause": cause, "state": item.state, "position": item.position, "revision": revision})
	print("INFRASTRUCTURE: ", JSON.stringify(infrastructure_history.back()))

func apply_blast_damage(point: Vector2, now: float, source: String) -> Array[String]:
	var interrupted: Array[String] = []
	for item in infrastructure.values():
		if item.position.distance_to(point) > INFRASTRUCTURE_HIT_RADIUS:
			continue
		if item.type == "Bridge" and item.state == "UNDER_RECONSTRUCTION":
			item.state = "DESTROYED"
			infrastructure_event(item, "reconstruction interrupted", now, source, "Spatial infrastructure impact")
			interrupted.append(item.id)
			continue
		if item.state != "INTACT":
			continue
		item.state = "DAMAGED" if item.type == "RoadSegment" else "DESTROYED"
		infrastructure_event(item, "road damaged" if item.type == "RoadSegment" else "bridge destroyed", now, source, "Spatial infrastructure impact")
	return interrupted

func repair_road(identity: String, now: float, source: String, job: String) -> void:
	var item: Dictionary = infrastructure[identity]
	if item.type != "RoadSegment" or item.state != "DAMAGED":
		return
	item.state = "INTACT"
	infrastructure_event(item, "road repaired", now, source, job)

func start_bridge_reconstruction(identity: String, now: float, source: String, job: String, resumed := false) -> void:
	var item: Dictionary = infrastructure[identity]
	if item.type != "Bridge" or item.state != "DESTROYED":
		return
	item.state = "UNDER_RECONSTRUCTION"
	item.reconstruction_job = job
	infrastructure_event(item, "reconstruction resumed" if resumed else "reconstruction started", now, source, job)

func complete_bridge_reconstruction(identity: String, now: float, source: String, job: String) -> void:
	var item: Dictionary = infrastructure[identity]
	if item.type != "Bridge" or item.state != "UNDER_RECONSTRUCTION" or item.get("reconstruction_job", "") != job:
		return
	item.state = "INTACT"
	infrastructure_event(item, "reconstruction completed", now, source, job)

func _init(supply) -> void:
	add_edge("depot-junction", "depot", "junction", "ROAD")
	add_edge("blocked-crossing", "junction", "crossing_exit", "ROAD", true)
	add_edge("east-road", "crossing_exit", "resupply", "ROAD")
	add_edge("south-road", "junction", "road_southwest", "ROAD")
	add_edge("lower-road", "road_southwest", "road_southeast", "ROAD")
	add_edge("return-road", "road_southeast", "resupply", "ROAD")
	add_edge("carrier-spawn", "carrier_start", "depot", "OFFROAD")
	add_edge("bypass-west", "junction", "offroad_west", "OFFROAD")
	add_edge("bypass-south", "offroad_west", "offroad_east", "OFFROAD")
	add_edge("bypass-east", "offroad_east", "crossing_exit", "OFFROAD")
	drivers = [Person.new("Driver-01", points.depot, 0), Person.new("Driver-02", points.carrier_start, 0)]
	truck = Vehicle.new(supply.truck.id, "ROAD_ONLY", "depot", points.depot, drivers[0])
	truck.inventory = supply.truck.inventory
	tracked = Vehicle.new("TrackedCarrier-01", "TRACKED", "carrier_start", points.carrier_start, drivers[1])
	tracked.speed = 56
	supply.truck = truck
	supply.vehicle_controller = weakref(self)

func add_edge(identity: String, start: String, end: String, terrain: String, blocked := false) -> void:
	edges.append({"id": identity, "a": start, "b": end, "terrain": terrain, "blocked": blocked})

func edge_allowed(edge: Dictionary, mobility: String) -> bool:
	var item := edge_infrastructure(edge)
	if not item.is_empty() and item.type == "Bridge" and item.state != "INTACT":
		return false
	return edge.terrain == "ROAD" or (edge.terrain == "OFFROAD" and mobility == "TRACKED")

func edge_between(start: String, end: String) -> Dictionary:
	for edge in edges:
		if (edge.a == start and edge.b == end) or (edge.b == start and edge.a == end):
			return edge
	return {}

func plan(start: String, goal: String, mobility: String, excluded: Dictionary) -> Array[String]:
	var costs := {start: 0.0}
	var previous: Dictionary = {}
	var open: Array[String] = [start]
	while not open.is_empty():
		open.sort_custom(func(a, b): return costs[a] < costs[b])
		var node: String = open.pop_front()
		if node == goal:
			break
		for edge in edges:
			if not edge_allowed(edge, mobility) or excluded.has(edge.id):
				continue
			var other := ""
			if edge.a == node:
				other = edge.b
			elif edge.b == node:
				other = edge.a
			else:
				continue
			var distance: float = costs[node] + edge_cost(edge, mobility)
			if distance < float(costs.get(other, INF)):
				costs[other] = distance
				previous[other] = node
				if other not in open:
					open.append(other)
	if not costs.has(goal):
		return []
	var result: Array[String] = [goal]
	while result[0] != start:
		result.push_front(previous[result[0]])
	return result

func legal_position(point: Vector2, mobility: String) -> bool:
	if infrastructure.is_empty() and BLOCKAGE.grow(3).has_point(point):
		return false
	for edge in edges:
		if edge_allowed(edge, mobility):
			var nearest := Geometry2D.get_closest_point_to_segment(point, points[edge.a], points[edge.b])
			if point.distance_to(nearest) <= ROAD_HALF_WIDTH:
				return true
	return false

func record(vehicle, now: float, reason: String, route_state: String) -> void:
	events.append({"time": now, "vehicle": vehicle.id, "driver": vehicle.driver.id, "driver_active": vehicle.driver.active, "assigned_vehicle": vehicle.driver.assigned_vehicle_id, "mobility": vehicle.mobility_class, "position": vehicle.position, "destination": vehicle.destination, "route": vehicle.route.duplicate(), "route_legal_world_diagnostic": vehicle.route_is_legal(self), "state": route_state, "cargo": vehicle.inventory.BoltActionRifleAmmo, "reason": reason})
	print("VEHICLE: ", JSON.stringify(events.back()))

func advance(delta: float, now: float) -> void:
	truck.advance(delta, now, self)
	tracked.advance(delta, now, self)
