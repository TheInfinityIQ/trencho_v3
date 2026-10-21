extends Node2D

const Session = preload("res://card_session.gd")
var session = Session.new()
var font := ThemeDB.fallback_font
var purchase_button: Button
var choice_buttons: Array[Button] = []
var production_button: Button
var bench_button: Button
var probe_button: Button
var showing_probe := false
var status := "Available in the fixture pool. No card acquired; ammo capability disabled."

func button(text: String, point: Vector2, size: Vector2, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = size
	item.pressed.connect(action)
	add_child(item)
	return item

func _ready() -> void:
	purchase_button = button("BUY TIER 1 DROP / 1 TOKEN", Vector2(45, 318), Vector2(390, 36), buy)
	for index in range(3):
		choice_buttons.append(button("", Vector2(45, 409 + index * 70), Vector2(780, 42), func(): choose(index)))
	bench_button = button("PLACE PROOF WORKBENCH", Vector2(900, 375), Vector2(330, 36), place_bench)
	production_button = button("ATTEMPT MANUAL AMMO BATCH", Vector2(900, 420), Vector2(330, 36), produce)
	probe_button = button("DETACHED NEXT-BATTLE PROBE", Vector2(900, 655), Vector2(330, 36), probe)
	refresh()

func buy() -> void:
	status = "Tier 1 drop purchased. Select one offered card; nothing acquired yet." if session.purchase() else session.cards.reason
	refresh()

func choose(index: int) -> void:
	var drop: Dictionary = session.cards.open_drop()
	if drop.is_empty():
		return
	var identity: String = drop.candidates[index]
	status = "Acquired " + identity + ". Capability activated; no physical output." if session.select_card(drop.id, identity) else session.cards.reason
	refresh()

func place_bench() -> void:
	var rear = session.campaign.world.rear
	rear.place_workbench(Vector2(380, 480))
	status = rear.message
	refresh()

func produce() -> void:
	var world = session.campaign.world
	world.rear.start_job("Avatar", world.elapsed)
	status = world.rear.message
	refresh()

func probe() -> void:
	session.build_reconstruction_probe()
	showing_probe = true
	status = "Detached campaign reconstruction: technology retained; physical Battle 2 stock left behind."
	refresh()

func refresh() -> void:
	var drop: Dictionary = session.cards.open_drop()
	for index in range(choice_buttons.size()):
		choice_buttons[index].visible = not showing_probe and not drop.is_empty()
		if not drop.is_empty():
			var definition: Dictionary = session.cards.DEFINITIONS[drop.candidates[index]]
			choice_buttons[index].text = definition.name + " / Tier " + str(definition.tier)
	purchase_button.disabled = showing_probe or not drop.is_empty() or session.cards.state.currency.DropToken < 1
	production_button.disabled = showing_probe
	bench_button.disabled = showing_probe or session.campaign.world.rear.placed
	probe_button.disabled = showing_probe or session.cards.state.acquired_cards.is_empty()

func _physics_process(delta: float) -> void:
	var was_working: bool = not session.campaign.world.rear.job.is_empty()
	session.advance(delta)
	if was_working and session.campaign.world.rear.job.is_empty() and not showing_probe:
		status = session.campaign.world.rear.message
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16, color := Color("dce7df")) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	var data: Dictionary = session.probe_data if showing_probe else session.campaign.data
	var cards = session.probe_cards if showing_probe else session.cards
	var world = session.probe_world if showing_probe else session.campaign.world
	var rear = world.rear
	draw_rect(Rect2(24, 100, 830, 640), Color("182b2b"))
	draw_rect(Rect2(875, 100, 380, 640), Color("112025"))
	label_at(Vector2(28, 40), "TRENCHO / CAMPAIGN CARD ACQUISITION PROOF", 25)
	label_at(Vector2(28, 75), "Protected progression view / fixture availability, acquisition, capability and physical stock", 16)
	label_at(Vector2(45, 130), "PRE-UNLOCKED FIXTURE POOL / NO META SHOP", 20)
	var definitions: Dictionary = cards.definitions()
	for index in range(cards.UNLOCKED.size()):
		var identity: String = cards.UNLOCKED[index]
		var definition: Dictionary = definitions[identity]
		label_at(Vector2(45, 161 + index * 29), "%s / T%d / %s / %s" % [identity, definition.tier, definition.category, definition.type], 16)
	label_at(Vector2(45, 300), "Drop Tokens: %d / Tier 1 purchase costs 1" % cards.state.currency.DropToken, 19)
	var drop: Dictionary = cards.open_drop()
	label_at(Vector2(45, 389), "No open drop" if drop.is_empty() else "Offer " + drop.id + " / choose exactly one / all Tier 1", 18)
	if not cards.state.drops.is_empty():
		var last: Dictionary = cards.state.drops.back()
		label_at(Vector2(45, 622), "Generated IDs: " + ", ".join(last.candidates), 15)
		label_at(Vector2(45, 650), "Selected: " + (last.selected_card if not last.selected_card.is_empty() else "none"), 17)
	label_at(Vector2(45, 686), "Campaign-owned: " + (", ".join(cards.state.acquired_cards) if not cards.state.acquired_cards.is_empty() else "none"), 16)
	label_at(Vector2(45, 716), "Meta fixture pool unchanged / no recurring income", 15)
	label_at(Vector2(900, 130), "BATTLE %d / LOCAL T%.2f" % [data.battle_index, world.elapsed], 20)
	label_at(Vector2(900, 160), "DETACHED RECONSTRUCTION" if showing_probe else "LIVE BATTLE 2 REAR", 17)
	label_at(Vector2(900, 200), "Ammo capability: " + str(rear.capability_unlocked), 18)
	var active: Array = []
	for capability in data.capabilities:
		if data.capabilities[capability]:
			active.append(capability)
	label_at(Vector2(900, 228), ", ".join(active) if not active.is_empty() else "No active campaign capabilities", 15)
	label_at(Vector2(900, 270), "PHYSICAL AMMO: %d" % rear.ammunition, 23, Color("a8dfba"))
	label_at(Vector2(900, 302), "Metal %d / workbench %s" % [rear.metal, str(rear.placed)], 18)
	label_at(Vector2(900, 334), "Produced %d / job %s" % [rear.produced, "none" if rear.job.is_empty() else "ACTIVE"], 17)
	if not rear.job.is_empty():
		var fraction: float = clampf((world.elapsed - rear.job.started_at) / 4.0, 0, 1)
		draw_rect(Rect2(900, 482, 330, 12), Color("34463e"))
		draw_rect(Rect2(900, 482, 330 * fraction, 12), Color("a8dfba"))
		label_at(Vector2(900, 525), "Avatar / %.1f of 4 seconds" % (world.elapsed - rear.job.started_at), 17)
		label_at(Vector2(900, 553), "Input: 1 Metal / output pending", 16)
	elif not rear.production_history.is_empty():
		label_at(Vector2(900, 507), "Completed: 1 Metal -> 8 rounds", 17)
		label_at(Vector2(900, 535), "4 seconds / Avatar labor / rear-owned", 15)
	else:
		label_at(Vector2(900, 507), "No automatic production from a card", 16)
	label_at(Vector2(900, 595), "Capability is permission; ammo is stock.", 16)
	label_at(Vector2(900, 625), "Fresh battle proof uses detached values.", 15)
	label_at(Vector2(28, 777), status, 16, Color("dfcf9e"))
