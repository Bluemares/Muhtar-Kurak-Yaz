extends Node3D
## Integration/render check for the selected replacement pack, including live worker states.

var views: Array = []
var worker: Worker
var actor: ActorView3D
var elapsed := 0.0
var animal_views: Array = []

func _ready() -> void:
	GameState.reset()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("6d8597")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.65
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.5
	camera.position = Vector3(7, 12, 17)
	add_child(camera)
	camera.look_at(Vector3(6, 0, 4))
	var cases := [["house",1], ["cop31",1], ["cop31",2], ["cop31",3], ["fire_station",1], ["well",1], ["well",2], ["well",3], ["water_tower",1], ["granary",1], ["lamp",1]]
	for i in cases.size():
		var spec: Array = cases[i]
		var building := Building.new()
		building.type = spec[0]
		building.level = spec[1]
		building.cell = Vector2i((i % 4) * 4, (i / 4) * 3)
		building.position = Vector2(building.cell) * Bal.CELL
		building.size = Bal.BUILDINGS[building.type].size
		building._pop = 1.0
		var visual := BuildingView3D.new(building)
		building.visible = false
		add_child(building)
		building.set_process(false)
		add_child(visual)
		visual.sync()
		views.append(visual)
		var bounds := BuildingKit._bounds(visual.model)
		assert(bounds.size.length() > 0.01, "Empty replacement: " + building.type)
		print("MODEL ", spec, " bounds=", bounds)
		var title := Label3D.new()
		title.text = "%s L%d" % spec
		title.position = visual.position + Vector3(0, 0.05, 1.2)
		title.font_size = 24
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(title)
	var vehicle := Models.spawn("car/firetruck")
	vehicle.scale = Vector3.ONE * 0.52
	vehicle.position = Vector3(0,0,10)
	add_child(vehicle)
	for i in 3:
		var animal := Critter.new()
		animal.kind = [122,120,121][i]
		animal.visible = false
		animal.position = Vector2(3+i*3,10)*Bal.CELL
		add_child(animal)
		animal.set_process(false)
		var visual := ActorView3D.new(animal,"critter")
		add_child(visual)
		animal_views.append(visual)
	var portraits := CanvasLayer.new()
	add_child(portraits)
	for i in 6:
		var portrait := TextureRect.new()
		portrait.texture = Thumbs.portrait(["hasan","farmer","teacher","cop","fire","press"][i])
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.position = Vector2(10+i*105,600)
		portrait.size = Vector2(92,104)
		portraits.add_child(portrait)
	worker = Worker.new()
	worker.visible = false
	add_child(worker)
	worker.set_process(false)
	worker.position = Vector2(12, 10) * Bal.CELL
	actor = ActorView3D.new(worker, "worker")
	add_child(actor)
	_run()

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(actor):
		actor.sync(delta)
		actor.visible = true
	for animal in animal_views:
		animal.src.position.x += delta * 18.0
		animal.sync(delta)
	for view in views:
		view.sync()

func _run() -> void:
	await get_tree().create_timer(0.5).timeout
	var village := Village.new()
	assert(village._fit_rot("granary",2) == 2, "180 degree rotation must survive placement")
	assert(village._fit_rot("house",1) == 1, "Square buildings rotate 90 degrees")
	add_child(village)
	village.visible = false
	village.queue_free()
	views[4].b.set_meta("garage_open",true)
	views[4].b.set_meta("truck_away",true)
	worker.state = Worker.State.WALKING
	for i in 15:
		worker.position.x += 1.0
		await get_tree().process_frame
	worker.state = Worker.State.WORKING
	var farm := Building.new()
	farm.type = "field"
	worker.job = farm
	await get_tree().create_timer(0.5).timeout
	worker.job = null
	farm.free()
	worker.carry_stage = 1
	worker._carry_well = views[5].b
	worker._carry_t = Bal.CARRY_FILL_TIME * 0.65
	GameState.workers.append(worker)
	await get_tree().create_timer(0.5).timeout
	assert(views[4].model.get_node("GarageDoor").scale.y < 0.05, "Garage must fully open")
	worker.carry_stage = 2
	await get_tree().create_timer(0.5).timeout
	worker.carry_stage = 0
	worker.task_cell = Vector2i(0, 0)
	await get_tree().create_timer(0.5).timeout
	worker.task_cell = Worker.NO_TASK
	worker.state = Worker.State.IDLE
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/shots/tt_models.png")
	for animal in animal_views:
		assert(animal._animal_rig != null)
		assert(animal._animal_phase > 0.1)
	views[4].b.set_meta("garage_open",false)
	views[4].b.set_meta("truck_away",false)
	views[0].b.state = "burning"
	await get_tree().create_timer(0.5).timeout
	views[0].b.state = "ruined"
	await get_tree().create_timer(0.5).timeout
	assert(views[0].model.get_child_count() > 0)
	views[0].b.state = "normal"
	await get_tree().create_timer(0.2).timeout
	assert(views[5]._well_motion != null)
	assert(views[4].model.get_node("GarageDoor").scale.y > 0.95, "Garage must close")
	print("TT_MODELS_OK: replacements, worker poses, well, fire, ruin and restoration")
	GameState.workers.clear()
	worker._carry_well = null
	for player in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	print("TEST_OK tt_models")
	get_tree().quit()
