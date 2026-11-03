extends RefCounted
## Quatre agents decisionnels locaux deterministes : sans cout d'API, sans invention
## de spectateurs et sans generer des messages dans le chat TikTok.
## Les messages sont des textes d'interface affiches par le jeu, pas des pubs.

const ADVICE_INTERVAL := 15.0
var clock := 0.0
var next_advice := 6.0
var last_stage := -1
var already_welcomed: Dictionary = {}
var milestones: Dictionary = {}
var gift_nudge_at := 75.0

func reset() -> void:
	clock = 0.0
	next_advice = 6.0
	last_stage = -1
	already_welcomed.clear()
	milestones.clear()
	gift_nudge_at = 75.0

func welcome(user: String, game: RefCounted) -> String:
	var name := user.strip_edges().trim_prefix("@").substr(0, 20)
	if name.is_empty() or already_welcomed.has(name):
		return ""
	already_welcomed[name] = true
	return "BIENVENUE @" + name + " ! ECRIS !build POUR CONSTRUIRE."

func reaction(event: Dictionary, game: RefCounted, is_live: bool) -> String:
	var kind := str(event.get("kind",""))
	var user := str(event.get("user","")).substr(0,20)
	match kind:
		"danger":
			return "AGENT SECURITE : STRUCTURE ENDOMMAGEE ! !repair"
		"gift":
			return "MERCI @" + user + " ! LES MATERIAUX ARRIVENT. !build RESTE GRATUIT."
		"power":
			return "AGENT MISSION : RENFORT DEPLOYE ! PROFITEZ-EN POUR AVANCER."
		"join":
			if is_live:
				return welcome(user,game)
		"success":
			if int(game.get("saved")) >= int(game.get("target")):
				return "AGENT MISSION : OBJECTIF ATTEINT ! BRAVO AUX SAUVETEURS."
		"build", "repair", "rescue":
			if is_live and user != "":
				var ranking: Dictionary = game.get("contribution")
				var score := int(ranking.get(user,0))
				if score >= 25 and not milestones.has(user):
					milestones[user] = true
					return "AGENT ACCUEIL : @" + user + " DEVIENT SAUVETEUR VEDETTE !"
	return ""

func tick(delta: float, game: RefCounted, is_live: bool) -> String:
	clock += minf(delta,0.2)
	var stage := int(game.get("weather_stage"))
	if stage != last_stage:
		last_stage = stage
		if stage > 0 and str(game.get("status")) == "RUNNING":
			return "AGENT SECURITE : VAGUE %d/3 ! RENFORCEZ LE SITE : !repair" % stage
	if clock < next_advice:
		return ""
	next_advice = clock + ADVICE_INTERVAL
	var status := str(game.get("status"))
	if status == "WAITING":
		return "AGENT ACCUEIL : REJOINS L'EQUIPE AVEC !join, C'EST GRATUIT."
	if status == "RESULT":
		return "AGENT MISSION : NOUVELLE MISSION APRES LE DECOMPTE."
	if status != "RUNNING":
		return ""
	var progress := float(game.get("progress"))
	var strength := float(game.get("strength"))
	var saved := int(game.get("saved"))
	var target := int(game.get("target"))
	if strength < 36.0:
		return "AGENT SECURITE : SOLIDITE CRITIQUE ! TAPE !repair."
	if progress < 99.9:
		return "AGENT CHANTIER : BESOIN D'OUVRIERS ! TAPE !build."
	if saved < target:
		return "AGENT SAUVETAGE : %d PERSONNES A SECOURIR ! TAPE !rescue." % (target-saved)
	if is_live and clock > gift_nudge_at:
		gift_nudge_at = clock + 90.0
		return "OPTIONNEL : UNE ROSE LIVRE DES MATERIAUX. !build RESTE GRATUIT."
	return "AGENT MISSION : GARDEZ LE SITE SOLIDE JUSQU'A LA FIN."
