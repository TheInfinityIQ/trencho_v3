extends SceneTree

const Scenario = preload("res://scenario.gd")
const Recovery = preload("res://recovery.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

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
	root.get_texture().get_image().save_png("res://artifacts/combat_" + name + ".png")

func run() -> void:
	var sample = Scenario.new(false, true)
	var combat = sample.combat
	var shooter = sample.squads[0].soldiers[0]
	var target = combat.defenders.soldiers[0]
	shooter.position = Vector2(600, 300)
	shooter.inventory.BoltActionRifleAmmo = 4
	target.position = Vector2(900, 300)
	expect(combat.detect(shooter, [target]).is_empty() and not combat.attempt_shot(shooter, target, 0, 0), "Out of range means no detection or shot")
	shooter.position = Vector2(350, 300)
	target.position = Vector2(600, 300)
	expect(shooter.position.distance_to(target.position) <= 260 and combat.detect(shooter, [target]).is_empty(), "Solid terrain blocks otherwise in-range detection")
	shooter.detected.append(target.id)
	expect(not combat.attempt_shot(shooter, target, 0, 0) and shooter.inventory.BoltActionRifleAmmo == 4, "Shot-time LOS revalidation rejects even stale detected target")
	shooter.position = Vector2(600, 400)
	target.position = Vector2(800, 400)
	combat.detect(shooter, [target])
	expect(combat.covered(shooter.position, target.position), "Cover is relative to individual target geometry")
	expect(combat.attempt_shot(shooter, target, 0, 0.2) and target.active, "Roll0.2 misses covered10percent target")
	expect(shooter.inventory.BoltActionRifleAmmo == 3, "Shot spends one actual shooter round")
	expect(not combat.attempt_shot(shooter, target, 0.5, 0.2), "One-second cadence enforced")
	target.position = Vector2(800, 300)
	shooter.position = Vector2(600, 300)
	combat.detect(shooter, [target])
	expect(not combat.covered(shooter.position, target.position), "Same squad member can become exposed by position")
	var body_rounds: int = target.inventory.BoltActionRifleAmmo
	expect(combat.attempt_shot(shooter, target, 1, 0.2) and not target.active and target.body_present, "Same roll hits exposed40percent target and creates persistent casualty")
	expect(target.inventory.BoltActionRifleAmmo == body_rounds and combat.history.size() == 1, "Death neither duplicates nor discards carried inventory")
	var recorded_history := JSON.stringify(combat.history)
	var recovery = Recovery.new(target, false, 0)
	for tick in range(100):
		recovery.advance(0.1, tick * 0.1)
	expect(not target.body_present and recovery.inventory.BoltActionRifleAmmo == body_rounds and JSON.stringify(combat.history) == recorded_history, "Existing recovery semantics handle combat body without adding fixture ammo or erasing history")
	var live_target = combat.defenders.soldiers[1]
	live_target.position = Vector2(800, 300)
	shooter.inventory.BoltActionRifleAmmo = 0
	combat.detect(shooter, [live_target])
	expect(not combat.attempt_shot(shooter, live_target, 10, 0), "Zero ammunition prevents intentional fire")
	var suppressed = Scenario.new(false, true)
	var suppressor = suppressed.combat.defenders.soldiers[0]
	var recipient = suppressed.squads[0].soldiers[0]
	suppressor.position = Vector2(800, 300)
	suppressor.inventory.BoltActionRifleAmmo = 4
	recipient.position = Vector2(600, 300)
	for shot_index in range(4):
		suppressed.combat.detect(suppressor, [recipient])
		suppressed.combat.attempt_shot(suppressor, recipient, shot_index, 0.99)
	expect(suppressed.combat.suppression == 4 and suppressed.combat.history.is_empty(), "Four nonlethal shots suppress without any casualty")
	expect(suppressed.combat.tactical_state == "COVERING" and recipient.path.size() == 3, "Squad replaces exposed advance with local cover path")
	expect(suppressed.combat.decisions[0].living_friendly == 4 and suppressed.combat.decisions[0].state == "SUPPRESSED", "Suppression decision proves four friendly survivors")
	suppressed.supply.phase = "Final approach"
	for enemy in suppressed.combat.defenders.soldiers:
		enemy.inventory.BoltActionRifleAmmo = 0
	suppressed.combat.advance(11)
	expect(suppressed.combat.suppression == 0, "No incoming fire decays suppression by one per2s")
	var scenario = Scenario.new(false, true)
	var conserved := true
	var clear_geometry := true
	var initial_higher: Array = scenario.trace.filter(func(entry): return entry.echelon in ["Operational", "Company", "Platoon"])
	for tick in range(7200):
		scenario.advance(1.0 / 60.0)
		conserved = conserved and scenario.total_ammunition() + scenario.combat.shots.size() == 35
		for soldier in scenario.squads[0].soldiers:
			clear_geometry = clear_geometry and not scenario.OBSTACLE.grow(6).has_point(soldier.position)
		if scenario.secured:
			break
	expect(conserved, "Every combat simulation sample accounts all inventories plus expended rounds")
	expect(clear_geometry, "Withdrawal and objective resumption avoid solid rock at every sample")
	expect(scenario.secured and scenario.combat.encounter_over, "Autonomous contact resolves and objective continues")
	expect(scenario.combat.history.size() > 0, "Seeded scenario produces actual combat casualties")
	expect(scenario.combat.decisions.any(func(entry): return entry.state == "SUPPRESSED" and entry.living_friendly == 4), "Seeded encounter suppresses before friendly casualty required")
	expect(scenario.combat.decisions.any(func(entry): return entry.state == "SUPPRESSED_HOLD") and scenario.combat.tactical_state == "RESUMING", "Squad reaches cover, holds and resumes after decay")
	var final_higher: Array = scenario.trace.filter(func(entry): return entry.echelon in ["Operational", "Company", "Platoon"])
	expect(initial_higher == final_higher, "Local adaptation requires no new higher-echelon intent")
	expect(scenario.information.query(Vector2(790, 420)).is_empty(), "Exact combat truth is not injected into HQ inquiry")
	for shot in scenario.combat.shots:
		expect(shot.ammo_before - shot.ammo_after == 1 and shot.los and shot.locally_detected, "Each recorded shot has local detection, LOS and individual consumption")
	var repeat_run = Scenario.new(false, true)
	for tick in range(7200):
		repeat_run.advance(1.0 / 60.0)
		if repeat_run.secured:
			break
	expect(JSON.stringify(scenario.combat.shots) == JSON.stringify(repeat_run.combat.shots), "Fixed seeds reproduce shot sequence")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/combat_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "shots": scenario.combat.shots, "history": scenario.combat.history, "decisions": scenario.combat.decisions, "remaining_ammo": scenario.total_ammunition(), "elapsed": scenario.elapsed}, "\t"))
	output.close()
	print("COMBAT CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Combat main scene script loads")
	if view.get_script() == null:
		view.free()
		return
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
	await capture("approach_before_supply")
	var waited := 0
	while view.model.combat.first_contact < 0 and waited < 700:
		await create_timer(0.1).timeout
		waited += 1
	await capture("first_contact")
	expect(view.model.supply.delivered_at >= 0 and view.model.rear.produced == 16, "Normal combat follows actual rear production and physical soldier delivery")
	while view.model.combat.decisions.is_empty() and waited < 800:
		await create_timer(0.1).timeout
		waited += 1
	await capture("suppression_local_cover")
	expect(not view.model.combat.decisions.is_empty() and view.model.combat.decisions[0].living_friendly == 4, "Renderer encounter enters suppression with all four friendly alive")
	key(KEY_B)
	await process_frame
	click(Vector2(790, 420))
	await capture("combat_inquiry_unknown")
	expect(view.query_result.is_empty(), "Real combat inquiry does not expose local/world truth")
	while view.model.combat.tactical_state == "COVERING" and waited < 1000:
		await create_timer(0.1).timeout
		waited += 1
	await capture("cover_hold")
	while view.model.combat.tactical_state != "RESUMING" and waited < 1200:
		await create_timer(0.1).timeout
		waited += 1
	await capture("resuming")
	while not view.model.secured and waited < 1500:
		await create_timer(0.1).timeout
		waited += 1
	await capture("autonomous_continuation")
	expect(view.model.secured and view.model.combat.history.size() > 0, "Real combat produces casualties and autonomous objective continuation")
