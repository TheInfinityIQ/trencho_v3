extends SceneTree

const Campaign = preload("res://campaign.gd")
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

func has_runtime_object(value) -> bool:
	if value is Object:
		return true
	if value is Dictionary:
		for item in value.values():
			if has_runtime_object(item):
				return true
	if value is Array:
		for item in value:
			if has_runtime_object(item):
				return true
	return false

func key(code: Key) -> void:
	var pressed := InputEventKey.new()
	pressed.keycode = code
	pressed.pressed = true
	Input.parse_input_event(pressed)
	var released := InputEventKey.new()
	released.keycode = code
	Input.parse_input_event(released)

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

func run() -> void:
	var session = Campaign.new()
	var data_before := JSON.stringify(session.data)
	expect(not has_runtime_object(session.data) and session.data.campaign_active and session.data.battle_index == 1 and session.data.person_registry.size() == 6, "Campaign data is a separate value-only registry/history/capability container, no battle objects")
	expect(not session.transition() and session.transition_reason == "ACTIVE_BATTLE_CANNOT_TRANSITION" and JSON.stringify(session.data) == data_before, "Active battle rejects transition without campaign mutation")
	step(session, 40)
	var old = session.world
	var corporal = session.find_person(old, "P1-A.2")
	var old_leader = session.find_person(old, "P1-A.1")
	expect(old.battle_state == "ENDED_FRIENDLY_VICTORY" and old_leader.medical_state == "DEAD" and old_leader.body_present, "Battle1 reaches real HQ victory after actual commander casualty, retaining corpse")
	expect(corporal.acting_appointment == "SquadLeader:P1-A" and corporal.formal_rank == "CORPORAL" and corporal.appointment_history.size() == 1, "Battle1 actual acting Corporal has historical appointment without promotion")
	expect(old.squads[0].morale == 60 and old.squads[0].suppression > 0 and old.engineering.structures.size() == 1 and old.rear.placed and not old.rear.job.is_empty(), "Archived source has real casualty morale/suppression, structure, bench and pending production to discriminate resets")
	var frozen := JSON.stringify(session.archive_snapshot(old))
	var old_corp_inventory: Dictionary = corporal.inventory.duplicate(true)
	expect(session.transition(), "Explicit terminal victory action transitions to new battle")
	var fresh = session.world
	expect(fresh != old and fresh.elapsed == 0 and session.data.battle_index == 2 and fresh.battle_state == "ACTIVE" and session.archived_worlds[0] == old, "Battle2 is separate world at local0; old frozen runtime remains separately archived")
	expect(not has_runtime_object(session.data) and session.data.completed_battles.size() == 1 and JSON.stringify(session.archive_snapshot(old)) == frozen, "Archive metadata contains no simulation objects and transition cannot mutate old world")
	var identities: Dictionary = {}
	var unique := true
	for person in fresh.all_people():
		unique = unique and not identities.has(person.id)
		identities[person.id] = true
	expect(unique and not identities.has("P1-A.1") and session.data.person_registry["P1-A.1"].medical_state == "DEAD", "Every active Battle2 person ID is unique; dead original leader is historical, never instantiated alive")
	var retained := true
	for identity in session.NEXT_SQUAD + ["P1-PL"]:
		var before_person = session.find_person(old, identity)
		var next_person = session.find_person(fresh, identity)
		var record: Dictionary = session.data.person_registry[identity]
		retained = retained and next_person != null and next_person != before_person and next_person.id == before_person.id
		for field in ["formal_rank", "normal_role", "squad_command_qualified", "engineer_qualified", "medic_qualified", "rifle_proficiency"]:
			retained = retained and next_person.get(field) == record[field] and next_person.get(field) == before_person.get(field)
		retained = retained and next_person.permanent_history == record.permanent_history and next_person.medical_state == "FIT"
	expect(retained, "Same survivor IDs, formal rank/role/qualifications/proficiency/history rehydrate into independent live runtime actors")
	var next_corp = session.find_person(fresh, "P1-A.2")
	expect(next_corp.acting_appointment.is_empty() and next_corp.appointment_history.size() == 1 and next_corp.appointment_history[0].battle == 1 and next_corp.formal_rank == "CORPORAL", "Past acting command remains history, not active appointment or promotion in Battle2")
	expect(fresh.squads[0].formal_leader.id == "P1-B.1" and fresh.squads[0].current_leader().id == "P1-B.1" and fresh.squads[0].command_available(), "Explicit surviving Sergeant formal assignment supplies actual new-battle command authority")
	expect(fresh.squads.all(func(squad): return squad.morale == 100 and squad.suppression == 0 and squad.routing_state == "NONE") and fresh.squads[0].morale_log.is_empty(), "Battle-local morale/suppression/tactical logs reset to100/0/none")
	expect(fresh.battle.hqs.values().all(func(hq): return hq.integrity == 2 and hq.state == "INTACT") and fresh.battle.history.is_empty() and fresh.vehicles.infrastructure_history.is_empty(), "Battle2 HQ/infrastructure state and history are genuinely fresh")
	expect(fresh.engineering.structures.is_empty() and fresh.engineering.jobs.is_empty() and fresh.engineering.reservations.is_empty() and fresh.vehicles.truck != old.vehicles.truck and fresh.vehicles.truck.inventory.BoltActionRifleAmmo == 0, "No old structures/jobs/material reservations/truck/cargo carry across")
	expect(fresh.information.knowledge.HQ.is_empty() and fresh.information.leader_relays.is_empty() and fresh.combat.history.is_empty() and fresh.medical.history.is_empty(), "New world gets empty knowledge/report/combat/medical containers")
	expect(not fresh.rear.placed and fresh.rear.workbench == Vector2.ZERO and fresh.rear.ammunition == 0 and fresh.rear.metal == 4 and fresh.rear.job.is_empty() and not fresh.rear.worker.assigned and fresh.rear.committed == 0 and fresh.rear.shipment.state == "None", "Fresh proof rear layout/Metal4/ammo0/jobs/worker/commitments/shipments do not inherit Battle1 values")
	expect(next_corp.inventory.BoltActionRifleAmmo == 6 and old_corp_inventory.BoltActionRifleAmmo != 6 and fresh.supply.carried() == 8 and fresh.supply.depot.inventory.BoltActionRifleAmmo == 0, "Fresh explicit0/6/1/1carried loadout replaces old person ammo; no old custody stock leaks")
	expect(session.data.capabilities.BoltActionAmmoProduction and fresh.rear.capability_unlocked and not fresh.rear.start_job("Avatar", 0) and fresh.rear.ammunition == 0, "Capability persists but creates no ammunition/job without actual workstation")
	var campaign_history: Dictionary = session.data.organizational_history[0]
	var history_before := JSON.stringify(campaign_history)
	var archive_before := JSON.stringify(session.data.completed_battles[0])
	expect(campaign_history.dead_person_ids == ["P1-A.1"] and campaign_history.surviving_person_ids.size() == 5 and campaign_history.terminal_hq_event.hq == "Enemy-HQ" and campaign_history.notable_local_events[0].leadership.any(func(event): return event.get("acting", "") == "P1-A.2"), "Organizational history retains result, exact survivors/dead, terminal HQ and real acting event")
	var start: Vector2 = next_corp.position
	step(session, 10)
	expect(fresh.elapsed > 9.99 and next_corp.position.distance_to(start) > 50 and fresh.squads[0].command_available() and fresh.battle_state == "ACTIVE", "Persistent people move/command normally through at least10fresh worldseconds")
	expect(fresh.rear.ammunition == 0 and fresh.rear.produced == 0 and fresh.rear.job.is_empty(), "Persistent capability alone creates no physical stock through10seconds")
	expect(fresh.information.knowledge.HQ[0].soldier_id.begins_with("B2-") and fresh.information.knowledge.HQ[0].observer.begins_with("B2-"), "Fresh local report provenance refers to fresh Battle2 people, not old IDs")
	var empty_actors: Array = []
	var empty_solids: Array[Rect2] = []
	fresh.artillery.blast(fresh.vehicles.infrastructure["Bridge-A"].position, fresh.elapsed, empty_actors, empty_solids, fresh.combat)
	fresh.supply.transfer(next_corp.id, next_corp.inventory, fresh.squads[0].formal_leader.id, fresh.squads[0].formal_leader.inventory, 1, "Battle2 local custody probe")
	expect(JSON.stringify(session.archive_snapshot(old)) == frozen and JSON.stringify(session.data.completed_battles[0]) == archive_before and JSON.stringify(campaign_history) == history_before, "Battle2 physical damage/custody mutation cannot change old world, old archive or Battle1 history")
	expect(fresh.rear.place_workbench(Vector2(380, 480)), "Battle2 must physically place its own new workbench")
	fresh.rear.metal = 0
	expect(not fresh.rear.start_job("Avatar", fresh.elapsed), "Persisted capability plus bench cannot produce without Metal")
	fresh.rear.metal = 4
	expect(fresh.rear.start_job("Avatar", fresh.elapsed) and fresh.rear.metal == 3 and fresh.rear.ammunition == 0, "Actual Battle2 input starts labor without immediate physical output")
	step(session, 3.99)
	expect(fresh.rear.ammunition == 0, "New battle production still requires full4worldseconds")
	step(session, 0.01)
	expect(fresh.rear.ammunition == 8 and fresh.rear.produced == 8 and fresh.rear.metal == 3, "Actual Battle2 labor transforms its own Metal1into8physical rounds")
	old.advance(100)
	expect(JSON.stringify(session.archive_snapshot(old)) == frozen and JSON.stringify(campaign_history) == history_before, "New battle advancement/production and attempted old ticks preserve immutable archived Battle1")
	var defeat = Campaign.new()
	defeat.world.battle.auto_strike = true
	defeat.world.battle.target_hq_id = "Friendly-HQ"
	step(defeat, 20)
	expect(defeat.world.battle_state == "ENDED_FRIENDLY_DEFEAT" and not defeat.transition() and defeat.transition_reason == "CAMPAIGN_DEFEAT_POLICY_DEFERRED" and defeat.data.battle_index == 1 and defeat.data.completed_battles.is_empty(), "PA-CAM-008 rejects genuine terminal defeat without inventing defeat continuation or rewards")
	var injured = Campaign.new()
	step(injured, 15)
	var casualty = injured.find_person(injured.world, "P1-A.2")
	injured.world.medical.wound_target_ids[casualty.id] = true
	var shooter = injured.world.combat.defenders.soldiers[1]
	shooter.position = casualty.position + Vector2(0, -100)
	injured.world.combat.detect(shooter, [casualty])
	injured.world.combat.attempt_shot(shooter, casualty, injured.world.elapsed, 0)
	step(injured, 20)
	expect(injured.world.battle_state == "ENDED_FRIENDLY_VICTORY" and not injured.transition() and injured.transition_reason.begins_with("UNSUPPORTED_NONFIT_ROSTER") and injured.data.completed_battles.is_empty(), "Unsupported wounded/stabilized/evacuated roster is rejected, never silently healed or carried as FIT")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/campaign_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "campaign": session.data, "old_terminal_time": old.elapsed, "new_time": fresh.elapsed, "new_people": fresh.all_people().map(func(person): return {"id": person.id, "rank": person.formal_rank, "role": person.normal_role, "medical": person.medical_state}), "old_corp_inventory": old_corp_inventory, "new_corp_history": next_corp.appointment_history}, "\t"))
	output.close()
	print("CAMPAIGN CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/campaign_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Campaign graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	view.campaign_session = Campaign.new()
	view.model = view.campaign_session.world
	view.view_mode = "battlefield"
	root.add_child(view)
	while view.model.battle_active() and view.model.elapsed < 35:
		await create_timer(0.1).timeout
	await capture("terminal_battle1_acting_history")
	key(KEY_N)
	await process_frame
	await capture("battle2_fresh_same_people")
	expect(view.campaign_session.data.battle_index == 2 and view.model.elapsed < 0.2 and view.model.squads[0].formal_leader.id == "P1-B.1", "Actual Ncontrol enters fresh battle with explicit Sergeant assignment")
	await create_timer(1).timeout
	await capture("battle2_movement_capability_not_stock")
	key(KEY_TAB)
	await process_frame
	await capture("fresh_rear_no_old_workbench_stock")
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	key(KEY_E)
	await create_timer(1).timeout
	await capture("battle2_new_inputs_labor")
	await create_timer(3.2).timeout
	await capture("battle2_physical_ammo_produced")
	expect(view.model.rear.produced == 8 and view.model.rear.metal == 3, "Renderer Battle2 input/workstation/labor creates its own8rounds")
	key(KEY_TAB)
	while view.model.elapsed < 10.1:
		await create_timer(0.1).timeout
	await capture("battle2_advances_battle1_archive_frozen")
	expect(view.model.elapsed > 10 and view.campaign_session.archived_worlds[0].elapsed == view.campaign_session.data.completed_battles[0].world_time, "Renderer fresh Battle2 advances while old terminal clock remains frozen")
