extends SceneTree

const Session = preload("res://card_session.gd")
const Cards = preload("res://card_progression.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func step(session, duration: float) -> void:
	var remaining := duration
	while remaining > 0.000001:
		var delta := minf(remaining, 1.0 / 60.0)
		session.advance(delta)
		remaining -= delta

func physical(session) -> String:
	return JSON.stringify(session.campaign.archive_snapshot(session.campaign.world, 2))

func values_only(value) -> bool:
	if value is Object:
		return false
	if value is Dictionary:
		return value.values().all(values_only)
	if value is Array:
		return value.all(values_only)
	return true

func run() -> void:
	var session = Session.new()
	var world = session.campaign.world
	var cards = session.cards
	var definitions: Dictionary = cards.definitions()
	var pool_before := JSON.stringify(cards.unlocked_pool())
	var defs_before := JSON.stringify(definitions)
	expect(world.elapsed == 0 and session.campaign.data.battle_index == 2 and world.battle_active(), "Primary proof starts at genuine separate Battle2 time0")
	expect(definitions.size() == 4 and definitions.keys().all(func(identity): return definitions[identity].id == identity and definitions[identity].has_all(["tier", "category", "type", "capability"])), "Four stable card IDs with tier/category/type/capability metadata")
	expect(cards.unlocked_pool().size() == 4 and cards.state.acquired_cards.is_empty() and not world.rear.capability_unlocked, "Fixture pool availability is not ownership or capability")
	expect(cards.state.currency.DropToken == 1 and cards.state.drops.is_empty(), "One campaign token and no offer initially")
	var pool_copy: Array = cards.unlocked_pool()
	pool_copy.clear()
	definitions["tech.bolt_ammo"].tier = 5
	expect(cards.unlocked_pool().size() == 4 and cards.definitions()["tech.bolt_ammo"].tier == 1, "External pool/definition copies cannot mutate fixture definitions")
	var before := physical(session)
	expect(not session.select_card("tier1-drop-1", "tech.bolt_ammo") and cards.reason == "UNKNOWN_DROP" and physical(session) == before, "Cannot acquire a card without an actual offered drop")
	expect(world.rear.place_workbench(Vector2(380, 480)) and world.rear.metal == 4, "Otherwise valid production fixture has workbench, Metal and nearby labor")
	before = physical(session)
	expect(not world.rear.start_job("Avatar", 0) and world.rear.message == "MISSING_CAPABILITY: BoltActionAmmoProduction", "Pre-card production explicitly rejects missing capability")
	expect(physical(session) == before and world.rear.job.is_empty() and world.rear.ammunition == 0, "Rejected job consumes no input or time/output")
	step(session, 1)
	expect(world.rear.produced == 0 and world.rear.ammunition == 0, "Elapsed time with bench/Metal creates no ammo while capability missing")
	before = physical(session)
	expect(session.purchase() and cards.state.currency.DropToken == 0 and cards.state.drops.size() == 1, "Purchase consumes exactly one token and creates one drop")
	var offer: Dictionary = cards.open_drop()
	expect(offer.candidates.size() == 3 and offer.candidates.all(func(identity): return cards.DEFINITIONS[identity].tier == 1) and "tech.mortar" not in offer.candidates, "Three distinct Tier1 candidates never include Tier2 mortar")
	expect(offer.candidates == ["tech.bolt_ammo", "tech.engineering", "tech.medical"], "Deterministic fixture offer uses stable IDs, not display text")
	expect(cards.state.acquired_cards.is_empty() and not world.rear.capability_unlocked and not session.campaign.data.capabilities.BoltActionAmmoProduction, "Offer generation grants no card or capability")
	expect(physical(session) == before, "Purchase/offer generates no physical resources, jobs, structures or custody changes")
	var state_before := JSON.stringify(cards.state)
	expect(not session.purchase() and cards.reason == "INSUFFICIENT_DROP_TOKENS" and JSON.stringify(cards.state) == state_before, "Zero currency purchase rejects without new candidates/acquisition or state mutation")
	expect(not session.select_card(offer.id, "tech.mortar") and cards.reason == "CARD_NOT_OFFERED" and JSON.stringify(cards.state) == state_before, "Unlisted Tier2 card cannot be selected")
	var detached_offer: Dictionary = cards.open_drop()
	detached_offer.candidates.append("tech.mortar")
	expect("tech.mortar" not in cards.open_drop().candidates, "Offer diagnostic copy cannot inject a candidate")
	before = physical(session)
	expect(session.select_card(offer.id, "tech.bolt_ammo"), "Explicit player selection acquires offered ammo technology")
	expect(cards.state.acquired_cards == ["tech.bolt_ammo"] and "tech.engineering" not in cards.state.acquired_cards and "tech.medical" not in cards.state.acquired_cards, "Exactly selected card owned; unselected candidates remain unowned")
	expect(cards.open_drop().is_empty() and cards.state.drops[0].state == "SELECTED" and cards.state.drops[0].selected_card == "tech.bolt_ammo", "Selection closes same drop with historical chosen ID")
	expect(session.campaign.data.capabilities.BoltActionAmmoProduction and world.rear.capability_unlocked, "Immediate acquisition activates and binds campaign ammo capability")
	expect(physical(session) == before and world.rear.ammunition == 0 and world.rear.metal == 4 and world.rear.job.is_empty(), "Activation changes no physical stock/workbench/Metal/job and creates no retroactive output")
	expect(cards.state.history.map(func(event): return event.event) == ["drop purchased", "card acquired", "capability activated"], "Purchase, acquisition and activation remain distinct recorded events")
	state_before = JSON.stringify(cards.state)
	expect(not session.select_card(offer.id, "tech.medical") and cards.reason == "DROP_CLOSED" and JSON.stringify(cards.state) == state_before, "Closed drop cannot grant second card")
	expect(not session.select_card(offer.id, "tech.bolt_ammo") and JSON.stringify(cards.state) == state_before, "Same choice cannot be duplicated or capability stacked")
	expect(cards.eligible(1) == ["tech.engineering", "tech.medical"] and "tech.bolt_ammo" not in cards.eligible(1), "Already acquired technology excluded from subsequent eligible candidates")
	# Explicit detached test funding, not recurring income or a shipping reward.
	var later_data: Dictionary = session.campaign.data.duplicate(true)
	later_data.card_progression.currency.DropToken = 1
	var later = Cards.new(later_data)
	var later_before := JSON.stringify(later_data)
	expect(not later.purchase() and later.reason == "INSUFFICIENT_ELIGIBLE_CARDS" and JSON.stringify(later_data) == later_before, "Too few unowned Tier1 cards rejects without spending instead of filling with duplicates/wrong tiers")
	expect(world.rear.start_job("Avatar", world.elapsed) and world.rear.metal == 3 and world.rear.ammunition == 0 and not world.rear.job.is_empty(), "A new explicit post-card action starts actual labor and consumes one Metal")
	step(session, 3.99)
	expect(world.rear.ammunition == 0 and world.rear.production_history.is_empty(), "Full production duration still required after activation")
	step(session, 0.01)
	expect(world.rear.ammunition == 8 and world.rear.produced == 8 and world.rear.metal == 3 and world.rear.job.is_empty(), "Exactly four seconds transforms Metal1 into8physical ammo")
	expect(world.rear.production_history.size() == 1 and world.rear.production_history[0].producer == "Avatar" and world.rear.production_history[0].metal_consumed == 1 and world.rear.production_history[0].completed_at - world.rear.production_history[0].started_at == 4, "Input/labor/duration/output accounted by actual rear production history")
	before = physical(session)
	var source_data := JSON.stringify(session.campaign.data)
	session.build_reconstruction_probe()
	expect(session.probe_data.campaign_id == session.campaign.data.campaign_id and session.probe_data.battle_index == 3 and session.campaign.data.battle_index == 2, "Detached next-battle reconstruction retains campaign identity, does not transition active authoritative Battle2")
	expect(session.probe_cards.state.acquired_cards == ["tech.bolt_ammo"] and session.probe_data.capabilities.BoltActionAmmoProduction and session.probe_world.rear.capability_unlocked, "Acquired card and technology persist into separate fresh-battle runtime from detached campaign values")
	expect(session.probe_world != world and session.probe_world.elapsed == 0 and session.probe_world.rear.ammunition == 0 and session.probe_world.rear.produced == 0 and session.probe_world.rear.metal == 4 and not session.probe_world.rear.placed and session.probe_world.rear.job.is_empty(), "Technology persists while actual Battle2 rounds/bench/input/jobs do not become next-battle resources")
	expect(session.probe_cards.state.currency.DropToken == 0 and session.probe_cards.state.drops[0].selected_card == "tech.bolt_ammo" and "tech.bolt_ammo" not in session.probe_cards.eligible(1), "Reconstruction preserves spend/drop/choice/duplicate exclusion without granting new token")
	expect(physical(session) == before and JSON.stringify(session.campaign.data) == source_data, "Constructing later runtime cannot mutate source battle or campaign")
	session.probe_cards.state.history.append({"event": "detachment test only"})
	session.probe_world.rear.metal = 0
	expect(JSON.stringify(session.campaign.data) == source_data and physical(session) == before, "Probe data/runtime mutation cannot alias authoritative campaign or Battle2 stock")
	expect(values_only(session.campaign.data) and values_only(session.probe_data), "Campaign and reconstruction data contain values only, never simulation objects")
	expect(JSON.stringify(cards.unlocked_pool()) == pool_before and JSON.stringify(cards.definitions()) == defs_before, "Selection and reconstruction never mutate fixture/meta availability or definitions")
	var poor_data := {"capabilities": {}}
	var poor = Cards.new(poor_data)
	poor.state.currency.DropToken = 0
	var poor_before := JSON.stringify(poor_data)
	expect(not poor.purchase() and poor.reason == "INSUFFICIENT_DROP_TOKENS" and JSON.stringify(poor_data) == poor_before and poor.open_drop().is_empty(), "Zero-token initial state has no generated candidates or grants")
	var blank_data := {"capabilities": {}}
	var blank = Cards.new(blank_data)
	blank.purchase()
	blank.select_card(blank.open_drop().id, "tech.bolt_ammo")
	var clean_world = session.Scenario.new(true, true, true, true)
	clean_world.rear.capability_unlocked = blank_data.capabilities.BoltActionAmmoProduction
	expect(not clean_world.rear.placed and clean_world.rear.metal == 4 and clean_world.rear.ammunition == 0 and clean_world.rear.job.is_empty(), "Acquisition with no bench creates neither workstation nor Metal/ammo/job")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/cards_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "campaign_cards": cards.state, "capabilities": session.campaign.data.capabilities, "production": world.rear.production_history, "probe_cards": session.probe_cards.state, "definitions": cards.definitions()}, "\t"))
	output.close()
	print("CARDS CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func click(point: Vector2) -> void:
	var pressed := InputEventMouseButton.new()
	pressed.position = point
	pressed.button_index = MOUSE_BUTTON_LEFT
	pressed.pressed = true
	Input.parse_input_event(pressed)
	var released := InputEventMouseButton.new()
	released.position = point
	released.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(released)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/cards_" + name + ".png")

func visual_run() -> void:
	var view = load("res://card_proof.tscn").instantiate()
	expect(view.get_script() != null, "Card proof graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	root.add_child(view)
	await capture("01_battle2_before_capability")
	click(Vector2(1050, 393))
	await process_frame
	click(Vector2(1050, 438))
	await process_frame
	await capture("02_missing_capability_with_inputs")
	expect(view.session.campaign.world.rear.message.begins_with("MISSING_CAPABILITY") and view.session.campaign.world.rear.job.is_empty(), "Actual manual button with otherwise valid inputs reports missing capability")
	click(Vector2(200, 336))
	await process_frame
	await capture("03_tier1_drop_three_choices")
	expect(view.session.cards.state.currency.DropToken == 0 and view.session.cards.open_drop().candidates.size() == 3 and view.session.cards.state.acquired_cards.is_empty(), "Actual purchase button spends token and offers three unowned Tier1 cards")
	click(Vector2(360, 430))
	await process_frame
	await capture("04_acquired_active_no_free_stock")
	expect(view.session.cards.state.acquired_cards == ["tech.bolt_ammo"] and view.session.campaign.world.rear.capability_unlocked and view.session.campaign.world.rear.ammunition == 0 and view.session.campaign.world.rear.job.is_empty(), "Actual explicit first card selection activates technology with no stock or automatic job")
	click(Vector2(1050, 438))
	await create_timer(1).timeout
	await capture("05_actual_production_labor")
	expect(view.session.campaign.world.rear.metal == 3 and view.session.campaign.world.rear.ammunition == 0 and not view.session.campaign.world.rear.job.is_empty(), "Actual post-card button consumes input and starts timed physical labor")
	await create_timer(3.2).timeout
	await capture("06_eight_physical_rounds")
	expect(view.session.campaign.world.rear.ammunition == 8 and view.session.campaign.world.rear.produced == 8, "Renderer actual production completes eight rounds after four worldseconds")
	click(Vector2(1050, 673))
	await process_frame
	await capture("07_detached_next_battle_technology_no_stock")
	expect(view.showing_probe and view.session.probe_data.battle_index == 3 and view.session.probe_world.rear.capability_unlocked and view.session.probe_world.rear.ammunition == 0 and not view.session.probe_world.rear.placed and view.session.probe_cards.state.acquired_cards == ["tech.bolt_ammo"], "Renderer detached next-battle probe preserves acquired technology and resets physical resources")
