extends SceneTree
## Jeu V0.4 : pas de bots, 3 manches pile, cadeaux et ames affectes a des joueurs.

var failures := 0

func check(condition: bool, title: String) -> void:
	if not condition:
		failures += 1
		push_error("MATCH TEST FAILED: " + title)
	else:
		print("MATCH TEST OK: " + title)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	var game: Node3D = scene.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	var director: Node3D = game.get("combat_director") as Node3D
	var fighters: Dictionary = director.get("units")
	check(not bool(game.get("match_started")), "Sans joueurs, le temps de match est suspendu")
	check(not bool(fighters["red"][0].get("deployed")), "Aucun personnage BOT visible")
	game.call("_join", "alice", "red")
	check(not bool(game.get("match_started")), "Un seul camp ne lance pas un combat")
	game.call("_join", "bob", "blue")
	check(bool(game.get("match_started")), "La presence des deux equipes lance la bataille")
	check(bool(fighters["red"][0].get("deployed")) and bool(fighters["blue"][0].get("deployed")), "Combattants reels deployes")
	check(not bool(fighters["red"][1].get("deployed")), "Pas de soldats automatiquement inventes")
	game.call("_gift", "alice", 35, "Doughnut")
	check(int(game.get("souls_earned")["red"]) == 35, "Doughnut : 35 ames creditees")
	check(int(game.get("souls_bank")["red"]) == 0, "35 ames automatiquement converties en bouclier")
	game.call("_gift", "carole", 150, "Galaxy")
	check(not game.get("players").has("carole"), "Cadeau sans equipe mis en attente, pas de camp arbitraire")
	check(int(game.get("souls_pending").get("carole", 0)) == 150, "Les ames d'un spectateur non inscrit sont conservees")
	game.call("_join", "carole", "blue")
	check(int(game.get("souls_bank")["blue"]) == 30, "Galaxy : pouvoir 120 ames, 30 ames restantes")
	for i in range(3):
		game.set("red_hp", 100.0)
		game.set("blue_hp", 0.0)
		game.call("_end_round")
		check(int(game.get("completed_rounds")) == i + 1, "Manche %d de 3 terminee" % [i + 1])
		if i < 2:
			game.call("_next_round")
	check(bool(game.get("match_finished")), "Le match s'arrete exactement a la troisieme manche")
	check(int(game.get("round_number")) == 3, "Aucune quatrieme manche dans le meme match")
	check(bool(game.get("result_panel").visible), "Ecran de victoire affiche")
	game.call("_next_round")
	check(int(game.get("round_number")) == 1 and not bool(game.get("match_finished")), "Nouveau match recommence en manche 1")
	check(int(game.get("wins_red")) == 0 and int(game.get("wins_blue")) == 0, "Resultats des manches reinitialises")
	print("MATCH TEST SUMMARY: failures=%d" % failures)
	quit(1 if failures > 0 else 0)
