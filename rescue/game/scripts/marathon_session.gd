extends RefCounted
## Session clock and playable support operations. Gifts never advance a challenge.
const CHALLENGES := [
	{"id":"convoy","title":"PREPARER LE CONVOI","stages":["CHARGER LES CAISSES","REPARER LE VEHICULE","GUIDER LE DEPART"],"actions":["build","repair","special"],"reward":"supplies"},
	{"id":"power","title":"RETABLIR LE COURANT","stages":["MONTER LES SUPPORTS","REPARER LE GENERATEUR","ACTIVER LE RESEAU"],"actions":["build","repair","special"],"reward":"protection"},
	{"id":"refuge","title":"SECURISER LE REFUGE","stages":["INSTALLER LES ABRIS","PREPARER LES SOINS","ACCUEILLIR LE CONVOI"],"actions":["build","repair","rescue"],"reward":"strength"}
]
var enabled := false
var duration := 7200.0
var elapsed := 0.0
var rounds := 0
var wins := 0
var total_saved := 0
var challenges_won := 0
var challenge_index := -1
var challenge_stage := 0
var challenge_progress := 0.0
var challenge_seconds := 0.0
var challenge_goal := 30.0
var pending_reward := ""
var pending_materials := 0.0

func configure(on: bool, seconds: float = 7200.0) -> void:
	enabled = on
	duration = clampf(seconds,600.0,10800.0)
	elapsed = 0.0
	rounds = 0
	wins = 0
	total_saved = 0
	challenges_won = 0
	challenge_index = -1
	challenge_stage = 0
	challenge_progress = 0.0
	challenge_seconds = 0.0
	challenge_goal = 30.0
	pending_reward = ""
	pending_materials = 0.0

func tick(delta: float) -> void:
	if enabled:
		elapsed += maxf(0.0,delta)

func record_result(success: bool, rescued: int) -> void:
	rounds += 1
	wins += 1 if success else 0
	total_saved += maxi(0,rescued)

func reached_duration() -> bool:
	return enabled and elapsed >= duration

func begin_challenge() -> void:
	challenge_index = (rounds-1) % CHALLENGES.size()
	challenge_stage = 0
	challenge_progress = 0.0
	challenge_seconds = 120.0
	# Bounded variations across cycles; no growing crowds or endless health bars.
	challenge_goal = 30.0 + float(mini(6,int(rounds/15))) * 2.0
	pending_reward = ""

func challenge_info() -> Dictionary:
	return CHALLENGES[challenge_index].duplicate(true) if challenge_index >= 0 else {}

func focus_action() -> String:
	if challenge_index < 0:
		return "build"
	return str(CHALLENGES[challenge_index]["actions"][mini(2,challenge_stage)])

func contribute(action: String, work: float) -> bool:
	if challenge_index < 0 or challenge_stage >= 3 or action not in ["build","repair","rescue","special","vote"]:
		return false
	var gain := work * (1.0 if action == focus_action() else 0.35)
	challenge_progress = minf(challenge_goal,challenge_progress+maxf(0.0,gain))
	if challenge_progress >= challenge_goal:
		challenge_stage += 1
		challenge_progress = 0.0
		if challenge_stage == 3:
			challenges_won += 1
			pending_reward = str(CHALLENGES[challenge_index]["reward"])
	return true

func challenge_fraction() -> float:
	return clampf((float(challenge_stage)+challenge_progress/maxf(1.0,challenge_goal))/3.0,0.0,1.0)

func snapshot() -> Dictionary:
	var out := {}
	for key in ["enabled","duration","elapsed","rounds","wins","total_saved","challenges_won","challenge_index","challenge_stage","challenge_progress","challenge_seconds","challenge_goal","pending_reward","pending_materials"]:
		out[key] = get(key)
	return out

func restore(data: Dictionary) -> bool:
	for key in snapshot():
		if not data.has(key):
			return false
	if typeof(data.get("enabled")) != TYPE_BOOL:
		return false
	var bounds := {"duration":[600,10800],"elapsed":[0,20000],"rounds":[0,10000],"wins":[0,10000],"total_saved":[0,240000],"challenges_won":[0,10000],"challenge_index":[-1,2],"challenge_stage":[0,3],"challenge_progress":[0,42],"challenge_seconds":[0,120],"challenge_goal":[30,42],"pending_materials":[0,150]}
	for key in bounds:
		var value = data.get(key)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
			return false
		if float(value) < float(bounds[key][0]) or float(value) > float(bounds[key][1]):
			return false
	for key in ["rounds","wins","total_saved","challenges_won","challenge_index","challenge_stage"]:
		if float(data[key]) != floor(float(data[key])):
			return false
	if str(data.get("pending_reward","")) not in ["","supplies","protection","strength"]:
		return false
	if int(data["wins"]) > int(data["rounds"]) or int(data["challenges_won"]) > int(data["rounds"]):
		return false
	if float(data["challenge_progress"]) > float(data["challenge_goal"]):
		return false
	for key in snapshot():
		set(key,data[key])
	return true
