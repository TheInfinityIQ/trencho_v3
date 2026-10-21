extends Node2D

const Fixture = preload("res://resume_fixture.gd")
const Store = preload("res://active_checkpoint.gd")
var store = Store.new()
var reference = Fixture.new()
var font := ThemeDB.fallback_font
var running := false
var loaded := false
var destroyed_original := false
var comparison := "NOT RUN"
var status := "Paused at T6.25: all six systems are mid-action. Explicit SAVE, LOAD, then RESUME."
var target_time := 0.0

func _init() -> void:
	reference.step(6.25)
	store.fixture = Fixture.new()
	store.fixture.step(6.25)
	target_time = reference.world.elapsed + 10

func button(text: String, point: Vector2, action: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = Vector2(330, 40)
	item.pressed.connect(action)
	add_child(item)

func _ready() -> void:
	button("SAVE ACTIVE CHECKPOINT", Vector2(895, 430), save)
	button("DESTROY ORIGINAL + LOAD FILE", Vector2(895, 480), restore)
	button("RESUME BOTH BRANCHES", Vector2(895, 530), resume_both)

func save() -> void:
	var text: String = store.serialize()
	if text.is_empty():
		status = store.reason
		return
	var file := FileAccess.open("res://artifacts/active_renderer_v2.json", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	status = "Schema2 checkpoint written: exact clock/timers, logical refs, physical custody and pending actions."

func restore() -> void:
	var text := FileAccess.get_file_as_string("res://artifacts/active_renderer_v2.json")
	if text.is_empty():
		status = "SAVE_FILE_REQUIRED"
		return
	var old_world: WeakRef = weakref(store.fixture.world)
	store.fixture = null
	destroyed_original = old_world.get_ref() == null
	loaded = store.load_serialized(text)
	running = false
	status = "New runtime restored at exact T6.25; all six actions remain unresolved." if loaded else store.reason

func resume_both() -> void:
	if not loaded or comparison != "NOT RUN":
		return
	running = true
	status = "Advancing uninterrupted and reconstructed branches with the same world-time steps."

func _physics_process(_delta: float) -> void:
	if running and store.fixture != null:
		store.fixture.advance(1.0 / 60.0)
		reference.advance(1.0 / 60.0)
		if store.fixture.world.elapsed + 0.000001 >= target_time:
			running = false
			comparison = "PASS" if store.semantic_snapshot(store.fixture) == store.semantic_snapshot(reference) else "FAIL"
			status = "Exact full-state comparison: " + comparison + ". Original transactions settled once."
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16, color := Color("dce7df")) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if store.fixture == null:
		return
	var world = store.fixture.world
	draw_rect(Rect2(24, 105, 830, 635), Color("182b2b"))
	draw_rect(Rect2(875, 105, 380, 635), Color("112025"))
	label_at(Vector2(28, 40), "TRENCHO / ACTIVE CHECKPOINT AND TRANSACTIONAL RESUME", 23)
	label_at(Vector2(28, 77), "Focused fixture only / new runtime, same logical identities, exact world-time/progress and custody", 16)
	label_at(Vector2(45, 142), "WORLD T%.6f / %s" % [world.elapsed, world.battle_state], 23)
	label_at(Vector2(45, 184), "TRUCK " + world.supply.truck.id + " / " + world.supply.truck.route_state, 18)
	label_at(Vector2(45, 213), "Cargo %d / at %s / delivered T%.3f" % [world.supply.truck.inventory.BoltActionRifleAmmo, str(world.supply.truck.position), world.supply.delivered_at], 16)
	label_at(Vector2(45, 258), "REPORT contact-1 / observed T5.500 / 1s hops", 18)
	label_at(Vector2(45, 287), "Known: Squad %d / Platoon %d / Company %d / deliveries %d" % [world.information.contact_knowledge.Squad.size(), world.information.contact_knowledge.Platoon.size(), world.information.contact_knowledge.Company.size(), world.information.contact_deliveries.size()], 16)
	var mission: Dictionary = world.artillery.missions[0]
	label_at(Vector2(45, 332), "SHELL " + mission.shell_id + " / " + mission.state, 17)
	label_at(Vector2(45, 361), "Impact due T%.3f / shells left %d / fired %d / impacts %d" % [mission.impact_at, world.artillery.inventory.MortarShell, world.artillery.fired_count, world.artillery.history.size()], 16)
	label_at(Vector2(45, 406), "MEDICAL " + world.medical.casualty.wound_episode_id, 17)
	label_at(Vector2(45, 435), "%s / progress %.3f of2 / bleed T%.3f / Medkits %d" % [world.medical.casualty.medical_state, world.medical.treatment_progress, world.medical.casualty.bleed_out_at, world.medical.medic.inventory.Medkit], 16)
	var job: Dictionary = world.engineering.jobs[0]
	label_at(Vector2(45, 480), "ENGINEERING " + job.id + " / " + job.state, 18)
	label_at(Vector2(45, 509), "Progress %.3f of5 / reserved %d / consumed %d / stock %d" % [job.progress, world.engineering.reservations.get(job.id, 0), world.engineering.consumed, world.engineering.stockpile.inventory.BuildingMaterial], 16)
	label_at(Vector2(45, 554), "REAR RearProduction-01 / " + ("COMPLETE" if world.rear.job.is_empty() else "WORKING"), 18)
	label_at(Vector2(45, 583), "Metal %d / ammo %d / produced %d / completion T9.500" % [world.rear.metal, world.rear.ammunition, world.rear.produced], 16)
	label_at(Vector2(45, 638), "Ammo total %d / original %d / one wound shot spent / +8 production" % [world.total_ammunition(), store.fixture.initial_ammo], 16)
	label_at(Vector2(45, 682), "Campaign/meta/archive values preserved separately from active world.", 16)
	label_at(Vector2(895, 145), "ACTIVE SCHEMA 2", 22)
	label_at(Vector2(895, 190), "Saved checkpoint T6.250000", 18)
	label_at(Vector2(895, 227), "Loaded: " + str(loaded), 18)
	label_at(Vector2(895, 264), "Old runtime destroyed: " + str(destroyed_original), 16)
	label_at(Vector2(895, 301), "Reference T%.6f" % reference.world.elapsed, 18)
	label_at(Vector2(895, 349), "EQUIVALENCE: " + comparison, 22, Color("a8dfba"))
	label_at(Vector2(895, 391), "No position/time tolerances used.", 16)
	label_at(Vector2(895, 625), "Order: existing Scenario update order", 15)
	label_at(Vector2(895, 658), "Array/event ordering preserved.", 16)
	label_at(Vector2(895, 696), "Exact float bits / stable logical refs", 15)
	label_at(Vector2(28, 779), status, 16, Color("dfcf9e"))
