extends RefCounted
## SES-041: sole scheduler for both persistent spaces. Views never advance models.
const Layout = preload("res://sector_layout.gd")
const Rural = preload("res://sector_environment.gd")
const Engagement = preload("res://sector_engagement.gd")
const Rear = preload("res://rear.gd")
const STEP := 1.0 / 60.0
const FAST_RATE := 4
const MAX_FRAME := 0.25
var layout = Layout.new()
var environment = Rural.new()
var battlefield
var rear = Rear.new()
var session_id := ""
var battle_id := ""
var view := "REAR"
var rate := 1
var previous_rate := 1
var ticks := 0
var elapsed := 0.0
var accumulator := 0.0
var last_step_count := 0

func _init(seed_value := Layout.DEFAULT_SEED) -> void:
	layout.generate(seed_value)
	environment.configure(JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/docs/metadata.json")), JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/provenance.json")).archive_sha256)
	environment.compose(layout)
	battlefield = Engagement.new(layout, environment)
	session_id = "SES041-%d-%d" % [seed_value, get_instance_id()]
	battle_id = session_id + "-battle-1"
	# A bounded existing workstation, not a new economy or production mechanic.
	rear.place_workbench(Vector2(410, 500))
	rear.message = "Walk near the workbench. E: manual batch; F: finite Worker order."

func select_view(value: String) -> void:
	if value in ["REAR", "BATTLEFIELD"]: view = value

func set_rate(value: int) -> void:
	if value not in [0, 1, FAST_RATE]: return
	rate = value
	if rate > 0: previous_rate = rate

func toggle_pause() -> void:
	set_rate(previous_rate if rate == 0 else 0)

func rear_action(action: String) -> bool:
	if view != "REAR" or rate == 0: return false
	match action:
		"MANUAL": return rear.start_job("Avatar", elapsed)
		"WORKER": return rear.assign_worker(3, elapsed)
		"STOP": return rear.stop_worker(elapsed)
	return false

func advance(real_delta: float, direction := Vector2.ZERO) -> void:
	last_step_count = 0
	if rate == 0 or real_delta <= 0 or not is_finite(real_delta): return
	# Slow the entire clock after stalls, never fast-forward one map alone.
	accumulator += minf(real_delta, MAX_FRAME) * rate
	while accumulator + 0.000000001 >= STEP and last_step_count < 60:
		accumulator = maxf(0, accumulator - STEP)
		ticks += 1
		elapsed = ticks * STEP
		if view == "REAR": rear.move_avatar(direction, STEP)
		battlefield.advance(STEP)
		rear.advance(STEP, elapsed, null)
		last_step_count += 1
