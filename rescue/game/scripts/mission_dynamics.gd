extends RefCounted
## 15 mechanically-distinct hazards and cooperation goals.
## The challenge is FREE to finish: TikTok gifts are NOT required.
## Only the 15 authored profiles below are valid; identity is stable by mission ID.
const PROFILES := [
	{"id":"bridge-01","side_title":"BARRIERES ANTI-CRUE","focus_action":"build","side_goal":65,"risk_start":18,"risk_gain":0.073,"reward_title":"BOUEE DE SECURITE","reward":"shield","visual":"sirene","crisis_name":"EAU EN HAUSSE","phases":["CONSTRUIRE LE TABLIER","TENIR FACE A LA CRUE","EVACUER LES FAMILLES"],"crisis_penalty":3,"rescue_speed_multiplier":1},
	{"id":"bridge-02","side_title":"COULOIR MEDICAL","focus_action":"rescue","side_goal":58,"risk_start":20,"risk_gain":0.078,"reward_title":"EQUIPE MEDICALE","reward":"supplies","visual":"medical","crisis_name":"CONVOI BLOQUE","phases":["PREPARER LE CONVOI","OUVRIR LA ROUTE","EVACUER LES BLESSES"],"crisis_penalty":3,"rescue_speed_multiplier":1},
	{"id":"bridge-03","side_title":"CABLES DE MAINTIEN","focus_action":"repair","side_goal":75,"risk_start":30,"risk_gain":0.099,"reward_title":"HAUBANS RENFORCES","reward":"stabilize","visual":"cables","crisis_name":"HAUBANS SOUS TENSION","phases":["INSTALLER LES CABLES","REPARER LES ANCRAGES","SAUVER LE GROUPE"],"crisis_penalty":3,"rescue_speed_multiplier":1},
	{"id":"dike-04","side_title":"STATION DE POMPAGE","focus_action":"special","side_goal":62,"risk_start":20,"risk_gain":0.079,"reward_title":"POMPES RENFORCEES","reward":"shield","visual":"pumps","crisis_name":"DIGUE EN SURCHARGE","phases":["METTRE EN PLACE LA DIGUE","ACTIVER LES POMPES","EVACUER LE QUARTIER"],"crisis_penalty":4,"rescue_speed_multiplier":1},
	{"id":"dike-05","side_title":"CANAL DE DELESTAGE","focus_action":"repair","side_goal":78,"risk_start":28,"risk_gain":0.083,"reward_title":"DELESTAGE REUSSI","reward":"stabilize","visual":"channels","crisis_name":"INFILTRATIONS DETECTEES","phases":["CANALISER LA CRUE","COLMATER LES BRECHES","SECURISER LES TOITS"],"crisis_penalty":4,"rescue_speed_multiplier":1},
	{"id":"dike-06","side_title":"BARRIERES DU PORT","focus_action":"build","side_goal":88,"risk_start":37,"risk_gain":0.114,"reward_title":"BARRIERE ANTI-VAGUE","reward":"shield","visual":"wave","crisis_name":"VAGUE SUR LE PORT","phases":["DEGAGER LES QUAIS","DRESSER LES BARRIERES","SECURISER LES EQUIPES"],"crisis_penalty":4,"rescue_speed_multiplier":0.9},
	{"id":"lighthouse-07","side_title":"FEU DE GUIDAGE","focus_action":"special","side_goal":64,"risk_start":15,"risk_gain":0.068,"reward_title":"FAISCEAU RECALIBRE","reward":"rapid_build","visual":"beacon","crisis_name":"VISIBILITE REDUITE","phases":["REPARER LE PHARE","ALLUMER LE SIGNAL","GUIDER LES NAUFRAGES"],"crisis_penalty":5,"rescue_speed_multiplier":1},
	{"id":"lighthouse-08","side_title":"GENERATEUR DE SECOURS","focus_action":"repair","side_goal":72,"risk_start":25,"risk_gain":0.083,"reward_title":"ENERGIE RETABLIE","reward":"supplies","visual":"generator","crisis_name":"GENERATEUR EN PANNE","phases":["PREPARER LA RESERVE","REPARER LES CIRCUITS","GUIDER LES BATEAUX"],"crisis_penalty":5,"rescue_speed_multiplier":1},
	{"id":"lighthouse-09","side_title":"RADIO DES PECHEURS","focus_action":"rescue","side_goal":86,"risk_start":30,"risk_gain":0.098,"reward_title":"BALISE DE LOCALISATION","reward":"priority_rescue","visual":"radar","crisis_name":"COMMUNICATIONS BROUILLEES","phases":["RAPPELER LES EQUIPAGES","STABILISER LA BALISE","GUIDER LE RETOUR"],"crisis_penalty":5,"rescue_speed_multiplier":0.86},
	{"id":"dam-10","side_title":"VANNES DE DECHARGE","focus_action":"special","side_goal":69,"risk_start":25,"risk_gain":0.089,"reward_title":"DEBIT MAITRISE","reward":"shield","visual":"spillway","crisis_name":"PRESSION DU RESERVOIR","phases":["RENFORCER LE BARRAGE","REGULER LE DEBIT","EVACUER LA VALLEE"],"crisis_penalty":6,"rescue_speed_multiplier":1},
	{"id":"dam-11","side_title":"FONDATIONS ANTISISMIQUES","focus_action":"repair","side_goal":86,"risk_start":34,"risk_gain":0.11,"reward_title":"STABILISATION DU SOL","reward":"stabilize","visual":"fracture","crisis_name":"REPLIQUES EN COURS","phases":["SONDER LES FISSURES","REPARER LES FONDATIONS","SAUVER LES FAMILLES"],"crisis_penalty":6,"rescue_speed_multiplier":1},
	{"id":"dam-12","side_title":"VANNES DE SECOURS","focus_action":"special","side_goal":90,"risk_start":36,"risk_gain":0.117,"reward_title":"VANNES DEBLOQUEES","reward":"rapid_build","visual":"sluice","crisis_name":"MECANISME BLOQUE","phases":["DIAGNOSTIQUER LES VANNES","DEBLOQUER LES MECANISMES","SECURISER LA VALLEE"],"crisis_penalty":6,"rescue_speed_multiplier":1},
	{"id":"helipad-13","side_title":"COULOIR COUPE-FEU","focus_action":"build","side_goal":75,"risk_start":28,"risk_gain":0.101,"reward_title":"COUPE-FEU ACTIVE","reward":"shield","visual":"flames","crisis_name":"INCENDIE EN APPROCHE","phases":["OUVRIR LA PISTE","CREER UN COUPE-FEU","EVACUER PAR HELICOPTERE"],"crisis_penalty":7,"rescue_speed_multiplier":1},
	{"id":"helipad-14","side_title":"DEGIVRAGE DU ROTOR","focus_action":"repair","side_goal":78,"risk_start":35,"risk_gain":0.101,"reward_title":"ROTOR DEGIVRE","reward":"rapid_build","visual":"snow","crisis_name":"GIVRAGE DES ROTORS","phases":["BALISER LA ZONE","DEGIVRER LES APPAREILS","SAUVER LES ALPINISTES"],"crisis_penalty":7,"rescue_speed_multiplier":0.77},
	{"id":"helipad-15","side_title":"CENTRE DE COMMANDE","focus_action":"rescue","side_goal":100,"risk_start":50,"risk_gain":0.139,"reward_title":"EVACUATION COORDONNEE","reward":"priority_rescue","visual":"command","crisis_name":"CYCLONE SUR LA BASE","phases":["PREPARER LA BASE","ORGANISER LES VOLANTS","SAUVER LES DERNIERS REFUGIES"],"crisis_penalty":7,"rescue_speed_multiplier":1}
]

static func get_profile(mission_id: String) -> Dictionary:
	for profile in PROFILES:
		if str(profile["id"]) == mission_id:
			return profile.duplicate(true)
	return {}

static func validate(catalog: Array) -> bool:
	if PROFILES.size() != 15 or catalog.size() != PROFILES.size():
		return false
	var seen: Dictionary = {}
	var visuals: Dictionary = {}
	for i in range(PROFILES.size()):
		var profile: Dictionary = PROFILES[i]
		var mission: Dictionary = catalog[i]
		if str(profile["id"]) != str(mission["id"]) or seen.has(profile["id"]):
			return false
		seen[profile["id"]] = true
		visuals[profile["visual"]] = true
		if str(profile["focus_action"]) not in ["build","repair","rescue","special"]:
			return false
		if int(profile["side_goal"]) <= 0 or float(profile["risk_gain"]) <= 0.0:
			return false
		if (profile["phases"] as Array).size() != 3:
			return false
	return visuals.size() == 15
