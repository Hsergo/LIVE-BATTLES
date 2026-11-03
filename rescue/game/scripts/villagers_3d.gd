extends Node3D
## Civilian population used by the 3D rescue scene.
## They are scenario NPCs, NEVER simulated TikTok spectators.
## Each pedestrian has a stable person_index throughout the rescue sequence.
## Lightweight procedural characters. Production rigged glTF assets can later replace them.

const MAX_CIVILIANS := 24
const SKIN := [
	Color("#eed1b5"),Color("#b87757"),Color("#714831"),
	Color("#e4ae8a"),Color("#af8063"),Color("#603b32")
]
const COATS := [
	Color("#c56b5b"),Color("#e2b65d"),Color("#4a87a3"),
	Color("#548c74"),Color("#af7ea5"),Color("#ca8b45")
]
const PANTS := [Color("#294052"),Color("#5a5754"),Color("#596b6f")]
const HAIR := [Color("#312526"),Color("#78543e"),Color("#222530"),Color("#b17e43")]
var crowd: Array[Dictionary] = []
var materials: Dictionary = {}
var mission: RefCounted
var site_type := "bridge"
var time := 0.0
var count_away := 0
var count_safe := 0
var count_waiting := 0
var waiting_sign: Label3D
var safe_sign: Label3D

func setup(game: RefCounted, scene_type: String) -> void:
	mission = game
	site_type = scene_type
	time = 0.0
	for child in get_children():
		child.queue_free()
	crowd.clear()
	var amount := mini(int(game.get("target")),MAX_CIVILIANS)
	for idx in range(amount):
		crowd.append(_create_civilian(idx))
	waiting_sign = _sign("VILLAGEOIS EN ATTENTE",Vector3(-13.3,4.5,-1.9),Color("#ffecd0"))
	safe_sign = _sign("ZONE DE REFUGE",Vector3(13.3,4.5,-1.9),Color("#a8ffe0"))
	sync(0.0)

func _material(tint: Color) -> StandardMaterial3D:
	var key := tint.to_html()
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.86
	mat.metallic = 0.0
	materials[key] = mat
	return mat

func _box(parent: Node3D, pos: Vector3, dimensions: Vector3, tint: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.material_override = _material(tint)
	node.position = pos
	parent.add_child(node)
	return node

func _sphere(parent: Node3D, pos: Vector3, radius: float, tint: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2.0
	mesh.radial_segments = 10
	mesh.rings = 4
	node.mesh = mesh
	node.material_override = _material(tint)
	node.position = pos
	parent.add_child(node)
	return node

func _capsule(parent: Node3D, pos: Vector3, height: float, radius: float, tint: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	node.mesh = mesh
	node.material_override = _material(tint)
	node.position = pos
	parent.add_child(node)
	return node

func _sign(message: String, pos: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	add_child(label)
	label.text = message
	label.position = pos
	label.font_size = 45
	label.pixel_size = 0.005
	label.modulate = color
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return label

func _create_civilian(index: int) -> Dictionary:
	var person := Node3D.new()
	person.name = "Villager_%02d" % index
	add_child(person)
	var is_child := index%6 == 2
	var is_elder := index%7 == 4
	person.scale = Vector3.ONE * (0.72 if is_child else (0.91 if is_elder else 0.99+float(index%3)*0.035))
	var skin: Color = SKIN[(index*7+2)%SKIN.size()]
	var outfit: Color = COATS[(index*5+1)%COATS.size()]
	var trousers: Color = PANTS[(index*3+1)%PANTS.size()]
	var hairstyle: Color = HAIR[(index*9+3)%HAIR.size()]
	# Human-proportioned torso and head; NPCs do not wear worker helmets.
	_capsule(person,Vector3(0,1.16,0),0.97,0.31,outfit)
	_capsule(person,Vector3(0,0.96,0),0.49,0.27,trousers)
	_sphere(person,Vector3(0,1.92,0),0.28,skin)
	var haircap := _sphere(person,Vector3(0,2.075,-0.025),0.278,hairstyle)
	haircap.scale = Vector3(1.04,0.56,0.99)
	for side in [-1.0,1.0]:
		_sphere(person,Vector3(side*0.096,1.94,0.249),0.023,Color("#24313e"))
	_sphere(person,Vector3(0,1.87,0.262),0.036,skin.darkened(0.09))
	_box(person,Vector3(0,1.78,0.267),Vector3(0.095,0.020,0.025),Color("#7d4f43"))
	if index%5==0:
		# A lightweight emergency backpack/shoulder bag.
		_box(person,Vector3(0,1.10,-0.35),Vector3(0.48,0.66,0.26),Color("#8b866f"))
		_box(person,Vector3(-0.20,1.14,0.035),Vector3(0.06,0.78,0.05),Color("#d9b97d"))
	if is_elder:
		_box(person,Vector3(0.40,0.52,0.07),Vector3(0.065,1.0,0.055),Color("#bba281"))
	var joints: Dictionary = {}
	for limb in ["left","right"]:
		var sign := -1.0 if limb=="left" else 1.0
		var arm := Node3D.new()
		person.add_child(arm)
		arm.position = Vector3(sign*0.36,1.47,0)
		_capsule(arm,Vector3(0,-0.36,0),0.72,0.115,outfit.darkened(0.10))
		_sphere(arm,Vector3(0,-0.71,0),0.105,skin)
		joints[limb+"_arm"] = arm
		var leg := Node3D.new()
		person.add_child(leg)
		leg.position = Vector3(sign*0.15,0.77,0)
		_capsule(leg,Vector3(0,-0.31,0),0.66,0.135,trousers)
		_box(leg,Vector3(0,-0.66,0.105),Vector3(0.27,0.14,0.43),Color("#514c47"))
		joints[limb+"_leg"] = leg
	joints["node"] = person
	joints["id"] = index
	joints["age"] = 0.0
	joints["phase"] = "waiting"
	joints["height"] = 0.76 if is_child else 1.0
	joints["previous_position"] = Vector3.ZERO
	person.position = _waiting_position(index)
	return joints

func _waiting_position(index: int) -> Vector3:
	var row := int(index/6)
	var col := index%6
	return Vector3(-13.6 + float(col)*0.75,0.1,-3.9 + float(row)*1.12)

func _safe_position(index: int) -> Vector3:
	var row := int(index/6)
	var col := index%6
	return Vector3(12.0+float(col)*0.55,0.10,0.6+float(row)*0.92)

func _interpolate(a: Vector3,b: Vector3,p: float) -> Vector3:
	return a.lerp(b,clampf(p,0.0,1.0))

func _route(progress: float, index: int, lane: int) -> Vector3:
	var p := clampf(progress,0.0,1.0)
	var z := -0.75+float(lane)*0.75
	match site_type:
		"bridge":
			var start := _waiting_position(index)
			if p < 0.18:
				return _interpolate(start,Vector3(-7.1,1.28,z),p/0.18)
			if p < 0.82:
				return _interpolate(Vector3(-7.1,1.28,z),Vector3(7.1,1.28,z),(p-0.18)/0.64)
			return _interpolate(Vector3(7.1,1.28,z),_safe_position(index),(p-0.82)/0.18)
		"dike","dam":
			var place := Vector3(-11.0,0.13,9.1+float(lane)*0.52)
			var refuge := Vector3(11.2,0.13,9.1+float(lane)*0.52)
			if p < 0.22:
				return _interpolate(_waiting_position(index),place,p/0.22)
			if p < 0.84:
				return _interpolate(place,refuge,(p-0.22)/0.62)
			return _interpolate(refuge,_safe_position(index),(p-0.84)/0.16)
		"lighthouse":
			var embark := Vector3(-5.8,0.2,2.4+float(lane)*0.6)
			if p < 0.20:
				return _interpolate(_waiting_position(index),embark,p/0.20)
			if p < 0.88:
				# Walkable representation of a passenger aboard the moving boat.
				return Vector3(-5.8+11.6*(p-0.2)/0.68,0.4,2.4+float(lane)*0.6)
			return _interpolate(Vector3(5.8,0.4,2.4+float(lane)*0.6),_safe_position(index),(p-0.88)/0.12)
		"helipad":
			var landing := Vector3(-1.9,0.73,3.4+float(lane)*0.38)
			if p < 0.62:
				return _interpolate(_waiting_position(index),landing,p/0.62)
			return landing+Vector3((p-0.62)*7.0,(p-0.62)*9.0,0)
	return _interpolate(_waiting_position(index),_safe_position(index),p)

func sync(delta: float) -> void:
	if mission == null:
		return
	var d := clampf(delta,0.0,0.1)
	time += d
	var crossing: Dictionary = {}
	for moving in mission.get("crossings"):
		var person_index := int(moving.get("person_index",-1))
		if person_index >= 0:
			crossing[person_index] = moving
	var started := int(mission.get("next_villager_index"))
	var endangered := float(mission.get("flood_level")) > 0.34
	count_away = crossing.size()
	count_waiting = 0
	count_safe = 0
	for actor in crowd:
		var idx := int(actor["id"])
		var rig: Node3D = actor["node"]
		var phase := "waiting"
		var target := _waiting_position(idx)
		var walk := false
		if crossing.has(idx):
			var entry: Dictionary = crossing[idx]
			phase = "crossing"
			target = _route(float(entry.get("p",0.0)),idx,int(entry.get("lane",0)))
			walk = true
		elif idx < started:
			phase = "safe"
			target = _safe_position(idx)
			count_safe += 1
			walk = rig.position.distance_to(target)>0.18
		else:
			count_waiting += 1
		actor["phase"] = phase
		actor["age"] = float(actor["age"])+d
		var t := float(actor["age"])
		var old := rig.position
		rig.position = rig.position.lerp(target,minf(1.0,d*(8.0 if walk else 4.0)))
		var movement := rig.position-old
		if movement.length_squared()>0.00003 and walk:
			rig.rotation.y = lerp_angle(rig.rotation.y,atan2(movement.x,movement.z),minf(1.0,d*5.0))
		var pace := 7.0 if walk else 2.2
		var swing := sin(t*pace+float(idx)*0.8)*(0.58 if walk else (0.25 if endangered and phase=="waiting" else 0.07))
		(actor["left_arm"] as Node3D).rotation.x = swing
		(actor["right_arm"] as Node3D).rotation.x = -swing
		(actor["left_leg"] as Node3D).rotation.x = -swing*0.60
		(actor["right_leg"] as Node3D).rotation.x = swing*0.60
		if phase=="safe" and not walk:
			(actor["right_arm"] as Node3D).rotation.z = 0.50+0.25*sin(t*4.3+float(idx))
		else:
			(actor["right_arm"] as Node3D).rotation.z = 0.0
		var base_y := target.y
		rig.position.y = lerpf(rig.position.y,base_y,0.6)+0.016*sin(t*pace) if walk else lerpf(rig.position.y,base_y,0.5)
	if waiting_sign != null:
		waiting_sign.text = "%d VILLAGEOIS EN ATTENTE" % count_waiting
	if safe_sign != null:
		safe_sign.text = "%d MIS EN SECURITE" % int(mission.get("saved"))

func visible_count() -> int:
	return crowd.size()

func movement_count() -> int:
	return count_away
