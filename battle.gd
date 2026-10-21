extends RefCounted

const HIT_RADIUS := 30.0
var model
var state := "ACTIVE"
var terminal_time := -1.0
var history: Array[Dictionary] = []
var hqs: Dictionary = {}
var auto_strike := true
var target_hq_id := "Enemy-HQ"
var strike_count := 0
var last_hq_hit := -1.0

func _init(scenario) -> void:
	model = weakref(scenario)
	for entry in [{"id": "Friendly-HQ", "owner": "friendly", "position": Vector2(100, 700)},
		{"id": "Enemy-HQ", "owner": "enemy", "position": Vector2(850, 200)}]:
		entry.integrity = 2
		entry.state = "INTACT"
		entry.geometry = Rect2(entry.position - Vector2(28, 22), Vector2(56, 44))
		hqs[entry.id] = entry

func is_active() -> bool:
	return state == "ACTIVE"

func strategic_report() -> Dictionary:
	# Explicit static briefing, not live recon or a World State-to-HQ inquiry copy.
	return {"kind": "STATIC_HQ_LOCATION", "source_echelon": "Company", "report_id": "strategic-" + target_hq_id,
		"observer": "Known static strategic briefing", "observed_position": hqs[target_hq_id].position,
		"observation_time": 0.0, "received_at": 0.0}

func advance(now: float) -> void:
	if not is_active() or not auto_strike or model.get_ref().artillery == null:
		return
	if strike_count == 0 or (strike_count == 1 and last_hq_hit >= 0 and now + 0.000001 >= last_hq_hit + 2):
		if model.get_ref().artillery.create_mission(strategic_report(), now):
			strike_count += 1

func apply_blast_damage(point: Vector2, now: float, source: String) -> void:
	if not is_active():
		return
	for hq in hqs.values():
		if point.distance_to(hq.position) > HIT_RADIUS or hq.state == "DESTROYED":
			continue
		hq.integrity = maxi(0, hq.integrity - 1)
		hq.state = "DAMAGED" if hq.integrity == 1 else "DESTROYED"
		last_hq_hit = now
		history.append({"hq": hq.id, "event": "HQ damaged" if hq.integrity > 0 else "HQ destroyed", "time": now, "source": source, "integrity": hq.integrity, "state": hq.state, "position": hq.position})
		if hq.integrity == 0:
			state = "ENDED_FRIENDLY_VICTORY" if hq.owner == "enemy" else "ENDED_FRIENDLY_DEFEAT"
			terminal_time = now
			history.append({"event": "terminal battle result", "result": state, "defeated_primary": hq.owner, "hq": hq.id, "time": now, "source": source})
			print("TERMINAL BATTLE: ", JSON.stringify(history.back()))
			return
