extends SceneTree
## Source-phase acceptance test: must be run during QA, not while art is being produced.
var failures := 0
func verify(condition: bool, message: String) -> void:
	if condition:
		print("CHARACTERS STAGE OK: " + message)
	else:
		failures += 1
		push_error("CHARACTERS STAGE FAILED: " + message)

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var mission: RefCounted = load("res://scripts/mission.gd").new()
	mission.call("configure",true)
	var world: Node3D = load("res://scripts/world_3d.gd").new()
	root.add_child(world)
	world.call("initialize",mission,false)
	var crew: Dictionary = world.get("actors")
	verify(crew.size() >= 12,"Twelve clearly labelled demonstration workers")
	verify(float((world.get("camera") as Camera3D).fov) >= 60.0,"Readable 3D field of view")
	var found_worker_rig := false
	for name in crew.keys():
		var actor: Dictionary = crew[name]
		var rig: Node3D = actor["rig"]
		var label: Label3D = actor["label"]
		verify(label.get_parent() == rig,"Worker nameplate independent from hidden fallback model")
		if actor.has("avatar"):
			found_worker_rig = true
			var avatar: Node3D = actor["avatar"]
			verify(avatar.get_parent() == rig and avatar.visible,"Skinned worker remains visible")
			verify(not (actor["visual"] as Node3D).visible,"Procedural worker body hidden only when rig exists")
	verify(found_worker_rig,"At least one genuine GLB skeleton used by worker team")
	var villagers: Node3D = world.get("civilians")
	var crowd: Array = villagers.get("crowd")
	verify(crowd.size() == int(mission.get("target")),"Every village resident has an independent body")
	var found_villager_rig := false
	for person in crowd:
		var npc: Node3D = person["node"]
		var status_tag: Label3D = person["status_tag"]
		verify(not status_tag.visible,"No misleading saved indicator before rescue")
		verify(status_tag.get_parent() == npc,"Status label survives fallback being hidden")
		if person.has("avatar"):
			found_villager_rig = true
			var avatar: Node3D = person["avatar"]
			verify(avatar.get_parent() == npc and avatar.visible,"Civilian rig is not hidden by its parent")
			verify(not (person["visual"] as Node3D).visible,"Only procedural civilian fallback is hidden")
	verify(found_villager_rig,"Skinned civilian source has a visible instance")
	mission.set("progress",100.0)
	mission.set("strength",90.0)
	verify(bool(mission.call("rescue","DEMO")),"Free evacuation command accepted")
	mission.call("tick",0.1)
	villagers.call("sync",0.1)
	verify(int(villagers.call("movement_count")) == 1,"One physical civilian enters evacuation route")
	verify(bool(crowd[0]["status_tag"].visible),"Active evacuee has a readable status")
	verify(str(crowd[0]["status_tag"].text) == "EN ROUTE","Evacuee is identified as travelling")
	world.call("set_live",true)
	verify(int(world.call("visible_workers")) == 0,"No fabricated real TikTok spectators in LIVE")
	mission.call("configure",false)
	mission.call("join","vrai_spectateur")
	world.call("_sync_workers")
	verify(world.get("actors").has("vrai_spectateur"),"Only real joined user's worker is visible")
	verify(str(world.get("actors")["vrai_spectateur"]["label"].text) == "@vrai_spectateur","Live worker displays actual username")
	world.queue_free()
	print("CHARACTERS STAGE QA: " + ("PASS" if failures == 0 else "FAIL "+str(failures)))
	quit(0 if failures == 0 else 1)
