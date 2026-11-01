extends Node3D
const R = preload("res://scripts/world/rock_geometry.gd")
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP rock_closeup: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	GameState.reset()
	var village := Village.new()
	village.visible = false
	add_child(village)
	village.set_process(false)
	village.setup_start()
	var c := Vector2i(2,3)
	var w = GameState.workers[0]
	for worker in GameState.workers: worker.set_process(false)
	w.position = Vector2(17.5,14.5)*Bal.CELL
	w.start_task(c)
	w.position = w._destination
	w.state = Worker.State.WORKING
	var actor := ActorView3D.new(w,"worker")
	add_child(actor)
	var rock := MeshInstance3D.new()
	rock.mesh = Models.mesh(R.ROCKS[int(R.noise(c.x,c.y,12)*R.ROCKS.size())])
	var off := Vector2(R.noise(c.x,c.y,40),R.noise(c.x,c.y,50))*0.6+Vector2.ONE*0.2
	rock.transform = Transform3D(Basis(Vector3.UP,R.noise(c.x,c.y,60)*TAU).scaled(Vector3.ONE*(1.3+R.noise(c.x,c.y,13)*0.8)),Vector3(c.x+off.x,0,c.y+off.y))
	add_child(rock)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a8b8b0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.8
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-30,0)
	add_child(light)
	var camera := Camera3D.new()
	add_child(camera)
	var center := rock.position.lerp(View.to3(w.position),0.5)+Vector3.UP*0.25
	var outward := (View.to3(w.position)-rock.position).normalized()
	camera.position = center+outward.cross(Vector3.UP)*3+Vector3.UP*1.5+outward*0.8
	camera.look_at(center)
	for i in 60: actor.sync(1.0/60.0)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/rock_closeup.png")
	print("TEST_OK rock_closeup")
	get_tree().quit()
