extends RefCounted

const Squad = preload("res://squad.gd")
const AMMO := "BoltActionRifleAmmo"
const RANGE := 260.0
const CADENCE := 1.0
const LOW_COVER := Rect2(750, 330, 12, 160)
const BUNKER := Rect2(820, 470, 70, 35)
const EXPOSED_HIT := 0.4
const COVERED_HIT := 0.1
var model
var defenders = Squad.new("E1", Vector2(790, 420), false)
var enemy_random := RandomNumberGenerator.new()
var friendly_random := RandomNumberGenerator.new()
var next_fire: Dictionary = {}
var shots: Array[Dictionary] = []
var history: Array[Dictionary] = []
var decisions: Array[Dictionary] = []
var solid_cover: Array[Rect2] = []
var suppression: int:
	get:
		return model.get_ref().squads[0].suppression
	set(value):
		model.get_ref().squads[0].suppression = value
var decay_at: float:
	get:
		return model.get_ref().squads[0].suppression_decay_at
	set(value):
		model.get_ref().squads[0].suppression_decay_at = value
var tactical_state := "ADVANCING"
var cover_arrived_at := -1.0
var first_contact := -1.0
var encounter_over := false

func _init(scenario) -> void:
	model = weakref(scenario)
	solid_cover.assign([scenario.OBSTACLE, BUNKER])
	enemy_random.seed = 6
	friendly_random.seed = 13
	defenders.task = "Defend approach"
	for soldier in defenders.soldiers:
		soldier.faction = "enemy"
		soldier.inventory[AMMO] = 2

func crosses_rect(start: Vector2, end: Vector2, rectangle: Rect2) -> bool:
	if rectangle.has_point(start) or rectangle.has_point(end):
		return true
	var corners := [rectangle.position, Vector2(rectangle.end.x, rectangle.position.y), rectangle.end, Vector2(rectangle.position.x, rectangle.end.y)]
	for index in range(4):
		if Geometry2D.segment_intersects_segment(start, end, corners[index], corners[(index + 1) % 4]) != null:
			return true
	return false

func visible(start: Vector2, end: Vector2) -> bool:
	for solid in solid_cover:
		if crosses_rect(start, end, solid):
			return false
	return true

func add_suppression(amount: int, now: float, reason: String) -> void:
	var squad = model.get_ref().squads[0]
	squad.receive_suppression(amount, now)
	if suppression >= 4 and tactical_state in ["ADVANCING", "RESUMING"] and squad.mission_execution_available():
		tactical_state = "SUPPRESSED"
		var living := 0
		for soldier in model.get_ref().squads[0].soldiers:
			if soldier.active:
				living += 1
		decisions.append({"time": now, "state": tactical_state, "reason": reason, "living_friendly": living})
		move_to_cover(now)

func can_detect(shooter, target) -> bool:
	return shooter.active and shooter.medical_state == "FIT" and target.is_physical_target() and shooter.faction != target.faction and shooter.position.distance_to(target.position) <= RANGE and visible(shooter.position, target.position)

func detect(shooter, candidates: Array) -> Array:
	if not model.get_ref().battle_active():
		return []
	shooter.detected.clear()
	var result: Array = []
	for target in candidates:
		if can_detect(shooter, target):
			shooter.detected.append(target.id)
			result.append(target)
	result.sort_custom(func(a, b): return shooter.position.distance_squared_to(a.position) < shooter.position.distance_squared_to(b.position))
	return result

func covered(shooter: Vector2, target: Vector2) -> bool:
	var engineering = model.get_ref().engineering
	if engineering != null:
		for structure in engineering.structures:
			if engineering.provides_small_arms_cover(structure) and structure.protection.has_point(target):
				return true
	var near_cover := target.distance_to(target.clamp(LOW_COVER.position, LOW_COVER.end)) <= 80
	return near_cover and crosses_rect(shooter, target, LOW_COVER)

func constructed_blast_solids() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var engineering = model.get_ref().engineering
	if engineering != null:
		for structure in engineering.structures:
			if engineering.provides_blast_obstruction(structure):
				result.append(structure.geometry)
	return result

func kill(target, shooter, now: float) -> void:
	if not model.get_ref().battle_active():
		return
	if target.medical_state in ["DEAD", "EVACUATED"] or (not target.active and target.medical_state not in ["WOUNDED", "STABILIZED"]):
		return
	target.active = false
	target.medical_state = "DEAD"
	target.bleed_out_at = -1
	target.body_present = true
	for squad in model.get_ref().squads:
		if target in squad.soldiers:
			squad.recognize_leader_loss(now)
			squad.combat_casualty(target, now)
	history.append({"event": "combat casualty", "person": target.id, "location": target.position, "time": now, "world_source": shooter.id, "body_inventory": target.inventory.duplicate(true)})
	print("COMBAT WORLD EVENT: ", JSON.stringify(history.back()))

func attempt_shot(shooter, target, now: float, roll: float) -> bool:
	if not model.get_ref().battle_active():
		return false
	for squad in model.get_ref().squads:
		if shooter in squad.soldiers and squad.routing_state != "NONE":
			return false
	if not shooter.active or shooter.medical_state != "FIT" or not shooter.on_battlefield or shooter.inventory.get(AMMO, 0) <= 0 or shooter.weapon_category != "BoltActionRifle":
		return false
	if target.id not in shooter.detected or not can_detect(shooter, target) or now + 0.000001 < float(next_fire.get(shooter.id, -1)):
		return false
	var before: int = shooter.inventory[AMMO]
	shooter.inventory[AMMO] -= 1
	next_fire[shooter.id] = now + CADENCE
	var protected := covered(shooter.position, target.position)
	var hit := roll < (COVERED_HIT if protected else EXPOSED_HIT)
	shots.append({"shooter": shooter.id, "target": target.id, "time": now, "shooter_position": shooter.position, "target_position": target.position, "los": true, "locally_detected": true, "ammo_before": before, "ammo_after": before - 1, "covered": protected, "roll": roll, "hit": hit})
	if first_contact < 0:
		first_contact = now
	if shooter.faction == "enemy":
		for squad in model.get_ref().squads:
			if target in squad.soldiers:
				if squad == model.get_ref().squads[0]:
					add_suppression(1, now, "Incoming effective fire prohibits exposed advance")
				else:
					squad.receive_suppression(1, now)
	if hit:
		var medical = model.get_ref().medical
		if medical != null and medical.wound_target_ids.has(target.id):
			medical.wound(target, shooter, now)
		else:
			kill(target, shooter, now)
	print("SHOT: ", JSON.stringify(shots.back()))
	return true

func move_to_cover(now: float) -> void:
	var squad = model.get_ref().squads[0]
	if not squad.mission_execution_available():
		return
	for index in range(squad.soldiers.size()):
		var soldier = squad.soldiers[index]
		if not soldier.active:
			continue
		# Local withdrawal stays north of, then west of, the solid rock. The
		# platoon/company/operational destination is never replaced by this path.
		soldier.route_origin = soldier.position
		soldier.path.assign([Vector2(soldier.position.x, 180 - index * 8), Vector2(370 - index * 8, 180 - index * 8), Vector2(375 + (index % 2) * 23, 310 + (index / 2) * 23)])
		soldier.waypoint = 0
		soldier.arrived = false
	tactical_state = "COVERING"
	decisions.append({"time": now, "state": tactical_state, "reason": "Squad chooses west face of solid outcrop to break enemy line of sight"})
	model.get_ref().record("Squad", squad.id, "Seize Objective A", "Withdraw locally behind rock", "Incoming fire suppresses exposed advance; intent retained")

func advance(now: float) -> void:
	var scenario = model.get_ref()
	if scenario.supply.phase != "Final approach":
		return
	if suppression >= 4 and tactical_state in ["ADVANCING", "RESUMING"] and scenario.squads[0].command_available():
		add_suppression(0, now, "Field command restored; pending suppression requires local cover")
	var friends: Array = scenario.squads[0].soldiers
	var friendly_targets: Array = friends + [scenario.platoons[0].leader]
	if not encounter_over:
		for enemy in defenders.soldiers:
			var targets := detect(enemy, friendly_targets)
			if not targets.is_empty() and now + 0.000001 >= float(next_fire.get(enemy.id, -1)) and enemy.inventory[AMMO] > 0:
				attempt_shot(enemy, targets[0], now, enemy_random.randf())
		for friendly in friends:
			var targets := detect(friendly, defenders.soldiers)
			if not targets.is_empty() and scenario.artillery != null:
				scenario.information.observe_enemy(friendly.id, targets[0].position, now)
			if not targets.is_empty() and now + 0.000001 >= float(next_fire.get(friendly.id, -1)) and friendly.inventory[AMMO] > 0:
				attempt_shot(friendly, targets[0], now, friendly_random.randf())
		var capable := 0
		for enemy in defenders.soldiers:
			if enemy.active and enemy.inventory[AMMO] > 0:
				capable += 1
		encounter_over = capable == 0
	for squad in scenario.squads + [defenders]:
		squad.decay_suppression(now)
	if scenario.squads[0].routing_state != "NONE":
		tactical_state = scenario.squads[0].routing_state
		return
	if tactical_state == "COVERING" and scenario.squads[0].complete():
		tactical_state = "SUPPRESSED_HOLD"
		cover_arrived_at = now
		decisions.append({"time": now, "state": tactical_state, "reason": "Members reached LOS-blocking cover; await safe suppression threshold"})
	if tactical_state == "SUPPRESSED_HOLD" and suppression <= 1 and now >= cover_arrived_at + 1 and scenario.squads[0].command_available():
		tactical_state = "RESUMING"
		scenario.squads[0].assign("Seize Objective A", scenario.OBJECTIVE, scenario.OBSTACLE)
		decisions.append({"time": now, "state": tactical_state, "reason": "Suppression at most one; resume original objective by local route"})
