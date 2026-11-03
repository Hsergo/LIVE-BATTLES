extends Node2D
## MISSION SAUVETAGE LIVE — premier niveau 2,5D procedural, vertical TikTok.
## Pas d'assets externes, aucune installation Blender requise.
## Les seules interactions des spectateurs en LIVE viennent de la passerelle.

const Mission = preload("res://scripts/mission.gd")
const WIDTH := 720.0
const HEIGHT := 1280.0
const BRIDGE_LEFT := 188.0
const BRIDGE_RIGHT := 558.0
const BRIDGE_Y := 692.0

var state: RefCounted
var ws: WebSocketPeer = WebSocketPeer.new()
var bridge_connected := false
var status_tiktok := "PASSERELLE NON CONNECTEE"
var reconnect := 2.5
var connected_before := false
var clock := 0.0
var pulse := 0.0
var ui_clock := 0.0
var game_mode := "DEMO"
var admin_visible := true
var live_name: LineEdit
var status_label: Label
var mode_button: Button
var act_buttons: Array[Button] = []
var canvas: Control
var bridge_wave := 0.0
var flash := 0.0
var twinkle: Array[Vector2] = []
var last_event := 0
var banner := ""
var banner_life := 0.0
var helicopter_time := 0.0
var helicopter_active := false
var last_progress := 0.0
var last_saved := 0
var last_strength := 0.0
var fx: Array[Dictionary] = []
var shake := 0.0
var music: Node
var live_auto_hide := false
var saved_live_name := ""
var hint_flash := 0.0

func _ready() -> void:
	randomize()
	state = Mission.new()
	state.call("configure",true)
	last_progress = float(state.get("progress"))
	last_strength = float(state.get("strength"))
	for i in range(32):
		twinkle.append(Vector2(randf_range(0, WIDTH),randf_range(255,515)))
	music = load("res://scripts/audio_fx.gd").new()
	add_child(music)
	_build_controls()
	_load_preferences()
	_open_socket()
	set_process(true)
	queue_redraw()

func _open_socket() -> void:
	ws = WebSocketPeer.new()
	var result := ws.connect_to_url("ws://127.0.0.1:8766")
	if result != OK:
		reconnect = 4.0

func _process(delta: float) -> void:
	var d := minf(0.1,delta)
	clock += d
	pulse += d
	bridge_wave += d
	ui_clock += d
	flash = maxf(0,flash-d*2.0)
	shake = maxf(0.0, shake-d*1.8)
	for item in fx.duplicate():
		item["time"] = float(item["time"])-d
		item["pos"] = item["pos"]+item["velocity"]*d
		item["velocity"] = item["velocity"]*0.96
		if float(item["time"]) <= 0.0:
			fx.erase(item)
	banner_life = maxf(0,banner_life-d)
	if helicopter_active:
		helicopter_time += d
		if helicopter_time > 5.0:
			helicopter_active = false
	_poll_socket(d)
	state.call("tick",d)
	var progress := float(state.get("progress"))
	var strength := float(state.get("strength"))
	var rescued := int(state.get("saved"))
	if progress > last_progress + 7.0:
		flash = maxf(flash,0.12)
	if strength < last_strength - 8.0:
		flash = 0.6
	if rescued > last_saved:
		banner = "UN HABITANT SAUVE !"
		banner_life = 2.2
	if state.get("events").size() > 0:
		var e: Dictionary = state.get("events")[0]
		if int(e.get("id",0)) != last_event:
			last_event = int(e.get("id",0))
			var kind := str(e.get("kind",""))
			_visual_event(e)
			if music != null:
				music.call("play_effect", kind)
			if kind in ["gift","power"]:
				helicopter_active = true
				helicopter_time = 0.0
			if kind in ["danger","success","power"]:
				banner = str(e.get("message",""))
				banner_life = 2.6
	last_progress = progress
	last_strength = strength
	last_saved = rescued
	if ui_clock >= 0.25:
		ui_clock = 0.0
		_update_controls()
	queue_redraw()

func _poll_socket(d: float) -> void:
	ws.poll()
	var status := ws.get_ready_state()
	if status == WebSocketPeer.STATE_OPEN:
		if not connected_before:
			connected_before = true
			if game_mode == "LIVE" and not saved_live_name.is_empty():
				ws.send_text(JSON.stringify({"type":"control","action":"connect","username":saved_live_name}))
				status_tiktok = "RECONNEXION AUTOMATIQUE : @" + saved_live_name
		bridge_connected = true
		reconnect = 4.0
		while ws.get_available_packet_count() > 0:
			_handle_packet(ws.get_packet().get_string_from_utf8())
	elif status == WebSocketPeer.STATE_CLOSED:
		bridge_connected = false
		connected_before = false
		reconnect -= d
		if reconnect <= 0.0:
			reconnect = 4.0
			_open_socket()

func _handle_packet(raw: String) -> void:
	var packet = JSON.parse_string(raw)
	if typeof(packet) != TYPE_DICTIONARY:
		return
	if str(packet.get("type","")) == "status":
		status_tiktok = str(packet.get("message","")).substr(0,90)
		if game_mode == "LIVE" and status_tiktok.begins_with("TIKTOK LIVE CONNECTE") and not live_auto_hide:
			admin_visible = false
			live_auto_hide = true
			_update_controls()
		return
	if str(packet.get("type","")) != "event":
		return
	if game_mode != "LIVE":
		return
	var user := str(packet.get("user","Spectateur")).strip_edges().substr(0,24)
	if user.is_empty():
		return
	match str(packet.get("event","")):
		"chat":
			state.call("receive",user,str(packet.get("text","")))
		"gift":
			state.call("gift",user,str(packet.get("gift_name","")),int(packet.get("count",1)))
		"like":
			# Les likes soutiennent la popularite du LIVE, pas un achat force.
			pass

func _switch_mode() -> void:
	if game_mode == "DEMO":
		game_mode = "LIVE"
		live_auto_hide = false
		state.call("configure",false)
		banner = "MODE LIVE : AUCUN JOUEUR FICTIF"
		banner_life = 3.0
	else:
		game_mode = "DEMO"
		admin_visible = true
		state.call("configure",true)
		saved_live_name = ""
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.send_text(JSON.stringify({"type":"control","action":"disconnect"}))
		_save_preferences(false)
		banner = "MODE DEMONSTRATION • SCENARIO AUTOMATIQUE"
		banner_life = 3.0
	_update_controls()

func _connect_tiktok() -> void:
	var name := live_name.text.strip_edges().trim_prefix("@")
	if name.is_empty():
		status_tiktok = "SAISIS TON PSEUDO TIKTOK"
		return
	if game_mode != "LIVE":
		_switch_mode()
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		status_tiktok = "PASSERELLE LOCALE NON DISPONIBLE"
		return
	saved_live_name = name
	_save_preferences(true)
	ws.send_text(JSON.stringify({"type":"control","action":"connect","username":name}))
	status_tiktok = "CONNEXION DEMANDEE : @" + name

func _admin_command(command: String) -> void:
	if game_mode != "DEMO":
		return
	state.call("receive","DEMO",command)

func _style_button(button: Button, color: Color) -> void:
	button.add_theme_font_size_override("font_size",17)
	button.add_theme_color_override("font_color",Color("#f1fbff"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(11)
	normal.set_content_margin_all(11)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.14)
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.17)
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hover)
	button.add_theme_stylebox_override("pressed",pressed)

func _make_btn(parent: Node, text_value: String, width: float, action: Callable, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width,44)
	_style_button(button,color)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	canvas = Control.new()
	layer.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.position = Vector2(14,1058)
	panel.size = Vector2(692,208)
	canvas.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#061628f4")
	style.border_color = Color("#5caab56e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(17)
	style.set_content_margin_all(11)
	panel.add_theme_stylebox_override("panel",style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",7)
	panel.add_child(stack)
	var first := HBoxContainer.new()
	first.add_theme_constant_override("separation",8)
	stack.add_child(first)
	act_buttons.append(_make_btn(first,"+ CONSTRUIRE",210,func(): _admin_command("!build"),Color("#087978")))
	act_buttons.append(_make_btn(first,"REPARER",210,func(): _admin_command("!repair"),Color("#3c657b")))
	act_buttons.append(_make_btn(first,"EVACUER",210,func(): _admin_command("!rescue"),Color("#bc6e30")))
	var second := HBoxContainer.new()
	second.add_theme_constant_override("separation",8)
	stack.add_child(second)
	mode_button = _make_btn(second,"MODE : DEMO",165,_switch_mode,Color("#3b557a"))
	live_name = LineEdit.new()
	live_name.placeholder_text = "Pseudo TikTok sans @"
	live_name.custom_minimum_size = Vector2(280,46)
	live_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_name.add_theme_font_size_override("font_size",19)
	second.add_child(live_name)
	_make_btn(second,"CONNECTER LIVE",165,_connect_tiktok,Color("#c24b74"))
	status_label = Label.new()
	status_label.text = "SIMULATION AUTONOME • CHANGE EN LIVE POUR RECEVOIR LES COMMENTAIRES"
	status_label.add_theme_font_size_override("font_size",14)
	status_label.add_theme_color_override("font_color",Color("#9bb6c9"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(status_label)
	var hint := Label.new()
	hint.text = "F11 : plein ecran    |    F10 : masquer les commandes    |    F9 : son"
	hint.add_theme_font_size_override("font_size",13)
	hint.add_theme_color_override("font_color",Color("#8c9dac"))
	stack.add_child(hint)
	_update_controls()

func _update_controls() -> void:
	if mode_button == null:
		return
	mode_button.text = "MODE : " + game_mode
	for button in act_buttons:
		button.disabled = game_mode != "DEMO"
	if game_mode == "DEMO":
		status_label.text = "DEMO : LES ACTIONS SONT SIMULEES • AUCUN SPECTATEUR FICTIF"
	else:
		status_label.text = status_tiktok if bridge_connected else "CONNECTE LE LIVE AVEC TON PSEUDO TIKTOK"
	canvas.visible = admin_visible

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F10:
		admin_visible = not admin_visible
		_update_controls()
	elif event.keycode == KEY_F9:
		if music != null:
			music.call("toggle_sound")
	elif event.keycode == KEY_F11:
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func _poly(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points),color)

func _rect(x: float,y: float,w: float,h: float,c: Color) -> void:
	draw_rect(Rect2(x,y,w,h),c)

func _text(message: String, at: Vector2, size: int = 20, color: Color = Color.WHITE, centered: bool = false, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT, width, size, color)

func _round_progress(y: float, fraction: float, main_color: Color, label: String) -> void:
	_rect(30,y,660,14,Color("#243d50"))
	_rect(30,y,660*clampf(fraction,0,1),14,main_color)
	_text(label,Vector2(30,y-9),18,Color("#c5e2ef"))

func _draw() -> void:
	_draw_base()
	var zoom := 1.14 + sin(clock*0.18)*0.013
	var camera_pan := Vector2(
		-50.0 + sin(clock*0.34)*2.6 + randf_range(-shake,shake)*11.0,
		-169.0 + sin(clock*0.23)*2.2 + randf_range(-shake,shake)*8.0
	)
	draw_set_transform(camera_pan,0.0,Vector2(zoom,zoom))
	_draw_landscape()
	_draw_village()
	_draw_bridge()
	_draw_bridge_detail()
	_draw_people()
	_draw_weather()
	_draw_fx()
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	_draw_header()
	_draw_scene_legend()
	_draw_emergency_card()
	_draw_footer()
	if banner_life > 0:
		_rect(50,861,620,71,Color("#0a213de8"))
		_rect(50,861,8,71,Color("#ffc56c"))
		_text(banner,Vector2(73,904),22,Color("#fff0bc"),false,565)
	if str(state.get("status")) == "RESULT":
		_draw_result()
	if flash > 0:
		_rect(0,250,720,720,Color(1.0,0.50,0.28,flash*0.22))

func _draw_base() -> void:
	_rect(0,0,720,1280,Color("#07162a"))
	for i in range(11):
		var hue := float(i)/10.0
		_rect(0,237+float(i)*72,720,76,Color("#102e4b").lerp(Color("#0d5d67"),hue*0.68))
	for j in range(14):
		_rect(0,237+float(j)*53,720,2,Color(1,1,1,0.007))
	_rect(0,0,720,236,Color("#091527"))
	_rect(0,962,720,318,Color("#081629"))

func _draw_header() -> void:
	_rect(23,20,674,52,Color("#142c3c"))
	_rect(23,20,7,52,Color("#ffc86a"))
	_text("MISSION SAUVETAGE",Vector2(42,57),33,Color("#f3fcff"))
	_rect(574,29,100,31,Color("#be405c") if game_mode == "LIVE" else Color("#256e6e"))
	_text("LIVE" if game_mode == "LIVE" else "DEMO",Vector2(584,52),18,Color.WHITE,true,80)
	_text("PONT DE LA DERNIERE CHANCE   /   MISSION %02d" % int(state.get("mission_index")),Vector2(30,102),20,Color("#9ac9d7"))
	var seconds := int(ceil(float(state.get("seconds"))))
	_text("%02d:%02d" % [seconds/60,seconds%60],Vector2(520,113),43,Color("#ffd080"))
	_text("AVANT LA CRUE",Vector2(532,138),14,Color("#f5cba6"))
	var rescued := int(state.get("saved"))
	var total := maxi(1,int(state.get("target")))
	_text("HABITANTS  %d/%d" % [rescued,total],Vector2(30,140),25,Color("#fff1c6"))
	_round_progress(169,float(rescued)/float(total),Color("#43d0a6"),"SAUVETAGE")
	_text("CONSTRUCTION  %d%%" % int(state.get("progress")),Vector2(30,224),19,Color("#9ee6e6"))
	_rect(273,211,168,12,Color("#233c50"))
	_rect(273,211,168*float(state.get("progress"))/100.0,12,Color("#ffa95a"))
	_text("PONT  %d%%" % int(state.get("strength")),Vector2(457,224),19,Color("#bfe4ff"))
	_rect(585,211,107,12,Color("#233c50"))
	_rect(585,211,107*float(state.get("strength"))/100.0,12,Color("#64c4ed"))

func _draw_landscape() -> void:
	_poly([Vector2(-30,570),Vector2(85,445),Vector2(185,526),Vector2(270,468),Vector2(345,588),Vector2(410,520),Vector2(735,565),Vector2(735,840),Vector2(-30,840)],Color("#1b5464"))
	_poly([Vector2(0,601),Vector2(115,535),Vector2(215,564),Vector2(303,523),Vector2(380,618),Vector2(720,571),Vector2(720,850),Vector2(0,850)],Color("#1b7774"))
	for i in range(25):
		var p := twinkle[i]
		draw_circle(Vector2(p.x, p.y + sin(clock*0.7+float(i))*2.0),1.4,Color(0.77,1.0,0.93,0.28))
	# Berges en perspective et riviere agitee.
	_poly([Vector2(184,535),Vector2(553,535),Vector2(650,955),Vector2(70,955)],Color("#073750"))
	_poly([Vector2(220,535),Vector2(523,535),Vector2(615,955),Vector2(112,955)],Color("#0a6880"))
	for line_idx in range(19):
		var yy := 548+float(line_idx)*21.0
		var drift := sin(clock*1.9+float(line_idx)*0.57)*34.0
		var sx := 200 + drift + float(line_idx%4)*55.0
		draw_line(Vector2(sx,yy),Vector2(sx+150+float(line_idx%3)*15,yy+8),Color(0.65,0.94,1.0,0.13),2.0)
	# Les rives couleur menthe.
	_poly([Vector2(-10,550),Vector2(180,531),Vector2(171,966),Vector2(-10,966)],Color("#366e55"))
	_poly([Vector2(544,529),Vector2(730,550),Vector2(730,965),Vector2(619,965)],Color("#39765a"))
	for i in range(5):
		_draw_tree(Vector2(25+float(i)*35,650+float(i%3)*85),0.75)
		_draw_tree(Vector2(655+float(i%2)*32,603+float(i)*62),0.68)
	# Barriere de crue a venir, impact visuel graduel.
	if int(state.get("weather_stage")) >= 1:
		for k in range(4):
			var rx := fposmod(clock*55.0+float(k)*170.0,850.0)-130
			var by := 825+float(k%2)*45
			draw_arc(Vector2(rx,by),74,PI,TAU,25,Color(0.85,0.95,1,0.24),5.0)

func _draw_tree(pos: Vector2, scale_value: float) -> void:
	draw_line(pos+Vector2(0,19)*scale_value,pos+Vector2(0,-9)*scale_value,Color("#624c38"),6.0*scale_value)
	draw_circle(pos+Vector2(0,-16)*scale_value,21.0*scale_value,Color("#0b6354"))
	draw_circle(pos+Vector2(-10,-23)*scale_value,14*scale_value,Color("#1d9971"))
	draw_circle(pos+Vector2(11,-23)*scale_value,13*scale_value,Color("#33ad7e"))

func _house(x: float,y: float,scale_value: float,roof: Color) -> void:
	var w := 77*scale_value
	var h := 64*scale_value
	_rect(x+6,y+12,w,h,Color("#1b3438"))
	_rect(x,y,w,h,Color("#f2d9a6"))
	_poly([Vector2(x-9,y+13),Vector2(x+w/2,y-21),Vector2(x+w+9,y+13)],roof)
	_rect(x+w*0.56,y+h*0.31,w*0.25,h*0.3,Color("#225b70"))
	_rect(x+9,y+h*0.46,w*0.22,h*0.54,Color("#8f5941"))

func _draw_village() -> void:
	_house(20,558,0.92,Color("#d96f60"))
	_house(114,540,0.73,Color("#e68e59"))
	_house(65,802,0.88,Color("#c05e65"))
	# Le refuge de droite est vraiment reconnaissable.
	_rect(609,566,104,103,Color("#d0e5c4"))
	_poly([Vector2(599,573),Vector2(659,531),Vector2(723,573)],Color("#5fa29d"))
	_rect(628,612,60,57,Color("#275b6f"))
	_rect(636,555,38,32,Color("#2f7d78"))
	_rect(649,535,11,70,Color("#f0e8b9"))
	_text("REFUGE",Vector2(597,699),19,Color("#e9f8e6"))
	_text("VILLAGE",Vector2(29,519),19,Color("#f7e1b4"))
	# Grue mobile simulee, uniquement un renfort de construction; sans joueur fictif.
	var swing := sin(clock*0.45)*5.0
	draw_line(Vector2(630,774),Vector2(630,622),Color("#f5b05d"),10)
	draw_line(Vector2(630,633),Vector2(455+swing,633),Color("#ffc46f"),8)
	draw_line(Vector2(498+swing,633),Vector2(498+swing,681),Color("#d1e5e3"),2)
	draw_circle(Vector2(630,622),14,Color("#ecd084"))
	if helicopter_active:
		var hx := -130+helicopter_time*190.0
		_rect(hx,397,104,31,Color("#ffc15f"))
		draw_circle(Vector2(hx+29,428),10,Color("#173b51"))
		draw_line(Vector2(hx+51,390),Vector2(hx+51,404),Color("#f7fff1"),3)
		draw_line(Vector2(hx+8,391),Vector2(hx+112,391),Color("#e5eafa"),5)
		draw_line(Vector2(hx+51,428),Vector2(hx+51,457),Color("#f1db9a"),2)
		_rect(hx+36,456,34,25,Color("#ba8c55"))

func _draw_bridge() -> void:
	var progress := float(state.get("progress"))
	var integrity := float(state.get("strength"))
	# Cable et poutrelles suspendues sous la passerelle.
	draw_line(Vector2(162,643),Vector2(585,647),Color("#ccdce0"),4.5)
	draw_line(Vector2(169,770),Vector2(593,762),Color("#173c4c"),9)
	for i in range(9):
		var xx := BRIDGE_LEFT+float(i)*((BRIDGE_RIGHT-BRIDGE_LEFT)/8.0)
		var yy := BRIDGE_Y - 11*sin(float(i)*PI/8.0)
		draw_line(Vector2(xx,yy-28),Vector2(xx,yy+35),Color("#f3d89d"),3.0)
	# Sections en construction visibles, pont en perspective.
	for i in range(8):
		var sx := BRIDGE_LEFT+float(i)*46.0
		var partial := clampf(progress/100.0*8.0-float(i),0.0,1.0)
		if partial <= 0.0:
			draw_line(Vector2(sx,BRIDGE_Y),Vector2(sx+43,BRIDGE_Y-4),Color("#c3dfdb"),2.0)
			continue
		var plank := 45*partial
		var bob := sin(clock*0.9+float(i))*1.1
		_poly([Vector2(sx,BRIDGE_Y+bob),Vector2(sx+plank,BRIDGE_Y+bob-2),Vector2(sx+plank+8,BRIDGE_Y+bob+25),Vector2(sx+7,BRIDGE_Y+bob+27)],Color("#bb8754"))
		draw_line(Vector2(sx+2,BRIDGE_Y+bob+2),Vector2(sx+plank-3,BRIDGE_Y+bob-1),Color("#ffd6a1"),3.0)
		if integrity < 52 and i%3 == 0:
			draw_line(Vector2(sx+9,BRIDGE_Y+6),Vector2(sx+28,BRIDGE_Y+23),Color("#633c3c"),2.7)
	for j in [0,1]:
		var px := 165.0 if j == 0 else 585.0
		draw_line(Vector2(px,BRIDGE_Y+34),Vector2(px,BRIDGE_Y-90),Color("#d4e0d2"),12.0)
		draw_circle(Vector2(px,BRIDGE_Y-90),13.0,Color("#f4d27b"))
	# Boites de materiaux et debris.
	for i in range(4):
		_rect(68+float(i)*16,745+float(i%2)*9,26,21,Color("#b97e52"))
		draw_line(Vector2(70+float(i)*16,748+float(i%2)*9),Vector2(90+float(i)*16,763+float(i%2)*9),Color("#eed0a1"),2)
	# Traversants en mouvement.
	for person in state.get("crossings"):
		var p := clampf(float(person.get("p",0)),0,1)
		var lane := float(person.get("lane",0))
		_draw_person(Vector2(178+p*392,BRIDGE_Y-7+lane*8),Color("#ffe9ae"),0.93+sin(clock*9+p)*0.03,false)

func _draw_person(at: Vector2, color: Color, scale_value: float, helmet: bool = true) -> void:
	draw_ellipse_shadow(at, 10*scale_value)
	draw_line(at+Vector2(-4,8)*scale_value,at+Vector2(-6,22)*scale_value,Color("#133448"),3.0*scale_value)
	draw_line(at+Vector2(4,8)*scale_value,at+Vector2(7,21)*scale_value,Color("#133448"),3.0*scale_value)
	_rect(at.x-8*scale_value,at.y-3*scale_value,16*scale_value,18*scale_value,color)
	draw_circle(at+Vector2(0,-12)*scale_value,9*scale_value,Color("#f5cba4"))
	if helmet:
		draw_arc(at+Vector2(0,-13)*scale_value,9*scale_value,PI,TAU,12,Color("#ffd675"),4.0)
	draw_line(at+Vector2(-7,1)*scale_value,at+Vector2(-14,6)*scale_value,color,3*scale_value)
	draw_line(at+Vector2(7,1)*scale_value,at+Vector2(13,5)*scale_value,color,3*scale_value)

func draw_ellipse_shadow(at: Vector2, width: float) -> void:
	draw_circle(at+Vector2(0,21),width,Color(0.01,0.14,0.18,0.27))

func _draw_people() -> void:
	var names: Array = []
	if game_mode == "LIVE":
		var members: Dictionary = state.get("participants")
		for user in members.keys():
			if names.size() >= 7:
				break
			names.append(str(user))
	else:
		names = ["DEMO"]
	var progress: float = float(state.get("progress"))/100.0
	var build_front := BRIDGE_LEFT+minf(progress,0.96)*(BRIDGE_RIGHT-BRIDGE_LEFT)
	for i in range(names.size()):
		var x := clampf(build_front-17.0-float(i%3)*27.0,BRIDGE_LEFT+10.0,BRIDGE_RIGHT-22.0)
		var y := BRIDGE_Y-19.0+float(i/3)*4.0+sin(clock*3.2+float(i))*5.0
		var color := Color("#ffdb87") if i%2==0 else Color("#7ef0cb")
		_draw_person(Vector2(x,y),color,1.27,true)
		var display_name := str(names[i]).substr(0,13)
		_rect(x-39,y-65,79,22,Color("#092737eb"))
		_text("@" + display_name if game_mode == "LIVE" else "DEMO",Vector2(x-36,y-48),13,Color("#ffffff"),true,73)
	var crossings: Array = state.get("crossings")
	var waiting := maxi(0,int(state.get("target"))-int(state.get("saved"))-crossings.size())
	for j in range(mini(8,waiting)):
		var px := 61.0 + float(j%4)*24.0
		var py := 740.0 + float(j/4)*40.0
		_draw_person(Vector2(px,py),Color("#ec9ead") if j%2==0 else Color("#bfefc9"),0.99,false)
	var caption := "%d VRAIS CONSTRUCTEURS" % names.size() if game_mode=="LIVE" else "DEMONSTRATION AUTOMATIQUE"
	_text(caption,Vector2(28,848),17,Color("#f7fff5"))

func _draw_weather() -> void:
	var stage := int(state.get("weather_stage"))
	var intensity := stage*0.33
	for i in range(22+stage*18):
		var seed := float(i)*37.23
		var px := fposmod(seed*11+clock*(95+intensity*170),820)-80
		var py := fposmod(seed*17+clock*(210+intensity*80),560)+275
		draw_line(Vector2(px,py),Vector2(px-5-intensity*7,py+16+intensity*10),Color(0.74,0.91,1,0.07+intensity*0.14),1.4)
	if stage >= 2:
		var lightning := sin(clock*3.0)
		if lightning > 0.985:
			draw_line(Vector2(534,304),Vector2(502,372),Color("#f7f9df"),6)
			draw_line(Vector2(502,372),Vector2(542,405),Color("#f7f9df"),5)

func _draw_scene_legend() -> void:
	_rect(21,242,678,53,Color("#06263dde"))
	if str(state.get("status")) == "WAITING":
		_text("ECRIS !join DANS LE CHAT POUR DEMARRER !",Vector2(33,274),19,Color("#ffec9f"))
	elif str(state.get("status")) == "RESULT":
		_text("SAUVETAGE TERMINE • NOUVELLE CRUE EN APPROCHE",Vector2(33,274),18,Color("#ffec9f"))
	else:
		_text("!build CONSTRUIRE    !repair REPARER    !rescue SAUVER",Vector2(34,275),18,Color("#e0f5f6"))
	var events: Array = state.get("events")
	if events.size() > 0:
		var latest: Dictionary = events[0]
		if float(latest.get("life",0)) > 0.0:
			_rect(18,912,682,43,Color("#082b40ef"))
			_text(str(latest.get("message","")).substr(0,65),Vector2(29,941),18,Color("#ffe5aa"),false,655)

func _draw_footer() -> void:
	_rect(0,961,720,100,Color("#091b2c"))
	draw_line(Vector2(0,962),Vector2(720,962),Color("#43cab9"),3)
	var seconds := int(ceil(float(state.get("seconds"))))
	var urgent := seconds <= 32 and str(state.get("status"))=="RUNNING"
	_text("DERNIERES SECONDES ! AGIS !" if urgent else "SAUVEZ LE VILLAGE ENSEMBLE !",Vector2(26,1001),26,Color("#ffba93") if urgent else Color("#fff1c6"))
	_text("MATERIAUX  %d" % int(state.get("wood")),Vector2(26,1040),19,Color("#b5f0d6"))
	var rank: Array[String] = state.call("ranking",2)
	if not rank.is_empty():
		_text("TOP  " + "   /   ".join(rank),Vector2(242,1040),17,Color("#cff7ec"),false,450)
	else:
		_text("!join  POUR APPARAITRE SUR LE CHANTIER",Vector2(230,1040),17,Color("#cff7ec"))

func _draw_result() -> void:
	_rect(42,342,636,463,Color("#06192af3"))
	_rect(42,342,636,6,Color("#ffd078"))
	var count := int(state.get("saved"))
	var total := int(state.get("target"))
	var success := count >= total
	_text("MISSION ACCOMPLIE !" if success else "MISSION TERMINEE",Vector2(60,418),38,Color("#a7ffdb") if success else Color("#ffdba3"),true,600)
	_text("%d / %d HABITANTS SAUVES" % [count,total],Vector2(60,486),29,Color("#f5fcff"),true,600)
	var stars := int(state.get("star_rating"))
	for i in range(3):
		var x := 280+float(i)*82.0
		var color := Color("#ffd77b") if i < stars else Color("#476071")
		_star(Vector2(x,551),28,color)
	_text("BRAVO A TOUS LES CONSTRUCTEURS",Vector2(70,635),21,Color("#c9dfec"),true,580)
	var leaders: Array = []
	var contributors: Dictionary = state.get("contribution")
	var order: Array = contributors.keys()
	order.sort_custom(func(a,b):return int(contributors[a])>int(contributors[b]))
	for i in range(mini(3,order.size())):
		leaders.append("@" + str(order[i]) + "  " + str(contributors[order[i]]))
	_text("   •   ".join(leaders) if not leaders.is_empty() else "DEMONSTRATION",Vector2(70,685),17,Color("#fff1b5"),true,580)
	_text("NOUVELLE MISSION DANS %d S" % int(ceil(float(state.get("result_seconds")))),Vector2(80,755),23,Color("#abf0e2"),true,560)

func _star(center: Vector2, radius: float, color: Color) -> void:
	var points: Array[Vector2] = []
	for i in range(10):
		var angle := -PI*0.5+float(i)*TAU/10.0
		var rad := radius if i%2==0 else radius*0.44
		points.append(center+Vector2(cos(angle),sin(angle))*rad)
	_poly(points,color)

func _visual_event(event: Dictionary) -> void:
	var kind := str(event.get("kind",""))
	var focus := Vector2(BRIDGE_LEFT+float(state.get("progress"))/100.0*(BRIDGE_RIGHT-BRIDGE_LEFT),BRIDGE_Y-8)
	var tint := Color("#ffe08a")
	var count := 0
	match kind:
		"build":
			count = 14
			tint = Color("#ffe0a3")
		"repair":
			count = 15
			tint = Color("#85ffcd")
		"gift", "power":
			count = 30
			tint = Color("#f5d581")
		"success":
			count = 34
			tint = Color("#98ffda")
		"danger":
			count = 35
			tint = Color("#fc7676")
			shake = 0.5
		"join":
			count = 14
			tint = Color("#c6eaff")
		_:
			return
	if kind == "success":
		focus = Vector2(560,BRIDGE_Y-23)
	if kind == "danger":
		focus = Vector2(385,BRIDGE_Y+20)
	for i in range(count):
		if fx.size() >= 135:
			fx.pop_front()
		fx.append({
			"pos":focus+Vector2(randf_range(-28,28),randf_range(-22,25)),
			"velocity":Vector2(randf_range(-100,100),randf_range(-160,-50)),
			"time":randf_range(0.40,0.90),
			"size":randf_range(2.5,6.5),
			"color":tint
		})

func _draw_fx() -> void:
	for item in fx:
		var alpha := clampf(float(item["time"])*1.6,0.0,1.0)
		var color: Color = item["color"]
		color.a = alpha
		draw_circle(item["pos"],float(item["size"]),color)
		draw_line(item["pos"],item["pos"]+Vector2(0,8),Color(color.r,color.g,color.b,alpha*0.27),1.5)

func _draw_emergency_card() -> void:
	var seconds := int(ceil(float(state.get("seconds"))))
	var level := float(state.get("flood_level"))
	var warning := seconds <= 35 and str(state.get("status"))=="RUNNING"
	var card := Color("#491f2bdc") if warning else Color("#153a4add")
	_rect(24,310,672,83,card)
	_rect(24,310,7,83,Color("#ff8264") if warning else Color("#51d9c3"))
	_text("URGENCE : L'EAU MONTE !" if warning else "LA CRUE APPROCHE • BESOIN DE VOUS",Vector2(42,347),24,Color("#ffe1a0"))
	_text("NIVEAU DE CRUE",Vector2(43,376),16,Color("#afdddf"))
	_rect(218,362,445,15,Color("#264453"))
	_rect(218,362,445*level,15,Color("#fa7e68") if warning else Color("#62c5cf"))
	if str(state.get("status"))=="RUNNING" and int(state.get("weather_stage"))>0:
		_text("TEMPETE %d/3" % int(state.get("weather_stage")),Vector2(505,347),17,Color("#ffb9ad"))
	_rect(24,397,672,39,Color("#081e33da"))
	if int(clock/6.0)%2 == 0:
		_text("VOTE 1 : PILIERS   2 : GRUE   3 : EVACUATION",Vector2(40,425),17,Color("#a5f6de"))
	else:
		_text("CADEAUX : ROSE +4  •  DOUGHNUT +40  •  GALAXY +120",Vector2(40,425),17,Color("#ffdcac"))

func _draw_bridge_detail() -> void:
	var completion := float(state.get("progress"))/100.0
	var passed := BRIDGE_LEFT+(BRIDGE_RIGHT-BRIDGE_LEFT)*completion
	# Eclairage chaleureux du pont et cordages en perspective.
	draw_line(Vector2(BRIDGE_LEFT-18,BRIDGE_Y-48),Vector2(BRIDGE_RIGHT+18,BRIDGE_Y-47),Color("#cfded7"),3.1)
	for i in range(10):
		var x := BRIDGE_LEFT+float(i)*((BRIDGE_RIGHT-BRIDGE_LEFT)/9.0)
		var built := x <= passed
		var rail_color := Color("#ffcf81") if built else Color("#708c9d")
		draw_line(Vector2(x,BRIDGE_Y-47),Vector2(x,BRIDGE_Y+6),rail_color,3.0 if built else 1.5)
		if built:
			draw_circle(Vector2(x,BRIDGE_Y-45),3.4,Color("#ffe8ab"))
	# Eclaboussures sous les supports.
	for i in range(8):
		var x := BRIDGE_LEFT+float(i)*50.0
		var ripple := 11.0+sin(clock*2.4+float(i))*5.0
		draw_arc(Vector2(x,BRIDGE_Y+106),ripple,0.0,PI,13,Color(0.70,0.98,1.0,0.19),1.8)
	# Une vague gagne du terrain a mesure que le chrono avance.
	var flood := float(state.get("flood_level"))
	var swell := 12.0+flood*48.0+sin(clock*2.7)*5.0
	draw_arc(Vector2(410,BRIDGE_Y+174-flood*52.0),swell,PI,TAU,25,Color(0.76,0.98,1.0,0.20+flood*0.32),5.0)

func _load_preferences() -> void:
	# Uniquement un pseudonyme public ; aucun mot de passe, cookie ou jeton.
	var config := ConfigFile.new()
	if config.load("user://mission_settings.cfg") != OK:
		return
	var name := str(config.get_value("startup","tiktok_username","")).strip_edges().trim_prefix("@")
	if name.is_empty():
		return
	live_name.text = name
	if bool(config.get_value("startup","auto_live",false)):
		saved_live_name = name
		if game_mode != "LIVE":
			_switch_mode()
		banner = "RECONNEXION AU LIVE : @" + name
		banner_life = 3.0

func _save_preferences(auto_live: bool) -> void:
	var config := ConfigFile.new()
	config.set_value("startup","tiktok_username",live_name.text.strip_edges().trim_prefix("@"))
	config.set_value("startup","auto_live",auto_live)
	config.save("user://mission_settings.cfg")
