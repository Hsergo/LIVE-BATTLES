extends SceneTree
## Pure mathematical acceptance checks; queued for future source+engine QA.
var failure_count := 0
func ensure(ok: bool, description: String) -> void:
	if not ok:
		failure_count += 1
		push_error("EVACUATION ROUTES FAIL: "+description)
	else:
		print("EVACUATION ROUTES OK: "+description)
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	var routes = load("res://scripts/rescue_routes_3d.gd")
	var start := Vector3(-13,0.1,-1)
	var dest := Vector3(13,0.1,1)
	for scene in ["bridge","dike","dam","lighthouse","helipad"]:
		ensure(routes.position(scene,0.0,start,dest,0).distance_to(start)<0.01,scene+" has correct start")
		ensure(routes.position(scene,1.0,start,dest,0).distance_to(dest)<0.01,scene+" ends inside refuge")
		ensure(routes.position(scene,0.2,start,dest,0).is_finite(),scene+" staging route is finite")
		ensure(routes.position(scene,0.51,start,dest,1).is_finite(),scene+" crossing is finite")
		ensure(routes.stage(scene,0.04)=="approach",scene+" approach phase")
		ensure(routes.stage(scene,0.92)=="arrival",scene+" arrival phase")
	ensure(routes.stage("bridge",0.50)=="bridge","Bridge pedestrian crossing")
	ensure(routes.stage("lighthouse",0.50)=="boat","Boat departure")
	ensure(routes.stage("helipad",0.50)=="flight","Helicopter transport")
	ensure(routes.transported("dam",0.5),"Dam requires real evacuation boat")
	ensure(not routes.transported("bridge",0.5),"Bridge is pedestrian route")
	ensure(routes.has_vehicle("helipad"),"Helipad has transport")
	ensure(not routes.has_vehicle("bridge"),"Bridge has no unnecessary craft")
	print("EVACUATION ROUTES RESULT: "+("PASS" if failure_count==0 else "FAIL"))
	quit(0 if failure_count==0 else 1)
