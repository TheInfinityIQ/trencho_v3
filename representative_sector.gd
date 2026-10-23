extends Node2D
## Bounded composition host. The existing campaign and vehicle simulation are untouched.
const Layout = preload("res://sector_layout.gd")
const Space = preload("res://representative_space.gd")
const Person = preload("res://soldier.gd")
const Visual = preload("res://soldier_visual.gd")
const Rural = preload("res://sector_environment.gd")
const ParcelShader = preload("res://sector_parcel.gdshader")
const Autonomous = preload("res://sector_scenario.gd")
var world
var layout = Layout.new()
var environment = Rural.new()
var parcel_materials: Array = []
var chunk_nodes: Array = []
var people: Array = []
var visuals: Array = []
var actor_chunks: Array = []
var camera: Camera2D
var truck: Sprite2D
var static_root: Node2D
var actors: Node2D
var overlay: Node2D
var moving_overlay: Node2D
var hud: Control
var status: Label
var textures := {}
var meshes := {}
var metadata: Dictionary
var mode := "local"
var debug_enabled := false
var paused := false
var elapsed := 0.0
var generation_count := 0
var generation_ms := 0.0
var update_us := 0
var active_chunks := 0
var truck_distance := 0.0
var batch_count := 0
const MAX_ZOOM := 2.0
const WHEEL_STEP := 1.18
const ZOOM_RESPONSE := 18.0
var zoom_target := 0.3125
var _zoom_anchor_screen := Vector2.ZERO
var _zoom_active := false
var _camera_initialized := false
var _active_chunk_range := Rect2i(-1, -1, 0, 0)
var activation_revision := 0
var _debug_elapsed := 0.0
var _previous_max_fps := -1
var _presentation_max_fps := -1

class Overlay extends Node2D:
	var host
	func _draw() -> void: host.draw_debug(self)

class MovingOverlay extends Node2D:
	var host
	func _draw() -> void: host.draw_moving_debug(self)

func _ready() -> void:
	# Lightweight views can run thousands of iterations/s even with VSync enabled
	# on the tested Compatibility backend. Pace independently of the F3 overlay.
	_previous_max_fps = Engine.max_fps
	var refresh := DisplayServer.screen_get_refresh_rate(get_window().current_screen) if DisplayServer.get_name() != "headless" else -1.0
	_presentation_max_fps = presentation_cap(refresh, _previous_max_fps)
	Engine.max_fps = _presentation_max_fps
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/a1_rev5/docs/metadata.json"))
	for i in range(2): textures["grass%d" % i] = load("res://art/a1_grass_rev6/terrain/terrain_grass_%02d.png" % (i + 1))
	textures.straight = load("res://art/a1_rev5/" + metadata.roads.straight.file)
	textures.corner = load("res://art/a1_rev5/" + metadata.roads.corner_90.file)
	textures.house = load("res://art/a1_rev5/" + metadata.house.file)
	textures.tree = load("res://art/a1_rev5/" + metadata.tree.file)
	textures.truck = load("res://art/a1_rev5/" + metadata.truck.file)
	var rural_metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/docs/metadata.json"))
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/provenance.json"))
	environment.configure(rural_metadata, provenance.archive_sha256)
	for key in environment.catalog: textures[key] = load(environment.catalog[key].file)
	for family in ["meadow", "field"]:
		for i in range(2): textures[family + str(i)] = load("res://art/env036/terrain/%s_%02d.png" % [family, i + 1])
	static_root = Node2D.new(); add_child(static_root)
	actors = Node2D.new(); actors.z_index = 2; add_child(actors)
	truck = Sprite2D.new(); truck.texture = textures.truck; truck.centered = false; truck.offset = Vector2(-128, -128); actors.add_child(truck)
	camera = Camera2D.new(); add_child(camera); camera.enabled = true
	overlay = Overlay.new(); overlay.host = self; overlay.z_index = 10; add_child(overlay)
	moving_overlay = MovingOverlay.new(); moving_overlay.host = self; moving_overlay.z_index = 10; add_child(moving_overlay)
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(hud)
	var bar := ColorRect.new(); bar.color = Color(0.035, 0.05, 0.04, 0.92); bar.size = Vector2(2000, 48); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(bar)
	var title := Label.new(); title.text = "TRENCHO  ·  Rural sector"; title.position = Vector2(16, 12); hud.add_child(title)
	var actions := [["1 Local", set_mode.bind("local")], ["2 Tactical", set_mode.bind("tactical")], ["3 Sector", set_mode.bind("sector")], ["N New seed", next_seed], ["F3 Details", toggle_debug], ["Space Pause", toggle_pause]]
	for i in range(actions.size()):
		var button := Button.new(); button.text = actions[i][0]; button.position = Vector2(255 + i * 142, 8); button.size = Vector2(134, 32); button.focus_mode = Control.FOCUS_NONE; button.pressed.connect(actions[i][1]); hud.add_child(button)
	var hint := Label.new(); hint.text = "WASD / arrows: pan   ·   Mouse wheel / 1–3: zoom"; hint.position = Vector2(16, 57); hint.add_theme_color_override("font_color", Color(0.94, 0.96, 0.89)); hud.add_child(hint)
	status = Label.new(); status.position = Vector2(16, 88); status.add_theme_color_override("font_color", Color.WHITE); hud.add_child(status)
	set_seed(Layout.DEFAULT_SEED)
	get_viewport().size_changed.connect(viewport_resized)

func _exit_tree() -> void:
	# Do not overwrite a later cap chosen by another owner while this scene ran.
	if _previous_max_fps >= 0 and Engine.max_fps == _presentation_max_fps:
		Engine.max_fps = _previous_max_fps

static func presentation_cap(refresh: float, previous: int) -> int:
	if not is_finite(refresh) or refresh <= 0:
		return previous if previous > 0 else 120
	var limit := ceili(refresh)
	return mini(previous, limit) if previous > 0 else limit

func quad(size: Vector2) -> ArrayMesh:
	var key := str(size)
	if meshes.has(key): return meshes[key]
	var half := size * 0.5
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-half.x, -half.y, 0), Vector3(half.x, -half.y, 0), Vector3(half.x, half.y, 0), Vector3(-half.x, half.y, 0)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays); meshes[key] = mesh
	return mesh

func batch(parent: Node2D, key: String, transforms: Array, z: int) -> void:
	if transforms.is_empty(): return
	var tex: Texture2D = textures[key]
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_2D; mm.mesh = quad(tex.get_size()); mm.instance_count = transforms.size()
	for i in range(transforms.size()): mm.set_instance_transform_2d(i, transforms[i])
	var item := MultiMeshInstance2D.new(); item.multimesh = mm; item.texture = tex; item.z_index = z; parent.add_child(item)
	batch_count += 1

func placement(point_px: Vector2, turns: int) -> Transform2D:
	return Transform2D(Layout.turn(Vector2.RIGHT, turns), Layout.turn(Vector2.DOWN, turns), point_px)

func source_placement(item: Dictionary, chunk_origin: Vector2) -> Transform2D:
	var source: Dictionary = environment.catalog[item.asset]
	var center: Vector2 = Rural.Properties.vec(source.canvas_px) * 0.5 - Rural.Properties.vec(source.pivot_px)
	return placement(item.position * 32 + Layout.turn(center, item.turns) - chunk_origin, item.turns)

func prepare_parcel_materials() -> void:
	parcel_materials.clear()
	for parcel in environment.land_use.parcels:
		var material := ShaderMaterial.new(); material.shader = ParcelShader
		material.set_shader_parameter("tile_a", textures[parcel.family + "0"])
		material.set_shader_parameter("tile_b", textures[parcel.family + "1"])
		material.set_shader_parameter("boundary", PackedVector2Array(parcel.polygon))
		material.set_shader_parameter("layout_seed", layout.seed_value)
		material.set_shader_parameter("meadow", parcel.family == "meadow")
		parcel_materials.append(material)

func build_parcels(node: Node2D, chunk: Vector2i) -> void:
	var bounds := Layout.bounds(chunk)
	var end := bounds.end
	var clip := PackedVector2Array([bounds.position, Vector2(end.x, bounds.position.y), end, Vector2(bounds.position.x, end.y)])
	for i in range(environment.land_use.parcels.size()):
		var parcel: Dictionary = environment.land_use.parcels[i]
		if not parcel.bounds.intersects(bounds): continue
		for polygon in Geometry2D.intersect_polygons(PackedVector2Array(parcel.polygon), clip):
			if polygon.size() < 3: continue
			var points := PackedVector2Array()
			for point in polygon: points.append((point - bounds.position) * 32)
			var shape := Polygon2D.new(); shape.polygon = points; shape.material = parcel_materials[i]; node.add_child(shape)
			batch_count += 1

func set_seed(value: int) -> void:
	var started := Time.get_ticks_usec()
	for node in chunk_nodes: node.free()
	for visual in visuals: visual.free()
	chunk_nodes.clear(); visuals.clear(); people.clear(); actor_chunks.clear(); batch_count = 0
	_active_chunk_range = Rect2i(-1, -1, 0, 0)
	layout.generate(value)
	environment.compose(layout)
	world = Autonomous.new(layout, environment)
	prepare_parcel_materials()
	for chunk in layout.chunks:
		var node := Node2D.new(); node.position = Vector2(chunk.key) * 256 * 32; static_root.add_child(node); chunk_nodes.append(node)
		var grass := [[], []]
		for i in range(1024): grass[chunk.variants[i]].append(placement(Vector2((i % 32) * 256 + 128, floori(i / 32.0) * 256 + 128), chunk.rotations[i]))
		batch(node, "grass0", grass[0], 0); batch(node, "grass1", grass[1], 0)
		build_parcels(node, chunk.key)
		var groups := {"straight":[], "corner":[], "driveway_short":[], "driveway_long":[], "yard_gravel":[], "worn_ground":[], "house":[], "house_b":[], "house_c":[], "farmhouse_d":[], "tree":[]}
		for index in chunk.roads:
			var road: Dictionary = layout.roads[index]
			var size := 256.0 if road.kind == "straight" else 512.0
			groups[road.kind].append(placement(road.origin_px + Layout.turn(Vector2.ONE * size * 0.5, road.turns) - node.position, road.turns))
		for index in chunk.houses:
			var house: Dictionary = environment.properties[index]
			groups[house.asset].append(source_placement(house, node.position))
		for index in chunk.access:
			var access: Dictionary = environment.access[index]
			groups[access.asset].append(source_placement(access, node.position))
		for index in chunk.trees:
			var tree: Dictionary = layout.trees[index]
			groups.tree.append(placement(tree.position * 32 - node.position, tree.turns))
		for key in groups:
			var z := 4 if key == "tree" else (3 if key in ["house", "house_b", "house_c", "farmhouse_d"] else 1)
			batch(node, key, groups[key], z)
	people = world.all_people()
	for person in people:
		var visual := Visual.new(); visual.model_to_presentation = Transform2D(Vector2(32, 0), Vector2(0, 32), Vector2.ZERO); actors.add_child(visual); visual.bind_model(person); visuals.append(visual)
	# The cohort starts moving immediately. Load the existing shared walking clip
	# during setup, rather than making the first simulation tick pay its I/O cost.
	Visual.Art.clip("standing_walk")
	elapsed = 0
	paused = false
	generation_count += 1
	advance_models(0)
	if not _camera_initialized:
		camera.position = layout.village * 32
		_camera_initialized = true
		set_mode("local")
	else:
		clamp_camera(); update_activation()
	generation_ms = (Time.get_ticks_usec() - started) / 1000.0
	refresh_debug(true)

func advance_models(delta: float) -> void:
	var started := Time.get_ticks_usec()
	world.advance(delta)
	elapsed = world.elapsed
	actor_chunks.clear()
	for i in range(people.size()):
		var person = people[i]
		visuals[i].sample(delta)
		actor_chunks.append(Layout.owner(person.position))
	# Presentation-only loop, reset at sector exit; no campaign vehicle changes.
	truck_distance = 6 + fposmod(layout.village_distance - 30 - 6 + elapsed * 12, layout.route_length - 12)
	var sample: Dictionary = layout.sample_route(truck_distance)
	truck.position = sample.position * 32
	truck.rotation = sample.direction.angle() + PI / 2
	actor_chunks.append(Layout.owner(sample.position))
	update_us = Time.get_ticks_usec() - started
	if debug_enabled: moving_overlay.queue_redraw()

func _physics_process(delta: float) -> void:
	if not paused: advance_models(delta)

func _process(delta: float) -> void:
	var camera_changed := false
	if _zoom_active:
		var old_zoom := camera.zoom.x
		var next_zoom := exp(lerpf(log(old_zoom), log(zoom_target), 1.0 - exp(-ZOOM_RESPONSE * delta)))
		if absf(next_zoom - zoom_target) <= maxf(0.000001, zoom_target * 0.00001):
			next_zoom = zoom_target
			_zoom_active = false
		# Re-evaluate the anchor each frame so simultaneous panning stays effective.
		var anchor_world := camera.position + _zoom_anchor_screen / old_zoom
		camera.zoom = Vector2.ONE * next_zoom
		camera.position = anchor_world - _zoom_anchor_screen / next_zoom
		camera_changed = true
		if not _zoom_active: refresh_debug(true)
	var movement := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if movement != Vector2.ZERO:
		camera.position += movement.normalized() * delta * 600 / camera.zoom.x
		camera_changed = true
	if camera_changed:
		clamp_camera(); update_activation()
	if debug_enabled:
		_debug_elapsed += delta
		if _debug_elapsed >= 0.1:
			_debug_elapsed = 0
			refresh_debug()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed: return
	if event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]: return
	var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
	var factor: float = event.factor if event.factor > 0 else 1.0
	zoom_target = clampf(zoom_target * pow(WHEEL_STEP, direction * factor), sector_zoom(), MAX_ZOOM)
	_zoom_anchor_screen = event.position - get_viewport_rect().size * 0.5
	_zoom_active = not is_equal_approx(zoom_target, camera.zoom.x)
	mode = "custom"
	get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_1: set_mode("local")
		KEY_2: set_mode("tactical")
		KEY_3: set_mode("sector")
		KEY_N: next_seed()
		KEY_F3: toggle_debug()
		KEY_SPACE: toggle_pause()

func next_seed() -> void: set_seed(Layout.ALTERNATE_SEED if layout.seed_value == Layout.DEFAULT_SEED else Layout.DEFAULT_SEED)
func toggle_pause() -> void: paused = not paused
func toggle_debug() -> void: debug_enabled = not debug_enabled; refresh_debug(true)

func sector_zoom() -> float:
	var viewport := get_viewport_rect().size
	return minf(viewport.x / (Layout.SIZE.x * 32), (viewport.y - 110) / (Layout.SIZE.y * 32)) * 0.96

func set_mode(value: String) -> void:
	mode = value
	var zoom := 0.3125 if mode == "local" else 0.1
	if mode == "sector": zoom = sector_zoom()
	zoom_target = zoom
	_zoom_active = false
	_zoom_anchor_screen = Vector2.ZERO
	camera.zoom = Vector2.ONE * zoom
	clamp_camera(); update_activation()
	refresh_debug(true)

func viewport_resized() -> void:
	if camera == null or chunk_nodes.is_empty(): return
	if mode == "sector":
		set_mode("sector")
	else:
		zoom_target = clampf(camera.zoom.x, sector_zoom(), MAX_ZOOM)
		camera.zoom = Vector2.ONE * zoom_target
		_zoom_active = false
		clamp_camera(); update_activation(); refresh_debug(true)

func clamp_camera() -> void:
	var size := Layout.SIZE * 32
	# Constrain the look point, not the viewport rectangle. Zoom presets must not
	# relocate the camera just because more of the sector now fits on screen.
	camera.position = camera.position.clamp(Vector2.ZERO, size)

func update_activation() -> void:
	var visible_m := get_viewport_rect().size / camera.zoom / 32
	var region := Rect2(camera.position / 32 - visible_m * 0.5, visible_m).grow(32)
	var first := Vector2i(floori(region.position.x / 256), floori(region.position.y / 256)).clamp(Vector2i.ZERO, Layout.CHUNKS)
	var end := Vector2i(ceili(region.end.x / 256), ceili(region.end.y / 256)).clamp(Vector2i.ZERO, Layout.CHUNKS)
	var needed := Rect2i(first, end - first)
	if needed == _active_chunk_range: return
	_active_chunk_range = needed
	activation_revision += 1
	active_chunks = needed.size.x * needed.size.y
	for i in range(chunk_nodes.size()):
		var active := needed.has_point(layout.chunks[i].key)
		if chunk_nodes[i].visible != active: chunk_nodes[i].visible = active
	refresh_debug()

func refresh_debug(redraw_static := false) -> void:
	if overlay == null: return
	overlay.visible = debug_enabled; moving_overlay.visible = debug_enabled; status.visible = debug_enabled
	if debug_enabled and redraw_static:
		overlay.queue_redraw(); moving_overlay.queue_redraw()
	if debug_enabled:
		status.text = "Seed %d · %s · scenario %d\n24 chunks · %d active · %d road modules · %d homes · %d trees\n6 fields · 3 meadows · %d access pieces\n18 people / 4 Squads @ 1.4 m/s · truck @ 12 m/s · %d batches\nCamera %.1f, %.1f m · generation %.1f ms · world %.1f s" % [layout.seed_value, Rural.VERSION, world.scenario_seed, active_chunks, layout.roads.size(), layout.houses.size(), layout.trees.size(), environment.access.size(), batch_count, camera.position.x / 32, camera.position.y / 32, generation_ms, elapsed]
		for squad in world.squads: status.text += "\n%s · %s · %s" % [squad.id, squad.task, squad.movement_state]

func draw_debug(canvas: Node2D) -> void:
	var width := 1.5 / camera.zoom.x
	for chunk in layout.chunks: canvas.draw_rect(Rect2(Vector2(chunk.key) * 256 * 32, Vector2.ONE * 256 * 32), Color(1, 0.85, 0.1, 0.7), false, width)
	for house in environment.properties:
		canvas.draw_rect(Rect2(house.presentation_clearance_bounds.position * 32, house.presentation_clearance_bounds.size * 32), Color.CYAN, false, width)
		var door: Vector2 = house.presentation_access_anchor
		canvas.draw_circle(door * 32, 0.35 * 32, Color.YELLOW)
		canvas.draw_line(house.road_access * 32, door * 32, Color.YELLOW, width)
	for parcel in environment.land_use.parcels:
		var points := PackedVector2Array()
		for point in parcel.polygon: points.append(point * 32)
		points.append(points[0]); canvas.draw_polyline(points, Color(0.9, 0.6, 0.2), width)
	for tree in layout.trees: canvas.draw_circle(tree.position * 32, tree.trunk_radius * 32, Color(1, 0.4, 0.1))
	for key in world.anchors:
		var point: Vector2 = world.anchors[key] * 32
		canvas.draw_circle(point, 3 * 32, Color(0.6, 0.9, 1), false, width)
		debug_label(canvas, point, key)

func debug_label(canvas: Node2D, point: Vector2, text: String) -> void:
	canvas.draw_set_transform(point, 0, Vector2.ONE / camera.zoom.x)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(8, -8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	canvas.draw_set_transform(Vector2.ZERO)

func draw_moving_debug(canvas: Node2D) -> void:
	var width := 1.5 / camera.zoom.x
	for squad in world.squads:
		var point: Vector2 = squad.formation_reference * 32
		canvas.draw_circle(point, 3 * 32, Color(0.4, 0.8, 1), false, width)
		var route := PackedVector2Array([point])
		for i in range(squad.formation_waypoint, squad.formation_route.size()): route.append(squad.formation_route[i] * 32)
		if route.size() > 1: canvas.draw_polyline(route, Color(0.4, 0.8, 1, 0.6), width)
		debug_label(canvas, point, squad.id)
	var truck_outline := PackedVector2Array()
	for corner in [Vector2(-38, -96), Vector2(39, -96), Vector2(39, 96), Vector2(-38, 96), Vector2(-38, -96)]: truck_outline.append(truck.transform * corner)
	canvas.draw_polyline(truck_outline, Color.CYAN, width)
