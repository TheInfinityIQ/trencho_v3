extends RefCounted

const Soldier = preload("res://soldier.gd")
var id: String
var soldiers: Array = []
var task := "Awaiting platoon intent"
var destination: Vector2
var route_side := "direct"
var decision: Dictionary = {}
var terrain: Rect2
var final_paths: Dictionary = {}
var suppression := 0
var suppression_decay_at := -1.0
var leadership_enabled := true
var formal_leader
var acting_leader
var leadership_state := "FORMAL_COMMAND"
var loss_time := -1.0
var deceased_leader_id := ""
var leader_reports: Array[Dictionary] = []
var leadership_log: Array[Dictionary] = []
var morale := 100
var morale_state := "STEADY"
var morale_log: Array[Dictionary] = []
var morale_reports: Array[Dictionary] = []
var casualty_morale_ids: Dictionary = {}
var suppression_episode_penalized := false
var last_incoming_at := -1.0
var routing_state := "NONE"
var routing_trigger: Dictionary = {}
var rally_destination := Vector2.ZERO
var rally_arrived_at := -1.0
var recovery_due_at := -1.0
const RANK := {"PRIVATE": 0, "CORPORAL": 1, "SERGEANT": 2, "LIEUTENANT": 3}

func mission_execution_available() -> bool:
	return command_available() and routing_state == "NONE"

func change_morale(amount: int, cause: String, now: float, person_id := "") -> void:
	var before := morale
	morale = clampi(morale + amount, 0, 100)
	morale_state = "STEADY" if morale >= 61 else ("SHAKEN" if morale >= 31 else "ROUTING")
	# Routing is latched until safe recovery reaches50, even above the entry band.
	if routing_state in ["RETREATING", "AT_RALLY"]:
		morale_state = "ROUTING"
	morale_log.append({"time": now, "cause": cause, "person": person_id, "before": before, "change": morale - before, "after": morale, "state": morale_state, "suppression": suppression})
	if morale <= 30 and routing_state == "NONE":
		routing_state = "PENDING_COMMAND"
		morale_state = "ROUTING"
		routing_trigger = morale_log.back().duplicate(true)

func combat_casualty(person, now: float) -> void:
	if person not in soldiers or casualty_morale_ids.has(person.id):
		return
	casualty_morale_ids[person.id] = true
	change_morale(-20, "Combat casualty", now, person.id)
	if person == formal_leader:
		change_morale(-20, "Formal Squad Leader death", now, person.id)

func receive_suppression(amount: int, now: float) -> void:
	suppression += amount
	if amount > 0:
		last_incoming_at = now
		suppression_decay_at = now + 2
	if suppression >= 4 and not suppression_episode_penalized:
		suppression_episode_penalized = true
		change_morale(-15, "Sustained suppression episode", now)

func decay_suppression(now: float) -> void:
	while suppression > 0 and suppression_decay_at >= 0 and now + 0.000001 >= suppression_decay_at:
		suppression -= 1
		suppression_decay_at += 2
	if suppression <= 1:
		suppression_episode_penalized = false

func morale_report(kind: String, now: float) -> void:
	morale_reports.append({"kind": kind, "squad": id, "observation_time": now, "sent_at": now,
		"morale": morale, "morale_state": morale_state, "routing_state": routing_state,
		"formal_leader": formal_leader.id if formal_leader != null else "",
		"acting_leader": acting_leader.id if acting_leader != null else "",
		"commander": current_leader().id if current_leader() != null else ""})

func retreat_path(start: Vector2, target: Vector2, clearance: float) -> Array[Vector2]:
	# Small visibility graph around the one known solid outcrop. Unlike the forward
	# fixture route, this supports a retreat from either side without crossing rock.
	var bounds := terrain.grow(clearance)
	var points: Array[Vector2] = [start, target, bounds.position,
		Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	var distance := [0.0, INF, INF, INF, INF, INF]
	var previous := [-1, -1, -1, -1, -1, -1]
	var visited := [false, false, false, false, false, false]
	for iteration in range(points.size()):
		var best := -1
		for index in range(points.size()):
			if not visited[index] and (best < 0 or distance[index] < distance[best]):
				best = index
		if best < 0 or is_inf(distance[best]):
			break
		visited[best] = true
		for index in range(points.size()):
			# Test against a slightly inset rectangle so travel along a corner/edge
			# is legal while every accepted segment retains the chosen clearance.
			if visited[index]:
				continue
			var inner := bounds.grow(-0.01)
			var corners := [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
			var blocked := inner.has_point(points[best]) or inner.has_point(points[index])
			for edge in range(4):
				blocked = blocked or Geometry2D.segment_intersects_segment(points[best], points[index], corners[edge], corners[(edge + 1) % 4]) != null
			var cost: float = distance[best] + points[best].distance_to(points[index])
			if not blocked and cost < distance[index]:
				distance[index] = cost
				previous[index] = best
	var result: Array[Vector2] = []
	var cursor := 1
	while cursor > 0 and previous[cursor] >= 0:
		result.push_front(points[cursor])
		cursor = previous[cursor]
	return result

func begin_routing(now: float) -> void:
	# The accepted contact is east of this outcrop. Its west face is the local
	# rearward rally cover, independent of the Platoon's existing objective.
	rally_destination = Vector2(terrain.position.x - 65, clampf(center().y, terrain.position.y + 65, terrain.end.y - 65))
	for index in range(soldiers.size()):
		var person = soldiers[index]
		if not person.active:
			continue
		person.route_origin = person.position
		var target := rally_destination + Vector2((index % 2) * 23 - 12, (index / 2) * 23 - 12)
		person.path = retreat_path(person.position, target, 10)
		person.waypoint = 0
		person.arrived = false
	routing_state = "RETREATING"
	morale_state = "ROUTING"
	morale_log.append({"time": now, "cause": "Local autonomous routing", "morale": morale, "rally": rally_destination, "intent": task, "commander": current_leader().id})
	morale_report("SQUAD_ROUTING", now)

func update_morale(now: float) -> void:
	if routing_state == "PENDING_COMMAND" and command_available():
		begin_routing(now)
	if routing_state == "RETREATING" and complete():
		routing_state = "AT_RALLY"
		rally_arrived_at = now
		morale_log.append({"time": now, "cause": "Rally cover reached", "morale": morale, "rally": rally_destination})
	if routing_state != "AT_RALLY":
		return
	if suppression > 1 or now + 0.000001 < last_incoming_at + 4:
		recovery_due_at = -1
		return
	if recovery_due_at < 0:
		recovery_due_at = now + 2
	if now + 0.000001 < recovery_due_at:
		return
	change_morale(mini(5, 50 - morale), "Safe rally recovery", now)
	# No unbounded catch-up, and unsafe time never earns recovery credit.
	recovery_due_at = now + 2
	if morale >= 50:
		routing_state = "RALLIED_HOLD"
		morale_state = "SHAKEN"
		morale_report("SQUAD_RALLIED", now)

func current_leader():
	if acting_leader != null and acting_leader.active:
		return acting_leader
	if formal_leader != null and formal_leader.active:
		return formal_leader
	return null

func command_available() -> bool:
	return not leadership_enabled or (leadership_state in ["FORMAL_COMMAND", "ACTING_COMMAND"] and current_leader() != null)

func eligibility_reason(person) -> String:
	if person not in soldiers:
		return "Not a member of this squad"
	if not person.active:
		return "Not alive/active"
	if not person.squad_command_qualified:
		return "Missing SquadCommand qualification"
	if int(RANK.get(person.formal_rank, -1)) < RANK.CORPORAL:
		return "Below Corporal rank"
	if person.normal_role in ["PlatoonLeader", "CompanyCommander", "OperationalCommander"]:
		return "Incompatible normal command role"
	if not person.acting_appointment.is_empty() and person.acting_appointment != "SquadLeader:" + id:
		return "Already acting in an incompatible command role"
	return "Eligible"

func recognize_leader_loss(now: float) -> void:
	if not leadership_enabled or leadership_state in ["DISRUPTION", "LEADERLESS_HOLD"]:
		return
	if current_leader() != null:
		return
	deceased_leader_id = acting_leader.id if acting_leader != null else formal_leader.id
	loss_time = now
	leadership_state = "DISRUPTION"
	leadership_log.append({"time": now, "squad": id, "deceased_leader": deceased_leader_id, "state": leadership_state, "intent": task, "reason": "Locally recognized real leader casualty"})

func update_leadership(now: float) -> void:
	if not leadership_enabled:
		return
	recognize_leader_loss(now)
	if leadership_state != "DISRUPTION" or now + 0.000001 < loss_time + 0.5:
		return
	var candidates: Array = []
	var reasons: Dictionary = {}
	for person in soldiers:
		reasons[person.id] = eligibility_reason(person)
		if reasons[person.id] == "Eligible":
			candidates.append(person)
	candidates.sort_custom(func(a, b): return RANK[a.formal_rank] > RANK[b.formal_rank] if RANK[a.formal_rank] != RANK[b.formal_rank] else a.id < b.id)
	if candidates.is_empty():
		acting_leader = null
		leadership_state = "LEADERLESS_HOLD"
	else:
		acting_leader = candidates[0]
		acting_leader.acting_appointment = "SquadLeader:" + id
		leadership_state = "ACTING_COMMAND"
	var replacement: String = acting_leader.id if acting_leader != null else ""
	leader_reports.append({"kind": "LEADER_CASUALTY", "squad": id, "deceased_leader": deceased_leader_id, "observation_time": loss_time, "acting_replacement": replacement, "sent_at": now})
	leadership_log.append({"time": now, "squad": id, "state": leadership_state, "acting": replacement, "intent": task, "candidate_reasons": reasons, "rank_unchanged": acting_leader.formal_rank if acting_leader != null else "no appointment"})
	print("LOCAL FIELD SUCCESSION: ", JSON.stringify(leadership_log.back()))

func carried_ammunition(category: String) -> int:
	var total := 0
	for soldier in soldiers:
		if soldier.active:
			total += int(soldier.inventory.get(category, 0))
	return total

func stage_for_supply() -> void:
	for soldier in soldiers:
		final_paths[soldier.id] = soldier.path.slice(1)
		soldier.path.resize(1)

func resume_final_approach() -> void:
	if not mission_execution_available():
		return
	for soldier in soldiers:
		soldier.route_origin = soldier.position
		soldier.path.assign(final_paths[soldier.id])
		soldier.waypoint = 0
		soldier.arrived = false

func _init(identity: String, start: Vector2, with_leadership := true) -> void:
	id = identity
	leadership_enabled = with_leadership
	for index in range(4):
		var offset := Vector2((index % 2) * 24, (index / 2) * 24)
		soldiers.append(Soldier.new("%s.%d" % [id, index + 1], start + offset, 43.0 + index * 1.2))
		soldiers[index].squad_id = id
	if leadership_enabled:
		formal_leader = soldiers[0]
		formal_leader.formal_rank = "SERGEANT"
		formal_leader.normal_role = "SquadLeader"
		formal_leader.squad_command_qualified = true
		soldiers[1].formal_rank = "CORPORAL"
		soldiers[1].normal_role = "AssistantSquadLeader"
		soldiers[1].squad_command_qualified = true

func center() -> Vector2:
	var result := Vector2.ZERO
	var living := 0
	for soldier in soldiers:
		if soldier.active:
			result += soldier.position
			living += 1
	return result / living if living > 0 else soldiers[0].position

func assign(local_task: String, target: Vector2, obstacle: Rect2) -> Dictionary:
	if not mission_execution_available():
		return {}
	task = local_task
	terrain = obstacle
	destination = target
	var start := center()
	var clearance := obstacle.grow(46)
	route_side = "direct"
	var blocking_bounds := obstacle.grow(8)
	var corners := [blocking_bounds.position, Vector2(blocking_bounds.end.x, blocking_bounds.position.y), blocking_bounds.end, Vector2(blocking_bounds.position.x, blocking_bounds.end.y)]
	var blocked := blocking_bounds.has_point(start) or blocking_bounds.has_point(target)
	for edge in range(4):
		blocked = blocked or Geometry2D.segment_intersects_segment(start, target, corners[edge], corners[(edge + 1) % 4]) != null
	# This fixture's approaches start west of the obstacle. Squad leadership, not
	# a higher command or the presentation, chooses the bypass and soldier paths.
	if blocked:
		var bottom_left := Vector2(clearance.position.x, clearance.end.y)
		var top_right := Vector2(clearance.end.x, clearance.position.y)
		var top := start.distance_to(clearance.position) + clearance.size.x + top_right.distance_to(target)
		var bottom := start.distance_to(bottom_left) + clearance.size.x + clearance.end.distance_to(target)
		route_side = "north" if top <= bottom else "south"
	for index in range(soldiers.size()):
		var soldier = soldiers[index]
		if not soldier.active:
			continue
		soldier.route_origin = soldier.position
		soldier.waypoint = 0
		soldier.arrived = false
		var final_position := target + Vector2((index % 2) * 23 - 12, (index / 2) * 23 - 12)
		if blocked:
			var bounds := obstacle.grow(22 + index * 8)
			var bypass_y := bounds.position.y if route_side == "north" else bounds.end.y
			soldier.path.assign([Vector2(bounds.position.x, bypass_y), Vector2(bounds.end.x, bypass_y), final_position])
		else:
			soldier.path.assign([final_position])
	decision = {"echelon": "Squad", "actor": id, "intent": task,
		"commander_person": current_leader().id if current_leader() != null else "stationary enemy fixture",
		"choice": "Route %s; four individual paths" % route_side,
		"reason": "Direct approach blocked by rock outcrop; shortest clear bypass" if blocked else "Clear local approach"}
	return decision

func advance(delta: float) -> void:
	if not command_available() or routing_state in ["PENDING_COMMAND", "AT_RALLY", "RALLIED_HOLD"]:
		return
	for soldier in soldiers:
		soldier.advance(delta)
	# Local separation acts on real individual positions; there is no squad token
	# from which positions are regenerated. Clearance protects the outcrop boundary.
	for a in range(soldiers.size()):
		for b in range(a + 1, soldiers.size()):
			if not soldiers[a].active or not soldiers[b].active:
				continue
			var difference: Vector2 = soldiers[b].position - soldiers[a].position
			var distance := difference.length()
			if distance < 14:
				var direction := difference / distance if distance > 0.001 else Vector2.UP
				var adjustment := direction * (14 - distance) * 0.5
				if not terrain.grow(7).has_point(soldiers[a].position - adjustment):
					soldiers[a].position -= adjustment
				if not terrain.grow(7).has_point(soldiers[b].position + adjustment):
					soldiers[b].position += adjustment

func complete() -> bool:
	var living := 0
	for soldier in soldiers:
		if not soldier.active:
			continue
		living += 1
		if not soldier.arrived:
			return false
	return living > 0
