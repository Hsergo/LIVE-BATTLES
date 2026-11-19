extends SceneTree
const Mission = preload("res://scripts/mission.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("MARATHON FAIL: "+label)
	else:
		print("MARATHON OK: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(17011)
	var model := Mission.new()
	model.configure_session(false,true,7200.0)
	for i in range(100): model.tick(0.1)
	check(model.marathon.elapsed==0.0,"Waiting for first participant does not consume marathon time")
	model.join("alice")
	model.set_pause("manual",true)
	model.set_pause("network",true)
	model.tick(0.1)
	check(model.elapsed==0.0 and not model.build("alice"),"Pause freezes time and gameplay")
	model.set_pause("network",false)
	check(model.is_paused(),"Reconnection cannot cancel a manual pause")
	model.set_pause("manual",false)
	model._finish(false)
	model.result_seconds = 0.0
	model.tick(0.1)
	check(model.status=="CHALLENGE","A mission is followed by a playable support operation")
	var before := model.marathon.challenge_fraction()
	model.gift("alice","Rose",5)
	check(model.marathon.challenge_fraction()==before,"Gifts do not complete free support challenges")
	model.marathon.challenge_seconds = 0.0
	model.tick(0.1)
	check(model.status=="RUNNING" and model.mission_index==2,"A timed-out support challenge never blocks the next mission")
	check(model.wood>=54.0,"Materials received during support are carried to the next mission")
	for size in [1,5,50]:
		_simulate(size,7200.0)
	_simulate(50,10800.0)
	print("MARATHON RESULT: "+("PASS" if failures==0 else "FAIL "+str(failures)))
	quit(0 if failures==0 else 1)

func _simulate(size: int, duration: float) -> void:
	var model := Mission.new()
	model.configure_session(false,true,duration)
	for i in range(size): model.join("crew_%d" % i)
	var seen := {}
	var frames := 0
	var checkpoints := 0
	var start := Time.get_ticks_msec()
	while model.status!="SESSION_COMPLETE" and frames<int((duration+750.0)*10.0):
		if frames%30==0:
			# Simulate a temporary audience drop during the middle hour.
			var active := mini(size,5) if frames>18000 and frames<36000 else size
			for i in range(active):
				var user := "crew_%d" % i
				if model.status=="CHALLENGE":
					seen[str(model.marathon.challenge_info()["id"])] = true
					model.receive(user,"!"+model.marathon.focus_action())
				elif model.status=="RUNNING":
					if model.strength<72.0: model.repair(user)
					elif model.progress<99.9: model.build(user)
					elif model.saved+model.rescue_queue+model.crossings.size()<model.target: model.rescue(user)
					elif not model.secondary_complete: model.special(user)
		if frames>0 and frames%9000==0:
			var restored := Mission.new()
			var payload: Dictionary = JSON.parse_string(JSON.stringify(model.snapshot()))
			if not restored.restore(payload):
				check(false,"Checkpoint rejected at frame %d status %s" % [frames,model.status])
				break
			model = restored
			checkpoints += 1
		model.tick(0.1)
		frames += 1
	check(model.status=="SESSION_COMPLETE","%d players / %dh reaches a final summary" % [size,int(duration/3600.0)])
	check(model.marathon.elapsed>=duration and model.marathon.elapsed<duration+750.0,"Duration ends at a safe mission or support boundary")
	check(seen.size()==3 and model.marathon.challenges_won>0,"All three support operations are playable")
	check(model.marathon.rounds>15 and model.marathon.total_saved>0,"Campaign continues beyond one 15-mission cycle")
	check(model.participants.size()==size and model.gifted_resources==0,"No invented players or required gifts")
	check(checkpoints>=7,"Repeated JSON recovery preserves the long session")
	check(model.visual_events.size()<=model.MAX_VISUAL_EVENTS and model.events.size()<=model.MAX_EVENTS,"Event history remains bounded")
	print("MARATHON SAMPLE players=%d target=%.0f elapsed=%.1f rounds=%d rescues=%d support=%d restores=%d runtime_ms=%d" % [size,duration,model.marathon.elapsed,model.marathon.rounds,model.marathon.total_saved,model.marathon.challenges_won,checkpoints,Time.get_ticks_msec()-start])
