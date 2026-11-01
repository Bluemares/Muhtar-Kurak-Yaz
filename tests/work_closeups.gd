extends Node3D

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP work_closeups: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a8b8b0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.8
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-30,0)
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.6
	camera.position = Vector3(1.25,1.65,4.7)
	add_child(camera)
	camera.look_at(Vector3(1.25,0.35,0.45))
	for row in 2:
		for col in 4:
			var person := preload("res://tt_models/scripts/worker_model.gd").create(self)
			person.scale = Vector3.ONE*0.46
			person.position = Vector3(col*0.85,0,row*0.95)
			person.rotation.y = PI*0.5 if row==1 else 0.0
			person.get_node("Job").visible = false
			var action: String = ["axe", "pickaxe", "water_crop", "basket"][col]
			for frame in 56:
				preload("res://tt_models/scripts/worker_pose.gd").apply(person, {"state":"working"}, 0.0, 0.0, frame / 60.0, 1.0 / 60.0, action, Vector3.ZERO, action == "water_crop", false)
			person.get_node("Basket").visible = action in ["basket", "harvest"]
	await RenderingServer.frame_post_draw
	var output := OS.get_user_data_dir()+"/motion-check/work_closeups.png"
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("HOE_CLOSEUPS ",output)
	print("TEST_OK work_closeups")
	get_tree().quit()

