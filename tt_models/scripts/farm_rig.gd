extends RefCounted
## Local visual rig only: grips, bent elbows and contact dust never change simulation state.
const Art = preload("res://tt_models/scripts/models.gd")

static func setup(person: Node3D) -> Node3D:
	if person.has_node("FarmRig"): return person.get_node("FarmRig")
	var rig := Node3D.new()
	rig.name = "FarmRig"
	person.add_child(rig)
	for side in 2:
		for part in 2:
			var bone := Art.box(rig,Vector3.ZERO,Vector3(0.095,1,0.095),person.shirt_color if part == 0 else person.skin_color)
			bone.name = "Bone%d%d" % [side,part]
		var hand := Art.ball(rig,Vector3.ZERO,Vector3.ONE*0.12,person.skin_color)
		hand.name = "Grip%d" % side
	for i in 5:
		var dust := Art.ball(rig,Vector3.ZERO,Vector3.ONE*0.04,"#b5a178")
		dust.name = "Dust%d" % i
		dust.visible = false
	return rig

static func segment(node: Node3D, a: Vector3, b: Vector3) -> void:
	node.position = (a+b)*0.5
	var direction := b-a
	node.quaternion = Quaternion(Vector3.UP,direction.normalized())
	node.scale = Vector3(1,direction.length(),1)


static func stroke_pose(cycle: float) -> Dictionary:
	# Lift the blade around the two-handed grip, strike, then pull loose soil back.
	var angle := -0.9
	var pull := 0.0
	var bend := 0.08
	if cycle < 0.30:
		var t := smoothstep(0.0,0.30,cycle)
		angle = lerpf(-0.9,-2.65,t)
		bend = lerpf(0.08,-0.02,t)
	elif cycle < 0.46:
		var t := smoothstep(0.30,0.46,cycle)
		angle = lerpf(-2.65,-0.9,t)
		bend = lerpf(-0.02,0.12,t)
	elif cycle < 0.58:
		bend = 0.12
	elif cycle < 0.82:
		pull = smoothstep(0.58,0.82,cycle)*0.05
		bend = 0.12
	else:
		pull = (1.0-smoothstep(0.82,1.0,cycle))*0.05
	return {"angle":angle,"pull":pull,"bend":bend}

static func apply(person: Node3D, active: bool, aligned: bool, delta: float) -> void:
	var rig := setup(person)
	if active and person.has_meta("farm_contact_world"):
		active = person.global_position.distance_to(person.get_meta("farm_contact_world")) < 0.58
	rig.visible = active
	for arm in person.arms: arm.visible = not active
	if not active:
		person.set_meta("farm_time",0.0)
		person.set_meta("dust_age",1.0)
		return
	var before: float = person.get_meta("farm_time",0.0)
	var elapsed := before+delta if aligned else before
	person.set_meta("farm_time",elapsed)
	var cycle := fposmod(elapsed/1.2,1.0)
	var pose := stroke_pose(cycle)
	var contact: Vector3 = person.to_local(person.get_meta("farm_contact_world")) if person.has_meta("farm_contact_world") else Vector3(0.08,0.15,0.86)
	var hoe: Node3D = person.get_node("Hoe")
	var upper_grip := Vector3(0,0.16,0)
	var tip_local := Vector3(0,-0.55,-0.21)
	var pivot := contact-Basis(Vector3.RIGHT,-0.9)*(tip_local-upper_grip)
	pivot.z -= pose.pull
	hoe.basis = Basis(Vector3.RIGHT,pose.angle)
	hoe.position = pivot-hoe.basis*upper_grip
	for side in 2:
		var grip: Vector3 = hoe.transform*Vector3(0,0.16 if side == 0 else 0.0,0)
		var shoulder: Vector3 = person.to_local(person.arms[side].global_position)
		shoulder.x = -0.28 if side == 0 else 0.28
		shoulder.z += 0.12
		var direction := shoulder.direction_to(grip)
		var distance := shoulder.distance_to(grip)
		var bend := Vector3(-1 if side == 0 else 1,-0.4,0.3)
		bend = (bend-direction*bend.dot(direction)).normalized()
		var elbow := shoulder+direction*distance*0.5+bend*sqrt(maxf(0.30*0.30-distance*distance*0.25,0.0))
		segment(rig.get_node("Bone%d0" % side),shoulder,elbow)
		segment(rig.get_node("Bone%d1" % side),elbow,grip)
		rig.get_node("Grip%d" % side).position = grip
	var age: float = person.get_meta("dust_age",1.0)+delta
	if aligned and floori(before/1.2-0.46) < floori(elapsed/1.2-0.46): age = 0.0
	person.set_meta("dust_age",age)
	person.set_meta("hoe_tip_world", hoe.to_global(Vector3(0,-0.55,-0.21)))
	for i in 5:
		var puff: Node3D = rig.get_node("Dust%d" % i)
		puff.visible = age < 0.35
		var t := clampf(age/0.35,0,1)
		puff.position = contact+Vector3(sin(i*2.4)*t*0.15,t*0.13,cos(i*2.4)*t*0.10)
		puff.scale = Vector3.ONE*(0.035+0.045*t)*(1-t)


