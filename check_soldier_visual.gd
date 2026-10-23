extends SceneTree
const Person = preload("res://soldier.gd")
const Scenario = preload("res://scenario.gd")
const Visual = preload("res://soldier_visual.gd")
const Art = preload("res://soldier_art.gd")
const Codec = preload("res://active_checkpoint.gd")
const OUT := "res://artifacts/spr034/"
var checks := 0
var failures: Array[String] = []
var evidence: Array = []
var native_completed := false

func _initialize() -> void: run.call_deferred()
func expect(ok: bool, reason: String) -> void:
	checks += 1
	if not ok: failures.append(reason)

func snapshot(world) -> String:
	var codec := Codec.new()
	var text := JSON.stringify(codec.exact_pack(codec.graph(world)), "", true, true)
	codec.release_mapping()
	return text

func key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	e = InputEventKey.new()
	e.keycode = code
	Input.parse_input_event(e)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Art.ROOT + "provenance.json"))
	expect(source.parent_archive_sha256 == "abf4255e4059a2ec05ad77f9709c932be508aa6a00b05ef62c165cc21a89392c" and source.standing_walk_revision_archive_sha256 == "d8f59246d9939c1a167360b8d075cf487ddbb6584c7825447b03a74665cc7aba", "Human-approved parent/revision identity is pinned")
	var hashes_ok: bool = source.files_sha256.size() == 518
	var imports_ok := true
	for path in source.files_sha256:
		hashes_ok = hashes_ok and FileAccess.get_sha256(Art.ROOT + path) == source.files_sha256[path]
		if path.ends_with(".png"):
			var config := ConfigFile.new()
			imports_ok = imports_ok and config.load(Art.ROOT + path + ".import") == OK and config.get_value("params", "mipmaps/generate", false) and config.get_value("params", "compress/mode", -1) == 0
	expect(hashes_ok, "Every one of518 integrated source files matches immutable delivered bytes")
	expect(imports_ok, "All504source layers import losslessly with mipmaps")
	var metadata_ok := true
	for name in Art.NAMES:
		var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Art.ROOT + "clips/" + name + "/assembly_manifest.json"))
		metadata_ok = metadata_ok and Vector2(m.pivot_px[0],m.pivot_px[1]) == Vector2(48,56) and Vector2(m.canvas_px[0],m.canvas_px[1]) == Vector2(96,96) and m.frames.size() == 4 and m.scale_px_per_meter == 32 and m.facing == "north/up"
	expect(metadata_ok, "All14clip metadata contracts remain explicit and unchanged")
	var a := Visual.new()
	var b := Visual.new()
	root.add_child(a)
	root.add_child(b)
	var person := Person.new("Visual-Test", Vector2(1, 2), 1.4)
	var second := Person.new("Independent", Vector2.ZERO, 1.4)
	a.model_to_presentation = Transform2D(Vector2(32,0), Vector2(0,32), Vector2(-200,300))
	a.bind_model(person)
	b.bind_model(second)
	expect(a.get_child_count() == 1 and a.assembly.get_child_count() == 12, "One root, one assembly and12preallocated layer nodes per visual")
	expect(a.parts.head.texture == b.parts.head.texture, "Instances share immutable texture resources")
	person.path.assign([Vector2(100, 2)])
	person.advance(1)
	a.sample(1)
	expect(a.position.distance_to(Vector2(-123.2,364)) < 0.001 and person.position.distance_to(Vector2(2.4,2)) < 0.0001, "Actual1.4m model displacement maps to44.8world units without changing model coordinates")
	expect(a.clip_name == "standing_walk" and absf(a.assembly.rotation - PI / 2) < 0.0001, "Real movement chooses approved walk and continuous north-art facing")
	var seen := {}
	for i in range(4):
		person.advance(0.85 / 4)
		a.sample(0.85 / 4)
		seen[a.frame_index] = true
	expect(seen.size() == 4 and a._data.metadata.cycle_seconds == 0.85, "Four real layers poses are displayed within the approved .85second walking loop")
	var angle := a.assembly.rotation
	a.sample(0.1)
	expect(a.clip_name == "standing_idle" and a.assembly.rotation == angle, "Stationary sample idles and retains last meaningful facing")
	var held_time := a.clip_time
	a.sample(0)
	expect(a.clip_time == held_time, "Zero-delta presentation sampling does not advance animation time")
	var independent_frame := b.frame_index
	a.sample(1.3)
	expect(b.frame_index == independent_frame and b.clip_time == 0, "Per-instance clocks remain independent despite shared artwork")
	a.world_units_per_design_meter = 64
	a.model_to_presentation = Transform2D(Vector2(0,2), Vector2(-3,0), Vector2(120,-40))
	person.position = Vector2(5,7)
	a.sample(0, {"look_vector":Vector2.UP})
	expect(a.position == Vector2(99,-30) and a.assembly.scale == Vector2(2,2) and absf(a.assembly.rotation - PI / 2) < 0.0001, "Affine model mapping, source-art scale and facing are separate host-supplied transforms")
	var anchor = a.muzzle_world()
	expect(anchor != null and anchor.distance_to(a.assembly.global_position) > 50, "Named muzzle anchor follows documented source pivot, art scale and rotation")
	var world := Scenario.new(false, true, false, false, false, false, true)
	var target = world.squads[0].soldiers[3]
	b.bind_model(target)
	var before := snapshot(world)
	b.sample(0.5, {"action":"RELOAD", "look_vector":Vector2(1,2)})
	expect(snapshot(world) == before and b.unsupported.has("UNSUPPORTED_VISUAL: RELOAD"), "Missing reload presentation cannot mutate the real world or delay its logic")
	world.medical.wound(target, world.combat.defenders.soldiers[0], 1)
	before = snapshot(world)
	b.sample(0)
	expect(b.clip_name == "standing_idle" and b.unsupported.has("UNSUPPORTED_VISUAL: WOUNDED") and snapshot(world) == before, "Actual Medical wound state uses truthful unsupported-pose fallback without inventing prone state")
	world.combat.kill(target, world.combat.defenders.soldiers[0], 2)
	before = snapshot(world)
	b.sample(0)
	expect(b.clip_name == "death_backward" and b.frame_index == 0 and snapshot(world) == before, "Actual existing Combat kill drives death without visual model writes")
	b.sample(2)
	expect(b.frame_index == 3 and b.muzzle_world() == null, "Death holds final frame and released rifle has no live muzzle")
	b.sample(5)
	expect(b.frame_index == 3, "One-shot death cannot wrap to life")
	b.bind_model(target)
	expect(b.frame_index == 3, "Binding an existing corpse shows held final pose instead of replaying death")
	target.on_battlefield = false
	b.sample(0)
	expect(not b.visible, "Off-battlefield model is not rendered")
	var ephemeral := Person.new("Ephemeral", Vector2.ZERO, 1)
	a.bind_model(ephemeral)
	ephemeral = null
	a.sample(0)
	expect(not a.visible and a.unsupported.has("MODEL_UNBOUND"), "Visual weak binding does not own or retain simulation objects")
	a.queue_free()
	b.queue_free()
	await process_frame
	if "--visual" in OS.get_cmdline_user_args():
		await native_run()
		expect(native_completed, "All required native-renderer proof stages completed")
	var file := FileAccess.open(OUT + "checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":evidence}, "\t"))
	file.close()
	print("SPR034 CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(view, name: String) -> void:
	view.refresh()
	for i in range(2):
		await process_frame
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	evidence.append({"capture":name,"mode":view.mode,"clock":view.clock,"zoom":view.camera.zoom.x})

func percentile(values: Array, fraction: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[mini(floori(sorted.size() * fraction), sorted.size() - 1)])

func native_run() -> void:
	var view = load("res://soldier_visual_proof.tscn").instantiate()
	if not view.has_method("reset_fixture"):
		expect(false, "Native proof scene script must load successfully")
		view.free()
		return
	root.add_child(view)
	await process_frame
	view.set_physics_process(false)
	view.reset_fixture()
	await process_frame
	view.advance_fixture(1)
	expect(view.visuals.meter[0].clip_name == "standing_idle" and view.visuals.meter[1].clip_name == "standing_walk", "Real stationary and advancing Person objects drive the same adapter")
	expect(view.visuals.meter[1].person().travelled > 1.399 and view.visuals.meter[1].person().travelled < 1.401, "Native representative proof advances1.4m at32world units/m")
	await capture(view, "meter_local_023")
	key(KEY_D)
	await process_frame
	await capture(view, "meter_anchors_023")
	key(KEY_D)
	await process_frame
	for heading in [67,135,217,0]:
		key(KEY_H)
		await process_frame
		view.advance_fixture(1)
		await capture(view, "meter_heading_%03d" % heading)
		expect(absf(wrapf(view.visuals.meter[1].assembly.rotation - deg_to_rad(heading), -PI, PI)) < 0.0001, "Actual movement-derived bearing " + str(heading))
	view.camera.zoom = Vector2.ONE * 4
	view.camera.position = view.visuals.meter[1].position
	view.camera.force_update_scroll()
	await capture(view, "source_layers_close")
	key(KEY_D)
	await process_frame
	await capture(view, "source_anchors_close")
	key(KEY_R)
	key(KEY_2)
	await process_frame
	view.advance_fixture(0.1)
	var before := snapshot(view.legacy)
	view.sync_visuals(0)
	expect(snapshot(view.legacy) == before and view.mode == "legacy", "Native existing-state view remains read-only over full real Scenario graph")
	key(KEY_F)
	await process_frame
	expect(view.legacy.combat.shots.size() == 1 and view.legacy_shooter.inventory.BoltActionRifleAmmo == 2 and view.visuals.legacy[0].unsupported.has("UNSUPPORTED_VISUAL: FIRE"), "Actual accepted rifle shot consumes ammunition immediately despite absent fire animation")
	await capture(view, "actual_fire_fallback")
	key(KEY_W)
	await process_frame
	expect(view.casualty.medical_state == "WOUNDED" and view.visuals.legacy[2].unsupported.has("UNSUPPORTED_VISUAL: WOUNDED"), "Real Medical wound event is reflected without false wound artwork")
	await capture(view, "actual_wound_fallback")
	key(KEY_K)
	await process_frame
	expect(view.casualty.medical_state == "DEAD" and view.visuals.legacy[2].frame_index == 0, "Actual casualty input invokes accepted Combat kill and initial fall")
	await capture(view, "actual_death_start")
	view.advance_fixture(0.45)
	await capture(view, "actual_death_mid")
	view.advance_fixture(1.0)
	expect(view.visuals.legacy[2].frame_index == 3 and view.visuals.legacy[2].muzzle_world() == null, "Real casualty reaches held corpse with separate released rifle")
	await capture(view, "actual_death_hold")
	key(KEY_3)
	key(KEY_D)
	await process_frame
	expect(view.mode == "cohort" and view.visuals.cohort.size() == 32 and view.groups.cohort.visible, "Actual mode input shows32 simultaneous modular Soldiers")
	var frame_us: Array = []
	var sample_us: Array = []
	for i in range(20):
		view.advance_fixture(1.0 / 60)
		await process_frame
	var last := Time.get_ticks_usec()
	for i in range(120):
		view.advance_fixture(1.0 / 60)
		await process_frame
		var now := Time.get_ticks_usec()
		frame_us.append(now - last)
		sample_us.append(view.cohort_sample_us)
		last = now
	var nodes_per_visual: int = 2 + view.visuals.cohort[0].assembly.get_child_count()
	expect(nodes_per_visual == 14 and view.visuals.cohort.all(func(v): return v.clip_name == "standing_walk" and v.is_visible_in_tree()), "All32live actors retain stable14node assemblies while walking")
	evidence.append({"cohort":32,"nodes_per_visual":nodes_per_visual,"cohort_nodes":32 * nodes_per_visual,"live_visuals_including_hidden_groups":37,"whole_tree_nodes":get_node_count(),"sample_frames":120,"frame_p50_ms":percentile(frame_us,0.5) / 1000,"frame_p95_ms":percentile(frame_us,0.95) / 1000,"cohort_adapter_p50_ms":percentile(sample_us,0.5) / 1000,"cohort_adapter_p95_ms":percentile(sample_us,0.95) / 1000,"note":"Warm-cache local native diagnostic with37live visuals; only32shown. Not a full battlefield benchmark."})
	await capture(view, "cohort_32_local")
	var clock_before: float = view.clock
	key(KEY_SPACE)
	await process_frame
	view._physics_process(0.1)
	expect(view.paused and view.clock == clock_before, "Actual pause input freezes proof model clock rather than changing Soldier speed")
	view.queue_free()
	await process_frame
	native_completed = true
