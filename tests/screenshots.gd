extends Node
## Pencereli çalıştır, ekran görüntülerini tests/shots/ altına kaydeder.
## godot --path . res://tests/screenshots.tscn

const OUT := "res://tests/shots/"


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP screenshots: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _run() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await _wait(2.0)
	await _shot("01_menu")
	menu.queue_free()
	var game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _wait(3.5)
	await _shot("02_intro_dialog")
	game.skip_tutorial()
	await _wait(0.3)
	await _shot("03_mission_card")
	for b in get_tree().root.find_children("*", "Button", true, false):
		if b.text == tr("BTN_START_MONTH"):
			b.pressed.emit()
	Engine.time_scale = 4.0
	await _wait(5.0)
	game.village.select(GameState.find_building("field"))
	game.village.hovered = GameState.find_building("well")
	await _shot("04_playing_selected")
	game.village.begin_build("house")
	game.village.ghost_cell = Vector2i(10, 6)
	await _wait(0.2)
	await _shot("05_build_ghost")
	game.village.cancel_mode()
	GameState.flags["ilk_yangin_goruldu"] = true
	game.ignite(GameState.find_building("field"))
	await _wait(0.9)
	await _shot("06_cinematic")
	game.skip_cinematic()
	await _wait(1.0)
	await _shot("07_minigame")
	await _wait(2.5)
	await _shot("07b_minigame_late")
	var mg := get_tree().root.find_child("FireMinigame", true, false)
	if mg:
		mg.time_left = 0.05
	await _wait(2.5)
	game.hud.show_round_summary({"round": 2, "produced": 120.0, "eaten": 40.0, "sold": 80.0, "earned": 120, "spent": 200, "fires": 1, "burned": 1, "mission_ok": true, "penalty": 0.0}, func(): pass)
	await _wait(0.8)
	await _shot("07c_summary")
	GameState.final_result = {"lost": false, "good": true, "won": true, "welfare": 84.0, "burned": 1, "produced": 420.0, "prevention": 340, "damage": 150, "missions": 3, "side": 7, "policies": ["solar_pump", "fire_watch"]}
	Progress.finalize(GameState.final_result)
	get_tree().paused = false
	for c in get_children():
		c.queue_free()
	var fs = load("res://scenes/final_screen.tscn").instantiate()
	add_child(fs)
	await _wait(1.5)
	await _shot("08_final_good")
	fs.queue_free()
	GameState.final_result = {"lost": true, "good": false, "won": false, "welfare": 0.0, "burned": 4, "produced": 120.0, "prevention": 40, "damage": 420, "missions": 0, "side": 1}
	Progress.finalize(GameState.final_result)
	add_child(load("res://scenes/final_screen.tscn").instantiate())
	await _wait(1.5)
	await _shot("09_final_lost")
	var menu2 = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu2)
	await _wait(0.5)
	menu2._credits()
	await _wait(0.6)
	await _shot("10_credits")
	for c in menu2.get_children():
		if c is ColorRect:
			c.queue_free()
	menu2._achievements()
	await _wait(0.6)
	await _shot("18_achievements")
	print("TEST_OK screenshots")
	get_tree().quit()
