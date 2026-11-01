extends Node3D
var actor: ActorView3D
var time := 0.0
var captured := false
var greenhouse := "--greenhouse" in OS.get_cmdline_user_args()
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP farm_visual: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	GameState.reset()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-30,0)
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("899882")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.7
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(30,30)
	BuildingKit.prim(self,floor_mesh,BuildingKit.mat("test_grass",Color("78864d")),Vector3.ZERO)
	var camera := Camera3D.new()
	camera.fov = 34.0
	camera.position = Vector3(3,2.9,4)
	add_child(camera)
	camera.look_at(Vector3(1,0.15,1))
	var field := Building.new()
	field.setup("greenhouse" if greenhouse else "field",Vector2i.ZERO)
	GameState.extra_roads[Vector2i(-1,0)] = true
	field.crop_ready = true
	field.visible = false
	add_child(field)
	field.set_process(false)
	var view := BuildingView3D.new(field)
	add_child(view)
	view.sync()
	var worker := Worker.new()
	worker.visible = false
	add_child(worker)
	worker.set_process(false)
	worker.job = field
	worker.state = Worker.State.WORKING
	# Static pose fixture: simulation is intentionally frozen for screenshots.
	worker.farm_activity = "farm"
	worker.position = Vector2(1.25,1.37)*Bal.CELL
	worker.farm_target = Vector2(1.25,1.75)*Bal.CELL
	if greenhouse:
		worker.position = Vector2(0.86,0.5)*Bal.CELL
		worker.farm_target = Vector2(1.2,0.68)*Bal.CELL
	actor = ActorView3D.new(worker,"worker")
	add_child(actor)

func _process(delta: float) -> void:
	if not is_instance_valid(actor): return
	time += delta
	actor.sync(delta)
	actor.visible = true
	if not captured and time > 1.0 and actor.body.has_meta("hoe_tip_world"):
		var tip: Vector3 = actor.body.get_meta("hoe_tip_world")
		if tip.distance_to(View.to3(actor.src.farm_target,0.02 if greenhouse else BuildingKit.FIELD_SURFACE)) < 0.01:
			captured = true
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://tests/shots/greenhouse_contact.png" if greenhouse else "res://tests/shots/farm_contact.png")
			print("FARM_CONTACT_RENDER_OK")
			for player in Audio.get_children():
				if player is AudioStreamPlayer: player.stop()
			print("TEST_OK farm_visual")
			get_tree().quit()
