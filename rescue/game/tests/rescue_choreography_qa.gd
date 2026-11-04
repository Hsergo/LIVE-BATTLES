extends SceneTree
## Prepared for a future manual production QA run. No Windows export is needed.
var failures := 0
func check(valid: bool, description: String) -> void:
	if not valid:
		failures += 1
		push_error("CHOREOGRAPHY QA FAIL: " + description)
	else:
		print("CHOREOGRAPHY QA OK: " + description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script = load("res://scripts/mission.gd")
	var model: RefCounted = script.new()
	model.call("configure",false)
	check(bool(model.call("join","alice")),"Real spectator joins without buying")
	model.set("progress",100.0)
	model.set("strength",90.0)
	check(bool(model.call("rescue","alice")),"Alice requests free evacuation")
	check(int(model.get("rescue_queue"))==1,"One physical evacuation queued")
	var queued: Array[String] = model.get("rescue_owners")
	check(queued.size()==1 and queued[0]=="alice","Rescue retains requester's identity")
	model.call("tick",0.1)
	var crossings: Array = model.get("crossings")
	check(crossings.size()==1,"One evacuee actually departs")
	if not crossings.is_empty():
		check(str(crossings[0].get("rescuer",""))=="alice","Passenger linked to real rescuer")
		check(int(crossings[0].get("person_index",-1))==0,"Stable villager ID")
	var civilians := load("res://scripts/villagers_3d.gd").new() as Node3D
	root.add_child(civilians)
	civilians.call("setup",model,"bridge")
	civilians.call("sync",0.1)
	check(int(civilians.call("movement_count"))==1,"One villager visibly walks toward bridge")
	var crowd: Array = civilians.get("crowd")
	if not crowd.is_empty():
		check(str(crowd[0]["status_tag"].text)=="EN ROUTE","Village resident displays travel stage")
	if not crossings.is_empty():
		var rescued_entry: Dictionary = crossings[0]
		rescued_entry["p"] = 0.99
		model.call("tick",0.1)
		civilians.call("sync",0.1)
		check(int(model.get("saved"))==1,"Arrival increments the rescue score")
		check(int(model.get("rescuer_points").get("alice",0))==19,"Request + confirmed arrival both credit Alice")
		check(str(crowd[0]["phase"])=="safe","Resident changes from transit to safe")
		check(bool(crowd[0]["status_tag"].visible),"Arrival confirmation appears above character")
	civilians.queue_free()

	for entry in [{"level":7,"scene":"lighthouse","stage":"boat","label":"A BORD"},
		{"level":4,"scene":"dike","stage":"boat","label":"A BORD"},
		{"level":10,"scene":"dam","stage":"boat","label":"A BORD"},
		{"level":13,"scene":"helipad","stage":"flight","label":"EN VOL"}]:
		model.set("mission_index",int(entry["level"]))
		model.call("_start_mission",false)
		model.set("progress",100.0)
		model.set("strength",95.0)
		check(bool(model.call("rescue","alice")),"Mission "+str(entry["scene"])+": valid request")
		model.call("tick",0.1)
		var transport: Array = model.get("crossings")
		var new_npc := load("res://scripts/villagers_3d.gd").new() as Node3D
		root.add_child(new_npc)
		new_npc.call("setup",model,str(entry["scene"]))
		if not transport.is_empty():
			var passenger: Dictionary = transport[0]
			passenger["p"] = 0.51
			new_npc.call("sync",0.1)
			var npc: Dictionary = new_npc.get("crowd")[0]
			check(str(npc["route_stage"])==str(entry["stage"]),"Correct vehicle stage for "+str(entry["scene"]))
			check(str(npc["status_tag"].text)==str(entry["label"]),"Readable transport status "+str(entry["scene"]))
			check((npc["node"] as CharacterBody3D).collision_mask==0,"Vehicle passenger doesn't collide with structures")
			check((npc["node"] as CharacterBody3D).collision_layer==0,"Vehicle passenger does not block other NPCs")
		new_npc.queue_free()

	model.call("configure",false)
	for i in range(60):
		model.call("join","real_person_%d" % i)
	var world := load("res://scripts/world_3d.gd").new() as Node3D
	root.add_child(world)
	world.call("initialize",model,true)
	check(int(world.call("live_participants"))==60,"All 60 viewers are credited")
	check(int(world.call("visible_workers"))<=48,"Crew render budget is respected")
	check(int(world.call("visible_workers"))>=12,"Many workers can be visible")
	check(int(world.call("visible_civilians"))==int(model.get("target")),"Civilian population independent of TikTok users")
	world.queue_free()
	print("CHOREOGRAPHY QA RESULT: " + ("PASS" if failures==0 else "FAIL "+str(failures)))
	quit(0 if failures==0 else 1)
