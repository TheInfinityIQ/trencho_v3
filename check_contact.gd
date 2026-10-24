extends SceneTree
const Layout = preload("res://sector_layout.gd")
const Rural = preload("res://sector_environment.gd")
const Engagement = preload("res://sector_engagement.gd")
var checks := 0
var failures: Array[String] = []
var evidence := []
func _initialize() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func make_world(seed_value := 35035):
	var layout=Layout.new(); layout.generate(seed_value)
	var rural=Rural.new()
	rural.configure(JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/docs/metadata.json")),JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/provenance.json")).archive_sha256)
	rural.compose(layout)
	return Engagement.new(layout,rural)
func run() -> void:
	for seed_value in [35035,35036]:
		var world=make_world(seed_value)
		expect(world.friendly_people().size()==18 and world.enemy_people().size()==9 and world.all_people().size()==27,"Two real physical forces retain embodied command")
		expect(world.initial_ammunition==288 and world.information.world_event.is_empty(),"Finite physical carried load and no authored casualty")
		var first_company := -1.0
		var unaware_at_contact := false
		var morale_ok := true
		for tick in range(60*120):
			world.advance(1.0/60)
			if world.combat.first_friendly_detection>=0 and world.information.contact_knowledge.Company.is_empty(): unaware_at_contact=true
			if first_company<0 and not world.information.contact_knowledge.Company.is_empty(): first_company=world.elapsed
			for squad in world.squads+world.enemy_platoon.squads: morale_ok=morale_ok and squad.morale==100 and squad.routing_state=="NONE"
		print("CONTACT seed=",seed_value," first=",world.combat.first_detection," friendly=",world.combat.first_friendly_detection," company=",first_company," shots=",world.combat.shots.size()," deaths=",world.combat.history.size()," ammo=",world.ammunition_remaining())
		expect(world.combat.first_detection>0 and world.combat.first_friendly_detection>0,"Actual movement closes initially separated forces into local detection")
		expect(unaware_at_contact and first_company>=world.combat.first_friendly_detection+2-0.000001,"Company remains unaware until the accepted two1second hops")
		expect(world.information.world_event.is_empty(),"Sector opt-out prevents legacy forcedT5incident")
		expect(not world.combat.shots.is_empty() and world.ammunition_remaining()+world.combat.shots.size()==world.initial_ammunition,"All actual shots consume conserved carried ammunition")
		var cadence_ok := true; var shot_ok := true; var last := {}
		for shot in world.combat.shots:
			if last.has(shot.shooter): cadence_ok=cadence_ok and shot.time-last[shot.shooter]>=1-0.000001
			last[shot.shooter]=shot.time
			shot_ok=shot_ok and shot.ammo_before>0 and shot.ammo_after==shot.ammo_before-1 and shot.shooter_position.distance_to(shot.target_position)<=260.001 and shot.locally_detected and shot.los
		expect(cadence_ok and shot_ok,"Accepted cadence, geometry, local detection and per-shot ammo rules hold")
		expect(morale_ok and not world.combat.suppression_events.is_empty(),"Actual combat creates suppression independently of morale/routing")
		var provenance_ok := true
		for report in world.information.contact_knowledge.Company:
			provenance_ok=provenance_ok and report.received_at==report.observation_time+2 and report.has("source_formation") and report.has("source_platoon") and report.has("detection_basis")
		expect(provenance_ok,"Company records retain immutable observation/receipt/provenance")
		var copy_contacts: Array = world.company_contacts()
		var original: Vector2 = copy_contacts[0].observed_position
		world.enemy_people()[0].position += Vector2(50,50)
		expect(world.company_contacts()[0].observed_position == original,"Hidden enemy motion cannot update received knowledge")
		copy_contacts[0].observed_position = Vector2.ZERO
		expect(world.company_contacts()[0].observed_position == original,"Returned knowledge snapshots cannot mutate the report owner")
		var repeat = make_world(seed_value)
		for tick in range(60*120): repeat.advance(1.0/60)
		expect(JSON.stringify(Layout.canonical(repeat.combat.shots)) == JSON.stringify(Layout.canonical(world.combat.shots)),"Explicit fixed RNG streams reproduce shot decisions and outcomes")
		evidence.append({"seed":seed_value,"first_detection":world.combat.first_detection,"first_friendly_detection":world.combat.first_friendly_detection,"first_company":first_company,"shots":world.combat.shots,"casualties":world.combat.history,"local_events":world.combat.local_events,"suppression":world.combat.suppression_events,"reports":world.information.contact_knowledge.Company,"contacts":world.company_contacts(),"ammo_remaining":world.ammunition_remaining()})
	var isolated = make_world()
	var shooter=isolated.squads[0].soldiers[0]; var target=isolated.enemy_people()[0]
	target.position=shooter.position+Vector2(100,0); shooter.detected.assign([target.id]); shooter.inventory.BoltActionRifleAmmo=0
	expect(not isolated.combat.attempt_shot(shooter,target,1,0.9),"Zero physical ammo prevents a geometrically valid shot")
	shooter.inventory.BoltActionRifleAmmo=2; target.position=shooter.position+Vector2(300,0)
	expect(not isolated.combat.attempt_shot(shooter,target,1,0.9),"Even a previously detected target must still satisfy current range")
	target.position=shooter.position+Vector2(100,0)
	expect(isolated.combat.attempt_shot(shooter,target,1,0.9) and not isolated.combat.attempt_shot(shooter,target,1.5,0.9),"Cadence gates repeated fire independently of ammo")
	var squad=isolated.squads[1];var reference:Vector2=squad.formation_reference
	squad.receive_suppression(4,0);squad.advance(0.1)
	expect(squad.contact_hold and squad.formation_reference==reference and squad.morale==100,"Suppression4holds local movement without morale coupling")
	squad.decay_suppression(6);squad.advance(0.1)
	expect(not squad.contact_hold and squad.suppression<=1 and squad.formation_reference!=reference,"Accepted decay/safe threshold resumes the retained mission")
	var separated=make_world()
	for person in separated.enemy_people(): person.position+=Vector2(500,0)
	for tick in range(60*60):separated.advance(1.0/60)
	expect(separated.combat.first_detection<0 and separated.combat.shots.is_empty(),"Changing physical separation prevents contact despite advancing past the default contact time")
	if "--visual" in OS.get_cmdline_user_args(): await visual_run()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/cnt039"))
	var name := "checks_native.json" if "--visual" in OS.get_cmdline_user_args() else "checks.json"
	var file=FileAccess.open("res://artifacts/cnt039/"+name,FileAccess.WRITE);file.store_string(JSON.stringify(Layout.canonical({"checks":checks,"failures":failures,"evidence":evidence}),"\t"));file.close()
	print("CONTACT CHECKS ",checks," failures: ",failures)
	quit(0 if failures.is_empty() else 1)

func capture(view, label: String) -> void:
	view.refresh_debug()
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/cnt039/"+label+".png")

func advance_to(view, target: float) -> void:
	while view.elapsed + 0.000001 < target: view.advance_models(minf(1.0/60,target-view.elapsed))

func visual_run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/cnt039"))
	var view=load("res://representative_sector.tscn").instantiate(); root.add_child(view)
	view.paused=true;view.set_process(false);view.set_process_unhandled_input(false);view.set_process_unhandled_key_input(false)
	view.camera.position=(view.layout.village+Vector2(170,35))*32;view.set_mode("tactical")
	expect(view.people.size()==27 and view.visuals.size()==27,"Native presentation binds27physical people")
	expect(view.visuals.filter(func(visual):return visual.person().faction=="enemy" and visual.visible).is_empty(),"Clean view hides all enemy truth sprites")
	await capture(view,"01_clean_approach")
	view.toggle_debug();await capture(view,"02_debug_truth_before_contact")
	expect(view.visuals.filter(func(visual):return visual.person().faction=="enemy" and visual.visible).size()==9,"F3 explicitly exposes all9enemy truth models")
	while view.world.combat.first_friendly_detection<0 and view.elapsed<100: view.advance_models(1.0/60)
	expect(view.world.information.contact_knowledge.Company.is_empty(),"Native first local contact does not grant immediate Company knowledge")
	await capture(view,"03_first_local_contact_company_unaware")
	view.toggle_debug();await capture(view,"04_clean_local_contact_no_report")
	while view.world.company_contacts().is_empty() and view.elapsed<105: view.advance_models(1.0/60)
	expect(not view.world.company_contacts().is_empty(),"Native received report enables knowledge markers")
	await capture(view,"05_clean_received_report")
	advance_to(view,45);view.toggle_debug();await capture(view,"06_debug_firefight")
	view.camera.position=view.world.squads[0].center()*32;view.set_mode("local")
	await capture(view,"07_local_combat")
	view.toggle_debug();advance_to(view,120)
	view.camera.position=(view.layout.village+Vector2(170,35))*32;view.set_mode("tactical")
	await capture(view,"08_clean_last_known_stale")
	expect(view.visuals.filter(func(visual):return visual.person().faction=="enemy" and visual.visible).is_empty(),"Enemy truth remains hidden after contact and casualties")
	evidence.append({"native_time":view.elapsed,"people":view.people.size(),"cap":Engine.max_fps,"generation":view.generation_count,"fingerprint":view.layout.fingerprint})
	view.free()
