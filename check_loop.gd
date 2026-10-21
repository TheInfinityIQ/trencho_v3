extends SceneTree

const Loop = preload("res://campaign_loop.gd")
const Scenario = preload("res://scenario.gd")
var checks := 0
var failures: Array[String] = []
var evidence: Array = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func work(session, batches: int) -> void:
	var world = session.operations.world
	world.rear.place_workbench(Vector2(380, 480))
	world.rear.assign_worker(batches, world.elapsed)
	world.rear.set_policy("AVAILABLE")

func until_terminal(session, limit := 240.0) -> void:
	while session.phase == "ACTIVE" and session.operations.world.elapsed < limit:
		session.advance(1.0 / 60.0)

func run() -> void:
	if "--panel-review" in OS.get_cmdline_user_args():
		await panel_review()
		quit()
		return
	var session = Loop.new()
	var campaign = session.progression.campaign
	var first = session.operations.world
	expect(first.elapsed == 0 and first.rear.ammunition == 0 and first.rear.produced == 0 and not first.rear.placed and first.rear.policy == "LOCKED", "Player campaign starts at true time0 without proof labor, stock or policy autoplay")
	expect(campaign.data.card_progression.acquired_cards == ["tech.bolt_ammo"] and campaign.data.capabilities.BoltActionAmmoProduction and first.rear.capability_unlocked, "Existing card ownership grants only production capability")
	expect(not session.continue_campaign(), "No active battle skip via Continue")
	work(session, 1)
	until_terminal(session)
	evidence.append({"battle": 1, "time": first.elapsed, "outcome": first.battle_state, "roster": session.roster_text()})
	expect(session.phase == "INTERMISSION" and first.battle_state == "ENDED_FRIENDLY_VICTORY" and first.battle.hqs["Enemy-HQ"].integrity == 0 and first.rear.produced == 8 and first.supply.delivered_at >= 0 and first.secured, "B1 real shortage, production, physical delivery and autonomous objective lead to real HQ victory/intermission")
	var frozen: String = JSON.stringify(campaign.archive_snapshot(first), "", true, true)
	for tick in range(600):
		session.advance(1.0 / 60.0)
	expect(campaign.world == first and campaign.data.battle_index == 1 and JSON.stringify(campaign.archive_snapshot(first), "", true, true) == frozen and session.progression.meta.currency == 0, "Intermission remains frozen indefinitely with no transition/reward")
	var saved: String = session.intermission_checkpoint()
	expect(not saved.is_empty(), "Real B1 intermission creates existing SAV021 safe checkpoint")
	print("B1 roster: ", session.roster_text(), " checkpoint: ", session.reason)
	if not session.continue_campaign():
		expect(false, "Existing Campaign transition succeeds: " + session.reason)
		finish()
		return
	var second = session.operations.world
	expect(second != first and campaign.data.battle_index == 2 and second.elapsed == 0 and campaign.archived_worlds[0] == first, "Only explicit Continue uses accepted Campaign transition to fresh B2 world at time0")
	expect(second.rear.ammunition == 0 and second.rear.produced == 0 and second.rear.metal == 4 and not second.rear.placed and second.rear.job.is_empty() and second.rear.production_order.is_empty() and second.rear.committed == 0 and second.combat.shots.is_empty() and second.artillery.missions.is_empty() and second.information.contact_knowledge.Company.is_empty() and session.operations.alerts.entries.is_empty(), "B2 receives fresh finite stock/work/orders/commitments/shots/missions/delivered contact knowledge/alerts")
	var identities := true
	for identity in campaign.NEXT_SQUAD + ["P1-PL"]:
		var person = campaign.find_person(second, identity)
		var previous: Dictionary = campaign.data.person_registry[identity]
		identities = identities and person != null and person.formal_rank == previous.formal_rank and person.squad_command_qualified == previous.squad_command_qualified and person.acting_appointment.is_empty() and person.personal_history.size() == previous.personal_history.size() + 1
	expect(identities, "Persistent IDs, formal rank, qualification and history survive with fresh active appointments")
	expect(second.battle.hqs.values().all(func(hq): return hq.integrity == 2 and hq.state == "INTACT") and second.battle.history.is_empty() and second.battle.terminal_time == -1 and second.engineering.jobs.is_empty() and second.engineering.structures.is_empty() and second.artillery.inventory.MortarShell == 2, "B2 HQ damage/history, construction jobs/structures and finite artillery stock are fresh")
	expect(second.squads.all(func(squad): return squad.suppression == 0 and squad.morale == 100 and squad.morale_log.is_empty()) and second.all_people().all(func(person): return not person.body_present and person.medical_state == "FIT" and person.detected.is_empty()), "No B1 bodies, wounds, suppression, morale episodes or local detections carry into B2")
	var dead_excluded := true
	for record in campaign.data.person_registry.values():
		if record.medical_state == "DEAD":
			dead_excluded = dead_excluded and campaign.find_person(second, record.id) == null
	expect(dead_excluded, "No dead B1 registered person re-enters B2")
	var archive_text: String = session.archive_text()
	expect(archive_text.contains("BATTLE 1") and archive_text.contains("B1 survivors:") and archive_text.contains("B1 dead:"), "B1 outcome, terminal time and survivor/dead IDs remain readable during B2")
	var restored = Loop.new()
	expect(restored.phase == "ACTIVE" and not restored.load_intermission(saved), "Safe reload cannot replace active battle")
	restored.phase = "INTERMISSION"
	expect(restored.load_intermission(saved) and restored.progression.campaign.world == null and restored.phase == "INTERMISSION", "Safe reload restores progression without advancing/creating next battle")
	expect(restored.continue_campaign() and restored.operations.world.elapsed == 0 and restored.operations.world.rear.requests.size() == 2 and restored.operations.world.rear.produced == 0, "Reloaded intermission needs explicit Continue and builds fresh priority/context B2")
	if restored.progression.campaign.world != null:
		expect(restored.roster_text() == session.roster_text(), "Restored and direct paths retain identical selected roster identity/rank/history")
	while second.rear.requests.any(func(item): return item.requested == 0) and second.elapsed < 12:
		session.advance(1.0 / 60.0)
	expect(session.operations.set_priority("Request-B"), "Player may prioritize SUPPORT in B2 through existing logistics action")
	work(session, 2)
	var conserved := true
	var split := false
	while session.phase == "ACTIVE" and second.elapsed < 240:
		session.advance(1.0 / 60.0)
		conserved = conserved and second.total_ammunition() + second.combat.shots.size() == session.operations.initial_ammo + second.rear.produced
		split = split or (second.rear.requests[1].delivered == 8 and second.rear.requests[0].delivered == 0)
	evidence.append({"battle": 2, "time": second.elapsed, "outcome": second.battle_state, "requests": second.rear.requests.duplicate(true), "conserved": conserved, "priority_delivered_first": split, "history": campaign.data.organizational_history.duplicate(true)})
	expect(conserved and split and second.rear.requests.all(func(item): return item.delivered == 8), "B2 chosen request receives scarce stock first; both actual deliveries conserve ammunition")
	expect(session.phase == "FINAL" and second.battle_state == "ENDED_FRIENDLY_VICTORY" and second.battle.hqs["Enemy-HQ"].integrity == 0 and second.secured, "B2 autonomous physical consequence reaches actual HQ victory")
	expect(campaign.data.status == "COMPLETED_SUCCESS" and session.progression.meta.currency == 1 and session.progression.meta.reward_history.size() == 1, "Existing Meta settlement awards exactly1 token for successful two-battle completion")
	for tick in range(30):
		session.advance(1)
		session.progression.process_result()
	expect(session.progression.meta.currency == 1 and session.progression.meta.reward_history.size() == 1 and not session.continue_campaign(), "Repeated result/UI processing cannot duplicate reward or create B3")
	expect(JSON.stringify(campaign.archive_snapshot(first), "", true, true) == frozen and JSON.stringify(campaign.data.completed_battles[0], "", true, true) == frozen, "B1 runtime/archive terminal time, HQ state/history and people remain frozen throughout B2")
	expect(session.enter_meta() and session.phase == "OUT_META" and session.progression.meta.currency == 1, "Explicit META action enters OUT_META without automatic spending")
	var capabilities: Dictionary = campaign.data.capabilities.duplicate(true)
	expect(session.progression.unlock() and session.progression.meta.currency == 0 and "tech.mortar" in session.progression.meta.unlocked_card_ids and campaign.data.capabilities == capabilities and not session.progression.unlock(), "Existing optional Meta purchase spends1 only on future eligibility, with no campaign capability/assets or duplicate purchase")
	for battle_index in [1, 2]:
		var defeat = Loop.new()
		if battle_index == 2:
			work(defeat, 1)
			until_terminal(defeat)
			defeat.continue_campaign()
		defeat.operations.world.battle.auto_strike = true
		defeat.operations.world.battle.target_hq_id = "Friendly-HQ"
		until_terminal(defeat)
		expect(defeat.phase == "FINAL" and defeat.progression.campaign.data.status == "ENDED_DEFEAT" and defeat.progression.campaign.data.end_reason == "DEFEAT_REWARD_POLICY_DEFERRED" and defeat.progression.meta.currency == 0 and not defeat.continue_campaign(), "Actual FriendlyHQ defeat in B%d stops progression with deferred defeat reward and no success token" % battle_index)
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	finish()

func finish() -> void:
	var output := FileAccess.open("res://artifacts/loop_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "evidence": evidence}, "\t", true, true))
	output.close()
	print("LOOP CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func visual_run() -> void:
	var view = load("res://campaign_loop.tscn").instantiate()
	root.add_child(view)
	await process_frame
	await capture("01_battle1_active_shortage")
	expect(view.session.phase == "ACTIVE" and view.session.progression.campaign.data.battle_index == 1 and not view.overlay.visible, "Single player entry opens real B1 Operations")
	await create_timer(7).timeout
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	key(KEY_F)
	key(KEY_1)
	while view.session.phase == "ACTIVE" and view.session.operations.world.elapsed < 100:
		await create_timer(0.1).timeout
	await capture("02_battle1_actual_hq_victory")
	expect(view.session.phase == "INTERMISSION" and view.heading.text.contains("BATTLE 1 VICTORY") and view.continue_button.visible and view.details.text.contains("dead 1"), "Actual B1 victory presents frozen explicit intermission with real casualty and persistent roster")
	var terminal_time: float = view.session.operations.world.elapsed
	await create_timer(1).timeout
	await capture("03_intermission_no_automatic_continue")
	expect(view.session.operations.world.elapsed == terminal_time and view.session.progression.campaign.data.battle_index == 1 and view.session.progression.meta.currency == 0, "Visible intermission remains frozen without automatic continue/reward")
	click(Vector2(570, 620))
	await process_frame
	click(Vector2(900, 620))
	await process_frame
	await capture("04_safe_checkpoint_reloaded_continue_required")
	expect(view.notice.contains("reloaded") and view.session.phase == "INTERMISSION" and view.session.progression.campaign.world == null, "Normal Save/Reload intermission controls restore safe values and still require Continue")
	view.set_physics_process(false)
	click(Vector2(240, 620))
	await process_frame
	expect(view.session.phase == "ACTIVE" and view.session.operations.world.elapsed == 0 and view.session.progression.campaign.data.battle_index == 2, "Actual Continue button builds B2 at exact local time0 before first tick")
	await capture("05_explicit_continue_battle2_time0")
	key(KEY_V)
	await process_frame
	await capture("06_persistent_ids_and_battle1_archive")
	expect(view.details.text.contains("B1 dead: P2-B.4") and view.details.text.contains("P1-A.2 / CORPORAL") and view.details.text.contains("BATTLE 1"), "Normal roster panel shows persistent identity/rank and archived B1 result/dead IDs in B2")
	key(KEY_V)
	view.set_physics_process(true)
	await create_timer(7).timeout
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	click(Vector2(150, 345))
	await process_frame
	key(KEY_F)
	while view.session.operations.world.rear.produced < 8 and view.session.operations.world.elapsed < 20:
		await create_timer(0.1).timeout
	key(KEY_C)
	await process_frame
	await capture("07_battle2_request_competition_support_priority")
	expect(view.battle_view.context_panel.visible and view.battle_view.context_headers[0].text.contains("MAIN EFFORT") and view.battle_view.context_headers[1].text.contains("SUPPORT") and view.session.operations.world.rear.requests[1].priority == "PRIORITY" and view.session.operations.world.rear.committed == 0, "Normal B2 controls expose command context and player SUPPORT priority while LOCKED stock remains physical")
	key(KEY_C)
	key(KEY_1)
	key(KEY_TAB)
	while view.session.operations.world.rear.requests[1].delivered < 8 and view.session.operations.world.elapsed < 60:
		await create_timer(0.1).timeout
	var support_position: Vector2 = view.session.operations.world.squads[1].center()
	await create_timer(2).timeout
	await capture("08_physical_support_delivery_autonomous_consequence")
	expect(view.session.operations.world.rear.requests[0].delivered == 0 and view.session.operations.world.rear.requests[1].delivered == 8 and view.session.operations.world.squads[1].center().distance_to(support_position) > 20, "Chosen SUPPORT physically supplied and moves autonomously while MAIN EFFORT remains short")
	key(KEY_TAB)
	await process_frame
	key(KEY_F)
	key(KEY_TAB)
	while view.session.phase == "ACTIVE" and view.session.operations.world.elapsed < 160:
		await create_timer(0.1).timeout
	await capture("09_battle2_hq_victory_campaign_complete")
	expect(view.heading.text.contains("CAMPAIGN COMPLETE") and view.heading.text.contains("WON 2") and view.details.text.contains("Earned 1 MetaToken / current balance 1") and view.session.operations.world.battle.hqs["Enemy-HQ"].integrity == 0, "Actual second physical HQ victory shows completed two-battle campaign and exactly1 earned/current token")
	click(Vector2(240, 620))
	await process_frame
	await capture("10_explicit_out_meta_unspent_token")
	expect(view.heading.text.contains("OUT_META") and view.session.progression.meta.currency == 1 and view.unlock_button.visible, "Actual META click enters shop without automatic spending")
	click(Vector2(330, 620))
	await process_frame
	await capture("11_optional_meta_unlock_eligibility_only")
	expect(view.session.progression.meta.currency == 0 and "tech.mortar" in view.session.progression.meta.unlocked_card_ids and not view.session.progression.campaign.data.capabilities.get("MortarSupport", false) and view.unlock_button.disabled, "Actual Meta purchase changes eligibility only and disables duplicate purchase")
	view.queue_free()
	await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
	Input.parse_input_event(release)

func panel_review() -> void:
	var session = Loop.new()
	work(session, 1)
	until_terminal(session)
	session.continue_campaign()
	work(session, 2)
	until_terminal(session)
	var view = load("res://campaign_loop.tscn").instantiate()
	view.session = session
	root.add_child(view)
	await process_frame
	await capture("12_final_roster_latest_history_review")
	view.session.enter_meta()
	view.refresh()
	await capture("13_meta_final_text_review")
	view.queue_free()
	await process_frame

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventMouseButton.new()
	release.position = point
	release.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(release)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/loop_" + name + ".png")
