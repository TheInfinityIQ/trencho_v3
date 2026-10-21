extends SceneTree

const Scenario = preload("res://scenario.gd")
const Squad = preload("res://squad.gd")
var failures: Array[String] = []
var checks := 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var model = Scenario.new()
	expect(model.squads.size() == 4 and model.platoons.size() == 2, "Fixture contains two platoons/four squads")
	var ids: Dictionary = {}
	for squad in model.squads:
		for soldier in squad.soldiers:
			ids[soldier.id] = true
	expect(ids.size() == 16, "Sixteen uniquely identified individuals")
	expect(model.platoons[0].assignment == "Main effort" and model.platoons[1].assignment == "Reserve", "Company allocates main and reserve")
	expect(model.squads[0].task != model.squads[1].task, "Platoon decomposes intent")
	expect(model.squads[0].route_side == "north", "Squad chooses shorter northern bypass")
	var blocked_samples := 0
	var overlap_samples := 0
	for tick in range(2400):
		model.advance(1.0 / 60.0)
		for squad in model.squads:
			for soldier in squad.soldiers:
				if Scenario.OBSTACLE.grow(6).has_point(soldier.position):
					blocked_samples += 1
			for a in range(squad.soldiers.size()):
				for b in range(a + 1, squad.soldiers.size()):
					if squad.soldiers[a].position.distance_to(squad.soldiers[b].position) < 3:
						overlap_samples += 1
	expect(blocked_samples == 0, "All movement samples clear the obstacle including actor radius")
	expect(overlap_samples == 0, "Squad members do not collapse into an overlapping token")
	expect(model.secured and model.squads[1].complete(), "Seizure and support arrive autonomously")
	for squad in model.squads.slice(2):
		for soldier in squad.soldiers:
			expect(soldier.position == soldier.origin and soldier.path.is_empty(), "Reserve stays staged: " + soldier.id)
	var independent = Scenario.new()
	independent.squads[0].soldiers[0].speed = 0
	independent.advance(2)
	expect(independent.squads[0].soldiers[0].position == independent.squads[0].soldiers[0].origin, "One stalled soldier retains its own position")
	expect(independent.squads[0].soldiers[1].travelled > 80, "Other individuals advance independently")
	var south = Squad.new("south-test", Vector2(160, 480))
	south.assign("Approach", Vector2(815, 450), Scenario.OBSTACLE)
	expect(south.route_side == "south", "Squad chooses southern route for southern approach")
	var trace_echelons: Dictionary = {}
	for entry in model.trace:
		trace_echelons[entry.echelon] = true
		expect(not entry.intent.is_empty() and not entry.choice.is_empty() and not entry.reason.is_empty(), "Trace preserves decision context")
	expect(trace_echelons.size() == 5, "Trace covers all five echelons")
	var report := {"checks": checks, "failures": failures, "elapsed_simulation": model.elapsed, "trace": model.trace}
	var output := FileAccess.open("res://artifacts/checks.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("HIERARCHY CHECKS: ", checks, " failures: ", failures)
	if "--visual" in OS.get_cmdline_user_args():
		var view = load("res://main.tscn").instantiate()
		view.model = Scenario.new(false)
		view.view_mode = "battlefield"
		root.add_child(view)
		for delay in [0.3, 6.0, 7.0, 12.0]:
			await create_timer(delay).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/run_%02d.png" % int(view.model.elapsed))
		print("GRAPHICAL RUN: elapsed=", view.model.elapsed, " secured=", view.model.secured)
		expect(view.model.secured, "Real graphical run secures objective without input")
	quit(0 if failures.is_empty() else 1)
