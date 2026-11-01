extends Node

func _ready() -> void:
	GameState.reset()
	var village := Village.new()
	village.visible = false
	add_child(village)
	village.set_process(false)
	village.setup_start()
	for worker in GameState.workers: worker.set_process(false)
	var b = GameState.find_building("field")
	var w = GameState.workers[0]
	w.position = Vector2(17.5,14.5)*Bal.CELL
	w.assign(b)
	for manual in [true,false]:
		GameState.food = 0.0
		GameState.water = 0.0
		b.farm_phase = "grow"
		b.crop_ready = true
		b._ready_t = 0.0
		b.harvest_progress = b.harvest_time()
		w.farm_activity = "fetch"
		w._carry_well = GameState.find_building("well")
		w.state = Worker.State.WORKING
		if manual:
			village.tap_harvest(b)
			assert(GameState.food > 0,"Manual harvest must credit immediately")
			var credited: float = GameState.food
			village.tap_harvest(b)
			assert(GameState.food == credited,"Duplicate manual reward")
		var delivered := false
		for frame in 5000:
			b.grow(0.05)
			if not manual and frame < 70: assert(b.farm_phase != "harvest")
			w._process(0.05)
			if GameState.food > 0:
				delivered = true
				break
		assert(delivered,"Ripe crop stuck fetching water")
		assert(b.pending_harvest == 0 and not b.crop_ready)
		print("HARVEST_DELIVERED manual=",manual," food=",GameState.food)
	# Watering immediately resumes hoeing; a wet plot grows at its base rate.
	b.farm_phase = "grow"
	b.harvest_progress = 0
	b.soil_water = 0
	w.state = Worker.State.WORKING
	w.farm_activity = "water_crop"
	w._farm_work_time = 1.79
	preload("res://scripts/world/farm_cycle.gd").tick(w,0.02)
	assert(w.farm_activity == "farm")
	b.grow(1.0)
	assert(is_equal_approx(b.harvest_progress,1.0))
	var index: int = w._farm_index
	preload("res://scripts/world/farm_cycle.gd").tick(w,2.5)
	assert(w._farm_index != index and w.state == Worker.State.WALKING)
	b.farm_phase = "harvest"
	b.reset_crop_work()
	assert(b.farm_phase == "prepare")
	print("HARVEST_REQUEST_OK; watering resumes hoeing and wet growth is full-speed")
	print("TEST_OK harvest_request")
	get_tree().quit()
