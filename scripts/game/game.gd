extends Node2D
## Oyun sahnesi orkestratörü: giriş, öğretici, turlar, tehditler, yangın akışı, final.

const MINIGAME_SCENE := preload("res://scenes/fire_minigame.tscn")

var village: Village
var camera  # camera_rig.gd (2D) ya da camera_rig_3d.gd
var world3d: WorldView3D
var truck: FireTruck
var hud
var tutorial
var events
var _rain: CPUParticles2D

var fire_active := false
var round_fire_count := 0
var round_elapsed := 0.0
var _tick_acc := 0.0
var _modal_open := false
var _pause_modal: Control
var _drive_tween: Tween
var _fire_target = null
var _travel_time := 0.0
var _arrived := false
var _follow_truck := false
var _pest_arrow := false
var _round_summary: Dictionary = {}


func _ready() -> void:
	add_to_group("game")
	get_tree().paused = false
	GameState.reset()
	village = Village.new()
	add_child(village)
	truck = FireTruck.new()
	truck.village = village
	village.add_child(truck)
	View.risk_map = false
	if Bal.RENDER_3D:
		world3d = WorldView3D.new()
		world3d.village = village
		world3d.truck = truck
		add_child(world3d)
		village.visible = false
		camera = preload("res://scripts/world3d/camera_rig_3d.gd").new()
		View.camera = camera
		var info_layer := CanvasLayer.new()
		info_layer.layer = 3
		info_layer.add_child(preload("res://scripts/world3d/info_overlay.gd").new())
		add_child(info_layer)
	else:
		camera = preload("res://scripts/world/camera_rig.gd").new()
		View.camera = null
	add_child(camera)
	camera.make_current()
	add_child(preload("res://scripts/world/atmosphere.gd").new())
	add_child(preload("res://scripts/world/daylight.gd").new())
	events = preload("res://scripts/game/events.gd").new()
	events.game = self
	add_child(events)
	_add_rain()
	UI.fade_in(self, 0.6)
	hud =preload("res://scripts/ui/hud.gd").new()
	hud.game = self
	add_child(hud)
	tutorial = preload("res://scripts/game/tutorial.gd").new()
	tutorial.game = self
	add_child(tutorial)

	var load_data: Dictionary = GameState.pending_load
	GameState.pending_load = {}
	if load_data.is_empty():
		village.setup_start()
	else:
		GameState.apply_save(load_data)
		village.setup_from_save(load_data)
	truck.position = _station().center()
	truck.visible = false
	if is_instance_valid(_station()):
		_station().set_meta("garage_open", false)
		_station().set_meta("truck_away", false)
	camera.fit_to(village.unlocked_world_rect(), Rect2(Vector2.ZERO, village.world_size()))
	village.building_selected.connect(hud.show_selection)
	village.focus_requested.connect(func(b):
		if not camera.cinematic:
			camera.focus(b.center(), camera.base_zoom * 2.2, 0.5))
	village.selection_cleared.connect(hud.hide_selection)
	GameState.worker_born.connect(village.spawn_worker_at_house)
	GameState.welfare_zero.connect(_on_welfare_zero)
	tutorial.finished.connect(_on_tutorial_finished)
	if load_data.is_empty():
		_intro()
	else:
		_round_summary = GameState.resume_context.get("round_summary", {}).duplicate(true)
		if not _round_summary.is_empty():
			events.start_round(true)
			Audio.set_intensity(GameState.round_index)
			policy_offer = GameState.resume_context.get("policy_offer", []).duplicate()
			if policy_offer.is_empty():
				_show_round_summary()
			else:
				_show_policy_offer()
		else:
			start_round(GameState.round_index, GameState.round_time_left)


# ---------------- Giriş ----------------

func _intro() -> void:
	village.input_locked = true
	camera.cinematic = true
	var home: Vector2 = camera.home_position()
	camera.position = home - Vector2(0, 260)
	camera.zoom = Vector2.ONE * camera.base_zoom * 0.45
	var tw: Tween = camera.focus(home, camera.base_zoom, 2.6)
	await tw.finished
	camera.cinematic = false
	village.input_locked = false
	hud.show_dialog(tr("INTRO_1"), _intro_2, true)


func _intro_2() -> void:
	hud.show_dialog(tr("INTRO_2"), tutorial.start, true)


func skip_tutorial() -> void:
	if tutorial.active:
		tutorial.skip()
	else:
		hud.hide_dialog()
		_on_tutorial_finished()


func _on_tutorial_finished() -> void:
	if GameState.round_active or _modal_open:
		return
	start_round(0)


# ---------------- Turlar ----------------

## resume_time > 0: kayıttan devam (ay yarıda kaldıysa kalan süreyle).
func start_round(i: int, resume_time := -1.0) -> void:
	_round_summary = {}
	policy_offer = []
	var resuming := resume_time > 0.0
	GameState.round_index = i
	GameState.round_time_left = resume_time if resume_time > 0.0 else Bal.ROUND_SECONDS
	round_fire_count = int(GameState.round_stats.fires) if resuming else 0
	round_elapsed = maxf(0.0, Bal.ROUND_SECONDS - resume_time) if resuming else 0.0
	_full_tank_secs = float(GameState.resume_context.get("full_tank_secs", 0.0)) if resuming else 0.0
	events.start_round(resuming)
	GameState.save_game()
	Audio.set_intensity(i)
	_modal_open = true
	get_tree().paused = true
	hud.show_mission_card(i, func():
		_modal_open = false
		get_tree().paused = false
		GameState.round_active = true
		events.resume_pending()
		hud.banner(tr(Bal.MONTH_KEYS[i]), "%d°C" % Bal.TEMPERATURE[i]))


func save_runtime_context() -> Dictionary:
	return {"events": events.save_state(), "full_tank_secs": _full_tank_secs,
		"round_summary": _round_summary.duplicate(true), "policy_offer": policy_offer.duplicate()}


## Ekran üstü yağmur (HUD altında).
func _add_rain() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(0.8, 0.9, 1.0, 0.0))
	gr.set_color(1, Color(0.8, 0.9, 1.0, 0.8))
	g.gradient = gr
	g.fill_from = Vector2(0.5, 0.0)
	g.fill_to = Vector2(0.5, 1.0)
	g.width = 2
	g.height = 22
	_rain = CPUParticles2D.new()
	_rain.texture = g
	_rain.amount = 260
	_rain.lifetime = 0.8
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(760, 10)
	_rain.position = Vector2(700, -30)
	_rain.direction = Vector2(-0.25, 1)
	_rain.spread = 2
	_rain.gravity = Vector2.ZERO
	_rain.initial_velocity_min = 900
	_rain.initial_velocity_max = 1100
	_rain.rotation = 0.24
	_rain.emitting = false
	layer.add_child(_rain)


func _process(delta: float) -> void:
	_rain.emitting = GameState.rain_left > 0.0 and not get_tree().paused
	if _follow_truck:
		if not camera.has_method("follow_fire_subject"):
			camera.position = truck.position
	if get_tree().paused or not GameState.round_active or GameState.game_over:
		return
	GameState.round_time_left -= delta
	round_elapsed += delta
	_tick_acc += delta
	while _tick_acc >= 1.0:
		_tick_acc -= 1.0
		_sim_tick()
	if GameState.round_time_left <= 0.0:
		GameState.round_time_left = 0.0
		_end_round()


func _sim_tick() -> void:
	GameState.tick(1.0)
	village.assign_workers()
	_threats_tick()
	_side_tick()
	events.tick(1.0)


# ---------------- Yan görevler ----------------

var _full_tank_secs := 0.0


func side_key(id: String) -> String:
	return "side_%d_%s" % [GameState.round_index, id]


func side_completed(id: String) -> bool:
	return GameState.flags.get(side_key(id), false)


func _side_tick() -> void:
	var gs := GameState
	if gs.round_index == 2 and gs.water >= gs.water_cap * 0.8:
		_full_tank_secs += 1.0
	for m in Bal.SIDE_MISSIONS[gs.round_index]:
		if not side_completed(m[0]) and _side_done(m[0]):
			gs.flags[side_key(m[0])] = true
			gs.stats.side += 1
			gs.add_money(m[1])
			gs.notify.emit("SIDE_DONE", Color("8fe388"))
			village.spawn_floating(village.unlocked_world_rect().get_center(), "+%d" % m[1], Color.GOLD)
			Audio.play("saved", 0.0)


func _side_done(id: String) -> bool:
	var gs := GameState
	match id:
		"road2": return gs.road_level >= 2
		"house3": return gs.count("house") >= 3
		"river_well": return gs.buildings.any(func(b): return b.type == "well" and b.near_river and b.state == "normal")
		"drip": return gs.buildings.any(func(b): return b.type == "field" and b.drip)
		"spray": return gs.flags.get("sprayed_%d" % gs.round_index, false)
		"cop2": return village.cop_level() >= 2
		"full_tank": return _full_tank_secs >= Bal.FULL_TANK_SECONDS
		"station_near":
			var st = _station()
			var cop = gs.find_building("cop31")
			return st and cop and st.center().distance_to(cop.center()) <= Bal.CELL * 4.5
		"fields4": return gs.buildings.filter(func(b): return b.type == "field" and b.state == "normal").size() >= 4
	return false


func _end_round() -> void:
	GameState.round_active = false
	village.cancel_mode()
	var summary: Dictionary = GameState.end_round(_mission_ok())
	if GameState.game_over:
		return
	_round_summary = summary
	GameState.save_game()
	_show_round_summary()


func _show_round_summary() -> void:
	_modal_open = true
	get_tree().paused = true
	hud.show_round_summary(_round_summary, func():
		_modal_open = false
		if GameState.round_index >= Bal.MONTH_KEYS.size() - 1:
			_finish_game(false)
		else:
			_offer_policies())


## Ay sonu COP31 politika seçimi: alınmamışlardan 3 rastgele kart.
var policy_offer: Array = []


func _offer_policies() -> void:
	var pool := Bal.POLICIES.filter(func(p): return not GameState.has_policy(p))
	pool.shuffle()
	policy_offer = pool.slice(0, 3)
	if policy_offer.is_empty():
		start_round(GameState.round_index + 1)
		return
	GameState.save_game()
	_show_policy_offer()


func _show_policy_offer() -> void:
	_modal_open = true
	get_tree().paused = true
	hud.show_policy_choice(policy_offer, choose_policy)


func choose_policy(i: int) -> void:
	var id: String = policy_offer[i]
	policy_offer = []
	GameState.flags["pol_" + id] = true
	if id == "green_fund":
		GameState.add_money(150)
	Audio.play("upgrade", 0.0)
	_modal_open = false
	start_round(GameState.round_index + 1)


func _mission_ok() -> bool:
	match GameState.round_index:
		0:
			var fields := GameState.buildings.filter(func(b): return b.type == "field" and b.state != "ruined")
			return fields.size() >= 2 and not GameState.hungry
		1:
			return GameState.food_days() >= Bal.JULY_FOOD_DAYS and not GameState.hungry
		2:
			return GameState.crop_kinds() >= Bal.AUGUST_CROP_KINDS and not GameState.hungry
	return false


# ---------------- Tehditler ----------------

func _threats_tick() -> void:
	var d := GameState.drought()
	var grace := GameState.round_index == 0 and round_elapsed < Bal.FIRE_GRACE_SECONDS
	if not fire_active and not grace:
		var candidates: Array = []
		for b in GameState.buildings:
			if Bal.BUILDINGS[b.type].flammable and b.state == "normal":
				candidates.append(b)
				if randf() < GameState.fire_chance(b):
					ignite(b)
					break
		if not fire_active and GameState.round_index == Bal.GUARANTEED_FIRE_ROUND and round_fire_count == 0 \
				and round_elapsed >= Bal.GUARANTEED_FIRE_AT and not candidates.is_empty():
			var fields := candidates.filter(func(b): return b.type == "field")
			ignite((fields if not fields.is_empty() else candidates).pick_random())
	# Böcek
	if GameState.round_index >= Bal.PEST_START_ROUND:
		for b in GameState.buildings:
			if b.type == "field" and b.state == "normal" and not b.pest and not b.is_protected():
				if randf() < Bal.PEST_CHANCE * (1.0 + d):
					b.pest = true
					GameState.notify.emit("NOTE_PEST", Color.YELLOW)
					Audio.play("alert", 0.0)
					if GameState.flag_once("ilk_bocek_goruldu"):
						_first_pest(b)


func _first_pest(b) -> void:
	get_tree().paused = true
	_modal_open = true
	village.select(b)
	camera.focus(b.center(), camera.base_zoom * 1.2)
	hud.point_world(b.center())
	hud.show_dialog(tr("FIRST_PEST"), func():
		_modal_open = false
		get_tree().paused = false
		_pest_arrow = true
		hud.point_control(hud.control_for("spray_btn")), false, "farmer")


# ---------------- Yangın akışı ----------------

func ignite(b) -> void:
	if fire_active:
		_set_burning(b)  # aynı yangın olayına katılır
		return
	_set_burning(b)
	fire_active = true
	round_fire_count += 1
	GameState.stats.fires += 1
	GameState.round_stats.fires += 1
	GameState.notify.emit("NOTE_FIRE", Color("ff6b35"))
	Audio.play("fire", 0.0)
	Audio.loop("crackle", true, -6.0)
	Audio.duck(true)
	camera.shake(10.0, 0.6)
	village.cancel_mode()
	if GameState.flag_once("ilk_yangin_goruldu"):
		get_tree().paused = true
		_modal_open = true
		camera.focus(b.center(), camera.base_zoom * 1.3)
		hud.point_world(b.center())
		hud.show_dialog(tr("FIRST_FIRE"), func():
			hud.clear_arrow()
			_modal_open = false
			_start_fire_sequence(b), false, "fire")
	else:
		_start_fire_sequence(b)


func _set_burning(b) -> void:
	b.state = "burning"
	if b.worker:
		b.worker.shelter()
	if village.selected == b:
		hud.show_selection(b)


func _start_fire_sequence(b) -> void:
	get_tree().paused = true
	village.input_locked = true
	_fire_target = b
	_arrived = false
	var station = _station()
	station.set_meta("garage_open", true)
	station.set_meta("truck_away", true)
	var start: Vector2 = station.center()
	var heading: float = -station.rot * PI * 0.5
	truck.set_meta("heading", heading)
	var exit_point := start + Vector2(sin(heading), cos(heading)) * Bal.CELL * 2.5
	var target: Vector2 = b.center()
	truck.position = start
	truck.visible = true
	# rota: yol bulma yolları tercih eder; yolda hızlı, yol dışında (tarla/çayır) yavaş gider.
	# Böylece yol ağı ve yol seviyesi itfaiyenin varış süresini, dolayısıyla yangının yayılmasını belirler.
	var pts: Array = village.road_path(exit_point, b)
	if pts.is_empty() or not village.truck_segment_clear(start, exit_point, station):
		truck.visible = false
		station.set_meta("garage_open", false)
		station.set_meta("truck_away", false)
		_travel_time = Bal.CINEMATIC_MAX
		GameState.notify.emit("NOTE_TRUCK_ROUTE_BLOCKED", Color.ORANGE_RED)
		_arrive()
		return
	truck.set_meta("arrival_point", pts[-1])
	pts.push_front(exit_point)
	var prev := start
	_travel_time = 0.0
	for p in pts:
		var mid: Vector2 = (prev + p) * 0.5
		var spd: float = Bal.TRUCK_SPEED * (GameState.road_speed() if village.is_road(village.cell_of(mid)) else Bal.TRUCK_OFFROAD)
		_travel_time += prev.distance_to(p) / spd
		prev = p
	if GameState.has_policy("early_warning"):
		_travel_time /= 1.3
	var anim := clampf(_travel_time, 1.5, Bal.CINEMATIC_MAX)
	camera.cinematic = true
	var z: float = camera.base_zoom
	if camera.has_method("begin_fire_shot"):
		camera.begin_fire_shot(start, heading)
	else:
		camera.focus(start, z * 2.2, 0.5)
	hud.show_skip(true)
	await get_tree().create_timer(0.85, true).timeout
	if _arrived:
		station.set_meta("garage_open", false)
		return
	_follow_truck = true
	if camera.has_method("follow_fire_subject"):
		camera.follow_fire_subject(truck)
	if not camera.has_method("begin_fire_shot"):
		var zt: Tween = camera.create_tween()
		zt.tween_property(camera, "zoom", Vector2.ONE * z * 1.3, anim)
	_drive_tween = truck.drive(pts, anim)
	_drive_tween.finished.connect(_arrive)
	_close_garage_after_exit(station)


func _close_garage_after_exit(station) -> void:
	while is_instance_valid(station) and truck.visible and not _arrived and truck.position.distance_to(station.center()) < Bal.CELL * 2.0:
		await get_tree().process_frame
	if is_instance_valid(station):
		station.set_meta("garage_open", false)


func skip_cinematic() -> void:
	if _arrived or _fire_target == null:
		return
	if _drive_tween and _drive_tween.is_valid():
		_drive_tween.kill()
	truck.position = truck.get_meta("arrival_point", truck.position)
	_arrive()


func _arrive() -> void:
	if _arrived:
		return
	_arrived = true
	_follow_truck = false
	if camera.has_method("follow_fire_subject"):
		camera.follow_fire_subject(null)
	truck.stop()
	hud.show_skip(false)
	_simulate_spread(_travel_time)
	var burning := GameState.buildings.filter(func(x): return x.state == "burning")
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var mg = MINIGAME_SCENE.instantiate()
	layer.add_child(mg)
	mg.setup(burning, _best_well_level())
	var towers := GameState.buildings.filter(func(x): return x.type == "water_tower" and x.state == "normal").size()
	mg.tank_max += towers * Bal.TOWER_HOSE + maxi(0, burning.size() - 1) * Bal.HOSE_PER_EXTRA_FIRE
	mg.tank = mg.tank_max
	if GameState.flags.get("volunteers", false):
		mg.time_left += 6.0
	mg.finished.connect(_on_minigame_finished.bind(layer))


## Varış süresi boyunca yangının komşu tarla/evlere sıçraması mantıksal olarak hesaplanır.
func _simulate_spread(seconds: float) -> void:
	var step := 0.5
	var p := Bal.FIRE_SPREAD_PER_SEC * (0.5 + GameState.drought()) * step
	var t := 0.0
	while t < seconds:
		t += step
		var newly: Array = []
		for b in GameState.buildings:
			if b.state != "burning":
				continue
			for n in village.neighbors(b):
				if Bal.BUILDINGS[n.type].flammable and (n.state == "normal" or n.state == "moving") and randf() < p:
					newly.append(n)
		for n in newly:
			if n.state != "burning":
				_set_burning(n)


func _best_well_level() -> int:
	var lvl := 1
	for b in GameState.buildings:
		if b.type == "well" and b.state == "normal":
			lvl = maxi(lvl, b.level)
	return lvl


func _on_minigame_finished(results: Dictionary, layer: CanvasLayer) -> void:
	layer.queue_free()
	for b in results:
		if results[b]:
			b.state = "normal"
			b.burst("spray")
		else:
			b.state = "ruined"
			b.pest = false
			b.drip = false
			b.harvest_progress = 0.0
			b.crop_ready = false
			b.pending_harvest = 0.0
			b.reset_crop_work()
			GameState.stats.burned += 1
			GameState.round_stats.burned += 1
			GameState.stats.damage += b.repair_cost()
			camera.shake(6.0, 0.4)
			Audio.play("collapse")
	for w in GameState.workers:
		if w.state == Worker.State.SHELTER or (w._goal == Worker.State.SHELTER):
			w.return_to_work()
	_fire_target = null
	fire_active = false
	Audio.loop("crackle", false)
	Audio.duck(false)
	camera.cinematic = false
	if camera.has_method("end_fire_shot"):
		camera.end_fire_shot()
	else:
		camera.reset_view()
	village.input_locked = false
	truck.visible = false
	if is_instance_valid(_station()):
		_station().set_meta("garage_open", false)
		_station().set_meta("truck_away", false)
	get_tree().paused = _modal_open
	if village.selected:
		hud.show_selection(village.selected)
	GameState.changed.emit()


func _station():
	return GameState.find_building("fire_station")


# ---------------- Oyuncu eylemleri (HUD çağırır) ----------------

func _blocked() -> bool:
	return get_tree().paused or village.input_locked


func request_road_paint() -> void:
	if _blocked():
		return
	if village.mode == "road":
		village.cancel_mode()
	else:
		village.begin_road()


func request_clear() -> void:
	if _blocked():
		return
	if village.mode == "clear":
		village.cancel_mode()
	else:
		village.begin_clear()


## Binayı satar: yarı fiyatını geri verir, işçisi boşa çıkar. COP31 ve itfaiye satılamaz.
func request_sell(b) -> void:
	if not can_sell(b):
		return
	var refund := sell_value(b)
	if b.worker and is_instance_valid(b.worker):
		b.worker.unassign()
	for w in GameState.workers:
		if w.job == b:
			w.unassign()
	village.clear_selection()
	GameState.buildings.erase(b)
	GameState.add_money(refund)
	village.spawn_floating(b.center(), "+%d" % refund, Color.GOLD)
	b.burst("dust")
	Audio.play("collapse", 0.1)
	b.queue_free()


func can_sell(b) -> bool:
	return b.type != "cop31" and b.type != "fire_station" and b.state != "burning"


func sell_value(b) -> int:
	return int(Bal.BUILDINGS[b.type].cost * Bal.SELL_REFUND)


## Rotate placed buildings by 90 degrees and update their occupied cells.
func request_rotate(b) -> void:
	if not is_instance_valid(b) or b.state != "normal" or village.input_locked:
		return
	if village.mode == "move" and village.moving_building == b:
		village.ghost_rot = (village.ghost_rot+1)%4
		return
	var next_rot: int = (b.rot + 1) % 4
	var new_cell: Vector2i = village.rotation_cell(b,next_rot)
	if new_cell == Vector2i(-999,-999):
		if b.can_move():
			village.begin_move(b)
			village.ghost_rot = next_rot
			village.ghost_cell = b.cell
			GameState.notify.emit("NOTE_ROTATE_REPOSITION", Color.ORANGE)
		else:
			GameState.notify.emit("NOTE_ROTATE_BLOCKED", Color.ORANGE_RED)
		return
	b.set_cell(new_cell)
	b.rot = next_rot
	b.pop()
	if b.worker and b.is_crop():
		b.worker.go_to_work()
	if village.selected == b:
		hud.show_selection(b)
	Audio.play("click", 0.1)


## Tarlada ürünü değiştirir: yeniden ekim, büyüme baştan.
func request_crop(b, id: String) -> void:
	if b.crop == id:
		return
	b.crop = id
	b.harvest_progress = 0.0
	b.crop_ready = false
	b.reset_crop_work()
	b.burst("dust")
	Audio.play("build", 0.15)
	GameState.notify.emit("NOTE_CROP_" + id.to_upper(), Color("bfe8a0"))
	if village.selected == b:
		hud.show_selection(b)


func request_build(type: String) -> void:
	if _blocked():
		return
	village.begin_build(type)


func can_move(b) -> bool:
	if not b.can_move():
		return false
	if fire_active and b.type == "fire_station":
		return false
	return true


func request_move(b) -> void:
	if _blocked():
		return
	if not can_move(b):
		GameState.notify.emit("NOTE_CANT_MOVE", Color.ORANGE_RED)
		return
	village.begin_move(b)


func request_upgrade(b) -> void:
	if _blocked() or b.state != "normal":
		return
	var c: int = b.upgrade_cost()
	if c <= 0:
		return
	var cat := "prevention" if b.type == "well" else "upgrade"
	if GameState.spend(c, cat):
		b.level += 1
		b.harvest_progress = 0.0
		b.crop_ready = false
		b.reset_crop_work()
		b.burst("upgrade")
		if b.type == "cop31":
			_expand_village()
		village.spawn_floating(b.center(), tr("FLOAT_UPGRADED"), Color.AQUAMARINE)
		Audio.play("upgrade")
		hud.show_selection(b)


func request_spray(b) -> void:
	if _blocked() or b.state == "ruined" or b.state == "burning":
		return
	if GameState.spend(Bal.SPRAY_COST, "prevention"):
		b.pest = false
		b.protect_until = GameState.time + Bal.SPRAY_DURATION
		GameState.flags["sprayed_%d" % GameState.round_index] = true
		b.burst("spray")
		village.spawn_floating(b.center(), tr("FLOAT_SPRAYED"), Color.GREEN_YELLOW)
		Audio.play("spray")
		hud.show_selection(b)
		if _pest_arrow:
			_pest_arrow = false
			hud.clear_arrow()


## COP31 yükselince köy sınırı genişler: kamera yeni alana açılır.
func _expand_village() -> void:
	village.queue_redraw()
	camera.fit_to(village.unlocked_world_rect(), Rect2(Vector2.ZERO, village.world_size()), false)
	camera.reset_view(1.2)
	camera.shake(4.0, 0.4)
	hud.banner(tr("BANNER_EXPANDED"), tr("BANNER_EXPANDED_SUB"))


## Damla sulama: tarlanın su tüketimini azaltan önlem.
func request_drip(b) -> void:
	if _blocked() or b.type != "field" or b.drip or b.state != "normal":
		return
	if GameState.spend(Bal.DRIP_COST, "prevention"):
		b.drip = true
		b.burst("water")
		Audio.play("upgrade")
		village.spawn_floating(b.center(), tr("FLOAT_DRIP"), Color(0.55, 0.85, 1.0))
		hud.show_selection(b)


func request_repair(b) -> void:
	if _blocked() or b.state != "ruined":
		return
	if GameState.spend(b.repair_cost(), "repair"):
		b.state = "moving"
		b.move_timer = Bal.MOVE_DURATION
		b.burst("repair")
		Audio.play("build")
		village.spawn_floating(b.center(), tr("FLOAT_REPAIRED"), Color.AQUAMARINE)
		hud.show_selection(b)


func request_road_upgrade() -> void:
	if _blocked() or GameState.road_level >= Bal.ROAD_MAX_LEVEL:
		return
	if GameState.spend(Bal.ROAD_UPGRADE_COST[GameState.road_level + 1], "prevention"):
		GameState.road_level += 1
		GameState.notify.emit("NOTE_ROAD_UPGRADED", Color.AQUAMARINE)
		Audio.play("upgrade")
		camera.shake(3.0, 0.25)


func toggle_pause() -> void:
	if fire_active or _modal_open:
		return
	if _pause_modal and is_instance_valid(_pause_modal):
		_resume()
		return
	get_tree().paused = true
	_pause_modal = hud.show_pause_menu(_resume, _to_menu)


## Duraklatma menüsünden dil değişimi: menüyü yeni dilde yeniden açar.
func set_language_paused(code: String) -> void:
	Settings.set_language(code)
	if _pause_modal and is_instance_valid(_pause_modal):
		_pause_modal.queue_free()
	_pause_modal = hud.show_pause_menu(_resume, _to_menu)


func _resume() -> void:
	if _pause_modal and is_instance_valid(_pause_modal):
		_pause_modal.queue_free()
	_pause_modal = null
	get_tree().paused = false


func _to_menu() -> void:
	GameState.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if village.selected:
			village.clear_selection()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()


# ---------------- Final ----------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and GameState.round_index >= 0 and not GameState.game_over:
		if GameState.round_active or _modal_open:
			GameState.save_game()


func _on_welfare_zero() -> void:
	_finish_game(true)


func _finish_game(lost: bool) -> void:
	var w := GameState.welfare
	GameState.final_result = {
		"lost": lost,
		"good": not lost and w >= Bal.GOOD_WELFARE,
		"won": not lost and w >= Bal.WIN_WELFARE,
		"welfare": w,
		"burned": GameState.stats.burned,
		"produced": GameState.stats.produced,
		"prevention": GameState.stats.prevention,
		"damage": GameState.stats.damage,
		"missions": GameState.stats.missions,
		"side": GameState.stats.side,
		"fed_pct": int(round(100.0 * (1.0 - float(GameState.stats.get("hunger_secs", 0.0)) / maxf(float(GameState.stats.get("play_secs", 1.0)), 1.0)))),
		"policies": GameState.policies(),
		"climate_report": ClimateReport.snapshot(GameState.stats),
	}
	Progress.finalize(GameState.final_result)
	GameState.delete_save()
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/final_screen.tscn")
