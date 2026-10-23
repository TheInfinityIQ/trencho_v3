extends RefCounted
## Presentation-only clearances/access anchors; never wall, collision or nav data.
const Layout = preload("res://sector_layout.gd")

static func vec(values: Array) -> Vector2:
	return Vector2(values[0], values[1])

static func compose(layout, catalog: Array) -> Array:
	var properties := []
	var rng := RandomNumberGenerator.new()
	rng.seed = layout.seed_value ^ 360037
	var offset := rng.randi_range(0, catalog.size() - 1)
	for i in range(layout.houses.size()):
		var source: Dictionary = catalog[(i + offset) % catalog.size()]
		var house: Dictionary = layout.houses[i]
		var q: int = house.turns
		var clearance: Array = source.clearance_px
		var pivot := vec(source.pivot_px)
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		for corner in [Vector2(clearance[0], clearance[1]), Vector2(clearance[2], clearance[1]), Vector2(clearance[2], clearance[3]), Vector2(clearance[0], clearance[3])]:
			var point: Vector2 = house.position + Layout.turn((corner - pivot) / 32, q)
			low = low.min(point); high = high.max(point)
		var door: Vector2 = house.position + Layout.turn((vec(source.entrance_px) - pivot) / 32, q)
		var side := signf(house.position.y - layout.village.y)
		var access_start := Vector2(door.x, layout.village.y + side * 3)
		var direction := (access_start - door).normalized()
		var yard := door + direction * 2
		properties.append({"id":"property-%02d" % i, "asset":source.id, "position":house.position, "owner":Layout.owner(house.position), "turns":q, "presentation_clearance_bounds":Rect2(low, high - low), "presentation_access_anchor":door, "road_access":access_start, "yard":yard, "access_direction":direction, "reserve":Rect2(low, high - low).merge(Rect2(access_start - Vector2.ONE * 3, Vector2.ONE * 6)).grow(1)})
	return properties

static func tree_clear(point: Vector2, properties: Array) -> bool:
	for property in properties:
		if property.presentation_clearance_bounds.grow(4).has_point(point): return false
		if point.distance_to(property.yard) < 5: return false
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, property.road_access, property.presentation_access_anchor)) < 3: return false
	return true

static func access_modules(properties: Array) -> Array:
	# Physical endpoint spans, not canvas bounds. Overlap full authored pieces;
	# never stretch the ground texture to bridge an arbitrary setback.
	var modules := []
	for property in properties:
		var start: Vector2 = property.road_access
		var finish: Vector2 = property.yard
		var direction := (finish - start).normalized()
		var distance := start.distance_to(finish)
		var cursor := 0.0
		while cursor < distance:
			var length := 8.0 if distance - cursor > 5 else 4.0
			var piece_start := minf(cursor, maxf(0, distance - length))
			var point := start + direction * (piece_start + length * 0.5)
			modules.append({"asset":"driveway_long" if length == 8 else "driveway_short", "position":point, "owner":Layout.owner(point), "turns":property.turns, "property":property.id, "span":length})
			if piece_start + length >= distance: break
			cursor += length * 0.8
		for spec in [["yard_gravel", property.yard], ["worn_ground", property.presentation_access_anchor]]:
			modules.append({"asset":spec[0], "position":spec[1], "owner":Layout.owner(spec[1]), "turns":property.turns, "property":property.id})
	return modules
