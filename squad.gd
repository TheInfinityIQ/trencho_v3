extends RefCounted

const Soldier = preload("res://soldier.gd")
var id: String
var soldiers: Array = []
var task := "Awaiting platoon intent"
var destination: Vector2
var route_side := "direct"
var decision: Dictionary = {}
var terrain: Rect2
var final_paths: Dictionary = {}

func stage_for_supply() -> void:
	for soldier in soldiers:
		final_paths[soldier.id] = soldier.path.slice(1)
		soldier.path.resize(1)

func resume_final_approach() -> void:
	for soldier in soldiers:
		soldier.route_origin = soldier.position
		soldier.path.assign(final_paths[soldier.id])
		soldier.waypoint = 0
		soldier.arrived = false

func _init(identity: String, start: Vector2) -> void:
	id = identity
	for index in range(4):
		var offset := Vector2((index % 2) * 24, (index / 2) * 24)
		soldiers.append(Soldier.new("%s.%d" % [id, index + 1], start + offset, 43.0 + index * 1.2))

func center() -> Vector2:
	var result := Vector2.ZERO
	for soldier in soldiers:
		result += soldier.position
	return result / soldiers.size()

func assign(local_task: String, target: Vector2, obstacle: Rect2) -> Dictionary:
	task = local_task
	terrain = obstacle
	destination = target
	var start := center()
	var clearance := obstacle.grow(46)
	var blocked := Geometry2D.segment_intersects_segment(start, target, clearance.position, clearance.position + Vector2(0, clearance.size.y)) != null
	# This fixture's approaches start west of the obstacle. Squad leadership, not
	# a higher command or the presentation, chooses the bypass and soldier paths.
	if blocked:
		var bottom_left := Vector2(clearance.position.x, clearance.end.y)
		var top_right := Vector2(clearance.end.x, clearance.position.y)
		var top := start.distance_to(clearance.position) + clearance.size.x + top_right.distance_to(target)
		var bottom := start.distance_to(bottom_left) + clearance.size.x + clearance.end.distance_to(target)
		route_side = "north" if top <= bottom else "south"
	for index in range(soldiers.size()):
		var soldier = soldiers[index]
		var final_position := target + Vector2((index % 2) * 23 - 12, (index / 2) * 23 - 12)
		if blocked:
			var bounds := obstacle.grow(22 + index * 8)
			var bypass_y := bounds.position.y if route_side == "north" else bounds.end.y
			soldier.path.assign([Vector2(bounds.position.x, bypass_y), Vector2(bounds.end.x, bypass_y), final_position])
		else:
			soldier.path.assign([final_position])
	decision = {"echelon": "Squad", "actor": id, "intent": task,
		"choice": "Route %s; four individual paths" % route_side,
		"reason": "Direct approach blocked by rock outcrop; shortest clear bypass" if blocked else "Clear local approach"}
	return decision

func advance(delta: float) -> void:
	for soldier in soldiers:
		soldier.advance(delta)
	# Local separation acts on real individual positions; there is no squad token
	# from which positions are regenerated. Clearance protects the outcrop boundary.
	for a in range(soldiers.size()):
		for b in range(a + 1, soldiers.size()):
			var difference: Vector2 = soldiers[b].position - soldiers[a].position
			var distance := difference.length()
			if distance < 14:
				var direction := difference / distance if distance > 0.001 else Vector2.UP
				var adjustment := direction * (14 - distance) * 0.5
				if not terrain.grow(7).has_point(soldiers[a].position - adjustment):
					soldiers[a].position -= adjustment
				if not terrain.grow(7).has_point(soldiers[b].position + adjustment):
					soldiers[b].position += adjustment

func complete() -> bool:
	for soldier in soldiers:
		if not soldier.arrived:
			return false
	return true
