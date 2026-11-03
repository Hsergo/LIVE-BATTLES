extends Node3D
## Orchestrateur : 12 combattants physiques, lignes d'assaut, choix de cible et
## degats sur le cristal SEULEMENT apres un coup de lame ou un combattant K.O.

signal damage_crystal(team: String, amount: float)
signal battle_notice(text: String)
signal physics_telemetry(hit_count: int, parry_count: int, knockout_count: int)

var arena: Node3D
var units: Dictionary = {"red": [], "blue": []}
var hero: Dictionary = {}
var crystal_areas: Dictionary = {}
var particles: Array[Node3D] = []
var fight_time := 0.0
var hit_count := 0
var parry_count := 0
var ko_count := 0
var physics_active := true

func _glow(parent: Node3D, dimensions: Vector3, point: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = point
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.85
	instance.material_override = material
	parent.add_child(instance)
	return instance

func setup(arena_node: Node3D, champion_visuals: Array[Node3D]) -> void:
	arena = arena_node
	arena.set("external_combat_control", true)
	var unit_script = load("res://scripts/combat_unit.gd")
	var sides := ["red", "blue"]
	var lanes := [-3.0, -1.65, -0.70, 1.65, 3.0]
	for side in sides:
		var red := side == "red"
		var start_x := -3.8 if red else 3.8
		var base_x := 4.8 if red else -4.8
		var target_base := Vector3(base_x, 0.0, 0.0)
		var battle_visuals: Array = arena.get("soldiers")[side]
		for slot in range(6):
			var artwork: Node3D = champion_visuals[0 if red else 1] if slot == 0 else battle_visuals[slot - 1]
			var z := 0.0 if slot == 0 else float(lanes[slot - 1])
			var spawn := Vector3(-2.6 if red else 2.6, 0.0, 0.0) if slot == 0 else Vector3(start_x, 0.0, z)
			var soldier: CharacterBody3D = unit_script.new()
			soldier.name = ("Red" if red else "Blue") + "Fighter" + str(slot)
			add_child(soldier)
			soldier.call("initialize", side, slot, artwork, spawn, target_base)
			soldier.connect("hit_landed", _hit_confirmed)
			soldier.connect("hit_parried", _parry_confirmed)
			soldier.connect("crystal_landed", _crystal_confirmed)
			soldier.connect("fallen", _knockout)
			units[side].append(soldier)
			if slot == 0:
				hero[side] = soldier
		_make_crystal_sensor(side)
	battle_notice.emit("ARMEE PRETE : 12 COMBATTANTS PHYSIQUES")

func _make_crystal_sensor(side: String) -> void:
	var red := side == "red"
	var crystal := Area3D.new()
	crystal.name = "CrystalHitbox_" + side
	crystal.collision_layer = 4
	crystal.collision_mask = 0
	crystal.monitorable = true
	crystal.monitoring = false
	crystal.set_meta("crystal_team", side)
	crystal.position = Vector3(-5.08 if red else 5.08, 1.30, 0)
	add_child(crystal)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.56, 2.5, 6.8)
	shape.shape = box
	crystal.add_child(shape)
	crystal_areas[side] = crystal
	var team_color := Color("#ff6274") if red else Color("#50c0ff")
	for z in [-3.2, 3.2]:
		_glow(self, Vector3(0.3, 2.4, 0.3), Vector3(-5.10 if red else 5.10, 1.2, z), team_color)
	_glow(self, Vector3(0.35, 0.16, 6.5), Vector3(-5.10 if red else 5.10, 2.46, 0), team_color)

func _physics_process(_delta: float) -> void:
	if not physics_active:
		return
	for side in ["red", "blue"]:
		var opponent := "blue" if side == "red" else "red"
		var opponents: Array = units[opponent]
		for u in units[side]:
			if u.get("active") != true:
				continue
			var nearest: Node3D = null
			var best := 9999.0
			for enemy in opponents:
				if enemy.get("active") != true:
					continue
				var lane_penalty := absf(u.global_position.z - enemy.global_position.z) * 1.9
				var distance := u.global_position.distance_to(enemy.global_position) + lane_penalty
				if distance < best:
					best = distance
					nearest = enemy
			u.set("target", nearest)

func _text_fx(where: Vector3, label: String, color: Color) -> void:
	if particles.size() > 48:
		return
	var holder := Node3D.new()
	holder.position = where + Vector3(0, 2.25, 0)
	add_child(holder)
	var font_label := Label3D.new()
	font_label.text = label
	font_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	font_label.font_size = 40
	font_label.pixel_size = 0.008
	font_label.modulate = color
	font_label.outline_size = 11
	font_label.no_depth_test = true
	holder.add_child(font_label)
	particles.append(holder)
	var timeline := create_tween()
	timeline.tween_property(holder, "position:y", holder.position.y + 0.75, 0.60)
	timeline.parallel().tween_property(font_label, "transparency", 1.0, 0.60)
	timeline.tween_callback(func():
		particles.erase(holder)
		if is_instance_valid(holder):
			holder.queue_free()
	)

func _hit_confirmed(attacker: Node3D, victim: Node3D, amount: float) -> void:
	hit_count += 1
	_text_fx(victim.global_position, "-%d PV" % int(ceil(amount)), Color("#ffd1a5"))
	physics_telemetry.emit(hit_count, parry_count, ko_count)

func _parry_confirmed(attacker: Node3D, defender: Node3D) -> void:
	parry_count += 1
	_text_fx(defender.global_position, "PARADE !", Color("#77ecff"))
	battle_notice.emit("PARADE %s : coup bloque" % str(defender.get("team")).to_upper())
	physics_telemetry.emit(hit_count, parry_count, ko_count)

func _crystal_confirmed(attacker: Node3D, target_side: String, amount: float) -> void:
	damage_crystal.emit(target_side, amount)
	_text_fx(Vector3(-4.7 if target_side == "red" else 4.7, 0, -2.6), "-%d CRISTAL" % int(amount), Color("#fff1a1"))

func _knockout(unit: Node3D, fallen_side: String) -> void:
	ko_count += 1
	_text_fx(unit.global_position, "K.O.", Color("#ffec8d"))
	damage_crystal.emit(fallen_side, 2.0)
	physics_telemetry.emit(hit_count, parry_count, ko_count)

func command(side: String, kind: String) -> void:
	if not hero.has(side):
		return
	var leader: Node3D = hero[side]
	if leader.get("active") != true:
		for u in units[side]:
			if u.get("active") == true:
				leader = u
				break
	if leader.get("active") != true:
		return
	match kind:
		"attack":
			leader.set("attack_cooldown", 0.0)
			leader.call("start_attack")
			_text_fx(leader.global_position, "CHARGE !", Color("#ffe091"))
		"defend":
			leader.call("raise_guard", 1.2)
			for u in units[side]:
				if u != leader and u.get("active") == true:
					u.call("raise_guard", 0.55)
			_text_fx(leader.global_position, "DEFENSE !", Color("#85efff"))
		"heal":
			for u in units[side]:
				if u.get("active") == true:
					u.call("heal", 8.0)
			_text_fx(leader.global_position, "+ SOIN", Color("#83ffb3"))

func gift_power(side: String, points: int) -> void:
	var seconds := clampf(2.0 + float(points) * 0.18, 3.0, 8.0)
	for u in units[side]:
		u.call("empower", seconds)
	if hero.has(side):
		_text_fx(hero[side].global_position, "BOOST %d s" % int(seconds), Color("#ffe091"))

func restart_round() -> void:
	for side in ["red", "blue"]:
		for u in units[side]:
			u.set("respawn_time", 0.01)
			u.call("_respawn")
			u.set("battle_paused", false)
	physics_active = true

func pause_round(paused: bool) -> void:
	physics_active = not paused
	for side in ["red", "blue"]:
		for u in units[side]:
			u.set("battle_paused", paused)
