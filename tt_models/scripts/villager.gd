extends Node3D
## Distance-driven gait: feet stop when the villager pauses at either destination.
const Art = preload("res://tt_models/scripts/models.gd")
var variant := 0
var skin_color := "#dfae7b"
var shirt_color := "#e8dec5"
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var distance := 0.0
var wait := 1.0
var target := Vector3(2.5,0.1,1.4)
var start := Vector3(-1.4,0.1,1.4)
var finish := Vector3(2.5,0.1,1.4)

func _ready() -> void:
	var skins := ["#dfae7b","#ba825d","#e7c29b","#cb956f","#f0cda9","#aa7654"]
	var shirts := ["#e8dec5","#e0c38d","#e0cfc5","#b9c9bd","#d7b7a3","#c3cbdb"]
	var vests := ["#3b7875","#8c4c3c","#626e98","#8a7748","#a05f72","#416573"]
	var cloth: String = vests[variant % vests.size()]
	skin_color = skins[variant % skins.size()]
	shirt_color = shirts[variant % shirts.size()]
	position = start
	for side in [-1,1]:
		var leg := Node3D.new()
		add_child(leg)
		leg.position = Vector3(side*0.10,0.34,0)
		Art.box(leg,Vector3(0,-0.12,0),Vector3(0.135,0.26,0.15),"#4f5e66")
		Art.box(leg,Vector3(0,-0.21,0.01),Vector3(0.145,0.05,0.16),"#87755b")
		Art.box(leg,Vector3(0,-0.27,0.045),Vector3(0.16,0.10,0.24),"#5e4735")
		legs.append(leg)
		var arm := Node3D.new()
		add_child(arm)
		arm.position = Vector3(side*0.23,0.66,0)
		Art.ball(arm,Vector3(0,-0.08,0),Vector3(0.15,0.24,0.16),shirt_color)
		Art.cylinder(arm,Vector3(0,-0.16,0),0.065,0.04,"#c9ba9b")
		Art.ball(arm,Vector3(0,-0.25,0),Vector3(0.13,0.14,0.13),skin_color)
		arms.append(arm)
	# Tunic, Anatolian patterned vest (yelek), red sash (kuşak) and collar
	Art.ball(self,Vector3(0,0.53,0),Vector3(0.46,0.50,0.31),shirt_color)
	Art.box(self,Vector3(0,0.55,0.01),Vector3(0.39,0.34,0.27),cloth)
	for side in [-1,1]:
		Art.box(self,Vector3(side*0.11,0.55,0.145),Vector3(0.13,0.32,0.03),Color(cloth).darkened(0.15).to_html())
		Art.box(self,Vector3(side*0.06,0.55,0.162),Vector3(0.025,0.30,0.02),"#d9b466")
	Art.box(self,Vector3(0,0.40,0.01),Vector3(0.41,0.09,0.28),"#b84a39")
	Art.box(self,Vector3(0.11,0.34,0.15),Vector3(0.07,0.12,0.03),"#9e3b2c")
	Art.cylinder(self,Vector3(0,0.72,0.02),0.14,0.06,"#d44b3a")
	# Head, ears, eyebrows, moustache and braided straw sun-hat
	Art.ball(self,Vector3(0,0.91,0),Vector3(0.38,0.40,0.35),skin_color)
	for side in [-1,1]:
		Art.ball(self,Vector3(side*0.185,0.90,0.0),Vector3(0.06,0.09,0.05),skin_color)
		Art.ball(self,Vector3(side*0.085,0.93,0.163),Vector3.ONE*0.036,"#3d3529")
		Art.box(self,Vector3(side*0.085,0.975,0.162),Vector3(0.065,0.018,0.02),"#594633").rotation.z = -side*0.12
		if variant % 2 == 0:
			Art.box(self,Vector3(side*0.048,0.845,0.176),Vector3(0.075,0.024,0.025),"#594633").rotation.z = -side*0.22
	Art.ball(self,Vector3(0,0.88,0.19),Vector3(0.08,0.08,0.07),"#d4a071")
	if variant % 3 == 0:
		Art.cylinder(self,Vector3(0,1.09,0),0.34,0.04,"#c7a55e")
		Art.cylinder(self,Vector3(0,1.11,0),0.31,0.04,"#e3c888")
		Art.cylinder(self,Vector3(0,1.19,0),0.19,0.17,"#e6cd93",0.15)
		Art.cylinder(self,Vector3(0,1.125,0),0.198,0.045,cloth)
	elif variant % 3 == 1:
		Art.ball(self,Vector3(0,1.08,-0.015),Vector3(0.40,0.21,0.37),cloth)
		Art.box(self,Vector3(0,1.075,0.20),Vector3(0.36,0.035,0.20),cloth)
	else:
		Art.ball(self,Vector3(0,1.07,-0.035),Vector3(0.43,0.30,0.42),cloth)
		for side in [-1,1]:
			Art.ball(self,Vector3(side*0.19,0.89,-0.02),Vector3(0.10,0.29,0.18),cloth)
		Art.ball(self,Vector3(0,0.81,-0.19),Vector3(0.18,0.32,0.17),cloth)

	# Bend the upper body at the hips without rotating planted feet through the ground.
	var upper := Node3D.new()
	upper.name = "UpperBody"
	upper.position.y = 0.34
	add_child(upper)
	for part in get_children():
		if part != upper and not part in legs: part.reparent(upper,true)

func _process(delta: float) -> void:
	if wait > 0:
		wait -= delta
		for limb in legs+arms:
			limb.rotation.x = move_toward(limb.rotation.x,0,delta*4)
		return
	var before := position
	position = position.move_toward(target,delta*0.75)
	var moved := position.distance_to(before)
	distance += moved
	if moved > 0.0001:
		rotation.y = atan2(target.x-before.x,target.z-before.z)
	for i in 2:
		legs[i].rotation.x = sin(distance*11+i*PI)*0.45
		arms[i].rotation.x = -legs[i].rotation.x*0.65
	if position.distance_to(target) < 0.02:
		target = start if target == finish else finish
		wait = 2.2
