extends Node
## Görsel kontrol: Ağustos durumu (böcek, harap, yanan bina, taş yol) ekran görüntüsü.
## godot --path . res://tests/qa_late.tscn  → tests/shots/11_august.png

var game


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP qa_late: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _press(key: String) -> void:
	var b := _find(get_tree().root, tr(key))
	if b:
		b.pressed.emit()


func _find(n: Node, text: String) -> Button:
	if n is Button and n.text == text and n.is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find(c, text)
		if r:
			return r
	return null


func _run() -> void:
	while not GameState.round_active and _find(get_tree().root, tr("BTN_START_MONTH")) == null:
		_press("BTN_SKIP_TUTORIAL")
		await _wait(0.3)
	_press("BTN_START_MONTH")
	await _wait(1.0)
	GameState.round_index = 2
	GameState.road_level = 2
	GameState.water = 10.0
	GameState.stats.prevention = 340
	GameState.stats.damage = 150
	var v = game.village
	var f2 = v.spawn_building("field", Vector2i(18, 7))
	f2.pest = true
	f2.drip = true
	var h = v.spawn_building("house", Vector2i(12, 14))
	v.spawn_building("greenhouse", Vector2i(19, 14))
	v.spawn_building("water_tower", Vector2i(13, 7))
	v.spawn_building("grove", Vector2i(20, 12))
	h.state = "ruined"
	GameState.find_building("field").state = "burning"
	await _wait(3.0)
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tests/shots/11_august.png"))
	GameState.money = 900
	for x in range(17, 21):
		game.village.paint_road(Vector2i(x, 11))
	game.village.paint_road(Vector2i(19, 9))
	f2.crop_ready = true
	GameState.fly.emit(f2.center(), "money", 5)
	GameState.fly.emit(f2.center(), "food", 3)
	await _wait(0.35)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/23_harvest.png"))
	f2.crop_ready = false
	game.village.select(f2)
	await _wait(0.8)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/22_actions.png"))
	game.village.clear_selection()
	game.hud._shop.open()
	await _wait(0.6)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/20_shop.png"))
	game.hud._shop._show_tab(1)
	await _wait(0.4)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/21_shop_water.png"))
	game.hud._shop.close()
	game.request_road_paint()
	game.village.ghost_cell = Vector2i(20, 9)
	await _wait(1.2)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/19_roads.png"))
	game.village.cancel_mode()
	GameState.round_time_left = Bal.ROUND_SECONDS - (0.85 - Bal.DAY_START_PHASE) * Bal.DAY_SECONDS
	await _wait(1.0)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/13_night.png"))
	GameState.round_time_left = Bal.ROUND_SECONDS - (0.66 - Bal.DAY_START_PHASE) * Bal.DAY_SECONDS
	await _wait(1.0)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/14_dusk.png"))
	GameState.round_time_left = Bal.ROUND_SECONDS - 10.0
	GameState.rain_left = 20.0
	await _wait(1.2)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/16_rain.png"))
	GameState.rain_left = 0.0
	game.events._open("stubble")
	await _wait(0.8)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/15_decision.png"))
	game.events.decide(1)
	await _wait(0.3)
	GameState.round_index = 0
	game._offer_policies()
	await _wait(0.8)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/17_policy.png"))
	_press("POL_PICK")
	await _wait(0.5)
	_press("BTN_START_MONTH")
	await _wait(0.3)
	GameState.find_building("cop31").level = 3
	game._expand_village()
	GameState.round_index = 0
	await _wait(1.5)
	game.camera.zoom = Vector2.ONE * game.camera.base_zoom * 0.62
	game.camera.position = game.village.world_size() * 0.5
	await _wait(1.0)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/12_valley.png"))
	print("TEST_OK qa_late")
	get_tree().quit()
