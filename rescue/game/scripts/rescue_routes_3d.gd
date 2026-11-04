extends RefCounted
## Physically staged evacuation routes shared by villagers, boats and helicopters.
## All positions are in world coordinates, and no TikTok account is generated.
## Scene-specific transport is activated only after a real rescue action.
const BREAKS := [0.0,0.15,0.25,0.76,0.88,1.0]

static func _points(scene: String, start: Vector3, refuge: Vector3, lane: int) -> Array[Vector3]:
	var lane_offset := float(clampi(lane,0,2))
	var z := -0.85+lane_offset*0.83
	match scene:
		"bridge":
			return [start,Vector3(-8.8,0.15,z),Vector3(-7.0,1.33,z),
				Vector3(7.0,1.33,z),Vector3(8.8,0.15,-1.5+float(clampi(lane,0,2))*0.4),refuge]
		"dike","dam":
			z = 9.0+lane_offset*0.69
			return [start,Vector3(-7.1,0.12,z),Vector3(-5.35,0.43,z),
				Vector3(5.35,0.43,z),Vector3(7.0,0.12,z+1.4),refuge]
		"lighthouse":
			z = 2.4+lane_offset*0.69
			return [start,Vector3(-7.0,0.15,z),Vector3(-5.35,0.43,z),
				Vector3(5.35,0.43,z),Vector3(9.0,0.15,-1.5),refuge]
		"helipad":
			z = 3.15+lane_offset*0.34
			return [start,Vector3(-4.4,0.15,z),Vector3(-1.9,1.55,z),
				Vector3(9.0,4.4,z),Vector3(11.2,0.45,-1.8),refuge]
	return [start,Vector3(-8.0,0.15,z),Vector3(-5.9,0.5,z),
		Vector3(5.9,0.5,z),Vector3(8.0,0.15,z),refuge]

static func _ease(t: float) -> float:
	var v := clampf(t,0.0,1.0)
	return v*v*(3.0-2.0*v)

static func position(scene: String, progress: float, start: Vector3, refuge: Vector3, lane: int) -> Vector3:
	var p := clampf(progress,0.0,1.0)
	var points := _points(scene,start,refuge,lane)
	for i in range(BREAKS.size()-1):
		if p <= float(BREAKS[i+1]):
			var k := (p-float(BREAKS[i]))/(float(BREAKS[i+1])-float(BREAKS[i]))
			# Scene's moving vehicle has linear motion across the channel;
			# approach/boarding/disembarkation are eased to prevent jerks.
			var vehicle := (scene in ["lighthouse","dike","dam","helipad"] and i==2)
			return points[i].lerp(points[i+1],clampf(k,0.0,1.0) if vehicle else _ease(k))
	return refuge

static func stage(scene: String, progress: float) -> String:
	var p := clampf(progress,0.0,1.0)
	if p < 0.15:
		return "approach"
	if p < 0.25:
		return "boarding"
	if p < 0.76:
		if scene=="helipad":
			return "flight"
		return "boat" if scene in ["dike","dam","lighthouse"] else "bridge"
	if p < 0.88:
		return "disembark"
	return "arrival"

static func transported(scene: String, progress: float) -> bool:
	return stage(scene,progress) in ["boat","flight"]

static func vehicle_position(scene: String, progress: float, lane: int) -> Vector3:
	var z := (2.4 if scene=="lighthouse" else 9.0)+float(clampi(lane,0,2))*0.69
	var p := clampf((progress-0.25)/0.51,0.0,1.0)
	if scene=="helipad":
		var z_air := 3.15+float(clampi(lane,0,2))*0.34
		return Vector3(lerpf(-1.9,9.0,p),lerpf(2.45,5.3,p),z_air)
	return Vector3(lerpf(-5.35,5.35,p),0.19,z)

static func has_vehicle(scene: String) -> bool:
	return scene in ["dike","dam","lighthouse","helipad"]
