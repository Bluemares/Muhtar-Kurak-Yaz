extends Node
## Model seti karşılaştırma: godot --path . res://tests/skin_compare.tscn -- --skin=tests/_cmp/gpt/ --out=gpt
## Stüdyo sayfaları + gerçek oyun görüntüleri + performans. Çıktı: tests/_cmp/shots/<out>_*.png

const OUT := "res://tests/_cmp/shots/"
const BLD := [["house", 1], ["cop31", 1], ["cop31", 2], ["cop31", 3], ["fire_station", 1], ["well", 1], ["well", 3], ["field", 1], ["greenhouse", 1], ["water_tower", 1], ["grove", 1], ["granary", 1], ["lamp", 1]]
const CHARS := ["male-a", "male-b", "male-c", "male-d", "male-e", "male-f", "female-a", "female-b", "female-c", "female-d", "female-e", "female-f"]
const NATURE := ["tree_pineTallA", "tree_pineRoundA", "tree_fat", "tree_plateau", "tree_default", "tree_palm", "tree_palmBend", "stone_largeA", "stone_tallA", "bridge_wood", "pot_large", "grass_large", "flower_redA", "plant_bushSmall", "crops_leafsStageB", "crop_carrot", "crop_turnip", "crop_melon", "crops_cornStageB", "crops_cornStageD", "crops_wheatStageB", "crops_dirtRow"]

var tag := "ken"


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP skin_compare: requires rendering")
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
	env.background_color = Color(0.72, 0.74, 0.68)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.88, 0.82)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.shadow_enabled = true
	r.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.62, 0.64, 0.5)
	g.material_override = gm
	r.add_child(g)
	add_child(r)
	return r


func _cam(r: Node3D, target: Vector3, dist: float, yaw: float, pitch: float) -> Camera3D:
	var c := Camera3D.new()
	c.fov = 30.0
	var b := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, -deg_to_rad(pitch))
	c.transform = Transform3D(b, target + b * Vector3(0, 0, dist))
	r.add_child(c)
	c.make_current()
	return c


func _clear(r: Node3D) -> void:
	r.queue_free()
	await get_tree().process_frame


func _run() -> void:
	# 1) binalar
	var r := _studio()
	var i := 0
	for e in BLD:
		var n: Node3D = BuildingKit.build(e[0], e[1], 1)
		n.position = Vector3((i % 5) * 3.2, 0, (i / 5) * 3.6)
		r.add_child(n)
		if e[0] == "field":
			var p := BuildingKit.field_plants(1, 0.8, false, "veg")
			p.position = n.position
			r.add_child(p)
		elif e[0] == "greenhouse":
			var p := BuildingKit.greenhouse_plants(0.8, false, "corn")
			p.position = n.position
			r.add_child(p)
		i += 1
	_cam(r, Vector3(6.4, 0.5, 3.4), 19.0, -24.0, 38.0)
	await _wait(0.5)
	await _shot("1_binalar")
	_cam(r, Vector3(6.4, 0.5, 3.4), 19.0, 156.0, 38.0)
	await _wait(0.3)
	await _shot("1b_binalar_arka")
	# 2) bina yakın plan: ev, COP31 L3
	_cam(r, Vector3(1.8, 0.8, 0.3), 6.5, -26.0, 24.0)
	await _wait(0.3)
	await _shot("2_yakin_ev_cop")
	_cam(r, Vector3(6.4, 0.7, 0.2), 6.5, -26.0, 24.0)
	await _wait(0.2)
	await _shot("2b_yakin_cop2_3")
	_cam(r, Vector3(12.8, 0.6, 0.2), 5.5, -26.0, 24.0)
	await _wait(0.2)
	await _shot("2c_yakin_itfaiye")
	await _clear(r)
	# 3) karakterler + hayvan + araç + alet (oyun ölçeğiyle)
	r = _studio()
	i = 0
	for c in CHARS:
		var ch := Models.spawn("chars/character-" + c)
		ch.scale = Vector3.ONE * 0.62
		ch.position = Vector3((i % 6) * 0.62, 0, (i / 6) * 0.8)
		r.add_child(ch)
		var aps := ch.find_children("*", "AnimationPlayer", true, false)
		if not aps.is_empty():
			var an := "walk" if i % 3 == 0 else ("hoe" if aps[0].has_animation("hoe") and i % 3 == 1 else "idle")
			if aps[0].has_animation(an):
				aps[0].play(an)
				aps[0].seek(0.25, true)
				aps[0].pause()
		i += 1
	var spec := [["pets/animal-chick", 0.17], ["pets/animal-cow", 0.36], ["pets/animal-dog", 0.24], ["car/firetruck", 0.38]]
	i = 0
	for s in spec:
		var a := Models.spawn(s[0])
		a.scale = Vector3.ONE * float(s[1])
		a.position = Vector3(i * 0.85, 0, 1.75)
		r.add_child(a)
		var aps := a.find_children("*", "AnimationPlayer", true, false)
		if not aps.is_empty() and aps[0].has_animation("walk"):
			aps[0].play("walk")
			aps[0].seek(0.2, true)
			aps[0].pause()
		i += 1
	i = 0
	for pr in ["hoe", "axe", "bucket", "basket", "hose"]:
		var a := Models.spawn("props/" + pr)
		a.position = Vector3(3.2 + i * 0.25, 0.15 if pr in ["bucket", "basket"] else 0.0, 1.75)
		r.add_child(a)
		i += 1
	_cam(r, Vector3(1.6, 0.25, 0.9), 5.0, -14.0, 26.0)
	await _wait(0.5)
	await _shot("3_karakter")
	await _clear(r)
	# 4) doğa + ekin
	r = _studio()
	i = 0
	for m in NATURE:
		var a := Models.spawn("nature/" + m)
		a.position = Vector3((i % 7) * 1.25, 0, (i / 7) * 1.5)
		r.add_child(a)
		i += 1
	_cam(r, Vector3(3.7, 0.3, 1.9), 12.0, -18.0, 32.0)
	await _wait(0.4)
	await _shot("4_doga")
	await _clear(r)
	# 5) gerçek oyun
	var game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _wait(4.0)
	game.skip_tutorial()
	await _wait(0.3)
	for b in get_tree().root.find_children("*", "Button", true, false):
		if b.text == tr("BTN_START_MONTH"):
			b.pressed.emit()
	await _wait(0.5)
	game.hud.hide_dialog()
	GameState.find_building("cop31").level = 3
	for e in [["house", Vector2i(12, 9)], ["house", Vector2i(13, 11)], ["house", Vector2i(10, 11)], ["house", Vector2i(17, 9)], ["house", Vector2i(18, 11)], ["house", Vector2i(12, 11)],
			["greenhouse", Vector2i(17, 8)], ["granary", Vector2i(19, 11)], ["water_tower", Vector2i(20, 9)], ["grove", Vector2i(15, 14)], ["field", Vector2i(14, 14)], ["lamp", Vector2i(15, 11)], ["field", Vector2i(17, 14)]]:
		if game.village.can_place(e[0], e[1]):
			var nb = game.village.spawn_building(e[0], e[1])
			if nb.type == "field":
				nb.crop = ["corn", "wheat", "melon", "veg"][e[1].x % 4]
				nb.harvest_progress = nb.harvest_time() * 0.9
	game.camera.pitch = 46.0
	game.camera.yaw = -32.0
	await _wait(1.5)
	await _shot("5_oyun")
	game.camera.position = Vector2(16, 11) * 64
	game.camera.zoom = Vector2.ONE * 2.0
	game.camera.pitch = 36.0
	await _wait(1.0)
	await _shot("6_oyun_yakin")
	game.camera.zoom = Vector2.ONE * 1.0
	game.camera.pitch = 50.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _wait(1.0)
	var fps := 0.0
	for k in 20:
		await _wait(0.1)
		fps += Engine.get_frames_per_second()
	printerr("SKIN %s fps=%.0f draw_calls=%d prims=%d objects=%d" % [tag, fps / 20.0, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
	print("TEST_OK skin_compare")
	get_tree().quit()
