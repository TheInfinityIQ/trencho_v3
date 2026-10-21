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
	var model = Scenario.new(false, true, true, false, true, true)
	model.combat.encounter_over = true
	return model

func hit(model, identity: String) -> void:
	var actors: Array = []
	var solids: Array[Rect2] = []
	Artillery.new().blast(model.vehicles.infrastructure[identity].position, model.elapsed, actors, solids, model.combat)

func run() -> void:
	var model = fixture()
	var network = model.vehicles
	var road: Dictionary = network.infrastructure["RoadSegment-A"]
	var bridge: Dictionary = network.infrastructure["Bridge-A"]
	var segment: Dictionary = network.edges[0]
	var intact_cost: float = network.edge_cost(segment, "ROAD_ONLY")
	expect(road.id == "RoadSegment-A" and road.state == "INTACT" and bridge.id == "Bridge-A" and bridge.state == "INTACT", "Persistent road and crossing identities start intact")
	expect("crossing_exit" in network.plan("depot", "resupply", "ROAD_ONLY", {}) and "road_southwest" not in network.plan("depot", "resupply", "ROAD_ONLY", {}), "Cost-based intact planner chooses short road/crossing route")
	step(model, 7)
	var start: Vector2 = network.truck.position
	step(model, 0.5)
	var intact_distance: float = start.distance_to(network.truck.position)
	expect(absf(intact_distance - 24) < 0.01 and network.truck.route_state == "MOVING", "Actual truck moves48units/s on intact RoadSegment-A")
	var route_before: Array = network.truck.route.duplicate()
	hit(model, "RoadSegment-A")
	expect(road.state == "DAMAGED" and network.edge_allowed(segment, "ROAD_ONLY") and absf(network.edge_speed_multiplier(segment, "ROAD_ONLY") - 0.3) < 0.000001, "Spatial damage leaves road legal at0.30speed")
	expect(absf(network.edge_cost(segment, "ROAD_ONLY") - intact_cost / 0.3) < 0.001 and network.plan("depot", "resupply", "ROAD_ONLY", {}) == route_before, "Live damaged cost updates; shared damaged approach still makes short crossing route cheapest")
	start = network.truck.position
	step(model, 0.5)
	expect(absf(start.distance_to(network.truck.position) - 7.2) < 0.01 and network.truck.route == route_before, "Existing route actually slows to14.4units/s without scenario recreation or route swap")
	var cargo: int = network.truck.inventory.BoltActionRifleAmmo
	hit(model, "Bridge-A")
	step(model, 1.0 / 60.0)
	expect(bridge.state == "DESTROYED" and not network.edge_allowed(network.edges[1], "ROAD_ONLY") and not network.edge_allowed(network.edges[1], "TRACKED"), "Destroyed bridge is unavailable to both mobility classes")
	expect(network.truck.route_state == "REPLAN_RETURN" and network.truck.blocked_reason.contains("Infrastructure"), "Already-computed route is explicitly invalidated before crossing")
	expect(model.supply.delivered_at < 0 and network.truck.inventory.BoltActionRifleAmmo == cargo and network.truck.route_state != "ARRIVED", "Invalidation neither delivers cargo nor reports arrival")
	var truck_route: Array[String] = network.plan("depot", "resupply", "ROAD_ONLY", {})
	var tracked_route: Array[String] = network.plan("depot", "resupply", "TRACKED", {})
	expect("road_southwest" in truck_route and "offroad_west" not in truck_route and "offroad_west" in tracked_route, "Updated planner chooses legal road detour versus advantageous tracked-only bypass")
	network.truck.faction = "enemy"
	expect(network.plan("depot", "resupply", network.truck.mobility_class, {}) == truck_route and not network.legal_position(Vector2(260, 210), "ROAD_ONLY"), "Faction change cannot grant truck off-road permission")
	network.truck.faction = "friendly"
	var engineering = model.engineering
	var engineer = engineering.people[0]
	var repair: Dictionary = engineering.assign_repair(engineer, road.id, model.elapsed)
	expect(not repair.is_empty() and repair.activity == "RepairRoad" and engineering.stockpile.inventory.BuildingMaterial == 2 and engineering.reserved_material() == 2, "Qualified physical Toolkit holder reserves2from explicit4repair stock")
	var legal := true
	var physical := true
	var no_crossing := true
	var tracked_offroad := false
	var conserved := true
	while repair.state != "COMPLETE" and model.elapsed < 40:
		var previous: Vector2 = network.truck.position
		model.advance(1.0 / 60.0)
		legal = legal and network.legal_position(network.truck.position, "ROAD_ONLY") and network.legal_position(network.tracked.position, "TRACKED")
		physical = physical and previous.distance_to(network.truck.position) <= network.truck.speed / 60.0 + 0.001
		no_crossing = no_crossing and network.truck.current_node != "crossing_exit"
		tracked_offroad = tracked_offroad or not network.legal_position(network.tracked.position, "ROAD_ONLY")
		conserved = conserved and model.total_ammunition() == 35
	expect(repair.state == "COMPLETE" and repair.progress == 4 and road.state == "INTACT" and engineering.stockpile.inventory.BuildingMaterial == 2 and engineering.reserved_material() == 0 and engineering.consumed == 2, "Four eligible worldseconds repair same road and consume exactly2material")
	expect(engineering.has_tool(engineer, "EngineerToolkit") and absf(network.edge_cost(segment, "ROAD_ONLY") - intact_cost) < 0.001 and network.edge_speed_multiplier(segment, "ROAD_ONLY") == 1, "Reusable Toolkit remains; live road cost/speed restore to intact values")
	# Repair completes while the truck is again on the shared approach. Measure the
	# same persistent truck reading the restored multiplier, with no route injection.
	start = network.truck.position
	step(model, 0.5)
	expect(network.truck.current_node == "depot" and absf(start.distance_to(network.truck.position) - 24) < 0.01, "Same truck physically returns to48units/s after road repair")
	while network.truck.route_state != "ARRIVED" and model.elapsed < 70:
		var previous: Vector2 = network.truck.position
		model.advance(1.0 / 60.0)
		legal = legal and network.legal_position(network.truck.position, "ROAD_ONLY") and network.legal_position(network.tracked.position, "TRACKED")
		physical = physical and previous.distance_to(network.truck.position) <= network.truck.speed / 60.0 + 0.001
		no_crossing = no_crossing and network.truck.current_node != "crossing_exit"
		tracked_offroad = tracked_offroad or not network.legal_position(network.tracked.position, "ROAD_ONLY")
		conserved = conserved and model.total_ammunition() == 35
	expect(legal and physical and no_crossing and tracked_offroad, "Every sampled truck step stays physical/on roads and never crosses destroyed bridge; carrier uses off-road bypass")
	expect(network.truck.route_state == "ARRIVED" and "road_southwest" in network.truck.route and model.supply.delivered_at >= 0 and network.truck.inventory.BoltActionRifleAmmo == 0 and conserved, "Only genuine legal arrival triggers conserved cargo delivery")
	expect(bridge.state == "DESTROYED" and network.infrastructure[bridge.id] == bridge, "Destroyed crossing record/geometry persist after legal arrival")
	expect(engineering.assign_repair(engineer, bridge.id, model.elapsed).is_empty() and engineering.failures.back().reason == "REQUIRES_REBUILD", "Road repair cannot rebuild destroyed bridge")
	network.repair_road(bridge.id, model.elapsed, engineer.id, "invalid bridge repair")
	expect(bridge.state == "DESTROYED", "Infrastructure road-repair mutation boundary also rejects bridge targets")
	expect(engineering.assign_repair(engineer, road.id, model.elapsed).is_empty() and engineering.failures.back().reason.contains("unnecessary"), "Intact road rejects unnecessary repair")
	expect(network.infrastructure_history.map(func(event): return event.event) == ["road damaged", "bridge destroyed", "road repaired"] and network.infrastructure_history.all(func(event): return event.has("time") and event.has("source") and event.has("cause")), "Infrastructure history preserves IDs, world times and sources/causes")
	expect(model.information.query(bridge.position).is_empty(), "Infrastructure history does not become HQ inquiry evidence")
	var failures_model = fixture()
	hit(failures_model, "RoadSegment-A")
	var eng = failures_model.engineering
	var qualified = eng.people[0]
	var unqualified = eng.people[1]
	eng.tools[1].holder = unqualified.id
	expect(eng.assign_repair(unqualified, "RoadSegment-A", 0).is_empty(), "Unqualified Toolkit holder cannot repair road")
	expect(eng.assign_repair(qualified, "RoadSegment-A", 0).is_empty(), "Qualified person without Toolkit cannot repair road")
	eng.tools[1].holder = qualified.id
	eng.stockpile.inventory.BuildingMaterial = 1
	expect(eng.assign_repair(qualified, "RoadSegment-A", 0).is_empty() and eng.reserved_material() == 0, "Insufficient material prevents road repair reservation")
	eng.stockpile.inventory.BuildingMaterial = 4
	var job: Dictionary = eng.assign_repair(qualified, "RoadSegment-A", 0)
	step(failures_model, 1)
	expect(job.progress == 0 and job.failure_reason == "Outside work radius", "Out-of-range road repair earns no labor")
	qualified.path.clear()
	qualified.position = eng.repair_target("RoadSegment-A").position
	step(failures_model, 1)
	var progress: float = job.progress
	qualified.position += Vector2(40, 0)
	step(failures_model, 1)
	expect(job.progress == progress and failures_model.vehicles.infrastructure["RoadSegment-A"].state == "DAMAGED", "Leaving road work range pauses incomplete repair")
	var impossible = fixture()
	impossible.vehicles.edges = impossible.vehicles.edges.filter(func(edge): return edge.id != "south-road")
	step(impossible, 7)
	hit(impossible, "Bridge-A")
	step(impossible, 15)
	expect(impossible.vehicles.truck.route_state == "NO_LEGAL_ROUTE" and impossible.supply.delivered_at < 0 and impossible.vehicles.truck.inventory.BoltActionRifleAmmo == 8, "Destroyed crossing without road detour yields genuine failure and retained cargo")
	var beyond = fixture()
	step(beyond, 11.3)
	expect(beyond.vehicles.truck.current_node == "crossing_exit", "Late-destruction fixture is physically beyond crossing before impact")
	var beyond_position: Vector2 = beyond.vehicles.truck.position
	hit(beyond, "Bridge-A")
	step(beyond, 0.1)
	expect(beyond.vehicles.truck.position.distance_to(beyond_position) < 5 and beyond.vehicles.truck.position.x >= beyond_position.x, "Vehicle already beyond crossing is not teleported backward by later destruction")
	var entry = fixture()
	while entry.vehicles.truck.current_node != "junction" and entry.elapsed < 15:
		entry.advance(1.0 / 60.0)
	var entry_position: Vector2 = entry.vehicles.truck.position
	hit(entry, "Bridge-A")
	step(entry, 1.0 / 60.0)
	expect(entry.vehicles.truck.position == entry_position and entry.vehicles.truck.route_state == "BLOCKED", "Destruction exactly before entry prevents any movement onto crossing")
	var mid = fixture()
	step(mid, 10.2)
	var mid_position: Vector2 = mid.vehicles.truck.position
	hit(mid, "Bridge-A")
	step(mid, 1)
	expect(mid.vehicles.truck.current_node == "junction" and mid.vehicles.truck.position == mid_position and mid.vehicles.truck.route_state == "NO_LEGAL_ROUTE", "Crossing destroyed under vehicle gives explicit hold, with no onward traversal or teleport")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/road_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "infrastructure": network.infrastructure, "history": network.infrastructure_history, "vehicle_events": network.events, "truck_route": network.truck.route, "tracked_route": network.tracked.route, "repair": repair, "ledger": engineering.ledger, "intact_cost": intact_cost, "damaged_multiplier": network.DAMAGED_SPEED, "edges": network.edge_diagnostics("ROAD_ONLY")}, "\t"))
	output.close()
	print("ROAD CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/road_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Road graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture()
	view.view_mode = "battlefield"
	root.add_child(view)
	await create_timer(7.0).timeout
	await capture("intact_short_route")
	hit(view.model, "RoadSegment-A")
	await create_timer(0.5).timeout
	await capture("damaged_road_slows")
	hit(view.model, "Bridge-A")
	await capture("bridge_destroyed_route_invalidated")
	var repair: Dictionary = view.model.engineering.assign_repair(view.model.engineering.people[0], "RoadSegment-A", view.model.elapsed)
	await create_timer(1).timeout
	await capture("return_to_safe_node")
	while repair.progress < 1 and view.model.elapsed < 25:
		await create_timer(0.1).timeout
	await capture("engineer_road_repair")
	while repair.state != "COMPLETE" and view.model.elapsed < 30:
		await create_timer(0.1).timeout
	await capture("road_repaired_normal_cost")
	while view.model.vehicles.legal_position(view.model.vehicles.tracked.position, "ROAD_ONLY") and view.model.elapsed < 35:
		await create_timer(0.1).timeout
	await create_timer(0.25).timeout
	await capture("road_detour_vs_tracked_bypass")
	expect(not view.model.vehicles.legal_position(view.model.vehicles.tracked.position, "ROAD_ONLY"), "Rendered carrier physically occupies tracked-only bypass")
	while view.model.vehicles.truck.route_state != "ARRIVED" and view.model.elapsed < 70:
		await create_timer(0.1).timeout
	await capture("legal_arrival_destroyed_bridge_persists")
	expect(view.model.vehicles.infrastructure["RoadSegment-A"].state == "INTACT" and view.model.vehicles.infrastructure["Bridge-A"].state == "DESTROYED" and view.model.supply.delivered_at >= 0, "Renderer repaired road and legal arrival coexist with persistent destroyed crossing")
