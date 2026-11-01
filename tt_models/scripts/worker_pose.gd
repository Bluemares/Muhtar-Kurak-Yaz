extends RefCounted
## Presentation only: reads traveled distance, job and the paused work clock.
static func apply(person: Node3D, worker: Dictionary, traveled: float, stride: float, clock: float, delta: float, activity: String, facing: Vector3, carrying: bool, paused: bool) -> void:
	var moving := traveled > 0.01
	if paused and not moving: return
	var blend := 1.0-exp(-delta*12.0)
	var upper: Node3D = person.get_node("UpperBody")
	var arm_targets := [0.0,0.0]
	var body_target := 0.0
	var escaping: bool = worker.state == "sheltering" and moving
	if facing.length_squared() > 0.00001 and (not paused or moving):
		person.rotation.y = lerp_angle(person.rotation.y,atan2(facing.x,facing.z),1.0-exp(-delta*10.0))
	var aligned := facing.length_squared() < 0.00001 or absf(angle_difference(person.rotation.y,atan2(facing.x,facing.z))) < 0.15
	var settling: float = person.get_meta("settling",0.0)
	settling = settling+delta if not moving and aligned else 0.0
	person.set_meta("settling",settling)
	var ready_work := aligned and settling >= 0.18
	var turning := not moving and not aligned
	var turn_clock: float = person.get_meta("turn_clock",0.0)
	turn_clock = turn_clock+delta if turning else 0.0
	person.set_meta("turn_clock",turn_clock)
	var swing := 0.65 if escaping else 0.42
	for limb in 2:
		person.legs[limb].rotation.x = sin(stride+limb*PI)*swing if moving else 0.0
		arm_targets[limb] = -person.legs[limb].rotation.x*(0.9 if escaping else 0.65)
		# Lift only the returning foot; a standing foot remains level.
		person.legs[limb].position.y = 0.34+maxf(0.0,sin(stride+limb*PI))*0.035 if moving else 0.34
		var angle: float = person.legs[limb].rotation.x
		var sole_low := 0.34-0.32*cos(angle)-maxf(-0.075*sin(angle),0.165*sin(angle))
		person.legs[limb].position.y += maxf(0.0,0.02-sole_low)
		var leg: Node3D = person.legs[limb]
		var foot_phase := fposmod(stride+limb*PI,TAU)
		var key := "plant_"+str(limb)
		leg.position.x = -0.10 if limb == 0 else 0.10
		leg.position.z = 0.0
		if moving and foot_phase >= PI:
			leg.rotation.x = 0.0
			leg.position.z = 0.14
			if not person.has_meta(key): person.set_meta(key,person.to_global(leg.position))
			var planted: Vector3 = person.to_local(person.get_meta(key))
			if Vector2(planted.x-leg.position.x,planted.z).length() > 0.35:
				person.set_meta(key,person.to_global(leg.position))
			else:
				leg.position.x = planted.x
				leg.position.z = planted.z
			leg.position.y = 0.34
		else:
			if person.has_meta(key): person.remove_meta(key)
			if moving: leg.position.z = lerpf(-0.14,0.14,foot_phase/PI)
		# Small alternating foot lifts make a stationary turn a step, not a rigid spin.
		if turning:
			leg.position.y += maxf(0.0,sin(turn_clock*18+limb*PI))*0.025
	body_target = 0.10 if escaping else 0.0
	var hoe: Node3D = person.get_node("Hoe")
	var bucket: Node3D = person.get_node("Bucket")
	hoe.visible = activity == "farm" and ready_work and not moving
	bucket.visible = carrying
	hoe.position = Vector3.ZERO
	bucket.position = Vector3.ZERO
	bucket.rotation.z = lerpf(bucket.rotation.z,sin(stride)*0.10 if moving else 0.0,blend)
	if activity == "farm" and ready_work:
		# A planted foot and a coordinated torso/arm/tool stroke into the bed.
		var cycle := fposmod((float(person.get_meta("farm_time",0.0))+delta)/1.2,1.0)
		var pose := preload("res://tt_models/scripts/farm_rig.gd").stroke_pose(cycle)
		body_target = pose.bend
		hoe.rotation.x = 0.0
		hoe.position = Vector3.ZERO
		arm_targets[1] = -0.4
		arm_targets[0] = -0.4
	elif activity == "water" and ready_work:
		var progress := clampf(float(worker.get("draw_progress",0.0))/3.0,0,1)
		var lift := smoothstep(0.25,0.85,progress)
		body_target = 0.06+sin(progress*PI)*0.10
		bucket.position = Vector3(0.13,lift*0.26,0.18)
		arm_targets[0] = -0.45-lift*0.65
		arm_targets[1] = -0.35-lift*0.50+sin(progress*TAU*3)*0.12
	elif activity == "harvest" and ready_work:
		var reach := (sin(clock * 4.0) + 1.0) * 0.5
		body_target = 0.12 + reach * 0.28
		arm_targets[1] = -0.45 - reach * 0.7
		arm_targets[0] = -0.2
	elif activity == "water_crop" and ready_work:
		arm_targets[0] = -0.85
		bucket.rotation.z = -0.65
		body_target = 0.12
	elif carrying:
		arm_targets[0] = -0.12
		body_target = 0.035
	elif not moving:
		var idle_phase := fposmod(clock,11.0)
		body_target = sin(idle_phase*PI/1.4)*0.025 if idle_phase < 1.4 else 0.0

	upper.rotation.x = lerpf(upper.rotation.x,body_target,blend)
	for limb in 2:
		person.arms[limb].rotation.x = lerpf(person.arms[limb].rotation.x,arm_targets[limb],blend)
	# Tools share the actual hand transform: no independent orbit or inverted grip.
	var hand: Node3D = person.arms[1]
	hoe.position = person.to_local(hand.to_global(Vector3(0,-0.25,0)))
	hoe.basis = person.global_basis.inverse()*hand.global_basis
	if carrying:
		var left: Node3D = person.arms[0]
		bucket.position = person.to_local(left.to_global(Vector3(0,-0.25,0)))

	preload("res://tt_models/scripts/farm_rig.gd").apply(person,activity == "farm" and not moving and ready_work,ready_work,delta)

	var equipment: String = worker.get("equipment", activity)
	preload("res://tt_models/scripts/equipment_pose.gd").apply(person,equipment,clock,ready_work,moving)
	var drops: Node3D = person.get_node("Pour")
	drops.visible = equipment == "water_crop" and not moving and ready_work
	if drops.visible:
		var can: Node3D = person.get_node("WateringCan")
		var outlet: Vector3 = person.to_local(can.get_node("Outlet").global_position)
		var target: Vector3 = person.to_local(person.get_meta("farm_contact_world")) if person.has_meta("farm_contact_world") else Vector3(0,0,1.0)
		for i in drops.get_child_count():
			var fall := fposmod(clock * 1.8 + i / 7.0, 1.0)
			drops.get_child(i).position = outlet.lerp(target,fall)+Vector3(sin(i*2.4)*fall*0.05,sin(fall*PI)*0.05,0)
