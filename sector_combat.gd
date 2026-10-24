extends "res://combat.gd"
## CNT-039 compatibility: accepted rifle rules in design meters, open LOS.
const COMBAT_SEED := 39039
var first_detection := -1.0
var first_friendly_detection := -1.0
var local_contacts := {}
var local_events: Array[Dictionary] = []
var last_shot_at := {}
var last_shot := {}
var suppression_events: Array[Dictionary] = []

func _init(scenario) -> void:
	super._init(scenario)
	solid_cover.clear()
	defenders = scenario.enemy_platoon.squads[0]
	verbose_events = false
	friendly_random.seed = COMBAT_SEED
	enemy_random.seed = COMBAT_SEED + 1

func combat_squads() -> Array:
	var world = model.get_ref()
	return world.squads + world.enemy_platoon.squads

func visible(_start: Vector2, _end: Vector2) -> bool:
	# No authoritative world LOS solids yet. Presentation art is not an occluder.
	return true

func covered(_shooter: Vector2, _target: Vector2) -> bool:
	return false

func incoming_fire(_shooter, target, now: float) -> void:
	for squad in combat_squads():
		if target in squad.soldiers:
			squad.receive_suppression(1, now)
			suppression_events.append({"time":now,"squad":squad.id,"target":target.id,"value":squad.suppression,"source":"actual rifle shot"})
			return

func attempt_shot(shooter, target, now: float, roll: float) -> bool:
	var fired := super.attempt_shot(shooter, target, now, roll)
	if fired:
		shots.back()["faction"] = shooter.faction
		last_shot_at[shooter.id] = now
		last_shot[shooter.id] = shots.back().duplicate(true)
	return fired

func detect(shooter, candidates: Array) -> Array:
	var result := super.detect(shooter, candidates)
	result.sort_custom(func(a,b):
		var da: float = shooter.position.distance_squared_to(a.position)
		var db: float = shooter.position.distance_squared_to(b.position)
		return da < db if da != db else a.id < b.id)
	return result

func observe(shooter, target, now: float) -> void:
	if first_detection < 0: first_detection = now
	if not local_contacts.has(shooter.id) or local_contacts[shooter.id].contact_id != target.id:
		local_events.append({"observer":shooter.id,"source_formation":shooter.squad_id,"contact_id":target.id,"observation_time":now,"observer_position":shooter.position,"observed_position":target.position,"distance_m":shooter.position.distance_to(target.position),"los":"open provisional","faction":shooter.faction})
	local_contacts[shooter.id] = {"contact_id":target.id,"observation_time":now,"observed_position":target.position,"observer":shooter.id,"source_formation":shooter.squad_id}
	if shooter.faction == "friendly":
		if first_friendly_detection < 0: first_friendly_detection = now
		model.get_ref().information.observe_contact(shooter.id, target.id, target.position, now, 3.0, {"source_formation":shooter.squad_id,"source_platoon":shooter.squad_id.get_slice("-",0),"detection_basis":"individual open LOS within260m"})

func advance(now: float) -> void:
	var world = model.get_ref()
	# Accepted fixture order: enemy shooters first, then friendly shooters. Leaders
	# remain embodied targets/command actors; Squad personnel own rifle observation.
	for side in [world.enemy_platoon.squads, world.squads]:
		var candidates: Array = world.friendly_people() if side == world.enemy_platoon.squads else world.enemy_people()
		for squad in side:
			for shooter in squad.soldiers:
				var targets := detect(shooter, candidates)
				if targets.is_empty():
					local_contacts.erase(shooter.id)
					continue
				observe(shooter, targets[0], now)
				if shooter.inventory.get(AMMO,0) <= 0 or now + 0.000001 < float(next_fire.get(shooter.id,-1)): continue
				var random: RandomNumberGenerator = enemy_random if shooter.faction == "enemy" else friendly_random
				attempt_shot(shooter, targets[0], now, random.randf())
	for squad in combat_squads(): squad.decay_suppression(now)
