extends Node
const Motion = preload("res://scripts/world/pedestrian_motion.gd")

func _ready() -> void:
	GameState.reset()
	var village := Village.new()
	village.visible = false
	add_child(village)
	for x in range(9,16):
		for y in range(6,16): GameState.cleared[Vector2i(x,y)] = true
	for test in ["head_on","crossing","stationary","greenhouse"]:
		var greenhouse: Building
		if test=="greenhouse": greenhouse = village.spawn_building("greenhouse",Vector2i(11,8))
		var a := Worker.new()
		var b := Worker.new()
		for worker in [a,b]:
			worker.village = village
			village.workers_layer.add_child(worker)
			worker.set_process(false)
			worker._speed_jitter = 1.0
		a.position = Vector2(10.5,8.5)*Bal.CELL
		b.position = Vector2(13.5,8.5)*Bal.CELL
		var atarget := b.position
		var btarget := a.position
		if test=="crossing":
			b.position = Vector2(12,7)*Bal.CELL
			btarget = Vector2(12,10)*Bal.CELL
		if test=="stationary":
			b.position = Vector2(12,8.5)*Bal.CELL
			b.state = Worker.State.WORKING
		else: b.go_to(btarget,Worker.State.WORKING)
		a.go_to(atarget,Worker.State.WORKING)
		var complete := false
		for frame in 3600:
			a._process(1.0/60.0)
			b._process(1.0/60.0)
			assert(a.position.distance_to(b.position)>=Motion.GAP-0.02,"Pedestrians overlap: "+test)
			assert(not village.point_blocked(a.position) and not village.point_blocked(b.position),"Steering entered a building")
			if a.state==Worker.State.WORKING and b.state==Worker.State.WORKING:
				complete = true
				break
		assert(complete,"Pedestrians deadlock: "+test+str([a.position/Bal.CELL,b.position/Bal.CELL]))
		print("PEDESTRIAN_OK ",test)
		a.free()
		b.free()
		if greenhouse:
			GameState.buildings.erase(greenhouse)
			greenhouse.free()
	var crowd: Array[Worker] = []
	var starts := [Vector2(10.5,8.5),Vector2(13.5,8.5),Vector2(12,7),Vector2(12,10)]
	for i in 4:
		var worker := Worker.new()
		worker.village = village
		worker.position = starts[i]*Bal.CELL
		village.workers_layer.add_child(worker)
		worker.set_process(false)
		worker.go_to(starts[i^1]*Bal.CELL,Worker.State.WORKING)
		crowd.append(worker)
	var finished := false
	for frame in 3600:
		for worker in crowd: worker._process(1.0/60.0)
		for i in 4:
			for j in range(i+1,4): assert(crowd[i].position.distance_to(crowd[j].position)>=Motion.GAP-0.02,"Crowd overlap")
		if crowd.all(func(w): return w.state==Worker.State.WORKING):
			finished = true
			break
	assert(finished,"Four-way intersection deadlock")
	print("PEDESTRIAN_OK four_way_crowd")
	print("TEST_OK pedestrians")
	get_tree().quit()
