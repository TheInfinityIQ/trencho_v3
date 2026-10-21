extends Node2D

const Scenario = preload("res://scenario.gd")
var model = Scenario.new()
var font := ThemeDB.fallback_font
var colors := [Color("85d9b0"), Color("7ebcda"), Color("d7b981"), Color("e0d3a5")]

func _ready() -> void:
	for entry in model.trace:
		print(JSON.stringify(entry))

func _physics_process(delta: float) -> void:
	model.advance(delta)
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16, color := Color("dce7df")) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_rect(Rect2(24, 105, 888, 645), Color("182b2b"))
	for x in range(40, 910, 40):
		draw_line(Vector2(x, 105), Vector2(x, 750), Color(0.6, 0.8, 0.6, 0.045))
	for y in range(110, 750, 40):
		draw_line(Vector2(24, y), Vector2(912, y), Color(0.6, 0.8, 0.6, 0.045))
	label_at(Vector2(28, 40), "TRENCHO / HIERARCHICAL INFANTRY PROOF", 25)
	label_at(Vector2(28, 73), "Autonomous scenario  •  Observation only  •  Prototype geometry", 16, Color("93aaa8"))
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
				var points := PackedVector2Array([soldier.origin])
				points.append_array(PackedVector2Array(soldier.path))
				draw_polyline(points, Color(color, 0.12), 1)
			draw_circle(soldier.position, 6, color)
			draw_arc(soldier.position, 8, 0, TAU, 16, Color(color, 0.5), 1)
			label_at(soldier.position + Vector2(9, 4), soldier.id.get_slice(".", 1), 11, color)
		label_at(squad.center() + Vector2(-20, -26), squad.id, 16, color)
	label_at(Vector2(273, 565), "P1-B / SUPPORT", 16, colors[1])
	draw_rect(Rect2(930, 105, 325, 645), Color("112025"))
	label_at(Vector2(948, 137), "COMMAND DECISIONS", 19)
	var lines := ["HQ  /  Secure Objective A", "One scenario objective", "", "COMPANY  /  Allocate force", "P1 main effort · P2 reserve", "Closest platoon; retain capacity", "", "P1  /  Divide responsibilities", "A seizes · B stages in support", "", "P1-A  /  Solve local approach", "Rock blocks direct movement", "Squad selects a north bypass", "", "SOLDIERS  /  Execute", "Independent positions and pace", "Four paths; loose cohesion", "", "P2  /  Hold reserve", "No release order; remains staged"]
	for index in range(lines.size()):
		label_at(Vector2(948, 175 + index * 23), lines[index], 14)
	label_at(Vector2(28, 781), "Elapsed %.1fs   |   %s" % [model.elapsed, "Objective reached; support and reserve hold" if model.secured else "Watch P1-A navigate around the outcrop"], 16)
