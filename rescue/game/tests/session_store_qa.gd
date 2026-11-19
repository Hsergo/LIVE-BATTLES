extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Store = preload("res://scripts/session_store.gd")
var failed := 0
const PATH := "user://qa_session_store.json"

func check(ok: bool, message: String) -> void:
	if ok: print("SAVE OK: "+message)
	else:
		failed += 1
		push_error("SAVE FAIL: "+message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model := Mission.new()
	model.configure_session(false,true)
	model.join("alice")
	model.progress = 100.0
	model._enqueue_rescue("alice",3)
	for i in range(3): model.tick(0.1)
	model.crossings[2]["speed"] = 1.0
	for i in range(12): model.tick(0.1)
	check(model.saved==1 and model.saved_person_indices[0]==2 and model.crossings.size()==2,"Out-of-order physical arrivals retain their identities")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(model.snapshot()))
	var restored := Mission.new()
	check(restored.restore(snapshot),"A JSON snapshot with active crossings loads")
	check(restored.saved==1 and restored.crossings.size()==2 and restored.saved_person_indices==model.saved_person_indices,"Counts and in-transit identities survive recovery")
	var points := int(restored.rescuer_points["alice"])
	for i in range(120): restored.tick(0.1)
	check(restored.saved==3 and int(restored.rescuer_points["alice"])==points+24,"Only the two unfinished rescues receive arrival points")
	for i in range(50): restored.tick(0.1)
	check(restored.saved==3,"Recovered arrivals cannot be counted twice")
	var unchanged := JSON.stringify(restored.snapshot())
	for field in ["crossings","participants","numbers","marathon"]:
		var broken: Dictionary = snapshot.duplicate(true)
		broken[field] = "invalid"
		check(not restored.restore(broken),"Malformed "+field+" is rejected")
		check(JSON.stringify(restored.snapshot())==unchanged,"Rejected data does not partially modify the game")
	var duplicate: Dictionary = snapshot.duplicate(true)
	duplicate["crossings"][0]["person_index"] = duplicate["saved_ids"][0]
	check(not restored.restore(duplicate),"An already rescued person cannot also be in transit")
	var service := Store.new()
	check(service.save_game(model,PATH),"Primary checkpoint is written")
	check(service.save_game(restored,PATH),"Second checkpoint preserves the previous one")
	var file := FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string("{broken checkpoint")
	file.close()
	var fallback := Mission.new()
	check(service.load_game(fallback,PATH) and service.used_backup,"Corrupt primary falls back to last-good backup")
	check(fallback.saved==1 and fallback.crossings.size()==2,"Backup restores the expected earlier state")
	check(service.save_game(fallback,PATH),"Recovery can safely replace the damaged primary")
	var station := load("res://scripts/support_setpiece.gd").new() as Node3D
	root.add_child(station)
	fallback._finish(false)
	fallback.result_seconds = 0.0
	fallback.tick(0.1)
	station.call("setup",fallback)
	check(station.visible and station.get("parts").size()==3,"Support state has three visible stage objects")
	var support_copy := Mission.new()
	check(support_copy.restore(JSON.parse_string(JSON.stringify(fallback.snapshot()))),"Support operations can also be restored")
	station.free()
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	print("SESSION STORE RESULT: "+("PASS" if failed==0 else "FAIL "+str(failed)))
	quit(0 if failed==0 else 1)
