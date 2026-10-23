extends Node2D
## Scoped fixture driver, never the campaign entry point.
const Person = preload("res://soldier.gd")
const Scenario = preload("res://scenario.gd")
const Visual = preload("res://soldier_visual.gd")
const Space = preload("res://representative_space.gd")
const BEARINGS := [0.0, 23.0, 67.0, 135.0, 217.0]
var clock := 0.0
var paused := false
var mode := "meter"
var bearing_index := 1
var debug_marks := false
var groups: Dictionary = {}
var visuals: Dictionary = {}
var people: Array = []
var cohort: Array = []
var legacy
var legacy_shooter
var legacy_mover
var casualty
var camera: Camera2D
var hud: Control
var overlay: Node2D
var font: Font
var ground: Array = []
var last_fire := -100.0
var cohort_sample_us := 0

class ProofHUD extends Control:
	var host
	func _draw() -> void: host.draw_hud(self)

class Markers extends Node2D:
	var host
	func _draw() -> void: host.draw_markers(self)

func _ready() -> void:
	font = ThemeDB.fallback_font
	for i in [1, 2]: ground.append(load("res://art/a1_grass_rev6/terrain/terrain_grass_%02d.png" % i))
	for name in ["meter", "legacy", "cohort"]:
		groups[name] = Node2D.new()
		add_child(groups[name])
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	overlay = Markers.new()
	overlay.host = self
	add_child(overlay)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = ProofHUD.new()
	hud.host = self
	layer.add_child(hud)
	var actions := [["1 Meter view", set_mode.bind("meter")], ["2 Existing state", set_mode.bind("legacy")], ["3 32 Soldiers", set_mode.bind("cohort")], ["Space Pause", toggle_pause], ["R Reset", reset_fixture], ["H Bearing", next_bearing], ["W Wound", wound_sample], ["K Casualty", casualty_sample], ["F Actual shot", fire_sample], ["D Anchors", toggle_marks]]
	for i in range(actions.size()):
		var item := Button.new()
		item.text = actions[i][0]
		item.position = Vector2(14 + (i % 5) * 249, 49 + floori(i / 5.0) * 35)
		item.size = Vector2(241, 30)
		item.focus_mode = Control.FOCUS_NONE
		item.pressed.connect(actions[i][1])
		hud.add_child(item)
	reset_fixture()

func attach(person, group: String, transform: Transform2D):
	var visual := Visual.new()
	visual.model_to_presentation = transform
	visual.world_units_per_design_meter = Space.WORLD_UNITS_PER_METER
	groups[group].add_child(visual)
	visual.bind_model(person)
	visuals[group].append(visual)
	return visual

func reset_fixture() -> void:
	for group in groups.values():
		for node in group.get_children():
			group.remove_child(node)
			node.queue_free()
	visuals = {"meter":[], "legacy":[], "cohort":[]}
	people.clear()
	cohort.clear()
	clock = 0
	last_fire = -100
	var meters := Transform2D(Vector2(32, 0), Vector2(0, 32), Vector2.ZERO)
	var idle = Person.new("Meter-Idle", Vector2(42, 32), 1.4)
	people.append(idle)
	attach(idle, "meter", meters)
	var walker = Person.new("Meter-Walk", Vector2(60, 36), 1.4)
	var direction := Vector2.UP.rotated(deg_to_rad(BEARINGS[bearing_index]))
	walker.path.assign([walker.position + direction * 16, walker.position + direction * 16 + direction.rotated(PI / 2) * 8])
	people.append(walker)
	attach(walker, "meter", meters)
	for i in range(32):
		var person = Person.new("Cohort-%02d" % i, Vector2(20 + (i % 8) * 8, 22 + floori(i / 8.0) * 8), 1.4)
		var heading: float = BEARINGS[1 + i % 4]
		person.path.assign([person.position + Vector2.UP.rotated(deg_to_rad(heading)) * 16])
		cohort.append(person)
		attach(person, "cohort", meters)
	# Existing Scenario/Soldier/Medical/Combat state and APIs; legacy units stay legacy.
	legacy = Scenario.new(false, true, false, false, false, false, true)
	legacy_shooter = legacy.squads[0].soldiers[0]
	legacy_mover = legacy.squads[0].soldiers[1]
	casualty = legacy.squads[0].soldiers[3]
	legacy_shooter.path.clear()
	legacy_shooter.inventory.BoltActionRifleAmmo = 3
	legacy_mover.path.assign([legacy_mover.position + Vector2(80, 0)])
	legacy_mover.waypoint = 0
	legacy_mover.arrived = false
	var x := Vector2.RIGHT.rotated(0.3) * 2
	var y := Vector2.DOWN.rotated(0.3) * 2
	var offset: Vector2 = Space.point_to_world(Vector2(62, 35)) - x * legacy_shooter.position.x - y * legacy_shooter.position.y
	var legacy_map := Transform2D(x, y, offset)
	for person in [legacy_shooter, legacy_mover, casualty]: attach(person, "legacy", legacy_map)
	legacy.combat.defenders.soldiers[0].position = legacy_shooter.position + Vector2(80, 0)
	sync_visuals(0)
	set_mode(mode)

func sync_visuals(delta: float) -> void:
	for visual in visuals.meter: visual.sample(delta)
	for visual in visuals.legacy:
		var context := {}
		if visual.person() == legacy_shooter and clock - last_fire < 0.2:
			context = {"action":"FIRE", "look_vector":legacy.combat.defenders.soldiers[0].position - legacy_shooter.position}
		visual.sample(delta, context)
	var start := Time.get_ticks_usec()
	for visual in visuals.cohort: visual.sample(delta)
	cohort_sample_us = Time.get_ticks_usec() - start

func advance_fixture(delta: float) -> void:
	clock += delta
	for person in people + cohort: person.advance(delta)
	legacy_mover.advance(delta)
	sync_visuals(delta)
	refresh()

func _physics_process(delta: float) -> void:
	if not paused: advance_fixture(delta)

func refresh() -> void:
	queue_redraw()
	if hud != null: hud.queue_redraw()
	if overlay != null: overlay.queue_redraw()

func set_mode(value: String) -> void:
	mode = value
	for name in groups: groups[name].visible = name == mode
	camera.position = Space.point_to_world(Vector2(64, 35))
	camera.zoom = Vector2.ONE * (1.0 if mode == "legacy" else Space.ZOOMS.local)
	camera.force_update_scroll()
	refresh()

func toggle_pause() -> void:
	paused = not paused
	refresh()

func next_bearing() -> void:
	bearing_index = (bearing_index + 1) % BEARINGS.size()
	reset_fixture()

func toggle_marks() -> void:
	debug_marks = not debug_marks
	refresh()

func wound_sample() -> void:
	legacy.medical.wound(casualty, legacy.combat.defenders.soldiers[0], clock)
	sync_visuals(0)
	set_mode("legacy")

func casualty_sample() -> void:
	legacy.combat.kill(casualty, legacy.combat.defenders.soldiers[0], clock)
	sync_visuals(0)
	set_mode("legacy")

func fire_sample() -> void:
	var target = legacy.combat.defenders.soldiers[0]
	legacy.combat.detect(legacy_shooter, [target])
	if legacy.combat.attempt_shot(legacy_shooter, target, clock, 1.0): last_fire = clock
	sync_visuals(0)
	set_mode("legacy")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_1: set_mode("meter")
		KEY_2: set_mode("legacy")
		KEY_3: set_mode("cohort")
		KEY_SPACE: toggle_pause()
		KEY_R: reset_fixture()
		KEY_H: next_bearing()
		KEY_W: wound_sample()
		KEY_K: casualty_sample()
		KEY_F: fire_sample()
		KEY_D: toggle_marks()

func _draw() -> void:
	if ground.is_empty(): return
	for row in range(10):
		for col in range(16): draw_texture_rect(ground[(row + col) % 2], Rect2(col * 256, row * 256, 256, 256), false)

func draw_markers(canvas: Node2D) -> void:
	if not debug_marks: return
	var pixel := 1.0 / camera.zoom.x
	for visual in visuals[mode]:
		if not visual.visible: continue
		canvas.draw_circle(visual.position, 3 * pixel, Color("e6bc69"))
		var muzzle = visual.muzzle_world()
		if muzzle != null: canvas.draw_circle(muzzle, 3 * pixel, Color("7ddce6"))
		if camera.zoom.x <= 1:
			canvas.draw_string(font, visual.position + Vector2(9, 10) * pixel, visual.identity, HORIZONTAL_ALIGNMENT_LEFT, -1, 12 * pixel, Color.WHITE)

func line_at(c: Control, y: float, text: String, size := 16) -> void:
	c.draw_string(font, Vector2(14, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("e2e9e0"))

func draw_hud(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 1280, 150), Color("102026"))
	line_at(c, 25, "REAL SOLDIER STATE / provisionally approved modular presentation", 22)
	line_at(c, 44, "%s | zoom %.4f | t %.2f | paused %s | heading %.0f deg" % [mode, camera.zoom.x, clock, paused, BEARINGS[bearing_index]], 15)
	line_at(c, 138, "Meter view: real Soldier.advance at 1.4 m/s. Existing-state view: original fixture units with a separate affine map.", 15)
	c.draw_rect(Rect2(0, 698, 1280, 102), Color("102026"))
	if mode == "legacy":
		line_at(c, 720, "Accepted Combat/Medical calls drive casualty state. Wounded-specific art, fire/reload and death direction are unavailable.", 15)
		line_at(c, 741, "Casualty: %s | shots %d | rounds %d | fixture movement %.1f model units/s (not meters)" % [casualty.medical_state, legacy.combat.shots.size(), legacy_shooter.inventory.BoltActionRifleAmmo, legacy_mover.speed], 15)
		var rows: Array[String] = []
		for visual in visuals.legacy: rows.append("%s %s/%d %s" % [visual.identity, visual.clip_name, visual.frame_index, str(visual.unsupported)])
		line_at(c, 766, " | ".join(rows), 12)
	elif mode == "cohort":
		line_at(c, 724, "32 visible Soldiers / 14 nodes each / shared source textures / diagnostic cohort, not a battlefield-density benchmark")
		line_at(c, 750, "Latest cohort presentation sample %.3f ms; all movement still comes from existing Soldier.advance." % (cohort_sample_us / 1000.0))
	else:
		line_at(c, 722, "Idle retains facing. Walking follows real movement. No model state is authored by the visual adapter.")
		line_at(c, 746, "32 world units/m; Local .3125. Source remains 96x96 / pivot (48,56) / 32px/m / four-frame .85s walk.")
		var length := 10.0 if camera.zoom.x < 1 else 1.0
		var pixels := length * Space.WORLD_UNITS_PER_METER * camera.zoom.x
		c.draw_line(Vector2(14, 777), Vector2(14 + pixels, 777), Color.WHITE, 2)
		c.draw_string(font, Vector2(24 + pixels, 782), "%.0f m" % length, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
