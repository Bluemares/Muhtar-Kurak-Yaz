extends Node
## Animasyon ve yakın plan sayfası: godot --path . res://tests/skin_anim.tscn -- --skin=tests/_cmp/gpt/ --out=gpt
## Çıktı: tests/_cmp/shots/<out>_a_anim.png, <out>_b_animal.png, <out>_c_bina.png, <out>_d_kaya.png

const OUT := "res://tests/_cmp/shots/"
const CHARS := ["male-a", "female-a", "male-c", "female-d"]
const CLIPS := ["idle", "walk", "hoe", "chop", "carry", "sit"]
const ANIMALS := [["pets/animal-cow", 0.36], ["pets/animal-dog", 0.24], ["pets/animal-chick", 0.17]]
const ANIMAL_CLIPS := ["idle", "walk", "eat"]
const CLOSE := [["house", 1], ["cop31", 3], ["fire_station", 1], ["well", 3], ["grove", 1], ["granary", 1]]
const ROCKS := ["stone_largeA", "stone_tallA", "stump_old", "tree_fat", "tree_default", "plant_bushSmall"]

var tag := "ken"


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP skin_anim: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			tag = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + tag + "_" + n + ".png"))


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _studio() -> Node3D:
	var r := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.52, 0.58)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	r.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.3, 0.33, 0.28)
	g.material_override = gm
	r.add_child(g)
	add_child(r)
	return r


func _cam(r: Node3D, target: Vector3, dist: float, yaw: float, pitch: float) -> void:
	var c := Camera3D.new()
	c.fov = 30.0
	var b := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, -deg_to_rad(pitch))
	c.transform = Transform3D(b, target + b * Vector3(0, 0, dist))
	r.add_child(c)
	c.make_current()


func _pose(n: Node, clip: String, t: float) -> bool:
	var aps := n.find_children("*", "AnimationPlayer", true, false)
	if aps.is_empty() or not aps[0].has_animation(clip):
		return false
	aps[0].play(clip)
	aps[0].seek(t, true)
	aps[0].pause()
	return true


func _run() -> void:
	# a) köylü × klip
	var r := _studio()
	for y in CHARS.size():
		for x in CLIPS.size():
			var ch := Models.spawn("chars/character-" + CHARS[y])
			ch.scale = Vector3.ONE * 0.62
			ch.position = Vector3(x * 1.0, 0, y * 1.0)
			r.add_child(ch)
			if not _pose(ch, CLIPS[x], 0.3):
				ch.visible = false
	_cam(r, Vector3(2.5, 0.2, 1.5), 9.5, -8.0, 26.0)
	await _wait(0.4)
	await _shot("a_anim")
	r.queue_free()
	await get_tree().process_frame
	# b) hayvan × klip
	r = _studio()
	for y in ANIMALS.size():
		for x in ANIMAL_CLIPS.size():
			var a := Models.spawn(ANIMALS[y][0])
			a.scale = Vector3.ONE * float(ANIMALS[y][1])
			a.position = Vector3(x * 1.2, 0, y * 1.0)
			r.add_child(a)
			if not _pose(a, ANIMAL_CLIPS[x], 0.3):
				a.visible = false
	_cam(r, Vector3(1.2, 0.15, 1.0), 6.0, -25.0, 22.0)
	await _wait(0.4)
	await _shot("b_animal")
	r.queue_free()
	await get_tree().process_frame
	# c) bina yakın plan
	r = _studio()
	var i := 0
	for e in CLOSE:
		var n: Node3D = BuildingKit.build(e[0], e[1], 1)
		n.position = Vector3((i % 3) * 3.4, 0, (i / 3) * 3.6)
		r.add_child(n)
		i += 1
	_cam(r, Vector3(3.4, 0.6, 1.8), 15.0, -22.0, 26.0)
	await _wait(0.4)
	await _shot("c_bina")
	r.queue_free()
	await get_tree().process_frame
	# d) kaya ve ağaç
	r = _studio()
	i = 0
	for m in ROCKS:
		var a := Models.spawn("nature/" + m)
		a.position = Vector3((i % 3) * 1.6, 0, (i / 3) * 1.6)
		r.add_child(a)
		i += 1
	_cam(r, Vector3(1.6, 0.3, 0.8), 7.5, -20.0, 28.0)
	await _wait(0.4)
	await _shot("d_kaya")
	print("TEST_OK skin_anim")
	get_tree().quit()
