extends Node3D
var actors: Array = []
var clock := 0.0
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP animal_motion: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-30,0)
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("788c97")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.7
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.5
	cam.position = Vector3(3,2.5,4)
	add_child(cam)
	cam.look_at(Vector3(1.5,0.1,0.7))
	for i in 3:
		var name: String = ["animal-chick","animal-cow","animal-dog"][i]
		var original := Models.spawn("pets/"+name)
		original.position = Vector3(i,0,0)
		original.scale = Vector3.ONE * [0.17,0.36,0.24][i]
		add_child(original)
		var animation: AnimationPlayer = original.find_children("*","AnimationPlayer",true,false)[0]
		animation.play("walk")
		var animal := Critter.new()
		animal.kind = [122,120,121][i]
		animal.visible = false
		animal.position = Vector2(i,1.2)*Bal.CELL
		add_child(animal)
		animal.set_process(false)
		var actor := ActorView3D.new(animal,"critter")
		add_child(actor)
		actors.append(actor)
	await get_tree().create_timer(0.5).timeout
	var poses := {}
	var vertices := {}
	for sample in 6:
		await get_tree().create_timer(0.12).timeout
		for actor in actors:
			var leg: int = actor._animal_rig.find_bone("leg-fl")
			var pose: Quaternion = actor._animal_rig.get_bone_pose_rotation(leg)
			if not poses.has(actor): poses[actor] = []
			poses[actor].append(pose)
			if not vertices.has(actor): vertices[actor] = []
			var meshes: Array = actor.body.find_children("*leg*","MeshInstance3D",true,false)
			if meshes.is_empty(): meshes = actor.body.find_children("*","MeshInstance3D",true,false)
			var baked: ArrayMesh = meshes[0].bake_mesh_from_current_skeleton_pose()
			vertices[actor].append(baked.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	for actor in actors:
		var motion := 0.0
		for pose in poses[actor]: motion = maxf(motion,poses[actor][0].angle_to(pose))
		assert(motion>0.35,"Walking gait does not keep cycling")
		var mesh_motion := 0.0
		for sample in vertices[actor]:
			for i in sample.size(): mesh_motion = maxf(mesh_motion,vertices[actor][0][i].distance_to(sample[i]))
		print("MESH_MOTION ",actor.src.kind," ",mesh_motion)
		assert(mesh_motion>0.03,"Bone moves but visible leg mesh is frozen")
	var output := OS.get_user_data_dir()+"/motion-check"
	DirAccess.make_dir_recursive_absolute(output)
	for i in 2:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output+"/animal_motion_%d.png" % i)
		await get_tree().create_timer(0.13).timeout
	for player in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	print("ANIMAL_MOTION_OK: continuous visible leg cycle; frames: ",output)
	print("TEST_OK animal_motion")
	get_tree().quit()
func _process(delta: float) -> void:
	for actor in actors:
		actor.src.position.x += delta * 22.0
		actor.sync(delta)
