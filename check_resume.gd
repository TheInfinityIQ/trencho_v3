extends SceneTree

const Fixture = preload("res://resume_fixture.gd")
const Store = preload("res://active_checkpoint.gd")
var checks := 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _initialize() -> void:
	run.call_deferred()

func oracle(fixture) -> String:
	var inspector = Store.new()
	var state: Dictionary = inspector.graph(fixture.world)
	inspector.release_mapping()
	return JSON.stringify(inspector.exact_pack({"world": state, "authored": fixture.authored, "progression": fixture.progression, "initial_ammo": fixture.initial_ammo}), "", true, true)

func diff(a, b, path := "") -> void:
	if a is Dictionary and b is Dictionary:
		for key in a:
			if not b.has(key):
				print("DIFF missing ", path, "/", key)
			else:
				diff(a[key], b[key], path + "/" + str(key))
	elif a is Array and b is Array:
		if a.size() != b.size():
			print("DIFF size ", path, " ", a.size(), " != ", b.size())
		for index in range(mini(a.size(), b.size())):
			diff(a[index], b[index], path + "/" + str(index))
	elif a != b:
		print("DIFF ", path, " ", a, " != ", b)

func run() -> void:
	var uninterrupted = Fixture.new()
	uninterrupted.step(6.25)
	expect(uninterrupted.concurrent(), "All six real systems are simultaneously unresolved at T6.25")
	var w = uninterrupted.world
	expect(absf(w.elapsed - 6.25) < 0.000000001 and w.supply.truck.inventory.BoltActionRifleAmmo == 8 and w.supply.delivered_at < 0 and w.vehicles.truck.route_state == "MOVING", "Checkpoint truck holds8physical rounds on legal unfinished route")
	expect(w.information.contact_knowledge.Squad[0].report_id == "contact-1" and w.information.contact_knowledge.Platoon.is_empty() and w.information.contact_knowledge.Company.is_empty(), "Real observed report remains in initial propagation stage, not destination truth")
	expect(w.artillery.missions[0].state == "IN_FLIGHT" and w.artillery.inventory.MortarShell == 1 and w.artillery.fired_count == 1 and w.artillery.history.is_empty(), "One real shell spent and in flight, no impact yet")
	expect(w.medical.casualty.medical_state == "WOUNDED" and absf(w.medical.casualty.bleed_out_at - 13.5) < 0.000001 and w.medical.treatment_progress > 0.7 and w.medical.treatment_progress < 0.8 and w.medical.medic.inventory.Medkit == 2, "Original medical deadline13.5 and partial treatment0.75/2, Medkit2")
	expect(w.engineering.jobs[0].progress > 0.7 and w.engineering.jobs[0].progress < 0.8 and w.engineering.reservations.values() == [4] and w.engineering.stockpile.inventory.BuildingMaterial == 0 and w.engineering.consumed == 0, "Engineering0.75/5 retains one material4reservation,0consumed")
	expect(w.rear.metal == 3 and w.rear.ammunition == 0 and w.rear.produced == 0 and not w.rear.job.id.is_empty() and absf(w.rear.job.finishes_at - 9.5) < 0.000001, "Rear input already charged Metal4->3, job due9.5, output0")
	expect(not w.artillery.missions[0].id.is_empty() and not w.artillery.missions[0].shell_id.is_empty() and not w.medical.casualty.wound_episode_id.is_empty() and not w.engineering.jobs[0].id.is_empty(), "Unresolved mission/shell/wound/engineering/production actions have stable logical IDs")
	var pre_oracle := oracle(uninterrupted)
	var progression_before := JSON.stringify(uninterrupted.progression)
	var writer = Store.new()
	writer.fixture = uninterrupted
	var text: String = writer.serialize()
	expect(not text.is_empty() and JSON.parse_string(text).schema_version == 2 and JSON.parse_string(text).fixture_id == Fixture.FIXTURE_ID, "Focused active schema2 is real value-only serialized text")
	var file := FileAccess.open("res://artifacts/active_checkpoint_v2.json", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var saved_time: float = w.elapsed
	var initial_ammo: int = w.total_ammunition()
	var old_ids: Dictionary = {}
	for person in w.all_people():
		old_ids[person.id] = person.get_instance_id()
	writer.fixture = null
	# A separate identical source for the destruction proof, not Branch A.
	var discarded = Fixture.new()
	discarded.step(6.25)
	writer.fixture = discarded
	var discard_text: String = writer.serialize()
	var weak_world: WeakRef = weakref(discarded.world)
	var weak_person: WeakRef = weakref(discarded.world.medical.casualty)
	discarded = null
	writer.fixture = null
	expect(weak_world.get_ref() == null and weak_person.get_ref() == null, "Original resumed-branch world and casualty are actually destroyed before load")
	expect(discard_text == text, "Independently constructed identical fixture produces identical checkpoint bytes")
	var resumed = Store.new()
	expect(resumed.load_serialized(FileAccess.get_file_as_string("res://artifacts/active_checkpoint_v2.json")), "Actual file roundtrip reconstructs new active runtime")
	if resumed.fixture == null:
		print("LOAD REASON: ", resumed.reason)
		finish(uninterrupted, "LOAD_FAILED")
		return
	expect(resumed.fixture.world != w and resumed.fixture.world.all_people().all(func(person): return old_ids[person.id] != person.get_instance_id()), "Every live person/world is a new runtime object with same logical IDs")
	expect(resumed.fixture.world.elapsed == saved_time and resumed.fixture.concurrent() and oracle(resumed.fixture) == pre_oracle, "No simulated load time: every relevant field/progress/custody/report/knowledge/RNG matches checkpoint exactly")
	if oracle(resumed.fixture) != pre_oracle:
		diff(JSON.parse_string(pre_oracle), JSON.parse_string(oracle(resumed.fixture)))
		var before_file := FileAccess.open("res://artifacts/resume_oracle_before.json", FileAccess.WRITE)
		before_file.store_string(pre_oracle)
		before_file.close()
		var loaded_file := FileAccess.open("res://artifacts/resume_oracle_loaded.json", FileAccess.WRITE)
		loaded_file.store_string(oracle(resumed.fixture))
		loaded_file.close()
	expect(resumed.fixture.world.supply.truck == resumed.fixture.world.vehicles.truck and resumed.fixture.world.medical.casualty == resumed.fixture.world.squads[1].soldiers[3] and resumed.fixture.world.combat.model.get_ref() == resumed.fixture.world and resumed.fixture.world.engineering.infrastructure_owner.get_ref() == resumed.fixture.world.vehicles, "Rebuilt shared actors/controller and weak associations target fresh local runtime")
	var stable_before := oracle(resumed.fixture)
	var original_runtime = resumed.fixture
	var invalid: Dictionary = JSON.parse_string(text)
	invalid.erase("objects")
	expect(not resumed.load_serialized(JSON.stringify(invalid)) and resumed.reason == "MISSING_ACTIVE_SAVE_FIELDS" and resumed.fixture == original_runtime and oracle(resumed.fixture) == stable_before, "Missing active fields reject atomically")
	invalid = JSON.parse_string(text)
	invalid.world_time = 2.0
	expect(not resumed.load_serialized(JSON.stringify(invalid)) and resumed.reason == "INVALID_ACTIVE_REFERENCES_OR_TIME" and resumed.fixture == original_runtime, "Authoritative time mismatch rejects without replacing current runtime")
	invalid = JSON.parse_string(text)
	invalid.objects["rear.gd"].fields.erase("job")
	expect(not resumed.load_serialized(JSON.stringify(invalid)) and resumed.reason == "INVALID_ACTIVE_OBJECT_FIELDS" and oracle(resumed.fixture) == stable_before, "Missing production state rejects without partial mutation")
	invalid = JSON.parse_string(text)
	invalid.objects["rear.gd"].fields.job = "not a job"
	expect(not resumed.load_serialized(JSON.stringify(invalid)) and resumed.reason == "INVALID_ACTIVE_FIELD_TYPE" and oracle(resumed.fixture) == stable_before, "Invalid typed active field rejects before property restoration")
	expect(not resumed.load_serialized("{broken") and resumed.reason == "MALFORMED_ACTIVE_SAVE" and oracle(resumed.fixture) == stable_before, "Malformed active text cannot mutate current progression/runtime")
	uninterrupted.step(10)
	resumed.fixture.step(10)
	var final_oracle := oracle(uninterrupted)
	expect(oracle(resumed.fixture) == final_oracle, "Entire relevant mutable graph, event order, exact time/positions/counts/RNG equals uninterrupted branch at T16.25")
	var final_world = resumed.fixture.world
	expect(final_world.supply.delivered_at >= 0 and final_world.supply.truck.inventory.BoltActionRifleAmmo == 0 and final_world.supply.transactions.filter(func(event): return event.reason == "Physical delivery at staging").size() == 8, "Truck delivers original8rounds exactly once through physical arrival")
	expect(final_world.total_ammunition() == initial_ammo + 8 and final_world.total_ammunition() == resumed.fixture.initial_ammo - 1 + 8, "Global ammunition equals initial minus1real woundshot plus8manufactured, custody conserved")
	expect(final_world.information.contact_deliveries.size() == 2 and final_world.information.contact_knowledge.Company[0].report_id == "contact-1" and absf(final_world.information.contact_knowledge.Company[0].received_at - 7.5) < 0.000001 and final_world.information.contact_knowledge.Company[0].observation_time == w.information.contact_knowledge.Company[0].observation_time, "Pending report's two remaining hops arrive once atoriginal6.5/7.5 with unchanged provenance")
	expect(final_world.artillery.missions[0].state == "IMPACTED" and final_world.artillery.history.size() == 1 and final_world.artillery.inventory.MortarShell == 1 and final_world.artillery.fired_count == 1, "Persisted shell impacts once with no refund/doublefire/reconsumption")
	expect(final_world.medical.casualty.medical_state in ["STABILIZED", "EVACUATED"] and final_world.medical.medic.inventory.Medkit == 1 and final_world.medical.ledger.size() == 1 and final_world.medical.history.filter(func(event): return event.event == "stabilized").size() == 1, "Original treatment finishes once using exactly one existing Medkit before bleed deadline")
	expect(final_world.engineering.jobs.size() == 1 and final_world.engineering.jobs[0].state == "COMPLETE" and final_world.engineering.structures.size() == 1 and final_world.engineering.reservations.is_empty() and final_world.engineering.consumed == 4 and final_world.engineering.stockpile.inventory.BuildingMaterial == 0, "Original partial engineering job completes once consuming its held4material, no reservation loss/duplicate structure")
	expect(final_world.rear.metal == 3 and final_world.rear.ammunition == 8 and final_world.rear.produced == 8 and final_world.rear.production_history.size() == 1 and final_world.rear.job.is_empty(), "Original production finishes once: Metal3,ammo8,onehistory,no duplicate input/output")
	expect(JSON.stringify(resumed.fixture.progression) == progression_before and JSON.stringify(uninterrupted.progression) == progression_before, "Active resume/transactions cannot mutate unrelated campaign/meta/archive histories")
	var twice = Store.new()
	twice.load_serialized(text)
	twice.fixture.step(0.5)
	var second_text: String = twice.serialize()
	var second_time: float = twice.fixture.world.elapsed
	twice.fixture = null
	expect(twice.load_serialized(second_text) and twice.fixture.world.elapsed == second_time, "Resumed supported fixture can be explicitly saved/destroyed/reloaded again at same time")
	twice.fixture.step(9.5)
	expect(oracle(twice.fixture) == final_oracle, "Additional active reload preserves exact uninterrupted result without duplicate transactions")
	var untreated = Store.new()
	untreated.load_serialized(text)
	untreated.fixture.world.medical.medic.active = false
	var bleed_deadline: float = untreated.fixture.world.medical.casualty.bleed_out_at
	var bleed_text: String = untreated.serialize()
	untreated.fixture = null
	untreated.load_serialized(bleed_text)
	untreated.fixture.step(7.233333333333)
	expect(untreated.fixture.world.medical.casualty.medical_state == "WOUNDED" and untreated.fixture.world.elapsed < bleed_deadline, "Untreated reloaded casualty remains wounded untiloriginal deadline, no early death")
	untreated.fixture.step(1.0 / 60.0)
	expect(untreated.fixture.world.medical.casualty.medical_state == "DEAD" and untreated.fixture.world.medical.history.back().event == "died from wounds" and untreated.fixture.world.medical.history.back().time == bleed_deadline, "Untreated reload dies at original13.5 deadline, never a fresh8seconds")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run(text, final_oracle)
	finish(uninterrupted, final_oracle)

func finish(fixture, final_oracle: String) -> void:
	var output := FileAccess.open("res://artifacts/resume_checks.json", FileAccess.WRITE)
	var world = fixture.world
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "checkpoint_time": 6.25, "final_time": world.elapsed, "comparison": "PASS" if failures.is_empty() else "FAIL", "final_semantic_sha256": final_oracle.sha256_text(),
		"ammo": {"initial": fixture.initial_ammo, "final": world.total_ammunition(), "wound_shots": 1, "manufactured": world.rear.produced},
		"truck": {"id": world.supply.truck.id, "position": world.supply.truck.position, "cargo": world.supply.truck.inventory, "delivered_at": world.supply.delivered_at},
		"report_deliveries": world.information.contact_deliveries, "artillery": {"missions": world.artillery.missions, "shells": world.artillery.inventory, "impacts": world.artillery.history},
		"medical": {"person": world.medical.casualty.id, "state": world.medical.casualty.medical_state, "progress": world.medical.treatment_progress, "medkits": world.medical.medic.inventory.Medkit, "history": world.medical.history},
		"engineering": {"jobs": world.engineering.jobs, "reservations": world.engineering.reservations, "consumed": world.engineering.consumed}, "rear": {"metal": world.rear.metal, "ammo": world.rear.ammunition, "history": world.rear.production_history}}, "\t", true, true))
	output.close()
	var semantic_file := FileAccess.open("res://artifacts/resume_final_semantics_v2.json", FileAccess.WRITE)
	semantic_file.store_string(final_oracle)
	semantic_file.close()
	print("RESUME CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	var released := InputEventMouseButton.new()
	released.position = point
	released.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(released)

func capture(name: String) -> void:
	await create_timer(0.04).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/resume_" + name + ".png")

func visual_run(_text: String, final_oracle: String) -> void:
	var view = load("res://resume_proof.tscn").instantiate()
	expect(view.get_script() != null, "Active resume graphical scene loads")
	if view.get_script() == null:
		view.free()
		return
	root.add_child(view)
	await capture("01_six_unresolved_at_checkpoint")
	click(Vector2(1050, 450))
	await process_frame
	await capture("02_real_checkpoint_file_written")
	click(Vector2(1050, 500))
	await process_frame
	await capture("03_new_runtime_same_time_six_pending")
	expect(view.loaded and view.destroyed_original and view.store.fixture.concurrent() and view.store.fixture.world.elapsed == view.reference.world.elapsed, "Actual save/destroy/load controls preserve all six unresolved systems and clock")
	click(Vector2(1050, 550))
	while view.store.fixture.world.elapsed < 7.2:
		await create_timer(0.05).timeout
	await capture("04_resumed_intermediate_pending_shell")
	while view.store.fixture.world.elapsed < 9.0:
		await create_timer(0.05).timeout
	await capture("05_resumed_jobs_not_restarted")
	while view.running:
		await create_timer(0.1).timeout
	await capture("06_exact_equivalence_pass_all_settled_once")
	expect(view.comparison == "PASS" and view.store.semantic_snapshot(view.store.fixture) == final_oracle, "Real renderer resumed branch equals uninterrupted model oracle exactly atT16.25")
