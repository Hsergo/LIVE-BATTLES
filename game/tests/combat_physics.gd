extends SceneTree
## Tests de recette physiques : IA en mouvement, collision de lame, parade, PV.
## Le test refuse de livrer une version dont les coups sont seulement cosmetiques.

var failed := false

func _assert_check(condition: bool, explanation: String) -> void:
	if not condition:
		failed = true
		push_error("COMBAT TEST FAILED: " + explanation)
	else:
		print("COMBAT TEST OK: " + explanation)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		push_error("Scene principale introuvable")
		quit(1)
		return
	var game: Node3D = scene.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	var director: Node3D = game.get("combat_director") as Node3D
	if director == null:
		push_error("Orchestrateur de combat introuvable")
		quit(1)
		return
	var teams: Dictionary = director.get("units")
	_assert_check(teams["red"].size() == 6 and teams["blue"].size() == 6, "Six unites physiques par equipe")
	await create_timer(6.0).timeout
	var real_hits := int(director.get("hit_count"))
	_assert_check(real_hits > 0, "Des attaques automatiques ont touche une hitbox")

	var isolated := Node3D.new()
	isolated.name = "ArenaCombatTest"
	root.add_child(isolated)
	var script = load("res://scripts/combat_unit.gd")
	var visual_red := Node3D.new()
	var visual_blue := Node3D.new()
	isolated.add_child(visual_red)
	isolated.add_child(visual_blue)
	var attacker: CharacterBody3D = script.new()
	var defender: CharacterBody3D = script.new()
	isolated.add_child(attacker)
	isolated.add_child(defender)
	attacker.call("initialize", "red", 0, visual_red, Vector3(-0.8, 0, -10), Vector3(5, 0, -10))
	defender.call("initialize", "blue", 0, visual_blue, Vector3(0.8, 0, -10), Vector3(-5, 0, -10))
	attacker.rotation.y = PI / 2.0
	defender.rotation.y = -PI / 2.0
	defender.call("raise_guard", 2.0)
	attacker.set("battle_paused", true)
	defender.set("battle_paused", true)
	var counters := {"blocked": 0, "landed": 0}
	attacker.connect("hit_parried", func(_a: Node3D, _v: Node3D): counters["blocked"] += 1)
	attacker.connect("hit_landed", func(_a: Node3D, _v: Node3D, _d: float): counters["landed"] += 1)
	for i in range(4):
		await physics_frame
	var before := float(defender.get("hp"))
	attacker.call("_detect_contacts")
	_assert_check(int(counters["blocked"]) == 1, "La parade bloque l'epee dans la zone de collision")
	_assert_check(is_equal_approx(float(defender.get("hp")), before), "Parade sans degats de vie")
	defender.set("guard_time", 0.0)
	attacker.set("hit_ids", {})
	for i in range(2):
		await physics_frame
	attacker.call("_detect_contacts")
	_assert_check(int(counters["landed"]) == 1, "Une collision sans parade declenche une touche")
	_assert_check(float(defender.get("hp")) < before, "Une touche physique retire des PV")
	print("COMBAT SUMMARY: auto_hits=%d, parades=%d, manual_hits=%d" % [real_hits, int(counters["blocked"]), int(counters["landed"])])
	quit(1 if failed else 0)
