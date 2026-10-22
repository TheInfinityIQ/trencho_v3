extends Node2D
## Rev5 artist PNGs are immutable; all controls affect diagnostics/presentation only.
const Space = preload("res://representative_space.gd")
const ROOT := "res://art/a1_rev5/"
const GRASS_ROOT := "res://art/a1_grass_rev6/"
const WALK_LOOP_SECONDS := 0.85
const WALK_ROUTE_METERS := 8.0
const WALK_PAUSE_SECONDS := 1.0
const TRUCK_DEMO_METERS_PER_SECOND := 3.0
const FILTERS := [CanvasItem.TEXTURE_FILTER_NEAREST, CanvasItem.TEXTURE_FILTER_LINEAR, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS]
const FILTER_NAMES := ["nearest", "linear", "linear+mipmaps"]
var metadata: Dictionary
var textures: Dictionary = {}
var camera: Camera2D
var hud: Control
var font: Font
var elapsed := 0.0
var paused := false
var diagnostic_overlays := true
var filter_index := 2
var focus := "context"
var zoom_value := 0.3125
var pose_case := -1
var source_ratio := 1.0
var rifle: Node2D
var rifle_sprite: Sprite2D
var idle: Node2D
var truck: Node2D
var hull: Node2D
var turret: Node2D
var house: Node2D
var tree: Node2D
var frame_index := 0
var actor_moving := true
var corner_origin := Vector2.ZERO
var last_truck_sample: Dictionary = {}
var world_overlay: Node2D
var house_pivot_source := Vector2.ZERO

class ArtHUD extends Control:
	var host
	func _draw() -> void:
		host.draw_overlay(self)

class WorldOverlay extends Node2D:
	var host
	func _draw() -> void:
		host.draw_world_overlay(self)

func source_vec(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func actor(point_m: Vector2) -> Node2D:
	var node := Node2D.new()
	node.position = Space.point_to_world(point_m)
	node.scale = Vector2.ONE * source_ratio
	add_child(node)
	return node

func sprite(file: String, pivot: Vector2, parent: Node2D) -> Sprite2D:
	var item := Sprite2D.new()
	item.texture = textures[file]
	item.centered = false
	item.offset = -pivot
	parent.add_child(item)
	return item

func _ready() -> void:
	font = ThemeDB.fallback_font
	metadata = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "docs/metadata.json"))
	source_ratio = Space.WORLD_UNITS_PER_METER / float(metadata.source_scale_px_per_m)
	for item in metadata.infantry.frames: textures[item.file] = load(ROOT + item.file)
	for file in metadata.terrain.files: textures[file] = load(GRASS_ROOT + file)
	for item in metadata.roads.values(): textures[item.file] = load(ROOT + item.file)
	for key in ["truck", "house", "tree"]:
		textures[metadata[key].file] = load(ROOT + metadata[key].file)
	for key in ["hull_file", "turret_file"]:
		textures[metadata.tank[key]] = load(ROOT + metadata.tank[key])
	texture_filter = FILTERS[filter_index]
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.enabled = true
	# A/A, A/B, B/B, both orientations and all four cardinal rotations.
	for row in range(4):
		for col in range(4):
			var tile := actor(Vector2(8 + col * 8, 8 + row * 8))
			tile.rotation = ((row + col) % 4) * PI / 2
			sprite(metadata.terrain.files[(floori(col / 2.0) + row) % 2], Vector2(128, 128), tile)
	corner_origin = Space.point_to_world(Vector2(32, 32))
	var corner := actor(Vector2(32, 32))
	sprite(metadata.roads.corner_90.file, Vector2.ZERO, corner)
	var south: Vector2 = source_vec(metadata.roads.corner_90.connections[0].center_px)
	var east: Vector2 = source_vec(metadata.roads.corner_90.connections[1].center_px)
	var straight_south := actor(Space.point_to_meters(corner_origin + Vector2(south.x, 640) * source_ratio))
	sprite(metadata.roads.straight.file, Vector2(128, 128), straight_south)
	var straight_east := actor(Space.point_to_meters(corner_origin + Vector2(640, east.y) * source_ratio))
	straight_east.rotation = PI / 2
	sprite(metadata.roads.straight.file, Vector2(128, 128), straight_east)
	rifle = actor(Vector2(58, 52))
	rifle_sprite = sprite(metadata.infantry.frames[0].file, source_vec(metadata.infantry.body_pivot_px), rifle)
	idle = actor(Vector2(60, 47))
	sprite(metadata.infantry.frames[0].file, source_vec(metadata.infantry.body_pivot_px), idle)
	truck = actor(Vector2.ZERO)
	sprite(metadata.truck.file, source_vec(metadata.truck.pivot_px), truck)
	hull = actor(Vector2(82, 52))
	sprite(metadata.tank.hull_file, source_vec(metadata.tank.hull_pivot_px), hull)
	turret = Node2D.new()
	turret.position = source_vec(metadata.tank.turret_ring_center_on_hull_px) - source_vec(metadata.tank.hull_pivot_px)
	hull.add_child(turret)
	sprite(metadata.tank.turret_file, source_vec(metadata.tank.turret_pivot_px), turret)
	house = actor(Vector2(68, 50))
	var footprint: Array = metadata.house.authoritative_footprint_rect_px
	house_pivot_source = (Vector2(footprint[0], footprint[1]) + Vector2(footprint[2], footprint[3])) / 2
	sprite(metadata.house.file, house_pivot_source, house)
	tree = actor(Vector2(86, 36))
	sprite(metadata.tree.file, source_vec(metadata.tree.trunk_collision_center_px), tree)
	world_overlay = WorldOverlay.new()
	world_overlay.host = self
	add_child(world_overlay)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = ArtHUD.new()
	hud.host = self
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	for pair in [["1 Zoom 1.0", 1.0], ["2 Zoom 0.5", 0.5], ["3 Zoom 0.25", 0.25], ["4 SCL local 0.3125", 0.3125]]:
		var i: int = hud.get_child_count()
		button(pair[0], Vector2(14 + i * 224, 51), 215, set_zoom.bind(pair[1]))
	var focuses := [["G Grass", "grass"], ["R Road", "road"], ["H House", "house"], ["W Context", "context"]]
	for i in range(focuses.size()): button(focuses[i][0], Vector2(14 + 132 * i, 87), 125, set_focus.bind(focuses[i][1]))
	button("F Filter", Vector2(550, 87), 120, cycle_filter)
	button("D Overlays", Vector2(678, 87), 130, toggle_overlays)
	button("K Tank poses", Vector2(816, 87), 150, cycle_pose)
	button("Space Pause", Vector2(974, 87), 160, toggle_pause)
	set_focus("context")
	apply_sample(0)

func button(text: String, point: Vector2, width: float, action: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = Vector2(width, 30)
	item.focus_mode = Control.FOCUS_NONE
	item.pressed.connect(action)
	hud.add_child(item)

func set_zoom(value: float) -> void:
	zoom_value = value
	camera.zoom = Vector2.ONE * value
	camera.force_update_scroll()

func set_focus(value: String) -> void:
	focus = value
	var point := Vector2(64, 29)
	if value == "grass": point = Vector2(20, 10)
	if value == "road": point = Vector2(44, 42)
	if value == "house": point = Vector2(68, 47)
	camera.position = Space.point_to_world(point)
	set_zoom(zoom_value)

func cycle_filter() -> void:
	filter_index = (filter_index + 1) % FILTERS.size()
	texture_filter = FILTERS[filter_index]

func toggle_overlays() -> void:
	diagnostic_overlays = not diagnostic_overlays

func toggle_pause() -> void:
	paused = not paused

func cycle_pose() -> void:
	pose_case = pose_case + 1 if pose_case < 3 else -1

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_1: set_zoom(1.0)
		KEY_2: set_zoom(0.5)
		KEY_3: set_zoom(0.25)
		KEY_4: set_zoom(Space.ZOOMS.local)
		KEY_G: set_focus("grass")
		KEY_R: set_focus("road")
		KEY_H: set_focus("house")
		KEY_W: set_focus("context")
		KEY_F: cycle_filter()
		KEY_D: toggle_overlays()
		KEY_K: cycle_pose()
		KEY_SPACE: toggle_pause()

func truck_path(distance_px: float) -> Dictionary:
	var road: Dictionary = metadata.roads.corner_90
	var start := source_vec(road.connections[0].center_px)
	var end := source_vec(road.connections[1].center_px)
	var center := source_vec(road.centerline_definition.center_px)
	var radius: float = road.centerline_definition.radius_px
	var leg := 768.0 - start.y
	var arc := radius * PI / 2
	if distance_px < leg:
		return {"point": start + Vector2(0, leg - distance_px), "direction": Vector2.UP, "on_curve": false}
	if distance_px < leg + arc:
		var angle := PI + (distance_px - leg) / radius
		return {"point": center + Vector2(cos(angle), sin(angle)) * radius, "direction": Vector2(-sin(angle), cos(angle)), "on_curve": true}
	return {"point": end + Vector2(clampf(distance_px - leg - arc, 0, 768 - end.x), 0), "direction": Vector2.RIGHT, "on_curve": false}

func apply_sample(seconds: float) -> void:
	elapsed = seconds
	var move_seconds := WALK_ROUTE_METERS / Space.WALK_METERS_PER_SECOND
	var leg_seconds := move_seconds + WALK_PAUSE_SECONDS
	var phase := fposmod(seconds, 4 * leg_seconds)
	var side := floori(phase / leg_seconds)
	var leg_time := fposmod(phase, leg_seconds)
	var corners := [Vector2(58, 52), Vector2(66, 52), Vector2(66, 60), Vector2(58, 60)]
	var direction: Vector2 = (corners[(side + 1) % 4] - corners[side]).normalized()
	rifle.position = Space.point_to_world(corners[side] + direction * minf(leg_time * 1.4, WALK_ROUTE_METERS))
	actor_moving = leg_time < move_seconds
	rifle.rotation = direction.angle() + PI / 2
	if not actor_moving:
		rifle.rotation += (leg_time - move_seconds) / WALK_PAUSE_SECONDS * PI / 2
	frame_index = 1 + floori(fposmod(seconds, WALK_LOOP_SECONDS) / WALK_LOOP_SECONDS * 8) if actor_moving else 0
	rifle_sprite.texture = textures[metadata.infantry.frames[frame_index].file]
	idle.rotation = seconds * 0.3
	var radius: float = metadata.roads.corner_90.centerline_definition.radius_px
	var path_pixels := 2 * 257.0 + radius * PI / 2
	var travel_seconds := path_pixels / float(metadata.source_scale_px_per_m) / TRUCK_DEMO_METERS_PER_SECOND
	var travel_time := minf(fposmod(seconds, travel_seconds + 2), travel_seconds)
	last_truck_sample = truck_path(travel_time * TRUCK_DEMO_METERS_PER_SECOND * float(metadata.source_scale_px_per_m))
	truck.position = corner_origin + last_truck_sample.point * source_ratio
	truck.rotation = last_truck_sample.direction.angle() + PI / 2
	var hull_degrees := seconds * 9
	var turret_degrees := seconds * -15
	if pose_case >= 0:
		var poses := [[0.0, 0.0], [0.0, 45.0], [45.0, 0.0], [45.0, 225.0]]
		hull_degrees = poses[pose_case][0]
		turret_degrees = poses[pose_case][1]
	hull.rotation = deg_to_rad(hull_degrees)
	turret.rotation = deg_to_rad(turret_degrees) - hull.rotation
	queue_redraw()
	world_overlay.queue_redraw()
	hud.queue_redraw()

func _physics_process(delta: float) -> void:
	if not paused: apply_sample(elapsed + delta)

func _process(delta: float) -> void:
	var pan := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if pan != Vector2.ZERO:
		camera.position += Space.point_to_world(pan * 10 * delta)
	queue_redraw()
	world_overlay.queue_redraw()
	hud.queue_redraw()

func rifle_muzzle_world() -> Vector2:
	return rifle.to_global(source_vec(metadata.infantry.frames[frame_index].muzzle_px) - source_vec(metadata.infantry.body_pivot_px))

func tank_muzzle_world() -> Vector2:
	return turret.to_global(source_vec(metadata.tank.muzzle_point_px) - source_vec(metadata.tank.turret_pivot_px))

func _draw() -> void:
	if camera == null: return
	draw_rect(Rect2(Vector2.ZERO, Space.point_to_world(Vector2(128, 128))), Color("334c39"))

func draw_world_overlay(canvas: Node2D) -> void:
	if not diagnostic_overlays: return
	var pixel := 1.0 / camera.zoom.x
	for node in [rifle, truck, hull, house, tree]: canvas.draw_circle(node.position, 3 * pixel, Color("e9c85e"))
	canvas.draw_circle(rifle_muzzle_world(), 3 * pixel, Color("77e9eb"))
	canvas.draw_circle(tank_muzzle_world(), 3 * pixel, Color("77e9eb"))
	canvas.draw_rect(Rect2(Space.point_to_world(Vector2(64, 44)), Space.point_to_world(Vector2(8, 12))), Color("8de0e4"), false, pixel)
	canvas.draw_circle(tree.position, float(metadata.tree.trunk_collision_radius_px) * source_ratio, Color("8de0e4"), false, pixel)
	var entry := source_vec(metadata.house.entrance_point_px) - house_pivot_source
	canvas.draw_circle(house.to_global(entry), 3 * pixel, Color("efb190"))

func label(control: Control, point: Vector2, text: String, size := 15) -> void:
	control.draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("dce8e3"))

func draw_overlay(control: Control) -> void:
	var viewport := get_viewport_rect().size
	control.draw_rect(Rect2(0, 0, viewport.x, 143), Color("102026"))
	label(control, Vector2(14, 23), "REV5 + GRASS REV6 / isolated scale and motion review / road and house provisional", 18)
	label(control, Vector2(14, 44), "%s | zoom %.4f | %s | 32 world units/m | walk 1.4 m/s / loop %.2f s | t %.2f" % [focus, camera.zoom.x, FILTER_NAMES[filter_index], WALK_LOOP_SECONDS, elapsed])
	label(control, Vector2(14, 135), "Grass seams / road markings / house projection: evaluate at normal viewing scale. Arrows pan; K cycles independent tank poses.", 14)
	control.draw_rect(Rect2(0, viewport.y - 48, viewport.x, 48), Color("102026"))
	label(control, Vector2(14, viewport.y - 27), "Actual artist PNGs; no code repainting. Truck loop restarts after end hold; not a traffic/steering simulation.", 14)
	var length := Space.ruler_meters(Space.visible_meters(viewport, camera.zoom.x).x)
	var pixels := length * Space.WORLD_UNITS_PER_METER * camera.zoom.x
	control.draw_line(Vector2(14, viewport.y - 12), Vector2(14 + pixels, viewport.y - 12), Color.WHITE, 2)
	label(control, Vector2(22 + pixels, viewport.y - 8), "%.0f m" % length, 14)
