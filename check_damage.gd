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

func fixture():
	var model = Scenario.new(false, true, false, false, true)
	model.combat.encounter_over = true
	step(model, 12.1)
	return model

func wall(model) -> Dictionary:
	return model.engineering.structures.filter(func(structure): return structure.type == "ReinforcedPosition")[0]

func blast(model, index: int, offset := -20.0) -> Array[Dictionary]:
	var structure := wall(model)
	var target = model.squads[2].soldiers[index]
	target.position = structure.position + Vector2(10, 0)
	var empty: Array[Rect2] = []
	var effects: Array[Dictionary] = Artillery.new().blast(structure.position + Vector2(offset, 0), model.elapsed, [{"person": target, "squad": model.squads[2]}], empty, model.combat)
	model.engineering.proof_effects = effects
	model.engineering.proof_blast_point = structure.position + Vector2(offset, 0)
	return effects

func rifle_covered(model) -> bool:
	return model.combat.covered(wall(model).position + Vector2(-100, 0), wall(model).position + Vector2(10, 0))

func run() -> void:
	var model = fixture()
	var engineering = model.engineering
	var structure := wall(model)
	var identity: String = structure.id
	var engineer = engineering.people[0]
	var rifleman = engineering.people[1]
	expect(structure.state == "INTACT" and structure.integrity == 2 and rifle_covered(model) and model.combat.constructed_blast_solids().size() == 1, "Constructed reinforced cover starts with integrity2 and both protections")
	var initial_history: Array = engineering.lifecycle_history.duplicate(true)
	step(model, 10)
	expect(structure.integrity == 2 and engineering.lifecycle_history == initial_history, "Time alone causes no degradation or regeneration")
	expect(engineering.assign_repair(engineer, identity, model.elapsed).is_empty() and engineering.failures.back().reason.contains("unnecessary"), "INTACT target rejects unnecessary repair without reservation")
	var first := blast(model, 0)
	expect(first[0].solid_obstruction and first[0].effect == "suppressed" and model.squads[2].soldiers[0].active, "First qualifying impact protects occupant using pre-impact INTACT wall")
	expect(structure.state == "DAMAGED" and structure.integrity == 1 and not structure.solid_blast, "Only after occupant outcome does first hit produce DAMAGED integrity1")
	expect(rifle_covered(model) and model.combat.constructed_blast_solids().is_empty(), "Current DAMAGED queries retain small-arms cover but invalidate blast obstruction")
	step(model, 3)
	expect(structure.state == "DAMAGED" and structure.integrity == 1, "Damaged wall does not passively repair")
	# A later30-unit impact still reaches the occupant lethally but is outside the
	#24-unit structure-hit radius, preserving a damaged target for repair proof.
	var later := blast(model, 0, -30)
	expect(not later[0].solid_obstruction and later[0].effect == "dead" and structure.state == "DAMAGED", "Later spatial blast passes degraded wall; outside24radius leaves damaged target repairable")
	engineering.tools[1].holder = rifleman.id
	expect(engineering.assign_repair(rifleman, identity, model.elapsed).is_empty() and not rifleman.engineer_qualified, "Unqualified Toolkit holder cannot repair")
	expect(engineering.assign_repair(engineer, identity, model.elapsed).is_empty() and engineering.failures.back().reason.contains("EngineerToolkit"), "Qualified Engineer without Toolkit cannot repair")
	engineering.tools[1].holder = engineer.id
	engineering.stockpile.inventory.BuildingMaterial = 1
	expect(engineering.assign_repair(engineer, identity, model.elapsed).is_empty() and engineering.reserved_material() == 0, "Insufficient material rejects repair without reserving")
	engineering.stockpile.inventory.BuildingMaterial = 4
	engineer.active = false
	expect(engineering.assign_repair(engineer, identity, model.elapsed).is_empty(), "Inactive Engineer cannot begin repair")
	engineer.active = true
	engineer.position = structure.position + Vector2(-120, 0)
	var repair: Dictionary = engineering.assign_repair(engineer, identity, model.elapsed)
	expect(not repair.is_empty() and repair.duration == 4 and repair.required_material == 2 and engineering.stockpile.inventory.BuildingMaterial == 2 and engineering.reserved_material() == 2, "Repair reserves2from explicit remaining4and requires4labor seconds")
	expect(not engineering.reserve_material("DuplicateRepairAllocation", 3, model.elapsed) and engineering.assign_repair(engineer, identity, model.elapsed).is_empty(), "Reserved repair units cannot be respent; target/person cannot receive duplicate job")
	step(model, 1)
	expect(repair.progress == 0 and engineer.position.distance_to(engineer.route_origin) > 60 and engineer.position.distance_to(structure.position) > 24, "Engineer physically approaches; no out-of-range repair credit")
	while repair.progress == 0 and model.elapsed < 60:
		model.advance(1.0 / 60.0)
	var progress: float = repair.progress
	engineer.path.clear()
	engineer.position = structure.position + Vector2(-40, 0)
	step(model, 1)
	expect(repair.progress == progress and repair.failure_reason == "Outside work radius", "Leaving range pauses repair progress")
	engineer.position = structure.position
	engineering.tools[1].holder = engineering.stockpile.id
	step(model, 1)
	expect(repair.progress == progress and repair.failure_reason.contains("EngineerToolkit"), "Losing Toolkit pauses repair")
	engineering.tools[1].holder = engineer.id
	engineer.engineer_qualified = false
	step(model, 1)
	expect(repair.progress == progress and repair.failure_reason.contains("qualification"), "Losing qualification independently pauses repair")
	engineer.engineer_qualified = true
	engineering.reservations[repair.id] = 1
	step(model, 1)
	expect(repair.progress == progress and repair.failure_reason.contains("reservation"), "Invalid reservation prevents repair labor")
	engineering.reservations[repair.id] = 2
	step(model, 4 - progress - 0.01)
	expect(repair.state != "COMPLETE" and structure.state == "DAMAGED", "No repair completion before all4eligible labor seconds")
	step(model, 0.01)
	expect(repair.state == "COMPLETE" and structure.state == "INTACT" and structure.integrity == 2 and structure.id == identity and engineering.structures.size() == 2, "Successful repair restores same structure without duplication")
	expect(engineering.stockpile.inventory.BuildingMaterial == 2 and engineering.reserved_material() == 0 and engineering.consumed == 6 and engineering.has_tool(engineer, "EngineerToolkit"), "Repair consumes exactly2additional material and preserves Toolkit")
	expect(rifle_covered(model) and model.combat.constructed_blast_solids().size() == 1 and structure.solid_blast, "Repair immediately restores live blast and rifle query classifications")
	var repaired := blast(model, 1)
	expect(repaired[0].solid_obstruction and repaired[0].effect == "suppressed" and structure.state == "DAMAGED", "Restored wall protects next qualifying blast before becoming DAMAGED again")
	var destroyed := blast(model, 1)
	expect(not destroyed[0].solid_obstruction and destroyed[0].effect == "dead" and structure.state == "DESTROYED" and structure.integrity == 0, "Second qualifying hit uses prior DAMAGED semantics then destroys wall")
	expect(not rifle_covered(model) and model.combat.constructed_blast_solids().is_empty() and not structure.small_arms_cover and not structure.solid_blast, "DESTROYED immediately invalidates both protections without stale cache")
	var after := blast(model, 2)
	expect(not after[0].solid_obstruction and after[0].effect == "dead", "Later blast remains unblocked by destroyed geometry")
	expect(engineering.assign_repair(engineer, identity, model.elapsed).is_empty() and engineering.failures.back().reason == "REQUIRES_REBUILD", "Destroyed target explicitly requires future rebuild, cannot ordinary-repair")
	var destroyed_history: Array = engineering.lifecycle_history.duplicate(true)
	step(model, 10)
	expect(engineering.structure_by_id(identity) == structure and structure.state == "DESTROYED" and engineering.structures.size() == 2 and engineering.lifecycle_history == destroyed_history, "Destroyed entity/ID/geometry/history persist without passive changes")
	var events: Array = engineering.lifecycle_history.filter(func(event): return event.structure == identity)
	expect(events.map(func(event): return event.event) == ["constructed", "damaged", "repaired", "damaged", "destroyed"] and events.all(func(event): return event.has("time") and event.has("source") and event.has("cause") and event.has("position")), "Lifecycle history retains constructed/damaged/repaired/destroyed with identity/time/source/cause")
	expect(model.information.query(structure.position).is_empty() and model.information.knowledge.HQ.all(func(report): return not report.has("structure")), "Structure damage history never becomes omniscient HQ inquiry knowledge")
	var boundary = fixture()
	var empty_actors: Array = []
	var empty_solids: Array[Rect2] = []
	var mortar = Artillery.new()
	mortar.blast(wall(boundary).position + Vector2(-24.01, 0), boundary.elapsed, empty_actors, empty_solids, boundary.combat)
	expect(wall(boundary).integrity == 2, "Outside24unit damage radius does not alter structure")
	mortar.blast(wall(boundary).position + Vector2(-24, 0), boundary.elapsed, empty_actors, empty_solids, boundary.combat)
	expect(wall(boundary).integrity == 1, "Exactly24unit damage radius applies one explicit hit")
	var foxhole: Dictionary = boundary.engineering.structures[0]
	mortar.blast(foxhole.position, boundary.elapsed, empty_actors, empty_solids, boundary.combat)
	expect(foxhole.state == "INTACT" and foxhole.integrity == -1, "Foxhole destruction remains outside bounded reinforced lifecycle")
	# If a repair target is destroyed while work is pending, its reservation stays
	# held (no cancellation/refund doctrine) and work cannot reconstruct it.
	var interrupted = fixture()
	blast(interrupted, 0)
	var interrupted_job: Dictionary = interrupted.engineering.assign_repair(interrupted.engineering.people[0], wall(interrupted).id, interrupted.elapsed)
	blast(interrupted, 0)
	step(interrupted, 5)
	expect(interrupted_job.progress == 0 and interrupted_job.failure_reason == "REQUIRES_REBUILD" and interrupted.engineering.reserved_material() == 2 and wall(interrupted).state == "DESTROYED", "Destruction during pending repair cannot consume labor/material or silently rebuild")
	var multiple = fixture()
	var actors: Array = []
	for index in range(2):
		var person = multiple.squads[2].soldiers[index]
		person.position = wall(multiple).position + Vector2(10, index * 8)
		actors.append({"person": person, "squad": multiple.squads[2]})
	var multi_effects: Array[Dictionary] = mortar.blast(wall(multiple).position + Vector2(-20, 0), multiple.elapsed, actors, empty_solids, multiple.combat)
	expect(multi_effects.all(func(effect): return effect.solid_obstruction and effect.effect == "suppressed") and wall(multiple).integrity == 1, "All occupants share pre-impact protection; one impact damages structure once, regardless of occupant count")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/damage_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "structure": structure, "history": events, "ledger": engineering.ledger, "repair": repair, "rejections": engineering.failures, "first_impact": first, "later_damaged_impact": later, "repaired_impact": repaired, "destroying_impact": destroyed, "destroyed_impact": after, "hit_radius": engineering.STRUCTURE_HIT_RADIUS}, "\t"))
	output.close()
	print("DAMAGE CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/damage_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Damage graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture()
	view.view_mode = "battlefield"
	root.add_child(view)
	await capture("intact")
	var first := blast(view.model, 0)
	view.model.engineering.proof_comparison = "First impact: pre-impact wall protects Soldier; wall is now DAMAGED"
	await capture("first_hit_protected_damaged")
	expect(first[0].solid_obstruction and wall(view.model).state == "DAMAGED", "Renderer first damaging impact preserves same-impact protection")
	blast(view.model, 0, -30)
	view.model.engineering.proof_comparison = "Later impact outside wall damage radius: damaged wall no longer protects Soldier"
	await capture("damaged_wall_no_blast_protection")
	var engineer = view.model.engineering.people[0]
	engineer.position = wall(view.model).position + Vector2(-120, 0)
	var repair: Dictionary = view.model.engineering.assign_repair(engineer, wall(view.model).id, view.model.elapsed)
	view.model.engineering.proof_comparison = "Repair: Engineer + Toolkit + 2 reserved Building Material + 4s labor in range"
	await create_timer(0.5).timeout
	await capture("repair_travel_reservation")
	while repair.progress < 1 and view.model.elapsed < 35:
		await create_timer(0.05).timeout
	await capture("repair_labor")
	while repair.state != "COMPLETE" and view.model.elapsed < 40:
		await create_timer(0.05).timeout
	view.model.engineering.proof_comparison = "Repair complete: original structure INTACT / both cover queries restored"
	await capture("repair_restored")
	expect(wall(view.model).state == "INTACT" and view.model.combat.constructed_blast_solids().size() == 1, "Renderer repair restores original wall protection")
	blast(view.model, 1)
	view.model.engineering.proof_comparison = "Restored wall protects first new blast; becomes DAMAGED after occupant effects"
	await capture("restored_wall_protects")
	blast(view.model, 1)
	view.model.engineering.proof_comparison = "Second hit: DESTROYED / persistent rubble / rifle and blast protection removed"
	await capture("destroyed_rubble")
	blast(view.model, 2)
	await create_timer(1).timeout
	await capture("persistent_rubble_later_blast")
	expect(wall(view.model).state == "DESTROYED" and not rifle_covered(view.model) and view.model.combat.constructed_blast_solids().is_empty(), "Rendered destroyed rubble persists with no stale cover")
