extends SceneTree
var fails := 0
func expect(ok: bool, msg: String) -> void:
	if ok:
		print("CAMPAIGN OK: " + msg)
	else:
		fails += 1
		push_error("CAMPAIGN FAIL: " + msg)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model_script = load("res://scripts/mission.gd")
	var catalog = load("res://scripts/mission_catalog.gd")
	var campaign: RefCounted = model_script.new()
	campaign.call("configure", false)
	for level_number in range(1,16):
		campaign.set("mission_index",level_number)
		campaign.call("_start_mission",true)
		var info: Dictionary = campaign.call("scenario_info")
		expect(campaign.call("join","constructeur_reel"),"Niveau %d : inscription libre" % level_number)
		campaign.set("progress",100.0)
		campaign.set("strength",72.0)
		campaign.set("wood",48.0)
		var before := float(campaign.get("strength"))
		var special_ok: bool = campaign.call("receive","constructeur_reel","!special")
		expect(special_ok,"Niveau %d : commande speciale gratuite" % level_number)
		expect(int(campaign.get("gifted_resources")) == 0,"Niveau %d : aucun cadeau obligatoire" % level_number)
		expect(int(campaign.get("builder_points").get("constructeur_reel",0)) >= 8,"Niveau %d : action attribuee au vrai auteur" % level_number)
		if str(info["site_type"]) == "dam" or str(info["site_type"]) == "dike":
			expect(float(campaign.get("strength")) > before,"Niveau %d : pompage / vannes renforcent le site" % level_number)
		# Force a distinct storm stage without depending on the desktop render.
		campaign.set("elapsed",float(campaign.get("total_duration"))*0.36)
		campaign.call("tick",0.1)
		expect(int(campaign.get("weather_stage")) >= 1,"Niveau %d : danger progressif" % level_number)
		campaign.set("saved",int(campaign.get("target")))
		campaign.call("tick",0.1)
		expect(str(campaign.get("status")) == "RESULT","Niveau %d : victoire et ecran final" % level_number)
		campaign.set("result_seconds",0.1)
		campaign.call("tick",0.1)
		expect(int(campaign.get("mission_index")) == level_number+1,"Niveau %d : passage au niveau suivant" % level_number)
	# Also verify non-paying failure paths resolve, rather than freezing.
	campaign.call("configure",false)
	campaign.call("join","spectateur_reel")
	campaign.set("seconds",0.0)
	campaign.call("tick",0.1)
	expect(str(campaign.get("status")) == "RESULT","Echec par timeout est definitif, pas de mission figee")
	print("CAMPAIGN TEST RESULT: " + ("PASS" if fails == 0 else "FAIL " + str(fails)))
	quit(0 if fails == 0 else 1)
