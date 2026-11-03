extends Node3D

const ROUND_DURATION: float = 60.0
const SOCKET_URL := "ws://127.0.0.1:8765"

var red_hp: float = 100.0
var blue_hp: float = 100.0
var red_shield: float = 0.0
var blue_shield: float = 0.0
var score_red := 0
var score_blue := 0
var round_number := 1
var round_time := ROUND_DURATION
var combat_tick := 0.0
var intermission := 0.0
var players: Dictionary = {}
var contributions: Dictionary = {}
var like_totals: Dictionary = {}
var cooldown: Dictionary = {}
var socket := WebSocketPeer.new()
var connected := false
var retry_in := 4.0
var fighters: Array[Node3D] = []
var score_ui: Label
var health_ui: Label
var round_ui: Label
var status_ui: Label
var log_ui: Label
var leaders_ui: Label
var live_username: LineEdit
var arena_live: Node3D
var combat_director: Node3D
var confirmed_hits := 0
var confirmed_parries := 0
var confirmed_knockouts := 0
var souls_bank: Dictionary = {"red": 0, "blue": 0}
var souls_earned: Dictionary = {"red": 0, "blue": 0}
var souls_pending: Dictionary = {}
var match_started := false
var match_number := 1
var completed_rounds := 0
var final_message := ""
var souls_ui: Label
var gift_guide_ui: Label
var result_panel: PanelContainer
var result_ui: Label
var main_camera: Camera3D
var camera_clock := 0.0
var wins_red := 0
var wins_blue := 0
var match_finished := false
var bridge_state := "MODE SIMULATION"
var recruitment_ui: Label

func _ready() -> void:
	randomize()
	_build_scene()
	arena_live = load("res://scripts/arena_live.gd").new()
	add_child(arena_live)
	arena_live.call("setup", fighters)
	combat_director = load("res://scripts/combat_director.gd").new()
	add_child(combat_director)
	combat_director.connect("damage_crystal", _on_crystal_damage)
	combat_director.connect("battle_notice", _log)
	combat_director.connect("physics_telemetry", _on_physics_telemetry)
	combat_director.call("setup", arena_live, fighters)
	combat_director.call("sync_players", players, contributions)
	_build_hud()
	_connect_bridge()
	_log("Bienvenue dans LIVE BATTLES !")

func _mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.45
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _block(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(self, mesh, color, pos)

func _fighter(pos: Vector3, color: Color) -> Node3D:
	var fighter := Node3D.new()
	fighter.position = pos
	add_child(fighter)
	var body := CapsuleMesh.new()
	body.radius = 0.62
	body.height = 1.8
	_mesh(fighter, body, color, Vector3(0, 1.2, 0))
	var head := SphereMesh.new()
	head.radius = 0.54
	head.height = 1.08
	_mesh(fighter, head, color.lightened(0.18), Vector3(0, 2.42, 0))
	var eye := SphereMesh.new()
	eye.radius = 0.10
	eye.height = 0.20
	_mesh(fighter, eye, Color.WHITE, Vector3(-0.2, 2.48, 0.46))
	_mesh(fighter, eye, Color.WHITE, Vector3(0.2, 2.48, 0.46))
	var limb := CapsuleMesh.new()
	limb.radius = 0.19
	limb.height = 1.0
	_mesh(fighter, limb, color.darkened(0.18), Vector3(-0.76, 1.2, 0))
	_mesh(fighter, limb, color.darkened(0.18), Vector3(0.76, 1.2, 0))
	_mesh(fighter, limb, color.darkened(0.20), Vector3(-0.30, 0.45, 0))
	_mesh(fighter, limb, color.darkened(0.20), Vector3(0.30, 0.45, 0))
	return fighter

func _build_scene() -> void:
	var camera := Camera3D.new()
	add_child(camera)
	main_camera = camera
	camera.position = Vector3(0, 7.4, 20.2)
	camera.look_at(Vector3(0, 1.05, 0))
	camera.fov = 68.0
	camera.current = true
	var sunlight := DirectionalLight3D.new()
	add_child(sunlight)
	sunlight.rotation_degrees = Vector3(-55, -25, 0)
	sunlight.light_energy = 1.6
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#121a31")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e0e7ff")
	env.ambient_light_energy = 0.6
	world.environment = env
	add_child(world)
	_block(Vector3(0, -0.25, 0), Vector3(12, 0.5, 9), Color("#233249"))
	_block(Vector3(-3, 0.03, 0), Vector3(5.8, 0.08, 8.5), Color("#6b2437"))
	_block(Vector3(3, 0.03, 0), Vector3(5.8, 0.08, 8.5), Color("#194974"))
	_block(Vector3(0, 0.10, 0), Vector3(0.12, 0.14, 8.6), Color("#f8ca54"))
	fighters.append(_fighter(Vector3(-2.6, 0, 0), Color("#ff4a61")))
	fighters.append(_fighter(Vector3(2.6, 0, 0), Color("#39aaff")))

func _text(message: String, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color("#f3f6ff"))
	return lbl

func _panel(parent: Control, top: bool) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.12, 0.92)
	style.set_corner_radius_all(15)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 12
	panel.offset_right = -12
	if top:
		panel.offset_top = 12
		panel.offset_bottom = 290
	else:
		panel.offset_top = -405
		panel.offset_bottom = -12
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	return box

func _button(parent: Node, title: String, handler: Callable) -> void:
	var btn := Button.new()
	btn.text = title
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(btn)
	btn.pressed.connect(handler)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	canvas.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var top := _panel(root, true)
	top.add_child(_text("LIVE BATTLES", 40))
	score_ui = _text("", 28)
	top.add_child(score_ui)
	health_ui = _text("", 23)
	top.add_child(health_ui)
	round_ui = _text("", 19)
	top.add_child(round_ui)
	status_ui = _text("MODE SIMULATION", 15)
	top.add_child(status_ui)
	recruitment_ui = _text("Entre dans l'arene : !join red / !join blue", 17)
	top.add_child(recruitment_ui)
	souls_ui = _text("", 21)
	top.add_child(souls_ui)
	gift_guide_ui = _text("ROSE +1 | FINGER HEART +6 | DOUGHNUT +35 | GALAXY +150", 15)
	top.add_child(gift_guide_ui)
	var bottom := _panel(root, false)
	log_ui = _text("", 19)
	bottom.add_child(log_ui)
	leaders_ui = _text("", 16)
	bottom.add_child(leaders_ui)
	var toggle := Button.new()
	toggle.text = "OUTILS DE TEST / CONNECTER TIKTOK"
	bottom.add_child(toggle)
	var test_panel := VBoxContainer.new()
	test_panel.visible = false
	bottom.add_child(test_panel)
	var panel_container := bottom.get_parent() as PanelContainer
	panel_container.offset_top = -190
	toggle.pressed.connect(func():
		test_panel.visible = not test_panel.visible
		panel_container.offset_top = -420 if test_panel.visible else -190
	)
	var connection_row := HBoxContainer.new()
	test_panel.add_child(connection_row)
	live_username = LineEdit.new()
	live_username.placeholder_text = "Compte TikTok (sans @)"
	live_username.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	connection_row.add_child(live_username)
	_button(connection_row, "CONNECTER", _request_tiktok)
	var row1 := HBoxContainer.new()
	test_panel.add_child(row1)
	_button(row1, "ROUGE REJOINDRE", func(): _join("DemoRouge", "red"))
	_button(row1, "BLEU REJOINDRE", func(): _join("DemoBleu", "blue"))
	var row2 := HBoxContainer.new()
	test_panel.add_child(row2)
	_button(row2, "CADEAU ROUGE", func(): _gift("DemoRouge", 10, "Cadeau test"))
	_button(row2, "CADEAU BLEU", func(): _gift("DemoBleu", 10, "Cadeau test"))
	var row3 := HBoxContainer.new()
	test_panel.add_child(row3)
	_button(row3, "ATTAQUE ROUGE", func(): _action("DemoRouge", "!attack"))
	_button(row3, "ATTAQUE BLEUE", func(): _action("DemoBleu", "!attack"))
	var row4 := HBoxContainer.new()
	test_panel.add_child(row4)
	_button(row4, "SOINS ROUGE", func(): _action("DemoRouge", "!heal"))
	_button(row4, "SOINS BLEU", func(): _action("DemoBleu", "!heal"))
	result_panel = PanelContainer.new()
	root.add_child(result_panel)
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -320
	result_panel.offset_right = 320
	result_panel.offset_top = -120
	result_panel.offset_bottom = 120
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.16, 0.95)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(20)
	result_panel.add_theme_stylebox_override("panel", style)
	result_ui = _text("", 31)
	result_panel.add_child(result_ui)
	result_panel.visible = false

func _connect_bridge() -> void:
	socket = WebSocketPeer.new()
	var status := socket.connect_to_url(SOCKET_URL)
	if status != OK:
		connected = false
		retry_in = 4.0

func _process(delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		connected = true
		while socket.get_available_packet_count() > 0:
			_handle_packet(socket.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		connected = false
		retry_in -= delta
		if retry_in <= 0:
			retry_in = 4.0
			_connect_bridge()
	camera_clock += delta
	if main_camera != null:
		var ease := minf(1.0, delta * 1.7)
		main_camera.position = main_camera.position.lerp(
			Vector3(sin(camera_clock * 0.34) * 0.33, 7.4 + sin(camera_clock * 0.26) * 0.12, 20.2),
			ease
		)
		main_camera.look_at(Vector3(0, 1.05, 0))
	if match_finished:
		intermission -= delta
		if intermission <= 0:
			_next_round()
	elif match_started:
		if intermission > 0:
			intermission -= delta
			if intermission <= 0:
				_next_round()
		else:
			round_time -= delta
			if round_time <= 0 or red_hp <= 0 or blue_hp <= 0:
				_end_round()
	_update_hud()

func _members(team: String) -> int:
	var number := 0
	for value in players.values():
		if value == team:
			number += 1
	return number

func _damage(team: String, damage: float) -> void:
	# Cette fonction ne recoit QUE des evenements de collision ou de K.O.
	var dealt := 0.0
	if team == "red":
		var absorbed := minf(red_shield, damage)
		red_shield -= absorbed
		dealt = minf(red_hp, damage - absorbed)
		red_hp = maxf(0.0, red_hp - dealt)
	elif team == "blue":
		var absorbed := minf(blue_shield, damage)
		blue_shield -= absorbed
		dealt = minf(blue_hp, damage - absorbed)
		blue_hp = maxf(0.0, blue_hp - dealt)
	if arena_live != null:
		arena_live.call("set_health", team, red_hp if team == "red" else blue_hp)

func _end_round() -> void:
	if not match_started or intermission > 0 or match_finished:
		return
	combat_director.call("pause_round", true)
	completed_rounds += 1
	var round_winner := "EGALITE"
	if red_hp > blue_hp:
		wins_red += 1
		score_red += 10
		round_winner = "ROUGE"
	elif blue_hp > red_hp:
		wins_blue += 1
		score_blue += 10
		round_winner = "BLEU"
	_log("FIN MANCHE %d/3 : %s" % [round_number, round_winner])
	if completed_rounds >= 3:
		match_finished = true
		intermission = 11.0
		var winner := "ROUGE" if wins_red > wins_blue else ("BLEU" if wins_blue > wins_red else "EGALITE")
		final_message = "MATCH %d TERMINE !\n%s\nMANCHES %d - %d\nNOUVEAU MATCH DANS 11 s" % [
			match_number, "VICTOIRE " + winner if winner != "EGALITE" else "EGALITE !", wins_red, wins_blue
		]
		result_panel.visible = true
		result_ui.text = final_message
		_log("VICTOIRE " + winner + " • MATCH TERMINE")
	else:
		intermission = 4.0

func _next_round() -> void:
	if match_finished:
		match_number += 1
		match_finished = false
		completed_rounds = 0
		round_number = 1
		wins_red = 0
		wins_blue = 0
		score_red = 0
		score_blue = 0
		contributions.clear()
		cooldown.clear()
		souls_earned = {"red": 0, "blue": 0}
		combat_director.call("reset_match_stats")
		combat_director.call("sync_players", players, contributions)
		arena_live.call("update_players", players, contributions)
		result_panel.visible = false
	else:
		round_number += 1
	red_hp = 100.0
	blue_hp = 100.0
	red_shield = 0.0
	blue_shield = 0.0
	round_time = ROUND_DURATION
	combat_tick = 0.0
	intermission = 0.0
	match_started = _members("red") > 0 and _members("blue") > 0
	arena_live.call("set_health", "red", 100.0)
	arena_live.call("set_health", "blue", 100.0)
	combat_director.call("restart_round")
	if not match_started:
		combat_director.call("pause_round", true)
		_log("EN ATTENTE : UN JOUEUR PAR EQUIPE")
	else:
		_log("MATCH %d • MANCHE %d/3 : COMBAT !" % [match_number, round_number])
		_apply_soul_power("red")
		_apply_soul_power("blue")

func _join(user: String, team: String) -> void:
	if team != "red" and team != "blue" or user.is_empty():
		return
	if players.has(user):
		if str(players[user]) != team:
			_log("@" + user + " est deja dans une equipe")
		return
	players[user] = team
	arena_live.call("update_players", players, contributions)
	combat_director.call("sync_players", players, contributions)
	_log("@" + user + " rejoint " + team.to_upper())
	if souls_pending.has(user):
		var amount := int(souls_pending.get(user, 0))
		souls_pending.erase(user)
		_credit_souls(user, team, amount, "CADEAU EN ATTENTE")
	if not match_started and not match_finished and _members("red") > 0 and _members("blue") > 0:
		match_started = true
		combat_director.call("pause_round", false)
		_log("BATAILLE LANCEE : MANCHE %d/3 !" % round_number)
		_apply_soul_power("red")
		_apply_soul_power("blue")

func _add_points(user: String, team: String, amount: int) -> void:
	if team == "red":
		score_red += amount
	else:
		score_blue += amount
	contributions[user] = int(contributions.get(user, 0)) + amount
	if arena_live != null:
		arena_live.call("update_players", players, contributions)
	if combat_director != null:
		combat_director.call("sync_players", players, contributions)

func _action(user: String, command: String) -> void:
	if not match_started or match_finished or intermission > 0:
		return
	var team: String = str(players.get(user, ""))
	if team == "":
		_log(user + " doit d'abord rejoindre une equipe")
		return
	var key := user + ":" + command
	var now := Time.get_ticks_msec()
	if now - int(cooldown.get(key, -10000)) < 1500:
		return
	cooldown[key] = now
	match command:
		"!attack":
			combat_director.call("command", team, "attack")
			_add_points(user, team, 2)
			_log(user + " ordonne une CHARGE !")
		"!defend":
			combat_director.call("command", team, "defend")
			if team == "red":
				red_shield = minf(30.0, red_shield + 5.0)
			else:
				blue_shield = minf(30.0, blue_shield + 5.0)
			_add_points(user, team, 1)
			_log(user + " active les PARADES !")
		"!heal":
			combat_director.call("command", team, "heal")
			if team == "red":
				red_hp = minf(100, red_hp + 3.0)
			else:
				blue_hp = minf(100, blue_hp + 3.0)
			arena_live.call("set_health", team, red_hp if team == "red" else blue_hp)
			_add_points(user, team, 1)
			_log(user + " soigne ses combattants !")

func _gift(user: String, points: int, gift_name: String) -> void:
	var amount := clampi(points, 0, 3000)
	if amount <= 0:
		return
	if not players.has(user):
		souls_pending[user] = mini(5000, int(souls_pending.get(user, 0)) + amount)
		_log("@" + user + " : " + str(amount) + " AMES EN ATTENTE • !join red / !join blue")
		return
	_credit_souls(user, str(players[user]), amount, gift_name)

func _chat(user: String, message: String) -> void:
	var text := message.strip_edges().to_lower()
	if text == "!join red":
		_join(user, "red")
	elif text == "!join blue":
		_join(user, "blue")
	elif text == "!attack" or text == "!defend" or text == "!heal":
		_action(user, text)
	elif text == "!status":
		_log("Manche " + str(round_number))

func _handle_packet(raw: String) -> void:
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var packet: Dictionary = parsed
	if str(packet.get("type", "")) == "status":
		bridge_state = str(packet.get("message", "Passerelle connectee"))
		_log(bridge_state)
		return
	if str(packet.get("type", "")) != "event":
		return
	var user := str(packet.get("user", "Spectateur")).substr(0, 48)
	match str(packet.get("event", "")):
		"chat":
			_chat(user, str(packet.get("text", "")))
		"gift":
			_gift(user, int(packet.get("points", 1)), str(packet.get("gift_name", "Cadeau")))
		"like":
			if players.has(user):
				var count := maxi(1, int(packet.get("count", 1)))
				var total := int(like_totals.get(user, 0)) + count
				like_totals[user] = total % 50
				if total >= 50:
					_add_points(user, str(players[user]), int(total / 50))
		"follow":
			if players.has(user):
				_add_points(user, str(players[user]), 2)

func _request_tiktok() -> void:
	var user := live_username.text.strip_edges().trim_prefix("@")
	if user == "":
		_log("Saisir un identifiant TikTok")
		return
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_log("Passerelle non connectee")
		return
	socket.send_text(JSON.stringify({"type":"control","action":"connect","username":user}))
	_log("Connexion demandee : @" + user)

func _update_hud() -> void:
	score_ui.text = "MATCH %d  |  ROUGE %d - %d BLEU" % [match_number, wins_red, wins_blue]
	health_ui.text = "CRISTAUX   %d PV  /  %d PV" % [int(red_hp), int(blue_hp)]
	round_ui.text = "MANCHE %d/3  •  %02d s  •  %d ROUGES / %d BLEUS" % [
		round_number, int(maxf(0, round_time)), _members("red"), _members("blue")
	]
	if not match_started:
		status_ui.text = "EN ATTENTE DE 2 EQUIPES • PAS DE BOTS"
	elif match_finished:
		status_ui.text = "MATCH TERMINE • PROCHAIN DANS %d s" % int(ceil(intermission))
	elif intermission > 0:
		status_ui.text = "PAUSE AVANT PROCHAINE MANCHE : %d s" % int(ceil(intermission))
	else:
		status_ui.text = bridge_state if connected else "COMBAT AUTONOME • JOUEURS REELS"
	recruitment_ui.text = "!join red  /  !join blue  •  !attack  •  !defend  •  !heal"
	souls_ui.text = "AMES   ROUGE %d  |  BLEU %d  •  POUVOIRS 10 / 35 / 120" % [
		int(souls_bank["red"]), int(souls_bank["blue"])
	]
	var people: Array = contributions.keys()
	people.sort_custom(func(a, b): return int(contributions[a]) > int(contributions[b]))
	var leaders := PackedStringArray()
	for i in range(mini(3, people.size())):
		leaders.append("@" + str(people[i]).substr(0, 12) + ": " + str(contributions[people[i]]))
	leaders_ui.text = "TOP : " + " | ".join(leaders) if not leaders.is_empty() else "TON PSEUDO S'AFFICHERA APRES !join"
	if match_finished and result_panel != null:
		var winner := "ROUGE" if wins_red > wins_blue else ("BLEU" if wins_blue > wins_red else "EGALITE")
		result_ui.text = "FIN DU MATCH %d\n%s\nMANCHES %d - %d\nREPRISE DANS %d s" % [
			match_number, "VICTOIRE " + winner if winner != "EGALITE" else "EGALITE", wins_red, wins_blue, int(ceil(intermission))
		]

func _log(message: String) -> void:
	if log_ui != null:
		log_ui.text = message

func _on_crystal_damage(team: String, amount: float) -> void:
	if match_started and not match_finished and intermission <= 0:
		_damage(team, amount)

func _on_physics_telemetry(hits: int, parries: int, knockouts: int) -> void:
	confirmed_hits = hits
	confirmed_parries = parries
	confirmed_knockouts = knockouts

func _credit_souls(user: String, team: String, amount: int, gift_name: String) -> void:
	if amount <= 0 or not souls_bank.has(team):
		return
	souls_bank[team] = mini(10000, int(souls_bank[team]) + amount)
	souls_earned[team] = int(souls_earned[team]) + amount
	_add_points(user, team, amount)
	arena_live.call("gift_feedback", team, amount, user, gift_name)
	_log("@" + user + " apporte " + str(amount) + " AMES aux " + team.to_upper())
	_apply_soul_power(team, user)

func _apply_soul_power(team: String, user: String = "EQUIPE") -> void:
	if not match_started or intermission > 0 or match_finished:
		return
	var balance := int(souls_bank.get(team, 0))
	var tier := 0
	var cost := 0
	if balance >= 120:
		tier = 3
		cost = 120
	elif balance >= 35:
		tier = 2
		cost = 35
	elif balance >= 10:
		tier = 1
		cost = 10
	if tier <= 0:
		return
	souls_bank[team] = balance - cost
	combat_director.call("soul_power", team, tier, user)
	_log("POUVOIR DES AMES %d ACTIVE • %s" % [tier, team.to_upper()])
