extends Node2D
## Read-only adapter. Hosts advance the existing model, then call sample().
const Person = preload("res://soldier.gd")
const Art = preload("res://soldier_art.gd")
var model_to_presentation := Transform2D.IDENTITY
var world_units_per_design_meter := 32.0
var assembly: Node2D
var parts: Dictionary = {}
var clip_name := "standing_idle"
var frame_index := 0
var clip_time := 0.0
var unsupported: Array[String] = []
var identity := ""
var role := ""
var equipment := ""
var _model: WeakRef
var _last_position := Vector2.ZERO
var _last_facing := Vector2.UP
var _last_medical := ""
var _moving := false
var _data: Dictionary

func _ready() -> void:
	ensure_parts()

func ensure_parts() -> void:
	if assembly != null: return
	assembly = Node2D.new()
	add_child(assembly)
	for name in Art.PARTS:
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.offset = Vector2(-48, -56)
		assembly.add_child(sprite)
		parts[name] = sprite
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_data = Art.clip(clip_name)

func bind_model(person: Person) -> void:
	ensure_parts()
	_model = weakref(person) if person != null else null
	_last_position = person.position if person != null else Vector2.ZERO
	_last_facing = Vector2.UP
	_last_medical = ""
	_moving = false
	clip_name = "standing_idle"
	clip_time = 0.0
	_data = Art.clip(clip_name)
	sample(0.0)

func person() -> Person:
	return _model.get_ref() if _model != null else null

func map_direction(direction: Vector2) -> Vector2:
	return model_to_presentation.x * direction.x + model_to_presentation.y * direction.y

func sample(delta: float, context: Dictionary = {}) -> void:
	ensure_parts()
	var actor := person()
	unsupported.clear()
	if actor == null:
		visible = false
		unsupported.append("MODEL_UNBOUND")
		return
	identity = actor.id
	role = actor.normal_role
	equipment = actor.weapon_category
	position = model_to_presentation * actor.position
	assembly.scale = Vector2.ONE * world_units_per_design_meter / 32.0
	var displacement := map_direction(actor.position - _last_position)
	var look: Vector2 = context.get("look_vector", Vector2.ZERO)
	if look.is_finite() and look.length_squared() > 0.00000001:
		var mapped := map_direction(look)
		if mapped.length_squared() > 0.00000001: _last_facing = mapped.normalized()
	elif displacement.length_squared() > 0.00000001:
		_last_facing = displacement.normalized()
	assembly.rotation = _last_facing.angle() + PI / 2
	if delta > 0:
		_moving = displacement.length_squared() > 0.00000001 and not actor.arrived
	_last_position = actor.position
	visible = actor.on_battlefield and (actor.medical_state != "DEAD" or actor.body_present)
	var next := "standing_idle"
	if actor.medical_state == "DEAD":
		next = "death_backward"
		# Model has no impact/fall direction: documented generic death fallback.
		unsupported.append("DEATH_DIRECTION_UNAVAILABLE")
	elif actor.medical_state in ["WOUNDED", "STABILIZED"]:
		# Neither diagnosis specifies posture; do not invent prone/kneeling state.
		unsupported.append("UNSUPPORTED_VISUAL: " + actor.medical_state)
	elif not actor.active:
		unsupported.append("UNSUPPORTED_VISUAL: INACTIVE")
	elif _moving:
		next = "standing_walk"
	var action: String = context.get("action", "")
	if not action.is_empty(): unsupported.append("UNSUPPORTED_VISUAL: " + action)
	if equipment != "BoltActionRifle": unsupported.append("UNSUPPORTED_EQUIPMENT: " + equipment)
	if next != clip_name:
		clip_name = next
		_data = Art.clip(clip_name)
		clip_time = 0.0
		if next == "death_backward" and _last_medical.is_empty():
			# Binding an existing corpse should not replay a death it just observed.
			clip_time = float(_data.metadata.cycle_seconds)
	clip_time += maxf(delta, 0.0)
	_last_medical = actor.medical_state
	var cycle: float = _data.metadata.cycle_seconds
	frame_index = floori(fposmod(clip_time, cycle) / cycle * 4) if _data.metadata.loop else mini(floori(clip_time / cycle * 4), 3)
	for name in Art.PARTS:
		var sprite: Sprite2D = parts[name]
		sprite.visible = _data.textures[frame_index].has(name)
		if sprite.visible: sprite.texture = _data.textures[frame_index][name]

func source_anchor_world(part: String, anchor: String) -> Variant:
	var frame: Dictionary = _data.metadata.frames[frame_index]
	if not frame.parts.has(part) or not frame.parts[part].anchors.has(anchor): return null
	var point: Array = frame.parts[part].anchors[anchor]
	return assembly.to_global(Vector2(point[0], point[1]) - Vector2(48, 56))

func muzzle_world() -> Variant:
	return source_anchor_world("rifle_topdown", "muzzle")
