extends Node
## Kaydet/yükle testi: durumu değiştir → kaydet → yeni oyun sahnesine yükle → karşılaştır.
## godot --headless --path . res://tests/save_test.tscn

var game


func _ready() -> void:
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


func _check(name: String, ok: bool) -> void:
	printerr("SAVE %s %s" % ["OK  " if ok else "FAIL", name])


func _run() -> void:
	GameState.delete_save()
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _wait(3.5)
	_press("BTN_SKIP_TUTORIAL")
	await _wait(0.3)
	_press("BTN_START_MONTH")
	await _wait(0.5)
	GameState.round_index = 1
	GameState.round_time_left = 77.0
	game.village.paint_road(Vector2i(13, 7))
	GameState.money = 777
	GameState.road_level = 2
	GameState.stats.prevention = 123
	var f = game.village.spawn_building("field", Vector2i(18, 7))
	f.drip = true
	f.pest = true
	f.level = 2
	var count := GameState.buildings.size()
	var workers := GameState.workers.size()
	GameState.save_game()
	_check("dosya var", GameState.has_save())
	var data := GameState.read_save()
	game.queue_free()
	await _wait(0.3)
	GameState.pending_load = data
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _wait(0.5)
	_check("para", GameState.money == 777)
	_check("ay", GameState.round_index == 1)
	_check("kalan süre", absf(GameState.round_time_left - 77.0) < 0.5)
	_check("yol", GameState.road_level == 2)
	_check("önlem stat", GameState.stats.prevention == 123)
	_check("bina sayısı", GameState.buildings.size() == count)
	_check("işçi sayısı", GameState.workers.size() == workers)
	var f2 = game.village.building_at(Vector2i(18, 7))
	_check("tarla geri geldi", f2 != null and f2.type == "field" and f2.drip and f2.pest and f2.level == 2)
	_check("döşenen yol", GameState.extra_roads.has(Vector2i(13, 7)))
	_check("görev kartı açık", _find(get_tree().root, tr("BTN_START_MONTH")) != null)
	game._finish_game(false)
	_check("final sonrası kayıt silindi", not GameState.has_save())
	printerr("SAVE BITTI")
	print("TEST_OK save_test")
	get_tree().quit()
