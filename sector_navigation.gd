extends RefCounted
## Bounded infantry routing in meters. Envelopes are presentation avoidance only.
const Layout = preload("res://sector_layout.gd")
const GRID := 64.0
const CLEARANCE := 5.0
var points: Array[Vector2] = []
var road_flags: Array[bool] = []
var envelopes: Array[Rect2] = []
var graph: AStar2D
var route_queries := 0
var edge_count := 0

class Graph extends AStar2D:
	func _estimate_cost(from: int, to: int) -> float:
		return get_point_position(from).distance_to(get_point_position(to)) * 0.85

func _init(layout, environment) -> void:
	graph = Graph.new()
	for property in environment.properties: envelopes.append(property.presentation_clearance_bounds.grow(CLEARANCE))
	for y in range(int(Layout.SIZE.y / GRID)):
		for x in range(int(Layout.SIZE.x / GRID)):
			var point := Vector2(x + 0.5, y + 0.5) * GRID
			add_anchor(point, layout.road_distance(point) < 6)
	# Sample the generated corridor, not a seed-authored route. Include flanks so
	# infantry can leave roads and enter open ground without a dense nav mesh.
	for distance in range(0, ceili(layout.route_length), 32):
		var sample: Dictionary = layout.sample_route(distance)
		var normal := Vector2(-sample.direction.y, sample.direction.x)
		for offset in [-8.0, 0.0, 8.0]: add_anchor(sample.position + normal * offset, true)
	for bounds in envelopes:
		var outer := bounds.grow(0.05)
		for point in [outer.position, Vector2(outer.end.x, outer.position.y), outer.end, Vector2(outer.position.x, outer.end.y)]: add_anchor(point, false)
	for i in range(points.size()):
		for j in range(i):
			if points[i].distance_squared_to(points[j]) <= 96 * 96 and clear_segment(points[i], points[j]):
				graph.connect_points(i, j); edge_count += 1

func clear_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ONE * 6, Layout.SIZE - Vector2.ONE * 12).has_point(point): return false
	for bounds in envelopes:
		if bounds.has_point(point): return false
	return true

func clear_segment(a: Vector2, b: Vector2) -> bool:
	var span := Rect2(a, Vector2.ZERO).expand(b).grow(0.001)
	for bounds in envelopes:
		if not span.intersects(bounds): continue
		if bounds.has_point(a) or bounds.has_point(b): return false
		var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
		for edge in range(4):
			if Geometry2D.segment_intersects_segment(a, b, corners[edge], corners[(edge + 1) % 4]) != null: return false
	return true

func add_anchor(point: Vector2, road: bool) -> void:
	if not clear_point(point): return
	for existing in points:
		if point.distance_squared_to(existing) < 0.01: return
	var id := points.size()
	points.append(point); road_flags.append(road)
	graph.add_point(id, point, 0.85 if road else 1.0)

func safe_position(wanted: Vector2) -> Vector2:
	if clear_point(wanted): return wanted
	return points[graph.get_closest_point(wanted)]

func connect_endpoint(id: int, point: Vector2) -> void:
	graph.add_point(id, point)
	var candidates := []
	for i in range(points.size()): candidates.append({"id":i, "distance":point.distance_squared_to(points[i])})
	candidates.sort_custom(func(a, b): return a.distance < b.distance if a.distance != b.distance else a.id < b.id)
	var linked := 0
	for candidate in candidates:
		if clear_segment(point, points[candidate.id]):
			graph.connect_points(id, candidate.id); linked += 1
			if linked == 12: break

func route(start: Vector2, destination: Vector2) -> Array[Vector2]:
	route_queries += 1
	var result: Array[Vector2] = []
	if not clear_point(start) or not clear_point(destination): return result
	var first := points.size(); var last := first + 1
	connect_endpoint(first, start); connect_endpoint(last, destination)
	if clear_segment(start, destination): graph.connect_points(first, last)
	var path := graph.get_point_path(first, last)
	graph.remove_point(first); graph.remove_point(last)
	for i in range(1, path.size()): result.append(path[i])
	return result
