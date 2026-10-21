extends RefCounted

const Meta = preload("res://meta_session.gd")
const Operations = preload("res://operations.gd")
const Priority = preload("res://priority_operations.gd")
const Checkpoint = preload("res://checkpoint.gd")
var progression = Meta.new(false, {}, {}, false, true)
var operations
var phase := "ACTIVE"
var reason := ""
var restored_checkpoint

func _init() -> void:
	# The initial capability uses the existing card ownership path. It supplies
	# knowledge only: every round still needs Metal, work and physical delivery.
	progression.cards.purchase(1)
	progression.cards.select_card(progression.cards.open_drop().id, "tech.bolt_ammo")
	operations = Operations.new(progression.campaign.world)
	progression.campaign.bind_capabilities(operations.world)

func advance(delta: float) -> void:
	if phase != "ACTIVE":
		return
	operations.advance(delta)
	if operations.world.battle_active():
		return
	if operations.world.battle_state == "ENDED_FRIENDLY_VICTORY" and progression.campaign.data.battle_index == 1:
		phase = "INTERMISSION"
		return
	# Settle through the accepted guarded Meta result path exactly once.
	var campaign = progression.campaign
	for identity in campaign.data.person_registry:
		var person = campaign.find_person(campaign.world, identity)
		if person != null:
			campaign.data.person_registry[identity] = campaign.profile(person, campaign.data.battle_index)
	campaign.data.completed_battles.append(campaign.archive_snapshot(campaign.world, campaign.data.battle_index))
	progression.process_result()
	phase = "FINAL"

func continue_campaign() -> bool:
	reason = ""
	if phase != "INTERMISSION":
		reason = "EXPLICIT_INTERMISSION_REQUIRED"
		return false
	if restored_checkpoint != null:
		if not restored_checkpoint.start_next_battle():
			reason = restored_checkpoint.reason
			return false
	else:
		if not progression.campaign.transition():
			reason = progression.campaign.transition_reason
			return false
	operations = Priority.new(progression.campaign.world)
	progression.campaign.bind_capabilities(operations.world)
	phase = "ACTIVE"
	return true

func intermission_checkpoint() -> String:
	if phase != "INTERMISSION":
		reason = "INTERMISSION_REQUIRED"
		return ""
	var checkpoint = Checkpoint.new()
	if restored_checkpoint != null:
		checkpoint = restored_checkpoint
	else:
		# Prepare a detached progression copy, without advancing either world.
		# SAV021 stores a prepared BETWEEN_BATTLES value checkpoint at index2.
		var copy = Meta.new(false, progression.meta, progression.campaign.data)
		copy.campaign.world = progression.campaign.world
		if not copy.campaign.transition():
			reason = copy.campaign.transition_reason
			return ""
		copy.campaign.world = null
		copy.campaign.archived_worlds.clear()
		checkpoint.progression = copy
		checkpoint.checkpoint = "BETWEEN_BATTLES"
	var result: String = checkpoint.serialize()
	reason = checkpoint.reason
	return result

func load_intermission(text: String) -> bool:
	if phase != "INTERMISSION":
		reason = "INTERMISSION_REQUIRED"
		return false
	var checkpoint = Checkpoint.new()
	if not checkpoint.load_serialized(text) or checkpoint.checkpoint != "BETWEEN_BATTLES":
		reason = "VALID_BETWEEN_BATTLES_CHECKPOINT_REQUIRED"
		return false
	progression = checkpoint.progression
	restored_checkpoint = checkpoint
	reason = ""
	return true

func enter_meta() -> bool:
	if phase != "FINAL" or not progression.shop_accessible():
		return false
	phase = "OUT_META"
	return true

func roster_text() -> String:
	var campaign = progression.campaign
	var lines: Array[String] = []
	var identities: Array = campaign.data.person_registry.keys()
	identities.sort()
	for identity in identities:
		var record: Dictionary = campaign.data.person_registry[identity]
		var person = campaign.find_person(campaign.world, identity) if campaign.world != null else null
		if person != null:
			record = campaign.profile(person, campaign.data.battle_index)
		var last_event: String = str(record.personal_history.back().event) if not record.personal_history.is_empty() else "none"
		lines.append("%s / %s / %s / %s / history %d+%d+%d / latest: %s" % [identity, record.formal_rank, record.normal_role, record.medical_state, record.personal_history.size(), record.appointment_history.size(), record.permanent_history.size(), last_event])
	var dead := 0
	for identity in campaign.data.person_registry:
		var person = campaign.find_person(campaign.world, identity) if campaign.world != null else null
		var record: Dictionary = campaign.profile(person, campaign.data.battle_index) if person != null else campaign.data.person_registry[identity]
		if record.medical_state == "DEAD":
			dead += 1
	lines.append("Registered survivors %d / dead %d. Battle 2 deployment: %s + P1-PL" % [campaign.data.person_registry.size() - dead, dead, ", ".join(campaign.NEXT_SQUAD)])
	return "\n".join(lines)

func archive_text() -> String:
	var campaign = progression.campaign
	var lines: Array[String] = []
	for archive in campaign.data.completed_battles:
		lines.append("BATTLE %d / %s / HQ terminal T%.2f" % [archive.battle_index, archive.outcome, archive.terminal_time])
	for record in campaign.data.organizational_history:
		if record.has("surviving_person_ids"):
			lines.append("B1 survivors: %s\nB1 dead: %s" % [", ".join(record.surviving_person_ids), ", ".join(record.dead_person_ids) if not record.dead_person_ids.is_empty() else "none"])
	return "\n".join(lines)
