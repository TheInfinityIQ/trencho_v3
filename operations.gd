extends RefCounted

const Scenario = preload("res://scenario.gd")
const Situation = preload("res://situation.gd")
var world = Scenario.new(true, true, true, true, false, true, false, true)
var campaign_capabilities := {"BoltActionAmmoProduction": true}
var initial_ammo := 0
var objective_release_at := -1.0

func _init() -> void:
	world.battle.auto_strike = false
	# One real contact shot leaves8; the accepted16round readiness threshold
	# then needs exactly one manufactured/exported8round batch. No free grant.
	for person in world.squads[0].soldiers:
		person.inventory.BoltActionRifleAmmo = 0
	world.squads[0].soldiers[0].inventory.BoltActionRifleAmmo = 9
	world.combat.friendly_random.seed = 1
	world.combat.hold_contact_enabled = true
	world.combat.contact_refresh_interval = 3.0
	world.artillery.auto_contact_enabled = false
	for person in world.combat.defenders.soldiers:
		person.inventory.BoltActionRifleAmmo = 1
	var forward_guard = world.combat.defenders.soldiers[0]
	forward_guard.position = Vector2(600, 200)
	forward_guard.origin = forward_guard.position
	world.rear.capability_unlocked = campaign_capabilities.BoltActionAmmoProduction
	initial_ammo = world.total_ammunition()

func advance(delta: float) -> void:
	world.advance(delta)
	# Existing Company/HQ director receives the strategic fire task only after
	# autonomous infantry actually reaches its objective, never on delivery.
	if world.secured and world.battle_active() and objective_release_at < 0:
		objective_release_at = world.elapsed
		world.battle.auto_strike = true

func step(duration: float) -> void:
	for tick in range(int(round(duration * 60))):
		advance(1.0 / 60.0)

func friendly_shots() -> Array:
	var ids: Array = world.squads[0].soldiers.map(func(person): return person.id)
	return world.combat.shots.filter(func(shot): return shot.shooter in ids)

func visible_contacts() -> Array:
	# Deliberately copied delivered Company records; never enemy live positions.
	return Situation.latest_contacts(world)

func situation() -> Dictionary:
	return Situation.build(world)
