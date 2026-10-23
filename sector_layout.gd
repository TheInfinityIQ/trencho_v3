extends RefCounted
## Versioned, seed-local composition in design meters. No scene or global RNG writes.
const VERSION := "map035-v1"
const DEFAULT_SEED := 35035
const ALTERNATE_SEED := 35036
const SIZE := Vector2(1536, 1024)
const CHUNKS := Vector2i(6, 4)
const PX := 32.0
const CHUNK := 256.0
var seed_value: int
var chunks: Array = []
var roads: Array = []
var houses: Array = []
var trees: Array = []
var spawns: Array = []
var route_length := 0.0
var village := Vector2.ZERO
var village_distance := 0.0
var fingerprint := ""

static func turn(p: Vector2, q: int) -> Vector2:
	match posmod(q, 4):
		1: return Vector2(-p.y, p.x)
		2: return -p
		3: return Vector2(p.y, -p.x)
	return p

static func owner(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CHUNK), floori(p.y / CHUNK))

static func bounds(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CHUNK, Vector2.ONE * CHUNK)

func index_object(item: Dictionary, kind: String, index: int) -> void:
	item["owner"] = owner(item.position)
	chunks[item.owner.y * CHUNKS.x + item.owner.x][kind].append(index)

func generate(value: int) -> void:
	seed_value = value
	chunks.clear(); roads.clear(); houses.clear(); trees.clear(); spawns.clear()
	route_length = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	for y in range(CHUNKS.y):
		for x in range(CHUNKS.x):
			var variants := PackedByteArray()
			var rotations := PackedByteArray()
			for tile in range(1024):
				variants.append(rng.randi_range(0, 1))
				rotations.append(rng.randi_range(0, 3))
			chunks.append({"key":Vector2i(x, y), "variants":variants, "rotations":rotations, "roads":[], "houses":[], "trees":[], "spawns":[]})
	var point := Vector2(0, rng.randi_range(440, 584) * PX)
	var heading := 0 # E, S, W, N in screen coordinates.
	var prefix := rng.randi_range(54, 70)
	for i in range(prefix): point = add_road(point, heading, "straight")
	village_distance = route_length * 0.6
	village = sample_route(village_distance).position
	var right := rng.randi_range(0, 1) == 0
	point = add_road(point, heading, "corner", right)
	heading = posmod(heading + (1 if right else -1), 4)
	for i in range(rng.randi_range(14, 28)): point = add_road(point, heading, "straight")
	point = add_road(point, heading, "corner", not right)
	heading = 0
	while point.x < SIZE.x * PX: point = add_road(point, heading, "straight")
	var per_side := rng.randi_range(4, 8)
	for side in [-1, 1]:
		for i in range(per_side):
			var p := village + Vector2((i - (per_side - 1) * 0.5) * 23 + rng.randf_range(-1, 1), side * rng.randf_range(17, 23))
			var item := {"position":p, "turns":0 if side == -1 else 2, "footprint":Rect2(p - Vector2(4, 6), Vector2(8, 12))}
			houses.append(item)
			index_object(item, "houses", houses.size() - 1)
	for i in range(16):
		var side := -1 if i < 8 else 1
		var p := village + Vector2((i % 8 - 3.5) * 7, side * (6.5 + (i % 3) * 0.45))
		var d := Vector2(18 if i % 2 == 0 else -18, side * (0.4 + (i % 3) * 0.25))
		var item := {"position":p, "route":[p + d, p], "speed":1.4}
		spawns.append(item)
		index_object(item, "spawns", i)
	var groves: Array = [{"position":village + Vector2(64, -56), "radii":Vector2(58, 21), "turns":0}]
	for i in range(6):
		groves.append({"position":Vector2(rng.randf_range(90, SIZE.x - 90), rng.randf_range(90, SIZE.y - 90)), "radii":Vector2(rng.randf_range(45, 110), rng.randf_range(18, 55)), "turns":rng.randi_range(0, 3)})
	var target := rng.randi_range(190, 250)
	for attempt in range(target * 100):
		if trees.size() == target: break
		var grove: Dictionary = groves[attempt % groves.size()]
		var angle := rng.randf_range(0, TAU)
		var p: Vector2 = grove.position + turn(Vector2(cos(angle), sin(angle)) * sqrt(rng.randf()) * grove.radii, grove.turns)
		if not tree_allowed(p): continue
		var item := {"position":p, "turns":rng.randi_range(0, 3), "trunk_radius":0.375, "canopy_radius":3.0}
		trees.append(item)
		index_object(item, "trees", trees.size() - 1)
	fingerprint = JSON.stringify(canonical({"version":VERSION, "seed":value, "chunks":chunks, "roads":roads, "houses":houses, "trees":trees, "spawns":spawns}), "", true, true).sha256_text()

func add_road(entry: Vector2, heading: int, kind: String, right := true) -> Vector2:
	var q := posmod(heading - 1, 4)
	var start := Vector2(128, 0)
	var finish := Vector2(128, 255)
	var length := 255.0 / PX
	if kind == "corner":
		q = posmod(heading + 1 if right else heading - 2, 4)
		start = Vector2(200, 511) if right else Vector2(511, 200)
		finish = Vector2(511, 200) if right else Vector2(200, 511)
		length = 311.0 / PX * PI / 2
	var origin := entry - turn(start, q)
	var exit := origin + turn(finish, q)
	# A through-exit canvas may overhang the sector. Its owner is on the visible road.
	var midpoint := ((entry + exit) * 0.5 / PX).clamp(Vector2.ZERO, SIZE - Vector2.ONE * 0.001)
	var item := {"kind":kind, "position":midpoint, "origin_px":origin, "turns":q, "right":right, "entry":entry / PX, "exit":exit / PX, "distance":route_length, "length":length}
	roads.append(item)
	index_object(item, "roads", roads.size() - 1)
	route_length += length
	return exit

func sample_segment(item: Dictionary, distance: float) -> Dictionary:
	var t := clampf(distance / item.length, 0, 1)
	if item.kind == "straight":
		return {"position":item.entry.lerp(item.exit, t), "direction":(item.exit - item.entry).normalized()}
	var angle := PI + t * PI / 2 if item.right else PI * 1.5 - t * PI / 2
	var radial := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-radial.y, radial.x) * (1 if item.right else -1)
	return {"position":(item.origin_px + turn(Vector2(511, 511) + radial * 311, item.turns)) / PX, "direction":turn(tangent, item.turns)}

func sample_route(distance: float) -> Dictionary:
	var d := clampf(distance, 0, route_length)
	for item in roads:
		if d <= item.distance + item.length: return sample_segment(item, d - item.distance)
	return sample_segment(roads.back(), roads.back().length)

func distance_to_segment(p: Vector2, item: Dictionary) -> float:
	if item.kind == "straight":
		return p.distance_to(Geometry2D.get_closest_point_to_segment(p, item.entry, item.exit))
	var local := turn(p * PX - item.origin_px, -item.turns) - Vector2(511, 511)
	if local.x <= 0 and local.y <= 0: return absf(local.length() - 311) / PX
	return minf(p.distance_to(item.entry), p.distance_to(item.exit))

func road_distance(p: Vector2) -> float:
	var result := INF
	for item in roads: result = minf(result, distance_to_segment(p, item))
	return result

func tree_allowed(p: Vector2) -> bool:
	if not Rect2(Vector2.ONE * 4, SIZE - Vector2.ONE * 8).has_point(p) or road_distance(p) < 7: return false
	for house in houses:
		if house.footprint.grow(4).has_point(p): return false
	for spawn in spawns:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, spawn.position, spawn.route[0])) < 2.0: return false
	for tree in trees:
		if p.distance_to(tree.position) < 1.25: return false
	return true

static func canonical(value):
	if value is Vector2 or value is Vector2i: return [value.x, value.y]
	if value is Rect2: return [value.position.x, value.position.y, value.size.x, value.size.y]
	if value is PackedByteArray: return value.hex_encode()
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = canonical(value[key])
		return result
	if value is Array:
		var result := []
		for item in value: result.append(canonical(item))
		return result
	return value
