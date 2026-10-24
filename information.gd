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
var contact_knowledge := {"Squad": [], "Platoon": [], "Company": []}
var contact_deliveries: Array[Dictionary] = []
var contact_next_hop := 1
var contact_updates: Array[Dictionary] = []
var contact_observed_at: Dictionary = {}
var next_contact_report := 1
var fixture_enabled := true
var leader_knowledge := {"Squad": [], "Platoon": [], "Company": []}
var leader_relays: Array[Dictionary] = []
var morale_knowledge := {"Squad": [], "Platoon": [], "Company": []}
var morale_relays: Array[Dictionary] = []
var morale_deliveries: Array[Dictionary] = []

func queue_morale_report(report: Dictionary) -> void:
	var local: Dictionary = report.duplicate(true)
	local.received_at = report.sent_at
	morale_knowledge.Squad.append(local)
	morale_relays.append({"report": local.duplicate(true), "hop": 1})

func queue_leader_report(report: Dictionary) -> void:
	var local: Dictionary = report.duplicate(true)
	local.received_at = report.sent_at
	leader_knowledge.Squad.append(local)
	leader_relays.append({"report": local, "hop": 1})

func observe_enemy(observer: String, point: Vector2, now: float) -> void:
	if not contact_knowledge.Squad.is_empty():
		return
	contact_knowledge.Squad.append({"kind": "ENEMY_POSITION_OBSERVED", "report_id": "contact-1", "observer": observer, "observation_time": now, "observed_position": point, "received_at": now})
	print("LOCAL CONTACT OBSERVATION: ", JSON.stringify(contact_knowledge.Squad[0]))

func observe_contact(observer: String, contact_id: String, point: Vector2, now: float, interval := 3.0, provenance: Dictionary = {}) -> bool:
	if observer.is_empty() or contact_id.is_empty() or now < 0 or interval <= 0:
		return false
	if contact_observed_at.has(contact_id) and now + 0.000001 < float(contact_observed_at[contact_id]) + interval:
		return false
	# This opt-in stream reuses the accepted local->Platoon->Company hops.
	# Disable only the legacy single-report relay when this stream is selected.
	contact_next_hop = 3
	var report := {"kind": "ENEMY_POSITION_OBSERVED", "contact_id": contact_id, "report_id": "contact-" + str(next_contact_report), "observer": observer, "observation_time": now, "observed_position": point, "received_at": now}
	for key in ["source_formation", "source_platoon", "detection_basis"]:
		if provenance.has(key): report[key] = provenance[key]
	next_contact_report += 1
	contact_observed_at[contact_id] = now
	contact_knowledge.Squad.append(report)
	contact_updates.append({"report": report.duplicate(true), "hop": 1})
	return true

func company_contact_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in contact_knowledge.Company:
		var delivered := {"kind": record.kind, "report_id": record.report_id, "observer": record.observer, "observation_time": record.observation_time, "observed_position": record.observed_position, "received_at": record.received_at, "source_echelon": "Company"}
		if record.has("contact_id"):
			delivered.contact_id = record.contact_id
		for key in ["source_formation", "source_platoon", "detection_basis"]:
			if record.has(key): delivered[key] = record[key]
		result.append(delivered)
	return result

func advance(now: float, casualty) -> void:
	for relay in contact_updates:
		while relay.hop < 3 and now + 0.000001 >= relay.report.observation_time + relay.hop * HOP_DELAY:
			var delivered: Dictionary = relay.report.duplicate(true)
			delivered.received_at = relay.report.observation_time + relay.hop * HOP_DELAY
			contact_knowledge[ECHELONS[relay.hop]].append(delivered)
			contact_deliveries.append({"sender": ECHELONS[relay.hop - 1], "recipient": ECHELONS[relay.hop], "sent_at": delivered.received_at - HOP_DELAY, "received_at": delivered.received_at, "report_id": delivered.report_id})
			relay.hop += 1
	for relay in morale_relays:
		while relay.hop < 3 and now + 0.000001 >= relay.report.sent_at + relay.hop * HOP_DELAY:
			var received: Dictionary = relay.report.duplicate(true)
			received.received_at = relay.report.sent_at + relay.hop * HOP_DELAY
			morale_knowledge[ECHELONS[relay.hop]].append(received)
			morale_deliveries.append({"kind": received.kind, "squad": received.squad, "sender": ECHELONS[relay.hop - 1], "recipient": ECHELONS[relay.hop], "sent_at": received.received_at - HOP_DELAY, "received_at": received.received_at, "observation_time": received.observation_time})
			print("MORALE REPORT RELAY: ", JSON.stringify(morale_deliveries.back()))
			relay.hop += 1
	if fixture_enabled and world_event.is_empty() and now + 0.000001 >= EVENT_TIME:
		casualty.active = false
		casualty.medical_state = "DEAD"
		casualty.body_present = true
		world_event = {"event_id": "fixture-incident-1", "soldier_id": casualty.id,
			"location": casualty.position, "event_time": EVENT_TIME,
			"cause": "explosion", "hidden_source_id": "enemy-indirect-source-7"}
		# The local observer knows effects, not the firing source. Construct this
		# representation explicitly; never duplicate the omniscient event object.
		knowledge.Squad.append({"soldier_id": casualty.id, "location": casualty.position,
			"observation_time": EVENT_TIME, "received_at": EVENT_TIME,
			"observer": casualty.squad_id + ".1", "facts": ["explosion", "friendly casualty"]})
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
	# The contact proof uses the same one-second upward relay semantics, stopping
	# at Company rather than granting automatic Operational/HQ knowledge.
	while not contact_knowledge.Squad.is_empty() and contact_next_hop < 3:
		var observation: Dictionary = contact_knowledge.Squad[0]
		var receipt_time: float = observation.observation_time + contact_next_hop * HOP_DELAY
		if now + 0.000001 < receipt_time:
			break
		var sender: String = ECHELONS[contact_next_hop - 1]
		var recipient: String = ECHELONS[contact_next_hop]
		var delivered: Dictionary = contact_knowledge[sender][0].duplicate(true)
		delivered.received_at = receipt_time
		contact_knowledge[recipient].append(delivered)
		contact_deliveries.append({"sender": sender, "recipient": recipient, "sent_at": receipt_time - HOP_DELAY, "received_at": receipt_time, "report_id": delivered.report_id})
		print("CONTACT RELAY: ", JSON.stringify(contact_deliveries.back()))
		contact_next_hop += 1
	for relay in leader_relays:
		while relay.hop < 3 and now + 0.000001 >= relay.report.sent_at + relay.hop * HOP_DELAY:
			var received: Dictionary = relay.report.duplicate(true)
			received.received_at = relay.report.sent_at + relay.hop * HOP_DELAY
			leader_knowledge[ECHELONS[relay.hop]].append(received)
			print("LEADER CASUALTY RELAY: ", ECHELONS[relay.hop], " ", JSON.stringify(received))
			relay.hop += 1

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
