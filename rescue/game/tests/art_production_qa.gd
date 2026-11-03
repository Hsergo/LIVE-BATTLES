extends SceneTree
## Godot headless production regression tests; NO Windows build.
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok:
		print("ART QA PASS: " + label)
	else:
		failures += 1
		push_error("ART QA FAIL: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model: RefCounted = load("res://scripts/mission.gd").new()
	model.call("configure",true)
	check(ResourceLoader.exists("res://assets/characters/base_male_rigged.glb"),"Imported GLB is available")
	var avatar: Node3D = load("res://scripts/rigged_humanoid.gd").new()
	root.add_child(avatar)
	var loaded: bool = bool(avatar.call("setup",1.0))
	check(loaded,"Skinned human GLB imported into Godot")
	if loaded:
		check(int(avatar.call("rig_bone_count")) >= 50,"Real skeleton has at least 50 bones")
		avatar.call("animate",0.016,"walk")
		avatar.call("animate",0.016,"build")
		avatar.call("animate",0.016,"rescue")
	var world: Node3D = load("res://scripts/world_3d.gd").new()
	root.add_child(world)
	world.call("initialize",model,false)
	check(int(world.call("visible_civilians"))==int(model.get("target")),"Every civilian has its own 3D body")
	check(int(world.call("visible_workers")) >= 7,"Multiple workers are visible")
	check(world.get("segments").size() >= 15,"Buildable 3D modules exist")
	var first_module: Node3D = world.get("segments")[0]
	var collision := first_module.get_node_or_null("StructureCollider") as StaticBody3D
	check(collision != null,"Construction uses a StaticBody3D collider")
	world.call("_update_segments",0.0)
	if collision != null:
		check(collision.collision_layer == 0,"Unbuilt module has no collision")
	world.call("_update_segments",100.0)
	if collision != null:
		check(collision.collision_layer != 0,"Built module has physical collision")
	var civilians: Node3D = world.get("civilians") as Node3D
	model.set("progress",100.0)
	model.set("strength",90.0)
	check(bool(model.call("rescue","DEMO")),"Free rescue accepted on completed bridge")
	model.call("tick",0.1)
	world.call("_animate_rescues")
	civilians.call("sync",0.1)
	check(int(civilians.call("movement_count"))>=1,"Villager is visibly in transit")
	model.set("strength",10.0)
	var p_before: float = float(model.get("crossings")[0]["p"])
	model.call("tick",0.1)
	var p_after: float = float(model.get("crossings")[0]["p"])
	check(is_equal_approx(p_after,p_before),"Villager pauses on an unsafe bridge")
	model.set("strength",95.0)
	model.call("tick",0.1)
	check(float(model.get("crossings")[0]["p"])>p_after,"Movement resumes when repaired")
	check(int(model.get("crossings")[0].get("person_index",-1))==0,"Civilian identity is stable")
	for level_number in [1,4,7,10,13]:
		model.set("mission_index",level_number)
		model.call("_start_mission",true)
		world.call("_rebuild_world")
		check(int(world.call("visible_civilians"))>0,"Civilian roster in mission "+str(level_number))
		check(world.get("segments").size()==15,"3D construction in mission "+str(level_number))
		check(world.get("civilians")!=null,"Civilian controller in mission "+str(level_number))
	print("ART QA RESULT: " + ("PASS" if failures==0 else "FAILED"))
	quit(0 if failures==0 else 1)
