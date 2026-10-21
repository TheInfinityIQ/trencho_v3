extends Node2D

const Loop = preload("res://campaign_loop.gd")
var session = Loop.new()
var battle_view
var overlay: Panel
var heading: Label
var details: Label
var continue_button: Button
var save_button: Button
var reload_button: Button
var meta_button: Button
var unlock_button: Button
var close_button: Button
var roster_open := false
var notice := ""

func make_button(text: String, point: Vector2, action: Callable, parent: Node, width := 300.0) -> Button:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = Vector2(width, 32)
	item.pressed.connect(action)
	parent.add_child(item)
	return item

func _ready() -> void:
	mount_battle()
	make_button("CAMPAIGN / ROSTER [V]", Vector2(650, 5), toggle_roster, self, 280)
	overlay = Panel.new()
	overlay.position = Vector2(80, 80)
	overlay.size = Vector2(1120, 650)
	overlay.z_index = 50
	var style := StyleBoxFlat.new()
	style.bg_color = Color("112025")
	style.border_color = Color("739b94")
	style.set_border_width_all(2)
	overlay.add_theme_stylebox_override("panel", style)
	add_child(overlay)
	heading = Label.new()
	heading.position = Vector2(30, 20)
	heading.add_theme_font_size_override("font_size", 24)
	overlay.add_child(heading)
	details = Label.new()
	details.position = Vector2(30, 65)
	details.size = Vector2(1060, 445)
	details.add_theme_font_size_override("font_size", 15)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_child(details)
	continue_button = make_button("CONTINUE CAMPAIGN", Vector2(30, 525), continue_campaign, overlay)
	save_button = make_button("SAVE INTERMISSION", Vector2(350, 525), save_intermission, overlay)
	reload_button = make_button("RELOAD INTERMISSION", Vector2(670, 525), reload_intermission, overlay)
	meta_button = make_button("META", Vector2(30, 525), enter_meta, overlay)
	unlock_button = make_button("UNLOCK MORTAR ELIGIBILITY / 1 TOKEN", Vector2(30, 525), unlock, overlay, 440)
	close_button = make_button("RETURN TO BATTLE [V]", Vector2(30, 575), toggle_roster, overlay)
	refresh()

func mount_battle() -> void:
	if battle_view != null:
		remove_child(battle_view)
		battle_view.queue_free()
	var scene := "res://operations.tscn" if session.progression.campaign.data.battle_index == 1 else "res://priority_operations.tscn"
	battle_view = load(scene).instantiate()
	battle_view.operations = session.operations
	battle_view.model = session.operations.world
	add_child(battle_view)
	move_child(battle_view, 0)
	battle_view.set_physics_process(false)

func _physics_process(delta: float) -> void:
	if session.phase == "ACTIVE" and battle_view.view_mode == "rear" and not roster_open:
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		session.operations.world.rear.move_avatar(direction, delta)
	session.advance(delta)
	battle_view.refresh()
	battle_view.queue_redraw()
	refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		toggle_roster()
		get_viewport().set_input_as_handled()

func toggle_roster() -> void:
	if session.phase == "ACTIVE":
		roster_open = not roster_open
	refresh()

func continue_campaign() -> void:
	if session.continue_campaign():
		roster_open = false
		notice = ""
		mount_battle()
	else:
		notice = session.reason
	refresh()

func save_intermission() -> void:
	var text: String = session.intermission_checkpoint()
	if text.is_empty():
		notice = session.reason
	else:
		var file := FileAccess.open("user://campaign_loop_intermission.json", FileAccess.WRITE)
		if file == null:
			notice = "Save could not be written"
		else:
			file.store_string(text)
			file.close()
			notice = "Intermission saved. Continue remains explicit."
	refresh()

func reload_intermission() -> void:
	var path := "user://campaign_loop_intermission.json"
	if FileAccess.file_exists(path) and session.load_intermission(FileAccess.get_file_as_string(path)):
		notice = "Intermission reloaded. Continue builds fresh Battle 2."
	else:
		notice = "No valid saved intermission: " + session.reason
	refresh()

func enter_meta() -> void:
	session.enter_meta()
	refresh()

func unlock() -> void:
	if session.progression.unlock():
		notice = "Mortar card now eligible in future campaigns; no capability or assets granted."
	else:
		notice = session.progression.reason
	refresh()

func refresh() -> void:
	if overlay == null:
		return
	var phase: String = session.phase
	overlay.visible = phase != "ACTIVE" or roster_open
	battle_view.set_process_input(not overlay.visible)
	battle_view.set_process_unhandled_input(not overlay.visible)
	continue_button.visible = phase == "INTERMISSION"
	save_button.visible = phase == "INTERMISSION"
	reload_button.visible = phase == "INTERMISSION"
	meta_button.visible = phase == "FINAL"
	unlock_button.visible = phase == "OUT_META"
	unlock_button.disabled = not session.progression.eligible_meta_unlocks().has("tech.mortar") or session.progression.meta.currency < 1
	close_button.visible = phase == "ACTIVE"
	var campaign = session.progression.campaign
	var title := "CAMPAIGN / BATTLE %d / T%.2f — live world continues" % [campaign.data.battle_index, session.operations.world.elapsed]
	if phase == "INTERMISSION":
		title = "BATTLE 1 VICTORY / INTERMISSION — world frozen"
	elif phase == "FINAL":
		title = "CAMPAIGN COMPLETE / BATTLES WON 2" if campaign.data.status == "COMPLETED_SUCCESS" else "DEFEAT / CAMPAIGN STOPPED"
	elif phase == "OUT_META":
		title = "OUT_META / META SHOP"
	heading.text = title
	var result := ""
	if phase in ["FINAL", "OUT_META"]:
		result = "Earned %d MetaToken / current balance %d\n%s\n" % [1 if campaign.data.status == "COMPLETED_SUCCESS" else 0, session.progression.meta.currency, "Two battles won. Reward settled." if campaign.data.status == "COMPLETED_SUCCESS" else "Defeat reward policy remains deferred."]
	var live_archive := ""
	if phase == "INTERMISSION" and campaign.world != null:
		live_archive = "B1 actual HQ victory at T%.2f; explicit Continue required.\n" % campaign.world.battle.terminal_time
	details.text = result + "Campaign: " + campaign.data.campaign_id + "\nCapabilities: " + str(campaign.data.capabilities) + "\nPersistent people (history: personal + appointments + permanent):\n" + session.roster_text() + "\n" + live_archive + session.archive_text() + "\n" + notice
