extends RefCounted

const CATEGORY := "BoltActionRifleAmmo"
const DISPATCH_TIME := 15.0
const RANGE := 24.0
const DURATION := 2.0
var casualty
var position := Vector2(650, 650)
var state := "Waiting for quiet-site fixture"
var inventory := {CATEGORY: 0}
var dispatched_at := -1.0
var started_at := -1.0
var completed_at := -1.0
var ledger: Array[Dictionary] = []

func _init(person) -> void:
	casualty = person
	# Explicit starting inventory: death creates no new ammunition or duplicate pile.
	casualty.inventory[CATEGORY] = 3

func advance(delta: float, now: float) -> void:
	if not casualty.body_present or completed_at >= 0:
		return
	if dispatched_at < 0 and now + 0.000001 >= DISPATCH_TIME:
		dispatched_at = DISPATCH_TIME
		state = "Approaching body"
	if state == "Approaching body":
		position = position.move_toward(casualty.position, 80 * delta)
		if position.distance_to(casualty.position) <= RANGE:
			started_at = now
			state = "Recovering / 2 world seconds"
	if started_at >= 0 and completed_at < 0 and now + 0.000001 >= started_at + DURATION:
		var quantity: int = casualty.inventory[CATEGORY]
		casualty.inventory[CATEGORY] = 0
		inventory[CATEGORY] += quantity
		casualty.body_present = false
		completed_at = started_at + DURATION
		state = "Recovered / items held by team"
		ledger.append({"source": "body:" + casualty.id, "quantity": quantity, "destination": "Recovery Team", "time": completed_at, "ownership_before": "military", "ownership_after": "military", "reason": "Physical recovery completed; historical event unchanged"})
		print("RECOVERY: ", JSON.stringify(ledger.back()))
