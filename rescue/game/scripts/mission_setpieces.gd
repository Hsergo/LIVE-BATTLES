extends Node3D
## Mission-specific stage dressing controlled by the real collective mission state.
## Fifteen different 3D landmarks; one per level, no external assets or shaders.
## This is gameplay feedback, not decorative text over the LIVE screen.
var state: RefCounted
var identity := ""
var visual := ""
var machinery: Node3D
var progress_column: Node3D
var warning: OmniLight3D
var landmark: Node3D
var clock := 0.0
var last_crisis_event := 0
var base_position := Vector3(-16.8,0.16,12.2)
var material_cache: Dictionary = {}

func _mat(c: Color) -> StandardMaterial3D:
	var k := c.to_html()
	if material_cache.has(k):
		return material_cache[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.81
	material_cache[k] = m
	return m

func _box(parent: Node3D, p: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _mat(c)
	node.position = p
	parent.add_child(node)
	return node

func _ball(parent: Node3D, p: Vector3, radius: float, c: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.material_override = _mat(c)
	node.position = p
	parent.add_child(node)
	return node

func _cyl(parent: Node3D, p: Vector3, radius: float, height: float, c: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.material_override = _mat(c)
	node.position = p
	parent.add_child(node)
	return node

func setup(game: RefCounted) -> void:
	state = game
	var profile: Dictionary = game.get("mission_profile")
	identity = str(game.call("scenario_info").get("id",""))
	visual = str(profile.get("visual",""))
	if landmark != null and is_instance_valid(landmark):
		landmark.queue_free()
	landmark = Node3D.new()
	landmark.name = "MissionLandmark_" + identity
	add_child(landmark)
	var scene := str(game.call("scenario_info").get("site_type","bridge"))
	base_position = Vector3(-16.8,0.16,12.2)
	if scene=="lighthouse":
		base_position.z = 6.8
	elif scene=="helipad":
		base_position = Vector3(8.2,0.15,13.5)
	elif scene=="dam":
		base_position = Vector3(-17.6,0.15,11.4)
	landmark.position = base_position
	# 3D progress beacon: completing the optional free objective physically
	# raises the green column and powers the site's machine.
	_box(landmark,Vector3(0,0.17,0),Vector3(5.4,0.24,5.2),Color("#acb7ab"))
	_box(landmark,Vector3(1.95,0.61,1.9),Vector3(0.74,0.94,0.76),Color("#3a5d66"))
	progress_column = Node3D.new()
	progress_column.name = "CooperationIndicator"
	landmark.add_child(progress_column)
	progress_column.position = Vector3(1.95,0.15,1.9)
	_box(progress_column,Vector3.ZERO,Vector3(0.37,1.0,0.36),Color("#7dddc0"))
	machinery = Node3D.new()
	machinery.name = "PoweredMissionMechanism"
	landmark.add_child(machinery)
	warning = OmniLight3D.new()
	warning.name = "CrisisSignal"
	warning.position = Vector3(1.95,2.0,1.9)
	warning.omni_range = 7.2
	warning.light_color = Color("#ffbd7b")
	warning.light_energy = 0.36
	landmark.add_child(warning)
	_render_mission()
	sync(0.0)

func _render_mission() -> void:
	var metal := Color("#9aaeb1")
	var yellow := Color("#e9c277")
	var orange := Color("#e98f60")
	var aqua := Color("#70bac9")
	match visual:
		"sirene":
			_cyl(machinery,Vector3(-1.0,2.1,0),0.18,3.8,metal)
			_ball(machinery,Vector3(-1.0,4.1,0),0.46,orange)
			for i in range(3):
				_box(machinery,Vector3(-1.5+float(i)*0.8,0.55,1.4),Vector3(0.64,0.60,0.16),yellow)
		"medical":
			_box(machinery,Vector3(-0.9,1.12,0),Vector3(3.9,1.9,2.0),Color("#ecece4"))
			_box(machinery,Vector3(-2.1,2.26,0),Vector3(1.6,0.59,1.8),Color("#d6d8cf"))
			_box(machinery,Vector3(-0.7,1.54,1.07),Vector3(0.77,0.20,0.11),orange)
			_box(machinery,Vector3(-0.7,1.54,1.13),Vector3(0.20,0.83,0.11),orange)
			for x in [-2.2,0.38]:
				for z in [-0.78,0.78]:
					_cyl(machinery,Vector3(x,0.37,z),0.42,0.25,Color("#42535a"))
		"cables":
			for x in [-2.0,0.9]:
				_cyl(machinery,Vector3(x,2.3,-0.3),0.16,4.2,metal)
				for z in [-1.3,1.3]:
					var cable := _cyl(machinery,Vector3(x+0.6,2.2,z),0.055,3.5,yellow)
					cable.rotation.z = 0.25 if z>0 else -0.25
		"pumps":
			for i in range(2):
				_box(machinery,Vector3(-1.9+float(i)*2.1,0.9,0),Vector3(1.7,1.25,1.7),Color("#668a94"))
				_cyl(machinery,Vector3(-1.9+float(i)*2.1,1.75,0),0.57,0.16,yellow)
			_box(machinery,Vector3(-0.8,0.65,1.3),Vector3(3.7,0.38,0.42),metal)
		"channels":
			for z in [-1.3,0,1.3]:
				_box(machinery,Vector3(-0.8,0.42,z),Vector3(3.9,0.19,0.7),aqua)
				_box(machinery,Vector3(-0.8,0.8,z+0.44),Vector3(3.9,0.82,0.12),Color("#8eaaa2"))
		"wave":
			for i in range(5):
				var xx := -2.7+float(i)*0.8
				_ball(machinery,Vector3(xx,1.15+0.42*sin(float(i)*0.9),0),0.73,aqua)
			_box(machinery,Vector3(-0.8,0.47,1.3),Vector3(4.5,0.9,0.24),Color("#d2c39a"))
		"beacon":
			_cyl(machinery,Vector3(-0.8,2.0,0),0.50,3.7,Color("#e4e7d8"))
			_ball(machinery,Vector3(-0.8,4.2,0),0.63,yellow)
			_box(machinery,Vector3(-0.8,4.25,-1.1),Vector3(0.25,0.20,2.9),yellow)
		"generator":
			_box(machinery,Vector3(-0.9,0.95,0),Vector3(3.7,1.6,1.8),Color("#677d86"))
			_box(machinery,Vector3(0.45,1.22,0.96),Vector3(0.55,0.47,0.15),Color("#8de1cc"))
			_cyl(machinery,Vector3(-2.0,2.5,-0.4),0.22,2.2,metal)
			_ball(machinery,Vector3(-0.75,1.37,1.02),0.48,Color("#4e5a60"))
		"radar":
			_cyl(machinery,Vector3(-0.9,1.9,0),0.16,3.2,metal)
			_ball(machinery,Vector3(-0.9,3.72,0),0.68,Color("#e0e6de"))
			_box(machinery,Vector3(-0.9,3.74,-0.8),Vector3(2.1,0.17,1.4),aqua)
			_box(machinery,Vector3(-0.9,0.8,1.2),Vector3(3.3,1.3,0.52),Color("#607580"))
		"spillway":
			for i in range(3):
				_box(machinery,Vector3(-2.6+float(i)*1.55,1.8,0),Vector3(1.30,3.2,0.26),metal)
				_box(machinery,Vector3(-2.6+float(i)*1.55,0.65,0.25),Vector3(1.05,0.85,0.12),aqua)
			_box(machinery,Vector3(-1.0,3.7,0),Vector3(4.8,0.2,0.36),yellow)
		"fracture":
			for i in range(5):
				var crack := _box(machinery,Vector3(-2.7+float(i)*1.12,0.45,sin(float(i))*0.4),Vector3(0.12,0.11,2.0),Color("#41474d"))
				crack.rotation.y = float(i)*0.23
			_box(machinery,Vector3(-0.8,1.5,-1.2),Vector3(3.9,1.8,0.42),metal)
		"sluice":
			for i in range(3):
				var xx := -2.55+float(i)*1.55
				_box(machinery,Vector3(xx,1.30,0),Vector3(1.30,2.4,0.28),metal)
				_cyl(machinery,Vector3(xx,2.6,0.55),0.64,0.13,yellow)
				_box(machinery,Vector3(xx,2.6,0.67),Vector3(1.05,0.14,0.09),yellow)
		"flames":
			for i in range(5):
				_ball(machinery,Vector3(-2.7+float(i)*0.9,0.75,0.2),0.49,orange)
				_ball(machinery,Vector3(-2.7+float(i)*0.9,1.38,-0.1),0.31,yellow)
			_box(machinery,Vector3(-0.85,0.45,1.25),Vector3(4.1,0.57,0.4),Color("#b4bfad"))
		"snow":
			for i in range(5):
				_ball(machinery,Vector3(-2.7+float(i)*0.85,0.50,0),0.57,Color("#e4edf2"))
			_box(machinery,Vector3(-0.9,1.55,-1.2),Vector3(3.0,2.1,0.95),Color("#abbec5"))
			_cyl(machinery,Vector3(-0.9,2.9,-1.2),0.17,0.65,orange)
		"command":
			_box(machinery,Vector3(-0.9,1.08,0),Vector3(4.3,2.0,2.2),Color("#7d9aab"))
			_box(machinery,Vector3(-0.9,2.19,0),Vector3(4.7,0.32,2.5),metal)
			_cyl(machinery,Vector3(-0.9,3.5,0),0.23,2.7,Color("#bfc8c5"))
			_ball(machinery,Vector3(-0.9,4.9,0),0.66,yellow)
			for x in [-2.0,0.2]:
				_box(machinery,Vector3(x,1.48,1.16),Vector3(0.79,0.60,0.13),Color("#88d5c9"))
		_:
			_box(machinery,Vector3(-1.0,1.0,0),Vector3(2.0,1.7,2.0),metal)

func sync(delta: float) -> void:
	if state == null or machinery == null:
		return
	clock += clampf(delta,0.0,0.1)
	var goal := maxf(1.0,float(state.get("secondary_goal")))
	var completion := clampf(float(state.get("secondary_progress"))/goal,0.0,1.0)
	var threat := clampf(float(state.get("crisis_level"))/100.0,0.0,1.0)
	progress_column.scale.y = maxf(0.06,completion*2.4)
	progress_column.position.y = 0.17+progress_column.scale.y*0.48
	var rotating := visual in ["beacon","radar","pumps","generator","sluice","command"]
	if rotating:
		machinery.rotation.y = sin(clock*0.23)*(0.05+completion*0.12)
	# Distinct activity without spawning new geometry every frame.
	if visual in ["wave","flames","snow"]:
		machinery.position.y = sin(clock*(1.6+threat*2.0))*0.08*threat
	if visual=="cables":
		machinery.rotation.z = 0.035*sin(clock*2.0)*threat
	if visual=="fracture":
		machinery.position.x = 0.06*sin(clock*12.0)*threat
	var protected := bool(state.get("secondary_complete"))
	warning.light_color = Color("#75e8ae") if protected else (Color("#ff8b64") if threat>=0.64 else Color("#ffe1a1"))
	warning.light_energy = 0.55 if protected else (0.28+threat*0.9)*(0.6+0.4*sin(clock*4.5)*sin(clock*4.5))
