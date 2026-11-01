extends Node
## Haziran "nehir kenarına kuyu" yan görevi: COP31 seviye 1 alanında yapılabilir mi?
## godot --path . res://tests/river_quest.tscn  Çıktı: tests/shots/river_quest.png


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP river_quest: requires rendering")
		set_process(false)
		get_tree().quit()
		return
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _run() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _wait(3.0)
	game.skip_tutorial()
	await _wait(0.3)
	var v = game.village
	var spots: Array[Vector2i] = []
	var usable: Array[Vector2i] = []
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x, y)
			if v.can_place("well", c) and Terrain.river_distance(c) <= Bal.RIVER_WELL_DIST:
				spots.append(c)
				if v.road_adjacent("well", c):
					usable.append(c)
	printerr("COP seviye=%d uygun hücre=%s yola bitişik=%s" % [v.cop_level(), str(spots), str(usable)])
	printerr("görev önce=%s" % str(game._side_done("river_well")))
	if usable.is_empty():
		push_error("River quest: no road-adjacent well location")
		get_tree().quit(1)
		return
	var b = v.spawn_building("well", usable[0])
	b.state = "normal"
	assert(b.near_river and game._side_done("river_well"), "River well did not complete quest")
	printerr("kuyu=%s near_river=%s bonus=%.2f görev sonra=%s" % [str(b.cell), str(b.near_river), b.river_bonus(), str(game._side_done("river_well"))])
	game.hud.hide_dialog()
	game.camera.position = Vector2(b.cell) * Bal.CELL
	game.camera.zoom = Vector2.ONE * 1.6
	await _wait(1.2)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/shots/river_quest.png"))
	print("TEST_OK river_quest")
	get_tree().quit()
