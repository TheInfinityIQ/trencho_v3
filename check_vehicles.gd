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

func capture(name: String) -> void:
	await create_timer(0.08).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/vehicle_" + name + ".png")

func run() -> void:
	var model = Scenario.new(false, false, true)
	var network = model.vehicles
	expect(network.truck.id != network.tracked.id and network.drivers[0].id != network.drivers[1].id, "Persistent independent vehicle and driver identities")
	expect(network.truck.driver == network.drivers[0] and network.tracked.driver == network.drivers[1], "Vehicle references the same persistent driver person, no duplicate")
	var walking_driver := false
	for squad in model.squads:
		for soldier in squad.soldiers:
			walking_driver = walking_driver or soldier.id.begins_with("Driver-")
	expect(not walking_driver, "Occupied driver does not simultaneously act as a separate walking soldier")
	network.tracked.inventory.BoltActionRifleAmmo = 1
	expect(network.truck.inventory.BoltActionRifleAmmo == 0, "Vehicle cargo inventories are independent")
	network.tracked.inventory.BoltActionRifleAmmo = 0
	var offroad := Vector2(260, 210)
	expect(not network.legal_position(offroad, "ROAD_ONLY") and network.legal_position(offroad, "TRACKED"), "Terrain classification admits tracked bypass and rejects road truck")
	network.truck.faction = "enemy"
	expect(not network.legal_position(offroad, network.truck.mobility_class), "Changing faction grants no off-road permission")
	network.truck.faction = "friendly"
	var road_legal := true
	var tracked_legal := true
	var conserved := true
	var blocked := false
	var replanned := false
	var no_early_delivery := true
	var tracked_offroad := false
	var truck_arrival := -1.0
	var tracked_arrival := -1.0
	var infantry_offroad_movement := false
	for tick in range(3000):
		model.advance(1.0 / 60.0)
		road_legal = road_legal and network.legal_position(network.truck.position, "ROAD_ONLY")
		tracked_legal = tracked_legal and network.legal_position(network.tracked.position, "TRACKED")
		conserved = conserved and model.total_ammunition() == 27
		for soldier in model.squads[0].soldiers:
			if soldier.travelled > 20 and not network.legal_position(soldier.position, "ROAD_ONLY"):
				infantry_offroad_movement = true
		if network.truck.route_state == "BLOCKED":
			blocked = true
			no_early_delivery = no_early_delivery and model.supply.delivered_at < 0 and model.supply.carried() == 8 and network.truck.inventory.BoltActionRifleAmmo == 8
		if network.truck.route_state == "REPLANNING":
			replanned = true
			no_early_delivery = no_early_delivery and model.supply.delivered_at < 0 and network.truck.position != network.points.resupply
		if network.tracked.route_state == "MOVING" and not network.legal_position(network.tracked.position, "ROAD_ONLY"):
			tracked_offroad = true
		if network.truck.route_state == "ARRIVED" and truck_arrival < 0:
			truck_arrival = model.elapsed
		if network.tracked.route_state == "ARRIVED" and tracked_arrival < 0:
			tracked_arrival = model.elapsed
		if model.secured:
			break
	expect(road_legal and tracked_legal, "All sampled positions obey mobility-class terrain permissions")
	expect(blocked and replanned and no_early_delivery, "Primary route fails explicitly, replan does not claim arrival/delivery")
	expect("road_southwest" in network.truck.route and "offroad_west" not in network.truck.route, "Truck selects longer legal road alternative")
	expect(tracked_offroad and "offroad_west" in network.tracked.route, "Tracked carrier materially uses off-road bypass")
	expect(network.truck.route_is_legal(network) and network.tracked.route_is_legal(network), "Final planned routes exclude blocked/illegal edges")
	expect(tracked_arrival > 0 and truck_arrival > tracked_arrival + 3, "Legal mobility classes produce distinct arrival timing")
	expect(network.truck.position == network.points.resupply and model.supply.delivered_at >= truck_arrival, "Physical position and route arrival gate delivery")
	expect(conserved and network.truck.inventory.BoltActionRifleAmmo == 0 and model.supply.carried() == 20, "Delayed shipment conserves cargo and later capture remains physical")
	expect(model.secured and infantry_offroad_movement, "Infantry remains independent of road-only restrictions")
	var unavailable = Scenario.new(false, false, true)
	unavailable.vehicles.drivers[0].active = false
	for tick in range(1800):
		unavailable.advance(1.0 / 60.0)
	expect(unavailable.vehicles.truck.position == unavailable.vehicles.points.depot and unavailable.vehicles.truck.route_state == "NO_DRIVER", "Unavailable driver prevents all truck movement")
	expect(unavailable.vehicles.truck.inventory.BoltActionRifleAmmo == 8 and unavailable.supply.carried() == 8 and unavailable.supply.delivered_at < 0, "Driver absence retains cargo without false arrival or delivery")
	var unassigned = Scenario.new(false, false, true)
	unassigned.vehicles.drivers[0].assigned_vehicle_id = "another-vehicle"
	for tick in range(1200):
		unassigned.advance(1.0 / 60.0)
	expect(unassigned.vehicles.truck.position == unassigned.vehicles.points.depot and unassigned.supply.delivered_at < 0, "Living driver assigned elsewhere cannot drive this truck")
	var impossible = Scenario.new(false, false, true)
	impossible.vehicles.edges = impossible.vehicles.edges.filter(func(edge): return edge.id != "south-road")
	for tick in range(1800):
		impossible.advance(1.0 / 60.0)
	expect(impossible.vehicles.truck.route_state == "NO_LEGAL_ROUTE" and impossible.supply.delivered_at < 0 and impossible.vehicles.truck.inventory.BoltActionRifleAmmo == 8, "No alternate road means genuine failure rather than cheating through off-road terrain")
	var integrated = Scenario.new(true, true, true)
	integrated.rear.place_workbench(Vector2(380, 480))
	integrated.rear.start_job("Avatar", 0)
	integrated.rear.set_policy("RESERVE", 8)
	for tick in range(241):
		integrated.advance(1.0 / 60.0)
	integrated.rear.assign_worker()
	var combined_conserved := true
	for tick in range(7200):
		integrated.advance(1.0 / 60.0)
		combined_conserved = combined_conserved and integrated.total_ammunition() + integrated.combat.shots.size() == 19 + integrated.rear.produced
		if integrated.secured:
			break
	expect(integrated.secured and integrated.vehicles.truck.route_state == "ARRIVED" and integrated.combat.encounter_over and combined_conserved, "Full rear/vehicle/combat integration still completes with exact shot-and-production accounting")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/vehicle_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "truck_route": network.truck.route, "tracked_route": network.tracked.route, "truck_arrival": truck_arrival, "tracked_arrival": tracked_arrival, "road_half_width": network.ROAD_HALF_WIDTH, "events": network.events}, "\t"))
	output.close()
	print("VEHICLE CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func visual_run() -> void:
	var view = load("res://main.tscn").instantiate()
	expect(view.get_script() != null, "Vehicle graphical scene script loads")
	if view.get_script() == null:
		view.free()
		return
	# Isolate the accepted military-stocked shipment for the visual mobility proof.
	view.model = Scenario.new(false, false, true)
	view.view_mode = "battlefield"
	root.add_child(view)
	var waited := 0
	while view.model.vehicles.truck.route_state != "MOVING" and waited < 200:
		await create_timer(0.05).timeout
		waited += 1
	await capture("primary_route")
	while view.model.vehicles.truck.route_state != "BLOCKED" and waited < 400:
		await create_timer(0.05).timeout
		waited += 1
	await capture("blocked")
	expect(view.model.supply.carried() == 8 and view.model.supply.delivered_at < 0, "Rendered blockage keeps cargo unavailable to squad")
	while view.model.vehicles.truck.route_state != "REPLANNING" and waited < 500:
		await create_timer(0.05).timeout
		waited += 1
	await capture("replanning")
	while view.model.vehicles.truck.current_node != "road_southwest" and waited < 800:
		await create_timer(0.05).timeout
		waited += 1
	await capture("alternate_vs_bypass")
	while view.model.vehicles.truck.route_state != "ARRIVED" and waited < 1000:
		await create_timer(0.05).timeout
		waited += 1
	await capture("arrived_delivery")
	expect(view.model.supply.delivered_at >= 0 and view.model.supply.carried() >= 16 and view.model.vehicles.tracked.route_state == "ARRIVED", "Rendered legal arrival triggers physical delivery after tracked bypass")
