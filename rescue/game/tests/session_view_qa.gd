extends SceneTree
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("SESSION VIEW OK: "+label)
	else:
		failures += 1
		push_error("SESSION VIEW FAIL: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	await process_frame
	check(main.get("session_picker").selected==2,"Two-hour marathon is available by default")
	main.call("_switch_mode")
	var model: RefCounted = main.get("state")
	check(bool(model.call("is_paused")),"LIVE waits for a confirmed connection")
	main.call("_handle_packet",JSON.stringify({"type":"event","event":"chat","user":"alice","text":"!build","source":"tikfinity"}))
	check(not bool(model.call("is_paused")) and float(model.get("progress"))>14.0,"An authentic source packet resumes and applies free work")
	main.call("_handle_packet",JSON.stringify({"type":"status","message":"SOURCE DECONNECTEE","connection":{"liveConfirmed":false}}))
	var before := float(model.get("elapsed"))
	model.call("tick",0.1)
	check(bool(model.call("is_paused")) and float(model.get("elapsed"))==before,"Connection loss freezes the mission clock")
	main.call("_toggle_pause")
	main.call("_handle_packet",JSON.stringify({"type":"status","message":"CONNECTE","connection":{"liveConfirmed":true}}))
	check(bool(model.call("is_paused")),"Network recovery respects an organizer pause")
	main.call("_toggle_pause")
	check(not bool(model.call("is_paused")),"Organizer can continue after reconnection")
	var world: Node3D = main.get("world_3d")
	model.set("progress",100.0)
	model.call("rescue","alice")
	for i in range(25): model.call("tick",0.1)
	var payload: Dictionary = JSON.parse_string(JSON.stringify(model.call("snapshot")))
	check(bool(model.call("restore",payload)),"A running scene restores the same model")
	model.call("set_pause","manual",true)
	world.call("_process",0.0)
	var entry: Dictionary = model.get("crossings")[0]
	var population: Node3D = world.get("civilians")
	var expected: Vector3 = population.call("_route",float(entry["p"]),int(entry["person_index"]),int(entry["lane"]))
	var actual: Vector3 = population.call("evacuee_position",int(entry["person_index"]))
	check(actual.distance_to(expected)<0.05,"Recovered civilian appears at its recorded route position")
	var session: RefCounted = model.get("marathon")
	model.set("status","CHALLENGE")
	for i in range(3):
		session.set("challenge_index",i)
		session.set("challenge_stage",0)
		session.set("challenge_progress",0.0)
		world.call("_process",0.1)
		var station: Node3D = world.get("support_setpiece")
		check(station.visible and station.get("parts").size()==3,"Support scene %d contains three stage objects" % i)
		session.set("challenge_stage",2)
		station.call("sync")
		check(station.get("parts")[0].scale.y==1.0 and station.get("parts")[2].scale.y<1.0,"Completed and pending stages have different geometry")
	main.queue_free()
	await process_frame
	print("SESSION VIEW RESULT: "+("PASS" if failures==0 else "FAIL "+str(failures)))
	quit(0 if failures==0 else 1)
