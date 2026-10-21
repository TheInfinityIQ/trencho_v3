extends RefCounted

var id: String
var position: Vector2
var origin: Vector2
var path: Array[Vector2] = []
var speed: float
var travelled := 0.0
var arrived := false
var waypoint := 0
var active := true

func _init(identity: String, start: Vector2, pace: float) -> void:
	id = identity
	position = start
	origin = start
	speed = pace

func advance(delta: float) -> void:
	if not active:
		return
	var budget := speed * delta
	while budget > 0.0 and waypoint < path.size():
		var distance := position.distance_to(path[waypoint])
		var step := minf(distance, budget)
		position = position.move_toward(path[waypoint], step)
		travelled += step
		budget -= step
		if distance <= step:
			waypoint += 1
	arrived = not path.is_empty() and waypoint == path.size()
