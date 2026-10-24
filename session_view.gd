extends Node
## Root owns persistent models and presentations for the life of this run.
const Session = preload("res://game_session.gd")
const BattlefieldView = preload("res://representative_sector.gd")
const RearView = preload("res://session_rear_view.gd")
var session = Session.new()
var battlefield_view
var rear_view
var rear_layer: CanvasLayer
var rear_panel: Control
var clock_label: Label
var stock_label: Label
var work_label: Label
var rear_buttons: Array[Button] = []
var view_buttons := {}
var rate_buttons := {}
var _hud_elapsed := 0.0

func button(parent: Node, caption: String, point: Vector2, width: float, action: Callable) -> Button:
	var item := Button.new(); item.text = caption; item.position = point; item.size = Vector2(width, 34)
	item.focus_mode = Control.FOCUS_NONE; item.pressed.connect(action); parent.add_child(item)
	return item

func label(parent: Node, point: Vector2, width: float) -> Label:
	var item := Label.new(); item.position = point; item.size.x = width; item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(item); return item

func _ready() -> void:
	battlefield_view = BattlefieldView.new(); battlefield_view.session_owner = session; add_child(battlefield_view)
	rear_layer = CanvasLayer.new(); rear_layer.layer = 5; add_child(rear_layer)
	rear_view = RearView.new(); rear_view.session = session; rear_layer.add_child(rear_view)
	rear_panel = Control.new(); rear_layer.add_child(rear_panel)
	var background := ColorRect.new(); background.color = Color("152722"); background.position = Vector2(932, 105); background.size = Vector2(324, 645); rear_panel.add_child(background)
	stock_label = label(rear_panel, Vector2(950, 125), 285)
	work_label = label(rear_panel, Vector2(950, 250), 285)
	work_label.add_theme_font_size_override("font_size", 16)
	for item in [["E · Work one manual batch", "MANUAL"], ["F · Worker: 3 finite batches", "WORKER"], ["X · Stop future Worker batches", "STOP"]]:
		rear_buttons.append(button(rear_panel, item[0], Vector2(950, 600 + rear_buttons.size() * 46), 286, do_rear.bind(item[1])))
	var layer := CanvasLayer.new(); layer.layer = 10; add_child(layer)
	var bar := ColorRect.new(); bar.color = Color("10211e"); bar.size = Vector2(3000, 54); layer.add_child(bar)
	clock_label = label(layer, Vector2(18, 15), 435)
	view_buttons.REAR = button(layer, "REAR", Vector2(460, 10), 125, change_view.bind("REAR"))
	view_buttons.BATTLEFIELD = button(layer, "BATTLEFIELD", Vector2(592, 10), 150, change_view.bind("BATTLEFIELD"))
	for rate in [0, 1, Session.FAST_RATE]:
		var caption: String = {0:"Pause", 1:"Normal", 4:"Fast 4x"}[rate]
		rate_buttons[rate] = button(layer, caption, Vector2(780 + rate_buttons.size() * 145, 10), 135, change_rate.bind(rate))
	change_view("REAR")

func change_view(value: String) -> void:
	session.select_view(value)
	var rear: bool = session.view == "REAR"
	battlefield_view.visible = not rear; battlefield_view.hud.visible = not rear
	battlefield_view.set_process(not rear)
	battlefield_view.set_process_unhandled_input(not rear); battlefield_view.set_process_unhandled_key_input(not rear)
	battlefield_view.camera.enabled = not rear
	rear_layer.visible = rear
	if not rear: battlefield_view.advance_models(0); battlefield_view.refresh_debug(true)
	refresh()

func change_rate(value: int) -> void:
	session.set_rate(value); refresh()

func do_rear(action: String) -> void:
	session.rear_action(action); refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_TAB: change_view("BATTLEFIELD" if session.view == "REAR" else "REAR")
		KEY_SPACE: session.toggle_pause(); refresh()
		KEY_E: do_rear("MANUAL")
		KEY_F: do_rear("WORKER")
		KEY_X: do_rear("STOP")
		_: return
	get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	session.advance(delta, direction)
	if session.view == "BATTLEFIELD": battlefield_view.advance_models(session.last_step_count * Session.STEP)
	_hud_elapsed += delta
	if _hud_elapsed >= 0.1:
		_hud_elapsed = 0; refresh()

func refresh() -> void:
	if clock_label == null: return
	var rate: String = "PAUSED" if session.rate == 0 else ("NORMAL" if session.rate == 1 else "FAST 4x")
	clock_label.text = "%s   ·   World %02d:%05.2f   ·   %s" % [session.view, int(session.elapsed) / 60, fmod(session.elapsed, 60), rate]
	for key in view_buttons: view_buttons[key].disabled = session.view == key
	for key in rate_buttons: rate_buttons[key].disabled = session.rate == key
	var rear = session.rear
	stock_label.text = "REAR-OWNED STOCK\nMetal: %d\nFinished rifle ammunition: %d\nProduced here: %d rounds" % [rear.metal, rear.ammunition, rear.produced]
	var order: String = "No Worker order" if rear.production_order.is_empty() else "Worker: %s · %d/%d batches" % [rear.production_order.status, rear.production_order.completed, rear.production_order.requested]
	work_label.text = "1 Metal → 8 rounds\n4 world seconds per batch\n\n%s\n\n%s\n\nProduction continues while you observe the battlefield. Finished ammunition belongs to this rear stock." % [order, rear.message]
	for item in rear_buttons: item.disabled = session.rate == 0
	rear_view.queue_redraw()
