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

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.keycode = code
	Input.parse_input_event(release)

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
	root.get_texture().get_image().save_png("res://artifacts/artillery_" + name + ".png")

func run() -> void:
	var stale = Scenario.new(false, true, false, true)
	var mortar = stale.artillery
	var observer = stale.squads[0].soldiers[0]
	observer.position = Vector2(600, 400)
	var enemy = stale.combat.defenders.soldiers[0]
	expect(stale.combat.can_detect(observer, enemy), "Source report fixture begins with valid local detection")
	var reported: Vector2 = enemy.position
	stale.information.observe_enemy(observer.id, reported, 0)
	enemy.position = Vector2(900, 600)
	step(stale, 0.999)
	expect(mortar.missions.is_empty() and mortar.inventory.MortarShell == 2 and mortar.history.is_empty(), "Local truth alone creates no Company fire mission")
	step(stale, 0.001)
	expect(stale.information.contact_knowledge.Platoon.size() == 1 and stale.information.contact_knowledge.Company.is_empty(), "First delayed contact hop reaches Platoon only")
	step(stale, 1)
	expect(stale.information.contact_knowledge.Company.size() == 1 and mortar.missions.size() == 1, "Second delayed hop authorizes one Company mission")
	expect(mortar.missions[0].target == reported and mortar.missions[0].target != enemy.position and mortar.missions[0].report_id == "contact-1", "Reported coordinate and provenance drive mission rather than actual moved enemy")
	expect(not mortar.missions[0].values().any(func(value): return value is Object), "Mission contains copied values, no live target pointer")
	step(stale, 0.999)
	expect(mortar.inventory.MortarShell == 2 and mortar.fired_count == 0, "Preparation requires full one second")
	step(stale, 0.001)
	expect(mortar.inventory.MortarShell == 1 and mortar.fired_count == 1 and mortar.missions[0].state == "IN_FLIGHT", "Firing consumes exactly one physical shell")
	step(stale, 1.999)
	expect(mortar.history.is_empty(), "No damage or impact before two-second flight deadline")
	step(stale, 0.001)
	expect(mortar.history.size() == 1 and mortar.history[0].impact == reported and enemy.active, "Stale mission impacts old coordinate and does not follow moved target")
	expect(absf(mortar.history[0].impact_time - 5.0) < 0.000001 and mortar.history[0].report_observation_time == 0, "Impact history preserves fire/report timing")
	expect(stale.information.query(reported).is_empty(), "Company strike does not inject HQ inquiry knowledge")
	var historical := JSON.stringify(mortar.history)
	step(stale, 1)
	expect(JSON.stringify(mortar.history) == historical, "Impact history persists after immediate effect")
	var company: Dictionary = stale.information.company_contact_snapshot()[0]
	var operated = Artillery.new()
	expect(operated.create_mission(company, 6), "Company API can schedule a known-coordinate mission")
	operated.gunner.active = false
	var empty: Array[Dictionary] = []
	operated.advance_fire_control(7, empty)
	expect(operated.inventory.MortarShell == 2 and operated.fired_count == 0, "Unavailable gunner prevents fire and expenditure")
	operated.gunner.active = true
	operated.gunner.assigned_equipment_id = "OtherWeapon"
	operated.advance_fire_control(8, empty)
	expect(operated.inventory.MortarShell == 2, "Gunner assigned elsewhere cannot operate mortar")
	operated.gunner.assigned_equipment_id = operated.id
	operated.advance_fire_control(9, empty)
	expect(operated.inventory.MortarShell == 1 and operated.missions[0].impact_at == 11, "Actual fire time after operator availability controls flight time")
	operated.create_mission(company, 10)
	operated.advance_fire_control(11, empty)
	expect(operated.inventory.MortarShell == 0 and operated.fired_count == 2, "Second mission needs and consumes second shell")
	operated.create_mission(company, 12)
	operated.advance_fire_control(13, empty)
	expect(operated.inventory.MortarShell == 0 and operated.fired_count == 2 and operated.missions[2].state == "PREPARING", "Zero shells prevents any third shot")
	var geometry = Scenario.new(false, true, false, true)
	var squad = geometry.squads[0]
	var point := Vector2(700, 600)
	var placements := [Vector2(730, 600), Vector2(700, 630), Vector2(640, 600), Vector2(700, 691)]
	var entries: Array = []
	for index in range(4):
		squad.soldiers[index].position = placements[index]
		squad.soldiers[index].inventory.BoltActionRifleAmmo = 3
		entries.append({"person": squad.soldiers[index], "squad": squad})
	var solids: Array[Rect2] = [Rect2(710, 585, 5, 30)]
	var empty_solids: Array[Rect2] = []
	var effects: Array[Dictionary] = geometry.artillery.blast(point, 20, entries, solids, geometry.combat)
	expect(squad.soldiers[0].active and not squad.soldiers[1].active, "Same-Squad comparable30-unit targets differ from individual solid cover")
	expect(squad.soldiers[1].body_present and squad.soldiers[1].inventory.BoltActionRifleAmmo == 3, "Lethal blast leaves one persistent body with its actual inventory")
	expect(squad.soldiers[2].active and squad.soldiers[3].active and effects.size() == 3, "Outer-radius soldier survives; outside91-unit soldier receives no event")
	expect(squad.suppression == 3 and effects[0].suppression_added == 1 and effects[2].suppression_added == 2, "Protected blast adds at most1 and exposed outer blast adds2 through existing Squad suppression")
	expect(geometry.combat.history.size() == 1 and geometry.combat.history[0].world_source == "Mortar-01", "Blast death records persistent historical casualty without duplicate equipment")
	squad.soldiers[3].position = point + Vector2(0, 45)
	var single: Array = [{"person": squad.soldiers[3], "squad": squad}]
	geometry.artillery.blast(point, 21, single, empty_solids, geometry.combat)
	expect(not squad.soldiers[3].active, "Exactly45 is lethal when exposed")
	squad.soldiers[2].position = point + Vector2(-90, 0)
	single = [{"person": squad.soldiers[2], "squad": squad}]
	var boundary: Array[Dictionary] = geometry.artillery.blast(point, 22, single, empty_solids, geometry.combat)
	expect(squad.soldiers[2].active and boundary.size() == 1, "Exactly90 is nonlethal but affected")
	squad.soldiers[2].position = point + Vector2(-90.01, 0)
	expect(geometry.artillery.blast(point, 23, single, empty_solids, geometry.combat).is_empty(), "Outside90 is unaffected regardless of Squad membership")
	var normal = Scenario.new(false, true, false, true)
	for tick in range(7200):
		normal.advance(1.0 / 60.0)
		if normal.secured:
			break
	expect(normal.secured and normal.artillery.history.size() == 1 and normal.artillery.fired_count == 1, "One autonomous mission integrates with rifle contact and continuation")
	var main_effects: Array = normal.artillery.history[0].effects
	expect(main_effects.any(func(effect): return effect.effect == "dead") and main_effects.any(func(effect): return effect.solid_obstruction and effect.effect == "suppressed"), "Main scenario visibly contains exposed blast deaths and protected survivors")
	expect(normal.total_ammunition() + normal.combat.shots.size() == 35 and normal.artillery.inventory.MortarShell == 1, "Rifle accounting and separate shell inventory remain exact")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/artillery_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "stale_reported_coordinate": reported, "actual_moved_coordinate": enemy.position, "stale_mission": mortar.missions[0], "contact_deliveries": stale.information.contact_deliveries, "main_mission": normal.artillery.missions[0], "main_impact": normal.artillery.history[0], "geometry_effects": effects}, "\t"))
	output.close()
	print("ARTILLERY CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Artillery graphical scene script loads")
	if view.get_script() == null:
		view.free()
		return
	# Actual normal integrated rear+infantry+vehicle+artillery scenario.
	root.add_child(view)
	await create_timer(0.2).timeout
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	key(KEY_E)
	await create_timer(4.2).timeout
	key(KEY_F)
	key(KEY_2)
	key(KEY_TAB)
	var waited := 0
	while view.model.information.contact_knowledge.Squad.is_empty() and waited < 1000:
		await create_timer(0.05).timeout
		waited += 1
	await capture("contact_report_pending")
	expect(view.model.artillery.missions.is_empty(), "Rendered local observation precedes Company mission")
	while view.model.artillery.missions.is_empty() and waited < 1200:
		await create_timer(0.05).timeout
		waited += 1
	await capture("company_preparation")
	while view.model.artillery.fired_count == 0 and waited < 1300:
		await create_timer(0.05).timeout
		waited += 1
	await capture("mortar_fire")
	expect(view.model.artillery.inventory.MortarShell == 1 and view.model.artillery.history.is_empty(), "Renderer fire consumes shell before delayed effects")
	while view.model.artillery.history.is_empty() and waited < 1400:
		await create_timer(0.05).timeout
		waited += 1
	await capture("spatial_impact")
	var visible_effects: Array = view.model.artillery.history[0].effects
	expect(visible_effects.any(func(effect): return effect.effect == "dead") and visible_effects.any(func(effect): return effect.solid_obstruction and effect.effect == "suppressed"), "Actual integrated impact shows geometric deaths and covered survivors")
	while not view.model.secured and waited < 2200:
		await create_timer(0.05).timeout
		waited += 1
	await capture("postimpact_continuation")
	expect(view.model.secured and view.model.information.query(Vector2(790, 420)).is_empty(), "Post-impact continuation preserves restricted HQ inquiry")
