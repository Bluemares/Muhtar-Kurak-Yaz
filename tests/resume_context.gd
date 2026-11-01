extends Node

var game

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _start() -> void:
	for b in game.find_children("*", "Button", true, false):
		if b.text == tr("BTN_START_MONTH"):
			b.pressed.emit()
	game.set_process(false)

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(3.0).timeout
	game.skip_tutorial()
	_start()
	GameState.round_index = 1
	GameState.round_time_left = 170.0
	GameState.round_stats.fires = 1
	game.round_elapsed = 100.0
	game.round_fire_count = 1
	game._full_tank_secs = 18.0
	GameState.heat_left = 21.0
	GameState.rain_left = 12.0
	game.events._used = ["volunteers"]
	game.events._timer = 34.0
	game.events._heat_in = 8.0
	GameState.save_game()
	var saved := GameState.read_save()
	game.queue_free()
	await get_tree().process_frame
	GameState.pending_load = saved
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	_start()
	var checks := {"heat": is_equal_approx(GameState.heat_left, 21.0),
		"rain": is_equal_approx(GameState.rain_left, 12.0),
		"used_decisions": "volunteers" in game.events._used,
		"event_timer": is_equal_approx(game.events._timer, 34.0),
		"heat_warning": is_equal_approx(game.events._heat_in, 8.0),
		"elapsed": is_equal_approx(game.round_elapsed, 100.0),
		"fire_count": game.round_fire_count == 1,
		"tank_task": is_equal_approx(game._full_tank_secs, 18.0)}
	print("RESUME_CONTEXT ", checks)
	for key in checks:
		assert(checks[key], "Save/resume resets " + key)
	game.events._open("festival")
	GameState.save_game()
	saved = GameState.read_save()
	game.queue_free()
	await get_tree().process_frame
	GameState.pending_load = saved
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	_start()
	assert(game.events.pending == "festival" and game._modal_open and get_tree().paused,
		"An unanswered decision must reopen after continuing")
	print("TEST_OK resume_context")
	get_tree().quit()
