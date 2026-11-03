extends Node3D

const ROUND_DURATION: float = 90.0
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
	camera.position = Vector3(0, 8, 14)
	camera.look_at(Vector3(0, 1, 0))
	camera.fov = 54.0
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
		panel.offset_bottom = 225
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
	recruitment_ui = _text("Rejoins le combat : !join red ou !join blue", 17)
	top.add_child(recruitment_ui)
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
	if intermission > 0:
		intermission -= delta
		if intermission <= 0:
			_next_round()
	else:
		round_time -= delta
		combat_tick += delta
		if combat_tick >= 1.5:
			combat_tick = 0
			_damage("blue", 2.5 + float(_members("red")) * 0.25)
			_damage("red", 2.5 + float(_members("blue")) * 0.25)
		if round_time <= 0 or red_hp <= 0 or blue_hp <= 0:
			_end_round()
	var jump := sin(float(Time.get_ticks_msec()) / 300.0) * 0.11
	fighters[0].position.y = jump
	fighters[1].position.y = -jump
	_update_hud()

func _members(team: String) -> int:
	var number := 0
	for value in players.values():
		if value == team:
			number += 1
	return number

func _damage(team: String, damage: float) -> void:
	var dealt := 0.0
	if team == "red":
		var shielded := minf(red_shield, damage)
		red_shield -= shielded
		dealt = minf(red_hp, damage - shielded)
		red_hp = maxf(0, red_hp - dealt)
	elif team == "blue":
		var shielded := minf(blue_shield, damage)
		blue_shield -= shielded
		dealt = minf(blue_hp, damage - shielded)
		blue_hp = maxf(0, blue_hp - dealt)
	if arena_live != null:
		arena_live.call("set_health", team, red_hp if team == "red" else blue_hp)
		if dealt > 0:
			arena_live.call("strike", "blue" if team == "red" else "red", dealt, "EPEE")
func _end_round() -> void:
	if intermission > 0:
		return
	intermission = 4.0
	if red_hp > blue_hp:
		wins_red += 1
		score_red += 10
		_log("MANCHE GAGNEE : ROUGES !")
	elif blue_hp > red_hp:
		wins_blue += 1
		score_blue += 10
		_log("MANCHE GAGNEE : BLEUS !")
	else:
		_log("MATCH NUL")
	if wins_red >= 3 or wins_blue >= 3:
		match_finished = true
		intermission = 8.0
		_log("BATAILLE TERMINEE ! VAINQUEURS : " + ("ROUGES" if wins_red >= 3 else "BLEUS"))
func _next_round() -> void:
	if match_finished:
		wins_red = 0
		wins_blue = 0
		score_red = 0
		score_blue = 0
		contributions.clear()
		cooldown.clear()
		match_finished = false
		arena_live.call("update_players", players, contributions)
	red_hp = 100.0
	blue_hp = 100.0
	red_shield = 0
	blue_shield = 0
	round_time = ROUND_DURATION
	combat_tick = 0
	intermission = 0
	round_number += 1
	arena_live.call("set_health", "red", 100.0)
	arena_live.call("set_health", "blue", 100.0)
	_log("Nouvelle manche : COMBAT !")
func _join(user: String, team: String) -> void:
	if team != "red" and team != "blue":
		return
	if players.has(user):
		if str(players[user]) != team:
			_log(user + " est deja dans une autre equipe")
		return
	players[user] = team
	arena_live.call("update_players", players, contributions)
	arena_live.call("reaction", team, "join")
	_log(user + " entre dans l'arene " + team.to_upper() + " !")
func _add_points(user: String, team: String, amount: int) -> void:
	if team == "red":
		score_red += amount
	else:
		score_blue += amount
	contributions[user] = int(contributions.get(user, 0)) + amount
	if arena_live != null:
		arena_live.call("update_players", players, contributions)

func _action(user: String, command: String) -> void:
	var team: String = str(players.get(user, ""))
	if team == "":
		_log(user + " doit rejoindre une equipe")
		return
	var key := user + ":" + command
	var now := Time.get_ticks_msec()
	if now - int(cooldown.get(key, -10000)) < 1500:
		return
	cooldown[key] = now
	var opponent := "blue" if team == "red" else "red"
	match command:
		"!attack":
			_damage(opponent, 7)
			_add_points(user, team, 2)
			_log(user + " attaque !")
		"!defend":
			if team == "red":
				red_shield = minf(40.0, red_shield + 8)
			else:
				blue_shield = minf(40.0, blue_shield + 8)
			_add_points(user, team, 1)
			arena_live.call("reaction", team, "defend")
			_log(user + " defend !")
		"!heal":
			if team == "red":
				red_hp = minf(100, red_hp + 8)
			else:
				blue_hp = minf(100, blue_hp + 8)
			_add_points(user, team, 1)
			arena_live.call("reaction", team, "heal")
			_log(user + " soigne !")

func _gift(user: String, points: int, gift_name: String) -> void:
	if not players.has(user):
		_join(user, "red" if _members("red") <= _members("blue") else "blue")
	var team: String = str(players[user])
	var safe_points := clampi(points, 1, 1000)
	_add_points(user, team, safe_points)
	_damage("blue" if team == "red" else "red", minf(20.0, float(safe_points) * 0.6))
	arena_live.call("reaction", team, "gift")
	_log(user + " : " + gift_name + " +" + str(safe_points))

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
	score_ui.text = "MANCHES  ROUGE %d  -  %d BLEU" % [wins_red, wins_blue]
	health_ui.text = "CRISTAUX  %d PV  |  %d PV" % [int(red_hp), int(blue_hp)]
	round_ui.text = "MANCHE %d | %02d s | %d ROUGES / %d BLEUS" % [round_number, int(maxf(0, round_time)), _members("red"), _members("blue")]
	status_ui.text = bridge_state if connected else "AUTONOME • BOTS ACTIFS"
	recruitment_ui.text = "REJOINS : !join red  /  !join blue  |  ATTAQUE : !attack"
	var people: Array = contributions.keys()
	people.sort_custom(func(a, b): return int(contributions[a]) > int(contributions[b]))
	var leaders := PackedStringArray()
	for i in range(mini(3, people.size())):
		leaders.append(str(people[i]) + " " + str(contributions[people[i]]))
	leaders_ui.text = "TOP : " + " | ".join(leaders) if not leaders.is_empty() else "BOTS EN ACTION — SOIS LE PREMIER A REJOINDRE !"
func _log(message: String) -> void:
	if log_ui != null:
		log_ui.text = message
