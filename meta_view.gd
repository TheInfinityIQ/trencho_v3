extends Node2D

const Session = preload("res://meta_session.gd")
var session = Session.new()
var font := ThemeDB.fallback_font
var status := "Active final battle: meta shop requires ending this campaign."

func button(text: String, point: Vector2, size: Vector2, action: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.position = point
	item.size = size
	item.pressed.connect(action)
	add_child(item)

func _ready() -> void:
	button("TRY META UNLOCK / COST 1", Vector2(895, 420), Vector2(330, 40), unlock)
	button("START NEW CAMPAIGN", Vector2(895, 560), Vector2(330, 40), start_new)
	button("ABANDON ACTIVE CAMPAIGN / NO REWARD", Vector2(45, 610), Vector2(770, 40), abandon)
	button("PROOF TIER 2 DROP / 1 FIXTURE TOKEN", Vector2(45, 665), Vector2(770, 40), offer)

func unlock() -> void:
	status = "Meta Token spent: tech.mortar unlocked for future eligibility only." if session.unlock() else session.reason

func start_new() -> void:
	status = "New campaign: inherited eligibility; zero cards acquired, MortarSupport inactive." if session.start_campaign() else session.reason

func abandon() -> void:
	status = "Campaign abandoned. No completion reward." if session.abandon() else session.reason

func offer() -> void:
	status = "Tier 2 offer generated; Mortar Support still unacquired." if session.purchase_future_tier2() else session.reason

func _physics_process(delta: float) -> void:
	var was_active: bool = session.campaign.data.campaign_active
	session.advance(delta)
	if was_active and not session.campaign.data.campaign_active:
		status = "Campaign ended: " + session.campaign.data.status + " / reward recorded once."
	queue_redraw()

func label_at(point: Vector2, text: String, size := 16, color := Color("dce7df")) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	var data: Dictionary = session.campaign.data
	var world = session.campaign.world
	draw_rect(Rect2(24, 105, 830, 635), Color("182b2b"))
	draw_rect(Rect2(875, 105, 380, 635), Color("112025"))
	label_at(Vector2(28, 40), "TRENCHO / CAMPAIGN COMPLETION AND META UNLOCK", 24)
	label_at(Vector2(28, 76), "Two-battle campaign / one completion reward / unlock eligibility stays separate from ownership", 16)
	label_at(Vector2(45, 145), data.campaign_id + " / " + data.status, 22)
	label_at(Vector2(45, 185), "Battle %d / local T%.2f / %s" % [data.battle_index, world.elapsed, world.battle_state], 18)
	label_at(Vector2(45, 225), "Friendly-HQ " + world.battle.hqs["Friendly-HQ"].state + " / Enemy-HQ " + world.battle.hqs["Enemy-HQ"].state, 18)
	label_at(Vector2(45, 263), "Archived Battle 1 records: " + str(data.completed_battles.size()), 17)
	label_at(Vector2(45, 301), "Campaign acquired: " + (", ".join(session.cards.state.acquired_cards) if not session.cards.state.acquired_cards.is_empty() else "none"), 17)
	label_at(Vector2(45, 338), "MortarSupport capability: " + str(data.capabilities.get("MortarSupport", false)), 18)
	label_at(Vector2(45, 374), "Rear ammo %d / existing fixture mortar shells %d" % [world.rear.ammunition, world.artillery.inventory.MortarShell], 17)
	label_at(Vector2(45, 410), "End reason: " + (data.end_reason if not data.end_reason.is_empty() else "none"), 16)
	var offer_data: Dictionary = session.cards.open_drop()
	label_at(Vector2(45, 461), "FUTURE CAMPAIGN OFFER / NOT ACQUISITION", 20)
	label_at(Vector2(45, 498), "No open offer" if offer_data.is_empty() else "Tier %d / %s / %s" % [offer_data.tier, offer_data.id, ", ".join(offer_data.candidates)], 16)
	label_at(Vector2(45, 535), "Drop Tokens: %d / selected card: none" % session.cards.state.currency.DropToken, 17)
	label_at(Vector2(45, 573), "Meta unlock never adds campaign cards, capabilities or physical assets.", 16)
	label_at(Vector2(895, 145), "META TOKEN: %d" % session.meta.currency, 25, Color("d8c58c"))
	label_at(Vector2(895, 183), "Shop " + ("ACCESSIBLE" if session.shop_accessible() else "BLOCKED / active campaign"), 17)
	label_at(Vector2(895, 220), "META UNLOCKED IDS", 18)
	for index in range(session.meta.unlocked_card_ids.size()):
		label_at(Vector2(895, 250 + index * 25), session.meta.unlocked_card_ids[index], 15)
	label_at(Vector2(895, 392), "Locked eligible: " + ", ".join(session.eligible_meta_unlocks()), 14)
	label_at(Vector2(895, 500), "Reward events: %d / Unlocks: %d" % [session.meta.reward_history.size(), session.meta.unlock_history.size()], 17)
	label_at(Vector2(895, 532), "Ended campaign records: %d" % session.meta.campaign_results.size(), 16)
	label_at(Vector2(895, 640), "Old campaigns retained: %d" % session.archived_campaigns.size(), 16)
	label_at(Vector2(895, 680), "Meta values live outside campaigns.", 16)
	label_at(Vector2(895, 711), "In-memory proof / no save-load", 15)
	label_at(Vector2(28, 779), status, 16, Color("dfcf9e"))
