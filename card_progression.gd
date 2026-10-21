extends RefCounted

# PA-CAR-001: immutable proof availability, not a meta shop or run ownership.
const DEFINITIONS := {
	"tech.bolt_ammo": {"id": "tech.bolt_ammo", "name": "Bolt-Action Ammunition Production", "tier": 1, "category": "Logistics", "type": "TECHNOLOGY", "capability": "BoltActionAmmoProduction"},
	"tech.engineering": {"id": "tech.engineering", "name": "Field Engineering", "tier": 1, "category": "Engineering", "type": "TECHNOLOGY", "capability": "FieldEngineering"},
	"tech.medical": {"id": "tech.medical", "name": "Medical Support", "tier": 1, "category": "Medical", "type": "TECHNOLOGY", "capability": "MedicalSupport"},
	"tech.mortar": {"id": "tech.mortar", "name": "Mortar Support", "tier": 2, "category": "Artillery", "type": "TECHNOLOGY", "capability": "MortarSupport"}}
const UNLOCKED := ["tech.bolt_ammo", "tech.engineering", "tech.medical", "tech.mortar"]
const OFFER_COUNT := 3
var campaign: Dictionary
var state: Dictionary
var reason := ""

func _init(campaign_data: Dictionary) -> void:
	campaign = campaign_data
	if not campaign.has("card_progression"):
		campaign.card_progression = {"currency": {"DropToken": 1}, "acquired_cards": [], "drops": [], "next_drop": 1, "history": []}
	state = campaign.card_progression

func definitions() -> Dictionary:
	return DEFINITIONS.duplicate(true)

func unlocked_pool() -> Array:
	return UNLOCKED.duplicate()

func eligible(tier: int) -> Array:
	return UNLOCKED.filter(func(identity): return DEFINITIONS[identity].tier == tier and identity not in state.acquired_cards)

func open_drop() -> Dictionary:
	for drop in state.drops:
		if drop.state == "OFFERED":
			return drop.duplicate(true)
	return {}

func purchase(tier := 1) -> bool:
	reason = ""
	if tier != 1:
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
	if candidates.size() < OFFER_COUNT:
		reason = "INSUFFICIENT_ELIGIBLE_CARDS"
		return false
	var drop := {"id": "tier1-drop-" + str(state.next_drop), "tier": tier, "state": "OFFERED", "candidates": candidates.slice(0, OFFER_COUNT), "selected_card": ""}
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
	var capability: String = DEFINITIONS[card_id].capability
	if not capability.is_empty():
		campaign.capabilities[capability] = true
		state.history.append({"event": "capability activated", "card": card_id, "capability": capability})
	return true
