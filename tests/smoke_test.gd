extends Node
## Headless duman testi: tüm oyunu hızlandırılmış oynatır, ana akışların çökmeden çalıştığını doğrular.
## Çalıştır: godot --headless --path . res://tests/smoke_test.tscn

var game


func _ready() -> void:
	Engine.time_scale = 8.0
	game = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	get_tree().current_scene = game  # final sahne geçişi testi silmesin
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _press(key: String) -> bool:
	var b := _find_button(get_tree().root, tr(key))
	if b:
		b.pressed.emit()
		return true
	push_error("TEST: buton yok: " + key)
	return false


func _find_button(n: Node, text: String) -> Button:
	if n is Button and n.text == text and n.is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r:
			return r
	return null


func _dismiss() -> void:
	if not is_instance_valid(game):
		return
	var b := _find_button(get_tree().root, tr("BTN_CONTINUE"))
	if b:
		printerr("TEST | diyalog kapatildi")
		b.pressed.emit()
		await _wait(0.2)
	if not is_instance_valid(game):
		return
	if game.events.pending != "":
		printerr("TEST | karar: ", game.events.pending)
		_press("EVC_%s_A" % game.events.pending.to_upper())
		await _wait(0.2)
	if not game.policy_offer.is_empty():
		printerr("TEST | politika: ", game.policy_offer[0])
		_press("POL_PICK")
		await _wait(0.2)
	if game.fire_active and not game._arrived:
		game.skip_cinematic()
	var mg := get_tree().root.find_child("FireMinigame", true, false)
	if mg:
		mg.time_left = 0.05
		await _wait(2.5)


func _log(msg: String) -> void:
	printerr("TEST %ds | %s | para=%d su=%.0f erzak=%.0f refah=%.0f isci=%d ay=%d kalan=%.0f" % [Time.get_ticks_msec() / 1000, msg, GameState.money,
		GameState.water, GameState.food, GameState.welfare, GameState.workers.size(), GameState.round_index, GameState.round_time_left])


func _run() -> void:
	await _wait(4.0)
	_log("intro bitti")
	# öğretici adımları: COP31 seçimi
	_press("BTN_CONTINUE")  # INTRO_1
	_press("BTN_CONTINUE")  # INTRO_2 -> öğretici
	game.village.select(GameState.find_building("cop31"))
	_press("BTN_CONTINUE")  # TUT_CAMERA
	_press("BTN_CONTINUE")  # TUT_FIELD
	_press("BTN_CONTINUE")  # TUT_WELL
	_press("BTN_CONTINUE")  # TUT_WATER
	_press("BTN_CONTINUE")  # TUT_ROAD
	game.request_crop(GameState.find_building("field"), "wheat")  # TUT_CROP
	await _wait(0.2)
	var well = GameState.find_building("well")
	game.request_move(well)
	game.village.ghost_cell = Vector2i(15, 11)
	game.village._try_place()
	_log("taşıma: kuyu %s durum %s" % [well.cell, well.state])
	game.request_build("field")
	game.village.ghost_cell = Vector2i(17, 8)
	game.village._try_place()
	_log("tarla kuruldu, tarla sayısı %d" % GameState.count("field"))
	_press("BTN_CONTINUE")  # TUT_DONE
	await _wait(0.2)
	_press("BTN_START_MONTH")
	await _wait(12.0)
	await _dismiss()
	_log("haziran 25sn")
	game.request_upgrade(GameState.find_building("well"))
	game.request_road_upgrade()
	_log("kuyu sv %d yol sv %d" % [GameState.find_building("well").level, GameState.road_level])
	# yangın akışı
	var f = GameState.buildings.filter(func(b): return b.type == "field" and b.state == "normal")[0]
	game.ignite(f)
	await _wait(0.2)
	_press("BTN_CONTINUE")  # FIRST_FIRE
	await _wait(1.0)
	game.skip_cinematic()
	await _wait(0.5)
	_log("minigame açık? yanan=%d" % GameState.buildings.filter(func(b): return b.state == "burning").size())
	for i in 10:
		await _wait(2.0)
		printerr("TEST | t=%d paused=%s fire=%s mg=%s" % [i, get_tree().paused, game.fire_active, get_tree().root.find_child("FireMinigame", true, false) != null])
	_log("minigame sonrası harap=%d fire_active=%s paused=%s" % [GameState.buildings.filter(func(b): return b.state == "ruined").size(), game.fire_active, get_tree().paused])
	for b in GameState.buildings:
		if b.state == "ruined":
			game.request_repair(b)
	for month in 3:
		await _dismiss()
		GameState.round_time_left = 0.5
		await _wait(1.5)
		await _dismiss()
		if not is_instance_valid(game):
			break
		_log("tur sonu %d" % month)
		if month < 2:
			_press("BTN_NEXT_MONTH")
			await _wait(0.3)
			_log("politika teklifi: %s" % str(game.policy_offer))
			_press("POL_PICK")
			await _wait(0.3)
			_press("BTN_START_MONTH")
			await _wait(20.0 if month == 0 else 8.0)
			_log("ay ortası")
			if not is_instance_valid(game):
				printerr("TEST | oyun bitti (kayip yolu)")
				break
			for b in GameState.buildings:
				if is_instance_valid(b) and b.type == "field" and b.pest:
					game.request_spray(b)
		else:
			_press("BTN_FINAL")
	await _wait(1.0)
	printerr("TEST | final: ", GameState.final_result)
	printerr("TEST | sahne: ", get_tree().current_scene.scene_file_path if get_tree().current_scene else "yok")
	printerr("TEST | BITTI")
	print("TEST_OK smoke_test")
	get_tree().quit()
