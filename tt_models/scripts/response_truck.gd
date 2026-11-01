extends Node3D
## Wheels follow distance, heading eases independently of the collision-safe route.
const Art = preload("res://tt_models/scripts/models.gd")
var desired_heading := 0.0
var wheels: Array[Node3D] = []
var lamps: Array[StandardMaterial3D] = []
var previous := Vector3.ZERO
var clock := 0.0
var wheel_angle := 0.0

func _ready() -> void:
	Art.box(self,Vector3(0,0.35,0),Vector3(0.65,0.40,1.1),"#b84736")
	Art.box(self,Vector3(0,0.68,0.28),Vector3(0.61,0.3,0.44),"#d55f43")
	Art.box(self,Vector3(0,0.7,0.51),Vector3(0.48,0.16,0.03),"#99c4bf")
	Art.box(self,Vector3(0,0.36,0.58),Vector3(0.65,0.09,0.08),"#adada0")
	for side in [-1,1]:
		Art.box(self,Vector3(side*0.24,0.48,0.56),Vector3(0.12,0.09,0.03),"#eddaa5")
		Art.box(self,Vector3(side*0.20,0.63,-0.2),Vector3(0.035,0.06,0.75),"#c9c4ac")
		for rung in 5:
			Art.box(self,Vector3(0,0.63,-0.48+rung*0.14),Vector3(0.4,0.035,0.035),"#c9c4ac")
		var lamp := Art.box(self,Vector3(side*0.13,0.88,0.28),Vector3(0.20,0.10,0.16),"#4e9dbf")
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#428bb6")
		material.emission_enabled = true
		material.emission = Color("#76cef0")
		lamp.material_override = material
		lamps.append(material)
		for z in [-0.35,0.35]:
			var pivot := Node3D.new()
			pivot.position = Vector3(side*0.34,0.2,z)
			add_child(pivot)
			var tyre := Art.cylinder(pivot,Vector3.ZERO,0.17,0.10,"#3f4441")
			tyre.rotation.z = PI/2
			Art.box(pivot,Vector3(side*0.06,0,0),Vector3(0.02,0.23,0.045),"#b4b4a3")
			Art.box(pivot,Vector3(side*0.06,0,0),Vector3(0.02,0.045,0.23),"#b4b4a3")
			wheels.append(pivot)
	previous = position

func reset_motion() -> void:
	previous = position
	clock = 0

func _process(delta: float) -> void:
	if not visible:
		previous = position
		return
	clock += delta
	wheel_angle += position.distance_to(previous)/maxf(0.01,0.17*scale.x)
	previous = position
	rotation.y = lerp_angle(rotation.y,desired_heading,1-exp(-delta*11))
	for wheel in wheels: wheel.rotation.x = wheel_angle
	for i in lamps.size():
		var on := fmod(clock*5+i*0.5,1.0) < 0.4
		lamps[i].emission_energy_multiplier = 2.0 if on else 0.05
		lamps[i].albedo_color = Color("#94dbec") if on else Color("#386b90")
