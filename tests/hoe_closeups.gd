extends Node3D

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP hoe_closeups: requires rendering")
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
	camera.size = 2.8
	camera.position = Vector3(0.85,1.65,3.7)
	add_child(camera)
	camera.look_at(Vector3(0.85,0.3,0.45))
	for row in 2:
		for col in 3:
			var person := preload("res://tt_models/scripts/worker_model.gd").create(self)
			person.scale = Vector3.ONE*0.46
			person.position = Vector3(col*0.85,0,row*0.95)
			person.rotation.y = PI*0.5 if row==1 else 0.0
			person.get_node("Job").visible = false
			var phase: float = [0.29,0.51,0.78][col]
			var pose := preload("res://tt_models/scripts/farm_rig.gd").stroke_pose(phase)
			person.get_node("UpperBody").rotation.x = pose.bend
			person.set_meta("farm_contact_world",person.to_global(Vector3(0,0,0.38/0.46)))
			person.set_meta("farm_time",phase*1.2)
			person.get_node("Hoe").visible = true
			preload("res://tt_models/scripts/farm_rig.gd").apply(person,true,true,0.0)
	await RenderingServer.frame_post_draw
	var output := OS.get_user_data_dir()+"/motion-check/hoe_closeups.png"
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	get_viewport().get_texture().get_image().save_png(output)
	print("HOE_CLOSEUPS ",output)
	print("TEST_OK hoe_closeups")
	get_tree().quit()
