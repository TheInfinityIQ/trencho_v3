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
	# Isolate succession with one controlled real attack, without a second fight.
	model.combat.encounter_over = true
	if no_successor:
		for person in model.squads[0].soldiers.slice(1):
			person.squad_command_qualified = false
	return model

func lethal_hit(model) -> bool:
	var leader = model.squads[0].formal_leader
	var shooter = model.combat.defenders.soldiers[0]
	shooter.position = leader.position + Vector2(0, -100)
	model.combat.detect(shooter, [leader])
	return model.combat.attempt_shot(shooter, leader, model.elapsed, 0.0)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/command_" + name + ".png")

func run() -> void:
	var model = fixture()
	var squad = model.squads[0]
	expect(squad.formal_leader == squad.soldiers[0] and squad.formal_leader.id == "P1-A.1", "Formal authority references one existing physical Soldier")
	var identities: Dictionary = {}
	for group in model.squads:
		for person in group.soldiers:
			identities[person.id] = true
	for platoon in model.platoons:
		identities[platoon.leader.id] = true
	expect(identities.size() == 18 and model.platoons[0].leader != squad.formal_leader, "Sixteen squad people plus two distinct platoon leaders, no duplicate leader")
	expect(squad.eligibility_reason(squad.soldiers[1]) == "Eligible", "Qualified Corporal is eligible")
	squad.soldiers[2].rifle_proficiency = 1
	expect(squad.eligibility_reason(squad.soldiers[2]) != "Eligible", "Rifle proficiency does not invent command qualification/rank")
	squad.soldiers[2].squad_command_qualified = true
	expect(squad.eligibility_reason(squad.soldiers[2]) == "Below Corporal rank", "Qualification alone does not replace rank")
	squad.soldiers[2].squad_command_qualified = false
	expect(squad.eligibility_reason(model.squads[1].soldiers[0]) == "Not a member of this squad", "Other squad commander cannot become local candidate by rank alone")
	step(model, 13)
	var leader = squad.formal_leader
	var inherited_task: String = squad.task
	var higher: Array = model.trace.filter(func(entry): return entry.echelon in ["Operational", "Company", "Platoon"])
	var dead_inventory: Dictionary = leader.inventory.duplicate(true)
	var candidate_inventory: Dictionary = squad.soldiers[1].inventory.duplicate(true)
	expect(lethal_hit(model), "Controlled real shot uses range/LOS/ammo/hit path to kill formal leader")
	expect(not leader.active and leader.body_present and model.combat.history.size() == 1, "Genuine casualty creates body and historical event")
	expect(squad.leadership_state == "DISRUPTION" and squad.current_leader() == null, "Loss recognized locally at casualty time")
	var positions: Array = squad.soldiers.map(func(person): return person.position)
	step(model, 0.499)
	expect(squad.soldiers.map(func(person): return person.position) == positions and squad.acting_leader == null, "Disruption freezes maneuver for full0.5world seconds")
	step(model, 0.001)
	expect(squad.acting_leader == squad.soldiers[1] and squad.leadership_state == "ACTING_COMMAND", "Local acting appointment occurs after0.5s")
	expect(squad.acting_leader.formal_rank == "CORPORAL" and squad.acting_leader.normal_role == "AssistantSquadLeader" and squad.acting_leader.acting_appointment == "SquadLeader:P1-A", "Formal rank/normal role remain separate from acting appointment")
	expect(squad.task == inherited_task and higher == model.trace.filter(func(entry): return entry.echelon in ["Operational", "Company", "Platoon"]), "Existing mission and higher intent unchanged")
	expect(model.information.leader_knowledge.Platoon.is_empty() and model.information.leader_knowledge.Company.is_empty(), "Appointment is local before delayed superior knowledge")
	expect(leader.inventory == dead_inventory and squad.soldiers[1].inventory == candidate_inventory, "Succession does not transfer or copy dead leader equipment")
	step(model, 0.999)
	expect(model.information.leader_knowledge.Platoon.is_empty(), "No early Platoon casualty report")
	step(model, 0.001)
	expect(model.information.leader_knowledge.Platoon.size() == 1 and model.information.leader_knowledge.Company.is_empty(), "Report reaches Platoon one hop after local appointment/send")
	step(model, 1)
	var report: Dictionary = model.information.leader_knowledge.Company[0]
	expect(report.deceased_leader == leader.id and report.acting_replacement == squad.soldiers[1].id and absf(report.observation_time - 13) < 0.000001, "Company later receives casualty/acting identity with original observation time")
	var near := true
	var terrain_clear := true
	for tick in range(2400):
		model.advance(1.0 / 60.0)
		for platoon in model.platoons:
			var distance := INF
			for person in platoon.squads[0].soldiers:
				if person.active:
					distance = minf(distance, person.position.distance_to(platoon.leader.position))
			near = near and distance < 90
			terrain_clear = terrain_clear and not model.OBSTACLE.grow(6).has_point(platoon.leader.position)
	expect(near and terrain_clear, "Physical platoon leaders stay near troops and navigate clear of solid terrain")
	expect(model.secured and leader.body_present and leader.inventory == dead_inventory, "Survivors continue mission while leader body and inventory persist")
	var no_successor = fixture(true)
	step(no_successor, 13)
	lethal_hit(no_successor)
	var held_positions: Array = no_successor.squads[0].soldiers.map(func(person): return person.position)
	step(no_successor, 20)
	expect(no_successor.squads[0].leadership_state == "LEADERLESS_HOLD" and no_successor.squads[0].acting_leader == null, "No eligible successor yields explicit leaderless hold")
	expect(no_successor.squads[0].soldiers.map(func(person): return person.position) == held_positions and no_successor.squads.size() == 4, "Leaderless squad neither advances/scatters nor disbands")
	expect(no_successor.squads[0].soldiers[1].formal_rank == "CORPORAL" and no_successor.squads[0].soldiers[2].formal_rank == "PRIVATE", "No magical permanent promotions in failure case")
	var tie = fixture()
	tie.squads[0].soldiers[2].formal_rank = "CORPORAL"
	tie.squads[0].soldiers[2].squad_command_qualified = true
	tie.squads[0].soldiers[3].formal_rank = "SERGEANT"
	tie.squads[0].soldiers[3].squad_command_qualified = true
	tie.squads[0].soldiers[3].normal_role = "PlatoonLeader"
	step(tie, 13)
	lethal_hit(tie)
	step(tie, 0.5)
	expect(tie.squads[0].acting_leader.id == "P1-A.2", "Stable person-ID tie handling excludes incompatible higher-ranked role")
	var higher_rank = fixture()
	higher_rank.squads[0].soldiers[2].formal_rank = "SERGEANT"
	higher_rank.squads[0].soldiers[2].squad_command_qualified = true
	step(higher_rank, 13)
	lethal_hit(higher_rank)
	step(higher_rank, 0.5)
	expect(higher_rank.squads[0].acting_leader.id == "P1-A.3", "Highest qualified compatible rank precedes person-ID ordering")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/command_checks.json", FileAccess.WRITE)
	var people: Array = squad.soldiers.map(func(person): return {"id": person.id, "formal_rank": person.formal_rank, "normal_role": person.normal_role, "command_qualified": person.squad_command_qualified, "rifle_proficiency": person.rifle_proficiency, "acting_appointment": person.acting_appointment, "active": person.active, "position": person.position, "inventory": person.inventory})
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "people": people, "succession": squad.leadership_log, "company_report": report, "leaderless": no_successor.squads[0].leadership_log, "acting_rank": squad.acting_leader.formal_rank}, "\t"))
	output.close()
	print("COMMAND CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Command graphical scene script loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture()
	view.view_mode = "battlefield"
	view.leadership_diagnostics = true
	root.add_child(view)
	await create_timer(12.9).timeout
	await capture("formal_leader")
	expect(lethal_hit(view.model), "Rendered leader casualty uses real shot path")
	await capture("casualty_disruption")
	await create_timer(0.55).timeout
	await capture("acting_appointment")
	expect(view.model.squads[0].acting_leader != null and view.model.squads[0].acting_leader.formal_rank == "CORPORAL", "Visible acting appointment retains rank")
	await create_timer(2.0).timeout
	await capture("higher_report_delivered")
	while not view.model.secured and view.model.elapsed < 60:
		await create_timer(0.1).timeout
	await capture("same_mission_continues")
	expect(view.model.secured and view.model.squads[0].formal_leader.body_present, "Rendered surviving squad completes original mission")
	root.remove_child(view)
	view.free()
	var held = load("res://main.tscn").instantiate()
	held.model = fixture(true)
	held.view_mode = "battlefield"
	held.leadership_diagnostics = true
	root.add_child(held)
	await create_timer(13.0).timeout
	lethal_hit(held.model)
	await create_timer(0.6).timeout
	await capture("no_successor_hold")
	expect(held.model.squads[0].leadership_state == "LEADERLESS_HOLD", "Separate rendered no-successor fixture holds without invented command")
