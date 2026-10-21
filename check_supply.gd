extends SceneTree

const Scenario = preload("res://scenario.gd")
const Supply = preload("res://supply.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func counts(squad) -> Array:
	var result: Array = []
	for soldier in squad.soldiers:
		result.append(soldier.inventory[Supply.CATEGORY])
	return result

func capture(view, name: String) -> void:
	await create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/supply_" + name + ".png")
	print("SUPPLY VISUAL ", name, " T=", view.model.elapsed, " inventories=", counts(view.model.squads[0]), " phase=", view.model.supply.phase)

func run() -> void:
	var sharing = Scenario.new()
	var local = sharing.supply
	var donor = sharing.squads[0].soldiers[1]
	var recipient = sharing.squads[0].soldiers[0]
	expect(counts(local.squad) == [0, 6, 1, 1], "Uneven individual inventories")
	recipient.inventory[Supply.CATEGORY] = 1
	expect(donor.inventory[Supply.CATEGORY] == 6, "Changing one inventory does not alias another")
	recipient.inventory[Supply.CATEGORY] = 0
	var original: Vector2 = recipient.position
	recipient.position = donor.position + Vector2(43, 0)
	expect(not local.share(donor, recipient), "Beyond42-unit sharing radius prevents transfer")
	expect(counts(local.squad) == [0, 6, 1, 1], "Failed distant transfer changes no balances")
	recipient.position = original
	expect(local.share(donor, recipient), "Nearby compatible sharing succeeds")
	expect(counts(local.squad) == [2, 4, 1, 1] and local.carried() == 8, "Sharing conserves; donor retains four")
	expect(not local.share(donor, recipient), "Sharing does not duplicate repeated transfer")
	donor.active = false
	expect(local.carried() == 4 and local.total_accounted() == 24, "Inactive member custody remains accounted but is not living readiness")
	donor.active = true
	expect(local.compatible(recipient, "BoltActionRifleAmmo") and not local.compatible(recipient, "PistolAmmo"), "Category compatibility is explicit and faction-independent")
	var remote = Scenario.new()
	remote.supply.transfer(remote.supply.depot.id, remote.supply.depot.inventory, remote.supply.truck.id, remote.supply.truck.inventory, 8, "Delivery proximity test")
	remote.supply.truck.state = "At staging"
	remote.supply.truck.position = Supply.RESUPPLY_POSITION
	remote.supply.advance(0, 0)
	expect(remote.supply.carried() == 8 and remote.supply.truck.inventory[Supply.CATEGORY] == 8, "Distant soldiers cannot remotely unload arrived truck")
	var model = Scenario.new()
	var supply = model.supply
	var conserved := true
	var derived := true
	var held := false
	var in_transit := false
	var request_no_teleport := true
	var stage_hold := true
	var observed_stage: Array = []
	var delivery_before_ready := true
	for tick in range(2100):
		model.advance(1.0 / 60.0)
		conserved = conserved and supply.total_accounted() == 24
		var sum := 0
		for amount in counts(model.squads[0]):
			sum += int(amount)
		derived = derived and sum == supply.carried()
		if supply.phase == "Hold: ammunition shortage":
			held = true
			if observed_stage.is_empty():
				for soldier in model.squads[0].soldiers:
					observed_stage.append(soldier.position)
			for index in range(4):
				stage_hold = stage_hold and model.squads[0].soldiers[index].position.distance_to(observed_stage[index]) < 1
		if supply.requested_at >= 0 and supply.truck.state == "At depot":
			request_no_teleport = request_no_teleport and supply.carried() == 8
		if supply.truck.state == "In transit":
			in_transit = true
			request_no_teleport = request_no_teleport and supply.carried() == 8 and supply.depot.inventory[Supply.CATEGORY] == 4 and supply.truck.inventory[Supply.CATEGORY] == 8
		if supply.resumed_at >= 0:
			delivery_before_ready = delivery_before_ready and supply.delivered_at >= 0 and supply.resumed_at >= supply.delivered_at and supply.carried() >= 16
	expect(conserved, "All2100simulation samples conserve24 rounds")
	expect(derived, "Squad total always equals individual custody")
	expect(held and stage_hold and in_transit, "Shortage holds soldiers stationary while truck travels")
	expect(request_no_teleport, "Request, approval and transit do not alter carried inventory")
	expect(delivery_before_ready and supply.resumed_at >= 0, "Readiness resumes only after physical delivery")
	expect(model.secured, "Autonomous final approach still secures Objective A")
	expect(supply.depot.inventory[Supply.CATEGORY] == 4 and supply.truck.inventory[Supply.CATEGORY] == 0, "Depot-truck-soldier custody accounts for eight-round shipment")
	expect(supply.carried() == 20 and supply.captured.inventory[Supply.CATEGORY] == 0 and supply.captured_at > supply.delivered_at, "Captured four rounds recovered exactly once after supply")
	expect(supply.captured.owner.begins_with("friendly"), "Enemy container ownership changes")
	var ledger_net := {"military-depot": 12, "military-truck": 0, "enemy-ammo-container": 4, "P1-A.1": 0, "P1-A.2": 6, "P1-A.3": 1, "P1-A.4": 1}
	var capture_count := 0
	for transaction in supply.transactions:
		ledger_net[transaction.source] -= transaction.quantity
		ledger_net[transaction.destination] += transaction.quantity
		if transaction.source == "enemy-ammo-container":
			capture_count += 1
	for soldier in model.squads[0].soldiers:
		expect(ledger_net[soldier.id] == soldier.inventory[Supply.CATEGORY], "Ledger reconciles " + soldier.id)
	expect(capture_count == 1 and ledger_net["enemy-ammo-container"] == 0, "Capture cannot double spend enemy cargo")
	if "--visual" in OS.get_cmdline_user_args():
		var view = load("res://main.tscn").instantiate()
		# Keep the accepted already-military-owned supply fixture as regression.
		view.model = Scenario.new(false)
		view.view_mode = "battlefield"
		root.add_child(view)
		await capture(view, "initial")
		await create_timer(1.2).timeout
		await capture(view, "sharing")
		await create_timer(4.8).timeout
		await capture(view, "hold_request")
		await create_timer(2.0).timeout
		await capture(view, "transport")
		await create_timer(4.5).timeout
		await capture(view, "delivery_resume")
		await create_timer(9.0).timeout
		await capture(view, "capture_recovery")
		expect(view.model.supply.captured_at > 0 and view.model.supply.carried() == 20, "Real renderer reaches capture with twenty carried rounds")
	var output := FileAccess.open("res://artifacts/supply_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "final_individuals": counts(model.squads[0]), "total": supply.total_accounted(), "transactions": supply.transactions, "events": supply.events}, "\t"))
	output.close()
	print("SUPPLY CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)
