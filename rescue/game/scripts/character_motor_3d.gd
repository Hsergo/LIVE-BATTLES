extends CharacterBody3D
## Reusable collision-aware, deterministic character motor.
## Called from the parent crowd manager during _physics_process only.
## Layer 2: villagers; Layer 4: construction crew.
## No fake TikTok participants are created here.

var target_position := Vector3.ZERO
var collision_radius := 0.24
var collision_height := 1.55
var is_moving := false
var distance_left := 0.0

func configure(group_layer: int, radius: float, height: float) -> void:
	collision_layer = group_layer
	collision_mask = group_layer | 1
	collision_radius = maxf(0.15,radius)
	collision_height = maxf(height,collision_radius*2.0+0.1)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	max_slides = 3
	safe_margin = 0.007
	var capsule := CapsuleShape3D.new()
	capsule.radius = collision_radius
	capsule.height = collision_height
	var collider := CollisionShape3D.new()
	collider.name = "CollisionCapsule"
	collider.shape = capsule
	collider.position = Vector3(0,collision_height*0.5,0)
	add_child(collider)

func move_to(destination: Vector3, speed: float, delta: float) -> Vector3:
	target_position = destination
	var d := clampf(delta,0.0,0.1)
	var delta_position := destination-position
	distance_left = delta_position.length()
	if d < 0.0001 or distance_left < 0.045:
		velocity = Vector3.ZERO
		is_moving = false
		return Vector3.ZERO
	var requested := delta_position.normalized()*minf(speed,distance_left/d)
	var before := position
	velocity = requested
	move_and_slide()
	var travelled := position-before
	is_moving = travelled.length_squared()>0.000001
	# Do not teleport through another person if a walkway is crowded.
	# A blocked pedestrian stands in the queue until the route opens.
	if get_slide_collision_count() > 0:
		velocity = velocity*0.65
	return travelled

func has_physical_collider() -> bool:
	return get_node_or_null("CollisionCapsule") != null
