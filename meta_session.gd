extends RefCounted

const Campaign = preload("res://campaign.gd")
const Cards = preload("res://card_progression.gd")
const INITIAL_UNLOCKED := ["tech.bolt_ammo", "tech.engineering", "tech.medical", "cons.ammo_emergency_shipment"]
const META_ELIGIBLE := ["tech.mortar"]
# Persistent value state outside any campaign. Runtime references below never
# enter this tree. This is in-memory persistence, not save/load.
var meta := {"currency": 0, "unlocked_card_ids": INITIAL_UNLOCKED.duplicate(), "unlock_history": [],
	"reward_history": [], "campaign_results": [], "active_campaign_id": "", "next_campaign": 1}
var campaign
var cards
var archived_campaigns: Array = []
var reason := ""

func _init(defeat_fixture := false, restored_meta: Dictionary = {}, restored_campaign: Dictionary = {}, pause_between := false) -> void:
	if not restored_meta.is_empty():
		meta = restored_meta.duplicate(true)
		campaign = Campaign.new(false, "", restored_campaign)
		cards = Cards.new(campaign.data, true, meta.unlocked_card_ids, true)
		return
	start_campaign()
	# Accepted real Battle1 terminal -> explicit transition; no Battle3 in this
	# focused two-battle campaign. Only final Battle2 victory earns completion.
	for tick in range(1500):
		campaign.advance(1.0 / 60.0)
		if not campaign.world.battle_active():
			break
	if pause_between:
		return
	var transitioned: bool = campaign.transition()
	assert(transitioned)
	campaign.world.battle.auto_strike = true
	if defeat_fixture:
		campaign.world.battle.target_hq_id = "Friendly-HQ"

func start_campaign() -> bool:
	reason = ""
	if not str(meta.active_campaign_id).is_empty():
		reason = "ACTIVE_CAMPAIGN_MUST_END"
		return false
	if campaign != null:
		archived_campaigns.append(campaign)
	var identity := "MetaCampaign-" + str(meta.next_campaign)
	meta.next_campaign += 1
	campaign = Campaign.new(false, identity)
	campaign.data.status = "ACTIVE"
	campaign.data.end_reason = ""
	meta.active_campaign_id = identity
	# Snapshot meta eligibility, never campaign ownership. PA-META-006 enables a
	# one-candidate Tier2 offer for one fixture DropToken, not a final tier economy.
	cards = Cards.new(campaign.data, true, meta.unlocked_card_ids, true)
	return true

func eligible_meta_unlocks() -> Array:
	return META_ELIGIBLE.filter(func(identity): return Cards.DEFINITIONS.has(identity) and identity not in meta.unlocked_card_ids)

func shop_accessible() -> bool:
	return str(meta.active_campaign_id).is_empty()

func unlock() -> bool:
	reason = ""
	if not shop_accessible():
		reason = "ACTIVE_CAMPAIGN_MUST_END"
		return false
	var eligible := eligible_meta_unlocks()
	if eligible.is_empty():
		reason = "NO_ELIGIBLE_META_UNLOCKS"
		return false
	if meta.currency < 1:
		reason = "INSUFFICIENT_META_CURRENCY"
		return false
	var identity: String = eligible[0]
	meta.currency -= 1
	meta.unlocked_card_ids.append(identity)
	meta.unlock_history.append({"event": "meta card unlocked", "card": identity, "cost": 1, "currency": "MetaToken"})
	return true

func finish(status: String, end_reason: String) -> bool:
	if campaign.data.status != "ACTIVE" or not campaign.data.campaign_active or meta.active_campaign_id != campaign.data.campaign_id:
		reason = "CAMPAIGN_ALREADY_ENDED"
		return false
	if status == "COMPLETED_SUCCESS" and (campaign.data.battle_index != 2 or campaign.world.battle_state != "ENDED_FRIENDLY_VICTORY"):
		reason = "FINAL_VICTORY_REQUIRED"
		return false
	if status == "ENDED_DEFEAT" and campaign.world.battle_state != "ENDED_FRIENDLY_DEFEAT":
		reason = "ACTUAL_DEFEAT_REQUIRED"
		return false
	if status not in ["COMPLETED_SUCCESS", "ENDED_DEFEAT", "ABANDONED"]:
		reason = "INVALID_CAMPAIGN_OUTCOME"
		return false
	var reward := 1 if status == "COMPLETED_SUCCESS" else 0
	campaign.data.status = status
	campaign.data.end_reason = end_reason
	campaign.data.campaign_active = false
	meta.active_campaign_id = ""
	meta.campaign_results.append({"campaign": campaign.data.campaign_id, "status": status, "reason": end_reason, "reward": reward,
		"final_battle": campaign.data.battle_index, "battle_result": campaign.world.battle_state if campaign.world != null else "BETWEEN_BATTLES"})
	if reward > 0:
		meta.currency += reward
		meta.reward_history.append({"event": "successful campaign completion reward", "campaign": campaign.data.campaign_id, "quantity": reward, "currency": "MetaToken"})
	reason = ""
	return true

func process_result() -> bool:
	if campaign.data.status != "ACTIVE" or campaign.world == null:
		return false
	if campaign.world.battle_state == "ENDED_FRIENDLY_DEFEAT":
		return finish("ENDED_DEFEAT", "DEFEAT_REWARD_POLICY_DEFERRED")
	if campaign.data.battle_index == 2 and campaign.world.battle_state == "ENDED_FRIENDLY_VICTORY":
		return finish("COMPLETED_SUCCESS", "FINAL_BATTLE_FRIENDLY_VICTORY")
	return false

func abandon() -> bool:
	# If a genuine terminal result already exists, settle it before accepting a
	# stale abandon action. A completed success cannot be converted to abandonment.
	process_result()
	return finish("ABANDONED", "EXPLICIT_PLAYER_ABANDONMENT")

func advance(delta: float) -> void:
	if campaign.data.campaign_active:
		campaign.advance(delta)
		process_result()

func purchase_future_tier2() -> bool:
	if not campaign.data.campaign_active or campaign.data.battle_index != 1:
		reason = "NEW_ACTIVE_CAMPAIGN_REQUIRED"
		return false
	var purchased: bool = cards.purchase(2)
	reason = cards.reason
	return purchased

func snapshot_current() -> Dictionary:
	return {"data": campaign.data.duplicate(true), "world": campaign.archive_snapshot(campaign.world, campaign.data.battle_index),
		"artillery_inventory": campaign.world.artillery.inventory.duplicate(true), "artillery_missions": campaign.world.artillery.missions.duplicate(true),
		"card_receipts": campaign.world.rear.consumable_receipts.duplicate(true)}
