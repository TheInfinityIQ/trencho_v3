extends Node2D
## SCL-032 spatial diagnostics only: no campaign, art or tactical commands.
const Space = preload("res://representative_space.gd")
var camera: Camera2D
var hud: Control
var font: Font
var elapsed := 0.0
var time_scale := 1.0
var paused := false
var preset := "local"
var anchor_name := "logistics calibration site"
var origin_m := Space.SITE_METERS
var pause_button: Button
var rate_button: Button

class ScaleHUD extends Control:
	var host
	func _draw() -> void:
		host.draw_overlay(self)

func _ready() -> void:
	font = ThemeDB.fallback_font
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.enabled = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = ScaleHUD.new()
	hud.host = self
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	var views := [["1 Local / 128 m", "local"], ["2 District / 400 m", "district"], ["3 Tactical / 1.6 km", "tactical"], ["4 Operation / 6 x 8 km", "operation"]]
	for i in range(views.size()):
		button(views[i][0], Vector2(14 + 225 * i, 54), 215, set_view.bind(views[i][1]))
	var anchors := [["5 Near origin", "origin"], ["6 Map center", "center"], ["7 Far edges", "far"], ["8 Far chunk", "chunk"]]
	for i in range(anchors.size()):
		button(anchors[i][0], Vector2(14 + 140 * i, 90), 132, snap_anchor.bind(anchors[i][1]))
	pause_button = button("Space Pause", Vector2(580, 90), 135, toggle_pause)
	rate_button = button("X Clock x1", Vector2(723, 90), 130, toggle_rate)
	button("R Reset time", Vector2(861, 90), 140, reset_time)
	set_view("local")

func button(text: String, point: Vector2, width: float, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = Vector2(width, 30)
	item.focus_mode = Control.FOCUS_NONE
	item.pressed.connect(action)
	hud.add_child(item)
	return item

func set_view(name: String) -> void:
	preset = name
	anchor_name = "logistics calibration site"
	origin_m = Space.SITE_METERS
	camera.zoom = Vector2.ONE * float(Space.ZOOMS[name])
	var center := Vector2(410, 638)
	if name == "district": center = Space.DISTRICT_METERS.get_center()
	if name == "tactical": center = Vector2(900, 800)
	if name == "operation": center = Space.MAP_METERS / 2
	camera.position = Space.point_to_world(center)
	camera.force_update_scroll()
	queue_redraw()
	hud.queue_redraw()

func snap_anchor(name: String) -> void:
	set_view("local")
	anchor_name = name + " / same meter calibration"
	var center := Vector2(70, 70)
	origin_m = Vector2(20, 72)
	if name == "center":
		center = Vector2(3000, 4000)
		origin_m = Vector2(2950, 4002)
	if name == "far":
		center = Vector2(5938, 7960)
		origin_m = Vector2(5880, 7962)
	if name == "chunk":
		center = Vector2(5890, 7938)
		origin_m = Vector2(5840, 7940)
	camera.position = Space.point_to_world(center)
	camera.force_update_scroll()

func toggle_pause() -> void:
	paused = not paused
	pause_button.text = "Space Resume" if paused else "Space Pause"

func toggle_rate() -> void:
	time_scale = 10.0 if time_scale == 1 else 1.0
	rate_button.text = "X Clock x%d" % int(time_scale)

func reset_time() -> void:
	elapsed = 0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: set_view("local")
		KEY_2: set_view("district")
		KEY_3: set_view("tactical")
		KEY_4: set_view("operation")
		KEY_5: snap_anchor("origin")
		KEY_6: snap_anchor("center")
		KEY_7: snap_anchor("far")
		KEY_8: snap_anchor("chunk")
		KEY_SPACE: toggle_pause()
		KEY_X: toggle_rate()
		KEY_R: reset_time()

func _physics_process(delta: float) -> void:
	if not paused:
		elapsed += delta * time_scale

func _process(delta: float) -> void:
	var pan := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if pan != Vector2.ZERO:
		var center := Space.point_to_meters(camera.position)
		center += pan * Space.visible_meters(get_viewport_rect().size, camera.zoom.x).x * 0.5 * delta
		center = center.clamp(Vector2.ZERO, Space.MAP_METERS)
		camera.position = Space.point_to_world(center)
	queue_redraw()
	hud.queue_redraw()

func world_rect(rect_m: Rect2) -> Rect2:
	return Rect2(Space.point_to_world(rect_m.position), Space.point_to_world(rect_m.size))

func _draw() -> void:
	if camera == null: return
	var pixel := 1.0 / camera.zoom.x
	draw_rect(world_rect(Rect2(Vector2.ZERO, Space.MAP_METERS)), Color("172b2b"))
	draw_rect(world_rect(Rect2(Vector2.ZERO, Space.MAP_METERS)), Color("92b4bc"), false, 2 * pixel)
	var center := Space.point_to_meters(camera.position)
	var extent := Space.visible_meters(get_viewport_rect().size, camera.zoom.x)
	var visible := Rect2(center - extent / 2, extent).intersection(Rect2(Vector2.ZERO, Space.MAP_METERS))
	if visible.has_area():
		for x in range(maxi(0, floori(visible.position.x / 256)), mini(24, ceili(visible.end.x / 256)) + 1):
			var meters := minf(x * 256, 6000)
			draw_line(Space.point_to_world(Vector2(meters, visible.position.y)), Space.point_to_world(Vector2(meters, visible.end.y)), Color("31494b"), pixel)
		for y in range(maxi(0, floori(visible.position.y / 256)), mini(32, ceili(visible.end.y / 256)) + 1):
			var meters := minf(y * 256, 8000)
			draw_line(Space.point_to_world(Vector2(visible.position.x, meters)), Space.point_to_world(Vector2(visible.end.x, meters)), Color("31494b"), pixel)
	draw_rect(world_rect(Space.DISTRICT_METERS), Color("344b40"))
	draw_rect(world_rect(Space.DISTRICT_METERS), Color("b2c18d"), false, 2 * pixel)
	if preset == "operation":
		for item in Space.LANDMARKS:
			draw_circle(Space.point_to_world(item.point), Space.meters_to_world(30), Color("d3bb80"))
	# Bounded primitive shapes only; these are not substitute production art.
	draw_rect(world_rect(Rect2(origin_m + Vector2(-10, -6), Vector2(120, 6))), Color("565e62"))
	draw_line(Space.point_to_world(origin_m + Vector2(0, 4)), Space.point_to_world(origin_m + Vector2(100, 4)), Color("476b61"), pixel)
	var state: Dictionary = Space.positions_at(elapsed, origin_m)
	draw_rect(world_rect(Rect2(state.truck - Space.TRUCK_SIZE_METERS / 2, Space.TRUCK_SIZE_METERS)), Color("d3b47b"), false, 2 * pixel)
	draw_circle(Space.point_to_world(state.soldier), Space.meters_to_world(0.3), Color("9fddc6"))
	draw_line(Space.point_to_world(origin_m + Vector2(0, -10)), Space.point_to_world(origin_m + Vector2(10, -10)), Color("d8dedc"), pixel)
	draw_line(Space.point_to_world(origin_m + Vector2(0, 10)), Space.point_to_world(origin_m + Vector2(100, 10)), Color("9fb6c2"), pixel)
	draw_line(Space.point_to_world(Vector2(300, 1200)), Space.point_to_world(Vector2(1300, 1200)), Color("9fb6c2"), 2 * pixel)
	draw_line(Space.point_to_world(Vector2(1000, 2800)), Space.point_to_world(Vector2(3000, 2800)), Color("9fb6c2"), 2 * pixel)

func screen_point(meters: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * Space.point_to_world(meters)

func label(control: Control, point: Vector2, text: String, color := Color("e1e8e4"), size := 15) -> void:
	control.draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func map_label(control: Control, point_m: Vector2, text: String, offset := Vector2(8, -8)) -> void:
	var point := screen_point(point_m) + offset
	if point.x > -20 and point.x < get_viewport_rect().size.x - 20 and point.y > 155 and point.y < get_viewport_rect().size.y - 75:
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		point.x = clampf(point.x, 14, maxf(14, get_viewport_rect().size.x - width - 14))
		label(control, point, text)

func draw_overlay(control: Control) -> void:
	var viewport := get_viewport_rect().size
	var center := Space.point_to_meters(camera.position)
	var visible := Space.visible_meters(viewport, camera.zoom.x)
	control.draw_rect(Rect2(0, 0, viewport.x, 146), Color("102026"))
	label(control, Vector2(14, 23), "SPATIAL CALIBRATION / diagnostic shapes only / 1 m = 32 world units", Color("b8d4d0"), 18)
	label(control, Vector2(14, 45), "%s | center %.2f, %.2f m | chunk %s | zoom %.8f | view %.1f x %.1f m" % [preset.to_upper(), center.x, center.y, str(Space.chunk_for_world(camera.position)), camera.zoom.x, visible.x, visible.y])
	var state: Dictionary = Space.positions_at(elapsed, origin_m)
	label(control, Vector2(14, 138), "Sim %.2f s / clock x%d%s | walk %.2f m at 1.4 m/s | truck %.2f m at provisional 12 m/s | arrows pan" % [elapsed, int(time_scale), " PAUSED" if paused else "", state.walk_m, state.truck_m])
	if preset == "operation":
		for item in Space.LANDMARKS: map_label(control, item.point, item.name)
		map_label(control, Vector2(3000, 0), "6 km width", Vector2(-45, 20))
		map_label(control, Vector2(6000, 4000), "8 km height")
		map_label(control, Vector2(1800, 2800), "2 km reference")
	if preset == "local":
		map_label(control, origin_m + Vector2(0, -10), "10 m reference")
		map_label(control, origin_m + Vector2(42, 10), "100 m route / walk 71.43 s / truck 8.33 s", Vector2(-70, 20))
		map_label(control, state.soldier, "Soldier marker / 0.6 m diameter", Vector2(8, 22))
		map_label(control, state.truck, "Truck envelope 6.0 x 2.4 m", Vector2(8, -18))
		map_label(control, origin_m + Vector2(55, -3), "6 m paved width", Vector2(-30, 20))
	if preset in ["district", "tactical"]:
		map_label(control, Space.DISTRICT_METERS.position, "400 x 400 m logistics district", Vector2(8, 22))
		map_label(control, Vector2(700, 1200), "1 km reference")
	if preset == "district":
		map_label(control, origin_m, "100 m calibration route / press 1 for proportions", Vector2(0, -15))
	label(control, Vector2(14, viewport.y - 66), anchor_name + " | logical chunks 24 x 32 (768), partial east/south edges; no terrain cells", Color("a1b3b8"), 14)
	var ruler := Space.ruler_meters(visible.x)
	var pixels := ruler * Space.WORLD_UNITS_PER_METER * camera.zoom.x
	control.draw_line(Vector2(25, viewport.y - 30), Vector2(25 + pixels, viewport.y - 30), Color.WHITE, 2)
	for x in [25.0, 25.0 + pixels]: control.draw_line(Vector2(x, viewport.y - 35), Vector2(x, viewport.y - 25), Color.WHITE, 2)
	label(control, Vector2(30 + pixels, viewport.y - 26), "%.0f m" % ruler)
