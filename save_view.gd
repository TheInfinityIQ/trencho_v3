extends Node2D

const Checkpoint = preload("res://checkpoint.gd")
var store = Checkpoint.new(true)
var font := ThemeDB.fallback_font
var last_load := false
var status := "Safe between-battles checkpoint / no live battlefield projections."

func button(text: String, point: Vector2, action: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = Vector2(330, 40)
	item.pressed.connect(action)
	add_child(item)

func _ready() -> void:
	button("EXPLICIT SAVE FILE + LOAD", Vector2(895, 410), roundtrip)
	button("START FRESH BATTLE 2", Vector2(895, 465), start_next)
	button("META UNLOCK / COST 1", Vector2(895, 520), unlock)
	button("TRY UNSUPPORTED VERSION", Vector2(895, 575), invalid_version)

func roundtrip() -> void:
	var text: String = store.serialize()
	last_load = false
	if text.is_empty():
		status = store.reason
		return
	var file := FileAccess.open("res://artifacts/save_renderer_v1.json", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	last_load = store.load_serialized(FileAccess.get_file_as_string("res://artifacts/save_renderer_v1.json"))
	status = "Schema1 file saved, read and atomically loaded. Identity/counts preserved." if last_load else store.reason

func start_next() -> void:
	status = "Fresh Battle 2 created; archived Battle 1 remains metadata only." if store.start_next_battle() else store.reason

func unlock() -> void:
	if store.progression.unlock():
		store.checkpoint = "OUT_OF_CAMPAIGN_META"
		status = "Unlocked tech.mortar once / token0 / campaign ownership unchanged."
	else:
		status = store.progression.reason

func invalid_version() -> void:
	var text := FileAccess.get_file_as_string("res://artifacts/save_renderer_v1.json")
	if text.is_empty():
		status = "NO_SAVED_FILE"
		return
	var payload: Dictionary = JSON.parse_string(text)
	payload.schema_version = 99
	store.load_serialized(JSON.stringify(payload))
	status = store.reason

func _physics_process(delta: float) -> void:
	store.progression.advance(delta)
	if not store.progression.campaign.data.campaign_active and store.checkpoint.is_empty():
		store.checkpoint = "CAMPAIGN_ENDED"
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("dce7df"))

func _draw() -> void:
	var data: Dictionary = store.progression.campaign.data
	var meta: Dictionary = store.progression.meta
	draw_rect(Rect2(24, 105, 830, 635), Color("182b2b"))
	draw_rect(Rect2(875, 105, 380, 635), Color("112025"))
	label_at(Vector2(28, 40), "TRENCHO / SAFE-CHECKPOINT SAVE AND LOAD", 25)
	label_at(Vector2(28, 76), "Schema1 JSON / progression values only / explicit replacement / active-battle saves deferred", 16)
	label_at(Vector2(45, 145), data.campaign_id + " / " + data.status, 22)
	label_at(Vector2(45, 185), "Checkpoint: " + (store.checkpoint if not store.checkpoint.is_empty() else "ACTIVE / cannot save"), 19)
	label_at(Vector2(45, 225), "Battle index %d / persistent people %d" % [data.battle_index, data.person_registry.size()], 18)
	var index := 0
	var person_ids: Array = data.person_registry.keys()
	person_ids.sort()
	for identity in person_ids:
		var person: Dictionary = data.person_registry[identity]
		label_at(Vector2(45, 267 + index * 30), identity + " / " + person.formal_rank + " / " + person.medical_state, 17)
		index += 1
	label_at(Vector2(45, 475), "Acquired: " + ", ".join(store.progression.cards.state.acquired_cards), 17)
	label_at(Vector2(45, 515), "Archive records: %d / no live archived worlds" % data.completed_battles.size(), 18)
	if not data.completed_battles.is_empty():
		var archive: Dictionary = data.completed_battles[0]
		label_at(Vector2(45, 550), "Battle1 %s / frozen terminal T%.2f" % [archive.outcome, archive.terminal_time], 17)
	var world = store.progression.campaign.world
	label_at(Vector2(45, 600), "No live battlefield runtime" if world == null else "Fresh runtime / local T%.2f / %s" % [world.elapsed, world.battle_state], 18)
	label_at(Vector2(45, 640), "Old inventory, bodies, vehicles, jobs and map are never serialized.", 16)
	label_at(Vector2(45, 680), "Reward identity: campaign ID + successful completion event", 16)
	label_at(Vector2(895, 145), "META TOKEN: %d" % meta.currency, 24)
	label_at(Vector2(895, 185), "Rewards %d / Unlocks %d" % [meta.reward_history.size(), meta.unlock_history.size()], 18)
	label_at(Vector2(895, 220), "META UNLOCKED IDS", 17)
	for item in range(meta.unlocked_card_ids.size()):
		label_at(Vector2(895, 251 + item * 25), meta.unlocked_card_ids[item], 15)
	label_at(Vector2(895, 640), "Save revision %d / schema1" % store.revision, 17)
	label_at(Vector2(895, 680), "Last load: " + str(last_load), 17)
	label_at(Vector2(895, 714), "Atomic replacement / never merge", 15)
	label_at(Vector2(28, 779), status, 16)
