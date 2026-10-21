extends "res://operations_view.gd"

const PriorityOperations = preload("res://priority_operations.gd")
var priority_buttons: Array[Button] = []
var context_panel: Panel
var context_headers: Array[Label] = []
var context_bodies: Array[Label] = []

func _init() -> void:
	operations = PriorityOperations.new()
	model = operations.world

func _ready() -> void:
	super._ready()
	priority_buttons.append(button("PRIORITIZE REQUEST-A", Vector2(45, 290), func(): set_priority("Request-A"), 210))
	priority_buttons.append(button("PRIORITIZE REQUEST-B", Vector2(45, 330), func(): set_priority("Request-B"), 210))
	priority_buttons.append(button("ALL NORMAL", Vector2(45, 370), func(): set_priority("", "NORMAL"), 210))
	button("REQUEST CONTEXT [C]", Vector2(945, 5), toggle_context)
	context_panel = Panel.new()
	context_panel.position = Vector2(270, 115)
	context_panel.size = Vector2(650, 550)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("112025")
	context_panel.add_theme_stylebox_override("panel", background)
	context_panel.visible = false
	add_child(context_panel)
	var title := Label.new()
	title.position = Vector2(15, 12)
	title.text = "REQUEST COMPARISON — friendly facts only / C: close"
	title.add_theme_font_size_override("font_size", 15)
	context_panel.add_child(title)
	for index in range(2):
		var heading := Label.new()
		heading.position = Vector2(15, 50 + index * 250)
		heading.add_theme_font_size_override("font_size", 16)
		context_panel.add_child(heading)
		context_headers.append(heading)
		var body := Label.new()
		body.position = Vector2(15, 80 + index * 250)
		body.size = Vector2(620, 205)
		body.add_theme_font_size_override("font_size", 13)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		context_panel.add_child(body)
		context_bodies.append(body)
	refresh()

func toggle_context() -> void:
	context_panel.visible = not context_panel.visible
	if context_panel.visible:
		alert_panel.visible = false
	refresh()

func toggle_alert_history() -> void:
	if context_panel != null:
		context_panel.visible = false
	super.toggle_alert_history()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		toggle_context()
		get_viewport().set_input_as_handled()
	else:
		super._input(event)

func set_priority(identity: String, value := "PRIORITY") -> void:
	if view_mode == "rear" and model.battle_active():
		operations.set_priority(identity, value)

func refresh() -> void:
	super.refresh()
	for item in priority_buttons:
		item.visible = view_mode == "rear"
		item.disabled = not model.battle_active()
	if context_panel != null:
		var requests: Array = operations.situation().requests
		for index in range(requests.size()):
			var request: Dictionary = requests[index]
			var context: Dictionary = request.context
			context_headers[index].text = "%s / %s / %s" % [request.id, request.formation, context.command_role]
			context_bodies[index].text = "Task: %s / Mission: %s\nRequested %d / delivered %d / need %d / %s / %s\n%s\nRequest created T%.1f / age %.1fs\nOwn Supply record T%.1f / age %.1fs (direct friendly logistics)\nSource: %s\nAssignment established T%.1f (retained until hierarchy replaces)\nSource: %s" % [context.task_summary, context.mission_id, request.requested, request.delivered, request.remaining, request.priority, request.state, context.supply_reason, context.request_created_at, context.request_age, context.supply_record_time, context.supply_age, context.supply_provenance, context.command_record_time, context.command_provenance]

func draw_supply_panel() -> void:
	draw_rect(Rect2(930, 105, 325, 645), Color("112025"))
	var status: Dictionary = operations.situation()
	label_at(Vector2(945, 133), "MILITARY REQUESTS", 18)
	for index in range(status.requests.size()):
		var request: Dictionary = status.requests[index]
		var y: float = 155 + index * 65
		label_at(Vector2(945, y), "%s / %s / %s" % [request.id, request.formation, request.priority], 13, Color("e0cf98") if request.priority == "PRIORITY" else Color("dce7df"))
		label_at(Vector2(945, y + 18), "Requested %d / delivered %d / need %d" % [request.requested, request.delivered, request.remaining], 12)
		label_at(Vector2(945, y + 36), "%s / commitment %d" % [request.state, request.allocated if request.state == "COMMITTED" else 0], 12)
		label_at(Vector2(945, y + 51), request.context.command_role + " / C: context", 12)
	label_at(Vector2(945, 287), "REAR STOCK", 17)
	label_at(Vector2(945, 308), "Finished %d / committed %d / eligible %d" % [status.stock.finished, status.stock.committed, status.stock.eligible], 12)
	wrapped_label(Vector2(945, 330), status.stock.explanation, 292, 12)
	label_at(Vector2(945, 377), "REAR WORK", 17)
	label_at(Vector2(945, 398), "Workbench: %s / Metal %d" % ["available" if status.work.bench else "not placed", model.rear.metal], 13)
	label_at(Vector2(945, 419), status.work.state, 12)
	label_at(Vector2(945, 440), "Worker: " + status.work.worker, 11)
	if view_mode == "battlefield":
		wrapped_label(Vector2(945, 477), status.report_activity)
		wrapped_label(Vector2(945, 526), operations.Situation.inquiry(query_result, queried))

func draw_rear() -> void:
	super.draw_rear()
	label_at(Vector2(45, 270), "LOGISTICS PRIORITY", 17)
	label_at(Vector2(45, 425), "Policy authorizes; priority selects", 13)
	label_at(Vector2(45, 446), "uncommitted stock only.", 13)
	if not model.rear.commitment_request_id.is_empty():
		label_at(Vector2(635, 390), "Assignment: " + model.rear.commitment_request_id, 15)

func draw_battlefield() -> void:
	super.draw_battlefield()
	var truck = model.additional_supplies[0].truck
	draw_rect(Rect2(truck.position - Vector2(14, 9), Vector2(28, 18)), Color("cbbb85"))
	label_at(truck.position + Vector2(-30, -20), "Truck B / %d" % truck.inventory.BoltActionRifleAmmo, 13)

func rear_status_text() -> String:
	var summaries: Array[String] = []
	for request in operations.situation().requests:
		summaries.append("%s: %s (need %d)" % [request.id, request.state, request.remaining])
	return " / ".join(summaries)
