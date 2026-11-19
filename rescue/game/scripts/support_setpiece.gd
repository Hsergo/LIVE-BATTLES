extends Node3D
## Three distinct support stations; geometry reacts to completed free actions.
var model: RefCounted
var identity := ""
var parts: Array[Node3D] = []
var lights: Array[MeshInstance3D] = []

func setup(game: RefCounted) -> void:
	model = game
	position = Vector3(-8,0.12,6)
	sync()

func box(parent: Node3D, at: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.75
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	return mesh

func _build(kind: String) -> void:
	for child in get_children():
		child.free()
	parts.clear()
	lights.clear()
	box(self,Vector3(0,0,0),Vector3(7,0.18,4),Color("#b6b49b"))
	for step in range(3):
		var part := Node3D.new()
		add_child(part)
		part.position.x = float(step-1)*2.15
		parts.append(part)
		match kind:
			"convoy":
				box(part,Vector3(0,0.65,0),Vector3(1.65,0.8,2.5),Color("#276c81"))
				box(part,Vector3(0,1.35,0.55),Vector3(1.5,0.8,0.9),Color("#f2c965"))
				box(part,Vector3(0,1.4,1.02),Vector3(1.2,0.42,0.04),Color("#b4e5f0"))
				for side in [-1,1]:
					for axle in [-1,1]:
						box(part,Vector3(float(side)*0.85,0.4,float(axle)*0.8),Vector3(0.18,0.5,0.5),Color("#263844"))
				box(part,Vector3(0,1.3,-0.55),Vector3(1.2,0.6,0.8),Color("#c09562"))
			"power":
				box(part,Vector3(0,0.65,0),Vector3(1.5,1.1,1.4),Color("#ecbd57"))
				for stripe in range(4):
					box(part,Vector3(-0.45+float(stripe)*0.3,0.7,0.72),Vector3(0.12,0.55,0.03),Color("#233e4e"))
				box(part,Vector3(0,2.0,-0.5),Vector3(0.12,3.0,0.12),Color("#4f6671"))
				box(part,Vector3(0,3.3,-0.5),Vector3(1.8,0.15,0.15),Color("#cbd5c7"))
			"refuge":
				box(part,Vector3(0,0.85,0),Vector3(1.8,1.5,2.4),Color("#e9d9b1"))
				var roof := box(part,Vector3(0,1.7,0),Vector3(1.95,0.35,2.5),Color("#b45750"))
				roof.rotation.z = 0.08
				box(part,Vector3(0,1,1.22),Vector3(0.2,0.6,0.04),Color("#dc5953"))
				box(part,Vector3(0,1,1.23),Vector3(0.6,0.2,0.04),Color("#dc5953"))
		lights.append(box(part,Vector3(0,2.0,1.3),Vector3(0.3,0.3,0.3),Color("#daab60")))

func sync() -> void:
	if model == null:
		return
	visible = str(model.get("status"))=="CHALLENGE"
	if not visible:
		return
	var session: RefCounted = model.get("marathon")
	var info: Dictionary = session.call("challenge_info")
	var kind := str(info.get("id",""))
	if kind != identity:
		identity = kind
		_build(kind)
	var stage := int(session.get("challenge_stage"))
	var progress := float(session.get("challenge_progress"))/maxf(1,float(session.get("challenge_goal")))
	for i in range(parts.size()):
		var amount := 1.0 if i<stage else (progress if i==stage else 0.0)
		parts[i].scale.y = 0.2+0.8*amount
		var mat := lights[i].material_override as StandardMaterial3D
		mat.albedo_color = Color("#78dfb0") if i<stage else Color("#e9ba68")
		mat.emission_enabled = i<=stage
		mat.emission = mat.albedo_color
