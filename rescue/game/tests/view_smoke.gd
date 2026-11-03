extends SceneTree
var failed := false
func check(ok: bool, label: String) -> void:
	if ok:
		print("VIEW TEST OK: "+label)
	else:
		failed=true
		push_error("VIEW TEST FAILED: "+label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	check(scene != null,"Scene chargement")
	if scene == null:
		quit(1)
		return
	var main: Node2D = scene.instantiate() as Node2D
	root.add_child(main)
	await process_frame
	check(main != null,"Moteur graphique instancie")
	check(main.get("state") != null,"Modele de mission injecte")
	check(str(main.get("game_mode"))=="DEMO","Mode demonstration par defaut et explicite")
	check(main.get("act_buttons").size()==3,"Commandes de test presentes")
	await create_timer(0.3).timeout
	main.call("_switch_mode")
	check(str(main.get("game_mode"))=="LIVE","Mode LIVE accessible")
	var model: RefCounted = main.get("state")
	check(str(model.get("status"))=="WAITING","Pas de mission LIVE sans spectateur")
	main.call("_handle_packet",JSON.stringify({"type":"event","event":"chat","user":"SpectateurLive","text":"!join"}))
	check(model.get("participants").has("SpectateurLive"),"TikTok comment !join recu par le jeu")
	main.call("_handle_packet",JSON.stringify({"type":"event","event":"gift","user":"SpectateurLive","gift_name":"Rose","count":2}))
	check(int(model.get("gifted_resources"))==8,"Cadeau TikTok converti en materiaux")
	check(model.get("events").size()>0,"Journal d'actions visibles")
	print("VIEW TEST RESULT: "+("FAILED" if failed else "SUCCESS"))
	quit(1 if failed else 0)
