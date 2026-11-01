extends Node3D
## Developer-only F6 scene. Never referenced by the game; excluded from every export.
const POSE = preload("res://tt_models/scripts/worker_pose.gd")
var entries: Array[Dictionary] = []
var stage := Node3D.new()
var sources := Node2D.new()
var camera := Camera3D.new()
var catalog := ItemList.new()
var category := OptionButton.new()
var search := LineEdit.new()
var actions := OptionButton.new()
var heading := Label.new()
var details := Label.new()
var portrait := TextureRect.new()
var speed := HSlider.new()
var scrub := HSlider.new()
var playing := true
var clock := 0.0
var yaw := 0.45
var pitch := 0.3
var distance := 4.0
var center := Vector3(0, 0.5, 0)
var selected: Dictionary
var source
var visual: Node3D
var actor: ActorView3D
var building_view: BuildingView3D
var players: Array = []
var modes: Array[String] = []
var dragging := false

func _ready() -> void:
	if not OS.has_feature("editor"):
		get_tree().quit()
		return
	TranslationServer.set_locale("tr")
	GameState.reset()
	GameState.extra_roads[Vector2i(-2,-1)] = true
	add_child(stage)
	sources.visible = false
	add_child(sources)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1a2430")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d5e3ee")
	env.ambient_light_energy = 0.8
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-30,0)
	add_child(sun)
	add_child(camera)
	camera.current = true
	_make_ui()
	_inventory()
	_filter()
	if "--gallery-check" in OS.get_cmdline_user_args(): _check.call_deferred()

func _button(parent: Node, title: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_right = 310
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,14)
	panel.add_child(margin)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation",10)
	margin.add_child(left)
	var title := Label.new()
	title.text = "MODEL / ANİMASYON\nGeliştirici galerisi"
	title.add_theme_font_size_override("font_size",22)
	left.add_child(title)
	search.placeholder_text = "Model veya kategori ara…"
	search.text_changed.connect(func(_s): _filter())
	left.add_child(search)
	for name in ["Tümü","Köylüler","Hayvanlar","Binalar","Ürünler","Araçlar","Efektler","Portreler","Model dosyaları"]: category.add_item(name)
	category.item_selected.connect(func(_i): _filter())
	left.add_child(category)
	catalog.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog.item_selected.connect(func(i): _select(catalog.get_item_metadata(i)))
	left.add_child(catalog)
	var note := Label.new()
	note.text = "Yalnız geliştirme ekranı\nWindows / Web exportuna dahil değil."
	note.add_theme_font_size_override("font_size",12)
	left.add_child(note)
	var top := VBoxContainer.new()
	top.position = Vector2(338,20)
	layer.add_child(top)
	heading.add_theme_font_size_override("font_size",25)
	top.add_child(heading)
	details.add_theme_font_size_override("font_size",13)
	top.add_child(details)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 326
	bottom.offset_right = -16
	bottom.offset_top = -122
	bottom.offset_bottom = -16
	layer.add_child(bottom)
	var rows := VBoxContainer.new()
	bottom.add_child(rows)
	var row := HBoxContainer.new()
	rows.add_child(row)
	actions.custom_minimum_size.x = 230
	actions.item_selected.connect(func(_i): _mode_changed())
	row.add_child(actions)
	var play := _button(row,"Duraklat",func():
		playing = not playing
		stage.process_mode = Node.PROCESS_MODE_INHERIT if playing else Node.PROCESS_MODE_DISABLED
		for fx in stage.find_children("*", "CPUParticles3D", true, false):
			fx.speed_scale = 1.0 if playing else 0.0)
	play.pressed.connect(func(): play.text = "Duraklat" if playing else "Oynat")
	_button(row,"Başa al",func(): clock = 0; _mode_changed())
	_button(row,"Kamerayı sıfırla",_frame)
	var line := HBoxContainer.new()
	rows.add_child(line)
	var label := Label.new()
	label.text = "Hız"
	line.add_child(label)
	speed.min_value = 0.1
	speed.max_value = 2.0
	speed.step = 0.1
	speed.value = 1.0
	speed.custom_minimum_size.x = 130
	line.add_child(speed)
	var rate := Label.new()
	rate.text = "1.0×"
	speed.value_changed.connect(func(v):
		rate.text = "%.1f×" % v
		Engine.time_scale = v)
	line.add_child(rate)
	var time_label := Label.new()
	time_label.text = "   Zaman"
	line.add_child(time_label)
	scrub.max_value = 10.0
	scrub.step = 0.01
	scrub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrub.value_changed.connect(func(v): clock = v; _animate(0.001))
	line.add_child(scrub)
	var hint := Label.new()
	hint.text = "Sol tuşla sürükle: döndür   •   Tekerlek: yakınlaş   •   Animasyonlar döngüde oynar"
	hint.add_theme_font_size_override("font_size",13)
	rows.add_child(hint)
	portrait.position = Vector2(540,130)
	portrait.size = Vector2(300,360)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(portrait)

func _add(group: String, title: String, kind: String, key: String, level := 1) -> void:
	entries.append({"group":group,"title":title,"kind":kind,"key":key,"level":level})

func _inventory() -> void:
	for i in 6: _add("Köylüler","Köylü • görünüm %d" % (i+1),"worker",str(i))
	for item in [["Civciv","122"],["İnek","120"],["Köpek","121"]]: _add("Hayvanlar",item[0],"animal",item[1])
	for kind in Bal.BUILDINGS:
		for level in range(1,int(Bal.BUILDINGS[kind].max_level)+1):
			_add("Binalar","%s • seviye %d" % [tr(Bal.BUILDINGS[kind].name),level],"building",kind,level)
	for crop in Bal.CROPS:
		for kind in ["field","greenhouse"]: _add("Ürünler", "%s / %s" % [crop,kind],"crop",kind+"|"+crop)
	_add("Araçlar","İtfaiye aracı","truck","car/firetruck")
	for fx in ["fire","smoke","embers","pests","dust","upgrade","repair","water"]: _add("Efektler",fx,"fx",fx)
	for role in Thumbs.PORTRAIT_CHARS: _add("Portreler",role,"portrait",role)
	_scan("res://assets/models")

func _scan(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".glb"):
			var key := (path+"/"+file).trim_prefix(Models.ROOT).trim_suffix(".glb")
			_add("Model dosyaları",key,"raw",key)
	for dir in DirAccess.get_directories_at(path): _scan(path+"/"+dir)

func _filter() -> void:
	catalog.clear()
	for e in entries:
		if category.selected > 0 and e.group != category.get_item_text(category.selected): continue
		if not search.text.is_empty() and not (e.title+" "+e.group).to_lower().contains(search.text.to_lower()): continue
		var i := catalog.add_item(e.title)
		catalog.set_item_metadata(i,e)
		catalog.set_item_tooltip(i,e.group+" / "+e.key)
	if catalog.item_count > 0:
		catalog.select(0)
		_select(catalog.get_item_metadata(0))

func _options(labels: Array, ids: Array) -> void:
	for i in labels.size():
		actions.add_item(labels[i])
		modes.append(ids[i])

func _select(e: Dictionary) -> void:
	for n in stage.get_children(): n.free()
	for n in sources.get_children(): n.free()
	GameState.workers.clear()
	actor = null
	building_view = null
	visual = null
	source = null
	players.clear()
	selected = e
	clock = 0
	actions.clear()
	modes.clear()
	portrait.visible = e.kind == "portrait"
	heading.text = e.title
	details.text = e.group+"  •  "+("Dosya modeli / oyundaki nihai görünüm için Binalar veya Hayvanlar" if e.kind == "raw" else "Oyunun ortak model ve animasyon koduyla önizleme")
	match e.kind:
		"worker", "animal", "truck":
			if e.kind == "worker":
				source = Worker.new()
				source.visual_variant = int(e.key)
				var plot := Building.new()
				plot.setup("field",Vector2i(-1,-1))
				sources.add_child(plot)
				plot.set_process(false)
				source.job = plot
				source.farm_target = Vector2(0,0.38)*Bal.CELL
				_options(["Bekleme","Yürüme","Çapa / hazırlık","Kuyudan su alma","Sulama","Hasat","Sepet taşıma","Kova taşıma","Balta","Kazma","Sığınağa koşma"],["idle","walk","farm","fetch","water_crop","harvest","basket","carry","axe","pickaxe","shelter"])
			elif e.kind == "animal":
				source = Critter.new()
				source.kind = int(e.key)
				_options(["Bekleme","Yürüme","Beslenme"],["idle","walk","eat"])
			else:
				source = FireTruck.new()
				_options(["Park","Sürüş / siren"],["idle","walk"])
			sources.add_child(source)
			source.set_process(false)
			actor = ActorView3D.new(source,"critter" if e.kind == "animal" else e.kind)
			stage.add_child(actor)
			visual = actor
		"building", "crop":
			source = Building.new()
			source.setup(e.key.split("|")[0],Vector2i.ZERO)
			source.level = e.level
			source.position = -Vector2(source.size)*Bal.CELL*0.5
			if e.kind == "crop": source.crop = e.key.split("|")[1]
			sources.add_child(source)
			source.set_process(false)
			building_view = BuildingView3D.new(source)
			stage.add_child(building_view)
			building_view.sync()
			visual = building_view
			_options(["Normal","Yangın","Harabe","İnşaat / yerleşme","90° dönüş"],["idle","burning","ruined","drop","rotate"])
			if source.is_crop(): _options(["Büyüme","Zararlılar","Damla sulama"],["grow","pest","drip"])
			if source.type == "well": _options(["Kuyu ipi / kova"],["well"])
			if source.type == "fire_station": _options(["Garaj kapısı"],["door"])
		"raw":
			visual = Models.spawn(e.key)
			stage.add_child(visual)
			_options(["Sabit"],["idle"])
			for player in visual.find_children("*","AnimationPlayer",true,false):
				player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				players.append(player)
				for clip in player.get_animation_list(): _options([clip],["clip:"+clip])
			if e.key.contains("tree"): _options(["Devrilme"],["fall"])
			if e.key.contains("rock"): _options(["Kırılma / kaldırma"],["break"])
		"fx":
			visual = Node3D.new()
			stage.add_child(visual)
			_options(["Efekt döngüsü"],["fx"])
		"portrait":
			portrait.texture = Thumbs.portrait(e.key)
			_options(["2D karakter çizimi"],["idle"])
	_mode_changed()
	_frame()

func _mode_changed() -> void:
	clock = 0
	if is_instance_valid(actor):
		source.position = Vector2.ZERO
		actor._last = Vector3.ZERO
		actor._t = 0
		actor._stride = 0
		actor.body.set_meta("farm_time",0.0)
	if is_instance_valid(visual):
		visual.rotation = Vector3.ZERO
		visual.scale = Vector3.ONE
	for player in players: player.stop()
	if selected.get("kind") == "fx":
		for child in visual.get_children(): child.free()
		var key: String = selected.key
		var fx: CPUParticles3D
		match key:
			"fire": fx = Fx3D.fire(Vector3.ONE*0.3)
			"smoke": fx = Fx3D.smoke(Vector3.ONE*0.3)
			"embers": fx = Fx3D.embers(Vector3.ONE*0.3)
			"pests": fx = Fx3D.pests(Vector3.ONE*0.3)
			_: fx = Fx3D.burst(key,Vector3.ONE*0.3)
		if fx.one_shot:
			fx.finished.disconnect(fx.queue_free)
			fx.one_shot = false
		visual.add_child(fx)
	_animate(0.001)

func _frame() -> void:
	yaw = 0.45
	pitch = 0.3
	var bounds := BuildingKit._bounds(visual) if is_instance_valid(visual) else AABB(Vector3.ZERO,Vector3.ONE)
	center = bounds.get_center()
	distance = maxf(1.2,bounds.size.length()*1.5)
	_camera()

func _camera() -> void:
	camera.position = center + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(center)
	# Leave room for the catalog without distorting the model.
	camera.h_offset = -distance * 0.12

func _process(delta: float) -> void:
	if selected.is_empty(): return
	if playing:
		clock += delta
		_animate(delta)
		scrub.set_value_no_signal(fposmod(clock,10.0))
	_camera()

func _animate(dt: float) -> void:
	if modes.is_empty(): return
	var mode: String = modes[maxi(0,actions.selected)]
	if actor:
		actor._t = clock - dt
		actor.body.set_meta("farm_time", maxf(0,clock-dt))
		if selected.kind == "worker":
			source.state = Worker.State.WORKING
			source.carry_stage = 0
			source.task_cell = Worker.NO_TASK
			source._goal = Worker.State.WORKING
			source.farm_activity = mode
			source._carry_t = fposmod(clock,3.0)/3.0*Bal.CARRY_FILL_TIME
			if mode in ["idle","walk","basket","carry","shelter"]:
				source.state = Worker.State.WALKING if mode != "idle" else Worker.State.IDLE
				if mode != "idle": source.position.y = clock*20.0
			if mode == "carry": source.carry_stage = 2
			if mode == "shelter": source._goal = Worker.State.SHELTER
			actor.sync(dt)
		elif selected.kind == "animal":
			source.position.y = clock*18.0 if mode == "walk" else 0.0
			actor.sync(dt)
			if mode != "walk" and actor.anim and actor.anim.has_animation(mode):
				actor._play(mode)
				actor.anim.seek(fposmod(clock,actor.anim.get_animation(mode).length),true)
		else:
			source.siren = mode == "walk"
			source.position.y = clock*25.0 if mode == "walk" else 0.0
			actor.sync(dt)
		actor.position.x = 0
		actor.position.z = 0
	elif building_view:
		source.state = mode if mode in ["burning","ruined"] else "normal"
		source._drop = maxf(0,1.0-fposmod(clock,3.0))*Bal.CELL*2.0 if mode == "drop" else 0.0
		source.pest = mode == "pest"
		source.drip = mode == "drip"
		source.harvest_progress = fposmod(clock/6.0,1.0)*source.harvest_time() if mode == "grow" else source.harvest_time()
		source.set_meta("garage_open",fposmod(clock,5.0)<2.5 and mode == "door")
		if mode == "rotate": source.rot = int(clock/1.5)%4
		building_view.sync()
		if mode == "well" and building_view._well_motion:
			building_view._well_motion.update_motion(fposmod(clock/3.0,1.0),Vector3(0.5,0.5,0.4))
	elif selected.kind == "raw":
		if mode.begins_with("clip:"):
			var clip := mode.trim_prefix("clip:")
			for player in players:
				if not player.has_animation(clip): continue
				if player.current_animation != clip: player.play(clip)
				player.seek(fposmod(clock,maxf(0.001,player.get_animation(clip).length)),true)
		if mode == "fall": visual.rotation.x = pow(clampf(fposmod(clock,3.0)/1.2,0,1),2)*PI*0.48
		if mode == "break": visual.scale = Vector3.ONE*(1.0-clampf(fposmod(clock,3.0)/1.2,0,1)*0.85)
	elif selected.kind == "fx":
		for fx in visual.get_children(): fx.speed_scale = 1.0 if playing else 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(0.2,distance*0.88)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance *= 1.12
	if event is InputEventMouseMotion and dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): dragging = false
	if event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x*0.008
		pitch = clampf(pitch+event.relative.y*0.008,-0.4,1.4)

func _check() -> void:
	for entry in entries:
		_select(entry)
		for i in modes.size():
			actions.select(i)
			_mode_changed()
			clock = 1.4
			_animate(0.1)
		await get_tree().process_frame
	print("GALLERY_OK ",entries.size()," entries and all animation modes")
	_select(entries[0])
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://dev_gallery/preview.png")
	get_tree().quit()
