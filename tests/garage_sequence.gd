extends Node

func _ready() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(1.0).timeout
	game.skip_tutorial()
	await get_tree().create_timer(0.4).timeout
	for button in get_tree().root.find_children("*","Button",true,false):
		if button.text == tr("BTN_START_MONTH"):
			button.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	game.hud.hide_dialog()
	var station = GameState.find_building("fire_station")
	game.camera.position = station.center()
	game.camera.yaw = -15.0
	game.camera.pitch = 20.0
	game.camera.zoom = Vector2.ONE * 3.0
	await get_tree().create_timer(0.2).timeout
	await shot("garage_closed")
	var start: Vector2 = station.center()
	GameState.flag_once("ilk_yangin_goruldu")
	game.ignite(GameState.find_building("house"))
	await get_tree().create_timer(0.72, true).timeout
	assert(game.truck.position.distance_to(start) < 0.01, "Truck must wait until the door opens")
	assert(station.get_meta("garage_open",false))
	var world = get_tree().get_first_node_in_group("world3d")
	assert(world._b3[station].model.get_node("GarageDoor").scale.y < 0.05)
	await shot("garage_open")
	await get_tree().create_timer(0.55, true).timeout
	assert(game.truck.position.distance_to(start) > 0.01, "Truck must leave through the open door")
	await shot("garage_departure")
	await get_tree().create_timer(1.8, true).timeout
	assert(game.camera._fire_target.distance_to(View.to3(start,0.65)) > 1.0, "Paused cinematic camera is stuck at the door")
	assert(game.camera._fire_pullback > 0.0, "Camera does not pull back after departure")
	await shot("garage_follow")
	game.skip_cinematic()
	await get_tree().create_timer(0.15,true).timeout
	assert(not station.get_meta("garage_open",true))
	print("GARAGE_SEQUENCE_OK: opens before departure, truck exits, door closes; skip is safe")
	get_tree().paused = false
	for player in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	print("TEST_OK garage_sequence")
	get_tree().quit()

func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/shots/"+name+".png")
