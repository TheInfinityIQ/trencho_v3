extends SceneTree

const Scenario = preload("res://scenario.gd")
const Artillery = preload("res://artillery.gd")
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

func fixture(qualified := true, leader := false, rear := false):
	var model = Scenario.new(rear, true, false, false, false, false, true)
	model.combat.encounter_over = true
	model.medical.medic.medic_qualified = qualified
	var person = model.squads[0].soldiers[0 if leader else 1]
	model.medical.wound_target_ids[person.id] = true
	return model

func wound_hit(model, leader := false) -> bool:
	var person = model.squads[0].soldiers[0 if leader else 1]
	var shooter = model.combat.defenders.soldiers[0]
	shooter.position = person.position + Vector2(100, 0)
	model.combat.detect(shooter, [person])
	return model.combat.attempt_shot(shooter, person, model.elapsed, 0.0)

func run() -> void:
	var model = fixture()
	var medical = model.medical
	var person = model.squads[0].soldiers[1]
	var identity: String = person.id
	expect(person.medical_state == "FIT" and person.active and person.is_alive() and medical.medic.medic_qualified and medical.medic.inventory.Medkit == 2, "Persistent FIT person and real qualified Medic with2explicit Medkits")
	step(model, 13)
	var inventory: Dictionary = person.inventory.duplicate(true)
	var shooter_ammo: int = model.combat.defenders.soldiers[0].inventory.BoltActionRifleAmmo
	expect(wound_hit(model), "Designated actual rifle detection/LOS/ammo/cadence/hit path wounds")
	var deadline: float = person.bleed_out_at
	expect(model.combat.defenders.soldiers[0].inventory.BoltActionRifleAmmo == shooter_ammo - 1 and model.combat.shots.back().hit, "Wound-producing shot actually spends source round and resolves hit")
	expect(person.medical_state == "WOUNDED" and person.is_alive() and not person.active and person.on_battlefield and not person.body_present and absf(deadline - model.elapsed - 8) < 0.000001, "Wounded is alive/present/noncombat, no corpse, with8second world deadline")
	expect(person.inventory == inventory and model.squads[0].morale == 80 and medical.treatment_progress == 0, "Wound retains inventory, applies one casualty penalty, assignment does not heal")
	var location: Vector2 = person.position
	person.advance(1)
	expect(person.position == location and model.squads[0].eligibility_reason(person) != "Eligible", "Wounded cannot move normally or exercise qualified Corporal command")
	var ready := 0
	for member in model.squads[0].soldiers:
		if member.active:
			ready += member.inventory.BoltActionRifleAmmo
	expect(model.squads[0].carried_ammunition("BoltActionRifleAmmo") == ready and ready < 16, "Wounded inventory is excluded from living combat-readiness stock")
	person.detected.append(model.combat.defenders.soldiers[0].id)
	expect(not model.combat.attempt_shot(person, model.combat.defenders.soldiers[0], model.elapsed, 0) and person.inventory == inventory, "Wounded cannot fire or spend carried ammunition")
	expect(not medical.assign_evac(person) and medical.evac.state == "IDLE", "Still-WOUNDED casualty cannot be evacuated")
	medical.medic.medic_qualified = false
	expect(medical.treatment_eligibility(person).contains("qualification") and medical.medic.inventory.Medkit == 2, "Medkit holding alone does not grant Medic qualification")
	medical.medic.medic_qualified = true
	medical.medic.inventory.Medkit = 0
	expect(medical.treatment_eligibility(person).contains("Medkit"), "Qualified Medic without physical Medkit cannot treat")
	medical.medic.inventory.Medkit = 2
	step(model, 0.25)
	expect(medical.medic.position != medical.medic.origin and medical.treatment_progress == 0 and person.medical_state == "WOUNDED", "Medic physically approaches; no remote treatment credit")
	while person.medical_state == "WOUNDED" and model.elapsed < deadline:
		model.advance(1.0 / 60.0)
	expect(person.medical_state == "STABILIZED" and model.elapsed < deadline and medical.medic.inventory.Medkit == 1 and medical.ledger.size() == 1 and medical.ledger[0].quantity == 1, "Completed2seconds physical treatment before deadline consumes exactly1Medkit and stabilizes")
	expect(person.is_alive() and not person.active and person.on_battlefield and person.inventory == inventory and person.bleed_out_at == -1 and model.squads[0].eligibility_reason(person) != "Eligible", "Stabilized person retains inventory/presence but no normal movement/command/readiness or bleed timer")
	expect(medical.evac.state == "APPROACHING" and medical.evac.position.distance_to(person.position) > 24 and person.on_battlefield, "Distinct persistent EvacTeam is physically approaching, not teleport-picking up")
	while medical.evac.state != "PICKUP" and model.elapsed < 40:
		model.advance(1.0 / 60.0)
	expect(person.medical_state == "STABILIZED" and person.on_battlefield and medical.evac.position.distance_to(person.position) <= 24, "Casualty remains present until physical EvacTeam reaches pickup radius")
	var pickup: float = medical.evac.pickup_progress
	step(model, 2 - pickup - 0.01)
	expect(person.medical_state == "STABILIZED" and person.on_battlefield and model.elapsed > deadline, "Stabilized casualty survives original bleed deadline and waits all2pickup seconds")
	step(model, 0.01)
	expect(person.medical_state == "EVACUATED" and person.id == identity and person == model.squads[0].soldiers[1] and person.is_alive() and not person.active and not person.on_battlefield and not person.body_present, "Same living person becomes EVACUATED with no battlefield representation/corpse/replacement")
	expect(person.inventory == inventory and medical.evac.inventory.is_empty() and model.total_ammunition() + model.combat.shots.size() == 35, "Evacuated inventory stays with person, is not duplicated into team or lost from total custody")
	step(model, 10)
	expect(person.medical_state == "EVACUATED" and not person.body_present and model.squads[0].morale == 80 and medical.medic.inventory.Medkit == 1, "Later time neither creates corpse, repeats morale nor consumes extra Medkits")
	expect(medical.history.map(func(event): return event.event) == ["wounded", "stabilized", "evacuated"] and medical.history.all(func(event): return event.person == identity and event.has("time") and event.has("source")), "Medical history retains same identity and causal world times/sources")
	expect(model.information.query(location).is_empty(), "Medical World State does not populate HQ inquiry")
	var untreated = fixture(false)
	step(untreated, 13)
	expect(wound_hit(untreated), "Failure fixture also wounds through actual shot path")
	var victim = untreated.medical.casualty
	var failed_inventory: Dictionary = victim.inventory.duplicate(true)
	var failed_position: Vector2 = victim.position
	step(untreated, 7.99)
	expect(victim.medical_state == "WOUNDED" and victim.is_alive() and not victim.body_present and victim.position == failed_position, "Untreated casualty remains alive/present before full8seconds")
	var held_time: float = untreated.elapsed
	untreated.information.reconstructing = true
	step(untreated, 2)
	expect(untreated.elapsed == held_time and victim.medical_state == "WOUNDED", "Existing authoritative world pause also freezes bleed-out")
	untreated.information.reconstructing = false
	step(untreated, 0.01)
	expect(victim.medical_state == "DEAD" and not victim.is_alive() and victim.body_present and victim.on_battlefield and victim.inventory == failed_inventory and not victim.active, "Exact8second bleed-out produces ordinary same-person corpse and inventory")
	expect(untreated.squads[0].morale == 80 and untreated.combat.history.filter(func(event): return event.event == "combat casualty").size() == 1 and untreated.medical.history.map(func(event): return event.event) == ["wounded", "died from wounds"], "Bleed death is recorded once and does not charge second ordinary casualty morale")
	step(untreated, 5)
	expect(victim.body_present and victim.inventory == failed_inventory and untreated.medical.evac.state == "IDLE" and untreated.medical.medic.inventory.Medkit == 2, "Untreated body/inventory persist, no evacuation or free Medkit use")
	var pauses = fixture()
	step(pauses, 13)
	wound_hit(pauses)
	var controller = pauses.medical
	controller.medic.path.clear()
	controller.medic.position = controller.casualty.position
	step(pauses, 0.5)
	var progress: float = controller.treatment_progress
	controller.medic.position += Vector2(-40, 0)
	step(pauses, 0.5)
	expect(controller.treatment_progress == progress and controller.casualty.medical_state == "WOUNDED", "Leaving treatment radius pauses existing treatment rather than healing remotely")
	controller.medic.position = controller.casualty.position
	controller.medic.active = false
	step(pauses, 0.5)
	expect(controller.treatment_progress == progress, "Inactive Medic cannot progress treatment")
	controller.medic.active = true
	controller.medic.medic_qualified = false
	step(pauses, 0.5)
	expect(controller.treatment_progress == progress, "Lost qualification pauses treatment while retaining Medkit")
	controller.medic.medic_qualified = true
	controller.medic.inventory.Medkit = 0
	step(pauses, 0.5)
	expect(controller.treatment_progress == progress, "Lost Medkit custody pauses treatment")
	var leader = fixture(false, true)
	step(leader, 13)
	wound_hit(leader, true)
	var formal = leader.squads[0].formal_leader
	expect(formal.medical_state == "WOUNDED" and leader.squads[0].morale == 60 and leader.squads[0].leadership_state == "DISRUPTION", "Formal leader wound applies one casualty+one unavailable-leader morale penalty and disruption")
	step(leader, 0.5)
	expect(leader.squads[0].current_leader() == leader.squads[0].soldiers[1] and leader.squads[0].acting_leader.formal_rank == "CORPORAL", "Wounded formal leader is replaced through existing acting succession without promotion")
	step(leader, 2)
	expect(leader.information.leader_knowledge.Company[0].deceased_leader == "" and leader.information.leader_knowledge.Company[0].unavailability == "wounded", "Existing delayed succession report describes wounded unavailability without falsely declaring death")
	step(leader, 5.5)
	expect(formal.medical_state == "DEAD" and leader.squads[0].morale == 60 and leader.squads[0].morale_log.size() == 2, "Later formal-leader bleed-out does not repeat casualty or leader-loss morale")
	var under_fire = fixture()
	step(under_fire, 13)
	wound_hit(under_fire)
	step(under_fire, 1)
	var exposed = under_fire.medical.casualty
	var shooter = under_fire.combat.defenders.soldiers[0]
	under_fire.combat.detect(shooter, [exposed])
	expect(under_fire.combat.attempt_shot(shooter, exposed, under_fire.elapsed, 0) and exposed.medical_state == "DEAD" and under_fire.squads[0].morale == 80, "Wounded physical person remains vulnerable to subsequent ordinary lethal fire without duplicate casualty morale")
	var blast_case = fixture()
	step(blast_case, 13)
	wound_hit(blast_case)
	blast_case.medical.medic.position = blast_case.medical.casualty.position
	blast_case.medical.medic.path.clear()
	step(blast_case, 2)
	var stabilized = blast_case.medical.casualty
	var empty_solids: Array[Rect2] = []
	Artillery.new().blast(stabilized.position, blast_case.elapsed, [{"person": stabilized, "squad": blast_case.squads[0]}], empty_solids, blast_case.combat)
	expect(stabilized.medical_state == "DEAD" and stabilized.body_present and blast_case.squads[0].morale == 80, "Stabilized battlefield casualty remains physical in existing blast resolution, without duplicate morale")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/medical_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "history": medical.history, "ledger": medical.ledger, "person": {"id": identity, "state": person.medical_state, "present": person.on_battlefield, "body": person.body_present, "inventory": person.inventory}, "evac": medical.evac, "untreated_history": untreated.medical.history, "failed_inventory": victim.inventory, "leader_morale": leader.squads[0].morale_log, "leader_report": leader.information.leader_knowledge.Company}, "\t"))
	output.close()
	print("MEDICAL CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/medical_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Medical graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture(true, false, true)
	view.view_mode = "battlefield"
	root.add_child(view)
	await create_timer(13).timeout
	expect(wound_hit(view.model), "Rendered wound uses real rifle shot")
	await capture("wounded_present_no_corpse")
	await create_timer(0.2).timeout
	await capture("medic_approach")
	view.switch_map()
	var clock_before: float = view.model.elapsed
	await create_timer(0.5).timeout
	view.switch_map()
	expect(view.model.elapsed > clock_before + 0.4 and view.model.medical.casualty.medical_state == "WOUNDED", "Medical world clock continues across real map view switches")
	while view.model.medical.casualty.medical_state == "WOUNDED" and view.model.elapsed < 25:
		await create_timer(0.05).timeout
	await capture("stabilized_medkit_consumed")
	expect(view.model.medical.casualty.medical_state == "STABILIZED" and view.model.medical.medic.inventory.Medkit == 1, "Rendered qualified physical Medic consumes1to stabilize")
	await create_timer(0.6).timeout
	await capture("evac_team_approaches")
	while view.model.medical.casualty.medical_state != "EVACUATED" and view.model.elapsed < 40:
		await create_timer(0.05).timeout
	await capture("evacuated_no_body_inventory_retained")
	expect(not view.model.medical.casualty.on_battlefield and not view.model.medical.casualty.body_present, "Rendered evacuation removes person representation without corpse")
	root.remove_child(view)
	view.free()
	var failure_view = load("res://main.tscn").instantiate()
	failure_view.model = fixture(false)
	failure_view.view_mode = "battlefield"
	root.add_child(failure_view)
	await create_timer(13).timeout
	wound_hit(failure_view.model)
	await capture("untreated_wound")
	while failure_view.model.medical.casualty.medical_state != "DEAD" and failure_view.model.elapsed < 25:
		await create_timer(0.05).timeout
	await capture("bleed_out_death_body")
	await create_timer(1).timeout
	await capture("untreated_body_inventory_persists")
	expect(failure_view.model.medical.casualty.body_present and failure_view.model.medical.casualty.medical_state == "DEAD", "Separate renderer failure creates persistent ordinary corpse")
