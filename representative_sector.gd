extends Node2D
## Bounded composition host. The existing campaign and vehicle simulation are untouched.
const Layout = preload("res://sector_layout.gd")
const Space = preload("res://representative_space.gd")
const Person = preload("res://soldier.gd")
const Visual = preload("res://soldier_visual.gd")
const Rural = preload("res://sector_environment.gd")
const ParcelShader = preload("res://sector_parcel.gdshader")
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

class Overlay extends Node2D:
	var host
	func _draw() -> void: host.draw_debug(self)

func _ready() -> void:
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
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(hud)
	var bar := ColorRect.new(); bar.color = Color(0.035, 0.05, 0.04, 0.92); bar.size = Vector2(2000, 48); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(bar)
	var title := Label.new(); title.text = "TRENCHO  ·  Rural sector"; title.position = Vector2(16, 12); hud.add_child(title)
	var actions := [["1 Local", set_mode.bind("local")], ["2 Tactical", set_mode.bind("tactical")], ["3 Sector", set_mode.bind("sector")], ["N New seed", next_seed], ["F3 Details", toggle_debug], ["Space Pause", toggle_pause]]
	for i in range(actions.size()):
		var button := Button.new(); button.text = actions[i][0]; button.position = Vector2(255 + i * 142, 8); button.size = Vector2(134, 32); button.focus_mode = Control.FOCUS_NONE; button.pressed.connect(actions[i][1]); hud.add_child(button)
	var hint := Label.new(); hint.text = "WASD / arrows to explore"; hint.position = Vector2(16, 57); hint.add_theme_color_override("font_color", Color(0.94, 0.96, 0.89)); hud.add_child(hint)
	status = Label.new(); status.position = Vector2(16, 88); status.add_theme_color_override("font_color", Color.WHITE); hud.add_child(status)
	set_seed(Layout.DEFAULT_SEED)

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
	layout.generate(value)
	environment.compose(layout)
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
	for i in range(layout.spawns.size()):
		var spawn: Dictionary = layout.spawns[i]
		var person = Person.new("Sector-%02d" % i, spawn.position, spawn.speed)
		person.path.assign(spawn.route)
		people.append(person)
		var visual := Visual.new(); visual.model_to_presentation = Transform2D(Vector2(32, 0), Vector2(0, 32), Vector2.ZERO); actors.add_child(visual); visual.bind_model(person); visuals.append(visual)
	elapsed = 0
	paused = false
	generation_count += 1
	advance_models(0)
	set_mode(mode)
	generation_ms = (Time.get_ticks_usec() - started) / 1000.0
	refresh_debug()

func advance_models(delta: float) -> void:
	var started := Time.get_ticks_usec()
	elapsed += delta
	actor_chunks.clear()
	for i in range(people.size()):
		var person = people[i]
		if person.arrived:
			person.waypoint = 0; person.arrived = false
		person.advance(delta)
		visuals[i].sample(delta)
		actor_chunks.append(Layout.owner(person.position))
	# Presentation-only loop, reset at sector exit; no campaign vehicle changes.
	truck_distance = 6 + fposmod(layout.village_distance - 30 - 6 + elapsed * 12, layout.route_length - 12)
	var sample: Dictionary = layout.sample_route(truck_distance)
	truck.position = sample.position * 32
	truck.rotation = sample.direction.angle() + PI / 2
	actor_chunks.append(Layout.owner(sample.position))
	update_us = Time.get_ticks_usec() - started
	if debug_enabled: refresh_debug()

func _physics_process(delta: float) -> void:
	if not paused: advance_models(delta)

func _process(delta: float) -> void:
	var movement := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if movement != Vector2.ZERO:
		camera.position += movement.normalized() * delta * 600 / camera.zoom.x
		clamp_camera(); update_activation()

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
func toggle_debug() -> void: debug_enabled = not debug_enabled; refresh_debug()

func set_mode(value: String) -> void:
	mode = value
	var viewport := get_viewport_rect().size
	var zoom := 0.3125 if mode == "local" else 0.1
	if mode == "sector": zoom = minf(viewport.x / (Layout.SIZE.x * 32), (viewport.y - 110) / (Layout.SIZE.y * 32)) * 0.96
	camera.zoom = Vector2.ONE * zoom
	camera.position = (Layout.SIZE * 0.5 if mode == "sector" else layout.village) * 32
	clamp_camera(); update_activation()

func clamp_camera() -> void:
	var half := get_viewport_rect().size / camera.zoom / 2
	var size := Layout.SIZE * 32
	camera.position.x = clampf(camera.position.x, half.x, size.x - half.x) if half.x * 2 < size.x else size.x / 2
	camera.position.y = clampf(camera.position.y, half.y, size.y - half.y) if half.y * 2 < size.y else size.y / 2
	camera.force_update_scroll()

func update_activation() -> void:
	var visible_m := get_viewport_rect().size / camera.zoom / 32
	var region := Rect2(camera.position / 32 - visible_m * 0.5, visible_m).grow(32)
	active_chunks = 0
	for i in range(chunk_nodes.size()):
		chunk_nodes[i].visible = region.intersects(Layout.bounds(layout.chunks[i].key))
		if chunk_nodes[i].visible: active_chunks += 1
	refresh_debug()

func refresh_debug() -> void:
	if overlay == null: return
	overlay.visible = debug_enabled; overlay.queue_redraw(); status.visible = debug_enabled
	if debug_enabled: status.text = "Seed %d · %s\n24 chunks · %d active · %d road modules · %d homes · %d trees\n6 fields · 3 meadows · %d access pieces\n16 Soldiers @ 1.4 m/s · truck @ 12 m/s · %d batches\nCamera %.1f, %.1f m · generation %.1f ms" % [layout.seed_value, Rural.VERSION, active_chunks, layout.roads.size(), layout.houses.size(), layout.trees.size(), environment.access.size(), batch_count, camera.position.x / 32, camera.position.y / 32, generation_ms]

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
	for spawn in layout.spawns: canvas.draw_line(spawn.position * 32, spawn.route[0] * 32, Color(0.5, 0.85, 1, 0.6), width)
	var truck_outline := PackedVector2Array()
	for corner in [Vector2(-38, -96), Vector2(39, -96), Vector2(39, 96), Vector2(-38, 96), Vector2(-38, -96)]: truck_outline.append(truck.transform * corner)
	canvas.draw_polyline(truck_outline, Color.CYAN, width)
