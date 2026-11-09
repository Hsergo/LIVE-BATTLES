extends SceneTree
## QA source test for all 15 distinct cooperative situations.
## Run manually in Godot before any Windows release; no paid TikTok gift needed.
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok:
		print("15 MISSIONS QA OK: "+message)
	else:
		failed += 1
		push_error("15 MISSIONS QA FAIL: "+message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog = load("res://scripts/mission_catalog.gd")
	var dynamics = load("res://scripts/mission_dynamics.gd")
	check(dynamics.validate(catalog.LEVELS),"15 unique hazards, levels and authored setpieces")
	var previous_goals: Dictionary = {}
	var previous_visuals: Dictionary = {}
	for level_number in range(1,16):
		var raw: Dictionary = catalog.LEVELS[level_number-1]
		var profile: Dictionary = dynamics.get_profile(str(raw["id"]))
		check(not profile.is_empty(),"Mission %02d has a defined mechanic" % level_number)
		previous_goals[str(profile["side_title"])] = true
		previous_visuals[str(profile["visual"])] = true
		var model: RefCounted = load("res://scripts/mission.gd").new()
		model.call("configure",false)
		model.set("mission_index",level_number)
		model.call("_start_mission",true)
		check(bool(model.call("join","tiktok_builder")),"Mission %02d starts for a real joined user" % level_number)
		check(str(model.get("secondary_label"))==str(profile["side_title"]),"Mission %02d unique cooperative objective" % level_number)
		check(float(model.get("secondary_goal"))>50.0,"Mission %02d secondary score goal" % level_number)
		var focus := str(profile["focus_action"])
		if focus=="build":
			model.set("progress",30.0)
		elif focus=="repair":
			model.set("strength",42.0)
		elif focus=="rescue":
			model.set("progress",100.0)
			model.set("strength",75.0)
		else:
			model.set("progress",35.0)
		var before := float(model.get("secondary_progress"))
		check(bool(model.call(focus,"tiktok_builder")),"Mission %02d free focus action accepted" % level_number)
		check(float(model.get("secondary_progress"))>before,"Mission %02d players influence unique objective" % level_number)
		check(int(model.get("gifted_resources"))==0,"Mission %02d no paid unlocks" % level_number)
		for turn in range(22):
			if bool(model.get("secondary_complete")):
				break
			model.call("_advance_secondary",focus,"tiktok_builder")
		check(bool(model.get("secondary_complete")),"Mission %02d free side objective can be won" % level_number)
		check(float(model.get("secondary_progress"))>=float(model.get("secondary_goal")),"Mission %02d visible score reaches goal" % level_number)
		model.set("strength",99.0)
		model.set("crisis_level",69.0)
		model.set("crisis_cooldown",0.0)
		model.call("tick",0.1)
		check(int(model.get("crisis_trigger_count"))==1,"Mission %02d specific danger is live" % level_number)
		model.set("elapsed",0.45*float(model.get("total_duration")))
		model.call("tick",0.1)
		check(int(model.get("mission_phase"))==1,"Mission %02d enters Act II" % level_number)
		model.set("elapsed",0.81*float(model.get("total_duration")))
		model.set("strength",99.0)
		model.call("tick",0.1)
		check(int(model.get("mission_phase"))==2,"Mission %02d enters Act III" % level_number)
		var setpiece: Node3D = load("res://scripts/mission_setpieces.gd").new()
		root.add_child(setpiece)
		setpiece.call("setup",model)
		check(str(setpiece.get("identity"))==str(raw["id"]),"Mission %02d has its own stage prop" % level_number)
		check(str(setpiece.get("visual"))==str(profile["visual"]),"Mission %02d uses correct art variant" % level_number)
		var landmark: Node3D = setpiece.get("landmark")
		check(landmark.get_child_count()>=3,"Mission %02d stage object has renderable geometry" % level_number)
		setpiece.call("sync",0.1)
		check(setpiece.get("warning")!=null,"Mission %02d has a reactive crisis beacon" % level_number)
		setpiece.queue_free()
	check(previous_goals.size()==15,"Exactly fifteen different player goals")
	check(previous_visuals.size()==15,"Exactly fifteen distinct mission landmark designs")
	print("15 MISSIONS RESULT: "+("PASS" if failed==0 else "FAIL "+str(failed)))
	quit(0 if failed==0 else 1)
