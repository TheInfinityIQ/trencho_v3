extends SceneTree

const Session = preload("res://meta_session.gd")
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
	var campaign = session.campaign
	var before := JSON.stringify(session.meta)
	var campaign_before := JSON.stringify(session.snapshot_current())
	expect(values_only(session.meta) and session.meta.currency == 0 and session.meta.unlocked_card_ids == session.INITIAL_UNLOCKED and session.meta.active_campaign_id == campaign.data.campaign_id, "Meta is separate value-only currency/unlock/history/active-ID state")
	expect(not campaign.data.has("meta") and campaign.data.status == "ACTIVE" and campaign.data.battle_index == 2 and campaign.data.completed_battles.size() == 1 and campaign.world.elapsed == 0, "Actual accepted Battle1 transition reaches distinct active final Battle2, no meta embedded in campaign")
	expect("tech.mortar" not in session.cards.unlocked_pool() and session.cards.state.acquired_cards.is_empty() and not campaign.data.capabilities.get("MortarSupport", false), "Initially locked mortar unavailable and unowned/inactive")
	expect(not session.unlock() and session.reason == "ACTIVE_CAMPAIGN_MUST_END" and JSON.stringify(session.meta) == before and JSON.stringify(session.snapshot_current()) == campaign_before, "Active campaign blocks meta unlock without currency/pool/world mutation")
	expect(not session.start_campaign() and session.reason == "ACTIVE_CAMPAIGN_MUST_END" and JSON.stringify(session.meta) == before, "Cannot replace active campaign with new run")
	expect(not session.finish("COMPLETED_SUCCESS", "forged") and session.reason == "FINAL_VICTORY_REQUIRED" and JSON.stringify(session.meta) == before, "Success reward cannot be called before actual final victory")
	expect(not session.finish("ENDED_DEFEAT", "forged") and session.reason == "ACTUAL_DEFEAT_REQUIRED", "Defeat result also requires actual defeat")
	step(session, 3.1)
	expect(campaign.world.battle.hqs["Enemy-HQ"].state == "DAMAGED" and session.meta.currency == 0 and campaign.data.status == "ACTIVE", "First actual HQ hit does not complete campaign or award meta currency")
	step(session, 10)
	expect(campaign.world.battle_state == "ENDED_FRIENDLY_VICTORY" and campaign.data.status == "COMPLETED_SUCCESS" and not campaign.data.campaign_active and campaign.data.battle_index == 2, "Second real HQ hit completes successful two-battle campaign with no extra battle")
	expect(session.meta.currency == 1 and session.meta.reward_history.size() == 1 and session.meta.reward_history[0].quantity == 1 and session.meta.reward_history[0].campaign == campaign.data.campaign_id, "Completion grants one Meta Token exactly once with source campaign")
	expect(session.meta.campaign_results.size() == 1 and session.meta.campaign_results[0].status == "COMPLETED_SUCCESS" and session.meta.campaign_results[0].final_battle == 2 and session.shop_accessible() and session.meta.active_campaign_id == "", "Ended campaign clears active-shop block and records exact outcome/reward")
	before = JSON.stringify(session.meta)
	campaign_before = JSON.stringify(session.snapshot_current())
	var old_world = campaign.world
	var old_elapsed: float = old_world.elapsed
	for repeat in range(4):
		session.process_result()
		session.finish("COMPLETED_SUCCESS", "duplicate")
	step(session, 20)
	expect(JSON.stringify(session.meta) == before and session.meta.currency == 1 and old_world.elapsed == old_elapsed and JSON.stringify(session.snapshot_current()) == campaign_before, "Repeated completion processing/ticks never duplicate reward or mutate ended campaign/world")
	expect(not session.abandon() and session.reason == "CAMPAIGN_ALREADY_ENDED" and JSON.stringify(session.meta) == before, "Stale abandonment cannot erase successful completion/reward")
	expect(session.unlock() and session.meta.currency == 0 and "tech.mortar" in session.meta.unlocked_card_ids and session.meta.unlock_history.size() == 1, "Out-of-campaign unlock spends1token and expands pool with sole locked mortar")
	expect(session.meta.unlock_history[0].card == "tech.mortar" and session.meta.unlock_history[0].cost == 1 and session.meta.unlocked_card_ids.count("tech.mortar") == 1, "Unlock transaction records canonical card/cost with no duplicate ID")
	expect(JSON.stringify(session.snapshot_current()) == campaign_before and session.meta.active_campaign_id == "" and campaign.data.status == "COMPLETED_SUCCESS", "Meta unlock creates no campaign, ownership, capability, shells/stock/assets or old archive mutation")
	before = JSON.stringify(session.meta)
	expect(not session.unlock() and session.reason == "NO_ELIGIBLE_META_UNLOCKS" and JSON.stringify(session.meta) == before, "Exhausted pool rejects without currency/history/duplicate mutation")
	# Explicit isolated test balance, not another reward or recurring income.
	session.meta.currency = 1
	before = JSON.stringify(session.meta)
	expect(not session.unlock() and session.reason == "NO_ELIGIBLE_META_UNLOCKS" and session.meta.currency == 1 and JSON.stringify(session.meta) == before, "Even funded exhausted pool never spends or duplicates unlock")
	session.meta.currency = 0
	expect(session.start_campaign() and session.campaign != campaign and session.archived_campaigns[0] == campaign and session.campaign.data.campaign_id != campaign.data.campaign_id and session.campaign.data.battle_index == 1, "New campaign uses distinct identity/runtime and retains old campaign independently")
	expect("tech.mortar" in session.cards.unlocked_pool() and session.cards.state.acquired_cards.is_empty() and not session.campaign.data.capabilities.get("MortarSupport", false), "New campaign snapshots meta eligibility, not ownership or activated MortarSupport")
	expect(session.meta.unlocked_card_ids.size() == 5 and session.meta.currency == 0 and session.meta.unlock_history.size() == 1, "Starting new campaign preserves meta unlock/currency/history outside campaign lifecycle")
	var source: Dictionary = session.snapshot_current()
	var source_world: Dictionary = source.world.duplicate(true)
	var source_shells: Dictionary = source.artillery_inventory.duplicate(true)
	expect(session.purchase_future_tier2() and session.cards.state.currency.DropToken == 0 and session.cards.open_drop().tier == 2 and session.cards.open_drop().candidates == ["tech.mortar"], "PA-META-006 new campaign fixture token funds one same-tier offer containing newly unlocked mortar")
	expect(session.cards.state.acquired_cards.is_empty() and not session.campaign.data.capabilities.get("MortarSupport", false) and session.snapshot_current().world == source_world and session.campaign.world.artillery.inventory == source_shells, "Tier2 offering still creates no acquisition/capability/physical output")
	expect(campaign.data.status == "COMPLETED_SUCCESS" and JSON.stringify({"data": campaign.data, "world": campaign.archive_snapshot(campaign.world, 2), "artillery_inventory": campaign.world.artillery.inventory, "artillery_missions": campaign.world.artillery.missions, "card_receipts": campaign.world.rear.consumable_receipts}) == campaign_before, "New campaign/card offer cannot mutate ended campaign or archived Battle1/physical Battle2")
	session.cards.fixture_unlocked.erase("tech.mortar")
	expect("tech.mortar" in session.meta.unlocked_card_ids, "Campaign availability copy does not alias persistent meta pool")
	var abandoned = Session.new()
	abandoned.campaign.world.battle.auto_strike = false
	expect(abandoned.abandon() and abandoned.campaign.data.status == "ABANDONED" and not abandoned.campaign.data.campaign_active and abandoned.meta.currency == 0 and abandoned.meta.reward_history.is_empty() and abandoned.shop_accessible(), "Explicit active campaign abandonment ends it with no completion reward and shop access")
	before = JSON.stringify(abandoned.meta)
	var abandoned_world := JSON.stringify(abandoned.snapshot_current())
	expect(not abandoned.unlock() and abandoned.reason == "INSUFFICIENT_META_CURRENCY" and JSON.stringify(abandoned.meta) == before, "Zero-token ended campaign cannot unlock or mutate pool")
	step(abandoned, 20)
	abandoned.abandon()
	expect(JSON.stringify(abandoned.meta) == before and JSON.stringify(abandoned.snapshot_current()) == abandoned_world, "Repeated abandonment/ticks create no reward or old-world mutation")
	var defeat = Session.new(true)
	step(defeat, 12)
	expect(defeat.campaign.world.battle_state == "ENDED_FRIENDLY_DEFEAT" and defeat.campaign.data.status == "ENDED_DEFEAT" and not defeat.campaign.data.campaign_active and defeat.meta.currency == 0 and defeat.meta.reward_history.is_empty() and defeat.shop_accessible(), "Actual final defeat ends campaign/shop block with0proofreward")
	expect(defeat.campaign.data.end_reason == "DEFEAT_REWARD_POLICY_DEFERRED" and defeat.meta.campaign_results[0].reason == "DEFEAT_REWARD_POLICY_DEFERRED" and defeat.meta.campaign_results[0].reward == 0, "PA-META-004 provisional defeat reward explicitly marked deferred")
	expect(not defeat.campaign.transition() and defeat.campaign.transition_reason == "CAMPAIGN_DEFEAT_POLICY_DEFERRED" and defeat.campaign.data.battle_index == 2, "Defeated campaign cannot continue under existing CAM017 rule")
	before = JSON.stringify(defeat.meta)
	defeat.process_result()
	defeat.advance(100)
	expect(JSON.stringify(defeat.meta) == before, "Defeat reprocessing grants no reward or duplicate result")
	var race = Session.new()
	# Actual terminal world before session result handling: abandon must settle
	# existing success instead of converting a completed campaign to a zero reward.
	for tick in range(700):
		race.campaign.advance(1.0 / 60.0)
		if not race.campaign.world.battle_active():
			break
	expect(not race.abandon() and race.campaign.data.status == "COMPLETED_SUCCESS" and race.meta.currency == 1 and race.meta.reward_history.size() == 1, "Terminal victory wins stale abandon ordering without duplicate reward")
	expect(values_only(session.meta) and values_only(session.campaign.data) and values_only(defeat.meta), "Meta and campaign histories remain detached value-only state after lifecycle/unlocks")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/meta_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "meta": session.meta, "completed_campaign": campaign.data, "new_campaign": session.campaign.data, "abandonment": abandoned.meta, "defeat": defeat.meta}, "\t"))
	output.close()
	print("META CHECKS: ", checks, " failures: ", failures)
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
	root.get_texture().get_image().save_png("res://artifacts/meta_" + name + ".png")

func visual_run() -> void:
	var view = load("res://meta_proof.tscn").instantiate()
	expect(view.get_script() != null, "Meta graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	root.add_child(view)
	await process_frame
	click(Vector2(1050, 440))
	await process_frame
	await capture("01_active_campaign_shop_blocked")
	expect(view.status == "ACTIVE_CAMPAIGN_MUST_END" and view.session.meta.currency == 0, "Actual unlock button rejects active campaign")
	while view.session.campaign.data.campaign_active and view.session.campaign.world.elapsed < 12:
		await create_timer(0.1).timeout
	await capture("02_final_victory_completion_reward_once")
	expect(view.session.campaign.data.status == "COMPLETED_SUCCESS" and view.session.meta.currency == 1 and view.session.meta.reward_history.size() == 1 and view.session.shop_accessible(), "Rendered real final victory ends campaign with exactly1token and shopaccess")
	var old_snapshot := JSON.stringify(view.session.snapshot_current())
	click(Vector2(1050, 440))
	await process_frame
	await capture("03_meta_mortar_unlocked_no_campaign_grant")
	expect(view.session.meta.currency == 0 and "tech.mortar" in view.session.meta.unlocked_card_ids and view.session.meta.unlock_history.size() == 1 and JSON.stringify(view.session.snapshot_current()) == old_snapshot, "Actual unlock button spends token and adds only meta eligibility, leaving old campaign/physicalworld untouched")
	click(Vector2(1050, 580))
	await process_frame
	await capture("04_new_campaign_unlocked_but_unacquired")
	expect(view.session.campaign.data.status == "ACTIVE" and view.session.archived_campaigns.size() == 1 and "tech.mortar" in view.session.cards.unlocked_pool() and view.session.cards.state.acquired_cards.is_empty() and not view.session.campaign.data.capabilities.get("MortarSupport", false), "Actual newcampaign button creates independent run with eligibility but no acquired MortarSupport")
	click(Vector2(350, 685))
	await process_frame
	await capture("05_tier2_offer_not_acquisition")
	expect(view.session.cards.open_drop().tier == 2 and view.session.cards.open_drop().candidates == ["tech.mortar"] and view.session.cards.state.acquired_cards.is_empty() and not view.session.campaign.data.capabilities.get("MortarSupport", false), "Actual Tier2 proof offer includes unlocked mortar and grants no card/capability")
