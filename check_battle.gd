extends SceneTree

const Scenario = preload("res://scenario.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func step(model, duration: float) -> void:
	var remaining := duration
	while remaining > 0.000001:
		var delta := minf(remaining, 1.0 / 60.0)
		model.advance(delta)
		remaining -= delta

func fixture(auto_strike := true, target := "Enemy-HQ", rear := false, full := false):
	var model = Scenario.new(rear, true, full, true, full, full, full, true)
	model.combat.encounter_over = true
	model.battle.auto_strike = auto_strike
	model.battle.target_hq_id = target
	if target == "Friendly-HQ":
		model.artillery.id = "EnemyMortar-01"
		model.artillery.gunner.id = "EnemyGunner-01"
		model.artillery.gunner.faction = "enemy"
		model.artillery.gunner.assigned_equipment_id = model.artillery.id
	return model

func impact(model, point: Vector2, actors: Array = []) -> Array[Dictionary]:
	var solids: Array[Rect2] = []
	return model.artillery.blast(point, model.elapsed, actors, solids, model.combat)

func hit_person(model, target, lethal := true) -> bool:
	var shooter = model.combat.defenders.soldiers[0]
	shooter.position = target.position + Vector2(0, -100)
	model.combat.detect(shooter, [target])
	return model.combat.attempt_shot(shooter, target, model.elapsed, 0.0 if lethal else 0.99)

func snapshot(model) -> String:
	var people: Array = []
	for squad in model.squads:
		for person in squad.soldiers:
			people.append({"id": person.id, "position": person.position, "active": person.active, "medical": person.medical_state, "body": person.body_present, "present": person.on_battlefield, "inventory": person.inventory, "waypoint": person.waypoint})
	for person in model.combat.defenders.soldiers + model.platoons.map(func(platoon): return platoon.leader):
		people.append({"id": person.id, "position": person.position, "active": person.active, "medical": person.medical_state, "inventory": person.inventory})
	var data := {"time": model.elapsed, "result": model.battle_state, "hqs": model.battle.hqs, "battle_history": model.battle.history,
		"people": people, "trace": model.trace, "shots": model.combat.shots, "combat_history": model.combat.history,
		"suppression": model.squads.map(func(squad): return squad.suppression), "morale": model.squads.map(func(squad): return squad.morale),
		"information": model.information.knowledge, "leader_reports": model.information.leader_knowledge, "leader_relays": model.information.leader_relays,
		"contact_deliveries": model.information.contact_deliveries, "morale_deliveries": model.information.morale_deliveries,
		"supply": {"phase": model.supply.phase, "truck": model.supply.truck.position, "transactions": model.supply.transactions},
		"mortar": {"inventory": model.artillery.inventory, "missions": model.artillery.missions, "history": model.artillery.history},
		"recovery": {"position": model.recovery.position, "state": model.recovery.state, "inventory": model.recovery.inventory}}
	if model.integrated_rear:
		data.rear = {"avatar": model.rear.avatar, "worker": model.rear.worker, "job": model.rear.job, "metal": model.rear.metal, "ammunition": model.rear.ammunition, "produced": model.rear.produced, "committed": model.rear.committed, "shipment": model.rear.shipment, "ledger": model.rear.ledger}
	if model.engineering != null:
		data.engineering = {"jobs": model.engineering.jobs, "reservations": model.engineering.reservations, "stock": model.engineering.stockpile, "structures": model.engineering.structures}
	if model.vehicles != null:
		data.vehicles = [model.vehicles.truck.position, model.vehicles.truck.route_state, model.vehicles.truck.route, model.vehicles.tracked.position, model.vehicles.tracked.route_state, model.vehicles.events]
	if model.medical != null:
		data.medical = {"progress": model.medical.treatment_progress, "medic": model.medical.medic.position, "inventory": model.medical.medic.inventory, "evac": model.medical.evac, "history": model.medical.history}
	return JSON.stringify(data)

func run() -> void:
	var victory = fixture()
	var enemy: Dictionary = victory.battle.hqs["Enemy-HQ"]
	expect(enemy.id == "Enemy-HQ" and enemy.owner == "enemy" and enemy.integrity == 2 and enemy.state == "INTACT" and enemy.geometry is Rect2 and victory.battle.hqs["Friendly-HQ"].owner == "friendly", "Two physical persistent HQs have ownership, geometry, integrity2 and lifecycle")
	expect(victory.information.query(enemy.position).is_empty(), "Static strategic briefing does not inject live HQ inquiry knowledge")
	step(victory, 3.05)
	expect(victory.battle_state == "ACTIVE" and enemy.state == "DAMAGED" and enemy.integrity == 1 and victory.artillery.fired_count == 1 and victory.artillery.inventory.MortarShell == 1, "First actual autonomous shell impact damages HQ once and battle continues")
	var first_time: float = victory.elapsed
	step(victory, 0.5)
	expect(victory.elapsed > first_time and victory.battle_state == "ACTIVE", "Nonterminal first hit permits later normal world progression")
	step(victory, 10)
	expect(victory.battle_state == "ENDED_FRIENDLY_VICTORY" and enemy.integrity == 0 and enemy.state == "DESTROYED", "Second qualifying physical mortar impact destroys enemy HQ and latches friendly victory")
	expect(victory.artillery.fired_count == 2 and victory.artillery.inventory.MortarShell == 0 and victory.artillery.history.size() == 2 and victory.artillery.missions.all(func(mission): return mission.state == "IMPACTED"), "Both strikes spend physical shells through gunner/preparation/flight/impact and terminal impact fully commits")
	expect(victory.battle.hqs[enemy.id] == enemy and victory.battle.history.map(func(event): return event.event) == ["HQ damaged", "HQ destroyed", "terminal battle result"], "Destroyed same-ID HQ persists with damage/destruction/result history")
	var terminal_snapshot := snapshot(victory)
	step(victory, 100)
	expect(snapshot(victory) == terminal_snapshot and absf(victory.elapsed - victory.battle.terminal_time) < 0.02, "All later authoritative ticks are frozen at terminal world time")
	impact(victory, victory.battle.hqs["Friendly-HQ"].position)
	victory.battle.apply_blast_damage(victory.battle.hqs["Friendly-HQ"].position, victory.elapsed + 50, "late duplicate")
	expect(not victory.artillery.create_mission(victory.battle.strategic_report(), victory.elapsed + 1), "No new fire mission can be created after terminal result")
	var empty_reports: Array[Dictionary] = []
	victory.artillery.advance_fire_control(victory.elapsed + 50, empty_reports)
	victory.artillery.resolve_impacts(victory.elapsed + 50, victory.blast_entities(), victory.combat.solid_cover, victory.combat)
	expect(not victory.combat.attempt_shot(victory.combat.defenders.soldiers[0], victory.squads[0].formal_leader, victory.elapsed + 50, 0) and snapshot(victory) == terminal_snapshot, "Repeated damage/fire/tick calls cannot flip result, duplicate destruction or spend resources")
	var defeat = fixture(true, "Friendly-HQ")
	step(defeat, 20)
	expect(defeat.battle_state == "ENDED_FRIENDLY_DEFEAT" and defeat.battle.hqs["Friendly-HQ"].state == "DESTROYED" and defeat.battle.hqs["Enemy-HQ"].state == "INTACT" and defeat.artillery.fired_count == 2, "Mirrored actual enemy-mortar path destroys Friendly-HQ and freezes defeat")
	var unavailable = fixture()
	unavailable.artillery.gunner.active = false
	step(unavailable, 12)
	expect(unavailable.battle_state == "ACTIVE" and unavailable.artillery.inventory.MortarShell == 2 and unavailable.battle.hqs["Enemy-HQ"].integrity == 2, "Unavailable actual gunner prevents HQ damage, shell expenditure and result")
	unavailable.artillery.gunner.active = true
	step(unavailable, 12)
	expect(unavailable.battle_state == "ENDED_FRIENDLY_VICTORY" and unavailable.artillery.inventory.MortarShell == 0, "Restored gunner resumes real pending weapon path rather than free terminal damage")
	var commander = fixture(false)
	step(commander, 13)
	expect(hit_person(commander, commander.squads[0].formal_leader) and commander.squads[0].formal_leader.body_present and commander.battle_state == "ACTIVE", "Real formal commander casualty does not end battle")
	var objective = fixture(false)
	step(objective, 40)
	expect(objective.secured and objective.battle_state == "ACTIVE" and objective.battle.hqs.values().all(func(hq): return hq.integrity == 2), "Survivors reaching Objective A is nonterminal while HQs intact")
	var force = fixture(false)
	var rifleman = force.squads[2].soldiers[2]
	rifleman.inventory.BoltActionRifleAmmo = 4
	var real_hits := true
	for target in force.combat.defenders.soldiers:
		rifleman.position = target.position + Vector2(0, -100)
		force.combat.detect(rifleman, [target])
		real_hits = real_hits and force.combat.attempt_shot(rifleman, target, force.elapsed, 0)
		step(force, 1)
	expect(real_hits and force.combat.defenders.soldiers.all(func(person): return not person.active) and force.battle_state == "ACTIVE", "Four genuine rifle casualties eliminating normal defensive Squad do not end battle")
	var empty = fixture(false)
	var harmless: Dictionary = empty.battle.strategic_report()
	harmless.kind = "ENEMY_POSITION_OBSERVED"
	harmless.observed_position = Vector2(700, 600)
	empty.artillery.create_mission(harmless, 0)
	empty.artillery.create_mission(harmless, 0)
	step(empty, 4)
	expect(empty.artillery.inventory.MortarShell == 0 and empty.artillery.fired_count == 2 and empty.battle_state == "ACTIVE", "Actual mortar ammunition exhaustion after non-HQ impacts is nonterminal")
	var routing = fixture(false)
	routing.combat.defenders.soldiers[0].inventory.BoltActionRifleAmmo = 4
	step(routing, 13)
	hit_person(routing, routing.squads[0].formal_leader)
	step(routing, 1)
	hit_person(routing, routing.squads[0].soldiers[2])
	step(routing, 1)
	hit_person(routing, routing.squads[0].soldiers[3], false)
	step(routing, 1)
	hit_person(routing, routing.squads[0].soldiers[3], false)
	step(routing, 1.0 / 60.0)
	expect(routing.squads[0].routing_state == "RETREATING" and routing.battle_state == "ACTIVE", "Actual casualty/suppression morale rout is nonterminal")
	var fort = Scenario.new(false, true, false, true, true, false, false, true)
	fort.battle.auto_strike = false
	fort.combat.encounter_over = true
	step(fort, 12.1)
	var position: Vector2 = fort.engineering.sites["Reinforced Site B"]
	impact(fort, position)
	impact(fort, position)
	expect(fort.engineering.structures[1].state == "DESTROYED" and fort.battle_state == "ACTIVE", "Ordinary reinforced fortification destruction is not HQ defeat")
	var bridge = fixture(false, "Enemy-HQ", false, true)
	impact(bridge, bridge.vehicles.infrastructure["Bridge-A"].position)
	expect(bridge.vehicles.infrastructure["Bridge-A"].state == "DESTROYED" and bridge.battle_state == "ACTIVE", "Ordinary bridge destruction is not HQ defeat")
	var ordering = fixture(false)
	var prepared_shooter = ordering.combat.defenders.soldiers[0]
	var prepared_target = ordering.squads[0].formal_leader
	prepared_shooter.position = prepared_target.position + Vector2(100, 0)
	ordering.combat.detect(prepared_shooter, [prepared_target])
	var prepared_ammo: int = prepared_shooter.inventory.BoltActionRifleAmmo
	var point: Vector2 = ordering.battle.hqs["Enemy-HQ"].position
	impact(ordering, point)
	var actors: Array = []
	for index in [2, 3]:
		var person = ordering.squads[2].soldiers[index]
		person.position = point + Vector2(10 + index, 0)
		actors.append({"person": person, "squad": ordering.squads[2]})
	var effects := impact(ordering, point, actors)
	expect(effects.size() == 2 and effects.all(func(effect): return effect.effect == "dead") and ordering.battle_state == "ENDED_FRIENDLY_VICTORY", "All ordinary-person effects of destroying impact finish before HQ result latch/kill guard")
	expect(not ordering.combat.attempt_shot(prepared_shooter, prepared_target, ordering.elapsed + 2, 0) and prepared_shooter.inventory.BoltActionRifleAmmo == prepared_ammo and prepared_target.active, "Previously-valid detected/in-range shooter cannot spend remaining ammo or kill after terminal result")
	var old_suppression: int = ordering.squads[0].suppression
	impact(ordering, prepared_target.position + Vector2(60, 0), [{"person": prepared_target, "squad": ordering.squads[0]}])
	expect(ordering.squads[0].suppression == old_suppression and prepared_target.active, "Post-terminal direct blast cannot add even nonlethal suppression to present people")
	var boundary = fixture(false)
	var boundary_point: Vector2 = boundary.battle.hqs["Enemy-HQ"].position
	impact(boundary, boundary_point + Vector2(30.01, 0))
	expect(boundary.battle.hqs["Enemy-HQ"].integrity == 2, "Outside30unit HQ radius applies no damage")
	impact(boundary, boundary_point + Vector2(30, 0))
	expect(boundary.battle.hqs["Enemy-HQ"].integrity == 1 and boundary.battle_state == "ACTIVE", "Exactly30unit spatial hit damages once without premature terminal state")
	var busy = fixture(false, "Enemy-HQ", true, true)
	expect(busy.rear.place_workbench(Vector2(380, 480)) and busy.rear.start_job("Avatar", 0), "Busy freeze fixture begins real rear production")
	busy.rear.set_policy("RESERVE", 8)
	step(busy, 4.0166666667)
	expect(busy.rear.start_job("Avatar", busy.elapsed), "Second physical rear batch provides actual export/vehicle cargo")
	step(busy, 12 - busy.elapsed)
	busy.engineering.assign("BasicFoxhole", busy.engineering.people[1], "Dig Site A", busy.elapsed)
	busy.artillery.create_mission(busy.battle.strategic_report(), busy.elapsed)
	step(busy, 2)
	busy.artillery.create_mission(busy.battle.strategic_report(), busy.elapsed)
	step(busy, 1)
	busy.medical.wound_target_ids[busy.squads[0].formal_leader.id] = true
	hit_person(busy, busy.squads[0].formal_leader)
	expect(busy.rear.start_job("Avatar", busy.elapsed), "Third production job is pending during terminal strike")
	step(busy, 1)
	hit_person(busy, busy.squads[0].soldiers[2], false)
	busy.squads[1].assign("Stage in support", Vector2(335, 650), busy.OBSTACLE)
	while busy.battle_active() and busy.elapsed < 25:
		busy.advance(1.0 / 60.0)
	expect(not busy.rear.job.is_empty() and busy.engineering.jobs[0].progress > 0 and busy.engineering.jobs[0].progress < 3 and busy.vehicles.truck.route_state == "MOVING", "Terminal tick catches genuine production/engineering and vehicle movement in progress")
	expect(busy.medical.casualty.medical_state == "WOUNDED" and busy.medical.treatment_progress > 0 and busy.medical.treatment_progress < 2 and busy.squads[0].suppression > 0 and busy.information.leader_knowledge.Company.is_empty(), "Terminal tick catches treatment/bleed/suppression and undelivered superior report pending")
	var busy_snapshot := snapshot(busy)
	step(busy, 100)
	expect(snapshot(busy) == busy_snapshot and busy.battle_state == "ENDED_FRIENDLY_VICTORY", "Terminal guard freezes all movement, combat, suppression, medicine, vehicles, engineering, rear work/export and report propagation")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/battle_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "victory_history": victory.battle.history, "victory_missions": victory.artillery.missions, "victory_impacts": victory.artillery.history, "defeat_history": defeat.battle.history, "ordering_effects": effects, "busy_terminal_time": busy.elapsed, "busy_snapshot": JSON.parse_string(busy_snapshot), "hit_radius": victory.battle.HIT_RADIUS}, "\t"))
	output.close()
	print("BATTLE CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/battle_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Battle graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture()
	view.view_mode = "battlefield"
	root.add_child(view)
	await create_timer(0.2).timeout
	await capture("both_hqs_intact")
	while view.model.battle.hqs["Enemy-HQ"].integrity == 2 and view.model.elapsed < 10:
		await create_timer(0.05).timeout
	await capture("first_physical_hit_battle_active")
	expect(view.model.battle_active() and view.model.artillery.fired_count == 1, "Renderer first shell damages HQ without ending battle")
	while view.model.artillery.fired_count < 2 and view.model.elapsed < 12:
		await create_timer(0.05).timeout
	await capture("second_shell_in_flight")
	while view.model.battle_active() and view.model.elapsed < 15:
		await create_timer(0.05).timeout
	await capture("destroyed_enemy_hq_victory")
	var frozen: float = view.model.elapsed
	await create_timer(2).timeout
	await capture("frozen_world_persistent_hq_aftermath")
	expect(view.model.battle_state == "ENDED_FRIENDLY_VICTORY" and view.model.elapsed == frozen and view.model.battle.hqs["Enemy-HQ"].state == "DESTROYED", "Renderer terminal victory persists with frozen world and same destroyed HQ")
