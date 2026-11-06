extends Node3D
const Routes = preload("res://scripts/rescue_routes_3d.gd")
## Monde 3D procedurally constructed — visible 360-degree camera and attributed crews.
## Workers are represented only by real joined users when live_mode is enabled.
const MAX_RENDERED_WORKERS := 48
const MAX_DETAILED_WORKERS := 18
const MAX_WORK_SPARKS := 64
const PLANK_COUNT := 15
const SITE_COLORS := [Color("#29a6a7"), Color("#d3ae76"), Color("#d9e1b8")]
const SKIN := [Color("#f6d2ac"), Color("#d4a176"), Color("#8f573b"), Color("#674331"), Color("#ebbb90")]
const UNIFORMS := [Color("#eb8c45"), Color("#efb73e"), Color("#4db8a7"), Color("#db6a52"), Color("#5d9fca")]

var state: RefCounted
var live_mode := false
var terrain: Node3D
var civilians: Node3D
var rain: Array[MeshInstance3D] = []
var light_refuge: OmniLight3D
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
var rescue_focus_time := 0.0
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
var work_sparks: Array[Dictionary] = []
var rescue_helicopter: Node3D
var rescue_rotor: Node3D
var camera_focus: Vector3 = Vector3.ZERO
var lod_clock := 0.0
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
	sky.background_color = Color("#779eb3")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#c4d9db")
	sky.ambient_light_energy = 0.63
	var env := WorldEnvironment.new()
	env.environment = sky
	add_child(env)
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-43, -42, -10)
	sunlight.light_color = Color("#ffe5bd")
	sunlight.light_energy = 1.30
	sunlight.shadow_enabled = true
	add_child(sunlight)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 65.0
	camera.near = 0.15
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

func _collider(parent: Node3D, pos: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "StructureCollider"
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	return body

func _rebuild_world() -> void:
	if state == null:
		return
	var info: Dictionary = state.call("scenario_info")
	var name: String = str(info.get("id","bridge"))
	var site_type: String = str(info.get("site_type","bridge"))
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
	work_sparks.clear()
	rescue_helicopter = null
	rescue_rotor = null
	rain.clear()
	civilians = null
	# Avoid replaying old participants' work effects after a scene transition.
	# New authentic events continue with monotonically increasing event_id.
	last_event = int(state.get("event_id"))
	last_saved = int(state.get("saved"))
	# Generous terrain so full orbit never reveals a void.
	_box(terrain,Vector3(0,-2.4,0),Vector3(52,2.5,48),Color("#4b805d"))
	_box(terrain,Vector3(-15.0,-0.55,0),Vector3(19,1.25,39),Color("#688e64"))
	_box(terrain,Vector3(15.0,-0.55,0),Vector3(19,1.25,39),Color("#64895e"))
	# Static collision banks do not depend on render visibility.
	_collider(terrain,Vector3(-15.0,-0.55,0),Vector3(19,1.25,39))
	_collider(terrain,Vector3(15.0,-0.55,0),Vector3(19,1.25,39))
	water = _box(terrain,Vector3(0,-0.68,0),Vector3(11.5,0.18,42),Color("#286d83"))
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
	match site_type:
		"dike":
			_build_dike()
		"lighthouse":
			_build_lighthouse()
		"dam":
			_build_dam()
		"helipad":
			_build_helipad()
		_:
			_build_bridge()
	_build_crane()
	_build_boats()
	_build_environment_details()
	_build_rescue_camps()
	civilians = load("res://scripts/villagers_3d.gd").new()
	terrain.add_child(civilians)
	civilians.call("setup",state,site_type)
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
		_collider(plank,Vector3.ZERO,Vector3(0.98,0.27,3.1))
		for z in [-1.36,1.36]:
			_box(plank,Vector3(0,0.36,z),Vector3(0.16,0.8,0.16),Color("#e4d19c"))
			_box(plank,Vector3(0,0.8,z),Vector3(0.96,0.14,0.12),Color("#d8c39b"))
		segments.append(plank)
	# Steel trusses show this as a load-bearing bridge rather than flat tiles.
	for z in [-1.5,1.5]:
		_box(terrain,Vector3(0,0.38,z),Vector3(14.8,0.15,0.18),Color("#7f9192"),0.45)
		# Physics fences keep evacuated pedestrians inside the bridge deck.
		_add_rail_collider(Vector3(0,1.59,z*1.13),Vector3(15.4,0.63,0.18))
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
		_collider(wall,Vector3.ZERO,Vector3(2.3,2.6,0.95))
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
		_collider(part,Vector3.ZERO,Vector3(2.64*taper,0.5,2.64*taper))
		if j%3 == 0:
			_box(part,Vector3(0,0,1.37*taper),Vector3(0.36,0.23,0.12),Color("#5a9aa6"))
		segments.append(part)
	_cylinder(terrain,Vector3(0,8.35,0),1.55,0.3,Color("#4e6770"))
	_ball(terrain,Vector3(0,8.85,0),0.75,Color("#f6dc86"))
	_cylinder(terrain,Vector3(0,9.42,0),1.7,0.3,Color("#b96855"))

func _build_dam() -> void:
	# Dam with physical gates and vertical maintenance modules, 3D river gorge.
	for j in range(PLANK_COUNT):
		var section := Node3D.new()
		terrain.add_child(section)
		section.position = Vector3(0.0,-0.45,-7.0+float(j)*1.0)
		_box(section,Vector3(0,0.9,0),Vector3(2.3,3.5,0.96),Color("#9babb0"))
		_collider(section,Vector3(0,0.9,0),Vector3(2.3,3.5,0.96))
		_box(section,Vector3(0,2.67,0),Vector3(2.8,0.3,1.0),Color("#c5c8c1"))
		segments.append(section)
	for k in range(5):
		var zz := -5.0+float(k)*2.5
		_cylinder(terrain,Vector3(-1.65,1.12,zz),0.2,4.3,Color("#6e747b"))
		_cylinder(terrain,Vector3(1.65,1.12,zz),0.2,4.3,Color("#6e747b"))
	_box(terrain,Vector3(3.5,0.14,7.8),Vector3(5.7,0.26,4.3),Color("#b2a996"))
	_box(terrain,Vector3(2.0,1.45,6.5),Vector3(2.4,2.7,1.9),Color("#bdcec8"))
	_box(terrain,Vector3(2.0,2.86,6.5),Vector3(2.8,0.22,2.1),Color("#4e6b79"))

func _build_helipad() -> void:
	# Rescue base with runway, two hangars and modular rescue staging platforms.
	_box(terrain,Vector3(-3.2,0.15,0),Vector3(14.2,0.25,14.4),Color("#728c82"))
	for j in range(PLANK_COUNT):
		var section := Node3D.new()
		terrain.add_child(section)
		section.position = Vector3(-7.2+float(j)*0.96,0.56,1.0)
		_box(section,Vector3.ZERO,Vector3(0.91,0.38,5.4),Color("#b8bba9"))
		_collider(section,Vector3.ZERO,Vector3(0.91,0.38,5.4))
		if j%3 == 0:
			_box(section,Vector3(0.0,0.25,-2.45),Vector3(0.45,0.08,0.44),Color("#f9d17a"))
		segments.append(section)
	for x in [-12.3,7.8]:
		_box(terrain,Vector3(x,1.7,-10.0),Vector3(4.6,3.1,5.1),Color("#b1c2bb"))
		_box(terrain,Vector3(x,3.32,-10.0),Vector3(5.2,0.32,5.7),Color("#bc7565"))
	# Clearly recognisable 3D helipad sign.
	_cylinder(terrain,Vector3(-1.9,0.42,3.4),3.05,0.12,Color("#c6bfb0"))
	_box(terrain,Vector3(-1.9,0.54,3.4),Vector3(3.4,0.05,0.44),Color("#f4e9c1"))
	_box(terrain,Vector3(-1.9,0.54,3.4),Vector3(0.48,0.05,2.8),Color("#f4e9c1"))
	var heli := Node3D.new()
	terrain.add_child(heli)
	heli.position = Vector3(-1.9,2.45,3.15)
	_ball(heli,Vector3.ZERO,1.1,Color("#e6b35e"))
	_box(heli,Vector3(1.5,0.2,0.0),Vector3(2.8,0.25,0.28),Color("#e0c17e"))
	_box(heli,Vector3(0,1.15,0),Vector3(5.4,0.08,0.15),Color("#e7e6d9"))
	_box(heli,Vector3(0,0.24,0),Vector3(0.15,0.35,4.2),Color("#ece9df"))
	heli.name = "RescueHelicopter"
	rescue_helicopter = heli
	var rotor := Node3D.new()
	rotor.name = "RescueRotor"
	heli.add_child(rotor)
	rotor.position = Vector3(0,1.20,0)
	_box(rotor,Vector3.ZERO,Vector3(5.8,0.055,0.18),Color("#dfe7df"))
	_box(rotor,Vector3.ZERO,Vector3(0.18,0.055,5.8),Color("#dfe7df"))
	rescue_rotor = rotor

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
	var site := str(state.call("scenario_info").get("site_type"))
	for i in range(4):
		var ship := Node3D.new()
		ship.name = "EvacuationBoat_%d" % i
		terrain.add_child(ship)
		ship.position = Vector3(-5.35,0.19,9.0)
		var rescue_color := Color("#e6ba77") if site=="lighthouse" else Color("#69b0a5")
		_box(ship,Vector3.ZERO,Vector3(2.05,0.38,1.32),Color("#9c765b"))
		_box(ship,Vector3(0,0.19,0),Vector3(1.86,0.10,1.10),Color("#b8a382"))
		for z in [-0.52,0.52]:
			_box(ship,Vector3(0,0.35,z),Vector3(1.9,0.43,0.10),rescue_color)
		_box(ship,Vector3(-0.73,0.35,0),Vector3(0.11,0.48,1.0),rescue_color)
		_box(ship,Vector3(0.73,0.35,0),Vector3(0.11,0.48,1.0),rescue_color)
		_box(ship,Vector3(-0.45,0.62,0),Vector3(0.09,0.78,0.08),Color("#eee8ca"))
		_ball(ship,Vector3(-0.45,1.02,0),0.16,Color("#efda9b"))
		ship.visible = false
		boats.append(ship)
	if site in ["dike","dam","lighthouse"]:
		var dock_z := 2.9 if site=="lighthouse" else 9.7
		for shore in [-1.0,1.0]:
			_box(terrain,Vector3(shore*6.65,0.27,dock_z),Vector3(1.92,0.18,3.0),Color("#c3a77f"))
			_box(terrain,Vector3(shore*6.7,0.70,dock_z-1.34),Vector3(0.09,0.82,0.10),Color("#a38a6e"))
			_box(terrain,Vector3(shore*6.7,0.70,dock_z+1.34),Vector3(0.09,0.82,0.10),Color("#a38a6e"))

func _update_segments(completion: float) -> void:
	var count := int(ceil(clampf(completion,0.0,100.0)/100.0*float(PLANK_COUNT)))
	for index in range(segments.size()):
		var built := index < count
		segments[index].visible = built
		var body := segments[index].get_node_or_null("StructureCollider") as StaticBody3D
		if body != null:
			body.collision_layer = 1 if built else 0

func _worker(name: String) -> Dictionary:
	var rig: CharacterBody3D = load("res://scripts/character_motor_3d.gd").new()
	terrain.add_child(rig)
	rig.call("configure",4,0.255,1.73)
	var model_root := Node3D.new()
	model_root.name = "WorkerAppearance"
	rig.add_child(model_root)
	rig.name = "Worker_" + name.substr(0,15)
	var u_hash := absi(name.hash())
	var skin_color: Color = SKIN[u_hash % SKIN.size()]
	var uniform: Color = UNIFORMS[u_hash % UNIFORMS.size()]
	var helmet_color := Color("#ffcb51") if u_hash % 3 == 0 else (Color("#edebdf") if u_hash % 3 == 1 else Color("#eaa54d"))
	model_root.scale = Vector3(0.94+float(u_hash%5)*0.02,0.95+float(int(u_hash/5)%5)*0.021,1.0)
	# Safety boots, trousers, detailed vest, independent articulated arms and legs.
	_box(model_root,Vector3(0,1.02,0),Vector3(0.62,0.84,0.40),uniform)
	_box(model_root,Vector3(0,1.25,0.22),Vector3(0.58,0.09,0.055),Color("#fbe5a1"))
	_box(model_root,Vector3(0,0.84,0.22),Vector3(0.58,0.07,0.055),Color("#fbe5a1"))
	# Reflective safety vest, chest zipper, utility belt and radio badge.
	_box(model_root,Vector3(0,1.03,0.232),Vector3(0.04,0.67,0.04),Color("#efe8c5"))
	_box(model_root,Vector3(0,0.65,0),Vector3(0.68,0.17,0.47),Color("#56483c"))
	_box(model_root,Vector3(-0.19,0.65,0.266),Vector3(0.22,0.18,0.13),Color("#96795a"))
	_box(model_root,Vector3(0.21,1.28,0.258),Vector3(0.15,0.12,0.045),Color("#f7efe1"))
	_box(model_root,Vector3(0,1.65,0),Vector3(0.24,0.26,0.25),skin_color)
	_ball(model_root,Vector3(0,1.89,0),0.30,skin_color)
	_cylinder(model_root,Vector3(0,2.13,0),0.34,0.23,helmet_color)
	_box(model_root,Vector3(0,2.01,0.20),Vector3(0.71,0.08,0.26),helmet_color)
	_box(model_root,Vector3(0,2.22,0.0),Vector3(0.15,0.055,0.51),helmet_color.lightened(0.2))
	# Chin strap and facial features for a less toy-like worker silhouette.
	_box(model_root,Vector3(0,1.69,0.0),Vector3(0.038,0.12,0.41),Color("#575551"))
	_ball(model_root,Vector3(0,1.87,0.285),0.045,skin_color.darkened(0.1))
	_box(model_root,Vector3(0,1.765,0.286),Vector3(0.12,0.028,0.028),Color("#85544a"))
	for side in [-1.0,1.0]:
		_ball(model_root,Vector3(side*0.10,1.91,0.275),0.034,Color("#273b4b"))
	var limbs: Dictionary = {}
	for side in ["left","right"]:
		var factor := -1.0 if side=="left" else 1.0
		var arm := Node3D.new()
		model_root.add_child(arm)
		arm.position = Vector3(factor*0.39,1.40,0)
		_box(arm,Vector3(factor*0.045,-0.31,0),Vector3(0.21,0.67,0.25),uniform.darkened(0.1))
		_ball(arm,Vector3(factor*0.045,-0.67,0),0.115,Color("#d5bd90"))
		_box(arm,Vector3(factor*0.045,-0.48,0.14),Vector3(0.19,0.085,0.07),Color("#d9d9ca"))
		if side == "right":
			var hand_tool := Node3D.new()
			arm.add_child(hand_tool)
			hand_tool.position = Vector3(factor*0.045,-0.76,0.2)
			_cylinder(hand_tool,Vector3(0,-0.22,0),0.041,0.63,Color("#7c5f45"))
			if u_hash%3 == 0:
				_box(hand_tool,Vector3(0,-0.52,0),Vector3(0.34,0.13,0.12),Color("#9eafb0"))
			elif u_hash%3 == 1:
				_box(hand_tool,Vector3(0,-0.49,0),Vector3(0.20,0.17,0.17),Color("#adb9bd"))
				_box(hand_tool,Vector3(0.09,-0.39,0),Vector3(0.08,0.11,0.10),Color("#c5cbca"))
			else:
				_box(hand_tool,Vector3(0,-0.49,0),Vector3(0.32,0.09,0.10),Color("#b6bab3"))
				_box(hand_tool,Vector3(0.13,-0.45,0),Vector3(0.08,0.17,0.11),Color("#a2b5b8"))
			hand_tool.visible = false
			limbs["tool"] = hand_tool
		limbs[side+"_arm"] = arm
		var leg := Node3D.new()
		model_root.add_child(leg)
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
	var action_tag := Label3D.new()
	rig.add_child(action_tag)
	action_tag.text = ""
	action_tag.visible = false
	action_tag.position = Vector3(0,3.16,0)
	action_tag.font_size = 52
	action_tag.pixel_size = 0.0047
	action_tag.modulate = Color("#fff0a5")
	action_tag.outline_size = 9
	action_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var low_detail := Node3D.new()
	low_detail.name = "DistantCrewSilhouette"
	rig.add_child(low_detail)
	_box(low_detail,Vector3(0,1.0,0),Vector3(0.59,0.82,0.35),uniform)
	_ball(low_detail,Vector3(0,1.84,0),0.27,skin_color)
	_box(low_detail,Vector3(0,2.06,0),Vector3(0.62,0.22,0.34),helmet_color)
	for leg_x in [-0.17,0.17]:
		_box(low_detail,Vector3(leg_x,0.36,0),Vector3(0.23,0.70,0.24),Color("#35445b"))
	low_detail.visible = false
	limbs["lod"] = low_detail
	limbs["rig"] = rig
	limbs["visual"] = model_root
	limbs["label"] = tag
	limbs["action_tag"] = action_tag
	limbs["age"] = 0.0
	limbs["action_time"] = 0.0
	limbs["action"] = "idle"
	limbs["user"] = name
	limbs["last_used"] = clock
	limbs["slot"] = total_spawned % MAX_RENDERED_WORKERS
	total_spawned += 1
	# Limit skinned rigs to one worker in six. Others use the lightweight fallback.
	# This keeps the render predictable with up to 48 simultaneously visible workers.
	if int(limbs["slot"]) % 6 == 0:
		var avatar := load("res://scripts/rigged_humanoid.gd").new() as Node3D
		rig.add_child(avatar)
		if bool(avatar.call("setup",1.16)):
			# Only the fallback model disappears: the skinned human and the
			# player's nameplate remain visible as siblings under the rig.
			model_root.visible = false
			var equipment := Node3D.new()
			equipment.name = "PPE_Equipment"
			rig.add_child(equipment)
			_cylinder(equipment,Vector3(0,2.03,0),0.31,0.19,helmet_color)
			_box(equipment,Vector3(0,1.96,0.20),Vector3(0.65,0.09,0.25),helmet_color)
			_box(equipment,Vector3(-0.25,1.24,0.24),Vector3(0.075,0.67,0.075),Color("#ffe7a0"))
			_box(equipment,Vector3(0.25,1.24,0.24),Vector3(0.075,0.67,0.075),Color("#ffe7a0"))
			_box(equipment,Vector3(0,0.91,0.25),Vector3(0.54,0.065,0.06),Color("#ffe7a0"))
			limbs["avatar"] = avatar
			limbs["equipment"] = equipment
			tag.position.y = 2.49
			action_tag.position.y = 2.96
		else:
			avatar.queue_free()
	rig.position = _worker_position(int(limbs["slot"]))
	return limbs

func _worker_position(slot: int) -> Vector3:
	# Keep the crew on the west bank, separate from the civilians' shelter.
	var row := int(slot / 6)
	var col := slot % 6
	return Vector3(-10.25+float(col)*0.71,0.13,-6.4+float(row)*1.55)

func _sync_workers() -> void:
	if state == null:
		return
	if not live_mode:
		for index in range(12):
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
	if name.is_empty() or kind not in ["join","build","repair","rescue","gift","power","success"]:
		if kind in ["danger","power"]:
			surprise_time = 3.0
		return
	_ensure_visible(name)
	if not actors.has(name):
		return
	var actor: Dictionary = actors[name]
	actor["action_time"] = 8.0 if kind=="rescue" else 3.5
	actor["action"] = kind
	var action_tag: Label3D = actor["action_tag"]
	action_tag.visible = kind != "join"
	var contribution_text := ""
	match kind:
		"build":
			contribution_text = "CONSTRUCTION !"
		"repair":
			contribution_text = "REPARATION !"
		"rescue":
			contribution_text = "SAUVETAGE !"
		"gift":
			contribution_text = "RENFORT !"
		"power":
			contribution_text = "ACTION SPECIALE !"
		"success":
			contribution_text = "SAUVETAGE REUSSI !"
	action_tag.text = contribution_text
	actor["last_used"] = clock
	if kind in ["build","repair","gift","power","rescue","success"]:
		_spawn_work_sparks(actor["rig"].position+Vector3(0,1.4,0),kind)
	if spotlight_time <= 0.4 or kind == "rescue":
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
		var escort: Dictionary = {}
		if str(actor["action"]) == "rescue":
			for passenger in state.get("crossings"):
				if (live_mode and str(passenger.get("rescuer","")) == str(user)) or (not live_mode and escort.is_empty()):
					escort = passenger
					break
		if not escort.is_empty():
			remaining = maxf(remaining,0.9)
		actor["action_time"] = remaining
		var tool: Node3D = actor["tool"]
		tool.visible = remaining > 0.0 and str(actor["action"]) in ["build","repair"] and not actor.has("avatar")
		var nametag: Label3D = actor["label"]
		nametag.visible = actors.size() <= 18 or remaining > 0.0 or user == focus_user
		var action_tag: Label3D = actor["action_tag"]
		action_tag.visible = remaining > 0.0 and str(actor["action"]) != "join"
		if action_tag.visible:
			action_tag.position.y = 3.16+sin(t*3.4)*0.08
		var slot_pos := _worker_position(int(actor["slot"]))
		var target := slot_pos + Vector3(sin(t*0.65+float(actor["slot"]))*0.13,0.0,cos(t*0.42+float(actor["slot"]))*0.15)
		if remaining > 0.0:
			var site := str(state.call("scenario_info").get("site_type"))
			var lane := float(int(actor["slot"])%7)
			var work_x := -6.7+float(int(float(state.get("progress"))/100.0*14.0))
			if str(actor["action"]) == "rescue":
				# The user's builder accompanies THEIR villager, not a random NPC.
				# At docks/helipads, the escort stays near boarding facilities.
				if site == "bridge" and not escort.is_empty() and civilians != null:
					var person_index := int(escort.get("person_index",-1))
					var civilian_pos: Vector3 = civilians.call("evacuee_position",person_index)
					target = civilian_pos+Vector3(-0.70,0.0,0.43)
				elif site in ["dike","dam"]:
					target = Vector3(-7.3,0.16,9.0+float(int(actor["slot"])%3)*0.69)
				elif site == "lighthouse":
					target = Vector3(-7.3,0.16,2.4+float(int(actor["slot"])%3)*0.69)
				elif site == "helipad":
					target = Vector3(-4.35,0.16,3.15+float(int(actor["slot"])%3)*0.34)
				else:
					target = Vector3(-8.3,0.16,lane*0.4-1.8)
			elif site == "lighthouse":
				target = Vector3(-1.7,0.18,lane*0.7-2.4)
			elif site == "dike" or site == "dam":
				target = Vector3(-2.7,0.16,lane*0.72-2.0)
			elif site == "helipad":
				target = Vector3(-5.4,0.16,lane*0.55-1.7)
			else:
				# Operate construction from a camera-visible bank staging lane.
				# Avoid walking into the river through nonexistent deck panels.
				target = Vector3(-8.65+float(int(actor["slot"])%4)*0.46,0.17,lane*0.47-1.62)
		var moved: Vector3 = rig.call("move_to",target,5.7 if remaining > 0.0 else 2.9,delta)
		var visual: Node3D = actor["visual"]
		visual.position.y = 0.018*sin(t*7.2) if remaining > 0.0 else 0.005*sin(t*1.3)
		var fighting := remaining > 0.0
		var walking := moved.length_squared() > 0.000003
		var swing := sin(t*(10.0 if fighting else (7.0 if walking else 2.0)))*(0.92 if fighting else (0.47 if walking else 0.07))
		(actor["left_arm"] as Node3D).rotation.x = swing
		(actor["right_arm"] as Node3D).rotation.x = -swing*0.8
		(actor["left_leg"] as Node3D).rotation.x = -swing*0.35
		(actor["right_leg"] as Node3D).rotation.x = swing*0.35
		if moved.length_squared() > 0.0001:
			rig.rotation.y = lerp_angle(rig.rotation.y,atan2(moved.x,moved.z),minf(1.0,delta*6.0))
		elif fighting:
			rig.rotation.y = lerp_angle(rig.rotation.y,0.3,minf(1.0,delta*2.0))
		if actor.has("avatar"):
			var avatar: Node3D = actor["avatar"]
			if is_instance_valid(avatar) and avatar.visible:
				var gait_state := str(actor["action"]) if fighting else ("walk" if walking else "idle")
				avatar.call("animate",delta,gait_state)

func _spawn_work_sparks(at: Vector3, kind: String) -> void:
	var color := Color("#f5d477") if kind in ["gift","power"] else (
		Color("#9bffde") if kind in ["rescue","success"] else Color("#ffe6b7"))
	for i in range(6):
		while work_sparks.size() >= MAX_WORK_SPARKS:
			var first: Dictionary = work_sparks.pop_front()
			var old: MeshInstance3D = first["mesh"]
			if is_instance_valid(old):
				old.queue_free()
		var jitter := Vector3(randf_range(-0.25,0.25),randf_range(-0.1,0.28),randf_range(-0.3,0.3))
		var particle := _ball(terrain,at+jitter,0.055,color)
		var vel := Vector3(randf_range(-1.6,1.6),randf_range(1.3,3.3),randf_range(-1.6,1.6))
		work_sparks.append({"mesh":particle,"velocity":vel,"age":0.0,"lifetime":0.64+randf_range(0.0,0.6)})

func _animate_work_sparks(delta: float) -> void:
	for entry in work_sparks.duplicate():
		var particle: MeshInstance3D = entry["mesh"]
		if not is_instance_valid(particle):
			work_sparks.erase(entry)
			continue
		entry["age"] = float(entry["age"])+delta
		if float(entry["age"]) >= float(entry["lifetime"]):
			particle.queue_free()
			work_sparks.erase(entry)
			continue
		var vel: Vector3 = entry["velocity"]
		vel.y -= delta*3.5
		particle.position += vel*delta
		entry["velocity"] = vel
		var fade := 1.0-clampf(float(entry["age"])/float(entry["lifetime"]),0.0,1.0)
		particle.scale = Vector3.ONE*maxf(0.08,fade)

func _update_worker_lod() -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var order: Array = actors.keys()
	order.sort_custom(func(a,b):
		var worker_a: Dictionary = actors[a]
		var worker_b: Dictionary = actors[b]
		var pos_a: Node3D = worker_a["rig"]
		var pos_b: Node3D = worker_b["rig"]
		var score_a := pos_a.position.distance_to(camera.position)
		var score_b := pos_b.position.distance_to(camera.position)
		if float(worker_a.get("action_time",0.0)) > 0.0:
			score_a -= 45.0
		if float(worker_b.get("action_time",0.0)) > 0.0:
			score_b -= 45.0
		if str(a) == focus_user:
			score_a -= 40.0
		if str(b) == focus_user:
			score_b -= 40.0
		return score_a < score_b
	)
	var detailed := 0
	for user in order:
		var actor: Dictionary = actors[user]
		var full := detailed < MAX_DETAILED_WORKERS
		if full:
			detailed += 1
		var fallback: Node3D = actor["visual"]
		fallback.visible = full and not actor.has("avatar")
		var low: Node3D = actor["lod"]
		low.visible = not full
		if actor.has("avatar"):
			var human: Node3D = actor["avatar"]
			if is_instance_valid(human):
				human.visible = full
			if actor.has("equipment"):
				var equipment: Node3D = actor["equipment"]
				equipment.visible = full

func _animate_rescues() -> void:
	var site := str(state.call("scenario_info").get("site_type"))
	var using_boats := site in ["lighthouse","dike","dam"]
	var active: Array = state.get("crossings")
	for i in range(boats.size()):
		var boat: Node3D = boats[i]
		boat.visible = using_boats and i < active.size()
		if boat.visible:
			var passenger: Dictionary = active[i]
			var progress := float(passenger.get("p",0.0))
			var lane := int(passenger.get("lane",0))
			boat.position = Routes.vehicle_position(site,progress,lane)
			boat.position.y += sin(clock*2.5+float(i))*0.035
			boat.rotation.y = 0.09*sin(clock*1.8+float(i))
	if rescue_helicopter != null and is_instance_valid(rescue_helicopter) and site=="helipad":
		var flying := false
		if not active.is_empty():
			var first: Dictionary = active[0]
			var p := float(first.get("p",0.0))
			var lane := int(first.get("lane",0))
			if p >= 0.15 and p <= 0.90:
				var flight_target: Vector3 = Routes.vehicle_position(site,p,lane)
				rescue_helicopter.position = rescue_helicopter.position.lerp(flight_target,0.16)
				flying = true
		if not flying:
			rescue_helicopter.position = rescue_helicopter.position.lerp(
				Vector3(-1.9,2.45+sin(clock*2.0)*0.05,3.15),0.04)

func _process(delta: float) -> void:
	if state == null:
		return
	var d := minf(0.1,delta)
	clock += d
	var name := str(state.call("scenario_info").get("id"))
	if name != source_mission:
		_rebuild_world()
	spotlight_time = maxf(0.0,spotlight_time-d)
	rescue_focus_time = maxf(0.0,rescue_focus_time-d)
	var saved_count := int(state.get("saved"))
	if saved_count > last_saved:
		rescue_focus_time = 2.6
		last_saved = saved_count
	surprise_time = maxf(0.0,surprise_time-d)
	if orbit_enabled:
		orbit_angle = fposmod(orbit_angle+d*TAU/39.0,TAU)
	var radius := 21.8
	var desired := Vector3(sin(orbit_angle)*radius,8.9+sin(clock*0.2)*0.35,cos(orbit_angle)*radius)
	var target := Vector3(0,1.55,0)
	if civilians != null and is_instance_valid(civilians) and int(civilians.call("movement_count")) > 0 and spotlight_time <= 0.0:
		var active_rescue: Vector3 = civilians.call("first_in_transit_position")
		target = target.lerp(active_rescue+Vector3(0,0.7,0),0.45)
		desired = desired.lerp(active_rescue+Vector3(9.0,7.0,11.0),0.23)
	if spotlight_time > 0 and focus_user != "" and actors.has(focus_user):
		var focus: Node3D = actors[focus_user]["rig"]
		if is_instance_valid(focus):
			# Close-up in which the real author's visible worker performs the action.
			target = target.lerp(focus.position+Vector3(0,1.0,0),0.55)
			desired = desired.lerp(focus.position+Vector3(10,6.8,13),0.32)
	if rescue_focus_time > 0.0 and civilians != null and is_instance_valid(civilians):
		var rescue_pos: Vector3 = civilians.call("last_rescued_position")
		target = target.lerp(rescue_pos+Vector3(0,1.5,0),0.56)
		desired = desired.lerp(rescue_pos+Vector3(6.8,5.9,10.0),0.35)
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
	lod_clock += d
	if lod_clock >= 0.6:
		lod_clock = 0.0
		_update_worker_lod()
	_animate_environment(d)
	_animate_work_sparks(d)

func visible_workers() -> int:
	return actors.size()

func live_participants() -> int:
	return int(state.get("participants").size()) if state != null else 0

func camera_turn_degrees() -> float:
	return rad_to_deg(orbit_angle)

func camera_mode_next() -> void:
	orbit_enabled = not orbit_enabled

func _build_rescue_camps() -> void:
	# The two ends of the evacuation must be legible from any 360 view.
	# Refuge and waiting areas sit behind the character paths, not on top.
	var emergency_tent := Node3D.new()
	emergency_tent.name = "EmergencyCareCamp"
	terrain.add_child(emergency_tent)
	var site := str(state.call("scenario_info").get("site_type"))
	var refuge_z := 8.5 if site in ["dike","dam"] else -7.1
	emergency_tent.position = Vector3(13.3,0.14,refuge_z)
	_box(emergency_tent,Vector3(0,0.2,0),Vector3(5.5,0.28,4.4),Color("#bcb7a1"))
	_box(emergency_tent,Vector3(0,1.6,0),Vector3(4.8,2.6,3.5),Color("#e7e4d4"))
	var rooftop := _box(emergency_tent,Vector3(0,3.16,0),Vector3(5.2,0.32,3.9),Color("#d1dfd2"))
	rooftop.rotation.z = 0.08
	_box(emergency_tent,Vector3(0,1.5,1.79),Vector3(1.12,2.4,0.12),Color("#399282"))
	_box(emergency_tent,Vector3(0,2.7,1.87),Vector3(0.78,0.19,0.10),Color("#f4f6e4"))
	_box(emergency_tent,Vector3(0,2.7,1.92),Vector3(0.13,0.67,0.10),Color("#f4f6e4"))
	var refuge_beacon := OmniLight3D.new()
	refuge_beacon.position = Vector3(0.0,3.65,0.0)
	refuge_beacon.light_color = Color("#b5f5db")
	refuge_beacon.omni_range = 8.5
	refuge_beacon.light_energy = 0.75
	emergency_tent.add_child(refuge_beacon)
	var waiting_camp := Node3D.new()
	waiting_camp.name = "EvacuationAssemblyPoint"
	terrain.add_child(waiting_camp)
	waiting_camp.position = Vector3(-13.5,0.10,-2.3)
	_box(waiting_camp,Vector3(0,-0.035,0),Vector3(5.7,0.09,4.3),Color("#acb39d"))
	for x in [-2.0,2.0]:
		_cylinder(waiting_camp,Vector3(x,0.85,1.82),0.06,1.55,Color("#deb875"))
	_box(waiting_camp,Vector3(0,1.25,1.80),Vector3(4.35,0.11,0.12),Color("#e9cc84"))
	var ambulance := Node3D.new()
	ambulance.name = "RescueAmbulance"
	terrain.add_child(ambulance)
	ambulance.position = Vector3(18.6,0.13,refuge_z+1.2)
	_box(ambulance,Vector3(0,0.89,0),Vector3(3.6,1.65,1.75),Color("#eef0e2"))
	_box(ambulance,Vector3(-0.56,1.45,0.91),Vector3(0.81,0.57,0.09),Color("#5e99b4"))
	_box(ambulance,Vector3(1.3,1.07,0.91),Vector3(0.48,0.48,0.13),Color("#e76e57"))
	_box(ambulance,Vector3(1.3,1.07,0.98),Vector3(0.17,0.75,0.08),Color("#f1f4e9"))
	_box(ambulance,Vector3(0,1.8,0),Vector3(0.3,0.14,0.22),Color("#6fd9e1"))
	for x in [-1.1,1.1]:
		for z in [-0.72,0.72]:
			_cylinder(ambulance,Vector3(x,0.34,z),0.31,0.22,Color("#39444b"))

func _build_environment_details() -> void:
	# Curved river surface detail, moving rain and a refuge light,
	# without external shaders or purchased assets.
	for i in range(26):
		var x := randf_range(-5.1,5.1)
		var z := randf_range(-18.5,18.5)
		var ripple := _box(terrain,Vector3(x,-0.50,z),Vector3(randf_range(0.45,1.5),0.025,0.06),Color("#90d5dc"))
		water_foam.append(ripple)
	var hazard := str(state.call("scenario_info").get("hazard_kind"))
	var blizzard := hazard=="blizzard"
	var fire := hazard=="incendie"
	for i in range(34):
		var tint := Color("#eaf1f4") if blizzard else (Color("#f6ac6a") if fire else Color("#a9dce8"))
		var size := Vector3(0.085,0.10,0.085) if blizzard else (Vector3(0.11,0.18,0.11) if fire else Vector3(0.022,randf_range(0.42,1.1),0.022))
		var streak := _box(terrain,Vector3(randf_range(-22,22),randf_range(2.0,11.0),randf_range(-18,18)),size,tint)
		streak.visible = false
		rain.append(streak)
	light_refuge = OmniLight3D.new()
	light_refuge.position = Vector3(12.4,4.2,-5.0)
	light_refuge.light_color = Color("#ffe0ab")
	light_refuge.light_energy = 1.15
	light_refuge.omni_range = 10.0
	terrain.add_child(light_refuge)

func _animate_environment(delta: float) -> void:
	var stage := int(state.get("weather_stage"))
	var flood := float(state.get("flood_level"))
	var hazard_kind := str(state.call("scenario_info").get("hazard_kind"))
	var snowing := hazard_kind=="blizzard"
	var burning := hazard_kind=="incendie"
	for i in range(water_foam.size()):
		var wave: MeshInstance3D = water_foam[i]
		var pos := wave.position
		pos.z += delta*(1.1+flood*3.8+float(i%3)*0.12)
		if pos.z > 19.8:
			pos.z = -19.8
		pos.y = water.position.y+0.16+sin(clock*2.8+float(i))*0.025
		wave.position = pos
	for i in range(rain.size()):
		var drop: MeshInstance3D = rain[i]
		drop.visible = stage > 0
		if stage > 0:
			var vertical_speed := (2.2 if snowing else (4.8 if burning else 6.5+float(i%7)+float(stage)*1.9))
			drop.position.y += delta*vertical_speed if burning else -delta*vertical_speed
			drop.position.x += delta*(0.8 if snowing else 1.0+float(stage)*1.7)
			var reset := drop.position.y > 14.0 if burning else drop.position.y < 0.8
			if reset or drop.position.x > 26.0:
				var spawn_height := randf_range(0.2,1.5) if burning else randf_range(9.0,15.0)
				drop.position = Vector3(randf_range(-20.0,20.0),spawn_height,randf_range(-17.0,17.0))
	if light_refuge != null:
		light_refuge.light_energy = 1.15+0.13*sin(clock*1.8)
	if rescue_rotor != null and is_instance_valid(rescue_rotor):
		rescue_rotor.rotation.y += delta * 24.0
	# Helicopter location is driven by the passenger's rescue track in physics.

func visible_civilians() -> int:
	return int(civilians.call("visible_count")) if civilians != null else 0

func crossing_civilians() -> int:
	return int(civilians.call("movement_count")) if civilians != null else 0

func _physics_process(delta: float) -> void:
	# CharacterBody3D movement must happen on the fixed physics clock.
	if state == null or terrain == null:
		return
	var d := minf(0.1,delta)
	if civilians != null and is_instance_valid(civilians):
		civilians.call("sync",d)
	_animate_workers(d)
	_animate_rescues()

func _add_rail_collider(at: Vector3, box_size: Vector3) -> void:
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = 1
	obstacle.collision_mask = 0
	obstacle.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collider.shape = shape
	obstacle.add_child(collider)
	terrain.add_child(obstacle)

func can_complete_evacuate(person_index: int) -> bool:
	if civilians == null or not is_instance_valid(civilians):
		return false
	return bool(civilians.call("at_refuge",person_index))
