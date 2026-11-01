extends Node3D

func inside_body(person: Node3D, world: Vector3, margin: float) -> bool:
	var p: Vector3 = person.get_node("UpperBody").to_local(world)
	var torso := Rect2(Vector2(-0.23-margin,-0.16-margin),Vector2(0.46+2*margin,0.34+2*margin))
	if p.y>0.035 and p.y<0.40 and torso.has_point(Vector2(p.x,p.z)):
		return true
	var head := (p-Vector3(0,0.57,0))/Vector3(0.19+margin,0.20+margin,0.18+margin)
	return head.length_squared()<1.0

func _ready() -> void:
	GameState.reset()
	for type in ["field","greenhouse"]:
		var village := Village.new()
		add_child(village)
		var building := village.spawn_building(type,Vector2i(5,5))
		for x in range(3,9):
			for y in range(3,9): GameState.cleared[Vector2i(x,y)] = true
		GameState.extra_roads[Vector2i(4,5)] = true
		var worker := Worker.new()
		worker.village = village
		worker.position = Vector2(4.5,5.5)*Bal.CELL
		village.workers_layer.add_child(worker)
		worker.set_process(false)
		worker.job = building
		var actor := ActorView3D.new(worker,"worker")
		add_child(actor)
		for rotation in 4:
			building.rot = rotation
			worker.go_to_work()
			assert(not worker._path.is_empty())
			worker.position = worker._path[-1]
			worker.state = Worker.State.WORKING
			for frame in 240:
				actor.sync(1.0/60.0)
				var rig := actor.body.get_node("FarmRig")
				if not rig.visible: continue
				for side in 2:
					for part in 2:
						var bone: Node3D = rig.get_node("Bone%d%d"%[side,part])
						for sample in range(1,10):
							var world := bone.to_global(Vector3(0,-0.5+sample/10.0,0))
							if inside_body(actor.body,world,0.025): print("COLLISION ",actor.body.get_node("UpperBody").to_local(world)," bone=",bone.position," scale=",bone.scale," grip=",rig.get_node("Grip%d"%side).position)
							assert(not inside_body(actor.body,world,0.025),"Arm penetrates torso/head: %s rotation %d frame %d limb %d part %d"%[type,rotation,frame,side,part])
					var grip: Node3D = rig.get_node("Grip%d"%side)
					assert(not inside_body(actor.body,grip.global_position,0.06),"Hand penetrates body")
				var hoe: Node3D = actor.body.get_node("Hoe")
				for sample in 17:
					if inside_body(actor.body,hoe.to_global(Vector3(0,-0.55+sample*0.05,0)),0.025): print("SHAFT ",type," ",rotation," ",frame," ",sample," ",actor.body.get_node("UpperBody").to_local(hoe.to_global(Vector3(0,-0.55+sample*0.05,0))))
					assert(not inside_body(actor.body,hoe.to_global(Vector3(0,-0.55+sample*0.05,0)),0.025),"Hoe shaft penetrates body")
		actor.free()
		GameState.buildings.erase(building)
		village.free()
	print("HOE_CLEARANCE_OK: field/greenhouse, four rotations, full strokes; arms/hands/shaft outside torso and head")
	print("TEST_OK hoe_clearance")
	get_tree().quit()
