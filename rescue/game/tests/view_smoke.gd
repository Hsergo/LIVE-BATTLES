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
	var world: Node3D = main.get("world_3d") as Node3D
	check(world != null,"Moteur graphique 3D instancie")
	check(main.get("enable_3d"),"Affichage 3D actif par defaut")
	check(world.get("camera") != null,"Camera 360 degres disponible")
	check(int(world.call("visible_workers")) >= 6,"Plusieurs ouvriers visibles en demonstration")
	check(world.get("segments").size() >= 10,"Construction en 3D composee de vraies sections")

	await create_timer(0.3).timeout
	main.call("_switch_mode")
	check(str(main.get("game_mode"))=="LIVE","Mode LIVE accessible")
	var model: RefCounted = main.get("state")
	check(str(model.get("status"))=="WAITING","Pas de mission LIVE sans spectateur")
	main.call("_handle_packet",JSON.stringify({"type":"event","event":"chat","user":"FauxSpectateur","text":"!join","source":"simulator"}))
	check(not model.get("participants").has("FauxSpectateur"),"La simulation est rejetee pendant le LIVE reel")
	main.call("_handle_packet",JSON.stringify({"type":"event","event":"chat","user":"SpectateurLive","text":"!join","source":"tikfinity"}))
	check(model.get("participants").has("SpectateurLive"),"TikTok comment !join recu par le jeu")
	main.call("_handle_packet",JSON.stringify({"type":"event","event":"gift","user":"SpectateurLive","gift_name":"Rose","count":2,"source":"tikfinity"}))
	check(int(model.get("gifted_resources"))==8,"Cadeau TikTok converti en materiaux")
	check(model.get("events").size()>0,"Journal d'actions visibles")
	model.set("mission_index",2)
	model.call("_start_mission",false)
	check(str(model.call("scenario_info").get("id"))=="dike","Scene de digue disponible")
	model.set("mission_index",3)
	model.call("_start_mission",false)
	check(str(model.call("scenario_info").get("id"))=="lighthouse","Scene de phare disponible")
	check(model.get("participants").has("SpectateurLive"),"Les vrais participants restent inscrits entre missions")
	for i in range(55):
		model.call("join","user_%d" % i)
	world.call("_sync_workers")
	check(int(world.call("visible_workers")) >= 12,"Le chantier ne reste pas a deux ou trois ouvriers")
	check(int(world.call("visible_workers")) <= 48,"Limite de rendu 3D pour assurer les performances")
	check(int(world.call("live_participants")) >= 56,"Les joueurs non affiches restent comptabilises")

	print("VIEW TEST RESULT: "+("FAILED" if failed else "SUCCESS"))
	quit(1 if failed else 0)
