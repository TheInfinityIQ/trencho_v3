extends RefCounted

const Checkpoint = preload("res://checkpoint.gd")
const Campaign = preload("res://campaign.gd")
const Scenario = preload("res://scenario.gd")
const FIXTURE_ID := "RSM-022-six-actions-v1"
const SAVE_TIME := 6.25
var world
var progression: Dictionary
var authored := {"mission": false, "work": false}
var initial_ammo := 0

func _init(reconstructed_progression: Dictionary = {}) -> void:
	if not reconstructed_progression.is_empty():
		progression = reconstructed_progression.duplicate(true)
		var builder = Campaign.new(false, "", progression.campaign)
		var members: Array = []
		for index in range(Campaign.NEXT_SQUAD.size()):
			members.append(builder.fresh_person(progression.campaign.person_registry[Campaign.NEXT_SQUAD[index]], Vector2.ZERO, 43 + index * 1.2))
		var leader = builder.fresh_person(progression.campaign.person_registry["P1-PL"], Vector2(130, 280), 47)
		world = Scenario.new(true, true, true, true, true, true, true, true, {"main_members": members, "platoon_leader": leader, "fresh_prefix": "B2-"})
		return
	var safe = Checkpoint.new(true)
	safe.start_next_battle()
	world = safe.progression.campaign.world
	world.battle.auto_strike = false
	world.combat.encounter_over = true
	world.supply.depot.inventory.BoltActionRifleAmmo = 8
	world.supply.requested_at = 0
	world.supply.phase = "Hold: ammunition shortage"
	progression = {"meta": safe.progression.meta.duplicate(true), "campaign": safe.campaign_values()}
	initial_ammo = world.total_ammunition()

func advance(delta: float) -> void:
	world.advance(delta)
	if world.elapsed + 0.000001 >= 4.5 and not authored.mission:
		authored.mission = world.artillery.create_mission({"kind": "STATIC_HQ_LOCATION", "source_echelon": "Company", "report_id": "RSM-static-briefing-1", "observer": "Authored static site briefing", "observed_position": Vector2(900, 50), "observation_time": 4.5, "received_at": 4.5}, world.elapsed)
	if world.elapsed + 0.000001 >= 5.5 and not authored.work:
		authored.work = true
		var observer = world.squads[0].soldiers[1]
		var enemy = world.combat.defenders.soldiers[0]
		observer.position = Vector2(700, 420)
		world.combat.detect(observer, [enemy])
		assert(world.combat.can_detect(observer, enemy))
		world.information.observe_enemy(observer.id, enemy.position, world.elapsed)
		var wounded = world.squads[1].soldiers[3]
		wounded.position = Vector2(350, 400)
		var shooter = world.combat.defenders.soldiers[0]
		shooter.position = Vector2(350, 300)
		world.medical.medic.position = wounded.position + Vector2(0, -10)
		world.medical.wound_target_ids[wounded.id] = true
		world.combat.detect(shooter, [wounded])
		world.combat.attempt_shot(shooter, wounded, world.elapsed, 0)
		var engineer = world.engineering.people[0]
		engineer.position = world.engineering.sites["Reinforced Site B"]
		world.engineering.assign("ReinforcedPosition", engineer, "Reinforced Site B", world.elapsed)
		world.rear.place_workbench(Vector2(380, 480))
		world.rear.start_job("Avatar", world.elapsed)

func step(duration: float) -> void:
	for tick in range(int(round(duration * 60))):
		advance(1.0 / 60.0)

func concurrent() -> bool:
	return world.battle_active() and world.supply.truck.inventory.BoltActionRifleAmmo == 8 and world.supply.delivered_at < 0 and not world.information.contact_knowledge.Squad.is_empty() and world.information.contact_knowledge.Platoon.is_empty() and world.artillery.missions.size() == 1 and world.artillery.missions[0].state == "IN_FLIGHT" and world.medical.casualty != null and world.medical.casualty.medical_state == "WOUNDED" and world.medical.treatment_progress > 0 and world.medical.treatment_progress < 2 and world.engineering.jobs.size() == 1 and world.engineering.jobs[0].progress > 0 and world.engineering.jobs[0].progress < 5 and world.engineering.reservations.size() == 1 and not world.rear.job.is_empty() and world.rear.produced == 0
