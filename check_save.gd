extends SceneTree

const Checkpoint = preload("res://checkpoint.gd")
const Meta = preload("res://meta_session.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func step(store, duration: float) -> void:
	for tick in range(int(duration * 60)):
		store.progression.advance(1.0 / 60.0)

func file_roundtrip(path: String, text: String) -> String:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return FileAccess.get_file_as_string(path)

func signature(store) -> String:
	return JSON.stringify({"meta": store.progression.meta, "campaign": store.progression.campaign.data, "checkpoint": store.checkpoint})

func run() -> void:
	var active = Checkpoint.new()
	active.progression = Meta.new()
	active.checkpoint = "CAMPAIGN_ENDED"
	expect(active.serialize().is_empty() and active.reason == "MID_BATTLE_SAVE_DEFERRED", "Active battle rejects even a falsely requested safe checkpoint label")
	var source = Checkpoint.new(true)
	var identity: String = source.progression.campaign.data.campaign_id
	var people: Dictionary = source.progression.campaign.data.person_registry.duplicate(true)
	var archive: Array = source.campaign_values().completed_battles.duplicate(true)
	expect(source.checkpoint == "BETWEEN_BATTLES" and source.progression.campaign.world == null and source.progression.campaign.archived_worlds.is_empty(), "Prepared safe point discards all live Battle1/Battle2 projections")
	var text: String = source.serialize()
	expect(not text.is_empty() and JSON.parse_string(text).schema_version == 1 and source.values_only(source.campaign_values()), "Actual version1 JSON text contains value-only progression")
	expect(not text.contains('"inventory"') and not text.contains('"vehicle_cargo"') and not text.contains('"construction_jobs"') and not text.contains('"rear"') and not text.contains('"structures"') and not text.contains('"people"'), "Payload excludes all live physical inventory/map/job/body/stock/world representations")
	text = file_roundtrip("res://artifacts/save_between_v1.json", text)
	var weak_source: WeakRef = weakref(source)
	source = null
	expect(weak_source.get_ref() == null, "Original runtime session actually discarded before load")
	var restored = Checkpoint.new()
	expect(restored.load_serialized(text) and restored.progression.campaign.world == null and restored.checkpoint == "BETWEEN_BATTLES", "File text reconstructs safe progression without live battle resume")
	expect(restored.progression.campaign.data.campaign_id == identity and restored.progression.meta.active_campaign_id == identity and restored.progression.campaign.data.battle_index == 2, "Exact campaign ID/progression/active-ID survive load")
	expect(restored.progression.campaign.data.person_registry == people and restored.progression.campaign.data.person_registry.size() == 6, "Exact persistent person attributes/history/types and six unique registry IDs survive serialization")
	expect(restored.progression.campaign.data.person_registry["P1-A.1"].medical_state == "DEAD" and restored.progression.campaign.data.person_registry["P1-A.2"].appointment_history.size() == 1, "Dead leader and real past acting history remain historical")
	expect(restored.progression.campaign.data.completed_battles == archive and restored.progression.cards.state.acquired_cards == ["tech.bolt_ammo"] and restored.progression.campaign.data.capabilities.BoltActionAmmoProduction, "Archive metadata and acquired tech/capability persist exactly")
	expect(restored.start_next_battle() and restored.progression.campaign.world.elapsed == 0 and restored.progression.campaign.world.battle_active(), "Loaded between-battles state creates genuinely fresh Battle2 at0")
	var world = restored.progression.campaign.world
	var actual_ids: Array = world.all_people().map(func(person): return person.id)
	expect("P1-A.1" not in actual_ids and actual_ids.count("P1-A.2") == 1 and world.squads[0].formal_leader.id == "P1-B.1", "Fresh projections exclude dead leader and retain one actual actor per survivor ID with explicit Sergeant")
	expect(world.rear.ammunition == 0 and not world.rear.placed and world.rear.job.is_empty() and world.rear.metal == 4 and world.rear.capability_unlocked, "Loaded capability enables future production, no old physical stock/bench/job restored")
	step(restored, 4)
	expect(restored.progression.campaign.data.completed_battles == archive and world.elapsed > 3.99, "Fresh world progresses without changing archived terminal time/result/HQ history")
	expect(restored.serialize().is_empty() and restored.reason == "MID_BATTLE_SAVE_DEFERRED", "Resumed new active battle still rejects serialization")
	step(restored, 8)
	expect(restored.progression.campaign.data.status == "COMPLETED_SUCCESS" and restored.progression.meta.currency == 1, "Loaded identity can finish real final Battle2 and settle exactly one token")
	var completed_text: String = file_roundtrip("res://artifacts/save_completed_v1.json", restored.serialize())
	var completed_id: String = restored.progression.campaign.data.campaign_id
	var complete_registry: Dictionary = restored.progression.campaign.data.person_registry.duplicate(true)
	var before_reward: Array = restored.progression.meta.reward_history.duplicate(true)
	restored = null
	var completed = Checkpoint.new()
	expect(completed.load_serialized(completed_text) and completed.progression.campaign.world == null and completed.progression.campaign.data.status == "COMPLETED_SUCCESS" and completed.progression.meta.currency == 1, "Completed save loads token1/completed status with no world to revive")
	for repeat in range(3):
		completed.progression.process_result()
		completed.progression.advance(100)
	expect(completed.progression.meta.currency == 1 and completed.progression.meta.reward_history == before_reward and completed.progression.campaign.data.person_registry == complete_registry, "Postload repeated settlement/ticks cannot award token2 or mutate people")
	expect(completed.progression.unlock() and completed.progression.meta.currency == 0 and completed.progression.meta.unlock_history.size() == 1, "Loaded once-settled token can be spent on one unlock")
	completed.checkpoint = "OUT_OF_CAMPAIGN_META"
	var unlocked_text: String = file_roundtrip("res://artifacts/save_unlocked_v1.json", completed.serialize())
	expect(completed.load_serialized(unlocked_text) and completed.checkpoint == "OUT_OF_CAMPAIGN_META" and completed.progression.meta.currency == 0 and "tech.mortar" in completed.progression.meta.unlocked_card_ids and completed.progression.meta.unlock_history.size() == 1, "Afterunlock JSON roundtrip retains token0/mortar unlocked once")
	var stable := signature(completed)
	expect(not completed.progression.unlock() and completed.progression.reason == "NO_ELIGIBLE_META_UNLOCKS" and signature(completed) == stable, "Postload unlock cannot refund/spend/duplicate settlement")
	var previous = completed.progression
	expect(completed.load_serialized(unlocked_text) and completed.progression != previous and signature(completed) == stable, "Successful reload atomically replaces session rather than merging histories/cards/people")
	for repeat in range(3):
		completed.load_serialized(unlocked_text)
	expect(signature(completed) == stable and completed.progression.meta.reward_history.size() == 1 and completed.progression.meta.unlock_history.size() == 1, "Repeated same-file loads preserve exact counts/currency without duplicates")
	var invalid: Dictionary = JSON.parse_string(unlocked_text)
	invalid.schema_version = 99
	previous = completed.progression
	expect(not completed.load_serialized(JSON.stringify(invalid)) and completed.reason == "UNSUPPORTED_SAVE_VERSION" and completed.progression == previous and signature(completed) == stable, "Unsupported version rejects with no partial replacement/mutation")
	expect(not completed.load_serialized("{broken") and completed.reason == "MALFORMED_SAVE" and completed.progression == previous and signature(completed) == stable, "Malformed serialized bytes reject without session mutation")
	expect(not completed.load_serialized('{"schema_version":1}') and completed.reason == "MISSING_SAVE_FIELDS" and completed.progression == previous and signature(completed) == stable, "Missing top-level fields reject atomically")
	invalid = JSON.parse_string(unlocked_text)
	invalid.campaign = []
	expect(not completed.load_serialized(JSON.stringify(invalid)) and completed.reason == "INVALID_SAVE_STRUCTURE" and signature(completed) == stable, "Invalid campaign structure rejects without partial load")
	invalid = JSON.parse_string(unlocked_text)
	invalid.meta.currency = {"$value": "UnknownRuntime", "text": "Object"}
	expect(not completed.load_serialized(JSON.stringify(invalid)) and completed.reason == "INVALID_SAVE_VALUE" and signature(completed) == stable, "Unknown serialized value tag rejected, never loads an Object/resource")
	expect(completed.progression.start_campaign() and completed.progression.campaign.data.campaign_id != completed_id and completed.progression.meta.next_campaign == 3 and "tech.mortar" in completed.progression.cards.unlocked_pool(), "New campaign after load preserves meta and uses next distinct saved identity counter")
	var consumed = Checkpoint.new()
	consumed.progression = Meta.new()
	consumed.progression.cards.fixture_unlocked.erase("cons.ammo_emergency_shipment")
	consumed.progression.cards.fixture_unlocked.push_front("cons.ammo_emergency_shipment")
	consumed.progression.cards.purchase(1)
	consumed.progression.cards.select_card(consumed.progression.cards.open_drop().id, "cons.ammo_emergency_shipment")
	consumed.progression.cards.use_consumable("cons.ammo_emergency_shipment", consumed.progression.campaign.world.rear, 0)
	step(consumed, 12)
	var consumed_text: String = consumed.serialize()
	var consumed_loaded = Checkpoint.new()
	expect(consumed_loaded.load_serialized(consumed_text) and consumed_loaded.progression.cards.held_consumables().is_empty() and consumed_loaded.progression.cards.state.resolutions.size() == 1 and consumed_loaded.progression.cards.state.consumables["cons.ammo_emergency_shipment"].state == "CONSUMED", "Consumed history serializes without physical grant stock or a reusable instance")
	var held = Checkpoint.new()
	held.progression = Meta.new()
	held.progression.cards.fixture_unlocked.erase("cons.ammo_emergency_shipment")
	held.progression.cards.fixture_unlocked.push_front("cons.ammo_emergency_shipment")
	held.progression.cards.purchase(1)
	held.progression.cards.select_card(held.progression.cards.open_drop().id, "cons.ammo_emergency_shipment")
	step(held, 12)
	stable = signature(held)
	expect(held.serialize().is_empty() and held.reason == "UNSPENT_CONSUMABLE_PERSISTENCE_DEFERRED" and signature(held) == stable, "Even safe-ended state with HELD consumable rejects without silently discarding/using it")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/save_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "campaign_id": identity, "person_ids": people.keys(), "archive": archive, "reward_events": before_reward, "loaded_meta": completed.progression.meta}, "\t"))
	output.close()
	print("SAVE CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	var released := InputEventMouseButton.new()
	released.position = point
	released.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(released)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/save_" + name + ".png")

func visual_run() -> void:
	var view = load("res://save_proof.tscn").instantiate()
	expect(view.get_script() != null, "Save graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	root.add_child(view)
	await capture("01_between_before_save")
	click(Vector2(1060, 430))
	await process_frame
	await capture("02_loaded_same_identity_no_runtime")
	expect(view.last_load and view.store.progression.campaign.world == null and view.store.progression.campaign.data.campaign_id == "MetaCampaign-1", "Actual write/read/load button restores same safe identity, no battle runtime")
	click(Vector2(1060, 485))
	await process_frame
	await capture("03_fresh_battle2_after_load")
	expect(view.store.progression.campaign.world != null and view.store.progression.campaign.world.elapsed < 0.2, "Actual startnextbutton creates fresh world at local0")
	while view.store.progression.campaign.data.campaign_active and view.store.progression.campaign.world.elapsed < 12:
		await create_timer(0.1).timeout
	await capture("04_completed_token_one")
	click(Vector2(1060, 430))
	await process_frame
	await capture("05_loaded_completed_token_still_one")
	expect(view.last_load and view.store.progression.meta.currency == 1 and view.store.progression.meta.reward_history.size() == 1 and view.store.progression.campaign.world == null, "Actual completed save/load retains exactly1token and no resumed world")
	click(Vector2(1060, 540))
	await process_frame
	click(Vector2(1060, 430))
	await process_frame
	await capture("06_unlocked_loaded_once_token_zero")
	expect(view.store.progression.meta.currency == 0 and view.store.progression.meta.unlock_history.size() == 1 and "tech.mortar" in view.store.progression.meta.unlocked_card_ids, "Actual unlock/save/load retains one unlock and zero currency")
	click(Vector2(1060, 595))
	await process_frame
	await capture("07_unsupported_version_rejected")
	expect(view.store.reason == "UNSUPPORTED_SAVE_VERSION" and view.store.progression.meta.currency == 0 and view.store.progression.meta.unlock_history.size() == 1, "Actual invalid-version control rejects without state mutation")
