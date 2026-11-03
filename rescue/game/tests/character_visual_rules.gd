extends SceneTree
## Written as a production acceptance test. Run manually in Godot when
## the production phase is complete; it does not trigger any Windows build.
var errors := 0

func ensure(ok: bool, label: String) -> void:
	if ok:
		print("CHARACTER DESIGN OK: "+label)
	else:
		errors += 1
		push_error("CHARACTER DESIGN FAIL: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rules: RefCounted = load("res://scripts/mission.gd").new()
	rules.call("configure",true)
	var population: Node3D = load("res://scripts/villagers_3d.gd").new()
	root.add_child(population)
	population.call("setup",rules,"bridge")
	ensure(int(population.call("visible_count")) == int(rules.get("target")),"Chaque villageois a son propre corps 3D")
	ensure(int(population.call("movement_count")) == 0,"Tous les villageois commencent au village")
	ensure(population.get("waiting_sign") != null,"Panneau de village identifiable")
	ensure(population.get("safe_sign") != null,"Refuge reconnaissable")
	rules.set("progress",100.0)
	rules.set("strength",95.0)
	ensure(bool(rules.call("rescue","DEMO")),"Sauvetage declenche sans don")
	rules.call("tick",0.1)
	population.call("sync",0.1)
	ensure(int(population.call("movement_count")) > 0,"Un vrai NPC traverse et est visible")
	var moving: Array = rules.get("crossings")
	ensure(int(moving[0].get("person_index",-1)) == 0,"Identifiant du villageois stable")
	for i in range(75):
		rules.call("tick",0.1)
		population.call("sync",0.1)
	ensure(int(rules.get("saved")) > 0,"Villageois effectivement sauve")
	var arrived: Vector3 = population.call("last_rescued_position")
	ensure(arrived is Vector3,"Position du villageois disponible pour gros plan camera")
	rules.set("mission_index",4)
	rules.call("_start_mission",true)
	population.call("setup",rules,"dike")
	ensure(int(population.call("visible_count")) == 14,"La digue affiche 14 villageois differents")
	ensure(int(population.call("movement_count")) == 0,"Population renouvelee au prochain niveau")
	population.queue_free()
	print("CHARACTER ACCEPTANCE: "+("PASS" if errors == 0 else "FAILED"))
	quit(0 if errors == 0 else 1)
