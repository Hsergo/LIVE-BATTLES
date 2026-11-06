extends SceneTree
## Headless production test. It is not executed during this art-production phase.
## Explicitly check both collision hardware and model state after full crossing.
var failures := 0

func check(ok: bool, what: String) -> void:
	if ok:
		print("CROWD PHYSICS OK: "+what)
	else:
		failures += 1
		push_error("CROWD PHYSICS FAIL: "+what)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var motor := load("res://scripts/character_motor_3d.gd").new() as CharacterBody3D
	root.add_child(motor)
	motor.call("configure",2,0.24,1.60)
	motor.position = Vector3(0,0,0)
	check(bool(motor.call("has_physical_collider")),"Capsule de collision du personnage")
	check(motor.motion_mode == CharacterBody3D.MOTION_MODE_FLOATING,"Moteur compatible avec marches et tabliers")
	check(motor.collision_layer == 2,"Couche de collision villageois")
	var barrier := StaticBody3D.new()
	barrier.name = "TestWall"
	barrier.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.40,2.2,2.4)
	shape.shape = box
	shape.position.y = 1.10
	barrier.add_child(shape)
	barrier.position = Vector3(1.4,0,0)
	root.add_child(barrier)
	await physics_frame
	for i in range(55):
		await physics_frame
		motor.call("move_to",Vector3(4,0,0),3.6,1.0/60.0)
	check(motor.position.x < 1.20,"Personnage empeche de traverser une barriere")
	motor.queue_free()
	barrier.queue_free()
	var world_model: RefCounted = load("res://scripts/mission.gd").new()
	world_model.call("configure",true)
	var villagers := load("res://scripts/villagers_3d.gd").new() as Node3D
	root.add_child(villagers)
	villagers.call("setup",world_model,"bridge")
	check(int(villagers.call("visible_count")) == 12,"12 villageois presents pour la premiere mission")
	for entry in villagers.get("crowd"):
		var body: CharacterBody3D = entry["node"]
		check(bool(body.call("has_physical_collider")),"Capsule du villageois "+str(entry["id"]))
	check(world_model.get("crossings").is_empty(),"Aucune evacuation fictive avant commande")
	world_model.set("progress",100.0)
	world_model.set("strength",94.0)
	world_model.call("rescue","DEMO")
	for frame in range(800):
		await physics_frame
		world_model.call("tick",1.0/60.0)
		villagers.call("sync",1.0/60.0)
		if int(world_model.get("saved")) > 0:
			break
	check(int(world_model.get("saved")) > 0,"Un sauvetage gratuit aboutit")
	check(villagers.get("crowd")[0].get("phase") == "safe","Le villageois termine au refuge")
	check(int(villagers.call("movement_count")) == 0,"Fin de traversee vide la zone de circulation")
	check(int(world_model.get("gifted_resources")) == 0,"Aucun cadeau necessaire")
	print("CROWD PHYSICS RESULT: "+("PASS" if failures==0 else "FAIL "+str(failures)))
	quit(0 if failures==0 else 1)
