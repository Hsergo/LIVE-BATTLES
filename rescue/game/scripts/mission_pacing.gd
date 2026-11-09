extends RefCounted
## Bounded, deterministic pacing based on accepted free actions, never gifts.
## No fabricated participants, changed rescue targets or erased progress.

const ACTIVITY_WINDOW := 45.0
const MAX_ACTIVE := 500
const WORK_EXPONENT := 0.75
const RECOVERY_SECONDS := 8.0
var enabled := true
var clock := 0.0
var active_count := 0
var work_scale := 1.0
var pressure_scale := 1.0
var recent_actions: Dictionary = {}
var next_sample := 0.0

func reset(is_demo: bool) -> void:
	enabled = not is_demo
	clock = 0.0
	active_count = 0
	work_scale = 1.0
	pressure_scale = 1.0
	recent_actions.clear()
	next_sample = 0.0

func record_action(user: String) -> void:
	if not enabled or user.is_empty():
		return
	if not recent_actions.has(user) and recent_actions.size() >= MAX_ACTIVE:
		return
	recent_actions[user] = clock
	active_count = recent_actions.size()
	# Account for a burst before the next frame; do not drop anyone's action.
	work_scale = maxf(work_scale, _target_work_scale())

func tick(delta: float) -> void:
	if not enabled:
		return
	var d := maxf(0.0, delta)
	clock += d
	if clock >= next_sample:
		for user in recent_actions.keys():
			if clock - float(recent_actions[user]) >= ACTIVITY_WINDOW:
				recent_actions.erase(user)
		active_count = recent_actions.size()
		next_sample = clock + 1.0
	# Ease the workload after departures; preserve every completed percentage.
	var target_scale := _target_work_scale()
	work_scale = move_toward(work_scale, target_scale, d * maxf(1.0, work_scale) / RECOVERY_SECONDS)
	# Hazards stay close to authored values even with hundreds of players.
	var pressure_target := clampf(0.85 + float(active_count) * 0.006, 0.85, 1.15)
	pressure_scale = move_toward(pressure_scale, pressure_target, d * 0.025)

func _target_work_scale() -> float:
	return pow(float(maxi(1, active_count)), WORK_EXPONENT)

func work_gain(base: float) -> float:
	return maxf(0.0, base) / maxf(1.0, work_scale)

static func phase_for(previous: int, time_ratio: float, construction: float, evacuation_started: bool) -> int:
	var phase := 0 if time_ratio < 0.30 else (1 if time_ratio < 0.68 else 2)
	if construction >= 55.0:
		phase = maxi(phase, 1)
	if evacuation_started:
		phase = 2
	return maxi(previous, phase)
