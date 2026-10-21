extends RefCounted

# PA-CAR-001: immutable proof availability, not a meta shop or run ownership.
const DEFINITIONS := {
	"tech.bolt_ammo": {"id": "tech.bolt_ammo", "name": "Bolt-Action Ammunition Production", "tier": 1, "category": "Logistics", "type": "TECHNOLOGY", "capability": "BoltActionAmmoProduction"},
	"tech.engineering": {"id": "tech.engineering", "name": "Field Engineering", "tier": 1, "category": "Engineering", "type": "TECHNOLOGY", "capability": "FieldEngineering"},
	"tech.medical": {"id": "tech.medical", "name": "Medical Support", "tier": 1, "category": "Medical", "type": "TECHNOLOGY", "capability": "MedicalSupport"},
	"tech.mortar": {"id": "tech.mortar", "name": "Mortar Support", "tier": 2, "category": "Artillery", "type": "TECHNOLOGY", "capability": "MortarSupport"},
	"cons.ammo_emergency_shipment": {"id": "cons.ammo_emergency_shipment", "name": "Emergency Ammunition Shipment", "tier": 1, "category": "Logistics", "type": "CONSUMABLE", "capability": "", "effect": {"type": "RESOURCE_GRANT", "resource": "BoltActionRifleAmmo", "quantity": 8}}}
const UNLOCKED := ["tech.bolt_ammo", "tech.engineering", "tech.medical", "tech.mortar"]
const OFFER_COUNT := 3
var campaign: Dictionary
var state: Dictionary
var reason := ""
var fixture_unlocked: Array
var proof_tier2_access := false

func _init(campaign_data: Dictionary, with_consumable := false, unlocked_override = null, allow_proof_tier2 := false) -> void:
	campaign = campaign_data
	fixture_unlocked = UNLOCKED.duplicate()
	if with_consumable:
		fixture_unlocked.push_front("cons.ammo_emergency_shipment")
	if unlocked_override != null:
		fixture_unlocked = unlocked_override.duplicate(true)
	proof_tier2_access = allow_proof_tier2
	if not campaign.has("card_progression"):
		campaign.card_progression = {"currency": {"DropToken": 1}, "acquired_cards": [], "drops": [], "next_drop": 1, "history": []}
	state = campaign.card_progression
	if not state.has("consumables"):
		state.consumables = {}
		state.resolutions = []

func definitions() -> Dictionary:
	var result := {}
	for identity in fixture_unlocked:
		result[identity] = DEFINITIONS[identity].duplicate(true)
	return result

func unlocked_pool() -> Array:
	return fixture_unlocked.duplicate()

func eligible(tier: int) -> Array:
	return fixture_unlocked.filter(func(identity): return DEFINITIONS[identity].tier == tier and identity not in state.acquired_cards)

func open_drop() -> Dictionary:
	for drop in state.drops:
		if drop.state == "OFFERED":
			return drop.duplicate(true)
	return {}

func purchase(tier := 1) -> bool:
	reason = ""
	if tier != 1 and not (tier == 2 and proof_tier2_access):
		reason = "ONLY_TIER1_PROOF_DEFINED"
		return false
	if state.currency.DropToken < 1:
		reason = "INSUFFICIENT_DROP_TOKENS"
		return false
	if not open_drop().is_empty():
		reason = "OFFER_ALREADY_OPEN"
		return false
	var candidates := eligible(tier)
	# Never fill a three-card offer with a duplicate, acquired card or wrong tier.
	var count := OFFER_COUNT if tier == 1 else 1
	if candidates.size() < count:
		reason = "INSUFFICIENT_ELIGIBLE_CARDS"
		return false
	var drop := {"id": "tier%d-drop-%d" % [tier, state.next_drop], "tier": tier, "state": "OFFERED", "candidates": candidates.slice(0, count), "selected_card": ""}
	state.currency.DropToken -= 1
	state.next_drop += 1
	state.drops.append(drop)
	state.history.append({"event": "drop purchased", "drop": drop.id, "tier": tier, "cost": 1, "currency": "DropToken"})
	return true

func select_card(drop_id: String, card_id: String) -> bool:
	reason = ""
	var found: Dictionary = {}
	for drop in state.drops:
		if drop.id == drop_id:
			found = drop
			break
	if found.is_empty():
		reason = "UNKNOWN_DROP"
		return false
	if found.state != "OFFERED":
		reason = "DROP_CLOSED"
		return false
	if card_id not in found.candidates or not DEFINITIONS.has(card_id):
		reason = "CARD_NOT_OFFERED"
		return false
	if card_id in state.acquired_cards:
		reason = "CARD_ALREADY_ACQUIRED"
		return false
	state.acquired_cards.append(card_id)
	found.selected_card = card_id
	found.state = "SELECTED"
	state.history.append({"event": "card acquired", "drop": drop_id, "card": card_id})
	if DEFINITIONS[card_id].type == "CONSUMABLE":
		state.consumables[card_id] = {"instance_id": str(campaign.get("campaign_id", "fixture")) + ":" + card_id,
			"card": card_id, "state": "HELD", "acquired": true, "consumed": false, "grant_delivered": false,
			"effect": DEFINITIONS[card_id].effect.duplicate(true)}
	var capability: String = DEFINITIONS[card_id].capability
	if not capability.is_empty():
		campaign.capabilities[capability] = true
		state.history.append({"event": "capability activated", "card": card_id, "capability": capability})
	return true

func held_consumables() -> Array:
	return state.consumables.keys().filter(func(identity): return state.consumables[identity].state == "HELD")

func use_consumable(card_id: String, rear, now: float) -> bool:
	reason = ""
	if not DEFINITIONS.has(card_id) or card_id not in fixture_unlocked:
		reason = "UNKNOWN_CARD"
		return false
	if DEFINITIONS[card_id].type != "CONSUMABLE":
		reason = "WRONG_CARD_TYPE"
		return false
	if card_id not in state.acquired_cards or not state.consumables.has(card_id):
		reason = "CONSUMABLE_NOT_ACQUIRED"
		return false
	var held: Dictionary = state.consumables[card_id]
	if held.state != "HELD" or held.consumed or held.grant_delivered:
		reason = "CONSUMABLE_ALREADY_SPENT"
		return false
	var effect: Dictionary = held.effect
	if effect != DEFINITIONS[card_id].effect or effect.get("type", "") != "RESOURCE_GRANT" or effect.get("resource", "") != "BoltActionRifleAmmo" or typeof(effect.get("quantity")) != TYPE_INT or int(effect.quantity) <= 0:
		reason = "INVALID_EFFECT_PAYLOAD"
		return false
	if rear == null or not rear.receive_consumable_grant(held.instance_id, card_id, effect.quantity, now):
		reason = "PHYSICAL_GRANT_REJECTED"
		return false
	held.state = "CONSUMED"
	held.consumed = true
	held.grant_delivered = true
	var event := {"event": "consumable resolved", "card": card_id, "instance": held.instance_id,
		"time": now, "resource": effect.resource, "quantity": effect.quantity, "destination": "rear-finished-stock", "ownership": "rear"}
	state.resolutions.append(event)
	state.history.append(event.duplicate(true))
	return true
