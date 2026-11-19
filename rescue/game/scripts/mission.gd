extends RefCounted
## Mission Sauvetage LIVE : règles pures, indépendantes du rendu et de TikTok.
## Aucune identité simulée n'est présentée comme un vrai spectateur en mode LIVE.

const MAX_EVENTS := 8
const MAX_VISUAL_EVENTS := 256
const BASE_DURATION := 160.0
const DEMO_DURATION := 108.0
const MAX_MEMBERS := 500
const GIFT_RESOURCES := {"rose": 4, "gg": 4, "finger heart": 12, "doughnut": 40, "donut": 40, "galaxy": 120}
const POWER_COSTS := [15, 40, 90]
const BUILD_COOLDOWN := 2.0
const REPAIR_COOLDOWN := 2.0
const RESCUE_COOLDOWN := 2.6
const DISASTER_STAGES := [0.35, 0.68, 0.88]
const Catalog = preload("res://scripts/mission_catalog.gd")
const Dynamics = preload("res://scripts/mission_dynamics.gd")
const Pacing = preload("res://scripts/mission_pacing.gd")
const Marathon = preload("res://scripts/marathon_session.gd")
const SCENARIOS = Catalog.LEVELS
var pacing := Pacing.new()
var marathon := Marathon.new()
var pause_reasons: Dictionary = {}
var revision := 0
var saved_person_indices: Array[int] = []
var demo_mode := true
var hazard_pressure := 0.0
var last_special := ""
var mission_profile: Dictionary = {}
var secondary_label := ""
var secondary_goal := 80.0
var secondary_progress := 0.0
var secondary_complete := false
var secondary_milestone := 0
var mission_phase := 0
var mission_phase_label := ""
var crisis_level := 0.0
var crisis_cooldown := 0.0
var crisis_trigger_count := 0
var scenario_index := 0
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
var rescue_owners: Array[String] = []
# Optional scene-level arrival confirmation; source-only/headless model remains autonomous.
var arrival_gate: Callable = Callable()
var next_villager_index := 0
var crossings: Array[Dictionary] = []
var participants: Dictionary = {}
var contribution: Dictionary = {}
var builder_points: Dictionary = {}
var donor_points: Dictionary = {}
var rescuer_points: Dictionary = {}
var lifetime_contribution: Dictionary = {}
var cooldowns: Dictionary = {}
var votes: Dictionary = {"1":0, "2":0, "3":0}
var weather_stage := 0
var total_duration := BASE_DURATION
var flood_level := 0.0
var last_rescuer := ""
var last_rescued_person_index := -1
var protection_seconds := 0.0
var supply_level := 0
var gifted_resources := 0
var star_rating := 0
var missions_cleared := 0
var result_seconds := 0.0
var event_id := 0
var events: Array[Dictionary] = []
var visual_events: Array[Dictionary] = []
var action_sequence := 0
var last_user := ""
var bridge_gates := 0
var demo_clock := 0.0
var next_disaster := 0
var reward_names := ["HELICOPTERE", "GRUE DE CHANTIER", "DIGUE D'URGENCE"]

func configure(is_demo: bool) -> void:
	demo_mode = is_demo
	marathon.configure(false)
	pause_reasons.clear()
	mission_index = 1
	missions_cleared = 0
	participants.clear()
	contribution.clear()
	cooldowns.clear()
	_start_mission(true)

func configure_session(is_demo: bool, marathon_mode: bool, duration: float = 7200.0) -> void:
	configure(is_demo)
	marathon.configure(marathon_mode,duration)

func set_pause(reason: String, on: bool) -> void:
	if on:
		pause_reasons[reason] = true
	else:
		pause_reasons.erase(reason)

func is_paused() -> bool:
	return not pause_reasons.is_empty()

func _start_mission(reset_people: bool) -> void:
	revision += 1
	if reset_people:
		pacing.reset(demo_mode)
		participants.clear()
		contribution.clear()
		builder_points.clear()
		donor_points.clear()
		rescuer_points.clear()
		lifetime_contribution.clear()
	# Les spectateurs restent inscrits entre missions ; les delais de commande, non.
	cooldowns.clear()
	visual_events.clear()
	scenario_index = (mission_index - 1) % SCENARIOS.size()
	mission_profile = Dynamics.get_profile(str(SCENARIOS[scenario_index]["id"]))
	secondary_label = str(mission_profile.get("side_title","MISSION D'EQUIPE"))
	secondary_goal = float(mission_profile.get("side_goal",80))
	secondary_progress = 0.0
	secondary_complete = false
	secondary_milestone = 0
	mission_phase = 0
	mission_phase_label = str((mission_profile.get("phases",["PREPARATION"]) as Array)[0])
	crisis_level = float(mission_profile.get("risk_start",20.0))
	crisis_cooldown = 0.0
	crisis_trigger_count = 0
	status = "RUNNING" if demo_mode or not participants.is_empty() else "WAITING"
	total_duration = DEMO_DURATION if demo_mode else float(SCENARIOS[scenario_index]["duration"])
	seconds = total_duration
	elapsed = 0.0
	progress = 14.0
	strength = 86.0
	wood = 34.0
	saved = 0
	saved_person_indices.clear()
	target = int(SCENARIOS[scenario_index]["target"])
	rescue_queue = 0
	rescue_owners.clear()
	next_villager_index = 0
	crossings.clear()
	votes = {"1":0, "2":0, "3":0}
	weather_stage = 0
	flood_level = 0.0
	hazard_pressure = 0.0
	last_special = ""
	last_rescuer = ""
	last_rescued_person_index = -1
	next_disaster = 0
	protection_seconds = 0.0
	supply_level = 0
	gifted_resources = 0
	star_rating = 0
	result_seconds = 0.0
	action_sequence = 0
	demo_clock = 0.0
	bridge_gates = 0
	_note("MISSION %02d • %s !" % [mission_index, str(SCENARIOS[scenario_index]["title"])], "info")

func _note(message: String, kind: String = "info", username: String = "") -> void:
	event_id += 1
	var event := {"id":event_id, "message":message.substr(0,120), "kind":kind, "user":username, "life":4.0}
	events.push_front(event)
	visual_events.append(event.duplicate())
	if events.size() > MAX_EVENTS:
		events.resize(MAX_EVENTS)
	while visual_events.size() > MAX_VISUAL_EVENTS:
		visual_events.pop_front()

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
	builder_points[name] = int(builder_points.get(name,0))
	donor_points[name] = int(donor_points.get(name,0))
	rescuer_points[name] = int(rescuer_points.get(name,0))
	last_user = name
	_note("@" + name + " REJOINT LES SAUVETEURS", "join", name)
	if status == "WAITING":
		status = "RUNNING"
		_note("MISSION LANCEE !", "success")
	return true

func _eligible(user: String, command: String, cool: float) -> bool:
	if status not in ["RUNNING","CHALLENGE"] or is_paused():
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
	if participants.has(user):
		pacing.record_action(user)
	return true

func _credit(user: String, amount: int) -> void:
	if not user.is_empty() and participants.has(user):
		contribution[user] = int(contribution.get(user,0)) + amount
		lifetime_contribution[user] = int(lifetime_contribution.get(user,0)) + amount

func receive(user: String, command: String) -> bool:
	var cmd := command.strip_edges().to_lower()
	if cmd == str(SCENARIOS[scenario_index]["special"]):
		cmd = "!special"
	if cmd in ["!regles","!aide"]:
		cmd = "!rules"
	if cmd == "!join" or cmd == "!play":
		return join(user)
	if cmd == "!build":
		return build(user)
	if cmd == "!repair":
		return repair(user)
	if cmd == "!rescue":
		return rescue(user)
	if cmd == "!special":
		return special(user)
	if cmd == "!rules":
		_note("REGLES: !build, !repair, !rescue, " + str(SCENARIOS[scenario_index]["special"]) + " | CADEAUX FACULTATIFS", "hint", user)
		return true
	if cmd in ["1","2","3","!vote 1","!vote 2","!vote 3"]:
		return vote(user, cmd.right(1))
	return false

func _advance_secondary(action: String, user: String) -> void:
	if status != "RUNNING" or secondary_complete or mission_profile.is_empty():
		return
	var base := 3.0
	match action:
		"build":
			base = 5.0
		"repair":
			base = 6.0
		"rescue":
			base = 7.0
		"special":
			base = 13.0
		"vote":
			base = 4.0
	var focused := action == str(mission_profile.get("focus_action",""))
	var gain := pacing.work_gain(base * (2.4 if focused else 0.65))
	secondary_progress = minf(secondary_goal,secondary_progress+gain)
	crisis_level = maxf(0.0,crisis_level-gain*0.12)
	if secondary_progress >= secondary_goal:
		secondary_complete = true
		_award_secondary_reward(user)
	elif secondary_progress >= secondary_goal*0.5 and secondary_milestone == 0:
		secondary_milestone = 1
		_note(secondary_label + " • EQUIPE A MI-PARCOURS", "info")

func _award_secondary_reward(user: String) -> void:
	match str(mission_profile.get("reward","shield")):
		"shield":
			protection_seconds = maxf(protection_seconds,24.0)
		"stabilize":
			strength = minf(100.0,strength+22.0)
		"supplies":
			wood = minf(350.0,wood+48.0)
		"rapid_build":
			progress = minf(100.0,progress+pacing.work_gain(18.0))
		"priority_rescue":
			if progress >= 99.9 and strength >= 20.0:
				_enqueue_rescue(user,2)
			else:
				wood = minf(350.0,wood+35.0)
	crisis_level = maxf(0.0,crisis_level-28.0)
	_note(str(mission_profile.get("reward_title","BONUS COLLECTIF")) + " • BONUS GRATUIT ACTIVE !", "success")

func _apply_crisis_incident() -> void:
	var hazard := str(SCENARIOS[scenario_index].get("hazard_kind","crue"))
	var penalty := float(mission_profile.get("crisis_penalty",4)) * pacing.pressure_scale
	if protection_seconds > 0.0:
		penalty *= 0.25
	match hazard:
		"crue":
			flood_level = minf(1.0,flood_level+0.15)
			strength = maxf(0.0,strength-penalty)
		"glissement":
			progress = maxf(0.0,progress-penalty*1.8)
		"vent":
			strength = maxf(0.0,strength-penalty*1.7)
		"inondation":
			flood_level = minf(1.0,flood_level+0.18)
			strength = maxf(0.0,strength-penalty*0.85)
		"tsunami":
			flood_level = minf(1.0,flood_level+0.25)
			strength = maxf(0.0,strength-penalty*2.0)
		"brouillard":
			strength = maxf(0.0,strength-penalty*0.7)
		"blackout":
			progress = maxf(0.0,progress-penalty*1.5)
		"ouragan":
			strength = maxf(0.0,strength-penalty*1.8)
		"pression":
			hazard_pressure = minf(1.0,hazard_pressure+0.18)
			strength = maxf(0.0,strength-penalty*1.25)
		"seisme":
			progress = maxf(0.0,progress-penalty*1.5)
			strength = maxf(0.0,strength-penalty*0.8)
		"panne":
			wood = maxf(0.0,wood-penalty*4.0)
			progress = maxf(0.0,progress-penalty*0.7)
		"incendie":
			wood = maxf(0.0,wood-penalty*4.5)
			strength = maxf(0.0,strength-penalty)
		"blizzard":
			progress = maxf(0.0,progress-penalty)
			wood = maxf(0.0,wood-penalty*2.0)
		"cyclone":
			strength = maxf(0.0,strength-penalty*2.0)
			progress = maxf(0.0,progress-penalty)
	crisis_trigger_count += 1
	_note(str(mission_profile.get("crisis_name","NOUVEL INCIDENT")) + " • REPONSE COLLECTIVE !", "danger")

func _tick_mission_director(delta: float) -> void:
	if mission_profile.is_empty():
		return
	var ratio := elapsed/maxf(1.0,total_duration)
	var ready_to_depart := rescue_queue > 0 and progress >= 99.9 and strength >= 20.0
	var evacuation_started := saved > 0 or ready_to_depart or not crossings.is_empty()
	var next_phase := Pacing.phase_for(mission_phase, ratio, progress, evacuation_started)
	while mission_phase < next_phase:
		mission_phase += 1
		mission_phase_label = str((mission_profile.get("phases",[]) as Array)[mission_phase])
		_note("ACTE %d/3 : %s" % [mission_phase+1,mission_phase_label], "info")
	crisis_cooldown = maxf(0.0,crisis_cooldown-delta)
	var gain := delta*float(mission_profile.get("risk_gain",0.08))*pacing.pressure_scale
	if secondary_complete:
		gain *= 0.55
	if mission_phase == 2:
		gain *= 1.35
	crisis_level = clampf(crisis_level+gain,0.0,100.0)
	if crisis_level >= 68.0 and crisis_cooldown <= 0.0:
		_apply_crisis_incident()
		crisis_level = 28.0
		crisis_cooldown = 28.0

func build(user: String) -> bool:
	if status == "CHALLENGE":
		return _challenge_action(user,"build")
	if progress >= 99.9:
		_note("CHANTIER TERMINE • UTILISE !rescue", "hint", user)
		return false
	if not _eligible(user,"build",BUILD_COOLDOWN):
		return false
	var gain := 2.5
	if wood >= 6.0:
		wood -= 6.0
		gain = 6.0
	var applied := minf(100.0-progress,pacing.work_gain(gain))
	progress += applied
	_credit(user,int(gain))
	if participants.has(user):
		builder_points[user] = int(builder_points.get(user,0)) + int(gain)
	_advance_secondary("build",user)
	_note("@" + user + " CONSTRUIT +%.2f%%" % applied, "build", user)
	return true

func repair(user: String) -> bool:
	if status == "CHALLENGE":
		return _challenge_action(user,"repair")
	if strength >= 99.99:
		_note("STRUCTURE DEJA REPAREE • !rescue", "hint", user)
		return false
	if not _eligible(user,"repair",REPAIR_COOLDOWN):
		return false
	var gain := 3.0
	if wood >= 4.0:
		wood -= 4.0
		gain = 9.0
	strength = minf(100.0,strength+pacing.work_gain(gain))
	_credit(user,int(gain))
	if participants.has(user):
		builder_points[user] = int(builder_points.get(user,0)) + int(gain)
	_advance_secondary("repair",user)
	_note("@" + user + " REPARE " + str(SCENARIOS[scenario_index]["site"]), "repair", user)
	return true

func rescue(user: String) -> bool:
	if status == "CHALLENGE":
		return _challenge_action(user,"rescue")
	if progress < 99.9:
		_note(str(SCENARIOS[scenario_index]["site"]) + " INACHEVE • !build", "warning")
		return false
	if strength < 20.0:
		_note(str(SCENARIOS[scenario_index]["site"]) + " FRAGILE • !repair", "warning")
		return false
	if saved + rescue_queue + crossings.size() >= target:
		return false
	if not _eligible(user,"rescue",RESCUE_COOLDOWN):
		return false
	_enqueue_rescue(user,1)
	_credit(user,7)
	if participants.has(user):
		rescuer_points[user] = int(rescuer_points.get(user,0)) + 7
	_advance_secondary("rescue",user)
	_note("@" + user + " LANCE UN SAUVETAGE !", "rescue", user)
	return true

func _enqueue_rescue(user: String, count: int) -> void:
	var remaining := maxi(0,target-saved-rescue_queue-crossings.size())
	var accepted := mini(maxi(0,count),remaining)
	for n in range(accepted):
		rescue_owners.append(user)
	rescue_queue += accepted

func special(user: String) -> bool:
	if status == "CHALLENGE":
		return _challenge_action(user,"special")
	# Each type has its own free cooperative emergency action; gifts provide
	# optional spectacular reinforcements but are not needed for completion.
	if not _eligible(user,"special",7.0):
		return false
	var name := str(SCENARIOS[scenario_index]["site_type"])
	var gain := 0.0
	match name:
		"bridge":
			if progress < 99.9:
				gain = 5.0
				progress = minf(100.0,progress+pacing.work_gain(gain))
			elif saved + rescue_queue + crossings.size() < target:
				_enqueue_rescue(user,1)
			strength = minf(100.0,strength+pacing.work_gain(4.0))
		"dike":
			strength = minf(100.0,strength+pacing.work_gain(10.0))
			hazard_pressure = maxf(0.0,hazard_pressure-pacing.work_gain(0.18))
			protection_seconds = maxf(protection_seconds,5.0)
		"lighthouse":
			if progress < 99.9:
				progress = minf(100.0,progress+pacing.work_gain(5.0))
			elif saved + rescue_queue + crossings.size() < target:
				_enqueue_rescue(user,1)
			protection_seconds = maxf(protection_seconds,7.0)
		"dam":
			strength = minf(100.0,strength+pacing.work_gain(12.0))
			hazard_pressure = maxf(0.0,hazard_pressure-pacing.work_gain(0.27))
		"helipad":
			if progress < 99.9:
				progress = minf(100.0,progress+pacing.work_gain(5.0))
			else:
				_enqueue_rescue(user,2)
			protection_seconds = maxf(protection_seconds,4.0)
	_credit(user,8)
	if participants.has(user):
		builder_points[user] = int(builder_points.get(user,0)) + 8
	last_special = user
	_advance_secondary("special",user)
	_note("@" + user + " ACTIVE " + str(SCENARIOS[scenario_index]["special_label"]), "power", user)
	return true

func vote(user: String, option: String) -> bool:
	if not votes.has(option):
		return false
	if status == "CHALLENGE":
		return _challenge_action(user,"vote")
	if not _eligible(user,"vote",3.0):
		return false
	votes[option] += 1
	_credit(user,2)
	_note("@" + user + " VOTE " + option, "vote", user)
	if int(votes[option]) >= 3:
		_advance_secondary("vote",user)
		match option:
			"1":
				strength = minf(100.0,strength+pacing.work_gain(14.0))
				_note("CHOIX COLLECTIF : PILIERS RENFORCES", "success")
			"2":
				progress = minf(100.0,progress+pacing.work_gain(10.0))
				_note("CHOIX COLLECTIF : GRUE RAPIDE", "success")
			"3":
				_enqueue_rescue(user,2)
				_note("CHOIX COLLECTIF : EVACUATION PRIORITAIRE", "success")
		votes[option] = 0
	return true

func gift(user: String, gift_name: String, count: int = 1) -> bool:
	var key := gift_name.strip_edges().to_lower()
	if not GIFT_RESOURCES.has(key):
		return false
	if status == "WAITING" and not demo_mode:
		join(user)
	if status not in ["RUNNING","CHALLENGE"] or is_paused():
		return false
	if not participants.has(user):
		join(user)
	var quantity := clampi(count,1,1000)
	var amount := mini(1500,quantity * int(GIFT_RESOURCES[key]))
	wood = minf(350.0,wood+float(amount))
	gifted_resources += amount
	supply_level += amount
	_credit(user,amount*2)
	if participants.has(user):
		donor_points[user] = int(donor_points.get(user,0)) + amount
	_note("CADEAU @" + user.substr(0,16) + " • +" + str(amount) + " MATERIAUX", "gift", user)
	if status == "CHALLENGE":
		marathon.pending_materials = minf(150.0,marathon.pending_materials+float(amount))
		return true
	while supply_level >= POWER_COSTS[2]:
		supply_level -= POWER_COSTS[2]
		protection_seconds = maxf(protection_seconds,16.0)
		strength = minf(100.0,strength+20.0)
		_note("DIGUE D'URGENCE • TEMPETE BLOQUEE !", "power")
		bridge_gates += 1
	if supply_level >= POWER_COSTS[1]:
		supply_level -= POWER_COSTS[1]
		progress = minf(100.0,progress+pacing.work_gain(16.0))
		_note("SUPER GRUE • CONSTRUCTION ACCELEREE !", "power")
	elif supply_level >= POWER_COSTS[0]:
		supply_level -= POWER_COSTS[0]
		wood = minf(350.0,wood+20.0)
		_note("HELICOPTERE • LIVRAISON DE BOIS !", "power")
	return true

func tick(delta: float) -> void:
	var d := clampf(delta,0.0,0.1)
	if is_paused():
		return
	pacing.tick(d)
	for item in events:
		item["life"] = maxf(0,float(item["life"])-d)
	if status in ["RUNNING","RESULT","CHALLENGE"]:
		marathon.tick(d)
	if status == "CHALLENGE":
		elapsed += d
		marathon.challenge_seconds = maxf(0.0,marathon.challenge_seconds-d)
		if demo_mode:
			demo_clock += d
			if demo_clock >= 2.6:
				demo_clock = 0.0
				_challenge_action("DEMO",marathon.focus_action())
		if marathon.challenge_stage >= 3 or marathon.challenge_seconds <= 0.0:
			_complete_challenge()
		return
	if status == "RESULT":
		result_seconds = maxf(0.0,result_seconds-d)
		if result_seconds <= 0.0:
			if marathon.reached_duration():
				_complete_session()
			elif marathon.enabled:
				marathon.begin_challenge()
				status = "CHALLENGE"
				cooldowns.clear()
				demo_clock = 0.0
				_note(str(marathon.challenge_info()["title"])+" • BONUS GRATUIT", "info")
			else:
				mission_index += 1
				_start_mission(false)
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
	var stage_limits := [0.15, 0.32, 0.48] if demo_mode else DISASTER_STAGES
	hazard_pressure = clampf(hazard_pressure + d * 0.0005 * float(SCENARIOS[scenario_index]["hazard"]),0.0,1.0)
	flood_level = clampf(flood_level + hazard_pressure * 0.06,0.0,1.0)
	if next_disaster < stage_limits.size() and elapsed/duration >= stage_limits[next_disaster]:
		var damage := (18.0+float(next_disaster)*9.0) * float(SCENARIOS[scenario_index]["hazard"])
		damage *= pacing.pressure_scale
		damage *= (1.0 + hazard_pressure * 0.55)
		match str(SCENARIOS[scenario_index]["hazard_kind"]):
			"seisme","glissement":
				progress = maxf(0.0,progress-5.0-float(next_disaster))
			"incendie","blizzard","blackout","panne":
				wood = maxf(0.0,wood-11.0-float(next_disaster)*5.0)
			"tsunami","cyclone","ouragan":
				damage *= 1.23
		if protection_seconds > 0:
			damage *= 0.15
		strength = maxf(0.0,strength-damage)
		weather_stage = next_disaster+1
		next_disaster += 1
		crisis_level = minf(100.0,crisis_level+9.0+float(next_disaster)*4.0)
		_note("ALERTE %d/3 • %s !" % [next_disaster, str(SCENARIOS[scenario_index]["event_text"])], "danger")
	_tick_mission_director(d)
	if demo_mode:
		_tick_demo()
	var max_simultaneous := 1 if str(SCENARIOS[scenario_index]["site_type"])=="helipad" else 3
	if rescue_queue > 0 and crossings.size() < max_simultaneous and progress >= 99.9 and strength >= 20.0:
		rescue_queue -= 1
		var owner: String = str(rescue_owners.pop_front()) if not rescue_owners.is_empty() else ""
		var free_lane := 0
		for candidate in range(3):
			var occupied := false
			for entry in crossings:
				if int(entry.get("lane",-1)) == candidate:
					occupied = true
					break
			if not occupied:
				free_lane = candidate
				break
		crossings.append({"p":0.0,"speed":0.12+randf_range(-0.006,0.006),
			"lane":free_lane,"person_index":next_villager_index,
			"rescuer":owner})
		next_villager_index += 1
	for crossing in crossings.duplicate():
		# A destroyed or severely damaged construction temporarily stops evacuation
		# until real players repair it. Civilian positions remain stable meanwhile.
		var safe_crossing := progress >= 99.9 and strength >= 20.0
		if safe_crossing:
			var rescue_factor := float(mission_profile.get("rescue_speed_multiplier",1.0))
			if secondary_complete:
				rescue_factor = maxf(1.0,rescue_factor)
			crossing["p"] = minf(1.0,float(crossing["p"])+d*float(crossing["speed"])*rescue_factor)
		if float(crossing["p"]) >= 1.0 and (arrival_gate.is_null() or bool(arrival_gate.call(int(crossing.get("person_index",-1))))):
			crossings.erase(crossing)
			saved += 1
			saved_person_indices.append(int(crossing.get("person_index",-1)))
			last_rescued_person_index = int(crossing.get("person_index",-1))
			strength = maxf(0.0,strength-0.6)
			var rescuer := str(crossing.get("rescuer",""))
			if participants.has(rescuer):
				rescuer_points[rescuer] = int(rescuer_points.get(rescuer,0)) + 12
				_credit(rescuer,12)
			var outcome := "1 NAVIRE GUIDE" if str(SCENARIOS[scenario_index]["site_type"]) == "lighthouse" else "1 VILLAGEOIS SAUVE"
			if not rescuer.is_empty() and participants.has(rescuer):
				outcome = "@" + rescuer.substr(0,18) + " • " + outcome
			_note(outcome + " " + str(saved) + "/" + str(target), "success", rescuer)
	if saved >= target:
		_finish(true)
	elif strength <= 0.0 or seconds <= 0.0:
		_finish(false)

func _tick_demo() -> void:
	var interval := 1.15 if progress < 99.9 else 2.8
	if strength < 46.0:
		interval = 1.15
	if demo_clock < interval:
		return
	demo_clock = 0.0
	if progress < 99.9:
		build("DEMO")
	elif strength < 46.0:
		repair("DEMO")
	elif saved + rescue_queue + crossings.size() < target:
		rescue("DEMO")
	else:
		# Attente constructive des derniers traversants.
		if strength < 84.0:
			repair("DEMO")

func _finish(success: bool) -> void:
	if status == "RESULT":
		return
	status = "RESULT"
	marathon.record_result(success,saved)
	result_seconds = 12.0
	star_rating = 3 if saved >= target else (2 if saved >= int(ceil(target*0.75)) else (1 if saved > 0 else 0))
	if success:
		missions_cleared += 1
		_note("MISSION ACCOMPLIE • " + str(saved) + " HABITANTS SAUVES !", "success")
	else:
		_note("MISSION TERMINEE • " + str(saved) + "/" + str(target) + " SAUVES", "danger")

func _challenge_action(user: String, action: String) -> bool:
	if marathon.challenge_stage>=3 or marathon.challenge_seconds<=0.0:
		return false
	if not _eligible(user,"support_"+action,2.0):
		return false
	var before := marathon.challenge_stage
	if not marathon.contribute(action,pacing.work_gain(7.0)):
		return false
	_credit(user,5)
	if participants.has(user):
		builder_points[user] = int(builder_points.get(user,0))+5
	_note("@"+user+" • OPERATION DE SOUTIEN", "power" if action == "special" else action,user)
	if before != marathon.challenge_stage:
		_note("ETAPE %d/3 TERMINEE" % marathon.challenge_stage,"success")
	return true

func _complete_challenge() -> void:
	if marathon.reached_duration():
		_complete_session()
		return
	var reward := marathon.pending_reward
	var materials := marathon.pending_materials
	mission_index += 1
	_start_mission(false)
	wood = minf(350.0,wood+materials)
	match reward:
		"supplies": wood += 30.0
		"protection": protection_seconds = 25.0
		"strength": strength = 100.0
	marathon.pending_reward = ""
	marathon.pending_materials = 0.0
	if not reward.is_empty():
		_note("OPERATION REUSSIE • RENFORT GRATUIT POUR CETTE MISSION","success")

func _complete_session() -> void:
	status = "SESSION_COMPLETE"
	_note("MARATHON TERMINE • %d SAUVES • %d MISSIONS" % [marathon.total_saved,marathon.rounds],"success")

func ranking(limit: int = 3) -> Array[String]:
	var list: Array[String] = []
	var users: Array = contribution.keys()
	users.sort_custom(func(a, b): return int(contribution[a]) > int(contribution[b]))
	for i in range(mini(limit,users.size())):
		list.append("@" + str(users[i]).substr(0,14) + " " + str(contribution[users[i]]))
	return list

func scenario_info() -> Dictionary:
	return SCENARIOS[scenario_index].duplicate()

func active_players() -> int:
	return pacing.active_count

const SAVE_NUMBERS := {
	"seconds":[0,600],"elapsed":[0,1000],"progress":[0,100],"strength":[0,100],"wood":[0,350],
	"saved":[0,24],"rescue_queue":[0,24],"next_villager_index":[0,24],"weather_stage":[0,3],
	"flood_level":[0,1],"hazard_pressure":[0,1],"protection_seconds":[0,60],"supply_level":[0,1500],
	"gifted_resources":[0,1000000000],"star_rating":[0,3],"missions_cleared":[0,10000],
	"result_seconds":[0,12],"event_id":[0,1000000000],"action_sequence":[0,1000000000],
	"secondary_progress":[0,100],"secondary_milestone":[0,1],"mission_phase":[0,2],
	"crisis_level":[0,100],"crisis_cooldown":[0,28],"crisis_trigger_count":[0,10000],
	"next_disaster":[0,3],"bridge_gates":[0,1000000000],"demo_clock":[0,500],
	"last_rescued_person_index":[-1,23]
}
const SAVE_SCORES := ["contribution","builder_points","donor_points","rescuer_points","lifetime_contribution"]

func snapshot() -> Dictionary:
	var numbers := {}
	for key in SAVE_NUMBERS:
		numbers[key] = get(key)
	var scores := {}
	for key in SAVE_SCORES:
		scores[key] = (get(key) as Dictionary).duplicate()
	return {"version":1,"demo_mode":demo_mode,"mission_index":mission_index,"status":status,
		"numbers":numbers,"scores":scores,"participants":participants.keys(),
		"crossings":crossings.duplicate(true),"rescue_owners":rescue_owners.duplicate(),
		"saved_ids":saved_person_indices.duplicate(),"secondary_complete":secondary_complete,
		"votes":votes.duplicate(),"marathon":marathon.snapshot(),
		"manual_pause":pause_reasons.has("manual")}

func restore(data: Dictionary) -> bool:
	# Validate the complete snapshot before mutating the running game.
	if int(data.get("version",0)) != 1 or typeof(data.get("demo_mode")) != TYPE_BOOL:
		return false
	if not _bounded_number(data.get("mission_index"),1,10000,true):
		return false
	if str(data.get("status","")) not in ["WAITING","RUNNING","RESULT","CHALLENGE","SESSION_COMPLETE"]:
		return false
	if typeof(data.get("numbers")) != TYPE_DICTIONARY or typeof(data.get("scores")) != TYPE_DICTIONARY:
		return false
	var numbers: Dictionary = data["numbers"]
	for key in SAVE_NUMBERS:
		if not _bounded_number(numbers.get(key),float(SAVE_NUMBERS[key][0]),float(SAVE_NUMBERS[key][1]),typeof(get(key))==TYPE_INT):
			return false
	if typeof(data.get("participants")) != TYPE_ARRAY or data["participants"].size() > MAX_MEMBERS:
		return false
	var people := {}
	for person in data["participants"]:
		if typeof(person) != TYPE_STRING or str(person).is_empty() or str(person).length()>24 or people.has(person):
			return false
		people[person] = true
	for key in SAVE_SCORES:
		var scores = data["scores"].get(key)
		if typeof(scores) != TYPE_DICTIONARY or scores.size() > MAX_MEMBERS:
			return false
		for person in scores:
			if not people.has(person) or not _bounded_number(scores[person],0,2000000000,true):
				return false
	if typeof(data.get("crossings")) != TYPE_ARRAY or typeof(data.get("saved_ids")) != TYPE_ARRAY or typeof(data.get("rescue_owners")) != TYPE_ARRAY:
		return false
	var info: Dictionary = SCENARIOS[(int(data["mission_index"])-1)%SCENARIOS.size()]
	var limit := int(info["target"])
	var moving: Array = data["crossings"]
	var ids := {}
	if moving.size() > (1 if str(info["site_type"])=="helipad" else 3):
		return false
	if data["saved_ids"].size() != int(numbers["saved"]) or data["rescue_owners"].size() != int(numbers["rescue_queue"]):
		return false
	for person in data["saved_ids"]:
		if not _bounded_number(person,0,limit-1,true) or ids.has(int(person)):
			return false
		ids[int(person)] = true
	var lanes := {}
	for entry in moving:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		if not _bounded_number(entry.get("person_index"),0,limit-1,true) or ids.has(int(entry["person_index"])):
			return false
		if not _bounded_number(entry.get("p"),0,1) or not _bounded_number(entry.get("speed"),0.05,1):
			return false
		if not _bounded_number(entry.get("lane"),0,2,true) or lanes.has(int(entry["lane"])):
			return false
		if not _saved_owner_valid(entry.get("rescuer"),people,bool(data["demo_mode"])):
			return false
		ids[int(entry["person_index"])] = true
		lanes[int(entry["lane"])] = true
	for owner in data["rescue_owners"]:
		if not _saved_owner_valid(owner,people,bool(data["demo_mode"])):
			return false
	if ids.size() != int(numbers["next_villager_index"]) or ids.size()+int(numbers["rescue_queue"])>limit:
		return false
	for person in ids:
		if int(person)>=int(numbers["next_villager_index"]):
			return false
	if typeof(data.get("votes")) != TYPE_DICTIONARY or data["votes"].size()!=3:
		return false
	for key in ["1","2","3"]:
		if not _bounded_number(data["votes"].get(key),0,2,true):
			return false
	if typeof(data.get("secondary_complete"))!=TYPE_BOOL or typeof(data.get("manual_pause"))!=TYPE_BOOL or typeof(data.get("marathon"))!=TYPE_DICTIONARY:
		return false
	var restored_session := Marathon.new()
	if not restored_session.restore(data["marathon"]):
		return false
	if str(data["status"])=="CHALLENGE" and (not restored_session.enabled or restored_session.challenge_index<0):
		return false
	configure(bool(data["demo_mode"]))
	mission_index = int(data["mission_index"])
	_start_mission(true)
	marathon = restored_session
	status = str(data["status"])
	participants = people
	for key in SAVE_NUMBERS:
		set(key,numbers[key])
	for key in SAVE_SCORES:
		set(key,data["scores"][key].duplicate())
	crossings.assign(moving)
	rescue_owners.assign(data["rescue_owners"])
	saved_person_indices.assign(data["saved_ids"])
	votes = data["votes"].duplicate()
	secondary_complete = bool(data["secondary_complete"])
	mission_phase_label = str((mission_profile["phases"] as Array)[mission_phase])
	set_pause("manual",bool(data["manual_pause"]))
	events.clear()
	visual_events.clear()
	_note("SESSION RESTAUREE • PROGRESSION CONSERVEE","info")
	return true

func _saved_owner_valid(value, people: Dictionary, is_demo: bool) -> bool:
	return typeof(value)==TYPE_STRING and (people.has(value) or str(value).is_empty() or (is_demo and value=="DEMO"))

func _bounded_number(value, low: float, high: float, whole: bool = false) -> bool:
	if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
		return false
	return float(value)>=low and float(value)<=high and (not whole or float(value)==floor(float(value)))

func top_builders(limit: int = 3) -> Array[String]:
	return _leaders(builder_points,limit)

func top_donors(limit: int = 3) -> Array[String]:
	return _leaders(donor_points,limit)

func top_rescuers(limit: int = 3) -> Array[String]:
	return _leaders(rescuer_points,limit)

func _leaders(points: Dictionary, limit: int) -> Array[String]:
	var order: Array = points.keys()
	order.sort_custom(func(a, b): return int(points[a]) > int(points[b]))
	var out: Array[String] = []
	for user in order:
		if out.size() >= limit:
			break
		if int(points[user]) > 0:
			out.append("@" + str(user).substr(0,13) + " " + str(points[user]))
	return out
