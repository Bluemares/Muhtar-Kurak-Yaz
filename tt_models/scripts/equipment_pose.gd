extends RefCounted
const Art = preload("res://tt_models/scripts/models.gd")
const Rig = preload("res://tt_models/scripts/farm_rig.gd")

static func setup(person: Node3D) -> void:
	if person.has_node("Axe"): return
	for kind in ["Axe", "Pickaxe"]:
		var tool := Node3D.new()
		tool.name = kind
		person.add_child(tool)
		Art.box(tool,Vector3(0,0.34,0),Vector3(0.045,1.02,0.045),"#95653f")
		if kind == "Axe":
			Art.box(tool,Vector3(0,0.78,0.09),Vector3(0.07,0.24,0.28),"#697e84")
			Art.box(tool,Vector3(0,0.78,0.235),Vector3(0.055,0.26,0.025),"#d1dadd")
		else:
			for side in [-1,1]:
				var head := Art.box(tool,Vector3(0,0.78,side*0.18),Vector3(0.065,0.075,0.38),"#687b82")
				head.rotation.x = side*0.25
		tool.visible = false
	var can := Node3D.new()
	can.name = "WateringCan"
	person.add_child(can)
	Art.cylinder(can,Vector3(0.12,-0.23,0),0.18,0.29,"#518f86",0.16)
	# Closed lid and raised handle; origin is the upper hand grip.
	Art.cylinder(can,Vector3(0.12,-0.075,0),0.16,0.025,"#79b0a3")
	for x in [-0.04,0.28]: Art.box(can,Vector3(x,-0.035,0),Vector3(0.025,0.12,0.03),"#c4d2bc")
	Art.box(can,Vector3(0.12,0.025,0),Vector3(0.34,0.035,0.035),"#c4d2bc")
	var spout := Art.cylinder(can,Vector3.ZERO,0.045,1.0,"#79b0a3",0.035)
	Rig.segment(spout,Vector3(0.12,-0.22,0.1),Vector3(0.12,-0.1,0.48))
	var nozzle := Art.cylinder(can,Vector3(0.12,-0.09,0.51),0.10,0.06,"#c4d2bc",0.08)
	nozzle.rotation.x = PI*0.5-0.30
	for i in 7:
		Art.ball(can,Vector3(0.12+sin(i*TAU/7)*0.055,-0.09+cos(i*TAU/7)*0.055,0.545),Vector3.ONE*0.018,"#293d40")
	var outlet := Marker3D.new()
	outlet.name = "Outlet"
	outlet.position = Vector3(0.12,-0.09,0.55)
	can.add_child(outlet)
	can.visible = false

static func arm(person: Node3D, side: int, grip: Vector3) -> void:
	var rig := Rig.setup(person)
	var shoulder: Vector3 = person.to_local(person.arms[side].global_position)
	shoulder.x = -0.28 if side == 0 else 0.28
	shoulder.z += 0.1
	var direction := shoulder.direction_to(grip)
	var distance := shoulder.distance_to(grip)
	var pole := Vector3(-1 if side == 0 else 1,-0.2,0.25)
	pole = (pole-direction*pole.dot(direction)).normalized()
	var elbow := (shoulder+grip)*0.5+pole*sqrt(maxf(0.30*0.30-distance*distance*0.25,0))
	Rig.segment(rig.get_node("Bone%d0"%side),shoulder,elbow)
	Rig.segment(rig.get_node("Bone%d1"%side),elbow,grip)
	rig.get_node("Grip%d"%side).position = grip

static func apply(person: Node3D, activity: String, clock: float, ready: bool, moving: bool) -> void:
	setup(person)
	var chopping := activity in ["axe","pickaxe"] and ready and not moving
	var basket := activity in ["basket","harvest"]
	var watering := activity == "water_crop"
	person.get_node("Axe").visible = chopping and activity == "axe"
	person.get_node("Pickaxe").visible = chopping and activity == "pickaxe"
	person.get_node("Basket").visible = basket
	person.get_node("WateringCan").visible = watering
	var rig := Rig.setup(person)
	for node in rig.get_children():
		if node.name.begins_with("Bone") or node.name.begins_with("Grip"): node.visible = true
	if not (chopping or basket or watering): return
	rig.visible = true
	for part in person.arms: part.visible = false
	for i in 5: rig.get_node("Dust%d"%i).visible = false
	var left := Vector3(-0.43,0.50,0.22)
	var right: Vector3 = person.to_local(person.arms[1].to_global(Vector3(0,-0.25,0)))
	if chopping:
		var phase := fposmod(clock/1.65,1.0)
		# Deliberate backswing, fast strike, short contact and slow recovery.
		var strike := smoothstep(0.40,0.56,phase) if phase < 0.7 else 1.0-smoothstep(0.70,1.0,phase)
		var tool: Node3D = person.get_node("Axe" if activity == "axe" else "Pickaxe")
		tool.position = Vector3(0,0.79,0.35).lerp(Vector3(0,0.50,0.40),strike)
		tool.basis = Basis(Vector3.RIGHT,lerpf(0.12,1.45 if activity == "axe" else 2.10,strike))
		person.get_node("UpperBody").rotation.x = -0.03+strike*0.15
		left = tool.transform*Vector3(0,0.02,0)
		right = tool.transform*Vector3(0,0.19,0)
	elif basket:
		var held: Node3D = person.get_node("Basket")
		held.basis = Basis(Vector3.FORWARD,sin(clock*5.0)*0.035 if moving else 0.0)
		held.position = left-held.basis*Vector3(0,0.30,0)
	elif watering:
		var can: Node3D = person.get_node("WateringCan")
		left = Vector3(-0.20,0.65,0.52)
		can.basis = Basis(Vector3.RIGHT,0.5 if ready and not moving else 0.0)
		can.position = left-can.basis*Vector3(0.12,0.025,0)
		right = can.transform*Vector3(0.30,-0.23,0)
		person.get_node("Bucket").visible = false
	arm(person,0,left)
	arm(person,1,right)

	if basket:
		person.arms[1].visible = true
		for name in ["Bone10","Bone11","Grip1"]: rig.get_node(name).visible = false
