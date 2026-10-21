extends SceneTree

const Session = preload("res://card_session.gd")
const CONSUMABLE := "cons.ammo_emergency_shipment"
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

func military(world) -> String:
	return JSON.stringify({"people": world.all_people().map(func(person): return {"id": person.id, "inventory": person.inventory.duplicate(true)}),
		"truck": world.vehicles.truck.inventory, "tracked": world.vehicles.tracked.inventory,
		"shipment": world.rear.shipment, "commitment": world.rear.committed, "supply": world.supply.depot.inventory})

func run() -> void:
	var session = Session.new(true)
	var world = session.campaign.world
	var rear = world.rear
	var cards = session.cards
	rear.metal = 0
	var pool_before := JSON.stringify(cards.unlocked_pool())
	var definitions_before := JSON.stringify(cards.definitions())
	var schema: Dictionary = cards.definitions()[CONSUMABLE]
	expect(cards.unlocked_pool().size() == 5 and schema.id == CONSUMABLE and schema.tier == 1 and schema.category == "Logistics" and schema.type == "CONSUMABLE" and schema.capability == "" and schema.effect == {"type": "RESOURCE_GRANT", "resource": "BoltActionRifleAmmo", "quantity": 8}, "Explicit consumable schema with stable ID, tier/category/type and fixed resource payload")
	expect(cards.state.acquired_cards.is_empty() and cards.held_consumables().is_empty() and cards.state.resolutions.is_empty() and rear.ammunition == 0, "Fixture pool presence is neither ownership nor held state nor resolution nor ammo")
	var before := JSON.stringify(cards.state)
	expect(not session.use_consumable("unknown") and cards.reason == "UNKNOWN_CARD" and JSON.stringify(cards.state) == before, "Unknown use rejects without mutation")
	expect(not session.use_consumable(CONSUMABLE) and cards.reason == "CONSUMABLE_NOT_ACQUIRED" and JSON.stringify(cards.state) == before and rear.ammunition == 0, "Unacquired consumable use rejects without grant")
	expect(not session.use_consumable("tech.bolt_ammo") and cards.reason == "WRONG_CARD_TYPE" and JSON.stringify(cards.state) == before, "Technology cannot be used as a consumable")
	expect(session.purchase() and cards.state.currency.DropToken == 0, "Existing Tier1 drop machinery consumes one token")
	var offer: Dictionary = cards.open_drop()
	expect(offer.candidates == [CONSUMABLE, "tech.bolt_ammo", "tech.engineering"] and offer.candidates.all(func(identity): return cards.DEFINITIONS[identity].tier == 1) and "tech.mortar" not in offer.candidates, "Focused deterministic three-choice Tier1 drop includes consumable and excludes Tier2")
	expect(cards.held_consumables().is_empty() and cards.state.acquired_cards.is_empty() and rear.ammunition == 0, "Offer alone grants neither held instance nor ammo")
	var military_before := military(world)
	expect(session.select_card(offer.id, CONSUMABLE) and cards.state.acquired_cards == [CONSUMABLE] and cards.open_drop().is_empty(), "Explicit consumable selection acquires one card and closes drop normally")
	var held: Dictionary = cards.state.consumables[CONSUMABLE]
	expect(cards.held_consumables() == [CONSUMABLE] and held.state == "HELD" and held.acquired and not held.consumed and not held.grant_delivered, "Acquired, consumed and physical delivered diagnostics are separate")
	expect(rear.ammunition == 0 and not rear.capability_unlocked and not session.campaign.data.capabilities.BoltActionAmmoProduction and cards.state.resolutions.is_empty(), "Selection creates no ammo or technology activation/resolution")
	step(session, 1)
	expect(cards.held_consumables() == [CONSUMABLE] and rear.ammunition == 0 and cards.state.resolutions.is_empty(), "Holding through world time never automatically resolves consumable")
	before = JSON.stringify(session.campaign.data)
	expect(not session.build_reconstruction_probe() and session.probe_reason == "UNSPENT_CONSUMABLE_PERSISTENCE_DEFERRED" and session.probe_data.is_empty() and JSON.stringify(session.campaign.data) == before, "Unspent cross-battle policy explicitly deferred without silently copying or consuming")
	var valid_effect: Dictionary = held.effect.duplicate(true)
	held.effect.quantity = -1
	before = JSON.stringify(cards.state)
	expect(not session.use_consumable(CONSUMABLE) and cards.reason == "INVALID_EFFECT_PAYLOAD" and JSON.stringify(cards.state) == before and rear.ammunition == 0, "Invalid effect payload rejects with held state/input/stock unchanged")
	held.effect = valid_effect
	military_before = military(world)
	expect(rear.metal == 0 and not rear.placed and rear.job.is_empty() and not rear.worker.assigned and rear.production_history.is_empty(), "Grant fixture has no Metal/workbench/labor/job/capability")
	var use_time: float = world.elapsed
	expect(session.use_consumable(CONSUMABLE) and rear.ammunition == 8, "First explicit valid use grants exactly eight ordinary physical rear rounds")
	expect(world.elapsed == use_time and rear.metal == 0 and not rear.placed and rear.job.is_empty() and not rear.worker.assigned and rear.produced == 0 and rear.production_history.is_empty(), "Windfall consumes no input/labor/production time/workstation and never masquerades as manufacturing")
	expect(not rear.capability_unlocked and not session.campaign.data.capabilities.BoltActionAmmoProduction, "Consumable acquisition/use never unlocks ammo technology")
	expect(rear.policy == "LOCKED" and rear.eligible() == 0 and military(world) == military_before and rear.committed == 0 and rear.shipment.cargo == 0, "LOCKED policy remains unchanged; grant cannot teleport into military commitment/shipment/truck/person/depot")
	expect(held.state == "CONSUMED" and held.consumed and held.grant_delivered and cards.held_consumables().is_empty() and cards.state.acquired_cards == [CONSUMABLE], "Usable instance gone after use, acquisition and consumption history retained")
	expect(cards.state.resolutions.size() == 1 and cards.state.resolutions[0].quantity == 8 and cards.state.resolutions[0].ownership == "rear" and cards.state.history.filter(func(event): return event.event == "consumable resolved").size() == 1, "Campaign records one exact resolution event and retained acquisition history")
	expect(rear.ledger.size() == 1 and rear.ledger[0].source == "campaign-consumable:" + CONSUMABLE and rear.ledger[0].instance == held.instance_id and rear.ledger[0].destination == "rear-finished-stock" and rear.ledger[0].ownership_after == "rear" and rear.consumable_receipts.size() == 1, "Physical ledger and receipt identify unique campaign card provenance/normal rear destination")
	before = JSON.stringify(cards.state)
	var ledger_before := JSON.stringify(rear.ledger)
	expect(not session.use_consumable(CONSUMABLE) and cards.reason == "CONSUMABLE_ALREADY_SPENT" and rear.ammunition == 8 and JSON.stringify(cards.state) == before and JSON.stringify(rear.ledger) == ledger_before, "Second use creates zero stock and no duplicate campaign/physical history")
	expect(not rear.receive_consumable_grant(held.instance_id, CONSUMABLE, 8, use_time) and rear.ammunition == 8 and JSON.stringify(rear.ledger) == ledger_before, "Rear unique receipt also guards duplicate physical grant")
	expect(not rear.start_job("Avatar", world.elapsed) and rear.message.begins_with("MISSING_CAPABILITY"), "Manufacturing remains technology-gated after consumable use")
	expect(not rear.commit(8, world.elapsed) and rear.committed == 0, "Ordinary commitment cannot bypass LOCKED authorization")
	step(session, 1)
	expect(rear.ammunition == 8 and rear.committed == 0 and rear.shipment.state == "None", "Locked card stock remains rear-owned over actual world ticks")
	rear.set_policy("RESERVE", 8)
	expect(rear.eligible() == 0 and not rear.commit(8, world.elapsed), "Existing reserve floor also protects card-granted normal stock")
	rear.set_policy("AVAILABLE")
	expect(rear.eligible() == 8 and rear.commit(8, world.elapsed) and rear.committed == 8 and rear.ammunition == 8 and rear.shipment.state == "None", "Eligible policy allows ordinary commitment, still subset of rear physical onhand")
	step(session, 1.99)
	expect(rear.ammunition == 8 and rear.shipment.cargo == 0 and rear.committed == 8, "Card stock still requires physical loading delay")
	step(session, 0.01)
	expect(rear.ammunition == 0 and rear.committed == 0 and rear.shipment.cargo == 8 and rear.shipment.owner == "military" and rear.shipment.state == "Inter-map transit", "Normal export moves granted rounds physically into military transit only at actual departure")
	expect(rear.ledger.back().source == "rear-finished-stock" and rear.ledger.back().ownership_before == "rear" and rear.ledger.back().ownership_after == "military", "Export retains normal stock ownership-transfer provenance separate from original card grant")
	step(session, 3)
	expect(rear.shipment.cargo == 0 and rear.shipment.state == "Arrived at battlefield receiving point" and world.supply.depot.inventory.BoltActionRifleAmmo == 8, "Existing transit/receiving path accepts granted stock identically to manufactured stock")
	expect(CONSUMABLE not in cards.eligible(1) and CONSUMABLE in cards.unlocked_pool(), "Spent campaign-owned card excluded from reoffers while fixture availability remains intact")
	var later_data: Dictionary = session.campaign.data.duplicate(true)
	later_data.card_progression.currency.DropToken = 1
	var later = session.Cards.new(later_data, true)
	expect(later.purchase() and CONSUMABLE not in later.open_drop().candidates and later.open_drop().candidates == ["tech.bolt_ammo", "tech.engineering", "tech.medical"], "Detached test-funded later offer excludes consumed card, still three distinct Tier1 options")
	expect(session.build_reconstruction_probe() and session.probe_cards.state.consumables[CONSUMABLE].state == "CONSUMED" and session.probe_cards.held_consumables().is_empty() and session.probe_world.rear.ammunition == 0 and session.probe_world.rear.consumable_receipts.is_empty(), "Consumed historical record persists in detached next-battle probe without reusable card or old physical stock/receipt")
	expect(not session.probe_cards.use_consumable(CONSUMABLE, session.probe_world.rear, 0) and session.probe_world.rear.ammunition == 0, "Consumed card cannot be redeemed in reconstructed later battle")
	expect(JSON.stringify(cards.unlocked_pool()) == pool_before and JSON.stringify(cards.definitions()) == definitions_before, "Acquisition/consumption/export never mutates unlocked/meta fixture definitions")
	var active = Session.new(true)
	active.purchase()
	active.select_card(active.cards.open_drop().id, CONSUMABLE)
	active.campaign.data.capabilities.BoltActionAmmoProduction = true
	active.campaign.bind_capabilities(active.campaign.world)
	active.campaign.world.rear.place_workbench(Vector2(380, 480))
	active.campaign.world.rear.start_job("Avatar", 0)
	var job_before := JSON.stringify(active.campaign.world.rear.job)
	var metal_before: int = active.campaign.world.rear.metal
	expect(active.use_consumable(CONSUMABLE) and active.campaign.world.rear.ammunition == 8 and active.campaign.world.rear.metal == metal_before and JSON.stringify(active.campaign.world.rear.job) == job_before, "Grant while technology/job active neither consumes Metal nor changes timed manufacturing job")
	step(active, 4)
	expect(active.campaign.world.rear.ammunition == 16 and active.campaign.world.rear.produced == 8 and active.campaign.world.rear.production_history.size() == 1 and active.cards.state.resolutions.size() == 1, "Grant8 and manufactured8 retain distinguishable provenance, no production substitution")
	for policy in ["AVAILABLE", "RESERVE"]:
		var policy_fixture = Session.new(true)
		policy_fixture.purchase()
		policy_fixture.select_card(policy_fixture.cards.open_drop().id, CONSUMABLE)
		policy_fixture.campaign.world.rear.set_policy(policy, 5)
		policy_fixture.use_consumable(CONSUMABLE)
		expect(policy_fixture.campaign.world.rear.policy == policy and policy_fixture.campaign.world.rear.reserve == 5 and policy_fixture.campaign.world.rear.committed == 0, "Use preserves existing " + policy + " authorization/floor and does not itself commit")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/consumable_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "cards": cards.state, "rear_ledger": rear.ledger, "capabilities": session.campaign.data.capabilities, "production_distinction": active.campaign.world.rear.production_history}, "\t"))
	output.close()
	print("CONSUMABLE CHECKS: ", checks, " failures: ", failures)
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
	root.get_texture().get_image().save_png("res://artifacts/consumable_" + name + ".png")

func visual_run() -> void:
	var view = load("res://consumable_proof.tscn").instantiate()
	expect(view.get_script() != null, "Consumable renderer scene loads")
	if view.get_script() == null:
		view.free()
		return
	root.add_child(view)
	await process_frame
	click(Vector2(200, 336))
	await process_frame
	await capture("01_tier1_offer")
	expect(CONSUMABLE in view.session.cards.open_drop().candidates and view.session.cards.state.acquired_cards.is_empty(), "Actual purchase offers consumable without acquiring it")
	click(Vector2(350, 430))
	await process_frame
	await capture("02_acquired_held_no_ammo")
	expect(view.session.cards.held_consumables() == [CONSUMABLE] and view.session.campaign.world.rear.ammunition == 0 and not view.session.campaign.world.rear.capability_unlocked, "Actual selection creates held card, no ammo/capability")
	click(Vector2(350, 555))
	await process_frame
	await capture("03_explicit_use_eight_rear_locked")
	expect(view.session.campaign.world.rear.ammunition == 8 and view.session.campaign.world.rear.policy == "LOCKED" and view.session.campaign.world.rear.eligible() == 0 and view.session.cards.held_consumables().is_empty(), "Actual explicit use delivers8rear-owned locked rounds without capability or usable instance")
	click(Vector2(350, 555))
	await process_frame
	await capture("04_repeat_use_rejected")
	expect(view.status == "CONSUMABLE_ALREADY_SPENT" and view.session.campaign.world.rear.ammunition == 8 and view.session.cards.state.resolutions.size() == 1, "Actual repeat use rejects, stock/history unchanged")
	click(Vector2(1050, 438))
	await process_frame
	await capture("05_manufacturing_still_missing_capability")
	expect(view.status.begins_with("MISSING_CAPABILITY") and view.session.campaign.world.rear.metal == 0 and view.session.campaign.world.rear.job.is_empty() and view.session.campaign.world.rear.produced == 0, "Manufacturing still rejects technology absence after windfall")
	click(Vector2(1050, 673))
	await process_frame
	await capture("06_spent_history_no_later_stock")
	expect(view.showing_probe and view.session.probe_world.rear.ammunition == 0 and view.session.probe_cards.held_consumables().is_empty() and view.session.probe_cards.state.resolutions.size() == 1, "Renderer detached later battle retains spent history but no redeemable card or stock")
