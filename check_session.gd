extends SceneTree
const Session = preload("res://game_session.gd")
var checks := 0
var failures: Array[String] = []
var evidence := []
func _initialize() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func step(session, seconds: float, direction := Vector2.ZERO) -> void:
	for i in range(roundi(seconds * 60)): session.advance(1.0 / 60, direction)
func state(session) -> Dictionary:
	return {"time":session.elapsed,"ticks":session.ticks,"rear_time":session.rear.world_time,"avatar":session.rear.avatar,"worker":session.rear.worker.duplicate(true),"job":session.rear.job.duplicate(true),"metal":session.rear.metal,"ammo":session.rear.ammunition,"history":session.rear.production_history.duplicate(true),"people":session.battlefield.all_people().map(func(p):return [p.id,p.position,p.active,p.inventory.duplicate(true)]),"shots":session.battlefield.combat.shots.duplicate(true),"reports":session.battlefield.information.company_contact_snapshot(),"trace":session.battlefield.trace.duplicate(true)}
func run() -> void:
	var session = Session.new()
	expect(session.view == "REAR" and session.rate == 1 and session.elapsed == 0, "Session boots in protected rear at normal shared time")
	expect(session.battlefield.all_people().size() == 27 and session.rear.metal == 4, "Accepted physical battlefield and finite existing rear inventory")
	var world_id: int = session.battlefield.get_instance_id(); var rear_id: int = session.rear.get_instance_id()
	var ids: Array = session.battlefield.all_people().map(func(p):return p.get_instance_id())
	var fingerprint: String = session.layout.fingerprint; var battle_id: String = session.battle_id
	var initial: Vector2 = session.rear.avatar
	step(session, 0.25, Vector2.RIGHT)
	expect(session.rear.avatar.distance_to(initial) > 30, "Real rear avatar moves through session steps")
	expect(session.rear_action("MANUAL"), "Existing proximity-guarded manual production starts with real input")
	expect(session.rear.metal == 3 and session.rear.ammunition == 0, "Starting work consumes real Metal, no decorative stock grant")
	var start := state(session)
	session.select_view("BATTLEFIELD")
	expect(state(session) == start, "View selection itself changes no authoritative state")
	step(session, 2, Vector2.RIGHT)
	expect(not session.rear.job.is_empty() and session.elapsed - float(session.rear.job.started_at) > 1.99, "Rear manual work progresses while battlefield viewed")
	expect(session.rear.avatar == start.avatar, "Battlefield movement input cannot move rear avatar")
	expect(not session.rear_action("WORKER"), "Rear work commands unavailable in battlefield view")
	session.set_rate(0); var frozen := state(session)
	step(session, 2, Vector2.RIGHT)
	session.select_view("REAR"); session.select_view("BATTLEFIELD")
	expect(state(session) == frozen, "Pause freezes people, work, inventory, shots, reports and clock across switching")
	expect(not session.rear_action("MANUAL"), "Pause cannot consume production input")
	session.set_rate(4); step(session, 0.5)
	expect(session.rear.ammunition == 8 and session.rear.job.is_empty(), "4x finishes off-view work after same four world seconds")
	expect(is_equal_approx(session.elapsed, 4.25) and is_equal_approx(session.rear.world_time, session.battlefield.elapsed), "Both spaces agree with the one session clock")
	session.select_view("REAR"); session.set_rate(1)
	expect(session.rear_action("WORKER"), "Existing finite three-batch Worker order accepted")
	var battle_before: Array = state(session).people
	step(session, 8)
	expect(state(session).people != battle_before, "Battlefield genuinely progresses while player stays in rear")
	session.select_view("BATTLEFIELD"); step(session, 8)
	expect(session.rear.production_order.status == "COMPLETED" and session.rear.produced == 32 and session.rear.metal == 0, "Worker approaches, works and finishes finite batches off-view with conserved resources")
	session.select_view("REAR"); session.select_view("BATTLEFIELD")
	expect(session.battlefield.get_instance_id() == world_id and session.rear.get_instance_id() == rear_id and session.battlefield.all_people().map(func(p):return p.get_instance_id()) == ids, "Switching preserves all authoritative object identities")
	expect(session.layout.fingerprint == fingerprint and session.battle_id == battle_id, "Scenario seed and battle identity remain stable")
	var normal = Session.new(); var fast = Session.new(); fast.set_rate(4)
	for i in range(120 * 60):
		normal.advance(1.0 / 60)
		if i % 4 == 0: fast.advance(1.0 / 60)
		if i % 30 == 0: fast.select_view("REAR" if fast.view == "BATTLEFIELD" else "BATTLEFIELD")
	expect(state(normal) == state(fast), "Normal and4x produce identical combat, reports, movement and rear state at equal world time despite switches")
	expect(normal.battlefield.combat.shots.size() > 0 and not normal.battlefield.company_contacts().is_empty(), "Continuity proof reaches actual contact, shots and delivered reports")
	expect(normal.battlefield.ammunition_remaining() + normal.battlefield.combat.shots.size() == normal.battlefield.initial_ammunition, "Off-view combat conserves finite ammunition")
	var p = Session.new(); var person = p.battlefield.squads[0].soldiers[0]; var at: Vector2 = person.position
	step(p, 1)
	expect(person.position.distance_to(at) <= 1.406, "World movement remains bounded at accepted1.4m/s (float32 position tolerance)")
	p.advance(100)
	expect(p.last_step_count <= 60 and p.elapsed <= 1.251, "Long stalls use bounded shared clock catch-up")
	var previous := state(p); p.advance(INF); p.advance(NAN); p.advance(-1)
	expect(state(p) == previous, "Invalid frame deltas cannot corrupt authoritative clock")
	evidence.append({"rear_cross_view":state(session),"equal_time_contact":{"world_time":normal.elapsed,"shots":normal.battlefield.combat.shots.size(),"reports":normal.battlefield.company_contacts().size()},"checks":checks,"failures":failures})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/ses041"))
	var file := FileAccess.open("res://artifacts/ses041/model.json",FileAccess.WRITE); file.store_string(JSON.stringify(evidence,"  ")); file.close()
	print("SESSION CHECKS ",checks," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
