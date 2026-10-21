extends "res://operations.gd"

const Supply = preload("res://supply.gd")
const VehicleRoutes = preload("res://vehicle_routes.gd")
const RequestContext = preload("res://request_context.gd")

func _init() -> void:
	super._init()
	world.rear.multi_enabled = true
	world.supply.request_id = "Request-A"
	world.rear.register_request("Request-A", world.squads[0].id)
	# Authored second demand uses the existing support formation's mission and
	# ordinary staging/readiness/physical handoff logic, not UI fulfillment counters.
	var second = Supply.new(world.squads[1], true, true)
	second.request_id = "Request-B"
	second.depot.id = "military-depot-B"
	second.captured.id = "captured-cache-B"
	second.truck.id = "military-truck-B"
	var routes = VehicleRoutes.new(second)
	for driver in routes.drivers:
		driver.id = "B-" + driver.id
	routes.tracked.id = "B-" + routes.tracked.id
	routes.tracked.driver.assigned_vehicle_id = routes.tracked.id
	world.additional_supplies.append(second)
	world.additional_vehicle_routes.append(routes)
	world.rear.register_request("Request-B", world.squads[1].id)
	# Both formations physically carry8 against the accepted16 threshold. Enemy
	# contacts begin beyond staging, so no pre-request shot changes either deficit.
	world.squads[0].soldiers[0].inventory.BoltActionRifleAmmo = 8
	var guard = world.combat.defenders.soldiers[0]
	guard.position = Vector2(790, 420)
	guard.origin = guard.position
	initial_ammo = world.total_ammunition()
	world.rear.sync_requests([world.supply] + world.additional_supplies)
	RequestContext.capture_assignments(world)
	alerts = Alerts.new(world)

func advance(delta: float) -> void:
	super.advance(delta)
	if not world.information.reconstructing:
		RequestContext.capture_assignments(world)

func set_priority(identity: String, value := "PRIORITY") -> bool:
	return world.battle_active() and world.rear.set_request_priority(identity, value)
