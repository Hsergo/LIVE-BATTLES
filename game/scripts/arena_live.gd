extends Node3D
## LIVE BATTLES V0.2 — arene et avatars proceduraux, sans assets Blender.
## Les BOT restent clairement identifies tant qu'aucun spectateur n'a rejoint.

const MAX_VISIBLE_PER_TEAM := 5
const RED := Color("#ff526b")
const BLUE := Color("#3ebaff")
const GOLD := Color("#ffe091")

var champions: Array[Node3D] = []
var swords: Array[Node3D] = []
var crystal_meshes: Dictionary = {}
var soldiers: Dictionary = {"red": [], "blue": []}
var soldier_origins: Dictionary = {"red": [], "blue": []}
var labels: Dictionary = {"red": [], "blue": []}
var champion_labels: Dictionary = {}
var external_combat_control := false
var actor_time := 0.0
var carousel_offset := 0
var carousel_timer := 0.0
var last_players: Dictionary = {}
var last_contributions: Dictionary = {}

func _mat(color: Color, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.34
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.65
	return m

func _add(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = mesh
	result.position = at
	result.material_override = _mat(color, glow)
	parent.add_child(result)
	return result

func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, at, color, glow)

func _sphere(parent: Node3D, radius: float, at: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add(parent, mesh, at, color, glow)

func _tag(parent: Node3D, title: String, height: float, color: Color) -> Label3D:
	var tag := Label3D.new()
	tag.text = title
	tag.position = Vector3(0, height, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 28
	tag.pixel_size = 0.008
	tag.modulate = color
	tag.outline_size = 12
	tag.no_depth_test = true
	parent.add_child(tag)
	return tag

func _add_sword(parent: Node3D, team: String, scale_factor: float = 1.0) -> Node3D:
	var side := 1.0 if team == "red" else -1.0
	var hand := Node3D.new()
	hand.name = "SwordVisual"
	hand.position = Vector3(side * 0.72 * scale_factor, 1.3 * scale_factor, 0.12)
	parent.add_child(hand)
	_box(hand, Vector3(0.16, 0.44, 0.14) * scale_factor, Vector3(0, 0.18, 0), Color("#6a4f36"))
	_box(hand, Vector3(0.51, 0.11, 0.18) * scale_factor, Vector3(0, 0.43 * scale_factor, 0), GOLD)
	_box(hand, Vector3(0.15, 1.0, 0.10) * scale_factor, Vector3(0, 1.0 * scale_factor, 0), Color("#dbe9ff"), true)
	return hand

func _create_soldier(team: String, index: int) -> Node3D:
	var color := RED if team == "red" else BLUE
	var soldier := Node3D.new()
	add_child(soldier)
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.26
	capsule.height = 0.87
	_add(soldier, capsule, Vector3(0, 0.62, 0), color)
	_sphere(soldier, 0.27, Vector3(0, 1.35, 0), color.lightened(0.2))
	_box(soldier, Vector3(0.64, 0.12, 0.45), Vector3(0, 1.55, 0), color.darkened(0.18))
	_sphere(soldier, 0.055, Vector3(-0.09, 1.39, 0.23), Color.WHITE)
	_sphere(soldier, 0.055, Vector3(0.09, 1.39, 0.23), Color.WHITE)
	_box(soldier, Vector3(0.14, 0.50, 0.15), Vector3(-0.20, 0.2, 0), color.darkened(0.18))
	_box(soldier, Vector3(0.14, 0.50, 0.15), Vector3(0.20, 0.2, 0), color.darkened(0.18))
	_add_sword(soldier, team, 0.57)
	var tag := _tag(soldier, "BOT " + str(index + 1), 1.86, GOLD)
	labels[team].append(tag)
	var side := -1.0 if team == "red" else 1.0
	var x := side * (1.45 + float(index % 3) * 1.35)
	var z := -2.5 if index < 3 else 2.45
	soldier.position = Vector3(x, 0, z)
	soldier_origins[team].append(soldier.position)
	soldiers[team].append(soldier)
	return soldier

func _build_crystal(team: String) -> void:
	var side := -1.0 if team == "red" else 1.0
	var color := RED if team == "red" else BLUE
	var holder := Node3D.new()
	holder.position = Vector3(side * 4.85, 0, -2.9)
	add_child(holder)
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = 0.68
	pedestal.bottom_radius = 0.82
	pedestal.height = 0.50
	_add(holder, pedestal, Vector3(0, 0.25, 0), Color("#b8bac9"))
	_box(holder, Vector3(1.3, 0.11, 1.3), Vector3(0, 0.56, 0), GOLD, true)
	var crystal := _sphere(holder, 0.54, Vector3(0, 1.48, 0), color, true)
	crystal.scale = Vector3(0.74, 1.30, 0.74)
	crystal_meshes[team] = crystal
	_tag(holder, "CRISTAL " + team.to_upper(), 2.45, color.lightened(0.3))

func setup(existing_champions: Array[Node3D]) -> void:
	champions = existing_champions
	for team in ["red", "blue"]:
		_build_crystal(team)
		for i in range(MAX_VISIBLE_PER_TEAM):
			_create_soldier(team, i)
	for i in range(champions.size()):
		var team := "red" if i == 0 else "blue"
		var champion := champions[i]
		swords.append(_add_sword(champion, team))
		champion_labels[team] = _tag(champion, "CAPITAINE IA", 3.25, GOLD)
		_box(champion, Vector3(0.80, 0.20, 0.78), Vector3(0, 2.9, 0), GOLD)
	update_players({}, {})

func _process(delta: float) -> void:
	actor_time += delta
	carousel_timer += delta
	for team in ["red", "blue"]:
		var fighters: Array = soldiers[team]
		var origins: Array = soldier_origins[team]
		for i in range(fighters.size()):
			var node: Node3D = fighters[i]
			var start: Vector3 = origins[i]
			var sway := actor_time * 1.9 + float(i) * 1.47
			if not external_combat_control:
				node.position = start + Vector3(sin(sway) * 0.30, absf(sin(sway * 1.4)) * 0.07, cos(sway) * 0.23)
				node.rotation.y = sin(sway * 0.60) * 0.18
	var red_crystal: MeshInstance3D = crystal_meshes["red"]
	var blue_crystal: MeshInstance3D = crystal_meshes["blue"]
	red_crystal.rotation.y += delta * 0.7
	blue_crystal.rotation.y -= delta * 0.7
	if carousel_timer >= 9.0:
		carousel_timer = 0.0
		carousel_offset += MAX_VISIBLE_PER_TEAM
		update_players(last_players, last_contributions)

func update_players(player_data: Dictionary, scores: Dictionary) -> void:
	last_players = player_data.duplicate()
	last_contributions = scores.duplicate()
	for team in ["red", "blue"]:
		var members: Array[String] = []
		for key in player_data.keys():
			if str(player_data[key]) == team:
				members.append(str(key))
		members.sort_custom(func(a: String, b: String) -> bool:
			return int(scores.get(a, 0)) > int(scores.get(b, 0))
		)
		var lead: String = members[0] if members.size() > 0 else "CAPITAINE IA"
		var ch_label: Label3D = champion_labels[team]
		ch_label.text = "CHAMPION: " + lead.substr(0, 13) if members.size() > 0 else lead
		var offset := carousel_offset % maxi(1, members.size())
		var names: Array = labels[team]
		for i in range(names.size()):
			var label: Label3D = names[i]
			if members.size() > 0 and i < mini(members.size(), MAX_VISIBLE_PER_TEAM):
				label.text = members[(i + offset) % members.size()].substr(0, 13)
				label.modulate = Color.WHITE
			else:
				label.text = "BOT " + str(i + 1)
				label.modulate = GOLD

func set_health(team: String, hp: float) -> void:
	if not crystal_meshes.has(team):
		return
	var shard: MeshInstance3D = crystal_meshes[team]
	var f := clampf(hp / 100.0, 0.08, 1.0)
	shard.scale = Vector3(0.74 * f, 1.30 * f, 0.74 * f)

func strike(attacker_team: String, damage: float, reason: String = "EPEE") -> void:
	var idx := 0 if attacker_team == "red" else 1
	if champions.size() < 2:
		return
	var attacker := champions[idx]
	var origin := Vector3(-2.6, 0, 0) if idx == 0 else Vector3(2.6, 0, 0)
	var step := 0.55 if idx == 0 else -0.55
	var swing := swords[idx]
	var timeline := create_tween()
	timeline.tween_property(attacker, "position", origin + Vector3(step, 0, 0.12), 0.14)
	timeline.parallel().tween_property(swing, "rotation_degrees:z", -60.0 if idx == 0 else 60.0, 0.14)
	timeline.tween_property(attacker, "position", origin, 0.25)
	timeline.parallel().tween_property(swing, "rotation_degrees:z", 0.0, 0.25)
	var target := "blue" if idx == 0 else "red"
	_popup(target, "-%d PV" % int(ceil(damage)), Color("#ffe6a1"))

func reaction(team: String, kind: String) -> void:
	var words := {"heal": "+ SOIN", "defend": "BOUCLIER", "gift": "CADEAU !"}
	_popup(team, str(words.get(kind, kind)).to_upper(), Color("#8bffcb") if kind == "heal" else GOLD)

func _popup(team: String, title: String, color: Color) -> void:
	var side := -1.0 if team == "red" else 1.0
	var node := Node3D.new()
	node.position = Vector3(side * 4.0, 2.2, 0.4)
	add_child(node)
	var text_label := _tag(node, title, 0, color)
	text_label.font_size = 41
	var tween := create_tween()
	tween.tween_property(node, "position:y", 3.15, 0.65)
	tween.parallel().tween_property(text_label, "transparency", 1.0, 0.65)
	tween.tween_callback(node.queue_free)
