extends RefCounted

# One deliberately bounded truthful-report fixture. World truth is never used
# as inquiry or reconstruction input. Copies at the boundaries prevent aliasing.
const EVENT_TIME := 5.0
const HOP_DELAY := 1.0
const QUERY_RADIUS := 54.0
const ECHELONS := ["Squad", "Platoon", "Company", "HQ"]
var world_event: Dictionary = {}
var knowledge := {"Squad": [], "Platoon": [], "Company": [], "HQ": []}
var deliveries: Array[Dictionary] = []
var next_hop := 1
var reconstructing := false
var reconstruction: Array[Dictionary] = []

func advance(now: float, casualty) -> void:
	if world_event.is_empty() and now + 0.000001 >= EVENT_TIME:
		casualty.active = false
		casualty.body_present = true
		world_event = {"event_id": "fixture-incident-1", "soldier_id": casualty.id,
			"location": casualty.position, "event_time": EVENT_TIME,
			"cause": "explosion", "hidden_source_id": "enemy-indirect-source-7"}
		# The local observer knows effects, not the firing source. Construct this
		# representation explicitly; never duplicate the omniscient event object.
		knowledge.Squad.append({"soldier_id": casualty.id, "location": casualty.position,
			"observation_time": EVENT_TIME, "received_at": EVENT_TIME,
			"observer": "P2-B.1", "facts": ["explosion", "friendly casualty"]})
		print("OMNISCIENT DEVELOPER FIXTURE: ", JSON.stringify(world_event))
	while not world_event.is_empty() and next_hop < ECHELONS.size() and now + 0.000001 >= EVENT_TIME + next_hop * HOP_DELAY:
		var sender: String = ECHELONS[next_hop - 1]
		var recipient: String = ECHELONS[next_hop]
		var received_at := EVENT_TIME + next_hop * HOP_DELAY
		var report: Dictionary = knowledge[sender][0].duplicate(true)
		report.received_at = received_at
		knowledge[recipient].append(report)
		deliveries.append({"sender": sender, "recipient": recipient,
			"sent_at": received_at - HOP_DELAY, "received_at": received_at,
			"observation_time": EVENT_TIME, "observer": report.observer})
		print("REPORT DELIVERY: ", JSON.stringify(deliveries.back()))
		next_hop += 1

func player_observation() -> Dictionary:
	if world_event.is_empty():
		return {}
	# Direct visual effects only, not command knowledge and not a cause reveal.
	return {"location": world_event.location, "time": world_event.event_time}

func query(point: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for report in knowledge.HQ:
		if point.distance_to(report.location) <= QUERY_RADIUS:
			result.append(report.duplicate(true))
	return result

func begin_reconstruction(reports: Array[Dictionary]) -> bool:
	if reports.is_empty():
		return false
	# Reconstruct from the actual HQ-owned record, with a second whitelist at the
	# rendering boundary. Caller-supplied fields cannot introduce hidden truth.
	reconstruction.clear()
	for report in reports:
		for established in knowledge.HQ:
			if report == established:
				reconstruction.append({"soldier_id": established.soldier_id,
					"location": established.location, "observation_time": established.observation_time,
					"facts": established.facts.duplicate(), "observer": established.observer})
	reconstructing = not reconstruction.is_empty()
	return reconstructing

func end_reconstruction() -> void:
	reconstructing = false
	reconstruction.clear()
