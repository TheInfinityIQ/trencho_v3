extends RefCounted

const Meta = preload("res://meta_session.gd")
const Campaign = preload("res://campaign.gd")
const Cards = preload("res://card_progression.gd")
const Scenario = preload("res://scenario.gd")
const SCHEMA_VERSION := 1
const MAX_TEXT_BYTES := 2000000
const CHECKPOINTS := ["BETWEEN_BATTLES", "CAMPAIGN_ENDED", "OUT_OF_CAMPAIGN_META"]
var progression
var checkpoint := ""
var save_identity := "Trencho-safe-checkpoint"
var revision := 0
var reason := ""

func _init(with_between_fixture := false) -> void:
	if with_between_fixture:
		progression = Meta.new(false, {}, {}, true)
		progression.cards.purchase(1)
		progression.cards.select_card(progression.cards.open_drop().id, "tech.bolt_ammo")
		var prepared: bool = progression.campaign.transition()
		assert(prepared)
		progression.campaign.data.organizational_history.back().event = "next battle prepared"
		# Discard all old/fresh runtime projections. This safe point contains only
		# progression and archive values; Battle 2 has not advanced.
		progression.campaign.world = null
		progression.campaign.archived_worlds.clear()
		checkpoint = "BETWEEN_BATTLES"

func pack(value):
	if value is int:
		return {"$value": "int", "text": str(value)}
	if value is Vector2:
		return {"$value": "Vector2", "x": value.x, "y": value.y}
	if value is Rect2:
		return {"$value": "Rect2", "position": pack(value.position), "size": pack(value.size)}
	if value is Array:
		return value.map(pack)
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = pack(value[key])
		return result
	return value

func unpack(value):
	if value is Array:
		return value.map(unpack)
	if value is Dictionary:
		if value.has("$value"):
			if value["$value"] == "float64" and value.get("hex") is String and value.hex.length() == 16 and value.hex.is_valid_hex_number():
				return value.hex.hex_decode().decode_double(0)
			if value["$value"] == "int" and value.get("text") is String and value.text.is_valid_int():
				return int(value.text)
			if value["$value"] == "Vector2" and value.get("x") is float and value.get("y") is float:
				return Vector2(value.x, value.y)
			if value["$value"] == "Rect2":
				var point = unpack(value.get("position"))
				var size_value = unpack(value.get("size"))
				if point is Vector2 and size_value is Vector2:
					return Rect2(point, size_value)
			reason = "INVALID_SAVE_VALUE"
			return null
		var result := {}
		for key in value:
			result[key] = unpack(value[key])
		return result
	return value

func values_only(value) -> bool:
	if value is Object:
		return false
	if value is Dictionary:
		return value.values().all(values_only)
	if value is Array:
		return value.all(values_only)
	return true

func campaign_values() -> Dictionary:
	var data: Dictionary = progression.campaign.data.duplicate(true)
	var metadata: Array = []
	for archive in data.completed_battles:
		var record := {}
		for key in ["battle_index", "outcome", "terminal_time", "world_time", "hq_history"]:
			record[key] = archive[key].duplicate(true) if archive[key] is Array or archive[key] is Dictionary else archive[key]
		metadata.append(record)
	data.completed_battles = metadata
	return data

func serialize() -> String:
	reason = ""
	if progression == null:
		reason = "NO_PROGRESSION_SESSION"
		return ""
	var campaign = progression.campaign
	if campaign.world != null and campaign.world.battle_active():
		reason = "MID_BATTLE_SAVE_DEFERRED"
		return ""
	if not progression.cards.held_consumables().is_empty():
		reason = "UNSPENT_CONSUMABLE_PERSISTENCE_DEFERRED"
		return ""
	if not campaign.data.campaign_active:
		if checkpoint != "OUT_OF_CAMPAIGN_META":
			checkpoint = "CAMPAIGN_ENDED"
	elif checkpoint != "BETWEEN_BATTLES" or campaign.world != null:
		reason = "SAFE_CHECKPOINT_REQUIRED"
		return ""
	var data := campaign_values()
	if not values_only(data) or not values_only(progression.meta):
		reason = "RUNTIME_OBJECT_IN_SAVE"
		return ""
	revision += 1
	return JSON.stringify({"schema_version": SCHEMA_VERSION, "save_identity": save_identity, "revision": revision,
		"checkpoint": checkpoint, "meta": pack(progression.meta), "campaign": pack(data),
		"campaign_pool": progression.cards.unlocked_pool(), "proof_tier2": progression.cards.proof_tier2_access}, "\t", true, true)

func valid_payload(payload: Dictionary) -> bool:
	if not payload.has_all(["meta", "campaign", "campaign_pool", "proof_tier2", "checkpoint", "save_identity", "revision"]):
		return false
	if payload.checkpoint not in CHECKPOINTS or not payload.save_identity is String or payload.save_identity.is_empty() or not payload.revision is float or payload.revision < 1 or payload.revision != floor(payload.revision):
		return false
	if not payload.meta is Dictionary or not payload.campaign is Dictionary or not payload.campaign_pool is Array or not payload.proof_tier2 is bool:
		return false
	var meta: Dictionary = payload.meta
	var data: Dictionary = payload.campaign
	if not meta.has_all(["currency", "unlocked_card_ids", "reward_history", "unlock_history", "campaign_results", "active_campaign_id", "next_campaign"]) or not data.has_all(["campaign_id", "status", "campaign_active", "battle_index", "person_registry", "organizational_history", "capabilities", "completed_battles", "card_progression", "end_reason"]):
		return false
	if not meta.currency is int or meta.currency < 0 or not meta.next_campaign is int or meta.next_campaign < 2 or not meta.active_campaign_id is String or not data.campaign_id is String or data.campaign_id.is_empty() or not data.battle_index is int or data.battle_index not in [1, 2] or not data.campaign_active is bool:
		return false
	for key in ["unlocked_card_ids", "reward_history", "unlock_history", "campaign_results"]:
		if not meta[key] is Array:
			return false
	var seen := {}
	for identity in meta.unlocked_card_ids:
		if not identity is String or not Cards.DEFINITIONS.has(identity) or seen.has(identity):
			return false
		seen[identity] = true
	for identity in payload.campaign_pool:
		if identity not in meta.unlocked_card_ids:
			return false
	if not data.person_registry is Dictionary or not data.capabilities is Dictionary or not data.organizational_history is Array or not data.completed_battles is Array or not data.card_progression is Dictionary:
		return false
	for identity in data.person_registry:
		var person = data.person_registry[identity]
		if not person is Dictionary or not person.has_all(["id", "formal_rank", "normal_role", "squad_command_qualified", "engineer_qualified", "medic_qualified", "rifle_proficiency", "medical_state", "fit_survivor", "personal_history", "appointment_history", "permanent_history"]) or person.id != identity:
			return false
	for identity in Campaign.NEXT_SQUAD + ["P1-PL", "P1-A.1"]:
		if not data.person_registry.has(identity):
			return false
	var cards: Dictionary = data.card_progression
	if not cards.has_all(["currency", "acquired_cards", "drops", "next_drop", "history", "consumables", "resolutions"]) or not cards.consumables is Dictionary or not cards.acquired_cards is Array or not cards.history is Array or not cards.drops is Array or not cards.resolutions is Array or not cards.currency is Dictionary or not cards.currency.get("DropToken") is int:
		return false
	for item in cards.consumables.values():
		if not item is Dictionary or item.get("state") != "CONSUMED" or not item.get("consumed", false) or not item.get("grant_delivered", false):
			return false
	if payload.checkpoint == "BETWEEN_BATTLES":
		if data.status != "ACTIVE" or not data.campaign_active or data.battle_index != 2 or meta.active_campaign_id != data.campaign_id:
			return false
	else:
		if data.status not in ["COMPLETED_SUCCESS", "ABANDONED", "ENDED_DEFEAT"] or data.campaign_active or meta.active_campaign_id != "":
			return false
	return true

func load_serialized(text: String) -> bool:
	reason = ""
	if text.to_utf8_buffer().size() > MAX_TEXT_BYTES:
		reason = "SAVE_TOO_LARGE"
		return false
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		reason = "MALFORMED_SAVE"
		return false
	var raw: Dictionary = parser.data
	if not raw.has("schema_version"):
		reason = "MISSING_SAVE_FIELDS"
		return false
	if raw.schema_version != SCHEMA_VERSION:
		reason = "UNSUPPORTED_SAVE_VERSION"
		return false
	if not raw.has_all(["meta", "campaign"]):
		reason = "MISSING_SAVE_FIELDS"
		return false
	var candidate: Dictionary = raw.duplicate(true)
	candidate.meta = unpack(raw.meta)
	candidate.campaign = unpack(raw.campaign)
	if not reason.is_empty():
		return false
	if not valid_payload(candidate):
		reason = "INVALID_SAVE_STRUCTURE"
		return false
	# Construct a replacement without initialization, simulation or settlement.
	# Commit this reference only after full bounded validation/construction.
	var replacement = Meta.new(false, candidate.meta, candidate.campaign)
	replacement.cards = Cards.new(replacement.campaign.data, true, candidate.campaign_pool, candidate.proof_tier2)
	progression = replacement
	checkpoint = candidate.checkpoint
	save_identity = candidate.save_identity
	revision = int(candidate.revision)
	return true

func start_next_battle() -> bool:
	reason = ""
	if checkpoint != "BETWEEN_BATTLES" or progression.campaign.world != null:
		reason = "BETWEEN_BATTLES_REQUIRED"
		return false
	var campaign = progression.campaign
	var members: Array = []
	for index in range(Campaign.NEXT_SQUAD.size()):
		var person: Dictionary = campaign.data.person_registry[Campaign.NEXT_SQUAD[index]]
		if not person.fit_survivor or person.medical_state != "FIT":
			reason = "UNSUPPORTED_NONFIT_ROSTER"
			return false
	for index in range(Campaign.NEXT_SQUAD.size()):
		members.append(campaign.fresh_person(campaign.data.person_registry[Campaign.NEXT_SQUAD[index]], Vector2.ZERO, 43 + index * 1.2))
	var leader = campaign.fresh_person(campaign.data.person_registry["P1-PL"], Vector2(130, 280), 47)
	campaign.world = Scenario.new(true, true, true, true, true, true, true, true, {"main_members": members, "platoon_leader": leader, "fresh_prefix": "B2-"})
	campaign.world.combat.encounter_over = true
	campaign.bind_capabilities(campaign.world)
	campaign.data.organizational_history.append({"event": "battle entered after checkpoint", "battle_index": 2, "time": 0.0})
	checkpoint = ""
	return true
