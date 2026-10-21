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

func fixture(no_successor := false):
	var model = Scenario.new(false, true)
	model.combat.encounter_over = true
	# Explicit dedicated-test ammunition, accounted in the proof's initial total.
	model.combat.defenders.soldiers[0].inventory.BoltActionRifleAmmo = 24
	if no_successor:
		for person in model.squads[0].soldiers.slice(1):
			person.squad_command_qualified = false
	return model

func shoot(model, target, lethal := false) -> bool:
	var shooter = model.combat.defenders.soldiers[0]
	# The rout trigger originates east of the advancing squad. A separate rally
	# safety stress relocates the fixture north when west-face cover blocks east.
	shooter.position = target.position + Vector2(100, 0)
	if not model.combat.visible(shooter.position, target.position):
		shooter.position = target.position + Vector2(0, -100)
	model.combat.detect(shooter, [target])
	return model.combat.attempt_shot(shooter, target, model.elapsed, 0.0 if lethal else 0.99)

func losses_then_rout(model, no_successor := false) -> void:
	step(model, 13)
	expect(shoot(model, model.squads[0].formal_leader, true), "Actual range/LOS/ammunition shot kills formal leader")
	step(model, 0.5)
	expect(model.squads[0].acting_leader == (null if no_successor else model.squads[0].soldiers[1]), "Ordinary succession/leaderless rules precede routing")
	step(model, 0.5)
	expect(shoot(model, model.squads[0].soldiers[2], true), "Second actual combat casualty")
	step(model, 1)
	expect(shoot(model, model.squads[0].soldiers[3]), "First additional nonlethal incoming shot")
	step(model, 1)
	expect(shoot(model, model.squads[0].soldiers[3]), "Fourth accumulated incoming shot crosses episode threshold")
	step(model, 1.0 / 60.0)

func report_count(model, echelon: String, kind: String) -> int:
	return model.information.morale_knowledge[echelon].filter(func(report): return report.kind == kind).size()

func run() -> void:
	var ordinary = fixture()
	var normal = ordinary.squads[0]
	expect(normal.morale == 100 and normal.suppression == 0 and normal.morale_state == "STEADY", "Independent initial morale/suppression")
	step(ordinary, 13)
	for index in range(4):
		expect(shoot(ordinary, normal.soldiers[3]), "Ordinary suppression fixture uses real nonlethal incoming shot")
		if index < 3:
			step(ordinary, 1)
	expect(normal.morale == 85 and normal.suppression == 4 and normal.morale_state == "STEADY", "Ordinary four-miss episode costs15morale independently of suppression4")
	expect(normal.soldiers.all(func(person): return person.active) and ordinary.combat.tactical_state == "COVERING" and normal.routing_state == "NONE", "All four living members adapt to cover without routing")
	for index in range(2):
		step(ordinary, 1)
		shoot(ordinary, normal.soldiers[3])
	expect(normal.morale == 85 and normal.suppression == 6 and normal.morale_log.size() == 1, "Further shots in continuous episode do not repeat morale penalty")
	step(ordinary, 35)
	expect(ordinary.secured and ordinary.combat.tactical_state == "RESUMING" and normal.morale == 85 and normal.routing_state == "NONE", "Ordinary suppression reaches cover and resumes Objective A without morale rout")
	expect(normal.suppression <= 1 and not normal.suppression_episode_penalized, "Episode rearmed only after safe suppression decay")
	for index in range(4):
		shoot(ordinary, normal.soldiers[3])
		if index < 3:
			step(ordinary, 1)
	expect(normal.morale == 70 and normal.morale_log.size() == 2, "New episode after safe region can apply one new penalty")
	var model = fixture()
	var squad = model.squads[0]
	var initial_ammo: int = model.total_ammunition()
	var higher: Array = model.trace.filter(func(entry): return entry.echelon in ["Operational", "Company", "Platoon"]).duplicate(true)
	var assignments: Array = model.platoons.map(func(platoon): return platoon.assignment)
	losses_then_rout(model)
	expect(squad.morale == 25 and squad.morale_state == "ROUTING" and squad.routing_state == "RETREATING", "Real accumulated -20casualty -20leader -20casualty -15episode causes deterministic rout25")
	expect(squad.morale_log.slice(0, 4).map(func(event): return event.change) == [-20, -20, -20, -15], "Separate event penalties preserve actual causes/order")
	expect(squad.routing_trigger.cause == "Sustained suppression episode" and squad.routing_trigger.after == 25, "Exact route trigger is inspectable")
	expect(squad.morale_log[1].state == "SHAKEN" and squad.morale_log[1].after == 60, "Leader loss reaches inspectable SHAKEN band")
	expect(squad.current_leader() == squad.soldiers[1] and squad.acting_leader.formal_rank == "CORPORAL" and squad.acting_leader.normal_role == "AssistantSquadLeader", "Acting authority persists without promotion/normal-role change")
	expect(squad.task == "Seize Objective A" and assignments == model.platoons.map(func(platoon): return platoon.assignment) and higher == model.trace.filter(func(entry): return entry.echelon in ["Operational", "Company", "Platoon"]), "Routing leaves Operational/Company/Platoon intent and task records unchanged")
	expect(squad.rally_destination.x < model.OBSTACLE.position.x and squad.rally_destination.y > model.OBSTACLE.position.y and squad.rally_destination.y < model.OBSTACLE.end.y, "Squad chooses deterministic rearward west-face cover locally")
	expect(not model.combat.visible(model.combat.defenders.soldiers[0].position, squad.rally_destination), "Solid outcrop blocks LOS from actual last incoming source to chosen rally cover")
	var reverse_clear := true
	for start in [Vector2(650, 350), Vector2(620, 210), Vector2(620, 510)]:
		var path: Array[Vector2] = squad.retreat_path(start, squad.rally_destination, 10)
		reverse_clear = reverse_clear and not path.is_empty() and path.back() == squad.rally_destination
		for target in path:
			for sample in range(101):
				reverse_clear = reverse_clear and not model.OBSTACLE.grow(6).has_point(start.lerp(target, sample / 100.0))
			start = target
	expect(reverse_clear, "Retreat paths from east, north and south remain clear of expanded solid terrain")
	expect(squad.soldiers.filter(func(person): return person.active).all(func(person): return not person.path.is_empty() and person.position.distance_to(person.path.back()) > 10), "Living people have real retreat paths; no teleport to rally")
	var dead_inventories: Array = [squad.soldiers[0].inventory.duplicate(true), squad.soldiers[2].inventory.duplicate(true)]
	model.combat.kill(squad.soldiers[0], model.combat.defenders.soldiers[0], model.elapsed)
	expect(model.combat.history.size() == 2 and squad.morale == 25, "Duplicate casualty call cannot duplicate body/history/morale penalties")
	var advance_rejected: Dictionary = squad.assign("Seize Objective B", Vector2(900, 300), model.OBSTACLE)
	var retreat_paths: Array = squad.soldiers.map(func(person): return person.path.duplicate())
	squad.resume_final_approach()
	expect(advance_rejected.is_empty() and squad.task == "Seize Objective A" and retreat_paths == squad.soldiers.map(func(person): return person.path), "Mission APIs cannot replace retreat with an advance")
	var friendly = squad.soldiers[1]
	var enemy = model.combat.defenders.soldiers[1]
	enemy.position = friendly.position + Vector2(0, -80)
	model.combat.detect(friendly, [enemy])
	var rounds: int = friendly.inventory.BoltActionRifleAmmo
	expect(not model.combat.attempt_shot(friendly, enemy, model.elapsed, 0) and friendly.inventory.BoltActionRifleAmmo == rounds, "Routing suppresses attack even through direct combat API")
	expect(report_count(model, "Squad", "SQUAD_ROUTING") == 1 and report_count(model, "Platoon", "SQUAD_ROUTING") == 0 and report_count(model, "Company", "SQUAD_ROUTING") == 0, "Local routing report does not instantly give higher-command knowledge")
	var sent: float = model.information.morale_knowledge.Squad[0].sent_at
	step(model, 0.999)
	expect(report_count(model, "Platoon", "SQUAD_ROUTING") == 0, "No Platoon rout report before1second hop")
	step(model, 0.001)
	expect(report_count(model, "Platoon", "SQUAD_ROUTING") == 1 and report_count(model, "Company", "SQUAD_ROUTING") == 0, "Platoon receives rout report at1second; Company waits")
	step(model, 1)
	var route_report: Dictionary = model.information.morale_knowledge.Company[0]
	expect(report_count(model, "Company", "SQUAD_ROUTING") == 1 and absf(route_report.received_at - sent - 2) < 0.000001 and route_report.morale == 25 and route_report.acting_leader == "P1-A.2", "Company receives original morale/acting identity at2second delay")
	var geometry_clear := true
	var physical := true
	var conserved := true
	for tick in range(2400):
		var previous: Array = squad.soldiers.map(func(person): return person.position)
		model.advance(1.0 / 60.0)
		for index in range(4):
			var person = squad.soldiers[index]
			geometry_clear = geometry_clear and not model.OBSTACLE.grow(6).has_point(person.position)
			physical = physical and person.position.distance_to(previous[index]) < 2
		conserved = conserved and model.total_ammunition() + model.combat.shots.size() == initial_ammo
		if squad.routing_state == "AT_RALLY":
			break
	expect(squad.routing_state == "AT_RALLY" and squad.morale == 25 and physical and geometry_clear, "Survivors retreat physically around solid terrain and arrive without healing in transit")
	expect(conserved and squad.soldiers[0].body_present and squad.soldiers[2].body_present and dead_inventories == [squad.soldiers[0].inventory, squad.soldiers[2].inventory], "Retreat conserves ammunition, dead people, bodies and inventories")
	while squad.suppression > 1:
		model.advance(1.0 / 60.0)
	# Hold fire on the rally for8s. Real misses continually reset safety/decay.
	for index in range(8):
		shoot(model, squad.soldiers[3])
		step(model, 1)
	expect(squad.morale == 10 and squad.routing_state == "AT_RALLY", "New sustained episode at rally lowers morale; no recovery under continuing actual fire")
	var final_incoming: float = squad.last_incoming_at
	while squad.suppression > 1:
		model.advance(1.0 / 60.0)
	expect(model.elapsed >= final_incoming + 4 and squad.morale == 10, "Recovery still blocked by high suppression even after4quiet seconds")
	step(model, 1.98)
	expect(squad.morale == 10, "Safe recovery waits full2second interval")
	step(model, 0.04)
	expect(squad.morale == 15, "First safe2second interval adds exactly5morale")
	while squad.routing_state != "RALLIED_HOLD" and model.elapsed < 100:
		model.advance(1.0 / 60.0)
	expect(squad.morale == 50 and squad.morale_state == "SHAKEN" and squad.routing_state == "RALLIED_HOLD", "Rally stabilizes at50 and exits ROUTING into hold")
	var rally_sent: float = model.information.morale_knowledge.Squad.back().sent_at
	expect(report_count(model, "Company", "SQUAD_RALLIED") == 0, "Company does not know rally completion before delayed report")
	var held: Array = squad.soldiers.map(func(person): return person.position)
	step(model, 10)
	expect(held == squad.soldiers.map(func(person): return person.position) and squad.morale == 50 and not model.secured, "Rallied squad holds permanently without automatic objective resumption or perfect recovery")
	expect(report_count(model, "Company", "SQUAD_RALLIED") == 1 and absf(model.information.morale_knowledge.Company.back().received_at - rally_sent - 2) < 0.000001, "Rallied report uses same two delayed hops")
	expect(model.information.query(squad.rally_destination).is_empty() and not model.information.knowledge.HQ.any(func(report): return report.has("morale")), "HQ inquiry receives no exact morale/world-state shortcut")
	expect(higher == model.trace.filter(func(entry): return entry.echelon in ["Operational", "Company", "Platoon"]) and squad.current_leader().id == "P1-A.2", "Higher intent and acting authority unchanged through final hold")
	var repeat_run = fixture()
	losses_then_rout(repeat_run)
	expect(repeat_run.squads[0].morale_log == squad.morale_log.slice(0, 5) and repeat_run.squads[0].rally_destination == squad.rally_destination, "Identical real event sequence deterministically reproduces morale/rout/rally choice")
	var leaderless = fixture(true)
	losses_then_rout(leaderless, true)
	expect(leaderless.squads[0].leadership_state == "LEADERLESS_HOLD" and leaderless.squads[0].routing_state == "PENDING_COMMAND", "Low morale cannot invent command authority for leaderless squad")
	var leaderless_positions: Array = leaderless.squads[0].soldiers.map(func(person): return person.position)
	step(leaderless, 10)
	expect(leaderless_positions == leaderless.squads[0].soldiers.map(func(person): return person.position), "Leaderless routing request preserves existing hold")
	var timed = fixture()
	losses_then_rout(timed)
	while timed.squads[0].recovery_due_at < 0 and timed.elapsed < 60:
		timed.advance(1.0 / 60.0)
	var due: float = timed.squads[0].recovery_due_at
	step(timed, maxf(0, due - timed.elapsed - 1.0 / 60.0))
	var due_morale: int = timed.squads[0].morale
	var automatic_shooter = timed.combat.defenders.soldiers[0]
	automatic_shooter.position = timed.squads[0].soldiers[1].position + Vector2(-60, 0)
	timed.combat.encounter_over = false
	timed.advance(1.0 / 60.0)
	expect(absf(timed.squads[0].last_incoming_at - due) < 0.000001 and timed.squads[0].morale <= due_morale and not timed.squads[0].morale_log.any(func(event): return event.cause == "Safe rally recovery"), "Incoming automatic combat on exact recovery-due frame prevents morale gain")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/morale_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "events": squad.morale_log, "trigger": squad.routing_trigger, "rally": squad.rally_destination, "reports": model.information.morale_knowledge, "deliveries": model.information.morale_deliveries, "shots": model.combat.shots, "casualties": model.combat.history, "higher_intent": higher, "ordinary_events": normal.morale_log}, "\t"))
	output.close()
	print("MORALE CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/morale_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Morale graphical scene script loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture()
	view.view_mode = "battlefield"
	view.morale_diagnostics = true
	root.add_child(view)
	await create_timer(13.0).timeout
	await capture("steady")
	for index in range(4):
		shoot(view.model, view.model.squads[0].soldiers[3])
		await create_timer(1.02).timeout
	await capture("ordinary_suppression_no_rout")
	expect(view.model.squads[0].morale == 85 and view.model.squads[0].routing_state == "NONE", "Renderer ordinary suppression leaves morale85 without routing")
	root.remove_child(view)
	view.free()
	view = load("res://main.tscn").instantiate()
	view.model = fixture()
	view.view_mode = "battlefield"
	view.morale_diagnostics = true
	root.add_child(view)
	await create_timer(13.0).timeout
	shoot(view.model, view.model.squads[0].formal_leader, true)
	await capture("leader_casualty_shaken")
	await create_timer(0.55).timeout
	await capture("acting_authority")
	await create_timer(0.5).timeout
	shoot(view.model, view.model.squads[0].soldiers[2], true)
	await capture("second_casualty")
	await create_timer(1.02).timeout
	shoot(view.model, view.model.squads[0].soldiers[3])
	await create_timer(1.02).timeout
	shoot(view.model, view.model.squads[0].soldiers[3])
	await capture("routing_local_before_report")
	expect(view.model.squads[0].morale == 25 and report_count(view.model, "Company", "SQUAD_ROUTING") == 0, "Renderer accumulated rout precedes Company knowledge")
	await create_timer(2.1).timeout
	await capture("retreat_and_delivered_report")
	while view.model.squads[0].routing_state != "AT_RALLY" and view.model.elapsed < 65:
		await create_timer(0.05).timeout
	await capture("rally_cover")
	while view.model.squads[0].routing_state != "RALLIED_HOLD" and view.model.elapsed < 90:
		await create_timer(0.05).timeout
	await capture("rallied_holding")
	expect(view.model.squads[0].morale == 50 and view.model.squads[0].routing_state == "RALLIED_HOLD" and not view.model.secured, "Rendered survivors stabilize and hold without completing objective")
	await create_timer(2.1).timeout
	await capture("rallied_report_delivered")
	expect(report_count(view.model, "Company", "SQUAD_RALLIED") == 1, "Renderer Company learns rally through report")
