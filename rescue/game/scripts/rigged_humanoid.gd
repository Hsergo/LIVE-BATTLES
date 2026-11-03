extends Node3D
## CC0 Quaternius skinned humanoid adapter.
## Authentic mesh with Skeleton3D / skinned vertices, not a primitive placeholder.
## Animation clips are NOT included in the source GLB. Locomotion and gestures
## are generated from procedural bone poses until reviewed UAL2 clips are imported.
const MODEL_PATH := "res://assets/characters/base_male_rigged.glb"
const BONE_NAMES := [
	"pelvis","spine_02","Head",
	"upperarm_l","lowerarm_l","upperarm_r","lowerarm_r",
	"thigh_l","calf_l","thigh_r","calf_r"
]
var skeleton: Skeleton3D
var model_root: Node3D
var bone_indices: Dictionary = {}
var base_pose: Dictionary = {}
var clock := 0.0
var installed := false
var state := "idle"
var scale_factor := 1.0

func setup(target_scale: float = 1.0) -> bool:
	if not ResourceLoader.exists(MODEL_PATH):
		return false
	var source: Resource = load(MODEL_PATH)
	if not (source is PackedScene):
		return false
	model_root = (source as PackedScene).instantiate() as Node3D
	if model_root == null:
		return false
	add_child(model_root)
	skeleton = _find_skeleton(model_root)
	if skeleton == null:
		model_root.queue_free()
		model_root = null
		return false
	for key in BONE_NAMES:
		var index := skeleton.find_bone(key)
		if index >= 0:
			bone_indices[key] = index
			base_pose[key] = skeleton.get_bone_pose_rotation(index)
	scale_factor = target_scale
	scale = Vector3.ONE * scale_factor
	installed = bone_indices.has("pelvis") and bone_indices.has("thigh_l") and bone_indices.has("upperarm_l")
	return installed

func _find_skeleton(parent: Node) -> Skeleton3D:
	if parent is Skeleton3D:
		return parent as Skeleton3D
	for child in parent.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func animate(delta: float, next_state: String, moving_speed: float = 1.0) -> void:
	if not installed or skeleton == null:
		return
	state = next_state
	clock += minf(0.12, maxf(0.0,delta)) * maxf(0.3,moving_speed)
	var t := clock
	var walk := state == "walk" or state == "run"
	var work := state == "build" or state == "repair"
	var rescue := state == "rescue" or state == "celebrate"
	var gait := sin(t * (10.4 if state=="run" else 7.6))
	var breath := sin(t*1.6)
	var stride := 0.64 if walk else 0.0
	var effort := sin(t*10.8) if work else 0.0
	_pose("pelvis",Vector3(0,0,0.03*breath))
	_pose("spine_02",Vector3(0.08*breath if work else 0.025*breath,0,0))
	_pose("Head",Vector3(-0.03*breath,0.06*sin(t*0.7),0))
	_pose("thigh_l",Vector3(stride*gait,0,0))
	_pose("thigh_r",Vector3(-stride*gait,0,0))
	_pose("calf_l",Vector3(maxf(0.0,-gait)*0.43 if walk else 0.04,0,0))
	_pose("calf_r",Vector3(maxf(0.0,gait)*0.43 if walk else 0.04,0,0))
	var left_arm := -gait*0.47 if walk else 0.07*breath
	var right_arm := gait*0.47 if walk else -0.06*breath
	if work:
		left_arm = -0.70+effort*0.58
		right_arm = -1.1+effort*0.74
	elif rescue:
		left_arm = -0.75
		right_arm = -1.55+0.26*sin(t*5.2)
	_pose("upperarm_l",Vector3(left_arm,0,-0.09))
	_pose("upperarm_r",Vector3(right_arm,0,0.09))
	_pose("lowerarm_l",Vector3(-0.27 if work else -0.11,0,0))
	_pose("lowerarm_r",Vector3(-0.48 if work or rescue else -0.1,0,0))

func _pose(name: String, euler: Vector3) -> void:
	if not bone_indices.has(name):
		return
	var idx: int = int(bone_indices[name])
	var offset := Quaternion.from_euler(euler)
	var baseline: Quaternion = base_pose[name]
	skeleton.set_bone_pose_rotation(idx,baseline * offset)

func is_rigged() -> bool:
	return installed

func rig_bone_count() -> int:
	return skeleton.get_bone_count() if skeleton != null else 0
