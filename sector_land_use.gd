extends RefCounted
## Bounded land-use parcel placement, independent of terrain texture selection.
const Layout = preload("res://sector_layout.gd")
const VERSION := "env036-parcels-v1"
var parcels: Array = []

func generate(layout) -> Array:
	parcels.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = layout.seed_value ^ 360036
	for family in ["field", "meadow"]:
		var target := 6 if family == "field" else 3
		var placed := 0
		for attempt in range(300):
			if placed == target: break
			var size := Vector2(rng.randi_range(18, 30), rng.randi_range(12, 22)) * 8
			var quarter_turns := rng.randi_range(0, 1)
			if quarter_turns == 1: size = Vector2(size.y, size.x)
			var point := Vector2(rng.randi_range(6, floori((Layout.SIZE.x - size.x) / 8) - 6), rng.randi_range(6, floori((Layout.SIZE.y - size.y) / 8) - 6)) * 8
			var rect := Rect2(point, size)
			if not allowed(rect, layout): continue
			var center := rect.get_center()
			var end := rect.end
			var polygon := [point + Vector2(8, 0), Vector2(end.x - 8, point.y + rng.randf_range(0, 3)), Vector2(end.x, point.y + 8), end - Vector2(rng.randf_range(0, 3), 8), end - Vector2(8, 0), Vector2(point.x + 8, end.y - rng.randf_range(0, 3)), Vector2(point.x, end.y - 8), point + Vector2(rng.randf_range(0, 3), 8)]
			parcels.append({"id":"%s-%d" % [family, placed], "family":family, "bounds":rect, "polygon":polygon, "position":center, "owner":Layout.owner(center), "turns":quarter_turns})
			placed += 1
	return parcels

func allowed(rect: Rect2, layout) -> bool:
	for parcel in parcels:
		if parcel.bounds.grow(16).intersects(rect): return false
	for house in layout.houses:
		# Includes space for the approved larger-footprint variants and their yards.
		if house.footprint.grow(24).intersects(rect): return false
	for road in layout.roads:
		# A quarter arc lies in the AABB of its ports. Conservative rejection avoids
		# fields on pavement/shoulders without depending on an art edge shader.
		var low: Vector2 = road.entry.min(road.exit)
		var high: Vector2 = road.entry.max(road.exit)
		if Rect2(low, high - low).grow(16).intersects(rect): return false
	return true

func family_at(point: Vector2) -> String:
	for parcel in parcels:
		if parcel.bounds.has_point(point) and Geometry2D.is_point_in_polygon(point, PackedVector2Array(parcel.polygon)): return parcel.family
	return "grass"

func cultivated(point: Vector2, clearance := 0.0) -> bool:
	for parcel in parcels:
		if parcel.family == "field" and parcel.bounds.grow(clearance).has_point(point): return true
	return false
