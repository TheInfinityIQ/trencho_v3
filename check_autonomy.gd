extends SceneTree
const Layout = preload("res://sector_layout.gd")
const Rural = preload("res://sector_environment.gd")
const Sector = preload("res://sector_scenario.gd")
var checks := 0
var failures: Array[String] = []
var evidence := []
var model_update_us := []
var reassignment_update_us := 0
var slow_updates := []
func _initialize() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func make_world(seed_value: int, scenario_seed := 38038):
	var layout = Layout.new(); layout.generate(seed_value)
	var rural = Rural.new()
	rural.configure(JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/docs/metadata.json")), JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/provenance.json")).archive_sha256)
	rural.compose(layout)
	return Sector.new(layout, rural, scenario_seed)
func run() -> void:
	for seed_value in [35035, 35036]:
		var started := Time.get_ticks_usec()
		var world = make_world(seed_value)
		print("WORLD ",seed_value," build_ms=",(Time.get_ticks_usec()-started)/1000.0," graph=",world.navigation.points.size()," edges=",world.navigation.edge_count," anchors=",world.anchors)
		expect(world.all_people().size() == 18 and world.squads.size() == 4 and world.platoons.size() == 2, "Accepted hierarchy retains16Squad personnel and2embodied Platoon leaders")
		var initial_routes := []
		var initial_reserve: Vector2 = world.squads[3].center()
		var graph_size: int = world.navigation.graph.get_point_count()
		expect(world.platoons[0].assignment == "Main effort" and world.platoons[1].assignment == "Support / reserve", "Initial Company interpretation assigns Platoon A main effort and B support/reserve")
		expect(world.anchors.MAIN.distance_to(world.anchors.SUPPORT) > 30 and world.anchors.SUPPORT.distance_to(world.anchors.RESERVE) > 30, "Generated command anchors are meaningfully separated")
		expect(world.navigation.points.size() < 1000 and world.navigation.clear_point(world.anchors.MAIN), "Navigation is bounded well below one node per meter")
		for squad in world.squads:
			print(squad.id," ",squad.movement_state," route=",squad.formation_route," start=",squad.formation_reference)
			initial_routes.append(squad.formation_route.duplicate())
			if squad.task != "Hold reserve": expect(not squad.formation_route.is_empty(), "Moving Squad finds a geography route")
		var speed_ok := true; var clearance_ok := true; var cohesion_ok := true
		for tick in range(60 * 180):
			var positions := world.all_people().map(func(person): return person.position)
			world.advance(1.0/60)
			if tick == 60 * 23: expect(world.squads[3].center() == initial_reserve, "Initial reserve holds until a higher command releases it")
			var people: Array = world.all_people()
			for i in range(people.size()):
				speed_ok = speed_ok and people[i].speed == 1.4 and people[i].position.distance_to(positions[i]) <= 1.4 / 60 + 0.0001
				for bounds in world.navigation.envelopes: clearance_ok = clearance_ok and not bounds.grow(-5.0).has_point(people[i].position)
			for squad in world.squads:
				for i in range(4): cohesion_ok = cohesion_ok and squad.soldiers[i].position.distance_to(squad.formation_reference + squad.slot(i)) < 0.16
		expect(speed_ok and clearance_ok and cohesion_ok, "Real people retain bounded speed, presentation-envelope avoidance and Squad spacing")
		expect(world.reassigned and world.trace.filter(func(record): return record.echelon == "Operational").size() == 2, "One genuine Operational reassignment propagates")
		expect(world.navigation.graph.get_point_count() == graph_size, "Route recomputation leaves no temporary graph points")
		expect(world.squads[0].route_revision == 2 and initial_routes[0] != world.squads[0].formation_route, "Main Squad recalculates route for changed objective")
		var main: Dictionary = world.platoons.filter(func(platoon): return platoon.assignment == "Main effort")[0]
		var reserve: Dictionary = world.platoons.filter(func(platoon): return platoon.assignment != "Main effort")[0]
		expect(reserve.squads[1].movement_state == "HOLDING", "Current Company reserve remains staged rather than patrolling")
		expect(main.squads.all(func(squad): return squad.movement_state == "ARRIVED") and reserve.squads[0].movement_state == "ARRIVED", "Moving formations reach assigned destinations and stop")
		var repeat = make_world(seed_value)
		expect(repeat.decision_fingerprint == make_world(seed_value).decision_fingerprint, "Same geography/scenario reproduce initial logical decisions")
		expect(repeat.decision_fingerprint != make_world(seed_value, 38039).decision_fingerprint, "Scenario seed reproducibly influences generated command anchors")
		for i in range(24): repeat.advance(1.0)
		expect(repeat.reassigned and repeat.squads[0].destination == world.squads[0].destination, "Reassignment decision survives different time partitions")
		var fixed_repeat = make_world(seed_value)
		for i in range(24 * 60): fixed_repeat.advance(1.0/60)
		expect(JSON.stringify(Layout.canonical(fixed_repeat.squads.map(func(squad):return squad.formation_route))) == JSON.stringify(Layout.canonical(world.squads.map(func(squad):return squad.formation_route))), "Identical fixed-step initial state reproduces reassignment route choices")
		var lost = repeat.squads[0].soldiers[0]
		lost.position += Vector2(-6, 0)
		var reference: Vector2 = repeat.squads[0].formation_reference
		var prior: Vector2 = lost.position
		repeat.advance(1.0/60)
		expect(lost.position.distance_to(prior) <= 1.4/60 + 0.0001 and repeat.squads[0].formation_reference == reference, "Excess separation pauses reference and corrects through ordinary Soldier movement")
		evidence.append({"seed":seed_value,"decision_fingerprint":world.decision_fingerprint,"anchors":world.anchors,"initial_routes":initial_routes,"final_routes":world.squads.map(func(squad):return squad.formation_route),"states":world.squads.map(func(squad):return squad.movement_state),"state_history":world.squads.map(func(squad):return squad.movement_history),"trace":world.trace,"graph_nodes":graph_size,"graph_edges":world.navigation.edge_count})
	print("AUTONOMY CHECKS ",checks," failures: ",failures)
	if "--visual" in OS.get_cmdline_user_args(): await visual_run()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/aut038"))
	var report_name := "checks_native.json" if "--visual" in OS.get_cmdline_user_args() else "checks.json"
	var file := FileAccess.open("res://artifacts/aut038/" + report_name, FileAccess.WRITE)
	file.store_string(JSON.stringify(Layout.canonical({"checks":checks,"failures":failures,"evidence":evidence,"native_model_update_us":model_update_us,"native_reassignment_update_us":reassignment_update_us}),"\t")); file.close()
	print("AUTONOMY COMPLETE ",checks," failures: ",failures)
	quit(0 if failures.is_empty() else 1)

func advance_view(view, seconds: float) -> void:
	for i in range(roundi(seconds * 60)):
		var before: float = view.elapsed
		view.advance_models(1.0/60)
		model_update_us.append(view.update_us)
		if view.update_us > 2000: slow_updates.append({"world_time":view.elapsed,"update_us":view.update_us,"route_queries":view.world.navigation.route_queries})
		if before < 24 and view.elapsed >= 24: reassignment_update_us = view.update_us
	# This capture harness disables normal _process; refresh its throttled HUD
	# explicitly after diagnostic stepping so captions match authoritative time.
	view.refresh_debug()

func capture(label: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/aut038/" + label + ".png")

func visual_run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/aut038"))
	var view = load("res://representative_sector.tscn").instantiate(); root.add_child(view)
	view.paused = true; view.set_process(false); view.set_process_unhandled_input(false); view.set_process_unhandled_key_input(false)
	var fingerprint: String = view.layout.fingerprint
	var generations: int = view.generation_count
	var graph_size: int = view.world.navigation.graph.get_point_count()
	expect(view.people.size() == 18 and view.visuals.size() == 18 and not view.debug_enabled, "Native scene binds18embodied people through accepted SoldierVisual with clean default")
	await capture("01_clean_initial_local")
	advance_view(view, 12)
	expect(view.visuals[0].clip_name == "standing_walk" and view.visuals[16].clip_name == "standing_walk", "Squad personnel and separate Platoon leader animate actual movement")
	await capture("02_clean_local_walking")
	view.camera.position = view.world.squads[0].center() * 32
	view.camera.zoom = Vector2.ONE * 2.0; view.zoom_target = 2.0
	view.clamp_camera(); view.update_activation()
	await capture("08_max_zoom_animated_squad")
	view.camera.position = (view.layout.village + Vector2(60, 30)) * 32; view.set_mode("tactical"); view.toggle_debug()
	await capture("03_tactical_hierarchy_before_reassignment")
	advance_view(view, 12.1)
	expect(view.world.reassigned and view.world.squads[0].movement_history.any(func(event): return event.state == "REASSIGNED"), "Native scene physically advances through high-level reassignment")
	expect(view.status.text.contains("Redirect main formation"), "Diagnostic capture HUD reports the current authoritative assignment")
	await capture("04_tactical_reassignment_routes")
	view.toggle_debug(); await capture("05_clean_tactical_reassigned")
	advance_view(view, 11.9)
	view.camera.position = view.world.squads[0].center() * 32; view.set_mode("local")
	await capture("06_local_redirected_formation")
	advance_view(view, 104)
	view.camera.position = (view.world.anchors.SUPPORT + Vector2(-5, 0)) * 32; view.set_mode("tactical"); view.toggle_debug()
	await capture("07_arrived_formations")
	expect(view.layout.fingerprint == fingerprint and view.generation_count == generations and view.world.navigation.graph.get_point_count() == graph_size, "Autonomy and debug leave deterministic composition/generation/graph size unchanged")
	print("NATIVE AUTONOMY world_time=",view.elapsed," people=",view.people.size()," update_us=",view.update_us," route_queries=",view.world.navigation.route_queries)
	model_update_us.sort()
	evidence.append({"native_world_time":view.elapsed,"native_people":view.people.size(),"model_update_us_p50":model_update_us[int(model_update_us.size()*.5)],"model_update_us_p95":model_update_us[int(model_update_us.size()*.95)],"model_update_us_max":model_update_us.back(),"reassignment_update_us":reassignment_update_us,"slow_updates":slow_updates,"generation":view.generation_count,"fingerprint":view.layout.fingerprint,"cap":Engine.max_fps})
	model_update_us.clear()
	view.free()
