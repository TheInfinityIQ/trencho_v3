extends Node2D

const Scenario = preload("res://scenario.gd")
var model = Scenario.new()
var font := ThemeDB.fallback_font
var colors := [Color("85d9b0"), Color("7ebcda"), Color("d7b981"), Color("e0d3a5")]
var inquiry_mode := false
var queried := false
var query_point := Vector2.ZERO
var query_result: Array[Dictionary] = []
var inquiry_button: Button
var reconstruction_button: Button
var exit_button: Button

func _ready() -> void:
	for entry in model.trace:
		print(JSON.stringify(entry))
	inquiry_button = add_button("BINOCULAR INQUIRY [B]", Vector2(945, 625), toggle_inquiry)
	reconstruction_button = add_button("RECONSTRUCT [R]", Vector2(945, 667), reconstruct)
	exit_button = add_button("EXIT RECONSTRUCTION [Esc]", Vector2(945, 709), exit_reconstruction)

func add_button(text: String, location: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = location
	button.size = Vector2(292, 32)
	button.pressed.connect(action)
	add_child(button)
	return button

func toggle_inquiry() -> void:
	if not model.information.reconstructing:
		inquiry_mode = not inquiry_mode

func inquire(point: Vector2) -> void:
	if not Rect2(24, 105, 888, 645).has_point(point) or model.information.reconstructing:
		return
	queried = true
	query_point = point
	query_result = model.information.query(point)

func reconstruct() -> void:
	model.information.begin_reconstruction(query_result)

func exit_reconstruction() -> void:
	model.information.end_reconstruction()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			toggle_inquiry()
		elif event.keycode == KEY_R:
			reconstruct()
		elif event.keycode == KEY_ESCAPE:
			exit_reconstruction()
			inquiry_mode = false
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and inquiry_mode:
		inquire(event.position)

func _physics_process(delta: float) -> void:
	model.advance(delta)
	reconstruction_button.disabled = query_result.is_empty() or model.information.reconstructing
	exit_button.disabled = not model.information.reconstructing
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16, color := Color("dce7df")) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_rect(Rect2(24, 105, 888, 645), Color("182b2b"))
	for x in range(40, 910, 40):
		draw_line(Vector2(x, 105), Vector2(x, 750), Color(0.6, 0.8, 0.6, 0.045))
	for y in range(110, 750, 40):
		draw_line(Vector2(24, y), Vector2(912, y), Color(0.6, 0.8, 0.6, 0.045))
	label_at(Vector2(28, 40), "TRENCHO / PHYSICAL SUPPLY PROOF", 25)
	label_at(Vector2(28, 73), "[B] Binoculars: click any map location  •  [R] Reconstruct known history  •  [Esc] Exit", 16, Color("93aaa8"))
	draw_rect(Scenario.OBSTACLE, Color("59625d"))
	draw_rect(Scenario.OBSTACLE.grow(-8), Color("424e4b"))
	label_at(Vector2(425, 350), "ROCK OUTCROP", 15)
	label_at(Vector2(430, 377), "Impassable", 14)
	draw_circle(Scenario.OBJECTIVE, 40, Color(0.8, 0.72, 0.3, 0.14))
	draw_arc(Scenario.OBJECTIVE, 40, 0, TAU, 50, Color("ddce76"), 2)
	label_at(Vector2(745, 280), "OBJECTIVE A", 19, Color("e2d58b"))
	label_at(Vector2(754, 415), "SECURED" if model.secured else "Approach", 16)
	draw_rect(Rect2(80, 160, 115, 55), Color("344e4e"))
	label_at(Vector2(95, 182), "Operational", 15)
	label_at(Vector2(95, 202), "+ Company HQ", 13)
	draw_rect(Rect2(95, 575, 240, 108), Color(0.75, 0.64, 0.4, 0.07))
	label_at(Vector2(100, 715), "P2 / RESERVE — holding", 17, colors[2])
	for index in range(model.squads.size()):
		var squad = model.squads[index]
		var color: Color = colors[index]
		for soldier in squad.soldiers:
			if not soldier.path.is_empty():
				var points := PackedVector2Array([soldier.route_origin])
				points.append_array(PackedVector2Array(soldier.path))
				draw_polyline(points, Color(color, 0.12), 1)
			draw_circle(soldier.position, 6, color if soldier.active else Color("72716d"))
			if not soldier.active:
				draw_line(soldier.position - Vector2(7, 7), soldier.position + Vector2(7, 7), Color("e89882"), 2)
				draw_line(soldier.position + Vector2(-7, 7), soldier.position + Vector2(7, -7), Color("e89882"), 2)
			draw_arc(soldier.position, 8, 0, TAU, 16, Color(color, 0.5), 1)
			label_at(soldier.position + Vector2(9, 4), soldier.id.get_slice(".", 1), 11, color)
		label_at(squad.center() + Vector2(-20, -26), squad.id, 16, color)
	label_at(Vector2(273, 565), "P1-B / SUPPORT", 16, colors[1])
	if not model.information.reconstructing:
		var supply = model.supply
		draw_line(supply.DEPOT_POSITION, supply.RESUPPLY_POSITION, Color("52605a"), 13)
		draw_line(supply.DEPOT_POSITION, supply.RESUPPLY_POSITION, Color("9b9b77"), 1)
		draw_rect(Rect2(supply.DEPOT_POSITION - Vector2(17, 12), Vector2(34, 24)), Color("b6a47a"))
		label_at(Vector2(50, 102), "Depot: %d rounds" % supply.depot.inventory[supply.CATEGORY], 15)
		var truck_position: Vector2 = supply.truck.position
		draw_rect(Rect2(truck_position - Vector2(13, 8), Vector2(26, 16)), Color("b9c9aa"))
		draw_circle(truck_position + Vector2(-7, 9), 3, Color("17211e"))
		draw_circle(truck_position + Vector2(7, 9), 3, Color("17211e"))
		draw_rect(Rect2(supply.CAPTURE_POSITION - Vector2(10, 8), Vector2(20, 16)), Color("c18969"))
		label_at(supply.CAPTURE_POSITION + Vector2(-55, 27), "Captured +4" if supply.captured_at >= 0 else "Enemy ammo: 4", 14)
		draw_rect(Rect2(625, 112, 270, 124), Color("112025"))
		label_at(Vector2(638, 135), "P1-A / PHYSICAL AMMUNITION", 16)
		var counts: Array = []
		for soldier in model.squads[0].soldiers:
			counts.append(str(soldier.inventory[supply.CATEGORY]))
		label_at(Vector2(638, 160), "Individuals: " + " / ".join(counts), 15)
		label_at(Vector2(638, 185), "Carried %d / ready %d" % [supply.carried(), supply.READY_THRESHOLD], 15)
		label_at(Vector2(638, 213), supply.phase, 16, Color("e0c998"))
		label_at(Vector2(425, 520), "SUPPLY / CUSTODY DIAGNOSTICS", 16)
		label_at(Vector2(425, 546), "Depot %d · Truck %d · Carried %d · Enemy %d" % [supply.depot.inventory[supply.CATEGORY], supply.truck.inventory[supply.CATEGORY], supply.carried(), supply.captured.inventory[supply.CATEGORY]], 14)
		label_at(Vector2(425, 570), "Total conserved: %d rounds · %s" % [supply.total_accounted(), supply.truck.state], 14)
		var recent: Array = supply.events.slice(maxi(0, supply.events.size() - 3))
		for index in range(recent.size()):
			label_at(Vector2(425, 602 + index * 23), "T=%.1f  %s" % [recent[index].time, recent[index].choice], 14)
		if supply.shared:
			label_at(Vector2(425, 700), "Local sharing: P1-A.2 → P1-A.1 / 2 rounds", 14)
	var observation: Dictionary = model.information.player_observation()
	if not observation.is_empty():
		var age: float = model.elapsed - observation.time
		if age < 1.2:
			draw_circle(observation.location, 12 + age * 35, Color(1, 0.65, 0.2, 0.6 * (1 - age / 1.2)))
		label_at(observation.location + Vector2(-80, 42), "Casualty / explosion site", 14, Color("d6a89b"))
	if queried:
		draw_arc(query_point, model.information.QUERY_RADIUS, 0, TAU, 48, Color("99dfe9"), 1.5)
	if model.information.reconstructing:
		draw_rect(Rect2(24, 105, 888, 645), Color(0.04, 0.08, 0.12, 1))
		for record in model.information.reconstruction:
			draw_circle(record.location, 30, Color(0.5, 0.85, 1, 0.14))
			draw_circle(record.location, 7, Color(0.6, 0.9, 1, 0.65))
			draw_arc(record.location, 40, 0, TAU, 48, Color(0.6, 0.9, 1, 0.7), 2)
			label_at(record.location + Vector2(45, 0), "Known explosion / casualty", 17)
			label_at(record.location + Vector2(45, 27), "%s at T=%.1f" % [record.soldier_id, record.observation_time], 16)
		label_at(Vector2(80, 180), "HQ EVIDENCE RECONSTRUCTION — WORLD PAUSED", 22, Color("a8e8f1"))
		label_at(Vector2(80, 215), "Source not established. No trajectory or attacker is reconstructed.", 17)
	draw_rect(Rect2(930, 105, 325, 645), Color("112025"))
	label_at(Vector2(948, 137), "HIERARCHY / DIAGNOSTICS", 18)
	var lines := ["HQ: Secure A · Company: P1 main", "P1: A seizes / B supports", "P1-A: local north bypass", "P2: reserve holds", "", "REPORT RECEIPTS (1s / hop)"]
	for index in range(lines.size()):
		label_at(Vector2(948, 171 + index * 22), lines[index], 14)
	for index in range(4):
		var echelon: String = model.information.ECHELONS[index]
		var records: Array = model.information.knowledge[echelon]
		label_at(Vector2(948, 325 + index * 22), "%s: %s" % [echelon, "not received" if records.is_empty() else "T=%.1f (observed 5.0)" % records[0].received_at], 14)
	label_at(Vector2(948, 435), "HQ LOCATION INQUIRY", 18)
	label_at(Vector2(948, 459), "Radius 54 · " + ("Click any map location" if inquiry_mode else "Enter binocular mode [B]"), 14)
	if queried:
		label_at(Vector2(948, 486), "At (%.0f, %.0f)" % [query_point.x, query_point.y], 14)
		if query_result.is_empty():
			label_at(Vector2(948, 514), "No established information", 15, Color("dcca96"))
			label_at(Vector2(948, 536), "for this location. Query again later.", 14)
		else:
			var report: Dictionary = query_result[0]
			label_at(Vector2(948, 512), "T=%.1f: explosion / casualty" % report.observation_time, 14)
			label_at(Vector2(948, 535), "Friendly: " + report.soldier_id, 14)
			label_at(Vector2(948, 558), "Source: not established", 14)
			label_at(Vector2(948, 581), "Observed by " + report.observer, 14)
	label_at(Vector2(28, 781), "Elapsed %.1fs   |   %s" % [model.elapsed, "Objective reached; support and reserve hold" if model.secured else "Watch P1-A navigate around the outcrop"], 16)
