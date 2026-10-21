extends SceneTree

const Ops = preload("res://operations.gd")
const Codec = preload("res://checkpoint.gd")
var checks := 0
var failures: Array[String] = []
var evidence: Array = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func step(ops, duration: float) -> void:
	var remaining := duration
	while remaining > 0.0000001:
		var delta := minf(remaining, 1.0 / 60.0)
		ops.advance(delta)
		remaining -= delta

func prepared():
	var ops = Ops.new()
	ops.world.rear.place_workbench(Vector2(380, 480))
	return ops

func crate() -> Dictionary:
	return {"id": "FiniteMetalCrate-01", "owner": "rear", "position": Vector2(175, 230), "inventory": {"Metal": 2}}

func finish_batch(ops) -> void:
	var rear = ops.world.rear
	while rear.job.is_empty() and ops.world.elapsed < 60:
		ops.advance(1.0 / 60.0)
	var before: int = rear.produced
	var deadline: float = rear.job.finishes_at
	step(ops, deadline - ops.world.elapsed - 0.001)
	expect(rear.produced == before and not rear.job.is_empty(), "No early output before four world seconds")
	step(ops, 0.001)
	expect(rear.produced == before + 8 and rear.job.is_empty(), "One timed batch finishes exactly once at deadline")

func run() -> void:
	for count in [1, 2, 3]:
		var ops = prepared()
		var rear = ops.world.rear
		expect(not rear.assign_worker(0) and not rear.assign_worker(4), "Reject counts outside finite1–3")
		expect(rear.assign_worker(count, ops.world.elapsed) and not rear.assign_worker(count), "Explicit order accepted once, overlapping assignment rejected")
		expect(rear.metal == 4 and rear.production_order.requested == count and rear.production_order.completed == 0, "Assignment records requested count without upfront input charge")
		expect(rear.production_order.assigned_worker == "Worker-01" and rear.production_order.assigned_workstation == "AmmoWorkbench-01" and rear.production_order.recipe == "Metal1_to_Ammo8", "Plain order metadata identifies recipe/Worker/workstation")
		for batch in range(count):
			finish_batch(ops)
			expect(rear.metal == 4 - batch - 1 and rear.produced == 8 * (batch + 1) and rear.production_order.completed == batch + 1, "Each completed batch consumes only its own input and counts once")
			if batch < count - 1:
				expect(rear.production_order.status == "QUEUED" and rear.worker.batches_remaining == count - batch - 1, "Next batch remains finite and uncharged at completion boundary")
		expect(rear.production_order.status == "COMPLETED" and not rear.worker.assigned and ops.situation().work.future_batches == 0, "Exact N completes and releases Worker without repeat")
		step(ops, 15)
		expect(rear.produced == count * 8 and rear.metal == 4 - count and rear.job.is_empty(), "Waiting cannot overrun or repeat completed order")
		expect(rear.policy == "LOCKED" and rear.committed == 0 and rear.shipment.cargo == 0 and ops.situation().need.delivered == 0, "Worker output never authorizes, exports, or satisfies military request")
		var codec = Codec.new()
		var roundtrip = codec.unpack(JSON.parse_string(JSON.stringify(codec.pack(rear.production_order), "", true, true)))
		expect(roundtrip == rear.production_order, "Order metadata roundtrips as plain typed values")
		evidence.append(rear.production_order.duplicate(true))
	var blocked = prepared()
	var rear = blocked.world.rear
	rear.metal = 1
	var delivery := crate()
	rear.assign_worker(3)
	finish_batch(blocked)
	step(blocked, 3)
	var identity: String = rear.production_order.id
	expect(rear.production_order.status == "BLOCKED_INPUT" and rear.production_order.completed == 1 and rear.metal == 0 and rear.produced == 8, "Input exhaustion retains completed work and same pending order")
	expect(rear.metal + delivery.inventory.Metal + rear.produced / 8 == 3 and ops_snapshot(blocked).work.state.contains("MISSING_METAL"), "Nearby crate is not eligible raw input and UI explains block")
	var history_size: int = rear.order_history.size()
	step(blocked, 2)
	expect(rear.order_history.size() == history_size and rear.produced == 8 and rear.metal == 0, "Blocked waiting does not spam history or create input/output")
	delivery.owner = "military"
	expect(not rear.receive_metal(delivery, 2, blocked.world.elapsed), "Foreign custody cannot silently become raw input")
	delivery.owner = "rear"
	delivery.position = Vector2(500, 500)
	expect(not rear.receive_metal(delivery, 2, blocked.world.elapsed), "Crate outside physical raw store cannot be received")
	delivery.position = Vector2(175, 230)
	expect(not rear.receive_metal(delivery, 3, blocked.world.elapsed), "Receipt cannot exceed finite crate contents")
	expect(rear.receive_metal(delivery, 2, blocked.world.elapsed) and delivery.inventory.Metal == 0 and rear.metal == 2, "Exact2 Metal transfers from crate to raw custody")
	expect(not rear.receive_metal(delivery, 2, blocked.world.elapsed) and rear.ledger[-1].source == delivery.id and rear.ledger[-1].quantity == 2, "Receipt cannot duplicate depleted crate and retains provenance")
	blocked.advance(1.0 / 60.0)
	expect(rear.production_order.id == identity and rear.production_order.status == "ACTIVE" and rear.metal == 1, "Same blocked order resumes automatically only after eligible receipt")
	finish_batch(blocked)
	finish_batch(blocked)
	expect(rear.produced == 24 and rear.metal == 0 and delivery.inventory.Metal == 0 and rear.production_order.status == "COMPLETED", "Finite3 Metal becomes exactly24 rounds through ordinary batches")
	for requirement in ["capability_unlocked", "placed", "eligible"]:
		var gated = prepared()
		gated.world.rear.assign_worker(2)
		finish_batch(gated)
		if requirement == "eligible":
			gated.world.rear.worker.eligible = false
		else:
			gated.world.rear.set(requirement, false)
		step(gated, 5)
		expect(gated.world.rear.production_order.status == "BLOCKED_REQUIREMENT" and gated.world.rear.produced == 8 and gated.world.rear.metal == 3, "Capability/bench/Worker is rechecked before each batch: " + requirement)
		if requirement == "eligible":
			gated.world.rear.worker.eligible = true
		else:
			gated.world.rear.set(requirement, true)
		finish_batch(gated)
		expect(gated.world.rear.produced == 16 and gated.world.rear.production_order.status == "COMPLETED", "Requirement restoration automatically resumes retained order: " + requirement)
	for stop_at in ["queued", "active", "boundary", "blocked"]:
		var stopped = prepared()
		var target = stopped.world.rear
		target.assign_worker(3)
		var expected_output := 0
		if stop_at == "active":
			while target.job.is_empty():
				stopped.advance(1.0 / 60.0)
			step(stopped, 1)
			expected_output = 8
		elif stop_at in ["boundary", "blocked"]:
			finish_batch(stopped)
			expected_output = 8
			if stop_at == "blocked":
				target.metal = 0
				stopped.advance(1.0 / 60.0)
		var charged_metal: int = target.metal
		expect(target.stop_worker(stopped.world.elapsed), "Stop accepted: " + stop_at)
		if stop_at == "active":
			expect(target.production_order.status == "STOPPING" and not target.job.is_empty() and stopped.situation().work.future_batches == 0, "Active stop preserves current labor and clears future schedule")
		else:
			expect(target.production_order.status == "STOPPED" and target.job.is_empty(), "Inactive stop takes effect immediately: " + stop_at)
		step(stopped, 12)
		expect(target.produced == expected_output and target.metal == charged_metal and target.production_order.status == "STOPPED" and not target.stop_worker(), "Stop has no refund, extra batch, repeat or late output: " + stop_at)
		if stop_at != "blocked":
			var old_id: String = target.production_order.id
			expect(target.assign_worker(1) and target.production_order.id != old_id, "Later work requires explicit new order with unique ID")
	var terminal = prepared()
	terminal.world.rear.assign_worker(3)
	while terminal.world.rear.job.is_empty():
		terminal.advance(1.0 / 60.0)
	terminal.world.battle.apply_blast_damage(terminal.world.battle.hqs["Enemy-HQ"].position, terminal.world.elapsed, "test")
	terminal.world.battle.apply_blast_damage(terminal.world.battle.hqs["Enemy-HQ"].position, terminal.world.elapsed, "test")
	var frozen := JSON.stringify([terminal.world.elapsed, terminal.world.rear.job, terminal.world.rear.production_order, terminal.world.rear.metal])
	step(terminal, 10)
	expect(not terminal.world.battle_active() and terminal.world.rear.produced == 0 and JSON.stringify([terminal.world.elapsed, terminal.world.rear.job, terminal.world.rear.production_order, terminal.world.rear.metal]) == frozen and terminal.situation().work.state.begins_with("FROZEN") and terminal.situation().work.future_batches == 0, "WAR terminal freezes unfinished order/job without artificial completion")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
	var output := FileAccess.open("res://artifacts/worker_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "orders": evidence}, "\t", true, true))
	print("WORKER CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func ops_snapshot(ops) -> Dictionary:
	return ops.situation()

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
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
	root.get_texture().get_image().save_png("res://artifacts/worker_" + name + ".png")

func visual_run() -> void:
	var view = load("res://operations.tscn").instantiate()
	root.add_child(view)
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	await capture("01_normal_count_three_setup")
	expect(view.batch_count.value == 3 and view.model.rear.metal == 4, "Normal count selector chooses3 without spending original Metal4")
	click(Vector2(1030, 680))
	await process_frame
	expect(view.model.rear.production_order.requested == 3, "Normal assign button creates selected finite3 order")
	while view.model.rear.job.is_empty() and view.model.elapsed < 5:
		await create_timer(0.1).timeout
	await capture("02_normal_active_first_batch")
	var start: float = view.model.elapsed
	key(KEY_TAB)
	await create_timer(1).timeout
	await capture("03_field_attention_same_clock")
	expect(view.view_mode == "battlefield" and view.model.elapsed > start + 0.8 and not view.model.rear.job.is_empty() and view.operations.situation().work.progress > 0, "Field observation releases player attention while same production clock advances")
	var original_order: String = view.model.rear.production_order.id
	key(KEY_F)
	key(KEY_X)
	await process_frame
	expect(view.model.rear.production_order.id == original_order and not view.model.rear.production_order.stop_requested, "Rear assignment/stop shortcuts cannot issue field tactical commands")
	while (view.model.rear.production_order.completed < 1 or view.model.rear.job.is_empty()) and view.model.elapsed < 10:
		await create_timer(0.05).timeout
	await capture("04_field_one_complete_second_active")
	expect(view.model.rear.production_order.completed == 1 and view.model.rear.metal == 2 and view.model.rear.produced == 8, "Second batch starts sequentially while field remains observable")
	key(KEY_B)
	await process_frame
	click(Vector2(500, 600))
	await process_frame
	expect(view.queried and view.model.rear.worker.assigned, "Inquiry remains usable while finite Worker order runs")
	while view.model.rear.production_order.status != "COMPLETED" and view.model.elapsed < 20:
		await create_timer(0.1).timeout
	key(KEY_TAB)
	await process_frame
	await capture("05_normal_three_complete_locked")
	expect(view.model.rear.produced == 24 and view.model.rear.metal == 1 and view.model.rear.policy == "LOCKED" and view.model.rear.committed == 0 and view.operations.situation().need.remaining == 8, "Normal3 completion accumulates24 rear rounds without policy/commit/request shortcut")
	click(Vector2(1226, 687))
	await process_frame
	expect(view.batch_count.value == 2, "Normal selector can choose finite2 for explicit new order")
	click(Vector2(1030, 680))
	while view.model.rear.job.is_empty() and view.model.elapsed < 22:
		await create_timer(0.05).timeout
	click(Vector2(1030, 720))
	await process_frame
	await capture("06_normal_stop_after_current")
	expect(view.model.rear.production_order.status == "STOPPING" and view.model.rear.production_order.requested == 2 and view.operations.situation().work.future_batches == 0, "Normal stop button leaves current batch active and schedules no later batch")
	while view.model.rear.production_order.status != "STOPPED" and view.model.elapsed < 25:
		await create_timer(0.1).timeout
	await capture("07_normal_stopped_no_repeat")
	expect(view.model.rear.produced == 32 and view.model.rear.production_order.completed == 1 and view.model.rear.production_order.status == "STOPPED", "Player-stopped2 order completes only its already active batch")
	view.queue_free()
	await process_frame
	var variant = load("res://operations.tscn").instantiate()
	variant.model.rear.metal = 1
	var delivery := crate()
	root.add_child(variant)
	# PA-WRK-005: finite separate crate, no production-scene resource grant.
	var overlay := Node2D.new()
	variant.add_child(overlay)
	overlay.draw.connect(func():
		if variant.view_mode == "rear":
			overlay.draw_rect(Rect2(delivery.position - Vector2(9, 9), Vector2(18, 18)), Color("d3a965"))
			overlay.draw_string(ThemeDB.fallback_font, Vector2(260, 175), "PROOF: rear crate Metal%d / finite receipt at T10" % delivery.inventory.Metal, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e8c984")))
	key(KEY_TAB)
	await process_frame
	key(KEY_P)
	await process_frame
	click(Vector2(380, 480))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	click(Vector2(1226, 673))
	await process_frame
	click(Vector2(1030, 680))
	await process_frame
	while variant.model.rear.production_order.status != "BLOCKED_INPUT" and variant.model.elapsed < 8:
		await create_timer(0.1).timeout
	overlay.queue_redraw()
	await capture("08_finite_crate_waits_blocked")
	expect(variant.model.rear.produced == 8 and variant.model.rear.metal == 0 and delivery.inventory.Metal == 2 and variant.operations.situation().work.worker.contains("BLOCKED_INPUT"), "Renderer block retains1/3 complete and finite crate2 is not eligible before receipt")
	while variant.model.elapsed < 10:
		await create_timer(0.05).timeout
	expect(variant.model.rear.receive_metal(delivery, 2, variant.model.elapsed), "Authored finite physical receipt transfers exactly2 at T10")
	overlay.queue_redraw()
	await create_timer(0.1).timeout
	await capture("09_received_input_same_order_resumed")
	expect(variant.model.rear.production_order.status == "ACTIVE" and variant.model.rear.production_order.completed == 1 and variant.model.rear.metal == 1 and delivery.inventory.Metal == 0, "Renderer same blocked order automatically resumes ordinary second batch after custody transfer")
	while variant.model.rear.production_order.status != "COMPLETED" and variant.model.elapsed < 24:
		await create_timer(0.1).timeout
	await capture("10_finite_crate_three_complete_locked")
	expect(variant.model.rear.produced == 24 and variant.model.rear.metal == 0 and delivery.inventory.Metal == 0 and variant.model.rear.policy == "LOCKED" and variant.model.rear.committed == 0, "Renderer finite3 Metal ends as24 locked rounds, no recurring delivery or authorization")
	evidence.append({"fixture": "PA-WRK-005", "order": variant.model.rear.production_order.duplicate(true), "custody": variant.model.rear.ledger.duplicate(true), "crate": delivery.duplicate(true)})

