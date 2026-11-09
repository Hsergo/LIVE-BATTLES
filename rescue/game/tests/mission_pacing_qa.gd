extends SceneTree
## Behavioral source tests: real accepted actions, burst fairness and free wins.
const Mission = preload("res://scripts/mission.gd")
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok:
		print("PACING OK: " + message)
	else:
		failed += 1
		push_error("PACING FAIL: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(20261109)
	var model := Mission.new()
	model.configure(false)
	for i in range(500):
		model.join("player_%d" % i)
	check(model.active_players() == 0, "500 registrations alone do not raise difficulty")
	model.gift("player_0", "Rose", 1)
	check(model.active_players() == 0, "A gift never counts as free participation")
	check(not model.vote("player_0", "9"), "Invalid vote is rejected")
	check(not model.build("unregistered"), "Unregistered action is rejected")
	check(model.active_players() == 0, "Invalid commands do not change pacing")
	model.wood = 34.0
	var credited_actions := 0
	for i in range(500):
		var user := "player_%d" % i
		var before := model.progress
		if model.build(user) and model.progress > before and int(model.builder_points[user]) > 0:
			credited_actions += 1
	check(credited_actions == 500, "All 500 burst actions contribute visible work and personal points")
	check(model.active_players() == 500, "Every distinct contributor is counted")
	check(model.progress < 99.9, "One 500-player burst cannot finish the construction")
	check(not model.build("player_499"), "Same-player spam remains blocked")
	check(model.active_players() == 500, "Spam does not inflate the active audience")
	var built := model.progress
	var previous_scale := model.pacing.work_scale
	for frame in range(460):
		model.pacing.tick(0.1)
		if frame % 100 == 0:
			for i in range(5):
				model.pacing.record_action("player_%d" % i)
	check(model.active_players() == 5, "A 500-to-5 audience drop excludes inactive participants")
	check(model.pacing.work_scale < previous_scale and model.pacing.work_scale > 4.0,
		"Departures ease workload gradually, without a one-frame difficulty jump")
	for frame in range(600):
		model.pacing.tick(0.1)
	check(model.active_players() == 0, "Expired activity stops counting")
	check(model.pacing.work_scale < previous_scale, "Departures make the workload lighter")
	check(is_equal_approx(model.progress, built), "Rebalancing never erases completed construction")
	model.configure(true)
	model.build("DEMO")
	check(model.active_players() == 0 and is_equal_approx(model.pacing.work_scale,1.0),
		"Demo keeps its authored rhythm and creates no live participant")

	model.configure(false)
	model.join("builder")
	model._enqueue_rescue("builder",1)
	model.tick(0.1)
	check(model.mission_phase == 0, "A queued evacuation cannot skip unfinished construction")
	model.progress = 60.0
	model.tick(0.1)
	check(model.mission_phase == 1, "Construction advances Act II without waiting for the timer")
	model.progress = 100.0
	model.rescue("builder")
	model.tick(0.1)
	check(model.mission_phase == 2, "Actual evacuation advances Act III")
	model.progress = 25.0
	model.tick(0.1)
	check(model.mission_phase == 2, "Damage cannot rewind the narrative")
	model.seconds = 0.0
	model.tick(0.1)
	check(model.status == "RESULT", "Adaptive pacing cannot prevent timeout")
	model.result_seconds = 0.1
	model.tick(0.1)
	check(model.active_players() == 1, "Recent activity is carried into the next mission")
	model.configure(false)
	check(model.active_players() == 0, "A fresh session clears prior activity")

	for size in [1, 5, 50]:
		for level in range(1,16):
			_play_mission(level, size)
	for size in [100, 500]:
		_play_mission(1, size)
		_play_mission(15, size)
	print("PACING RESULT: " + ("PASS" if failed == 0 else "FAIL " + str(failed)))
	quit(0 if failed == 0 else 1)

func _play_mission(level: int, size: int) -> void:
	var model := Mission.new()
	model.configure(false)
	model.mission_index = level
	model._start_mission(true)
	for i in range(size):
		model.join("crew_%d" % i)
	var frames := 0
	while model.status == "RUNNING" and frames < 6200:
		# A cooperative, regular team: one free command per player every 3 s.
		if frames % 30 == 0:
			for i in range(size):
				var user := "crew_%d" % i
				if model.strength < 70.0:
					model.repair(user)
				elif model.progress < 99.9:
					model.build(user)
				elif model.saved + model.rescue_queue + model.crossings.size() < model.target:
					model.rescue(user)
				elif not model.secondary_complete:
					model.special(user)
		model.tick(0.1)
		frames += 1
	check(model.status == "RESULT" and model.saved == model.target and model.star_rating == 3,
		"Mission %02d / %d players can win using free commands" % [level,size])
	check(model.gifted_resources == 0 and model.participants.size() == size,
		"Mission %02d / %d players: no gifts or invented players" % [level,size])
	check(model.mission_phase == 2, "Mission %02d / %d players reaches the final act" % [level,size])
	check(model.pacing.pressure_scale >= 0.85 and model.pacing.pressure_scale <= 1.15,
		"Mission %02d / %d players has bounded hazard pressure" % [level,size])
	print("PACING SAMPLE level=%02d players=%d elapsed=%.1f saved=%d/%d" %
		[level,size,model.elapsed,model.saved,model.target])
