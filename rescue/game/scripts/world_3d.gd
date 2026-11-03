extends Node3D
## Monde 3D procedurally constructed — visible 360-degree camera and attributed crews.
## Workers are represented only by real joined users when live_mode is enabled.
const MAX_RENDERED_WORKERS := 48
const PLANK_COUNT := 15
const SITE_COLORS := [Color("#29a6a7"), Color("#d3ae76"), Color("#d9e1b8")]
const SKIN := [Color("#f6d2ac"), Color("#d4a176"), Color("#8f573b"), Color("#674331"), Color("#ebbb90")]
const UNIFORMS := [Color("#eb8c45"), Color("#efb73e"), Color("#4db8a7"), Color("#db6a52"), Color("#5d9fca")]

var state: RefCounted
var live_mode := false
var terrain: Node3D
var camera: Camera3D
var sunlight: DirectionalLight3D
var water: MeshInstance3D
var segments: Array[Node3D] = []
var cranes: Array[Node3D] = []
var clouds: Array[Node3D] = []
var boats: Array[Node3D] = []
var roof_parts: Array[MeshInstance3D] = []
var actors: Dictionary = {}
var focus_user := ""
var clock := 0.0
var orbit_angle := -0.6
var orbit_enabled := true
var spotlight_time := 0.0
var source_mission := ""
var surprise_time := 0.0
var dust: Array[MeshInstance3D] = []
var shaders: Dictionary = {}
var recent_actions: Array[Dictionary] = []
var last_status := ""
var last_saved := 0
var last_event := 0
var total_spawned := 0
var water_foam: Array[MeshInstance3D] = []
var roster_clock := 0.0
var cached_roster_size := 0

func initialize(model: RefCounted, is_live: bool) -> void:
	state = model
	live_mode = is_live
	_setup_environment()
	_rebuild_world()
	set_process(true)

func set_live(is_live: bool) -> void:
	live_mode = is_live
	for user in actors.keys():
		if not is_live:
			var a: Dictionary = actors[user]
			var worker: Node3D = a["rig"]
			worker.queue_free()
	actors.clear()
	last_event = 0
	last_saved = 0
	_rebuild_world()

func _setup_environment() -> void:
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("#95cadd")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#e1eff0")
	sky.ambient_light_energy = 0.83
	var env := WorldEnvironment.new()
	env.environment = sky
	add_child(env)
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-43, -42, -10)
	sunlight.light_color = Color("#ffe5bd")
	sunlight.light_energy = 1.65
	sunlight.shadow_enabled = true
	add_child(sunlight)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 69.0
	camera.near = 0.1
	camera.far = 190.0
	add_child(camera)
	orbit_enabled = true

func _material(tint: Color, metallic: float = 0.0, roughness: float = 0.85, glass: bool = false) -> StandardMaterial3D:
	var key := tint.to_html() + ":" + str(metallic) + ":" + str(roughness) + ":" + str(glass)
	if shaders.has(key):
		return shaders[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = metallic
	mat.roughness = roughness
	if glass:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	shaders[key] = mat
	return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, tint: Color, metallic: float = 0.0) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = _material(tint,metallic)
	parent.add_child(item)
	return item

func _ball(parent: Node3D, pos: Vector3, radius: float, tint: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	item.mesh = mesh
	item.position = pos
	item.material_override = _material(tint)
	parent.add_child(item)
	return item

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, tint: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	item.mesh = mesh
	item.position = pos
	item.material_override = _material(tint)
	parent.add_child(item)
	return item

func _rebuild_world() -> void:
	if state == null:
		return
	var name: String = str(state.call("scenario_info").get("id","bridge"))
	source_mission = name
	if terrain != null:
		terrain.free()
	terrain = Node3D.new()
	terrain.name = "Landscape_" + name
	add_child(terrain)
	actors.clear()
	segments.clear()
	clouds.clear()
	cranes.clear()
	boats.clear()
	roof_parts.clear()
	water_foam.clear()
	last_event = 0
	last_saved = 0
	# Generous terrain so full orbit never reveals a void.
	_box(terrain,Vector3(0,-2.4,0),Vector3(52,2.5,48),Color("#4b805d"))
	_box(terrain,Vector3(-15.0,-0.85,0),Vector3(19,1.25,39),Color("#71a06a"))
	_box(terrain,Vector3(15.0,-0.85,0),Vector3(19,1.25,39),Color("#6b9b66"))
	water = _box(terrain,Vector3(0,-0.68,0),Vector3(11.5,0.18,42),Color("#257a98"))
	# Riverbanks and rocks, with small irregular geometry.
	for i in range(24):
		var z := -18.0 + float(i)*1.6
		var left := -5.9 + sin(float(i)*1.8)*0.35
		var right := 5.9 + cos(float(i)*2.1)*0.35
		_ball(terrain,Vector3(left,-0.31,z),randf_range(0.35,0.82),Color("#647c6b"))
		_ball(terrain,Vector3(right,-0.31,z),randf_range(0.35,0.82),Color("#70867a"))
	for i in range(18):
		var x := -22.0 + float(i%6)*2.4
		var z := -15.0 + float(i/6)*9.4
		_tree(Vector3(x,0.0,z),0.78 + float(i%4)*0.12)
	for i in range(18):
		var x := 10.1 + float(i%6)*2.1
		var z := -16.0 + float(i/6)*10.0
		_tree(Vector3(x,0.0,z),0.7 + float((i+2)%4)*0.14)
	for i in range(5):
		_house(Vector3(-15.5+float(i%2)*4.0,0,-12.0+float(i)*5.0),0.8+float(i%2)*0.15)
	for i in range(4):
		_house(Vector3(12.6+float(i%2)*3.0,0,-11.0+float(i)*7),0.93)
	# Paths, lights and a refuge.
	_box(terrain,Vector3(-10.5,0.04,0),Vector3(8.9,0.1,3.1),Color("#c8b6a0"))
	_box(terrain,Vector3(10.6,0.04,0),Vector3(9.4,0.1,3.1),Color("#cfbda1"))
	_box(terrain,Vector3(13.0,0.14,-5),Vector3(4.4,0.25,6.8),Color("#dbd0ab"))
	_cylinder(terrain,Vector3(12.3,2.1,-5),0.08,4.2,Color("#dae5df"))
	_ball(terrain,Vector3(12.3,4.4,-5),0.33,Color("#ffeaa8"))
	for i in range(4):
		var cloud := Node3D.new()
		terrain.add_child(cloud)
		cloud.position = Vector3(-21+float(i)*11,10+float(i%2)*2,-13+float(i%3)*12)
		for j in range(4):
			_ball(cloud,Vector3(float(j)*1.3,0.2*sin(float(j)),float(j%2)*0.75),1.8+float(j%2)*0.5,Color("#f0f4ed"))
		clouds.append(cloud)
	match name:
		"dike":
			_build_dike()
		"lighthouse":
			_build_lighthouse()
		_:
			_build_bridge()
	_build_crane()
	_build_boats()
	_update_segments(float(state.get("progress")))
	_sync_workers()

func _tree(pos: Vector3, scale_factor: float) -> void:
	var tree := Node3D.new()
	terrain.add_child(tree)
	tree.position = pos
	tree.scale = Vector3.ONE * scale_factor
	_cylinder(tree,Vector3(0,1.1,0),0.2,2.2,Color("#7b5840"))
	for i in range(4):
		_ball(tree,Vector3(sin(float(i)*TAU/4.0)*0.56,2.4+float(i%2)*0.38,cos(float(i)*TAU/4.0)*0.56),
			1.06,Color("#237e61") if i%2 else Color("#31976b"))

func _house(pos: Vector3, scale_factor: float) -> void:
	var house := Node3D.new()
	terrain.add_child(house)
	house.position = pos
	house.scale = Vector3.ONE * scale_factor
	_box(house,Vector3(0,1.2,0),Vector3(3.1,2.4,2.9),Color("#e5d2a8"))
	var roof := _box(house,Vector3(0,2.66,0),Vector3(3.65,0.5,3.45),Color("#b46851"))
	roof.rotation.z = 0.04
	_box(house,Vector3(-0.5,0.82,1.48),Vector3(0.67,1.5,0.09),Color("#845b49"))
	_box(house,Vector3(0.67,1.68,1.48),Vector3(0.78,0.72,0.1),Color("#6b9fbd"))
	_box(house,Vector3(0.67,1.68,1.56),Vector3(0.1,0.72,0.04),Color("#e5d2a8"))

func _build_bridge() -> void:
	# Real 3D gap with piers, articulated deck segments and side handrails.
	for x in [-6.9,6.9]:
		for z in [-1.5,1.5]:
			_cylinder(terrain,Vector3(x,0.0,z),0.44,2.6,Color("#718381"))
			_ball(terrain,Vector3(x,1.45,z),0.48,Color("#f4c985"))
	for j in range(PLANK_COUNT):
		var x := -7.0 + float(j)*1.0
		var plank := Node3D.new()
		terrain.add_child(plank)
		plank.position = Vector3(x,1.17,0)
		_box(plank,Vector3.ZERO,Vector3(0.98,0.22,3.1),Color("#bf8352"))
		for z in [-1.36,1.36]:
			_box(plank,Vector3(0,0.36,z),Vector3(0.16,0.8,0.16),Color("#e4d19c"))
			_box(plank,Vector3(0,0.8,z),Vector3(0.96,0.14,0.12),Color("#d8c39b"))
		segments.append(plank)
	# Steel trusses show this as a load-bearing bridge rather than flat tiles.
	for z in [-1.5,1.5]:
		_box(terrain,Vector3(0,0.38,z),Vector3(14.8,0.15,0.18),Color("#7f9192"),0.45)
	for j in range(6):
		_cylinder(terrain,Vector3(-5.8+float(j)*2.3,-0.45,1.8),0.2,1.25,Color("#789092"))
	_box(terrain,Vector3(-9.0,0.5,0),Vector3(3.6,0.5,4.2),Color("#ae9671"))
	_box(terrain,Vector3(9.0,0.5,0),Vector3(3.6,0.5,4.2),Color("#ae9671"))

func _build_dike() -> void:
	# A storm barrier is physically built across the central flood channel.
	for j in range(PLANK_COUNT):
		var z := -7.0 + float(j)*1.0
		var wall := Node3D.new()
		wall.position = Vector3(0,0.1,z)
		terrain.add_child(wall)
		_box(wall,Vector3.ZERO,Vector3(2.3,2.6,0.95),Color("#c4b19a"))
		_box(wall,Vector3(0,1.36,0),Vector3(2.5,0.24,0.98),Color("#f1d1a1"))
		segments.append(wall)
	_box(terrain,Vector3(8.0,0.13,0),Vector3(6.0,0.2,5.0),Color("#a2aa8d"))
	_box(terrain,Vector3(-8.0,0.11,0),Vector3(5.0,0.15,5.0),Color("#baaa89"))
	for j in range(9):
		var z := -10.5 + float(j)*2.5
		_ball(terrain,Vector3(3.7,-0.32,z),0.4,Color("#9f9b89"))

func _build_lighthouse() -> void:
	# Reinforced tower, beacon and rotating light; boats cross a different route.
	_box(terrain,Vector3(0,0.0,0),Vector3(7.2,1.0,6.4),Color("#7a817c"))
	for j in range(PLANK_COUNT):
		var part := Node3D.new()
		terrain.add_child(part)
		part.position = Vector3(0,0.3 + float(j)*0.52,0)
		var taper := 1.0 - float(j)*0.019
		_cylinder(part,Vector3.ZERO,1.32*taper,0.5,Color("#e3ded1") if j%2==0 else Color("#d2a18c"))
		if j%3 == 0:
			_box(part,Vector3(0,0,1.37*taper),Vector3(0.36,0.23,0.12),Color("#5a9aa6"))
		segments.append(part)
	_cylinder(terrain,Vector3(0,8.35,0),1.55,0.3,Color("#4e6770"))
	_ball(terrain,Vector3(0,8.85,0),0.75,Color("#f6dc86"))
	_cylinder(terrain,Vector3(0,9.42,0),1.7,0.3,Color("#b96855"))

func _build_crane() -> void:
	var crane := Node3D.new()
	terrain.add_child(crane)
	crane.position = Vector3(-10.0,0.1,5.2)
	_box(crane,Vector3(0,2.7,0),Vector3(0.55,5.4,0.55),Color("#eac05d"))
	_box(crane,Vector3(2.5,5.4,0),Vector3(5.6,0.34,0.35),Color("#f4c85f"))
	_box(crane,Vector3(4.8,3.9,0),Vector3(0.07,3.0,0.08),Color("#edf3e6"))
	_box(crane,Vector3(4.8,2.4,0),Vector3(0.67,0.65,0.63),Color("#b2c3b4"))
	cranes.append(crane)

func _build_boats() -> void:
	for i in range(4):
		var ship := Node3D.new()
		terrain.add_child(ship)
		ship.position = Vector3(-6.1,-0.1,-3.0+float(i)*2.0)
		_box(ship,Vector3.ZERO,Vector3(1.6,0.34,0.8),Color("#b78d5a"))
		_cylinder(ship,Vector3(0,0.8,0),0.04,1.6,Color("#e8ddd0"))
		_box(ship,Vector3(0.25,0.93,0),Vector3(0.5,0.72,0.06),Color("#f2e5c9"))
		ship.visible = false
		boats.append(ship)

func _update_segments(completion: float) -> void:
	var count := int(ceil(clampf(completion,0.0,100.0)/100.0*float(PLANK_COUNT)))
	for index in range(segments.size()):
		segments[index].visible = index < count

func _worker(name: String) -> Dictionary:
	var rig := Node3D.new()
	terrain.add_child(rig)
	rig.name = "Worker_" + name.substr(0,15)
	var u_hash := absi(name.hash())
	var skin_color: Color = SKIN[u_hash % SKIN.size()]
	var uniform: Color = UNIFORMS[u_hash % UNIFORMS.size()]
	# Safety boots, trousers, detailed vest, independent articulated arms and legs.
	_box(rig,Vector3(0,1.02,0),Vector3(0.62,0.84,0.40),uniform)
	_box(rig,Vector3(0,1.25,0.22),Vector3(0.58,0.09,0.055),Color("#fbe5a1"))
	_box(rig,Vector3(0,0.84,0.22),Vector3(0.58,0.07,0.055),Color("#fbe5a1"))
	_box(rig,Vector3(0,1.65,0),Vector3(0.24,0.26,0.25),skin_color)
	_ball(rig,Vector3(0,1.89,0),0.30,skin_color)
	_cylinder(rig,Vector3(0,2.13,0),0.34,0.23,Color("#f9d05c"))
	_box(rig,Vector3(0,2.01,0.20),Vector3(0.71,0.08,0.26),Color("#f7d05b"))
	for side in [-1.0,1.0]:
		_ball(rig,Vector3(side*0.10,1.91,0.275),0.034,Color("#273b4b"))
	var limbs: Dictionary = {}
	for side in ["left","right"]:
		var factor := -1.0 if side=="left" else 1.0
		var arm := Node3D.new()
		rig.add_child(arm)
		arm.position = Vector3(factor*0.39,1.40,0)
		_box(arm,Vector3(factor*0.045,-0.31,0),Vector3(0.21,0.67,0.25),uniform.darkened(0.1))
		_ball(arm,Vector3(factor*0.045,-0.67,0),0.115,skin_color)
		limbs[side+"_arm"] = arm
		var leg := Node3D.new()
		rig.add_child(leg)
		leg.position = Vector3(factor*0.17,0.7,0)
		_box(leg,Vector3(0,-0.23,0),Vector3(0.23,0.49,0.30),Color("#293e57"))
		_box(leg,Vector3(0,-0.53,0.08),Vector3(0.29,0.14,0.43),Color("#25313a"))
		limbs[side+"_leg"] = leg
	# Each active worker gets an identifier that follows the 3D rig and faces the camera.
	var tag := Label3D.new()
	rig.add_child(tag)
	tag.text = "@" + name.substr(0,15) if live_mode else "DEMO"
	tag.position = Vector3(0,2.68,0)
	tag.font_size = 46
	tag.pixel_size = 0.0043
	tag.modulate = Color("#ffffff")
	tag.outline_size = 8
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	limbs["rig"] = rig
	limbs["label"] = tag
	limbs["age"] = 0.0
	limbs["action_time"] = 0.0
	limbs["action"] = "idle"
	limbs["user"] = name
	limbs["last_used"] = clock
	limbs["slot"] = total_spawned % MAX_RENDERED_WORKERS
	total_spawned += 1
	rig.position = _worker_position(int(limbs["slot"]))
	return limbs

func _worker_position(slot: int) -> Vector3:
	var row := slot / 12
	var col := slot % 12
	var x := -18.0 + float(col)*0.9
	var z := 7.6 + float(row)*1.13
	return Vector3(x,0.13,z)

func _sync_workers() -> void:
	if state == null:
		return
	if not live_mode:
		for index in range(9):
			var demo := "DEMO" + str(index+1)
			if not actors.has(demo):
				actors[demo] = _worker(demo)
		return
	# Live never synthesizes a user. Existing contributors stay visible when
	# possible, while workers not in the render budget retain their game score.
	var members: Dictionary = state.get("participants")
	for name in members.keys():
		if actors.size() >= MAX_RENDERED_WORKERS:
			break
		if not actors.has(name):
			actors[name] = _worker(name)

func _ensure_visible(name: String) -> void:
	if name.is_empty() or (not live_mode and name != "DEMO"):
		return
	if live_mode and not state.get("participants").has(name):
		return
	if actors.has(name):
		return
	if actors.size() >= MAX_RENDERED_WORKERS:
		var to_replace := ""
		var oldest := INF
		for user in actors.keys():
			var age := float(actors[user].get("last_used",0.0))
			if age < oldest:
				oldest = age
				to_replace = str(user)
		if not to_replace.is_empty():
			(actors[to_replace]["rig"] as Node3D).queue_free()
			actors.erase(to_replace)
	actors[name] = _worker(name)

func record_event(event: Dictionary) -> void:
	if state == null:
		return
	var kind := str(event.get("kind",""))
	var name := str(event.get("user",""))
	if not live_mode:
		name = "DEMO" + str(randi_range(1,9))
	if name.is_empty() or kind not in ["join","build","repair","rescue","gift"]:
		if kind in ["danger","power"]:
			surprise_time = 3.0
		return
	_ensure_visible(name)
	if not actors.has(name):
		return
	var actor: Dictionary = actors[name]
	actor["action_time"] = 3.5
	actor["action"] = kind
	actor["last_used"] = clock
	focus_user = name
	spotlight_time = 3.5 if kind != "join" else 1.5
	if recent_actions.size() >= 18:
		recent_actions.pop_front()
	recent_actions.append({"user":name,"kind":kind,"at":clock})
	var label: Label3D = actor["label"]
	label.modulate = Color("#fff1b6") if kind=="gift" else Color("#ffffff")

func _animate_workers(delta: float) -> void:
	for user in actors.keys():
		var actor: Dictionary = actors[user]
		var rig: Node3D = actor["rig"]
		if not is_instance_valid(rig):
			continue
		actor["age"] = float(actor["age"])+delta
		var t := float(actor["age"])
		var remaining := maxf(0,float(actor["action_time"])-delta)
		actor["action_time"] = remaining
		var slot_pos := _worker_position(int(actor["slot"]))
		var target := slot_pos + Vector3(0,0.0,sin(t*0.5+float(actor["slot"]))*0.16)
		if remaining > 0.0:
			var work_x := -6.7+float(int(float(state.get("progress"))/100.0*14.0))
			if source_mission == "lighthouse":
				target = Vector3(-1.7,0.18,float(int(actor["slot"])%8)*0.6-2.4)
			elif source_mission == "dike":
				target = Vector3(-2.7,0.16,float(int(actor["slot"])%12)*0.72-4.0)
			else:
				target = Vector3(work_x-1.1,0.18,float(int(actor["slot"])%12)*0.54-3.1)
		rig.position = rig.position.lerp(target,minf(1.0,delta*2.9))
		rig.position.y += sin(t*7.2)*0.003 if remaining>0 else sin(t*1.3)*0.001
		var fighting := remaining > 0.0
		var swing := sin(t*(11.0 if fighting else 2.0))*(0.93 if fighting else 0.10)
		(actor["left_arm"] as Node3D).rotation.x = swing
		(actor["right_arm"] as Node3D).rotation.x = -swing*0.8
		(actor["left_leg"] as Node3D).rotation.x = -swing*0.35
		(actor["right_leg"] as Node3D).rotation.x = swing*0.35
		rig.rotation.y = lerp_angle(rig.rotation.y,0.6 if fighting else -0.25,minf(1.0,delta*2.0))

func _animate_rescues() -> void:
	var idx := 0
	for boat in boats:
		boat.visible = false
		var crossing: Array = state.get("crossings")
		if idx < crossing.size():
			var p := float(crossing[idx].get("p",0.0))
			boat.visible = true
			if source_mission == "lighthouse":
				boat.position = Vector3(-5.7+p*11.4,-0.19,2.4+float(idx)*1.4)
			else:
				boat.position = Vector3(-6.2+p*12.4,1.13,0.25+float(idx)*0.52)
			boat.rotation.y = -0.4 if source_mission == "lighthouse" else 0.0
		idx += 1

func _process(delta: float) -> void:
	if state == null:
		return
	var d := minf(0.1,delta)
	clock += d
	var name := str(state.call("scenario_info").get("id"))
	if name != source_mission:
		_rebuild_world()
	spotlight_time = maxf(0.0,spotlight_time-d)
	surprise_time = maxf(0.0,surprise_time-d)
	if orbit_enabled:
		orbit_angle = fposmod(orbit_angle+d*TAU/39.0,TAU)
	var radius := 25.0
	var desired := Vector3(sin(orbit_angle)*radius,9.2+sin(clock*0.2)*0.4,cos(orbit_angle)*radius)
	var target := Vector3(0,1.2,0)
	if spotlight_time > 0 and focus_user != "" and actors.has(focus_user):
		var focus: Node3D = actors[focus_user]["rig"]
		if is_instance_valid(focus):
			# Close-up in which the real author's visible worker performs the action.
			target = target.lerp(focus.position+Vector3(0,1.0,0),0.55)
			desired = desired.lerp(focus.position+Vector3(10,6.8,13),0.32)
	camera.position = camera.position.lerp(desired,minf(1.0,d*1.25))
	camera.look_at(target,Vector3.UP)
	if water != null:
		var flood := float(state.get("flood_level"))
		water.position.y = -0.68 + flood*0.52 + sin(clock*1.8)*0.08
		water.scale.z = 1.0+flood*0.15
	for index in range(clouds.size()):
		clouds[index].position.x += d*(0.35+float(index)*0.04)
		if clouds[index].position.x > 28:
			clouds[index].position.x = -27
	for index in range(cranes.size()):
		cranes[index].rotation.y = sin(clock*0.35)*0.13
	_update_segments(float(state.get("progress")))
	roster_clock += d
	var roster_size: int = int(state.get("participants").size())
	if roster_clock > 1.0 or roster_size != cached_roster_size:
		roster_clock = 0.0
		cached_roster_size = roster_size
		_sync_workers()
	_animate_workers(d)
	_animate_rescues()

func visible_workers() -> int:
	return actors.size()

func live_participants() -> int:
	return int(state.get("participants").size()) if state != null else 0

func camera_turn_degrees() -> float:
	return rad_to_deg(orbit_angle)

func camera_mode_next() -> void:
	orbit_enabled = not orbit_enabled
