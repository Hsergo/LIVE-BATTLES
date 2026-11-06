extends Node3D
const Routes = preload("res://scripts/rescue_routes_3d.gd")
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
var rescue_started: Dictionary = {}
var last_safely_arrived := 0

func setup(game: RefCounted, scene_type: String) -> void:
	mission = game
	site_type = scene_type
	time = 0.0
	for child in get_children():
		child.queue_free()
	crowd.clear()
	rescue_started.clear()
	last_safely_arrived = 0
	var amount := mini(int(game.get("target")),MAX_CIVILIANS)
	for idx in range(amount):
		crowd.append(_create_civilian(idx))
	var waiting_title := "EQUIPAGES EN ATTENTE" if scene_type == "lighthouse" else ("PERSONNES A EVACUER" if scene_type == "helipad" else "VILLAGEOIS EN ATTENTE")
	waiting_sign = _sign(waiting_title,Vector3(-13.3,4.5,-1.9),Color("#ffecd0"))
	var shelter_pos := Vector3(12.8,3.8,11.2) if scene_type in ["dike","dam"] else Vector3(12.8,3.8,-4.6)
	safe_sign = _sign("ZONE DE REFUGE",shelter_pos,Color("#a8ffe0"))
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
	var person: CharacterBody3D = load("res://scripts/character_motor_3d.gd").new()
	person.name = "Villager_%02d" % index
	add_child(person)
	var visual := Node3D.new()
	visual.name = "CivilianAppearance"
	person.add_child(visual)
	var is_child := index%6 == 2
	var is_elder := index%7 == 4
	var is_responder_family := index%8 == 1
	person.call("configure",2,0.185 if is_child else 0.22,1.13 if is_child else 1.44)
	visual.scale = Vector3.ONE * (0.72 if is_child else (0.91 if is_elder else 0.99+float(index%3)*0.035))
	var skin: Color = SKIN[(index*7+2)%SKIN.size()]
	var outfit: Color = COATS[(index*5+1)%COATS.size()]
	var trousers: Color = PANTS[(index*3+1)%PANTS.size()]
	var hairstyle: Color = HAIR[(index*9+3)%HAIR.size()]
	# Human-proportioned torso and head; NPCs do not wear worker helmets.
	_capsule(visual,Vector3(0,1.16,0),0.97,0.31,outfit)
	_capsule(visual,Vector3(0,0.96,0),0.49,0.27,trousers)
	_sphere(visual,Vector3(0,1.92,0),0.28,skin)
	var haircap := _sphere(visual,Vector3(0,2.075,-0.025),0.278,hairstyle)
	haircap.scale = Vector3(1.04,0.56,0.99)
	for side in [-1.0,1.0]:
		_sphere(visual,Vector3(side*0.096,1.94,0.249),0.023,Color("#24313e"))
	_sphere(visual,Vector3(0,1.87,0.262),0.036,skin.darkened(0.09))
	_box(visual,Vector3(0,1.78,0.267),Vector3(0.095,0.020,0.025),Color("#7d4f43"))
	if index%5==0:
		# A lightweight emergency backpack/shoulder bag.
		_box(visual,Vector3(0,1.10,-0.35),Vector3(0.48,0.66,0.26),Color("#8b866f"))
		_box(visual,Vector3(-0.20,1.14,0.035),Vector3(0.06,0.78,0.05),Color("#d9b97d"))
	if is_elder:
		_box(visual,Vector3(0.40,0.52,0.07),Vector3(0.065,1.0,0.055),Color("#bba281"))
	if is_child:
		# A small school backpack and cap help viewers identify children.
		_box(visual,Vector3(0,1.08,-0.31),Vector3(0.44,0.50,0.22),Color("#d4a44f"))
		_box(visual,Vector3(0,2.11,0.09),Vector3(0.50,0.09,0.29),Color("#e9b66f"))
	if is_responder_family:
		# Emergency red armband: visual storytelling without text clutter.
		_box(visual,Vector3(0.33,1.38,0.02),Vector3(0.16,0.15,0.25),Color("#eaa19a"))
	if site_type == "lighthouse":
		# Life-vest makes the maritime rescue different from the village.
		_box(visual,Vector3(0.0,1.18,0.30),Vector3(0.58,0.65,0.085),Color("#ee994f"))
		_box(visual,Vector3(0.0,1.18,0.36),Vector3(0.09,0.59,0.035),Color("#e8e3a1"))
	elif site_type == "helipad":
		_box(visual,Vector3(0.0,1.50,0.29),Vector3(0.55,0.12,0.05),Color("#e8d77d"))
	var joints: Dictionary = {}
	for limb in ["left","right"]:
		var sign := -1.0 if limb=="left" else 1.0
		var arm := Node3D.new()
		visual.add_child(arm)
		arm.position = Vector3(sign*0.36,1.47,0)
		_capsule(arm,Vector3(0,-0.36,0),0.72,0.115,outfit.darkened(0.10))
		_sphere(arm,Vector3(0,-0.71,0),0.105,skin)
		joints[limb+"_arm"] = arm
		var leg := Node3D.new()
		visual.add_child(leg)
		leg.position = Vector3(sign*0.15,0.77,0)
		_capsule(leg,Vector3(0,-0.31,0),0.66,0.135,trousers)
		_box(leg,Vector3(0,-0.66,0.105),Vector3(0.27,0.14,0.43),Color("#514c47"))
		joints[limb+"_leg"] = leg
	joints["node"] = person
	joints["visual"] = visual
	joints["id"] = index
	joints["age"] = 0.0
	joints["is_child"] = is_child
	joints["is_elder"] = is_elder
	joints["phase"] = "waiting"
	joints["safe_at"] = -1.0
	joints["height"] = 0.76 if is_child else 1.0
	joints["previous_position"] = Vector3.ZERO
	# Use the licensed humanoid model on a subset of adults. Children and
	# elders retain distinct procedural silhouettes until suitable CC0 rigs exist.
	if not is_child and not is_elder and index % 4 == 0:
		var avatar := load("res://scripts/rigged_humanoid.gd").new() as Node3D
		# It must be a SIBLING of CivilianAppearance. Hiding its parent
		# previously hid the licensed rig as well, so nothing appeared.
		person.add_child(avatar)
		if bool(avatar.call("setup",1.05)):
			visual.visible = false
			joints["avatar"] = avatar
			# Independent visible accessory gives the civilian a distinct role.
			var carry := Node3D.new()
			carry.name = "PersonalEmergencyBag"
			person.add_child(carry)
			_box(carry,Vector3(0.0,0.95,-0.28),Vector3(0.39,0.53,0.20),COATS[(index+3)%COATS.size()])
			joints["carry"] = carry
		else:
			avatar.queue_free()
	var rescue_tag := Label3D.new()
	rescue_tag.name = "RescueStatus"
	person.add_child(rescue_tag)
	rescue_tag.visible = false
	rescue_tag.text = "EVACUATION"
	rescue_tag.position = Vector3(0,2.54,0)
	rescue_tag.font_size = 42
	rescue_tag.pixel_size = 0.0038
	rescue_tag.outline_size = 9
	rescue_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rescue_tag.modulate = Color("#fff0aa")
	joints["status_tag"] = rescue_tag
	person.position = _waiting_position(index)
	return joints

func _waiting_position(index: int) -> Vector3:
	var row := int(index/6)
	var col := index%6
	return Vector3(-13.6 + float(col)*0.75,0.1,-3.9 + float(row)*1.12)

func _safe_position(index: int) -> Vector3:
	var row := int(index/6)
	var col := index%6
	# The safe zone is next to the actual 3D triage camp, never in a river.
	if site_type in ["dike","dam"]:
		return Vector3(10.8+float(col)*0.50,0.14,11.5+float(row)*0.76)
	return Vector3(11.3+float(col)*0.52,0.14,-4.25+float(row)*0.75)

func _interpolate(a: Vector3,b: Vector3,p: float) -> Vector3:
	return a.lerp(b,clampf(p,0.0,1.0))

func _route(progress: float, index: int, lane: int) -> Vector3:
	return Routes.position(site_type,progress,_waiting_position(index),_safe_position(index),lane)

func route_phase(progress: float) -> String:
	return Routes.stage(site_type,progress)

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
	var urgent := float(mission.get("flood_level")) > 0.74
	count_away = crossing.size()
	count_waiting = 0
	count_safe = 0
	for actor in crowd:
		var idx := int(actor["id"])
		var rig: Node3D = actor["node"]
		var phase := "waiting"
		var target := _waiting_position(idx)
		# Background NPCs move within the assembly point, not stand frozen.
		var idle_drift := Vector3(sin(time*0.42+float(idx)*1.4)*0.19,0.0,cos(time*0.35+float(idx))*0.18)
		target += idle_drift
		var walk := false
		var is_passenger := false
		var route_stage := "waiting"
		if crossing.has(idx):
			var entry: Dictionary = crossing[idx]
			var progress := float(entry.get("p",0.0))
			phase = "crossing"
			route_stage = route_phase(progress)
			target = _route(progress,idx,int(entry.get("lane",0)))
			is_passenger = Routes.transported(site_type,progress)
			walk = not is_passenger
		elif idx < started:
			phase = "safe"
			target = _safe_position(idx)
			count_safe += 1
			walk = rig.position.distance_to(target)>0.18
		else:
			count_waiting += 1
			walk = rig.position.distance_to(target) > 0.12
		var previous_phase := str(actor.get("phase","waiting"))
		if phase == "crossing" and previous_phase != "crossing":
			rescue_started[idx] = time
		if phase == "safe" and previous_phase != "safe":
			actor["safe_at"] = time
		actor["phase"] = phase
		actor["age"] = float(actor["age"])+d
		var t := float(actor["age"])
		var walking_speed := 5.0 if bool(actor["is_elder"]) else (6.4 if bool(actor["is_child"]) else 6.0)
		# Passengers move with boats/helicopters. Disabling collision temporarily
		# avoids a phantom walk through a dam wall or aircraft while aboard.
		var body := rig as CharacterBody3D
		body.collision_mask = 0 if is_passenger else 3
		body.collision_layer = 0 if is_passenger else 2
		var move_speed := 8.5 if is_passenger else (walking_speed if walk else 2.4)
		var movement: Vector3 = rig.call("move_to",target,move_speed,d)
		if movement.length_squared()>0.00003 and walk:
			rig.rotation.y = lerp_angle(rig.rotation.y,atan2(movement.x,movement.z),minf(1.0,d*5.0))
		var pace := 7.8 if walk else 2.0
		var swing := sin(t*pace+float(idx)*0.8)*(0.58 if walk else (0.25 if endangered and phase=="waiting" else 0.07))
		if is_passenger:
			swing = sin(t*1.7+float(idx))*0.09
		(actor["left_arm"] as Node3D).rotation.x = swing
		(actor["right_arm"] as Node3D).rotation.x = -swing
		(actor["left_leg"] as Node3D).rotation.x = -swing*0.60
		(actor["right_leg"] as Node3D).rotation.x = swing*0.60
		if actor.has("avatar"):
			var avatar: Node3D = actor["avatar"]
			if is_instance_valid(avatar):
				avatar.call("animate",d,"idle" if is_passenger else ("walk" if walk else ("celebrate" if phase=="safe" else "idle")))
		# Different body language: asking for help, walking to safety,
		# and celebrating after reaching the real refuge.
		if phase=="safe" and not walk:
			(actor["right_arm"] as Node3D).rotation.z = 0.55+0.28*sin(t*3.7+float(idx))
			(actor["left_arm"] as Node3D).rotation.z = -0.25
		elif phase=="waiting" and endangered:
			(actor["right_arm"] as Node3D).rotation.z = 0.42+0.31*sin(t*4.3+float(idx))
			(actor["left_arm"] as Node3D).rotation.z = -0.12 if urgent else 0.0
		else:
			(actor["right_arm"] as Node3D).rotation.z = 0.0
			(actor["left_arm"] as Node3D).rotation.z = 0.0
		var rescue_tag: Label3D = actor["status_tag"]
		var recent_arrival := phase=="safe" and (time-float(actor.get("safe_at",-100.0))) < 3.5
		rescue_tag.visible = phase=="crossing" or recent_arrival
		if rescue_tag.visible:
			if phase=="safe":
				rescue_tag.text = "SAUVE"
			elif route_stage == "flight":
				rescue_tag.text = "EN VOL"
			elif route_stage == "boat":
				rescue_tag.text = "A BORD"
			elif route_stage == "boarding":
				rescue_tag.text = "EMBARQUEMENT"
			else:
				rescue_tag.text = "EN ROUTE"
			rescue_tag.modulate = Color("#ffe2a7") if phase=="crossing" else Color("#a9ffd5")
			rescue_tag.position.y = 2.54+0.10*sin(t*3.0)
		# Look toward the bridge or refuge even when standing still.
		if phase=="waiting" and not walk:
			rig.rotation.y = lerp_angle(rig.rotation.y,0.3+sin(t*0.45+float(idx))*0.16,minf(1.0,d*1.5))
		actor["route_stage"] = route_stage
		var appearance: Node3D = actor["visual"]
		appearance.position.y = 0.021*sin(t*pace) if walk else 0.008*sin(t*pace)
		if actor.has("avatar"):
			var visible_avatar: Node3D = actor["avatar"]
			if is_instance_valid(visible_avatar):
				visible_avatar.position.y = appearance.position.y
	if waiting_sign != null:
		waiting_sign.text = "%d PERSONNES EN ATTENTE" % count_waiting
	if safe_sign != null:
		safe_sign.text = "%d MIS EN SECURITE" % int(mission.get("saved"))

func visible_count() -> int:
	return crowd.size()

func movement_count() -> int:
	return count_away

func transit_details() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for actor in crowd:
		if str(actor.get("phase","")) == "crossing":
			var npc: Node3D = actor["node"]
			result.append({"index":int(actor["id"]),"stage":str(actor.get("route_stage","")),
				"position":npc.position})
	return result

func evacuee_position(person_index: int) -> Vector3:
	if person_index >= 0 and person_index < crowd.size():
		var npc: Node3D = crowd[person_index]["node"]
		if is_instance_valid(npc):
			return npc.position
	return Vector3(-8.0,0.15,0.0)

func first_in_transit_position() -> Vector3:
	for actor in crowd:
		if str(actor.get("phase","")) == "crossing":
			var npc: Node3D = actor["node"]
			if is_instance_valid(npc):
				return npc.position
	return Vector3.ZERO

func last_rescued_position() -> Vector3:
	if crowd.is_empty() or mission == null:
		return Vector3(12.0,0.2,0.0)
	var last_index := clampi(int(mission.get("last_rescued_person_index")),0,crowd.size()-1)
	var actor: Dictionary = crowd[last_index]
	var rig: Node3D = actor["node"]
	return rig.position if is_instance_valid(rig) else _safe_position(last_index)

func at_refuge(person_index: int) -> bool:
	if person_index < 0 or person_index >= crowd.size():
		return false
	var actor: Dictionary = crowd[person_index]
	var npc: Node3D = actor["node"]
	return is_instance_valid(npc) and npc.position.distance_to(_safe_position(person_index)) <= 0.65
