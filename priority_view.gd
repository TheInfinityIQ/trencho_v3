extends "res://operations_view.gd"

const PriorityOperations = preload("res://priority_operations.gd")
var priority_buttons: Array[Button] = []

func _init() -> void:
	operations = PriorityOperations.new()
	model = operations.world

func _ready() -> void:
	super._ready()
	priority_buttons.append(button("PRIORITIZE REQUEST-A", Vector2(45, 290), func(): set_priority("Request-A"), 210))
	priority_buttons.append(button("PRIORITIZE REQUEST-B", Vector2(45, 330), func(): set_priority("Request-B"), 210))
	priority_buttons.append(button("ALL NORMAL", Vector2(45, 370), func(): set_priority("", "NORMAL"), 210))
	refresh()

func set_priority(identity: String, value := "PRIORITY") -> void:
	if view_mode == "rear" and model.battle_active():
		operations.set_priority(identity, value)

func refresh() -> void:
	super.refresh()
	for item in priority_buttons:
		item.visible = view_mode == "rear"
		item.disabled = not model.battle_active()

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
