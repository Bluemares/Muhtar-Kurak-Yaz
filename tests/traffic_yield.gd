extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset()
	var short_walk := Critter.new()
	short_walk.area = Rect2(0,0,1000,1000)
	short_walk.position = Vector2(400,400)
	add_child(short_walk)
	short_walk.set_process(false)
	short_walk._process(0.01)
	assert(not short_walk._path.is_empty(),"Short animal destination was discarded")
	short_walk.free()
	var village := Village.new()
	add_child(village)
	village.setup_start()
	for actor in village.workers_layer.get_children():
		actor.set_process(false)
		actor.position = Vector2(5,5)*Bal.CELL
	var worker: Worker = GameState.workers[0]
	worker.position = Vector2(19.5,10.5)*Bal.CELL
	worker._destination = Vector2(18,11.5)*Bal.CELL
	worker._goal = Worker.State.IDLE
	var animal := Critter.new()
	animal.kind = 120
	animal.village = village
	animal.position = Vector2(18.0,10.5)*Bal.CELL
	animal._target = Vector2(18,12)*Bal.CELL
	village.workers_layer.add_child(animal)
	animal.set_process(false)
	var view := ActorView3D.new(animal,"critter")
	add_child(view)
	var truck := FireTruck.new()
	truck.village = village
	village.add_child(truck)
	truck.position = Vector2(22,10.5)*Bal.CELL
	var initial_worker := worker.position
	var initial_animal := animal.position
	get_tree().paused = true
	var drive := truck.drive([Vector2(16.5,10.5)*Bal.CELL],3.0)
	var yielded_worker := false
	var yielded_animal := false
	var animated_while_paused := false
	var leg := view._animal_rig.find_bone("leg-fl")
	var before := view._animal_rig.get_bone_pose_rotation(leg)
	var frames := 0
	while drive.is_valid() and frames < 2400:
		await get_tree().process_frame
		frames += 1
		view.sync(get_process_delta_time())
		yielded_worker = yielded_worker or worker.position.distance_to(initial_worker)>Bal.CELL*0.6
		yielded_animal = yielded_animal or animal.position.distance_to(initial_animal)>Bal.CELL*0.6
		animated_while_paused = animated_while_paused or before.angle_to(view._animal_rig.get_bone_pose_rotation(leg))>0.2
		assert(truck.position.distance_to(worker.position)>Bal.CELL*0.8,"Truck intersects villager")
		assert(truck.position.distance_to(animal.position)>Bal.CELL*0.8,"Truck intersects cow")
	assert(frames<2400,"Traffic never clears")
	assert(yielded_worker and yielded_animal,"Actors did not leave the road")
	assert(animated_while_paused,"Animal slides during fire cinematic")
	assert(not worker.has_meta("traffic_yield") and not animal.has_meta("traffic_yield"),"Yield state was not released")
	assert(worker.state==Worker.State.WALKING,"Worker does not resume route")
	get_tree().paused = false
	print("TRAFFIC_YIELD_OK: pedestrian and cow yield while paused, no overlap, gait runs, work resumes")
	for player in Audio.get_children():
		if player is AudioStreamPlayer: player.stop()
	print("TEST_OK traffic_yield")
	get_tree().quit()
