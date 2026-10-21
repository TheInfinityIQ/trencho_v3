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

func hit(model) -> void:
	var actors: Array = []
	var solids: Array[Rect2] = []
	Artillery.new().blast(model.vehicles.infrastructure["Bridge-A"].position, model.elapsed, actors, solids, model.combat)

func fixture():
	var model = Scenario.new(false, true, true, false, true, true)
	model.combat.encounter_over = true
	# Explicit8unit rebuild stock (not a later grant); six consumed, two remain.
	model.engineering.stockpile.inventory.BuildingMaterial = 8
	# A focused no-road-detour case proves existing waiting truck retries when the
	# bridge reconnects. Tracked retains its legal off-road bypass.
	model.vehicles.edges = model.vehicles.edges.filter(func(edge): return edge.id != "south-road")
	hit(model)
	return model

func run() -> void:
	var model = fixture()
	var network = model.vehicles
	var engineering = model.engineering
	var bridge: Dictionary = network.infrastructure["Bridge-A"]
	var identity: String = bridge.id
	var engineer = engineering.people[0]
	var rifleman = engineering.people[1]
	var crossing: Dictionary = network.edge_between("junction", "crossing_exit")
	var original_cost: float = network.points.junction.distance_to(network.points.crossing_exit)
	var edge_count: int = network.edges.size()
	expect(bridge.state == "DESTROYED" and not network.edge_allowed(crossing, "ROAD_ONLY") and not network.edge_allowed(crossing, "TRACKED"), "Destroyed Bridge-A is initially impassable to both mobility classes")
	step(model, 7)
	expect(network.truck.route_state == "NO_LEGAL_ROUTE" and model.supply.delivered_at < 0 and network.truck.inventory.BoltActionRifleAmmo == 8, "Existing loaded truck genuinely waits for connectivity without false delivery")
	engineering.tools[1].holder = rifleman.id
	expect(engineering.assign_bridge_rebuild(rifleman, identity, model.elapsed).is_empty() and not rifleman.engineer_qualified, "Toolkit holding does not grant qualification to rebuild")
	expect(engineering.assign_bridge_rebuild(engineer, identity, model.elapsed).is_empty(), "Engineer without actual Toolkit cannot rebuild")
	engineering.tools[1].holder = engineer.id
	engineering.stockpile.inventory.BuildingMaterial = 5
	expect(engineering.assign_bridge_rebuild(engineer, identity, model.elapsed).is_empty() and engineering.reserved_material() == 0, "Fewer than6material cannot reserve/start rebuild")
	engineering.stockpile.inventory.BuildingMaterial = 8
	engineer.active = false
	expect(engineering.assign_bridge_rebuild(engineer, identity, model.elapsed).is_empty(), "Inactive qualified Engineer cannot start rebuild")
	engineer.active = true
	var job: Dictionary = engineering.assign_bridge_rebuild(engineer, identity, model.elapsed)
	expect(not job.is_empty() and job.duration == 8 and engineering.stockpile.inventory.BuildingMaterial == 2 and engineering.reserved_material() == 6 and engineering.consumed == 0, "Valid rebuild reserves exclusive6of8and requires8eligible labor seconds")
	expect(bridge.state == "UNDER_RECONSTRUCTION" and not network.edge_allowed(crossing, "ROAD_ONLY") and not network.edge_allowed(crossing, "TRACKED"), "Assignment marks construction but restores no connectivity")
	expect(engineering.assign_bridge_rebuild(engineer, identity, model.elapsed).is_empty() and not engineering.reserve_material("SecondBridge", 6, model.elapsed) and engineering.jobs.size() == 1, "Same bridge/person and held6cannot fund duplicate job/reservation")
	step(model, 1)
	expect(job.progress == 0 and engineer.position != engineer.origin and job.failure_reason == "Outside work radius", "Engineer physically approaches with no out-of-range bridge labor")
	while job.progress < 1 and model.elapsed < 30:
		model.advance(1.0 / 60.0)
	var progress: float = job.progress
	engineer.path.clear()
	engineer.position = bridge.position + Vector2(-40, 0)
	step(model, 1)
	expect(job.progress == progress and job.failure_reason == "Outside work radius", "Leaving bridge work range pauses partial construction")
	engineer.position = bridge.position
	engineering.tools[1].holder = engineering.stockpile.id
	step(model, 1)
	expect(job.progress == progress and job.failure_reason.contains("EngineerToolkit"), "Toolkit loss pauses bridge labor")
	engineering.tools[1].holder = engineer.id
	engineer.engineer_qualified = false
	step(model, 1)
	expect(job.progress == progress and job.failure_reason.contains("qualification"), "Qualification loss pauses bridge labor independently")
	engineer.engineer_qualified = true
	engineering.reservations[job.id] = 5
	step(model, 1)
	expect(job.progress == progress and job.failure_reason.contains("reservation"), "Invalid held reservation blocks bridge labor")
	engineering.reservations[job.id] = 6
	step(model, 7.99 - progress)
	expect(job.progress < 8 and bridge.state == "UNDER_RECONSTRUCTION" and network.truck.current_node == "depot" and model.supply.delivered_at < 0 and not network.edge_allowed(crossing, "ROAD_ONLY"), "7.99eligible seconds leave waiting truck unable to cross partial bridge")
	step(model, 0.01)
	expect(job.state == "COMPLETE" and bridge.state == "INTACT" and bridge.id == identity and network.infrastructure.size() == 2 and network.edges.size() == edge_count, "Full8seconds restore same Bridge-A and original edge without duplication")
	expect(engineering.stockpile.inventory.BuildingMaterial == 2 and engineering.reserved_material() == 0 and engineering.consumed == 6 and engineering.has_tool(engineer, "EngineerToolkit"), "Completion consumes exactly6and retains Toolkit")
	expect(network.edge_allowed(crossing, "ROAD_ONLY") and network.edge_allowed(crossing, "TRACKED") and absf(network.edge_cost(crossing, "ROAD_ONLY") - original_cost) < 0.001, "Current legality and original crossing cost restore dynamically")
	expect("crossing_exit" in network.plan("depot", "resupply", "ROAD_ONLY", {}), "Cost-based route evaluation chooses rebuilt short crossing")
	var crossed := false
	var legal := true
	var physical := true
	while network.truck.route_state != "ARRIVED" and model.elapsed < 70:
		var before: Vector2 = network.truck.position
		model.advance(1.0 / 60.0)
		crossed = crossed or network.truck.current_node == "crossing_exit"
		legal = legal and network.legal_position(network.truck.position, "ROAD_ONLY")
		physical = physical and before.distance_to(network.truck.position) < 0.81
	expect(crossed and legal and physical and network.truck.route_state == "ARRIVED" and "crossing_exit" in network.truck.route, "Same previously-waiting truck observes revision, replans and physically traverses restored bridge")
	expect(model.supply.delivered_at >= 0 and network.truck.inventory.BoltActionRifleAmmo == 0, "Delivery occurs only after genuine crossing and destination arrival")
	expect(engineering.assign_bridge_rebuild(engineer, identity, model.elapsed).is_empty() and engineering.jobs.size() == 1, "Intact Bridge-A rejects unnecessary/duplicate rebuild")
	expect(network.infrastructure_history.map(func(event): return event.event) == ["bridge destroyed", "reconstruction started", "reconstruction completed"], "Destruction and rebuild history coexist on same infrastructure identity")
	expect(model.information.query(bridge.position).is_empty(), "Bridge rebuild does not reveal omniscient HQ history")
	var interrupted = fixture()
	var eng = interrupted.engineering
	var builder = eng.people[0]
	var interrupted_bridge: Dictionary = interrupted.vehicles.infrastructure[identity]
	builder.position = interrupted_bridge.position
	var paused: Dictionary = eng.assign_bridge_rebuild(builder, identity, interrupted.elapsed)
	step(interrupted, 3)
	expect(absf(paused.progress - 3) < 0.000001 and interrupted_bridge.state == "UNDER_RECONSTRUCTION", "Interrupted-build fixture earns actual3seconds first")
	hit(interrupted)
	expect(paused.progress == 0 and paused.state == "INTERRUPTED" and interrupted_bridge.state == "DESTROYED" and eng.reserved_material() == 6 and eng.consumed == 0 and eng.stockpile.inventory.BuildingMaterial == 2, "Real destructive blast resets progress, destroys construction and holds original6without consumption/refund")
	step(interrupted, 5)
	expect(paused.progress == 0 and interrupted_bridge.state == "DESTROYED", "Interrupted job never automatically restarts or restores route")
	expect(eng.assign_bridge_rebuild(builder, identity, interrupted.elapsed).is_empty() and eng.jobs.size() == 1, "Interrupted held job prevents duplicate replacement/reservation")
	eng.tools[1].holder = eng.stockpile.id
	expect(not eng.resume_bridge_rebuild(paused.id, interrupted.elapsed), "Explicit resume still requires actual Toolkit eligibility")
	eng.tools[1].holder = builder.id
	expect(eng.resume_bridge_rebuild(paused.id, interrupted.elapsed) and eng.jobs.size() == 1 and eng.ledger.size() == 1 and eng.reserved_material() == 6 and interrupted_bridge.state == "UNDER_RECONSTRUCTION", "PA-BRG-007 explicit fixture resume reuses same job/reservation without new charge")
	step(interrupted, 7.99)
	expect(interrupted_bridge.state == "UNDER_RECONSTRUCTION" and paused.progress < 8, "Resumed job requires fresh full8seconds, not pre-blast labor credit")
	step(interrupted, 0.01)
	expect(interrupted_bridge.state == "INTACT" and paused.state == "COMPLETE" and eng.ledger.size() == 2 and eng.consumed == 6 and eng.stockpile.inventory.BuildingMaterial == 2, "Resumed completion consumes held6exactly once and restores same bridge")
	expect(interrupted.vehicles.infrastructure_history.map(func(event): return event.event) == ["bridge destroyed", "reconstruction started", "reconstruction interrupted", "reconstruction resumed", "reconstruction completed"], "Interrupted reconstruction history remains attached through explicit recovery")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/bridge_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "bridge": bridge, "history": network.infrastructure_history, "job": job, "ledger": engineering.ledger, "vehicle_events": network.events, "interrupted_history": interrupted.vehicles.infrastructure_history, "interrupted_job": paused, "interrupted_ledger": eng.ledger}, "\t"))
	output.close()
	print("BRIDGE CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/bridge_" + name + ".png")

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Bridge graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	view.model = fixture()
	view.view_mode = "battlefield"
	root.add_child(view)
	await create_timer(7).timeout
	await capture("destroyed_truck_waiting")
	var eng = view.model.engineering
	var job: Dictionary = eng.assign_bridge_rebuild(eng.people[0], "Bridge-A", view.model.elapsed)
	await create_timer(0.5).timeout
	await capture("approach_reserved_material")
	while job.progress < 1 and view.model.elapsed < 25:
		await create_timer(0.05).timeout
	await capture("partial_bridge_still_closed")
	expect(not view.model.vehicles.edge_allowed(view.model.vehicles.edge_between("junction", "crossing_exit"), "ROAD_ONLY"), "Renderer partial rebuild keeps truck crossing closed")
	hit(view.model)
	await capture("blast_interrupted_held_reservation")
	await create_timer(0.3).timeout
	eng.resume_bridge_rebuild(job.id, view.model.elapsed)
	await create_timer(0.6).timeout
	await capture("same_job_explicit_resume")
	while job.state != "COMPLETE" and view.model.elapsed < 40:
		await create_timer(0.05).timeout
	await capture("same_bridge_restored_connectivity")
	while view.model.vehicles.truck.current_node != "junction" and view.model.elapsed < 55:
		await create_timer(0.05).timeout
	await create_timer(0.4).timeout
	await capture("truck_physically_on_rebuilt_crossing")
	while view.model.vehicles.truck.route_state != "ARRIVED" and view.model.elapsed < 65:
		await create_timer(0.05).timeout
	await capture("arrival_and_reconstruction_history")
	expect(view.model.vehicles.infrastructure["Bridge-A"].state == "INTACT" and view.model.supply.delivered_at >= 0 and eng.consumed == 6 and eng.jobs.size() == 1, "Renderer interruption/resume restores same bridge and waiting truck delivers after physical traversal")
