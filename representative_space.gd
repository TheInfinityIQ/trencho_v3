extends RefCounted
## Isolated diagnostic meters. Accepted campaign fixtures retain their own units.
const WORLD_UNITS_PER_METER := 32.0
const MAP_METERS := Vector2(6000, 8000)
const CHUNK_METERS := 256.0
const CHUNK_COUNT := Vector2i(24, 32)
const DISTRICT_METERS := Rect2(300, 500, 400, 400)
const SITE_METERS := Vector2(360, 640)
const WALK_METERS_PER_SECOND := 1.4
const TRUCK_METERS_PER_SECOND := 12.0 # Calibration only, not vehicle balance.
const ROUTE_METERS := 100.0
const TRUCK_SIZE_METERS := Vector2(6.0, 2.4) # Length along route / width.
const ROAD_WIDTH_METERS := 6.0
const ZOOMS := {"local": 0.3125, "district": 800.0 / (700.0 * 32.0), "tactical": 0.025, "operation": 800.0 / (13000.0 * 32.0)}
const LANDMARKS := [
	{"name": "LOGISTICS DISTRICT", "point": Vector2(500, 700)},
	{"name": "VILLAGE / diagnostic objective", "point": Vector2(2200, 1800)},
	{"name": "CROSSING", "point": Vector2(3400, 3900)},
	{"name": "DEPOT", "point": Vector2(1400, 6000)},
	{"name": "DISTANT OBJECTIVE", "point": Vector2(5400, 7400)}
]

static func meters_to_world(value: float) -> float:
	return value * WORLD_UNITS_PER_METER

static func world_to_meters(value: float) -> float:
	return value / WORLD_UNITS_PER_METER

static func km_to_world(value: float) -> float:
	return meters_to_world(value * 1000.0)

static func point_to_world(point: Vector2) -> Vector2:
	return point * WORLD_UNITS_PER_METER

static func point_to_meters(point: Vector2) -> Vector2:
	return point / WORLD_UNITS_PER_METER

static func contains_meters(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, MAP_METERS).has_point(point)

static func chunk_for_world(point: Vector2) -> Vector2i:
	var meters := point_to_meters(point)
	return Vector2i(floori(meters.x / CHUNK_METERS), floori(meters.y / CHUNK_METERS))

static func chunk_origin_world(chunk: Vector2i) -> Vector2:
	return point_to_world(Vector2(chunk) * CHUNK_METERS)

static func chunk_bounds_meters(chunk: Vector2i) -> Rect2:
	if chunk.x < 0 or chunk.y < 0 or chunk.x >= CHUNK_COUNT.x or chunk.y >= CHUNK_COUNT.y:
		return Rect2()
	return Rect2(Vector2(chunk) * CHUNK_METERS, Vector2.ONE * CHUNK_METERS).intersection(Rect2(Vector2.ZERO, MAP_METERS))

static func positions_at(seconds: float, origin := SITE_METERS) -> Dictionary:
	var walk := clampf(seconds * WALK_METERS_PER_SECOND, 0, ROUTE_METERS)
	var truck := clampf(seconds * TRUCK_METERS_PER_SECOND, 0, ROUTE_METERS)
	return {"soldier": origin + Vector2(walk, 4), "truck": origin + Vector2(truck, -3), "walk_m": walk, "truck_m": truck}

static func visible_meters(viewport: Vector2, zoom: float) -> Vector2:
	return viewport / (zoom * WORLD_UNITS_PER_METER)

static func ruler_meters(visible_width: float) -> float:
	var target := visible_width / 6.0
	var base := pow(10.0, floor(log(target) / log(10.0)))
	for factor in [5.0, 2.0, 1.0]:
		if base * factor <= target:
			return base * factor
	return base / 2.0
