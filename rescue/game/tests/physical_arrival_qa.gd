extends SceneTree
## Prepared for a later manual Godot source test. No build is launched here.
## The 3D world must be the authority on final civilian arrival.
var failures := 0
var arrivals_allowed: Dictionary = {}

func confirmed_arrival(person_id: int) -> bool:
	return bool(arrivals_allowed.get(person_id,false))

func check(ok: bool, message: String) -> void:
	if ok:
		print("PHYSICAL ARRIVAL QA OK: "+message)
	else:
		failures += 1
		push_error("PHYSICAL ARRIVAL QA FAIL: "+message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var mission: RefCounted = load("res://scripts/mission.gd").new()
	mission.call("configure",false)
	mission.set("arrival_gate",Callable(self,"confirmed_arrival"))
	check(bool(mission.call("join","alice")),"Alice joins")
	check(bool(mission.call("join","bob")),"Bob joins")
	mission.set("progress",100.0)
	mission.set("strength",92.0)
	check(bool(mission.call("rescue","alice")),"Alice starts first evacuation")
	check(bool(mission.call("rescue","bob")),"Bob starts another evacuation")
	mission.call("tick",0.1)
	mission.call("tick",0.1)
	var travelers: Array = mission.get("crossings")
	check(travelers.size() == 2,"Two stable evacuated civilians")
	if travelers.size() == 2:
		check(str(travelers[0].get("rescuer",""))=="alice","First civilian belongs to Alice")
		check(str(travelers[1].get("rescuer",""))=="bob","Second civilian belongs to Bob")
		travelers[0]["p"] = 1.0
		travelers[1]["p"] = 1.0
		mission.call("tick",0.1)
		check(int(mission.get("saved"))==0,"Logical progress is not mistaken for actual physical arrival")
		check(mission.get("crossings").size()==2,"Both travelers wait until their bodies reach the refuge")
		arrivals_allowed[1] = true
		mission.call("tick",0.1)
		check(int(mission.get("saved"))==1,"Bob's physical arrival is confirmed")
		check(int(mission.get("last_rescued_person_index"))==1,"Camera follows Bob's actual civilian, not queue order")
		check(int(mission.get("rescuer_points").get("bob",0))==19,"Bob's rescue score is credited exactly once")
		check(int(mission.get("rescuer_points").get("alice",0))==7,"Alice has dispatch credit only")
		arrivals_allowed[0] = true
		mission.call("tick",0.1)
		check(int(mission.get("saved"))==2,"Alice's civilian reaches safety")
		check(int(mission.get("last_rescued_person_index"))==0,"Camera follows Alice's civilian")
		check(int(mission.get("rescuer_points").get("alice",0))==19,"Alice gets confirmed arrival points")
		mission.call("tick",0.1)
		check(int(mission.get("rescuer_points").get("alice",0))==19,"Cannot duplicate rescue credit")

	# Room capacity and ferry lanes: three boats maximum, fourth queues.
	var crowd: RefCounted = load("res://scripts/mission.gd").new()
	crowd.call("configure",false)
	for username in ["a","b","c","d"]:
		check(bool(crowd.call("join",username)),username+" joins the rescue")
	crowd.set("progress",100.0)
	crowd.set("strength",92.0)
	for username in ["a","b","c","d"]:
		check(bool(crowd.call("rescue",username)),username+" requests free evacuation")
	for frame in range(4):
		crowd.call("tick",0.1)
	var ferry_active: Array = crowd.get("crossings")
	var lanes: Dictionary = {}
	for traveler in ferry_active:
		var lane := int(traveler.get("lane",-1))
		lanes[lane] = true
	check(ferry_active.size()==3,"Only three concurrent ferry lanes used")
	check(lanes.size()==3,"No two ferry passengers occupy the same lane")
	check(int(crowd.get("rescue_queue"))==1,"Fourth rescuer remains queued, not forgotten")

	# Source-only mode stays independent from the renderer.
	var pure: RefCounted = load("res://scripts/mission.gd").new()
	pure.call("configure",false)
	pure.call("join","headless_user")
	pure.set("progress",100.0)
	pure.set("strength",99.0)
	pure.call("rescue","headless_user")
	pure.call("tick",0.1)
	var headless_crossings: Array = pure.get("crossings")
	if not headless_crossings.is_empty():
		headless_crossings[0]["p"] = 1.0
	pure.call("tick",0.1)
	check(int(pure.get("saved"))==1,"Pure rules still run without a graphical arrival callback")
	print("PHYSICAL ARRIVAL QA RESULT: "+("PASS" if failures==0 else "FAIL "+str(failures)))
	quit(0 if failures==0 else 1)
