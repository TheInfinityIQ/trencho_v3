extends "res://card_view.gd"

const CONSUMABLE := "cons.ammo_emergency_shipment"
var use_button: Button

func _init() -> void:
	session = Session.new(true)
	# A resource windfall must work with zero Metal and no production facilities.
	session.campaign.world.rear.metal = 0
	status = "Consumable proof: select the shipment, then explicitly use it once."

func _ready() -> void:
	super._ready()
	use_button = button("USE EMERGENCY SHIPMENT ONCE", Vector2(45, 535), Vector2(780, 42), use_card)
	refresh()

func choose(index: int) -> void:
	var drop: Dictionary = session.cards.open_drop()
	if drop.is_empty():
		return
	var identity: String = drop.candidates[index]
	if session.select_card(drop.id, identity):
		status = "Card acquired. Consumable HELD; no grant until explicit use." if identity == CONSUMABLE else "Technology acquired; no free stock."
	else:
		status = session.cards.reason
	refresh()

func use_card() -> void:
	status = "One-time grant delivered: 8 rear-owned rounds; authorization policy unchanged." if session.use_consumable(CONSUMABLE) else session.cards.reason
	refresh()

func probe() -> void:
	if session.build_reconstruction_probe():
		showing_probe = true
		status = "Detached next-battle probe: spent history retained; no usable card or physical ammo carried."
	else:
		status = session.probe_reason
	refresh()

func refresh() -> void:
	super.refresh()
	if use_button != null:
		use_button.visible = not showing_probe and session.cards.state.consumables.has(CONSUMABLE)
	probe_button.disabled = showing_probe or session.cards.state.acquired_cards.is_empty() or not session.cards.held_consumables().is_empty()

func _draw() -> void:
	super._draw()
	var cards = session.probe_cards if showing_probe else session.cards
	var world = session.probe_world if showing_probe else session.campaign.world
	if cards.open_drop().is_empty() and cards.state.consumables.has(CONSUMABLE):
		var item: Dictionary = cards.state.consumables[CONSUMABLE]
		label_at(Vector2(45, 420), "ACQUIRED %s / CONSUMED %s / DELIVERED %s" % [str(item.acquired), str(item.consumed), str(item.grant_delivered)], 18)
		label_at(Vector2(45, 452), "Usable held instances: %d / resolution events: %d" % [cards.held_consumables().size(), cards.state.resolutions.size()], 17)
		label_at(Vector2(45, 484), "RESOURCE_GRANT / BoltActionRifleAmmo / exactly 8", 17)
		label_at(Vector2(45, 514), "State: " + item.state + " / policy: " + world.rear.policy + " / military draw: " + str(world.rear.eligible()), 17)
		if not cards.state.resolutions.is_empty():
			label_at(Vector2(45, 596), "Provenance: campaign consumable -> rear finished stock", 16)
