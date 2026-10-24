extends SceneTree
var view
var reports := []
func _initialize() -> void: run.call_deferred()
func held(code: Key, value: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=value;Input.parse_input_event(event);Input.flush_buffered_events()
func sample_case(label: String, at: float, debug: bool, close := false) -> void:
	view.paused=true;view.set_seed(35035);view.paused=true
	while view.elapsed+0.000001<at:view.advance_models(minf(1.0/60,at-view.elapsed))
	if view.debug_enabled!=debug:view.toggle_debug()
	view.camera.position=(view.layout.village+Vector2(170,35))*32;view.set_mode("tactical")
	if close:
		var event:=InputEventMouseButton.new();event.pressed=true;event.button_index=MOUSE_BUTTON_WHEEL_UP;event.factor=100;event.position=Vector2(640,400);view._unhandled_input(event)
	view.paused=false
	var frames:=[];var updates:=[];var previous:=Time.get_ticks_usec()
	var shots:int=view.world.combat.shots.size();var deliveries:int=view.world.information.contact_knowledge.Company.size()
	for i in range(600):
		await process_frame
		for key in [KEY_W,KEY_A,KEY_S,KEY_LEFT,KEY_UP,KEY_DOWN]:held(key,false)
		held(KEY_D,close)
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();frames.append((now-previous)/1000.0);previous=now;updates.append(view.update_us/1000.0)
	held(KEY_D,false);view.paused=true;frames.sort();updates.sort()
	var result:={"case":label,"debug":debug,"p50_ms":frames[300],"p95_ms":frames[570],"max_ms":frames.back(),"update_p95_ms":updates[570],"shots_during":view.world.combat.shots.size()-shots,"company_reports_during":view.world.information.contact_knowledge.Company.size()-deliveries,"cap":Engine.max_fps,"generation":view.generation_count,"active_chunks":view.active_chunks}
	reports.append(result);print(JSON.stringify(result))
func run() -> void:
	view=load("res://representative_sector.tscn").instantiate();root.add_child(view);view.paused=true
	view.set_process_unhandled_input(false);view.set_process_unhandled_key_input(false)
	for debug in [false,true]:
		await sample_case("approach_tactical",25,debug)
		await sample_case("local_contact_and_relay",38.15,debug)
		await sample_case("active_firefight",45,debug)
		await sample_case("max_wheel_zoom_pan",45,debug,true)
	var file:=FileAccess.open("res://artifacts/cnt039/performance.json",FileAccess.WRITE);file.store_string(JSON.stringify(reports,"\t"));file.close()
	view.free();print("CONTACT PROFILE COMPLETE");quit()
