extends RefCounted
## Mission Sauvetage LIVE : règles pures, indépendantes du rendu et de TikTok.
## Aucune identité simulée n'est présentée comme un vrai spectateur en mode LIVE.

const MAX_EVENTS := 8
const BASE_DURATION := 160.0
const DEMO_DURATION := 108.0
const MAX_MEMBERS := 200
const GIFT_RESOURCES := {"rose": 4, "gg": 4, "finger heart": 12, "doughnut": 40, "donut": 40, "galaxy": 120}
const POWER_COSTS := [15, 40, 90]
const BUILD_COOLDOWN := 2.0
const REPAIR_COOLDOWN := 2.0
const RESCUE_COOLDOWN := 2.6
const DISASTER_STAGES := [0.35, 0.68, 0.88]

var demo_mode := true
var mission_index := 1
var status := "WAITING"
var seconds := BASE_DURATION
var elapsed := 0.0
var progress := 12.0
var strength := 84.0
var wood := 30.0
var saved := 0
var target := 12
var rescue_queue := 0
var crossings: Array[Dictionary] = []
var participants: Dictionary = {}
var contribution: Dictionary = {}
var cooldowns: Dictionary = {}
var votes: Dictionary = {"1":0, "2":0, "3":0}
var weather_stage := 0
var total_duration := BASE_DURATION
var flood_level := 0.0
var last_rescuer := ""
var protection_seconds := 0.0
var supply_level := 0
var gifted_resources := 0
var star_rating := 0
var missions_cleared := 0
var result_seconds := 0.0
var event_id := 0
var events: Array[Dictionary] = []
var action_sequence := 0
var last_user := ""
var bridge_gates := 0
var demo_clock := 0.0
var next_disaster := 0
var reward_names := ["HELICOPTERE", "GRUE DE CHANTIER", "DIGUE D'URGENCE"]

func configure(is_demo: bool) -> void:
	demo_mode = is_demo
	mission_index = 1
	missions_cleared = 0
	participants.clear()
	contribution.clear()
	cooldowns.clear()
	_start_mission(true)

func _start_mission(reset_people: bool) -> void:
	if reset_people:
		participants.clear()
		contribution.clear()
		cooldowns.clear()
	status = "RUNNING" if demo_mode else "WAITING"
	total_duration = DEMO_DURATION if demo_mode else BASE_DURATION + 10.0 * float((mission_index - 1) % 3)
	seconds = total_duration
	elapsed = 0.0
	progress = 14.0
	strength = 86.0
	wood = 34.0
	saved = 0
	target = 12 + mini(6, (mission_index - 1) % 4 * 2)
	rescue_queue = 0
	crossings.clear()
	votes = {"1":0, "2":0, "3":0}
	weather_stage = 0
	flood_level = 0.0
	last_rescuer = ""
	next_disaster = 0
	protection_seconds = 0.0
	supply_level = 0
	gifted_resources = 0
	star_rating = 0
	result_seconds = 0.0
	action_sequence = 0
	demo_clock = 0.0
	bridge_gates = 0
	_note("MISSION %02d • CONSTRUISEZ LE PONT !" % mission_index, "info")

func _note(message: String, kind: String = "info", username: String = "") -> void:
	event_id += 1
	events.push_front({"id":event_id, "message":message.substr(0,120), "kind":kind, "user":username, "life":4.0})
	if events.size() > MAX_EVENTS:
		events.resize(MAX_EVENTS)

func join(user: String) -> bool:
	var name := user.strip_edges().trim_prefix("@").substr(0, 24)
	if name.is_empty():
		return false
	if participants.has(name):
		return true
	if participants.size() >= MAX_MEMBERS:
		return false
	participants[name] = true
	contribution[name] = int(contribution.get(name,0))
	last_user = name
	_note("@" + name + " REJOINT LES SAUVETEURS", "join", name)
	if status == "WAITING":
		status = "RUNNING"
		_note("MISSION LANCEE !", "success")
	return true

func _eligible(user: String, command: String, cool: float) -> bool:
	if status != "RUNNING":
		return false
	if not demo_mode and not participants.has(user):
		_note("@" + user.substr(0,16) + " : ECRIS !join D'ABORD", "hint", user)
		return false
	var key := user + "|" + command
	var now := elapsed
	if cooldowns.has(key) and now - float(cooldowns[key]) < cool:
		return false
	cooldowns[key] = now
	last_user = user
	action_sequence += 1
	return true

func _credit(user: String, amount: int) -> void:
	if not user.is_empty() and participants.has(user):
		contribution[user] = int(contribution.get(user,0)) + amount

func receive(user: String, command: String) -> bool:
	var cmd := command.strip_edges().to_lower()
	if cmd == "!join" or cmd == "!play":
		return join(user)
	if cmd == "!build":
		return build(user)
	if cmd == "!repair":
		return repair(user)
	if cmd == "!rescue":
		return rescue(user)
	if cmd in ["1","2","3","!vote 1","!vote 2","!vote 3"]:
		return vote(user, cmd.right(1))
	return false

func build(user: String) -> bool:
	if not _eligible(user,"build",BUILD_COOLDOWN):
		return false
	var gain := 2.5
	if wood >= 6.0:
		wood -= 6.0
		gain = 6.0
	progress = minf(100.0,progress+gain)
	_credit(user,int(gain))
	_note("@" + user + " CONSTRUIT +" + str(int(gain)) + "%", "build", user)
	return true

func repair(user: String) -> bool:
	if not _eligible(user,"repair",REPAIR_COOLDOWN):
		return false
	var gain := 3.0
	if wood >= 4.0:
		wood -= 4.0
		gain = 9.0
	strength = minf(100.0,strength+gain)
	_credit(user,int(gain))
	_note("@" + user + " REPARE LE PONT", "repair", user)
	return true

func rescue(user: String) -> bool:
	if not _eligible(user,"rescue",RESCUE_COOLDOWN):
		return false
	if progress < 78.0:
		_note("PONT INACHEVE • CONSTRUISSEZ D'ABORD !", "warning")
		return false
	if strength < 20.0:
		_note("PONT FRAGILE • IL FAUT REPARER !", "warning")
		return false
	if saved + rescue_queue + crossings.size() >= target:
		return false
	rescue_queue += 1
	_credit(user,7)
	_note("@" + user + " LANCE UN SAUVETAGE !", "rescue", user)
	return true

func vote(user: String, option: String) -> bool:
	if not _eligible(user,"vote",3.0):
		return false
	if not votes.has(option):
		return false
	votes[option] += 1
	_credit(user,2)
	_note("@" + user + " VOTE " + option, "vote", user)
	if int(votes[option]) >= 3:
		match option:
			"1":
				strength = minf(100.0,strength+14.0)
				_note("CHOIX COLLECTIF : PILIERS RENFORCES", "success")
			"2":
				progress = minf(100.0,progress+10.0)
				_note("CHOIX COLLECTIF : GRUE RAPIDE", "success")
			"3":
				rescue_queue += mini(2,maxi(0,target-saved-rescue_queue-crossings.size()))
				_note("CHOIX COLLECTIF : EVACUATION PRIORITAIRE", "success")
		votes[option] = 0
	return true

func gift(user: String, gift_name: String, count: int = 1) -> bool:
	if status == "WAITING" and not demo_mode:
		join(user)
	if status != "RUNNING":
		return false
	var key := gift_name.strip_edges().to_lower()
	if not GIFT_RESOURCES.has(key):
		return false
	var quantity := clampi(count,1,1000)
	var amount := mini(1500,quantity * int(GIFT_RESOURCES[key]))
	wood = minf(350.0,wood+float(amount))
	gifted_resources += amount
	supply_level += amount
	_credit(user,amount*2)
	_note("CADEAU @" + user.substr(0,16) + " • +" + str(amount) + " MATERIAUX", "gift", user)
	while supply_level >= POWER_COSTS[2]:
		supply_level -= POWER_COSTS[2]
		protection_seconds = maxf(protection_seconds,16.0)
		strength = minf(100.0,strength+20.0)
		_note("DIGUE D'URGENCE • TEMPETE BLOQUEE !", "power")
		bridge_gates += 1
	if supply_level >= POWER_COSTS[1]:
		supply_level -= POWER_COSTS[1]
		progress = minf(100.0,progress+16.0)
		_note("SUPER GRUE • CONSTRUCTION ACCELEREE !", "power")
	elif supply_level >= POWER_COSTS[0]:
		supply_level -= POWER_COSTS[0]
		wood = minf(350.0,wood+20.0)
		_note("HELICOPTERE • LIVRAISON DE BOIS !", "power")
	return true

func tick(delta: float) -> void:
	var d := clampf(delta,0.0,0.1)
	for item in events:
		item["life"] = maxf(0,float(item["life"])-d)
	if status == "RESULT":
		result_seconds -= d
		if result_seconds <= 0.0:
			mission_index += 1
			_start_mission(true)
		return
	if status != "RUNNING":
		return
	seconds = maxf(0.0,seconds-d)
	elapsed += d
	demo_clock += d
	protection_seconds = maxf(0.0,protection_seconds-d)
	wood = minf(350.0,wood+d*0.32)
	var duration := total_duration
	flood_level = clampf(elapsed/maxf(1.0,total_duration),0.0,1.0)
	if next_disaster < DISASTER_STAGES.size() and elapsed/duration >= DISASTER_STAGES[next_disaster]:
		var damage := 18.0+float(next_disaster)*9.0
		if protection_seconds > 0:
			damage *= 0.15
		strength = maxf(0.0,strength-damage)
		weather_stage = next_disaster+1
		next_disaster += 1
		_note("VAGUE %d/3 • PONT ENDOMMAGE ! REPARER !" % (next_disaster), "danger")
	if demo_mode:
		_tick_demo()
	if rescue_queue > 0 and crossings.size() < 4 and progress >= 78.0 and strength >= 20.0:
		rescue_queue -= 1
		crossings.append({"p":0.0,"speed":0.245+randf_range(-0.025,0.025),"lane":randi_range(0,2)})
	for crossing in crossings.duplicate():
		crossing["p"] = minf(1.0,float(crossing["p"])+d*float(crossing["speed"]))
		if float(crossing["p"]) >= 1.0:
			crossings.erase(crossing)
			saved += 1
			strength = maxf(0.0,strength-0.6)
			_note("1 HABITANT SAUVE ! " + str(saved) + "/" + str(target), "success")
	if saved >= target:
		_finish(true)
	elif strength <= 0.0 or seconds <= 0.0:
		_finish(false)

func _tick_demo() -> void:
	if demo_clock >= 0.96:
		demo_clock = 0.0
		var stage := action_sequence % 7
		if progress < 84.0:
			stage = 0
		elif strength < 48.0:
			stage = 1
		elif saved + rescue_queue + crossings.size() < target:
			stage = 2
		match stage:
			0, 3, 5:
				build("DEMO")
			1, 4:
				repair("DEMO")
			2, 6:
				rescue("DEMO")
		# Une demonstration est clairement marquee et ne simule pas de vrais spectateurs.

func _finish(success: bool) -> void:
	if status == "RESULT":
		return
	status = "RESULT"
	result_seconds = 12.0
	star_rating = 3 if saved >= target else (2 if saved >= int(ceil(target*0.75)) else (1 if saved > 0 else 0))
	if success:
		missions_cleared += 1
		_note("MISSION ACCOMPLIE • " + str(saved) + " HABITANTS SAUVES !", "success")
	else:
		_note("MISSION TERMINEE • " + str(saved) + "/" + str(target) + " SAUVES", "danger")

func ranking(limit: int = 3) -> Array[String]:
	var list: Array[String] = []
	var users: Array = contribution.keys()
	users.sort_custom(func(a, b): return int(contribution[a]) > int(contribution[b]))
	for i in range(mini(limit,users.size())):
		list.append("@" + str(users[i]).substr(0,14) + " " + str(contribution[users[i]]))
	return list
