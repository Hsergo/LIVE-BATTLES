extends SceneTree
var fail_count := 0

func assert_that(condition: bool, description: String) -> void:
	if condition:
		print("MISSION TEST OK: " + description)
	else:
		fail_count += 1
		push_error("MISSION TEST FAILED: " + description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model_script = load("res://scripts/mission.gd")
	var model: RefCounted = model_script.new()
	model.call("configure",false)
	assert_that(str(model.get("status")) == "WAITING", "Pas de temps qui tourne sans vrais spectateurs")
	assert_that(not model.call("receive","alice","!build"), "Impossible de construire avant inscription")
	assert_that(model.call("receive","alice","!join"), "Inscription gratuite du premier spectateur")
	assert_that(str(model.get("status")) == "RUNNING", "Inscription declenche le jeu")
	assert_that(model.call("receive","alice","!build"), "Commande de construction valide")
	assert_that(float(model.get("progress")) > 14.0, "Construction ameliore le pont")
	assert_that(int(model.get("builder_points").get("alice",0)) > 0, "Chaque construction est attribuee au vrai ouvrier")
	assert_that(not model.call("receive","alice","!build"), "Anti-spam empeche attaque instantanee")
	model.set("elapsed",10.0)
	assert_that(model.call("receive","alice","!repair"), "Reparation gratuite possible")
	assert_that(model.call("gift","alice","Rose",2), "Rose reconnue")
	assert_that(not model.call("gift","alice","Cadeau faux",1), "Cadeaux non declares refuses")
	assert_that(int(model.get("gifted_resources")) == 8, "Rose x2 apporte 8 materiaux")
	assert_that(int(model.get("donor_points").get("alice",0)) == 8, "Donateurs comptabilises separement des constructeurs")
	assert_that(model.call("gift","alice","Galaxy",1), "Galaxy declenche livraison majeure")
	assert_that(float(model.get("protection_seconds")) > 0.0, "La digue anti-tempete est active")
	model.set("progress",100.0)
	model.set("strength",90.0)
	assert_that(model.call("receive","alice","!rescue"), "Evacuation possible si pont assez construit")
	assert_that(int(model.get("rescue_queue")) > 0, "Habitant ajoute a la file d'evacuation")
	for i in range(75):
		model.call("tick",0.1)
	assert_that(int(model.get("saved")) >= 1, "L'habitant traverse reellement le pont")
	model.set("saved",int(model.get("target")))
	model.call("tick",0.1)
	assert_that(str(model.get("status")) == "RESULT", "Fin automatique apres sauvetage")
	assert_that(int(model.get("star_rating")) == 3, "Trois etoiles si tous sauves")
	model.call("tick",0.1)
	assert_that(str(model.get("status")) == "RESULT", "Resultat maintenu a l'ecran")
	model.set("result_seconds",0.1)
	model.call("tick",0.1)
	assert_that(int(model.get("mission_index")) == 2, "Une nouvelle mission commence apres le resultat")
	assert_that(str(model.call("scenario_info").get("id")) == "dike", "Mission 2 utilise le scenario digue")
	model.set("saved", int(model.get("target")))
	model.call("tick",0.1)
	model.set("result_seconds",0.1)
	model.call("tick",0.1)
	assert_that(str(model.call("scenario_info").get("id")) == "lighthouse", "Mission 3 utilise le scenario phare")
	model.call("configure",true)
	assert_that(str(model.get("status")) == "RUNNING", "Mode DEMO clairement distinct et auto-actif")
	assert_that(model.get("participants").size() == 0, "Aucun faux spectateur genere en demonstration")
	for i in range(1250):
		if str(model.get("status")) == "RESULT":
			break
		model.call("tick",0.1)
	assert_that(int(model.get("weather_stage")) >= 1, "Une vague frappe le pont pendant la demonstration")
	assert_that(int(model.get("saved")) > 0, "La demonstration evacue des habitants")
	print("DEMO DIAGNOSTIC: status=%s saved=%d/%d progress=%.2f strength=%.2f remaining=%.2f" % [str(model.get("status")), int(model.get("saved")),int(model.get("target")),float(model.get("progress")),float(model.get("strength")),float(model.get("seconds"))])
	assert_that(str(model.get("status")) == "RESULT", "Demo atteint un resultat sans intervention")
	assert_that(model.get("participants").size() == 0, "Aucun spectateur invente pendant le cycle automatique")
	model.call("configure",false)
	for i in range(65):
		model.call("join","spectateur_%d" % i)
	assert_that(model.get("participants").size() == 65,"65 vrais participants pris en compte sans limite de trois ouvriers")
	assert_that(model.call("top_builders",3).is_empty(),"Aucun faux constructeur dans le classement")
	print("MISSION RULES TESTS: ", "SUCCESS" if fail_count == 0 else "FAILED " + str(fail_count))
	quit(0 if fail_count == 0 else 1)

# Les trois scenarios disposent d'objectifs propres et le joueur reste inscrit.
