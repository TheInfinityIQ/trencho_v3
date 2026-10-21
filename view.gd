extends Node2D

const Scenario = preload("res://scenario.gd")
var model = Scenario.new(true, true, true)
var font := ThemeDB.fallback_font
var colors := [Color("85d9b0"), Color("7ebcda"), Color("d7b981"), Color("e0d3a5")]
var inquiry_mode := false
var queried := false
var query_point := Vector2.ZERO
var query_result: Array[Dictionary] = []
var inquiry_button: Button
var reconstruction_button: Button
var exit_button: Button
var view_mode := "rear"
var placing := false
var rear_buttons: Array[Button] = []
var map_button: Button

func _ready() -> void:
	for entry in model.trace:
		print(JSON.stringify(entry))
	inquiry_button = add_button("BINOCULAR INQUIRY [B]", Vector2(945, 625), toggle_inquiry)
	reconstruction_button = add_button("RECONSTRUCT [R]", Vector2(945, 667), reconstruct)
	exit_button = add_button("EXIT RECONSTRUCTION [Esc]", Vector2(945, 709), exit_reconstruction)
	map_button = add_button("SWITCH MAP [Tab]", Vector2(945, 45), switch_map)
	rear_buttons.append(add_button("AVAILABLE [1]", Vector2(945, 370), func(): model.rear.set_policy("AVAILABLE")))
	rear_buttons.append(add_button("RESERVE 8 [2]", Vector2(945, 412), func(): model.rear.set_policy("RESERVE", 8)))
	rear_buttons.append(add_button("LOCKED [3]", Vector2(945, 454), func(): model.rear.set_policy("LOCKED")))
	rear_buttons.append(add_button("PLACE WORKBENCH [P]", Vector2(945, 583), func(): placing = true))
	rear_buttons.append(add_button("MANUAL BATCH [E]", Vector2(945, 625), manual_work))
	rear_buttons.append(add_button("ASSIGN WORKER / 1 BATCH [F]", Vector2(945, 667), assign_worker))
	refresh_controls()

func switch_map() -> void:
	if model.integrated_rear and not model.information.reconstructing:
		view_mode = "battlefield" if view_mode == "rear" else "rear"
		placing = false
		refresh_controls()

func manual_work() -> void:
	model.rear.start_job("Avatar", model.elapsed)

func assign_worker() -> void:
	model.rear.assign_worker()

func refresh_controls() -> void:
	var is_rear: bool = view_mode == "rear" and model.integrated_rear
	for button in rear_buttons:
		button.visible = is_rear
	inquiry_button.visible = not is_rear
	reconstruction_button.visible = not is_rear
	exit_button.visible = not is_rear
	map_button.visible = model.integrated_rear

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

func _input(event: InputEvent) -> void:
	# Tab is also a UI focus key; handle map switching before GUI focus consumes it.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		switch_map()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			switch_map()
		elif view_mode == "rear" and model.integrated_rear:
			if event.keycode == KEY_P:
				placing = not placing
			elif event.keycode == KEY_E:
				manual_work()
			elif event.keycode == KEY_F:
				assign_worker()
			elif event.keycode == KEY_1:
				model.rear.set_policy("AVAILABLE")
			elif event.keycode == KEY_2:
				model.rear.set_policy("RESERVE", 8)
			elif event.keycode == KEY_3:
				model.rear.set_policy("LOCKED")
		elif event.keycode == KEY_B:
			toggle_inquiry()
		elif event.keycode == KEY_R:
			reconstruct()
		elif event.keycode == KEY_ESCAPE:
			exit_reconstruction()
			inquiry_mode = false
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if view_mode == "rear" and placing:
			if model.rear.place_workbench(event.position):
				placing = false
		elif view_mode == "battlefield" and inquiry_mode:
			inquire(event.position)

func _physics_process(delta: float) -> void:
	if view_mode == "rear" and model.integrated_rear:
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		model.rear.move_avatar(direction, delta)
	model.advance(delta)
	reconstruction_button.disabled = query_result.is_empty() or model.information.reconstructing
	exit_button.disabled = not model.information.reconstructing
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16, color := Color("dce7df")) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if view_mode == "rear" and model.integrated_rear:
		draw_rear()
		return
	draw_rect(Rect2(24, 105, 888, 645), Color("182b2b"))
	for x in range(40, 910, 40):
		draw_line(Vector2(x, 105), Vector2(x, 750), Color(0.6, 0.8, 0.6, 0.045))
	for y in range(110, 750, 40):
		draw_line(Vector2(24, y), Vector2(912, y), Color(0.6, 0.8, 0.6, 0.045))
	if model.vehicles != null:
		var network = model.vehicles
		for edge in network.edges:
			var is_road: bool = edge.terrain == "ROAD"
			draw_line(network.points[edge.a], network.points[edge.b], Color("4c5953") if is_road else Color("537c67"), network.ROAD_HALF_WIDTH * 2 if is_road else 3)
		for vehicle in [network.truck, network.tracked]:
			for segment in range(vehicle.route.size() - 1):
				draw_line(network.points[vehicle.route[segment]], network.points[vehicle.route[segment + 1]], Color("b6a36e") if vehicle.mobility_class == "ROAD_ONLY" else Color("76cbd5"), 1.5)
		draw_rect(network.BLOCKAGE, Color("b36755"))
		draw_line(network.BLOCKAGE.position, network.BLOCKAGE.end, Color("f0b59b"), 3)
		draw_line(Vector2(network.BLOCKAGE.position.x, network.BLOCKAGE.end.y), Vector2(network.BLOCKAGE.end.x, network.BLOCKAGE.position.y), Color("f0b59b"), 3)
		label_at(Vector2(240, 136), "Blocked crossing", 13)
		label_at(Vector2(244, 235), "Tracked bypass", 13, Color("8fbca4"))
	label_at(Vector2(28, 40), "TRENCHO / PHYSICAL SUPPLY PROOF", 25)
	label_at(Vector2(28, 73), "[B] Binoculars: click any map location  •  [R] Reconstruct known history  •  [Esc] Exit", 16, Color("93aaa8"))
	draw_rect(Scenario.OBSTACLE, Color("59625d"))
	draw_rect(Scenario.OBSTACLE.grow(-8), Color("424e4b"))
	label_at(Vector2(425, 350), "ROCK OUTCROP", 15)
	label_at(Vector2(430, 377), "Impassable", 14)
	draw_circle(Scenario.OBJECTIVE, 40, Color(0.8, 0.72, 0.3, 0.14))
	draw_arc(Scenario.OBJECTIVE, 40, 0, TAU, 50, Color("ddce76"), 2)
	label_at(Vector2(745, 280), "OBJECTIVE A", 19, Color("e2d58b"))
	label_at(Vector2(754, 395 if model.combat != null else 415), "SECURED" if model.secured else "Approach", 16)
	draw_rect(Rect2(80, 160, 115, 55), Color("344e4e"))
	label_at(Vector2(95, 182), "Operational", 15)
	label_at(Vector2(95, 202), "+ Company HQ", 13)
	draw_rect(Rect2(95, 575, 240, 108), Color(0.75, 0.64, 0.4, 0.07))
	label_at(Vector2(100, 715), "P2 / RESERVE — holding", 17, colors[2])
	for index in range(model.squads.size()):
		var squad = model.squads[index]
		var color: Color = colors[index]
		for soldier in squad.soldiers:
			if not soldier.active and not soldier.body_present:
				continue
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
		if model.vehicles == null:
			draw_line(supply.DEPOT_POSITION, supply.RESUPPLY_POSITION, Color("52605a"), 13)
			draw_line(supply.DEPOT_POSITION, supply.RESUPPLY_POSITION, Color("9b9b77"), 1)
		draw_rect(Rect2(supply.DEPOT_POSITION - Vector2(17, 12), Vector2(34, 24)), Color("b6a47a"))
		label_at(Vector2(50, 102), "Depot: %d rounds" % supply.depot.inventory[supply.CATEGORY], 15)
		var truck_position: Vector2 = supply.truck.position
		draw_rect(Rect2(truck_position - Vector2(13, 8), Vector2(26, 16)), Color("b9c9aa"))
		draw_circle(truck_position + Vector2(-7, 9), 3, Color("17211e"))
		draw_circle(truck_position + Vector2(7, 9), 3, Color("17211e"))
		if model.vehicles != null:
			var tracked_position: Vector2 = model.vehicles.tracked.position
			draw_rect(Rect2(tracked_position - Vector2(11, 6), Vector2(22, 12)), Color("76bfce"))
			draw_line(tracked_position + Vector2(-11, -8), tracked_position + Vector2(11, -8), Color("abcdd0"), 2)
			draw_line(tracked_position + Vector2(-11, 8), tracked_position + Vector2(11, 8), Color("abcdd0"), 2)
		if not supply.requires_rear:
			draw_rect(Rect2(supply.CAPTURE_POSITION - Vector2(10, 8), Vector2(20, 16)), Color("c18969"))
			label_at(supply.CAPTURE_POSITION + Vector2(-55, 27), "Captured +4" if supply.captured_at >= 0 else "Enemy ammo: 4", 14)
		var ammo_panel := Vector2(40, 450) if model.combat != null and model.combat.first_contact >= 0 else Vector2(625, 112)
		draw_rect(Rect2(ammo_panel, Vector2(270, 124)), Color("112025"))
		label_at(ammo_panel + Vector2(13, 23), "P1-A / PHYSICAL AMMUNITION", 16)
		var counts: Array = []
		for soldier in model.squads[0].soldiers:
			counts.append(str(soldier.inventory[supply.CATEGORY]))
		label_at(ammo_panel + Vector2(13, 48), "Individuals: " + " / ".join(counts), 15)
		label_at(ammo_panel + Vector2(13, 73), "Carried %d / initial readiness %d" % [supply.carried(), supply.READY_THRESHOLD], 14)
		label_at(ammo_panel + Vector2(13, 101), supply.phase, 16, Color("e0c998"))
		label_at(Vector2(425, 520), "SUPPLY / CUSTODY DIAGNOSTICS", 16)
		label_at(Vector2(425, 546), "Depot %d · Truck %d · Carried %d · Enemy %d" % [supply.depot.inventory[supply.CATEGORY], supply.truck.inventory[supply.CATEGORY], supply.carried(), supply.captured.inventory[supply.CATEGORY]], 14)
		if model.integrated_rear:
			label_at(Vector2(425, 570), "Supply %d · Rear %d · Body/team 3 · Total %d" % [supply.total_accounted(), model.rear.ammunition, model.total_ammunition()], 14)
			label_at(Vector2(425, 676), "Truck: " + supply.truck.state, 14)
		else:
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
	if model.combat != null and not model.information.reconstructing:
		var combat = model.combat
		draw_rect(combat.LOW_COVER, Color("9b8964"))
		draw_rect(combat.BUNKER, Color("7b8179"))
		for enemy in combat.defenders.soldiers:
			if enemy.active:
				draw_circle(enemy.position, 6, Color("e49b85"))
			elif enemy.body_present:
				draw_line(enemy.position - Vector2(6, 6), enemy.position + Vector2(6, 6), Color("c78f7b"), 2)
				draw_line(enemy.position + Vector2(-6, 6), enemy.position + Vector2(6, -6), Color("c78f7b"), 2)
			label_at(enemy.position + Vector2(8, 5), "%s:%d" % [enemy.id.get_slice(".", 1), enemy.inventory[combat.AMMO]], 11, Color("eab5a6"))
		label_at(Vector2(715, 520), "Enemy defense / sandbags", 13)
		for shot in combat.shots:
			if model.elapsed - shot.time < 0.15:
				draw_line(shot.shooter_position, shot.target_position, Color(1, 0.8, 0.4, 0.6), 1)
		if combat.first_contact >= 0:
			draw_rect(Rect2(40, 250, 285, 185), Color("112025"))
			label_at(Vector2(54, 278), "INFANTRY CONTACT", 19)
			label_at(Vector2(54, 309), "Squad: " + combat.tactical_state, 16)
			label_at(Vector2(54, 336), "Suppression: %d (threshold 4)" % combat.suppression, 15)
			label_at(Vector2(54, 362), "Rounds fired: %d" % combat.shots.size(), 15)
			label_at(Vector2(54, 388), "Combat casualties: %d" % combat.history.size(), 15)
			label_at(Vector2(54, 415), "Local cover choice; HQ intent retained", 14)
	if not model.information.reconstructing:
		var recovery = model.recovery
		draw_circle(recovery.position, 9, Color("b4addd"))
		label_at(recovery.position + Vector2(12, 20), "Recovery Team", 14, Color("c8c3e5"))
		label_at(Vector2(40, 760), "Body present: %s · Body ammo: %d · Team ammo: %d · History: %s" % [str(recovery.casualty.body_present), recovery.casualty.inventory[recovery.CATEGORY], recovery.inventory[recovery.CATEGORY], str(not model.information.world_event.is_empty())], 14)
		label_at(Vector2(580, 730), recovery.state, 14)
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
	if model.vehicles != null:
		var truck = model.vehicles.truck
		var tracked = model.vehicles.tracked
		lines = ["Truck / Driver-01 / ROAD_ONLY", "%s · cargo%d · driver %s" % [truck.route_state, truck.inventory.BoltActionRifleAmmo, "ready" if truck.driver.active and truck.driver.assigned_vehicle_id == truck.id else "unavailable"], "Carrier / Driver-02 / TRACKED", "%s · cargo%d · driver %s" % [tracked.route_state, tracked.inventory.BoltActionRifleAmmo, "ready" if tracked.driver.active and tracked.driver.assigned_vehicle_id == tracked.id else "unavailable"], "", "REPORT RECEIPTS (1s / hop)"]
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

func draw_rear() -> void:
	var rear = model.rear
	draw_rect(rear.MAP, Color("213433"))
	label_at(Vector2(28, 40), "TRENCHO / PROTECTED REAR BASE", 25)
	label_at(Vector2(28, 73), "WASD move · P place · E manual batch · F worker batch · Tab switch view", 16)
	draw_rect(rear.RAW_STORE, Color("586965"))
	label_at(Vector2(94, 184), "RAW STORAGE", 17)
	label_at(Vector2(94, 217), "Metal: %d" % rear.metal, 18)
	draw_rect(rear.DISPATCH, Color("64664f"))
	label_at(Vector2(705, 185), "DISPATCH BOUNDARY", 15)
	label_at(Vector2(690, 330), "Shipment: %d rounds" % rear.shipment.cargo, 14)
	label_at(Vector2(690, 355), "Owner: " + rear.shipment.owner, 14)
	if rear.shipment.state == "Inter-map transit":
		label_at(Vector2(660, 390), "Arrival at world T=%.1f" % rear.shipment.arrives_at, 15)
	if rear.committed > 0:
		draw_rect(Rect2(745, 225, 35, 28), Color("d5b37f"))
		label_at(Vector2(688, 420), "8 earmarked / still rear-owned", 14)
	if rear.placed:
		draw_rect(Rect2(rear.workbench - Vector2(27, 17), Vector2(54, 34)), Color("b5a17c"))
		label_at(rear.workbench + Vector2(-80, -30), "Ammunition workbench", 16)
		if not rear.job.is_empty():
			var progress: float = clampf((model.elapsed - rear.job.started_at) / rear.JOB_DURATION, 0, 1)
			draw_rect(Rect2(rear.workbench + Vector2(-35, 28), Vector2(70, 7)), Color("101d20"))
			draw_rect(Rect2(rear.workbench + Vector2(-35, 28), Vector2(70 * progress, 7)), Color("9ed3b5"))
			label_at(rear.workbench + Vector2(-80, 65), "%s / %.1f of 4s" % [rear.job.producer, model.elapsed - rear.job.started_at], 15)
	elif placing:
		label_at(Vector2(300, 300), "Click a free position for the workbench", 20, Color("d6d2ac"))
	draw_circle(rear.worker.position, 9, Color("e0bc83"))
	label_at(rear.worker.position + Vector2(-30, -18), "Worker-01", 14)
	draw_circle(rear.avatar, 10, Color("8ed4df"))
	label_at(rear.avatar + Vector2(-20, -20), "YOU", 14)
	draw_rect(Rect2(930, 105, 325, 645), Color("112025"))
	label_at(Vector2(945, 135), "REAR STOCK / AUTHORIZATION", 17)
	var request_status := "not yet issued"
	if model.supply.delivered_at >= 0:
		request_status = "delivered to soldiers"
	elif rear.shipment.state != "None":
		request_status = "in military supply chain"
	elif rear.committed > 0:
		request_status = "eight committed"
	elif model.supply.requested_at >= 0:
		request_status = "pending eight rounds"
	var lines := ["Metal: %d   Produced rounds: %d" % [rear.metal, rear.produced], "Ammo on hand: %d (rear-owned)" % rear.ammunition, "Committed subset: %d" % rear.committed, "Eligible new draw: %d" % rear.eligible(), "Policy: %s %s" % [rear.policy, str(rear.reserve) if rear.policy == "RESERVE" else ""], "Worker: " + ("assigned / one batch" if rear.worker.assigned else "unassigned"), "Request: " + request_status]
	for index in range(lines.size()):
		label_at(Vector2(945, 172 + index * 25), lines[index], 14)
	label_at(Vector2(945, 520), "1 Metal → 8 rounds / 4 world s", 15)
	label_at(Vector2(945, 548), "Capability unlocked (fixture)", 14)
	label_at(Vector2(50, 700), rear.message, 15)
	label_at(Vector2(28, 781), "World T=%.1f · Both maps advance continuously · Protected rear" % model.elapsed, 16)
