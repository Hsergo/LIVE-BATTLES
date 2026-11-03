extends CharacterBody3D
## Un combattant : mouvement CharacterBody3D, parade et impact par chevauchement
## physique Area3D (epee vers hitbox). Aucun degat sans collision.

signal hit_landed(attacker: Node3D, victim: Node3D, damage: float)
signal hit_parried(attacker: Node3D, victim: Node3D)
signal crystal_landed(attacker: Node3D, crystal_team: String, damage: float)
signal fallen(unit: Node3D, team: String)

const HURT_LAYER := 2
const CRYSTAL_LAYER := 4
const REACH := 1.73
const WINDUP := 0.17
const ACTIVE_END := 0.52
const SWING_END := 0.80

var team := "red"
var index := 0
var champion := false
var max_hp := 45.0
var hp := 45.0
var active := true
var respawn_time := 0.0
var slow_time := 0.0
var guard_time := 0.0
var attack_elapsed := -1.0
var attack_cooldown := 0.7
var attack_multiplier := 1.0
var boost_time := 0.0
var target: Node3D = null
var base_target := Vector3.ZERO
var spawn_point := Vector3.ZERO
var lane_z := 0.0
var unit_art: Node3D
var sword_pivot: Node3D
var hit_area: Area3D
var hurt_area: Area3D
var guard_mesh: MeshInstance3D
var health_mesh: MeshInstance3D
var spark_mesh: MeshInstance3D
var hit_ids: Dictionary = {}
var elapsed := 0.0
var stagger_push := Vector3.ZERO
var battle_paused := false

func _box(parent: Node3D, dimensions: Vector3, at: Vector3, color: Color, bright: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if bright:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.0
	model.material_override = material
	parent.add_child(model)
	return model

func initialize(side: String, slot: int, art: Node3D, start: Vector3, enemy_base: Vector3) -> void:
	team = side
	index = slot
	champion = slot == 0
	max_hp = 95.0 if champion else 39.0
	hp = max_hp
	spawn_point = start
	base_target = enemy_base
	lane_z = start.z
	unit_art = art
	position = start
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 1
	safe_margin = 0.02
	art.reparent(self)
	art.position = Vector3.ZERO
	var original_sword: Node3D = art.get_node_or_null("SwordVisual") as Node3D
	if original_sword:
		original_sword.visible = false

	var body := CollisionShape3D.new()
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = 0.46 if champion else 0.29
	body_shape.height = 2.45 if champion else 1.43
	body.shape = body_shape
	body.position.y = 1.23 if champion else 0.75
	add_child(body)

	hurt_area = Area3D.new()
	hurt_area.collision_layer = HURT_LAYER
	hurt_area.collision_mask = 0
	hurt_area.monitoring = false
	hurt_area.monitorable = true
	hurt_area.set_meta("combat_fighter", self)
	add_child(hurt_area)
	var hurt_collision := CollisionShape3D.new()
	var hurt_shape := CapsuleShape3D.new()
	hurt_shape.radius = 0.58 if champion else 0.37
	hurt_shape.height = 2.65 if champion else 1.50
	hurt_collision.shape = hurt_shape
	hurt_collision.position.y = 1.25 if champion else 0.78
	hurt_area.add_child(hurt_collision)

	sword_pivot = Node3D.new()
	sword_pivot.position = Vector3(0, 1.25 if champion else 0.76, 0)
	add_child(sword_pivot)
	var scale_factor := 1.0 if champion else 0.70
	_box(sword_pivot, Vector3(0.12, 0.35, 0.14) * scale_factor, Vector3(0, 0.05, 0.4 * scale_factor), Color("#9b7249"))
	_box(sword_pivot, Vector3(0.55, 0.11, 0.13) * scale_factor, Vector3(0, 0.28 * scale_factor, 0.48 * scale_factor), Color("#ffe496"))
	_box(sword_pivot, Vector3(0.13, 1.08, 0.10) * scale_factor, Vector3(0, 0.82 * scale_factor, 0.52 * scale_factor), Color("#c6edff"), true)

	hit_area = Area3D.new()
	hit_area.collision_layer = 0
	hit_area.collision_mask = HURT_LAYER | CRYSTAL_LAYER
	hit_area.monitoring = true
	hit_area.monitorable = false
	sword_pivot.add_child(hit_area)
	var blade_hit := CollisionShape3D.new()
	var blade_shape := SphereShape3D.new()
	blade_shape.radius = 0.73 if champion else 0.60
	blade_hit.shape = blade_shape
	blade_hit.position = Vector3(0, 0.27, 1.04 if champion else 0.90)
	hit_area.add_child(blade_hit)

	guard_mesh = _box(self, Vector3(1.18, 1.6, 0.10) if champion else Vector3(0.72, 1.1, 0.08), Vector3(0, 1.20 if champion else 0.75, 0.63 if champion else 0.41), Color("#5fe7fa"), true)
	guard_mesh.visible = false

	var background := _box(self, Vector3(1.20, 0.12, 0.12) if champion else Vector3(0.74, 0.10, 0.10), Vector3(0, 3.35 if champion else 2.02, 0), Color("#13212f"))
	health_mesh = _box(self, Vector3(1.16, 0.09, 0.13) if champion else Vector3(0.70, 0.08, 0.11), background.position + Vector3(0, 0, 0.012), Color("#6dffab"), true)
	spark_mesh = _box(self, Vector3(0.56, 0.56, 0.56), Vector3(0, 1.4, 0.15), Color("#ffe8ae"), true)
	spark_mesh.visible = false
	attack_cooldown = randf_range(0.2, 0.9)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if battle_paused:
		velocity = Vector3.ZERO
		_update_cosmetic()
		return
	if not active:
		respawn_time -= delta
		if respawn_time <= 0.0:
			_respawn()
		return

	slow_time = maxf(0, slow_time - delta)
	guard_time = maxf(0, guard_time - delta)
	attack_cooldown = maxf(0, attack_cooldown - delta)
	boost_time = maxf(0, boost_time - delta)
	guard_mesh.visible = guard_time > 0
	_update_cosmetic()

	var point := base_target
	var enemy_present := false
	if is_instance_valid(target) and target.get("active") == true:
		point = target.global_position
		enemy_present = true
	var towards := point - global_position
	towards.y = 0.0
	var distance := towards.length()
	if distance > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(towards.x, towards.z), minf(1, delta * 8.0))
	var stop_distance := REACH * 0.82 if enemy_present else 1.10
	var desired := Vector3.ZERO
	if slow_time <= 0 and distance > stop_distance:
		desired = towards.normalized() * (2.15 if champion else 2.45)
		desired.z += clampf((lane_z - global_position.z) * 0.65, -0.7, 0.7)
	if slow_time > 0:
		desired = Vector3.ZERO
	velocity = velocity.lerp(desired + stagger_push, minf(1, delta * 10.0))
	stagger_push = stagger_push.lerp(Vector3.ZERO, minf(1, delta * 10.0))
	move_and_slide()
	global_position.x = clampf(global_position.x, -5.2, 5.2)
	global_position.z = clampf(global_position.z, -3.3, 3.3)

	if attack_elapsed >= 0:
		attack_elapsed += delta
		var fraction := clampf(attack_elapsed / SWING_END, 0, 1)
		sword_pivot.rotation.y = lerpf(-1.13, 1.13, fraction)
		sword_pivot.rotation.z = sin(fraction * PI) * (0.22 if team == "red" else -0.22)
		if attack_elapsed >= WINDUP and attack_elapsed <= ACTIVE_END:
			_detect_contacts()
		if attack_elapsed >= SWING_END:
			attack_elapsed = -1.0
			sword_pivot.rotation = Vector3.ZERO
	else:
		sword_pivot.rotation.y = sin(elapsed * 2.2 + index) * 0.14
		if attack_cooldown <= 0 and slow_time <= 0 and distance <= REACH + (0.32 if enemy_present else 0.2):
			if enemy_present and randf() < 0.13:
				raise_guard(0.35)
			else:
				start_attack()

func _update_cosmetic() -> void:
	if health_mesh != null:
		health_mesh.scale.x = clampf(hp / max_hp, 0.0, 1.0)
	if unit_art != null and active:
		unit_art.position.y = absf(sin(elapsed * 4.0 + index * 1.3)) * 0.08
		unit_art.rotation.z = sin(elapsed * 3.2 + index) * 0.025
	if spark_mesh != null:
		spark_mesh.visible = slow_time > 0.04 and slow_time < 0.28

func start_attack() -> void:
	if not active or attack_elapsed >= 0 or slow_time > 0 or battle_paused:
		return
	attack_elapsed = 0.0
	hit_ids.clear()
	attack_cooldown = (1.35 if champion else 1.55) / (1.5 if boost_time > 0 else 1.0)
	sword_pivot.rotation.y = -1.13

func raise_guard(seconds: float = 0.75) -> void:
	if not active or battle_paused:
		return
	guard_time = maxf(guard_time, seconds)
	sword_pivot.rotation.y = -0.45
	attack_cooldown = maxf(attack_cooldown, 0.4)

func receive_damage(amount: float, from_position: Vector3) -> void:
	if not active:
		return
	hp = maxf(0, hp - amount)
	slow_time = maxf(slow_time, 0.22)
	var direction := global_position - from_position
	direction.y = 0
	if direction.length() > 0.1:
		stagger_push = direction.normalized() * 1.6
	if hp <= 0:
		_fall()

func _fall() -> void:
	active = false
	respawn_time = 5.0 if champion else 4.5
	velocity = Vector3.ZERO
	hurt_area.monitorable = false
	collision_layer = 0
	collision_mask = 0
	attack_elapsed = -1.0
	guard_mesh.visible = false
	unit_art.visible = false
	fallen.emit(self, team)

func _respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	hp = max_hp
	slow_time = 0
	guard_time = 0
	active = true
	unit_art.visible = true
	hurt_area.monitorable = true
	collision_layer = 1
	collision_mask = 1
	attack_cooldown = 1.0
	health_mesh.scale.x = 1.0

func heal(amount: float) -> void:
	if active:
		hp = minf(max_hp, hp + amount)

func empower(seconds: float) -> void:
	boost_time = maxf(boost_time, seconds)

func _detect_contacts() -> void:
	for area in hit_area.get_overlapping_areas():
		if area.has_meta("combat_fighter"):
			var opponent: Node3D = area.get_meta("combat_fighter")
			if not is_instance_valid(opponent) or opponent == self:
				continue
			if str(opponent.get("team")) == team or opponent.get("active") != true:
				continue
			var id := opponent.get_instance_id()
			if hit_ids.has(id):
				continue
			hit_ids[id] = true
			var protection := float(opponent.get("guard_time"))
			if protection > 0:
				opponent.set("guard_time", 0.0)
				slow_time = maxf(slow_time, 0.44)
				attack_elapsed = SWING_END + 0.01
				hit_parried.emit(self, opponent)
			else:
				var damage := (13.0 if champion else 8.5) * (1.45 if boost_time > 0 else 1.0)
				opponent.call("receive_damage", damage, global_position)
				hit_landed.emit(self, opponent, damage)
		elif area.has_meta("crystal_team"):
			var crystal_side := str(area.get_meta("crystal_team"))
			if crystal_side == team:
				continue
			var crystal_id := area.get_instance_id()
			if hit_ids.has(crystal_id):
				continue
			hit_ids[crystal_id] = true
			crystal_landed.emit(self, crystal_side, 4.0 if not champion else 7.0)
