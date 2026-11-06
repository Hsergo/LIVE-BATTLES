extends SceneTree
## Prepared static-production acceptance script: do not run/build until the QA stage.
var errors := 0
func check(ok: bool, what: String) -> void:
	if not ok:
		errors += 1
		push_error("CREW LOD FAIL: "+what)
	else:
		print("CREW LOD OK: "+what)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model: RefCounted = load("res://scripts/mission.gd").new()
	model.call("configure",false)
	for i in range(60):
		model.call("join","viewer_%02d" % i)
	var world := load("res://scripts/world_3d.gd").new() as Node3D
	root.add_child(world)
	world.call("initialize",model,true)
	check(int(world.call("live_participants"))==60,"All users remain registered")
	check(int(world.call("visible_workers"))==48,"Forty-eight workers displayed")
	world.call("_update_worker_lod")
	var actors: Dictionary = world.get("actors")
	var full := 0
	var light := 0
	for username in actors.keys():
		var actor: Dictionary = actors[username]
		var low: Node3D = actor["lod"]
		if low.visible:
			light += 1
			check(not (actor["visual"] as Node3D).visible,"Distant worker hides expensive model")
			if actor.has("avatar"):
				check(not (actor["avatar"] as Node3D).visible,"Distant rigged character has no active skeleton mesh")
		else:
			full += 1
			if actor.has("avatar"):
				check((actor["avatar"] as Node3D).visible,"Nearby rig appears correctly")
			else:
				check((actor["visual"] as Node3D).visible,"Nearby procedural human appears correctly")
		check((actor["label"] as Label3D).get_parent()==actor["rig"],"Nameplate stays with user avatar")
	check(full==18,"Exactly eighteen detailed characters")
	check(light==30,"Other thirty characters use light silhouettes")
	world.call("record_event",{"kind":"build","user":"viewer_58"})
	world.call("_update_worker_lod")
	actors = world.get("actors")
	check(actors.has("viewer_58"),"Active late spectator replaces least active slot")
	if actors.has("viewer_58"):
		var worker: Dictionary = actors["viewer_58"]
		check(not (worker["lod"] as Node3D).visible,"Recent contribution takes priority over camera distance")
	check(int(world.call("visible_workers"))==48,"Late entry never exceeds scene render budget")
	check(int(world.call("live_participants"))==60,"Non-visible viewers retain all game participation")
	world.queue_free()
	print("CREW LOD RESULT: "+("PASS" if errors==0 else "FAIL "+str(errors)))
	quit(0 if errors==0 else 1)
