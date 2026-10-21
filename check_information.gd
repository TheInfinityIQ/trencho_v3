extends SceneTree

const Scenario = preload("res://scenario.gd")
const Information = preload("res://information.gd")
var failures: Array[String] = []
var checks := 0

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
	# Input is dispatched before the next queued redraw; capture the resulting
	# displayed frame rather than the preceding buffer.
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func run() -> void:
	var model = Scenario.new()
	var info = model.information
	var incident := Vector2(264, 634)
	model.advance(4.999)
	expect(info.world_event.is_empty(), "No premature event")
	model.advance(0.001)
	expect(info.world_event.hidden_source_id == "enemy-indirect-source-7", "World knows hidden firing source")
	expect(not model.squads[3].soldiers[3].active, "Fixture creates actual inactive soldier")
	expect(info.knowledge.Squad.size() == 1 and info.knowledge.Platoon.is_empty(), "Squad knows locally before platoon")
	var before := JSON.stringify(info.knowledge)
	var initial_trace := JSON.stringify(model.trace)
	for attempt in range(100):
		expect(info.query(incident).is_empty(), "Pre-report query remains unknown")
	expect(JSON.stringify(info.knowledge) == before, "Repeated queries do not inject knowledge")
	expect(JSON.stringify(model.trace) == initial_trace, "Inquiry does not change command intent")
	for index in range(1, 4):
		model.advance(0.999)
		expect(info.knowledge[Information.ECHELONS[index]].is_empty(), "Hop not delivered before deadline")
		model.advance(0.001)
		expect(info.knowledge[Information.ECHELONS[index]].size() == 1, "Hop delivered at deadline")
		var delivered: Dictionary = info.knowledge[Information.ECHELONS[index]][0]
		expect(delivered.observation_time == 5.0 and delivered.received_at == 5.0 + index, "Observation time preserved separately from receipt")
	var known: Array[Dictionary] = info.query(incident)
	expect(known.size() == 1 and "explosion" in known[0].facts and "friendly casualty" in known[0].facts, "HQ query returns established partial incident")
	expect(info.query(incident + Vector2(55, 0)).is_empty(), "Nearby coordinate outside footprint is not snapped")
	expect(info.query(Vector2(850, 130)).is_empty(), "Distant empty coordinate is unknown")
	expect(info.query(incident + Vector2(54, 0)).size() == 1, "Radius boundary included")
	expect(not JSON.stringify(info.knowledge).contains("hidden_source") and not JSON.stringify(known).contains("enemy-indirect"), "Restricted knowledge has no hidden source")
	known[0].facts.append("malicious extra")
	expect(not "malicious extra" in info.query(incident)[0].facts, "Query result is detached from military knowledge")
	expect(not info.begin_reconstruction(known), "Forged or altered reconstruction record refused")
	known = info.query(incident)
	expect(info.begin_reconstruction(known), "Established HQ knowledge enables reconstruction")
	expect(not JSON.stringify(info.reconstruction).contains("enemy") and not JSON.stringify(info.reconstruction).contains("hidden_source"), "Reconstruction whitelist excludes source")
	var paused: float = model.elapsed
	var paused_position: Vector2 = model.squads[0].soldiers[0].position
	model.advance(10)
	expect(model.elapsed == paused and model.squads[0].soldiers[0].position == paused_position, "Reconstruction pauses authoritative time and movement")
	var history := JSON.stringify(info.knowledge)
	info.end_reconstruction()
	model.advance(0.5)
	expect(model.elapsed == paused + 0.5 and JSON.stringify(info.knowledge) == history, "Exit resumes without rewriting history")
	expect(info.deliveries.size() == 3, "Exactly three delayed reports")
	if "--visual" in OS.get_cmdline_user_args():
		var view = load("res://main.tscn").instantiate()
		view.view_mode = "battlefield"
		root.add_child(view)
		await create_timer(5.2).timeout
		key(KEY_B)
		await process_frame
		click(incident)
		await process_frame
		expect(view.inquiry_mode and view.queried and view.query_result.is_empty(), "Real input opens arbitrary coordinate pre-report inquiry")
		await capture("information_before_report")
		await create_timer(3.0).timeout
		click(incident)
		await process_frame
		expect(view.query_result.size() == 1, "Real input refreshes to post-report partial result")
		await capture("information_after_report")
		key(KEY_R)
		await process_frame
		expect(view.model.information.reconstructing, "Keyboard starts evidence-bound reconstruction")
		var time_before: float = view.model.elapsed
		await create_timer(1.0).timeout
		expect(view.model.elapsed == time_before, "Real renderer reconstruction pauses world")
		await capture("information_reconstruction")
		key(KEY_ESCAPE)
		await process_frame
		await create_timer(0.5).timeout
		expect(not view.model.information.reconstructing and view.model.elapsed > time_before, "Escape interrupts and resumes world")
		click(Vector2(850, 130))
		# Escape closes inquiry mode, so explicitly re-enter before empty query.
		key(KEY_B)
		await process_frame
		click(Vector2(850, 130))
		await process_frame
		expect(view.query_result.is_empty(), "Real empty-coordinate inquiry has no incident snapping")
	var output := FileAccess.open("res://artifacts/information_checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "deliveries": info.deliveries}, "\t"))
	output.close()
	print("INFORMATION CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)
