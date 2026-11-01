extends Node
## 3D görünüm ekran görüntüleri (pencereli): godot --path . res://tests/shots3d.tscn

const OUT := "res://tests/shots/"


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP shots3d: requires rendering")
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
	Settings.set_language("tr")
	var game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _wait(3.5)
	var st = GameState.find_building("fire_station")
	for tgt in GameState.buildings:
		if tgt.type in ["field", "house"]:
			var pts: Array = game.village.road_path(st.center(), tgt)
			var on_road := 0
			for q in pts:
				if game.village.is_road(game.village.cell_of(q)):
					on_road += 1
			print("TRUCK to %s %s: %d nokta, %d yolda" % [tgt.type, tgt.cell, pts.size(), on_road])
	game.skip_tutorial()
	await _wait(0.3)
	for b in get_tree().root.find_children("*", "Button", true, false):
		if b.text == tr("BTN_START_MONTH"):
			b.pressed.emit()
	await _wait(1.0)
	game.hud.hide_dialog()
	await _shot("3d_01_village")
	var err := 0.0
	for b in GameState.buildings:
		var sp: Vector2 = game.camera.world_to_screen(b.center())
		err = maxf(err, game.camera.screen_to_world(sp).distance_to(b.center()))
	print("PICK roundtrip max error px: ", err)
	game.camera.yaw += 90.0
	await _wait(0.2)
	await _shot("3d_02_rotated")
	game.camera.yaw -= 90.0
	game.camera.zoom = Vector2.ONE * 2.2
	game.camera.pitch = 40.0
	await _wait(0.2)
	await _shot("3d_03_close")
	game.camera.zoom = Vector2.ONE * 0.5
	game.camera.pitch = 60.0
	await _wait(0.2)
	await _shot("3d_04_far")
	game.camera.zoom = Vector2.ONE * 0.45
	game.camera.pitch = 28.0
	game.camera.yaw = 0.0
	await _wait(0.3)
	await _shot("3d_04b_taurus")
	game.camera.yaw = 180.0
	await _wait(0.3)
	await _shot("3d_04c_sea")
	GameState.round_index = 2
	game.camera.yaw = -32.0
	game.camera.pitch = 45.0
	game.camera.zoom = Vector2.ONE * 0.8
	await _wait(0.4)
	await _shot("3d_04d_august")
	GameState.round_index = 0
	game.camera.zoom = Vector2.ONE
	game.camera.pitch = 52.0
	game.village.begin_build("house")
	game.village.ghost_cell = Vector2i(17, 8)
	await _wait(0.2)
	await _shot("3d_05_ghost")
	game.village.cancel_mode()
	# tüm bina türleri ve durumlar
	for e in [["greenhouse", Vector2i(19, 8)], ["water_tower", Vector2i(12, 14)], ["grove", Vector2i(13, 14)], ["grove", Vector2i(13, 15)], ["house", Vector2i(9, 7)], ["field", Vector2i(19, 13)]]:
		if game.village.can_place(e[0], e[1]):
			game.village.spawn_building(e[0], e[1])
	var f2 = GameState.buildings[-1]
	f2.level = 2
	f2.harvest_progress = f2.harvest_time() * 0.9
	var cop = GameState.find_building("cop31")
	cop.level = 3
	game.village.select(cop)
	await _wait(0.3)
	game.camera.position = cop.center() + Vector2(64, 64)
	game.camera.zoom = Vector2.ONE * 1.8
	game.camera.pitch = 42.0
	await _wait(0.3)
	await _shot("3d_06_buildings")
	game.camera.yaw += 150.0
	await _wait(0.3)
	await _shot("3d_07_buildings_back")
	game.camera.yaw -= 150.0
	var houses = GameState.buildings.filter(func(b): return b.type == "house")
	houses[0].state = "burning"
	houses[1].state = "ruined"
	game.village.begin_build("greenhouse")
	game.village.ghost_cell = Vector2i(9, 13)
	game.camera.position = Vector2(11, 11) * 64
	await _wait(0.3)
	await _shot("3d_08_states_ghost")
	game.village.cancel_mode()
	# köylüler, hayvanlar, itfaiye aracı
	game.truck.visible = true
	game.truck.siren = true
	game.truck.position = Vector2(19.5, 10.5) * 64
	var tw: Tween = game.truck.create_tween()
	tw.tween_property(game.truck, "position", Vector2(16.5, 10.5) * 64, 3.0)
	game.camera.position = Vector2(18.2, 10.5) * 64
	game.camera.zoom = Vector2.ONE * 2.6
	game.camera.pitch = 38.0
	game.camera.yaw = -20.0
	await _wait(0.8)
	await _shot("3d_09_actors")
	game.camera.position = GameState.find_building("cop31").center() + Vector2(0, 90)
	game.camera.zoom = Vector2.ONE * 3.2
	await _wait(0.5)
	await _shot("3d_10_villagers")
	# efektler: yangın + olgun ürün balonu
	var field = GameState.find_building("field")
	field.crop_ready = true
	field.pest = true
	var burning = GameState.buildings.filter(func(b): return b.state == "burning")
	game.camera.position = Vector2(14.5, 10.5) * 64
	game.camera.zoom = Vector2.ONE * 1.5
	game.camera.pitch = 45.0
	game.camera.yaw = -30.0
	await _wait(1.5)
	await _shot("3d_11_fire_bubble")
	print("burning: ", burning.size())
	GameState.round_time_left = 204.0  # gece
	await _wait(0.5)
	await _shot("3d_12_night")
	GameState.round_time_left = 250.0
	GameState.rain_left = 10.0
	await _wait(0.5)
	await _shot("3d_13_rain")
	GameState.rain_left = 0.0
	game.hud._shop.open()
	await _wait(1.0)
	await _shot("3d_14_shop")
	game.hud._shop._show_tab(1)
	await _wait(0.5)
	await _shot("3d_15_shop_water")
	game.hud._shop.close()
	# yeni: küçük bilgi kartı, ürün seçici, yolsuz hayalet, arazi temizleme, yol modu
	var fl = GameState.find_building("field")
	fl.pest = false
	fl.crop_ready = false
	game.camera.position = fl.center()
	game.camera.zoom = Vector2.ONE * 1.6
	game.camera.pitch = 48.0
	game.camera.yaw = -30.0
	game.village.select(fl)
	await _wait(1.5)
	await _shot("3d_16_select_card")
	game.hud._crop_pick = true
	game.hud.show_selection(fl)
	await _wait(1.5)
	await _shot("3d_17_crop_picker")
	game.hud._crop_pick = false
	game.request_crop(fl, "wheat")
	fl.harvest_progress = fl.harvest_time() * 0.9
	game.village.clear_selection()
	game.village.begin_build("house")
	game.village.ghost_cell = Vector2i(9, 14)
	game.camera.position = Vector2(12, 12) * 64
	await _wait(0.5)
	await _shot("3d_18_ghost_noroad")
	game.village.cancel_mode()
	GameState.find_building("cop31").level = 2
	game.request_clear()
	var rock := Vector2i(-1, -1)
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			if rock.x < 0 and game.village.can_clear(Vector2i(x, y)):
				rock = Vector2i(x, y)
	game.village.ghost_cell = rock
	game.camera.position = (Vector2(rock) + Vector2(0.5, 0.5)) * 64
	await _wait(0.5)
	await _shot("3d_19_clear")
	game.village.clear_cell(rock)
	game.village.cancel_mode()
	game.request_road_paint()
	game.village.ghost_cell = Vector2i(20, 9)
	await _wait(0.5)
	await _shot("3d_20_road_mode")
	game.village.cancel_mode()
	GameState.round_index = 2
	GameState.water = 0.0
	game.camera.position = Vector2(15, 11) * 64
	game.camera.zoom = Vector2.ONE * 1.1
	game.camera.pitch = 52.0
	game.hud.set_risk_map(true)
	await _wait(0.6)
	await _shot("3d_21_risk_map")
	game.hud.set_risk_map(false)
	GameState.round_index = 0
	HowToPlay.open(game.hud._modal_layer)
	await _wait(0.8)
	await _shot("3d_22_howto")
	for m in game.hud._modal_layer.get_children():
		m.queue_free()
	# sokak lambası gece
	for c in [Vector2i(13, 11), Vector2i(17, 11), Vector2i(10, 9)]:
		if game.village.can_place("lamp", c):
			game.village.spawn_building("lamp", c)
	GameState.round_time_left = 204.0
	game.camera.position = Vector2(14, 11) * 64
	game.camera.zoom = Vector2.ONE * 1.4
	game.camera.pitch = 46.0
	await _wait(0.8)
	await _shot("3d_23_lamp_night")
	GameState.round_time_left = 250.0
	# dükkan ikinci açılış aynı boyutta mı
	game.hud._shop.open()
	await _wait(0.4)
	var s1: Vector2 = game.hud._shop.size
	game.hud._shop._show_tab(3)
	await _wait(0.2)
	game.hud._shop.close()
	game.hud._shop.open()
	await _wait(0.6)
	print("SHOP size1=", s1, " size2=", game.hud._shop.size, " pos=", game.hud._shop.position)
	await _shot("3d_24_shop_reopen")
	game.hud._shop.close()
	GameState.food = 35.0
	game.hud.open_market()
	await _wait(0.6)
	await _shot("3d_25_market")
	for m in game.hud._modal_layer.get_children():
		m.queue_free()
	GameState.round_index = 2
	GameState.water = 10.0
	game.camera.position = Vector2(17, 12) * 64
	game.hud.set_map_mode(2)
	await _wait(1.2)
	await _shot("3d_26_moisture")
	game.hud.set_map_mode(0)
	GameState.round_index = 0
	print("TEST_OK shots3d")
	get_tree().quit()
