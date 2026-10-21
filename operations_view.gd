extends Node2D

const Operations = preload("res://operations.gd")
var operations = Operations.new()
var model = operations.world
var font := ThemeDB.fallback_font
var view_mode := "battlefield"
var placing := false
var inquiry_mode := false
var queried := false
var query_point := Vector2.ZERO
var query_result: Array[Dictionary] = []
var rear_buttons: Array[Button] = []
var inquiry_button: Button
var reconstruct_button: Button
var exit_button: Button
var map_button: Button
var reserve_amount: SpinBox
var batch_count: SpinBox
var alerts_button: Button
var acknowledge_button: Button
var alert_panel: Panel
var alert_title: Label
var alert_rows: Array[Button] = []

func button(text: String, point: Vector2, action: Callable, width := 292.0) -> Button:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = Vector2(width, 32)
	item.pressed.connect(action)
	add_child(item)
	return item

func _ready() -> void:
	map_button = button("PROTECTED REAR [Tab]", Vector2(945, 45), switch_map)
	rear_buttons.append(button("AVAILABLE [1]", Vector2(945, 465), func(): authorize("AVAILABLE")))
	rear_buttons.append(button("RESERVE [2]", Vector2(945, 505), func(): authorize("RESERVE"), 185))
	rear_buttons.append(button("LOCKED [3]", Vector2(945, 545), func(): authorize("LOCKED")))
	reserve_amount = SpinBox.new()
	reserve_amount.position = Vector2(1140, 505)
	reserve_amount.size = Vector2(95, 32)
	reserve_amount.min_value = 0
	reserve_amount.max_value = 99
	reserve_amount.value = 8
	add_child(reserve_amount)
	rear_buttons.append(button("PLACE WORKBENCH [P]", Vector2(945, 585), begin_placement))
	rear_buttons.append(button("WORK: ONE BATCH [E]", Vector2(945, 625), manual_work))
	rear_buttons.append(button("WORKER ORDER [F]", Vector2(945, 665), assign_worker, 185))
	batch_count = SpinBox.new()
	batch_count.position = Vector2(1140, 665)
	batch_count.size = Vector2(95, 32)
	batch_count.min_value = 1
	batch_count.max_value = 3
	batch_count.step = 1
	batch_count.value = 1
	batch_count.tooltip_text = "Batches in the next finite Worker order (1–3)"
	add_child(batch_count)
	rear_buttons.append(button("STOP FUTURE BATCHES [X]", Vector2(945, 705), stop_worker))
	inquiry_button = button("BINOCULAR INQUIRY [B]", Vector2(945, 575), toggle_inquiry)
	reconstruct_button = button("RECONSTRUCT REPORT [R]", Vector2(945, 615), reconstruct)
	exit_button = button("RETURN TO LIVE VIEW [Esc]", Vector2(945, 655), exit_reconstruction)
	acknowledge_button = button("ACK PRIMARY [K]", Vector2(945, 760), acknowledge_newest, 140)
	alerts_button = button("ALERT HISTORY [H]", Vector2(1095, 760), toggle_alert_history, 140)
	alert_panel = Panel.new()
	alert_panel.position = Vector2(250, 115)
	alert_panel.size = Vector2(670, 550)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("112025")
	alert_panel.add_theme_stylebox_override("panel", background)
	alert_panel.visible = false
	add_child(alert_panel)
	alert_title = Label.new()
	alert_title.position = Vector2(15, 12)
	alert_title.add_theme_font_size_override("font_size", 15)
	alert_panel.add_child(alert_title)
	for index in range(11):
		var row := Button.new()
		row.position = Vector2(15, 48 + index * 44)
		row.size = Vector2(640, 42)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", 12)
		row.pressed.connect(acknowledge_row.bind(index))
		alert_panel.add_child(row)
		alert_rows.append(row)
	refresh()

func toggle_alert_history() -> void:
	alert_panel.visible = not alert_panel.visible
	refresh()

func acknowledge_newest() -> void:
	var newest: Dictionary = operations.alerts.primary()
	if not newest.is_empty():
		operations.alerts.acknowledge(newest.id)
	refresh()

func acknowledge_row(index: int) -> void:
	var entries: Array = operations.alerts.ranked()
	if index < entries.size():
		operations.alerts.acknowledge(entries[index].id)
	refresh()

func attention_text(area: String) -> String:
	return "Rear attention useful" if area == "REAR" else ("Battlefield report available" if area == "BATTLEFIELD" else "No attention suggestion")

func switch_map() -> void:
	if model.information.reconstructing:
		return
	view_mode = "rear" if view_mode == "battlefield" else "battlefield"
	placing = false
	inquiry_mode = false
	refresh()

func begin_placement() -> void:
	if model.battle_active() and view_mode == "rear":
		placing = not placing

func manual_work() -> void:
	if model.battle_active() and view_mode == "rear":
		model.rear.start_job("Avatar", model.elapsed)

func assign_worker() -> void:
	if model.battle_active() and view_mode == "rear":
		model.rear.assign_worker(int(batch_count.value), model.elapsed)

func stop_worker() -> void:
	if model.battle_active() and view_mode == "rear":
		model.rear.stop_worker(model.elapsed)

func authorize(policy: String) -> void:
	if model.battle_active() and view_mode == "rear":
		model.rear.set_policy(policy, int(reserve_amount.value))

func toggle_inquiry() -> void:
	if model.battle_active() and not model.information.reconstructing:
		inquiry_mode = not inquiry_mode

func inquire(point: Vector2) -> void:
	if not model.information.reconstructing and model.rear.MAP.has_point(point):
		query_point = point
		queried = true
		query_result = model.information.query(point)

func reconstruct() -> void:
	if model.battle_active() and view_mode == "battlefield":
		model.information.begin_reconstruction(query_result)

func exit_reconstruction() -> void:
	model.information.end_reconstruction()
	inquiry_mode = false

func refresh() -> void:
	var is_rear: bool = view_mode == "rear"
	for item in rear_buttons:
		item.visible = is_rear
		item.disabled = not model.battle_active()
	reserve_amount.visible = is_rear
	reserve_amount.editable = is_rear and model.battle_active()
	batch_count.visible = is_rear
	batch_count.editable = is_rear and model.battle_active()
	inquiry_button.visible = not is_rear
	reconstruct_button.visible = not is_rear
	exit_button.visible = not is_rear and model.information.reconstructing
	inquiry_button.disabled = not model.battle_active() or model.information.reconstructing
	reconstruct_button.disabled = not model.battle_active() or query_result.is_empty() or model.information.reconstructing
	map_button.disabled = model.information.reconstructing
	map_button.text = "BATTLEFIELD [Tab]" if is_rear else "PROTECTED REAR [Tab]"
	var primary_alert: Dictionary = operations.alerts.primary()
	acknowledge_button.disabled = primary_alert.is_empty() or primary_alert.acknowledged
	alert_title.text = "ALERT PRIORITY — click to acknowledge / " + ("world frozen" if not model.battle_active() else ("history paused" if model.information.reconstructing else "world continues"))
	var entries: Array = operations.alerts.ranked()
	for index in range(alert_rows.size()):
		alert_rows[index].visible = index < entries.size()
		if index < entries.size():
			var entry: Dictionary = entries[index]
			var state: String = entry.resolution if entry.state == "RESOLVED" else attention_text(entry.area)
			alert_rows[index].text = "%s %s T%.1f  %s\n%s / %s" % ["ACK" if entry.acknowledged else "NEW", entry["class"], entry.time, entry.text, state, entry.source]
			alert_rows[index].tooltip_text = JSON.stringify(entry.provenance)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_H, KEY_K]:
		if event.keycode == KEY_H:
			toggle_alert_history()
		else:
			acknowledge_newest()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		switch_map()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not model.battle_active():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			exit_reconstruction()
		elif view_mode == "rear":
			if event.keycode == KEY_P:
				begin_placement()
			elif event.keycode == KEY_E:
				manual_work()
			elif event.keycode == KEY_F:
				assign_worker()
			elif event.keycode == KEY_X:
				stop_worker()
			elif event.keycode in [KEY_1, KEY_2, KEY_3]:
				authorize({KEY_1: "AVAILABLE", KEY_2: "RESERVE", KEY_3: "LOCKED"}[event.keycode])
		elif event.keycode == KEY_B:
			toggle_inquiry()
		elif event.keycode == KEY_R:
			reconstruct()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if view_mode == "rear" and placing:
			if model.rear.place_workbench(event.position):
				placing = false
		elif view_mode == "battlefield" and inquiry_mode:
			inquire(event.position)

func _physics_process(delta: float) -> void:
	if view_mode == "rear" and model.battle_active():
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		model.rear.move_avatar(direction, delta)
	operations.advance(delta)
	refresh()
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16, color := Color("dce7df")) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func wrapped_label(point: Vector2, text: String, width := 292.0, size := 12) -> void:
	var line := ""
	var row := 0
	for word in text.split(" "):
		var next_line := word if line.is_empty() else line + " " + word
		if font.get_string_size(next_line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and not line.is_empty():
			label_at(point + Vector2(0, row * 17), line, size)
			line = word
			row += 1
		else:
			line = next_line
	label_at(point + Vector2(0, row * 17), line, size)

func draw_supply_panel() -> void:
	draw_rect(Rect2(930, 105, 325, 645), Color("112025"))
	var status: Dictionary = operations.situation()
	label_at(Vector2(945, 135), "MILITARY NEED", 18)
	label_at(Vector2(945, 157), "%s / request %d: %s" % [model.supply.squad.id, status.need.requested, status.need.state], 13)
	label_at(Vector2(945, 177), "Supplied %d/%d / carried %d" % [status.need.delivered, status.need.requested, status.need.carried], 14)
	var formation := "Moving to supply point"
	if model.supply.phase == "Hold: ammunition shortage":
		formation = "Holding: needs16 carried rounds"
	elif model.supply.phase == "Final approach":
		formation = "Mission continues autonomously"
	if not model.battle_active():
		formation = "Battle ended — world frozen"
	label_at(Vector2(945, 197), formation, 13, Color("dec88f"))
	label_at(Vector2(945, 223), "REAR STOCK", 17)
	label_at(Vector2(945, 244), "Finished %d / committed %d" % [status.stock.finished, status.stock.committed], 14)
	label_at(Vector2(945, 264), "Uncommitted %d / eligible %d" % [status.stock.uncommitted, status.stock.eligible], 14)
	label_at(Vector2(945, 284), status.stock.explanation, 12)
	label_at(Vector2(945, 312), "SUPPLY: " + status.chain.stage, 13, Color("d8c894"))
	wrapped_label(Vector2(945, 332), status.chain.explanation)
	label_at(Vector2(945, 377), "REAR WORK", 17)
	label_at(Vector2(945, 398), "Workbench: %s / Metal %d" % ["available" if status.work.bench else "not placed", model.rear.metal], 13)
	label_at(Vector2(945, 419), status.work.state, 12)
	label_at(Vector2(945, 440), "Worker: " + status.work.worker, 11)
	if view_mode == "battlefield":
		wrapped_label(Vector2(945, 477), status.report_activity, 292, 12)
		wrapped_label(Vector2(945, 526), Operations.Situation.inquiry(query_result, queried), 292, 12)
		if not query_result.is_empty():
			label_at(Vector2(945, 557), "Observed T%.1f / HQ receipt T%.1f" % [query_result[0].observation_time, query_result[0].received_at], 12)

func draw_rear() -> void:
	var rear = model.rear
	draw_rect(rear.RAW_STORE, Color("586965"))
	label_at(Vector2(94, 184), "RAW STORAGE", 17)
	label_at(Vector2(94, 217), "Metal: %d" % rear.metal, 18)
	draw_rect(rear.DISPATCH, Color("64664f"))
	label_at(Vector2(705, 185), "DISPATCH", 17)
	label_at(Vector2(660, 280), "Cargo: %d rounds" % rear.shipment.cargo, 16)
	label_at(Vector2(660, 310), rear.shipment.owner + " ownership", 15)
	if rear.shipment.state == "Inter-map transit":
		draw_line(rear.DISPATCH.end, Vector2(900, 400), Color("e0bd77"), 4)
		label_at(Vector2(650, 350), "Travelling to military receiving", 16)
	if rear.placed:
		draw_rect(Rect2(rear.workbench - Vector2(27, 17), Vector2(54, 34)), Color("b5a17c"))
		label_at(rear.workbench + Vector2(-70, -35), "AMMO WORKBENCH", 16)
		if not rear.job.is_empty():
			var progress: float = clampf((model.elapsed - rear.job.started_at) / 4, 0, 1)
			draw_rect(Rect2(rear.workbench + Vector2(-35, 28), Vector2(70, 8)), Color("101c1d"))
			draw_rect(Rect2(rear.workbench + Vector2(-35, 28), Vector2(70 * progress, 8)), Color("a8dfba"))
			label_at(rear.workbench + Vector2(-75, 65), "Working %.1f / 4s" % (model.elapsed - rear.job.started_at), 16)
	elif placing:
		label_at(Vector2(270, 330), "Click free ground to place the workbench", 21)
	draw_circle(rear.worker.position, 9, Color("e0bc83"))
	var worker_label: Vector2 = rear.worker.position + (Vector2(-110, -15) if rear.placed and rear.worker.position.distance_to(rear.workbench) < 70 else Vector2(-35, -20))
	label_at(worker_label, "WORKER", 15)
	draw_circle(rear.avatar, 10, Color("8ed4df"))
	label_at(rear.avatar + Vector2(-20, -20), "YOU", 15)
	label_at(Vector2(50, 620), "WASD: move / P: bench / E: manual / F: Worker order / X: stop future batches", 16)
	label_at(Vector2(50, 650), "Stock starts LOCKED. Choose AVAILABLE [1] when you want the military to draw it.", 16)
	var status: String = rear.message
	if rear.job.is_empty():
		if model.supply.delivered_at >= 0:
			status = "The formation received eight rounds and is continuing its mission."
		elif rear.shipment.state == "Inter-map transit":
			status = "Exported rounds are travelling in military custody."
		elif rear.shipment.state != "None":
			status = "Military receiving has the shipment. Follow the truck on the battlefield."
		elif rear.committed > 0:
			status = "Eight rounds committed for loading; still included in rear stock."
	label_at(Vector2(50, 675), status, 15, Color("dec88f"))

func draw_battlefield() -> void:
	for edge in model.vehicles.edges:
		draw_line(model.vehicles.points[edge.a], model.vehicles.points[edge.b], Color("4c5953") if edge.terrain == "ROAD" else Color("426657"), 11 if edge.terrain == "ROAD" else 2)
	if not model.vehicles.truck.known_blocked.is_empty():
		draw_rect(model.vehicles.BLOCKAGE, Color("b36755"))
		label_at(Vector2(226, 136), "Driver reported blockage", 13)
	draw_rect(model.OBSTACLE, Color("59625d"))
	label_at(Vector2(428, 355), "ROCK OUTCROP", 16)
	draw_arc(model.OBJECTIVE, 35, 0, TAU, 50, Color("d4c58d"), 2)
	label_at(Vector2(715, 312), "OBJECTIVE A" + (" / secured" if model.secured else ""), 15)
	var colors := [Color("91d8b1"), Color("84bfd3"), Color("d3bd8d"), Color("d7cda3")]
	for index in range(model.squads.size()):
		var squad = model.squads[index]
		for person in squad.soldiers:
			if not person.active and not person.body_present:
				continue
			draw_circle(person.position, 6, colors[index] if person.active else Color("7b8177"))
		label_at(squad.center() + Vector2(-20, -22), squad.id, 15, colors[index])
	var label_boxes: Array[Rect2] = []
	var contact_index := 0
	for row in operations.situation().contacts:
		contact_index += 1
		var contact: Dictionary = row.report
		var point: Vector2 = contact.observed_position
		var box := Rect2(Vector2(clampf(point.x - 95, 40, 666), maxf(125, point.y - 72)), Vector2(230, 55))
		while label_boxes.any(func(used): return used.intersects(box)):
			box.position.y += 60
		label_boxes.append(box)
		var color := Color("9d998e") if row.freshness == "STALE" else Color("d49f8c")
		draw_arc(point, 16, 0, TAU, 35, color, 2)
		draw_line(point, box.position + Vector2(115, 55), Color(color, 0.45), 1)
		draw_rect(box, Color(0.07, 0.14, 0.14, 0.92))
		label_at(box.position + Vector2(6, 15), "#%d LAST KNOWN / %s (%.1fs)" % [contact_index, row.freshness, row.age], 12, color)
		label_at(box.position + Vector2(6, 32), "Observed T%.1f / received T%.1f" % [contact.observation_time, contact.received_at], 12)
		label_at(box.position + Vector2(6, 49), row.provenance, 11)
	for identity in ["Friendly-HQ", "Enemy-HQ"]:
		var hq: Dictionary = model.battle.hqs[identity]
		draw_rect(hq.geometry, Color("7aa8a1") if identity == "Friendly-HQ" else Color("c8b487"), false, 2)
		label_at(hq.position + Vector2(-50, -32), identity, 15)
		if identity == "Enemy-HQ" and model.battle_active():
			label_at(hq.position + Vector2(-76, 47), "Known strategic location", 12)
		elif not model.battle_active():
			label_at(hq.position + Vector2(-40, 48), hq.state, 13)
	var truck = model.supply.truck
	draw_rect(Rect2(truck.position - Vector2(14, 9), Vector2(28, 18)), Color("b7c9a7"))
	label_at(truck.position + Vector2(-35, 30), "Truck / %d" % truck.inventory.BoltActionRifleAmmo, 14)
	var mortar = model.artillery
	draw_circle(mortar.position, 10, Color("90aaa0"))
	label_at(mortar.position + Vector2(-57, 32), "Friendly mortar", 14)
	for mission in mortar.missions:
		if mission.state == "IN_FLIGHT":
			var progress: float = clampf((model.elapsed - mission.fired_at) / mortar.FLIGHT, 0, 1)
			draw_circle(mortar.position.lerp(mission.target, progress), 4, Color("e4cf8f"))
		elif mission.state == "IMPACTED" and model.elapsed - mission.impact_at < 0.8:
			draw_arc(mission.target, 30, 0, TAU, 40, Color("deb483"), 2)
	if not model.information.world_event.is_empty():
		var seen: Dictionary = model.information.player_observation()
		draw_arc(seen.location, 24, 0, TAU, 32, Color("b7a18e"), 1)
	if inquiry_mode:
		label_at(Vector2(180, 675), "INQUIRY: click a location. Results are established reports, not live truth.", 15)
	else:
		label_at(Vector2(180, 675), "Contact labels show age and provenance. They do not track live enemies.", 15)
	if queried:
		draw_arc(query_point, model.information.QUERY_RADIUS, 0, TAU, 50, Color("8fc9d2"), 2)

func _draw() -> void:
	draw_rect(model.rear.MAP, Color("1c302e"))
	label_at(Vector2(28, 40), "TRENCHO / " + ("PROTECTED REAR" if view_mode == "rear" else "BATTLEFIELD OBSERVATION"), 25)
	label_at(Vector2(28, 76), "World T%.1f  |  %s" % [model.elapsed, "PAUSED: reconstruction" if model.information.reconstructing else ("FROZEN: battle ended" if not model.battle_active() else "Both maps share this world time")], 16)
	if model.information.reconstructing:
		label_at(Vector2(80, 180), "HISTORICAL RECONSTRUCTION / WORLD PAUSED", 23)
		for record in model.information.reconstruction:
			draw_circle(record.location, 28, Color(0.5, 0.85, 1, 0.17))
			label_at(record.location + Vector2(40, 0), "Known explosion / friendly casualty", 17)
			label_at(record.location + Vector2(40, 27), "Observation T%.1f / %s" % [record.observation_time, record.soldier_id], 16)
		label_at(Vector2(80, 225), "Established evidence, not live battlefield truth. Source remains unknown. Esc: return.", 16)
	elif view_mode == "rear":
		draw_rear()
	else:
		draw_battlefield()
	draw_supply_panel()
	var status: Dictionary = operations.situation()
	draw_rect(Rect2(180, 691, 720, 48), Color("142a26"))
	label_at(Vector2(196, 711), status.prompt, 15, Color("e0cf98"))
	label_at(Vector2(196, 732), status.chain.explanation, 12)
	if not model.battle_active():
		draw_rect(Rect2(170, 300, 600, 145), Color("102522"))
		label_at(Vector2(350, 348), "VICTORY" if model.battle_state == "ENDED_FRIENDLY_VICTORY" else "DEFEAT", 35, Color("e4d29b"))
		label_at(Vector2(280, 389), "Battle ended / world frozen", 23)
		label_at(Vector2(250, 421), "Primary HQ destroyed by autonomous artillery", 17)
	draw_rect(Rect2(24, 750, 1231, 50), Color("102522"))
	var newest: Dictionary = operations.alerts.primary()
	var counts: Dictionary = operations.alerts.counts()
	if newest.is_empty():
		label_at(Vector2(38, 770), "ALERTS: none unread / H: priority history", 14)
	else:
		var prefix: String = {"RESULT": "RESULT", "ACTION_REQUIRED": "ACTION NEEDED", "INFORMATION": "INFO"}[newest["class"]]
		if newest.state == "RESOLVED":
			prefix = "RESOLVED"
		if newest.acknowledged:
			prefix += " ACK"
		label_at(Vector2(38, 770), "%s / T%.1f  %s" % [prefix, newest.time, newest.text], 14, Color("e4d29b"))
	label_at(Vector2(38, 792), "ACTION open %d / unread %d | INFO unread %d | RESULT unread %d%s" % [counts.action_open, counts.action_unread, counts.information_unread, counts.result_unread, " / " + attention_text(newest.area) if not newest.is_empty() else ""], 12)
