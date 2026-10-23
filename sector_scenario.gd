extends "res://scenario.gd"
## Accepted command owner specialized for the procedural sector, with no combat.
const Navigation = preload("res://sector_navigation.gd")
const SectorSquad = preload("res://sector_squad.gd")
var navigation
var anchors := {}
var scenario_seed := 38038
var sector_seed := 0
var reassigned := false
var reassignment_at := 24.0
var decision_fingerprint := ""

func _init(layout, environment, seed_value := 38038) -> void:
	super._init(false, false, false, false, false, false, false, false, {}, false)
	scenario_seed = seed_value; sector_seed = layout.seed_value
	navigation = Navigation.new(layout, environment)
	var rng := RandomNumberGenerator.new(); rng.seed = scenario_seed ^ sector_seed
	var ahead: Dictionary = layout.sample_route(layout.village_distance + 120 + rng.randi_range(0, 24))
	var support: Dictionary = layout.sample_route(layout.village_distance + 45 + rng.randi_range(0, 12))
	anchors = {"MAIN":navigation.safe_position(ahead.position + Vector2(0, 64)), "SUPPORT":navigation.safe_position(support.position + Vector2(0, 60)), "RESERVE":navigation.safe_position(layout.village + Vector2(-24, 7))}
	for i in range(4):
		var start: Vector2 = navigation.safe_position(layout.village + Vector2(16 - i * 12, 7))
		squads.append(SectorSquad.new("P%d-%s" % [1 + i / 2, "A" if i % 2 == 0 else "B"], start, navigation))
	for i in range(2):
		var lead = Person.new("P%d-PL" % (i + 1), squads[i * 2].formation_reference + Vector2(-3, 0), 1.4)
		lead.formal_rank = "LIEUTENANT"; lead.normal_role = "PlatoonLeader"
		platoons.append({"id":"P%d" % (i + 1), "squads":[squads[i * 2], squads[i * 2 + 1]], "assignment":"Unassigned", "leader":lead, "follow_signature":""})
	operational_decide()
	decision_fingerprint = JSON.stringify(Navigation.Layout.canonical({"sector":sector_seed,"scenario":scenario_seed,"anchors":anchors,"trace":trace,"routes":squads.map(func(squad): return squad.formation_route)}), "", true, true).sha256_text()

func record(echelon: String, actor: String, intent: String, choice: String, reason: String) -> void:
	super.record(echelon, actor, intent, choice, reason)
	trace.back()["time"] = elapsed

func operational_decide() -> void:
	var objective: Vector2 = anchors.SUPPORT if reassigned else anchors.MAIN
	var intent := "Redirect main effort to SUPPORT" if reassigned else "Advance main effort; establish support and retain reserve"
	record("Operational", "HQ", intent, "Company receives generated %s anchor" % ("SUPPORT" if reassigned else "MAIN"), "Bounded deterministic operational intent; execution delegated")
	company_receive(intent, objective)

func company_receive(intent: String, target: Vector2) -> void:
	var main := 0
	if platoons[1].squads[0].center().distance_to(target) < platoons[0].squads[0].center().distance_to(target): main = 1
	for i in range(platoons.size()):
		platoons[i].assignment = "Main effort" if i == main else "Support / reserve"
		record("Company", "C1", intent, "%s: %s" % [platoons[i].id, platoons[i].assignment], "Nearest platoon carries main effort; retain supporting and staged capacity")
		platoon_receive(platoons[i], target)

func platoon_receive(platoon: Dictionary, target: Vector2) -> void:
	if not platoon.leader.active: return
	for i in range(platoon.squads.size()):
		var squad = platoon.squads[i]
		squad.command_time = elapsed
		if platoon.assignment != "Main effort" and i == 1:
			squad.hold("Hold reserve")
			record("Platoon", platoon.id, platoon.assignment, "%s: Hold reserve" % squad.id, "Retained capacity at generated staging area")
			continue
		var destination: Vector2 = navigation.safe_position(target + Vector2(-10, 9) * i) if platoon.assignment == "Main effort" else navigation.safe_position(anchors.SUPPORT + Vector2(-14, -9))
		var task := ("Redirect main formation" if reassigned else "Advance main formation") if platoon.assignment == "Main effort" else "Establish support"
		record("Platoon", platoon.id, platoon.assignment, "%s: %s" % [squad.id, task], "Separate subordinate formation destinations; Squad selects route")
		var local: Dictionary = squad.assign(task, destination)
		if not local.is_empty(): trace.append(local.duplicate(true))
		for person in squad.soldiers: record("Soldier", person.id, task, "Follow Squad formation slot at 1.4 m/s", "Real individual position and movement budget; no assigned proof patrol")

func advance(delta: float) -> void:
	# Split exactly at the command boundary so logical decisions do not depend on
	# the caller's frame partition. No unbounded catch-up or accelerated people.
	if not reassigned and elapsed + delta + 0.00000001 >= reassignment_at:
		var first := minf(delta, maxf(0, reassignment_at - elapsed))
		advance_movement(first); elapsed = reassignment_at
		reassigned = true; operational_decide()
		advance_movement(delta - first); elapsed += delta - first
	else:
		advance_movement(delta); elapsed += delta

func advance_movement(delta: float) -> void:
	for squad in squads: squad.advance(delta)
	for platoon in platoons:
		var leader = platoon.leader
		var anchor: Vector2 = platoon.squads[0].formation_reference + Vector2(-3, 0)
		leader.path.assign([anchor]); leader.waypoint = 0
		leader.advance(delta)
		if platoon.squads[0].movement_state in ["MOVING_TO_OBJECTIVE", "REASSIGNED"]: leader.arrived = false
