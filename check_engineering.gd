extends SceneTree

const Scenario = preload("res://scenario.gd")
const Engineering = preload("res://engineering.gd")
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

func fixture(assign_work := true, rear := false):
	var model = Scenario.new(rear, true, false, false, true)
	model.combat.encounter_over = true
	if not assign_work:
		model.engineering = Engineering.new(false)
	return model

func shot_at_site(model) -> Dictionary:
	var shooter = model.squads[3].soldiers[0]
	var target = model.combat.defenders.soldiers[0]
	target.position = model.engineering.sites["Dig Site A"]
	shooter.position = target.position + Vector2(-100, 0)
	shooter.inventory.BoltActionRifleAmmo = 2
	model.combat.detect(shooter, [target])
	var fired: bool = model.combat.attempt_shot(shooter, target, model.elapsed, 0.2)
	return {"fired": fired, "survived": target.active, "covered": model.combat.shots.back().covered, "position": target.position}

func compare_blast(model) -> Array[Dictionary]:
	var position: Vector2 = model.engineering.sites["Reinforced Site B"]
	var actors: Array = []
	for index in range(2):
		var person = model.squads[2].soldiers[index]
		person.position = position + (Vector2(20, 0) if index == 0 else Vector2(-20, 40))
		actors.append({"person": person, "squad": model.squads[2]})
	var solids: Array[Rect2] = []
	return Artillery.new().blast(position + Vector2(-20, 0), model.elapsed, actors, solids, model.combat)

func send_away(engineering) -> void:
	for person in engineering.people:
		person.route_origin = person.position
		person.path.assign([person.position + Vector2(-100, 0)])
		person.waypoint = 0
		person.arrived = false

func run() -> void:
	var denied = fixture(false)
	var rules = denied.engineering
	var engineer = rules.people[0]
	var rifleman = rules.people[1]
	expect(engineer.id == "Engineer-01" and engineer.engineer_qualified and rifleman.id == "Rifleman-01" and not rifleman.engineer_qualified, "Two persistent person records have independent engineering qualification")
	expect(rules.tools.size() == 2 and rules.tools[0].id != rules.tools[1].id and rules.has_tool(rifleman, "BasicShovel") and rules.has_tool(engineer, "EngineerToolkit"), "Distinct physical tool identities have explicit person custody")
	expect(rules.tool_position(rules.tools[0]) == rifleman.position, "Carried tool position follows actual custodian")
	expect(rules.eligibility("BasicFoxhole", rifleman).is_empty(), "Unqualified infantry with shovel may dig")
	expect(not rules.eligibility("ReinforcedPosition", rifleman).is_empty(), "Shovel does not unlock reinforced engineering")
	rules.tools[1].holder = rifleman.id
	expect(not rules.eligibility("ReinforcedPosition", rifleman).is_empty() and not rifleman.engineer_qualified, "Toolkit possession cannot grant Engineer qualification")
	expect(not rules.eligibility("ReinforcedPosition", engineer).is_empty(), "Qualification without actual toolkit is insufficient")
	expect(rules.assign("ReinforcedPosition", rifleman, "Reinforced Site B", 0).is_empty() and rules.stockpile.inventory.BuildingMaterial == 8 and rules.reserved_material() == 0, "Materials plus unqualified tool holder cannot start or reserve")
	rules.tools[1].holder = engineer.id
	rules.tools[0].holder = "MilitaryConstructionStock-01"
	expect(rules.assign("BasicFoxhole", rifleman, "Dig Site A", 0).is_empty(), "Missing shovel rejects basic job start")
	rules.tools[0].holder = rifleman.id
	engineer.active = false
	expect(rules.assign("ReinforcedPosition", engineer, "Reinforced Site B", 0).is_empty(), "Inactive qualified equipped person cannot construct")
	engineer.active = true
	rules.stockpile.inventory.BuildingMaterial = 3
	expect(rules.assign("ReinforcedPosition", engineer, "Reinforced Site B", 0).is_empty() and rules.stockpile.inventory.BuildingMaterial == 3, "Insufficient BuildingMaterial rejects without partial consumption")
	var idle = fixture(false)
	step(idle, 10)
	expect(idle.engineering.structures.is_empty() and idle.engineering.stockpile.inventory.BuildingMaterial == 8, "Materials/tools alone do not automatically create a structure without assignment")
	var basic = fixture(false)
	var dig = basic.engineering
	var digger = dig.people[1]
	var dig_job: Dictionary = dig.assign("BasicFoxhole", digger, "Dig Site A", basic.elapsed)
	step(basic, 1)
	expect(dig_job.progress == 0 and digger.position != digger.origin and digger.position.distance_to(dig_job.position) > dig.WORK_RADIUS, "Person physically travels; no remote labor credit")
	digger.path.clear()
	digger.position = dig_job.position
	step(basic, 2.99)
	expect(dig.structures.is_empty() and dig_job.progress < 3, "Foxhole requires all3worldseconds labor")
	dig.tools[0].holder = dig.stockpile.id
	var progress: float = dig_job.progress
	step(basic, 1)
	expect(dig_job.progress == progress and dig_job.failure_reason.contains("BasicShovel"), "Losing shovel pauses existing labor")
	dig.tools[0].holder = digger.id
	digger.position += Vector2(40, 0)
	step(basic, 1)
	expect(dig_job.progress == progress and dig_job.failure_reason == "Outside work radius", "Leaving24unit range pauses without remote completion")
	digger.position = dig_job.position
	step(basic, 0.01)
	expect(dig_job.state == "COMPLETE" and dig.structures.size() == 1 and dig_job.progress == 3, "Returning resumes retained labor and creates one Foxhole")
	expect(dig.stockpile.inventory.BuildingMaterial == 8 and dig.reserved_material() == 0 and dig.ledger.is_empty() and dig.has_tool(digger, "BasicShovel"), "Basic digging consumes no material and retains shovel")
	var before = fixture(false)
	var exposed := shot_at_site(before)
	var protected := shot_at_site(basic)
	expect(exposed.position == protected.position and exposed.fired and not exposed.covered and not exposed.survived and protected.fired and protected.covered and protected.survived, "Same-position real rifle roll0.2 kills exposed target but misses completed-Foxhole occupant using existing40/10percent rules")
	expect(basic.combat.visible(basic.squads[3].soldiers[0].position, protected.position) and basic.combat.constructed_blast_solids().is_empty(), "Foxhole neither blocks LOS nor supplies solid blast obstruction")
	var fox_target = basic.squads[2].soldiers[2]
	fox_target.position = dig.sites["Dig Site A"] + Vector2(20, 0)
	var solids: Array[Rect2] = []
	var fox_effects: Array = Artillery.new().blast(dig.sites["Dig Site A"] + Vector2(-20, 0), basic.elapsed, [{"person": fox_target, "squad": basic.squads[2]}], solids, basic.combat)
	expect(not fox_target.active and not fox_effects[0].solid_obstruction, "Foxhole occupant remains vulnerable to unobstructed lethal blast")
	var model = fixture()
	var construction = model.engineering
	var reinforced: Dictionary = construction.jobs[1]
	expect(construction.stockpile.inventory.BuildingMaterial == 4 and construction.reserved_material() == 4 and construction.consumed == 0, "Reinforced assignment moves4from free8into exclusive reservation")
	expect(not construction.reserve_material("CompetingConstruction", 5, model.elapsed) and construction.stockpile.inventory.BuildingMaterial == 4 and construction.reserved_material() == 4, "Second allocation cannot spend the already-reserved4")
	var allocation = fixture(false).engineering
	var first: Dictionary = allocation.assign("ReinforcedPosition", allocation.people[0], "Reinforced Site B", 0)
	allocation.people[1].engineer_qualified = true
	allocation.tools[1].holder = allocation.people[1].id
	var second: Dictionary = allocation.assign("ReinforcedPosition", allocation.people[1], "Dig Site A", 0)
	expect(not first.is_empty() and not second.is_empty() and allocation.stockpile.inventory.BuildingMaterial == 0 and allocation.reserved_material() == 8 and not allocation.reserve_material("ThirdConstruction", 4, 0), "Two real jobs may reserve disjoint4unit allocations; no third allocation can reuse either")
	var conserved := true
	var clear := true
	while reinforced.progress == 0 and model.elapsed < 20:
		model.advance(1.0 / 60.0)
		conserved = conserved and construction.stockpile.inventory.BuildingMaterial + construction.reserved_material() + construction.consumed == 8
		for person in construction.people:
			clear = clear and not model.OBSTACLE.grow(6).has_point(person.position)
	expect(reinforced.progress > 0 and construction.people[0].position.distance_to(reinforced.position) <= 24 and clear, "Engineer reaches authored site physically along clear approach before labor")
	construction.people[0].path.clear()
	construction.people[0].active = false
	progress = reinforced.progress
	step(model, 1)
	expect(reinforced.progress == progress, "Inactive constructor cannot progress assigned job")
	construction.people[0].active = true
	construction.tools[1].holder = construction.stockpile.id
	step(model, 1)
	expect(reinforced.progress == progress and reinforced.failure_reason.contains("EngineerToolkit"), "Toolkit custody is revalidated during labor")
	construction.tools[1].holder = construction.people[0].id
	construction.people[0].engineer_qualified = false
	step(model, 1)
	expect(reinforced.progress == progress and reinforced.failure_reason.contains("qualification"), "Engineer qualification is independently revalidated during labor")
	construction.people[0].engineer_qualified = true
	construction.reservations[reinforced.id] = 3
	step(model, 1)
	expect(reinforced.progress == progress and reinforced.failure_reason.contains("reservation"), "Invalid material reservation pauses specialist labor")
	construction.reservations[reinforced.id] = 4
	step(model, 5 - progress - 0.01)
	expect(reinforced.state != "COMPLETE" and construction.consumed == 0, "Reinforced structure cannot finish before full5labor seconds")
	step(model, 0.01)
	expect(reinforced.state == "COMPLETE" and construction.structures.size() == 2 and reinforced.progress == 5, "Five eligible labor seconds complete one reinforced position")
	expect(conserved and construction.stockpile.inventory.BuildingMaterial == 4 and construction.reserved_material() == 0 and construction.consumed == 4 and construction.ledger.size() == 2, "Exact reservation-to-consumption ledger leaves4total material without duplication")
	expect(construction.has_tool(construction.people[0], "EngineerToolkit"), "Toolkit remains reusable in same custody after completion")
	expect(construction.stockpile.inventory.keys() == ["BuildingMaterial"] and construction.ledger.all(func(event): return event.resource == "BuildingMaterial"), "Construction uses exactly one material currency")
	expect(construction.structures[0].type == "Foxhole" and construction.structures[1].type == "ReinforcedPosition" and construction.structures[1].solid_blast, "Persistent result records explicitly classify geometry/cover")
	var effects := compare_blast(model)
	expect(effects.size() == 2 and effects[0].distance == effects[1].distance and effects[0].solid_obstruction and effects[0].effect == "suppressed" and not effects[1].solid_obstruction and effects[1].effect == "dead", "Existing spatial blast at equal40unit range kills exposed Soldier while completed reinforced wall protects intervened Soldier")
	expect(model.combat.covered(Vector2(600, 580), construction.sites["Reinforced Site B"] + Vector2(20, 0)), "Reinforced protection area also supplies existing small-arms covered treatment")
	var structures := JSON.stringify(construction.structures)
	send_away(construction)
	step(model, 10)
	expect(JSON.stringify(construction.structures) == structures and construction.people.all(func(person): return person.arrived and person.position.distance_to(person.route_origin) >= 99), "Constructors physically walk away100units; completed geometry persists through elapsed world time")
	expect(construction.assign("BasicFoxhole", construction.people[1], "Dig Site A", model.elapsed).is_empty() and construction.structures.size() == 2, "Completed site cannot duplicate a persistent structure")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/engineering_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "tools": construction.tools, "jobs": construction.jobs, "structures": construction.structures, "stockpile": construction.stockpile, "ledger": construction.ledger, "rejections": rules.failures, "small_arms_before": exposed, "small_arms_after": protected, "blast": effects, "work_radius": construction.WORK_RADIUS}, "\t"))
	output.close()
	print("ENGINEERING CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/engineering_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Engineering graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture(true, true)
	view.view_mode = "battlefield"
	root.add_child(view)
	await create_timer(0.8).timeout
	await capture("travel_and_material_reservation")
	await create_timer(2.0).timeout
	await capture("foxhole_labor")
	while view.model.engineering.jobs[0].state != "COMPLETE" and view.model.elapsed < 10:
		await create_timer(0.05).timeout
	await capture("foxhole_complete_engineer_travel")
	while view.model.engineering.jobs[1].progress <= 0 and view.model.elapsed < 15:
		await create_timer(0.05).timeout
	await capture("reinforced_labor")
	var progress: float = view.model.engineering.jobs[1].progress
	view.switch_map()
	await create_timer(1.0).timeout
	expect(view.view_mode == "rear" and view.model.engineering.jobs[1].progress > progress, "Engineering labor continues on authoritative time across map switch")
	view.switch_map()
	await capture("after_view_change")
	while view.model.engineering.jobs[1].state != "COMPLETE" and view.model.elapsed < 20:
		await create_timer(0.05).timeout
	var effects := compare_blast(view.model)
	view.model.engineering.proof_comparison = "Equal 40-unit blast: behind wall survives / exposed Soldier dies"
	view.model.engineering.proof_effects = effects
	view.model.engineering.proof_blast_point = view.model.engineering.sites["Reinforced Site B"] + Vector2(-20, 0)
	expect(effects[0].solid_obstruction and effects[0].effect == "suppressed" and effects[1].effect == "dead", "Renderer fixture executes actual built-cover blast comparison")
	await capture("reinforced_complete_combat_comparison")
	send_away(view.model.engineering)
	await create_timer(2).timeout
	await capture("constructors_depart_structures_persist")
	expect(view.model.engineering.structures.size() == 2 and view.model.engineering.reserved_material() == 0 and view.model.engineering.stockpile.inventory.BuildingMaterial == 4 and view.model.engineering.people.all(func(person): return person.position.distance_to(person.route_origin) >= 99), "Rendered constructors physically depart; persistent structures retain exact final material accounting")
