extends Node

func _ready() -> void:
	seed(31)
	GameState.reset()
	var village := Village.new()
	village.visible = false
	add_child(village)
	village.setup_start()
	village.set_process(false)
	for child in village.workers_layer.get_children():
		child.set_process(false)
	var field = GameState.find_building("field")
	var worker: Worker = GameState.workers[0]
	worker.set_process(false)
	worker.job = field
	var actor := ActorView3D.new(worker,"worker")
	add_child(actor)
	# Every sampled segment must stay outside all building footprints.
	for building in GameState.buildings:
		var route := village.find_path(worker.position, building.center())
		assert(not route.is_empty())
		var previous := worker.position
		for point in route:
			assert(village.segment_clear(previous, point), "Route crosses " + building.type)
			previous = point
		assert(not village.point_blocked(route[-1]), "Blocked endpoint")
	worker.go_to_work()
	for frame in 2400:
		worker._process(1.0/60.0)
		if worker.state == Worker.State.WORKING:
			break
	if worker.state != Worker.State.WORKING:
		print("STUCK ",worker.position/Bal.CELL," path=",worker._path," detour=",worker._pedestrian_detour)
		for other in GameState.workers: print("PEER ",other.position/Bal.CELL)
	assert(worker.state == Worker.State.WORKING, "Worker cannot reach the crop row")
	for rotation in 4:
		field.rot = rotation
		worker.go_to_work()
		assert(not worker._path.is_empty(), "No reachable crop row")
		worker.position = worker._path[-1]
		worker.state = Worker.State.WORKING
		worker._path.clear()
		# Advance simulation after arrival before sampling presentation.
		worker._process(1.0/60.0)
		assert(worker.farm_activity in ["farm", "harvest"])
		var closest := INF
		for frame in 180:
			actor.sync(1.0/60.0)
			if actor.body.has_meta("hoe_tip_world"):
				var tip: Vector3 = actor.body.get_meta("hoe_tip_world")
				closest = minf(closest,tip.distance_to(View.to3(worker.farm_target,BuildingKit.FIELD_SURFACE)))
		assert(closest < 0.015, "Hoe misses crop at rotation %d: %f" % [rotation,closest])
		assert(not village.point_blocked(worker.position))
		assert(field.rect().has_point(village.cell_of(worker.position)), "Worker must stand inside field")
	var field_targets := {}
	for frame in 1200:
		worker._process(1.0/60.0)
		if worker.state == Worker.State.WORKING:
			field_targets[worker.farm_target] = true
	assert(field_targets.size() >= 4, "Field worker stays at a single crop")
	var plot := BuildingKit.build("field",1)
	var bounds := BuildingKit._bounds(plot)
	assert(bounds.position.y >= -0.001, "Soil is underground")
	plot.free()
	for kind in [120,121,122]:
		var animal := Critter.new()
		animal.kind = kind
		animal.visible = false
		add_child(animal)
		animal.set_process(false)
		var view := ActorView3D.new(animal,"critter")
		add_child(view)
		var bone := view._animal_rig.find_bone("leg-fl")
		view.sync(1.0/60.0)
		var before := view._animal_rig.get_bone_pose_rotation(bone)
		var max_leg_motion := 0.0
		for frame in 30:
			animal.position.x += 0.35
			view.sync(1.0/60.0)
			max_leg_motion = maxf(max_leg_motion, before.angle_to(view._animal_rig.get_bone_pose_rotation(bone)))
			assert(is_zero_approx(view.body.position.y), "Animal body bounces")
		assert(max_leg_motion > 0.1, "Leg does not move")
	var rig = preload("res://scripts/world3d/camera_rig_3d.gd").new()
	# A detached greenhouse cannot report production or stretch the worker's reach.
	var greenhouse := village.spawn_building("greenhouse", Vector2i(5,5))
	for x in range(3,9):
		for y in range(3,9):
			GameState.cleared[Vector2i(x,y)] = true
	worker.job = greenhouse
	greenhouse.worker = worker
	assert(not greenhouse.road_connected())
	worker.state = Worker.State.WORKING
	assert(not greenhouse.has_working_worker())
	GameState.extra_roads[Vector2i(4,5)] = true
	for rotation in 4:
		greenhouse.rot = rotation
		assert(greenhouse.size == (Vector2i(2,1) if rotation%2==0 else Vector2i(1,2)))
		worker.go_to_work()
		assert(not worker._path.is_empty(), "Greenhouse row inaccessible")
		worker.position = worker._path[-1]
		worker.state = Worker.State.WORKING
		worker._path.clear()
		# Advance simulation after arrival before sampling presentation.
		worker._process(1.0/60.0)
		assert(worker.farm_activity in ["farm", "harvest"])
		assert(greenhouse.has_working_worker())
		assert(greenhouse.rect().has_point(village.cell_of(worker.position)), "Worker must be inside greenhouse")
		assert(worker.position.distance_to(worker.farm_target) < Bal.CELL*0.58)
		var contact := INF
		for frame in 180:
			actor.sync(1.0/60.0)
			if actor.body.has_meta("hoe_tip_world"):
				contact = minf(contact,actor.body.get_meta("hoe_tip_world").distance_to(View.to3(worker.farm_target,0.02)))
		assert(contact < 0.015, "Greenhouse hoe misses nearby crop")
	var greenhouse_targets := {}
	for frame in 1200:
		worker._process(1.0/60.0)
		if worker.state == Worker.State.WORKING:
			greenhouse_targets[worker.farm_target] = true
	assert(greenhouse_targets.size() >= 4, "Greenhouse worker stays at one plant")
	var long_axis := Vector2.RIGHT.rotated(greenhouse.rot*PI*0.5)
	var across := Vector2.DOWN.rotated(greenhouse.rot*PI*0.5)
	assert(not village.segment_clear(greenhouse.center()+across*Bal.CELL,greenhouse.center()), "Worker can cross greenhouse side wall")
	assert(village.segment_clear(greenhouse.center()+long_axis*Bal.CELL*1.2,greenhouse.center()), "Greenhouse entrance is blocked")
	GameState.buildings.erase(greenhouse)
	greenhouse.queue_free()
	var station = GameState.find_building("fire_station")
	var departure: Vector2 = station.center()+Vector2(0,2.5)*Bal.CELL
	var route: Array = village.road_path(departure,field)
	assert(not route.is_empty(), "No fire response route")
	var previous: Vector2 = departure
	for point in route:
		assert(village.truck_segment_clear(previous,point), "Truck clips a building")
		assert(village.truck_segment_cost(previous,point) <= previous.distance_to(point)*1.01, "Truck leaves the connected road")
		previous = point
	print("TRUCK_ROUTE ",route)
	add_child(rig)
	rig.yaw = 170
	rig.pitch = 70
	rig.begin_fire_shot(Vector2(300,400),0.0)
	var shot: Transform3D = rig.cam.transform
	rig.end_fire_shot()
	assert(rig.yaw == 170 and rig.pitch == 70)
	rig.yaw = -90
	rig.pitch = 30
	rig.begin_fire_shot(Vector2(300,400),0.0)
	assert(rig.cam.transform.is_equal_approx(shot), "Shot inherits player camera")
	for frame in 240:
		rig.track_fire_shot(Vector2(300,400)+Vector2(0,frame)*2,1.0/60.0)
	assert(rig._fire_pullback > 0.8, "Fire camera does not pull out")
	assert(rig._fire_eye.y > 5.0)
	rig.end_fire_shot()
	print("CONTACT_REGRESSIONS_OK: solid building avoidance, greenhouse entrances, four crop rotations, interior row changes, hoe contact, road-only truck route, grounded gait, camera pullback")
	for player in Audio.get_children():
		if player is AudioStreamPlayer: player.stop()
	print("TEST_OK contact_regressions")
	get_tree().quit()
