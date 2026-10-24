extends Node2D
## Presentation only; all stock, people and jobs belong to GameSession.rear.
var session
var font := ThemeDB.fallback_font
func text(at: Vector2, value: String, size := 18, color := Color("dbe8d7")) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
func _draw() -> void:
	if session == null: return
	var rear = session.rear
	draw_rect(rear.MAP, Color("1c302e"))
	text(Vector2(30, 92), "PROTECTED LOGISTICS REAR", 24)
	draw_rect(rear.RAW_STORE, Color("586965"))
	text(Vector2(92, 184), "RAW STORAGE", 17)
	text(Vector2(92, 218), "Metal: %d" % rear.metal)
	draw_rect(rear.DISPATCH, Color("64664f"))
	text(Vector2(715, 180), "DISPATCH", 17)
	text(Vector2(690, 327), "No active shipment", 16)
	text(Vector2(690, 350), "Stock remains in rear", 16)
	draw_rect(Rect2(rear.workbench - Vector2(27, 17), Vector2(54, 34)), Color("b5a17c"))
	text(rear.workbench + Vector2(-78, -40), "AMMO WORKBENCH", 17)
	if not rear.job.is_empty():
		var progress: float = clampf((session.elapsed - rear.job.started_at) / rear.JOB_DURATION, 0, 1)
		draw_rect(Rect2(rear.workbench + Vector2(-45, 28), Vector2(90, 8)), Color("101c1d"))
		draw_rect(Rect2(rear.workbench + Vector2(-45, 28), Vector2(90 * progress, 8)), Color("a8dfba"))
		text(rear.workbench + Vector2(-70, 65), "Work: %.1fs left" % maxf(0, rear.job.finishes_at - session.elapsed), 16)
	draw_circle(rear.worker.position, 9, Color("e0bc83"))
	text(rear.worker.position + (Vector2(-125, -25) if rear.worker.position.distance_to(rear.workbench) < 70 else Vector2(-40, -20)), "WORKER", 15)
	draw_circle(rear.avatar, 11, Color("8ed4df"))
	text(rear.avatar + Vector2(-48, 0), "YOU", 15, Color("8ed4df"))
	text(Vector2(46, 675), "WASD / arrows: walk   |   E: manual batch   |   F: 3-batch Worker order", 16)
	text(Vector2(46, 705), "Tab: observe battlefield   |   Space: pause / resume", 16)
