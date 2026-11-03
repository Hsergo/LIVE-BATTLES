extends SceneTree
var fail := false
func check(ok: bool, label: String) -> void:
	if not ok:
		fail = true
		push_error("AGENTS TEST FAIL: " + label)
	else:
		print("AGENTS TEST OK: " + label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game: RefCounted = load("res://scripts/mission.gd").new()
	game.call("configure",false)
	var agents: RefCounted = load("res://scripts/agents.gd").new()
	var w: String = agents.call("welcome","alice",game)
	check(w.contains("alice"),"Bienvenue avec pseudo authentique")
	var second_welcome: String = str(agents.call("welcome","alice",game))
	check(second_welcome.is_empty(),"Une bienvenue par joueur")
	var guidance := ""
	for i in range(40):
		guidance = str(agents.call("tick",0.2,game,true))
		if not guidance.is_empty():
			break
	check(guidance.contains("!join"),"Invitation a rejoindre gratuitement")
	game.call("join","alice")
	game.set("strength",20.0)
	guidance = ""
	for i in range(100):
		guidance = str(agents.call("tick",0.2,game,true))
		if not guidance.is_empty():
			break
	check(guidance.contains("!repair"),"Agent de securite avertit en cas de danger")
	var gift: String = agents.call("reaction",{"kind":"gift","user":"alice"},game,true)
	check(gift.contains("!build") and gift.contains("GRATUIT"),"Remerciement cadeau non coercitif")
	check(str(agents.call("reaction",{"kind":"join","user":"alice"},game,true)).is_empty(),"Pas de double bienvenue")
	check(str(agents.call("reaction",{"kind":"join","user":"bot"},game,false)).is_empty(),"Pas de faux spectateur en demo")
	check(agents.get("milestones").size()==0,"Pas de pseudo invente par l'agent")
	print("AGENTS TEST RESULT: ", "FAILED" if fail else "SUCCESS")
	quit(1 if fail else 0)
