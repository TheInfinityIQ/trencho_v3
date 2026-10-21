extends RefCounted

# Stable authored ID for this fixture's already established HQ Objective-A mission.
const MISSION_ID := "HQ-Objective-A"

static func capture_assignments(world) -> void:
	for request in world.rear.requests:
		var platoon_id := ""
		for platoon in world.platoons:
			if platoon.squads.any(func(squad): return squad.id == request.formation):
				platoon_id = platoon.id
		var source := -1
		for index in range(world.trace.size()):
			var event: Dictionary = world.trace[index]
			if event.echelon == "Platoon" and (event.choice.begins_with(request.formation + ":") or (event.actor == platoon_id and event.intent == "Remain staged")):
				source = index
		if source < 0 or world.rear.request_context.get(request.id, {}).get("source_sequence", -1) == source:
			continue
		var event: Dictionary = world.trace[source]
		var summary: String = "Hold reserve" if event.intent == "Remain staged" else event.choice.trim_prefix(request.formation + ": ")
		var role: String = {"Seize Objective A": "MAIN EFFORT", "Stage in support": "SUPPORT", "Hold reserve": "RESERVE"}.get(summary, "ASSIGNED")
		world.rear.request_context[request.id] = {"request_id": request.id, "formation_id": request.formation,
			"mission_id": MISSION_ID, "command_role": role, "task_summary": summary,
			"command_provenance": "Company assignment / Platoon " + event.actor + " record",
			"command_record_time": world.elapsed, "source_sequence": source}

static func project(world, request: Dictionary) -> Dictionary:
	var established: Dictionary = world.rear.request_context.get(request.id, {}).duplicate(true)
	established.merge({"request_id": request.id, "formation_id": request.formation,
		"request_created_at": request.created_at, "request_age": maxf(0, world.elapsed - request.created_at) if request.created_at >= 0 else 0.0,
		"requested": request.requested, "remaining": request.remaining, "delivered": request.delivered,
		"carried": request.carried, "readiness_required": world.supply.READY_THRESHOLD,
		"supply_reason": "Ammunition %d / readiness requirement %d" % [request.carried, world.supply.READY_THRESHOLD],
		"supply_provenance": "Own formation Supply request / physical logistics record",
		"supply_record_time": request.get("supply_record_time", 0.0),
		"supply_age": maxf(0, world.elapsed - request.get("supply_record_time", 0.0))}, true)
	return established
