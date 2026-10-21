extends RefCounted

const Campaign = preload("res://campaign.gd")
const Cards = preload("res://card_progression.gd")
const Scenario = preload("res://scenario.gd")
var campaign
var cards
var probe_data: Dictionary = {}
var probe_world
var probe_cards
var with_consumable := false
var probe_reason := ""

func _init(include_consumable := false) -> void:
	with_consumable = include_consumable
	# Explicit CAR-018 campaign fixture starts without ammo capability. Default
	# CAM-017 remains unchanged. Reach its real terminal boundary before Battle 2.
	campaign = Campaign.new(false)
	for tick in range(1500):
		campaign.advance(1.0 / 60.0)
		if not campaign.world.battle_active():
			break
	var transitioned: bool = campaign.transition()
	assert(transitioned)
	cards = Cards.new(campaign.data, with_consumable)

func advance(delta: float) -> void:
	campaign.advance(delta)

func purchase() -> bool:
	return cards.purchase(1)

func select_card(drop_id: String, identity: String) -> bool:
	if not cards.select_card(drop_id, identity):
		return false
	campaign.bind_capabilities(campaign.world)
	return true

func use_consumable(identity: String) -> bool:
	if not campaign.world.battle_active():
		cards.reason = "BATTLE_ENDED"
		return false
	return cards.use_consumable(identity, campaign.world.rear, campaign.world.elapsed)

func build_reconstruction_probe() -> bool:
	# Permitted detached-state reconstruction proof, NOT a Battle 2 outcome or
	# an active-battle transition. Source campaign/world remain authoritative.
	if not cards.held_consumables().is_empty():
		probe_reason = "UNSPENT_CONSUMABLE_PERSISTENCE_DEFERRED"
		return false
	probe_reason = ""
	probe_data = campaign.data.duplicate(true)
	probe_data.battle_index = 3
	var members: Array = []
	for index in range(campaign.NEXT_SQUAD.size()):
		var identity: String = campaign.NEXT_SQUAD[index]
		var record: Dictionary = campaign.profile(campaign.find_person(campaign.world, identity), 2)
		probe_data.person_registry[identity] = record.duplicate(true)
		members.append(campaign.fresh_person(record, Vector2.ZERO, 43.0 + index * 1.2, 3))
	var leader_record: Dictionary = campaign.profile(campaign.find_person(campaign.world, "P1-PL"), 2)
	probe_data.person_registry["P1-PL"] = leader_record.duplicate(true)
	var leader = campaign.fresh_person(leader_record, Vector2(130, 280), 47, 3)
	probe_world = Scenario.new(true, true, true, true, true, true, true, true,
		{"main_members": members, "platoon_leader": leader, "fresh_prefix": "B3-"})
	probe_world.battle.auto_strike = false
	probe_world.combat.encounter_over = true
	probe_cards = Cards.new(probe_data, with_consumable)
	probe_world.rear.capability_unlocked = bool(probe_data.capabilities.get("BoltActionAmmoProduction", false))
	return true
