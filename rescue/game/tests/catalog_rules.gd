extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if value:
		print("CATALOG OK: " + label)
	else:
		failures += 1
		push_error("CATALOG FAIL: " + label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var catalog = load("res://scripts/mission_catalog.gd")
	check(catalog.validate(), "15 niveaux uniques et parametres valides")
	check(catalog.LEVELS.size() == 15, "15 niveaux")
	var types := {}
	var total_duration := 0
	var ids := {}
	for level in catalog.LEVELS:
		types[str(level["site_type"])] = true
		ids[str(level["id"])] = true
		total_duration += int(level["duration"])
		check(str(level["special"]).begins_with("!"), "Action speciale pour " + str(level["id"]))
	check(types.size() == 5, "Cinq types de decors 3D")
	check(ids.size() == 15, "Identifiants uniques")
	check(total_duration >= 7200, "Plus de deux heures de duree maximale pour la campagne")
	var mission: RefCounted = load("res://scripts/mission.gd").new()
	mission.call("configure",false)
	for i in range(15):
		mission.set("mission_index", i + 1)
		mission.call("_start_mission",true)
		var info: Dictionary = mission.call("scenario_info")
		check(str(info["id"]) == str(catalog.LEVELS[i]["id"]), "Mission %d chargee" % (i+1))
		check(int(mission.get("target")) == int(info["target"]), "Objectif du niveau %d" % (i+1))
		check(float(mission.get("total_duration")) == float(info["duration"]), "Chronometre du niveau %d" % (i+1))
	print("CATALOG TEST RESULT: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
