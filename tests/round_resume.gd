extends Node

var game

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _reload() -> void:
	GameState.save_game()
	var saved := GameState.read_save()
	game.queue_free()
	await get_tree().process_frame
	GameState.pending_load = saved
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	game.set_process(false)

func _button(key: String) -> Button:
	for b in game.find_children("*", "Button", true, false):
		if b.text == tr(key): return b
	return null

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(3.0).timeout
	game.skip_tutorial()
	_button("BTN_START_MONTH").pressed.emit()
	game.set_process(false)
	GameState.round_time_left = 0.0
	game._end_round()
	var money: int = GameState.money
	var missions: int = GameState.stats.missions
	await _reload()
	assert(GameState.round_time_left == 0.0 and _button("BTN_NEXT_MONTH") != null,
		"Continuing at the month report must not restart the finished month")
	assert(GameState.money == money and GameState.stats.missions == missions,
		"Restoring a report must not grant rewards twice")
	_button("BTN_NEXT_MONTH").pressed.emit()
	var offer: Array = game.policy_offer.duplicate()
	assert(not offer.is_empty())
	await _reload()
	assert(game.policy_offer == offer and get_tree().paused,
		"An unanswered policy offer must survive continuing")
	game.choose_policy(0)
	assert(GameState.round_index == 1 and _button("BTN_START_MONTH") != null)
	_button("BTN_START_MONTH").pressed.emit()
	GameState.round_index = 2
	GameState.round_time_left = 0.0
	game._end_round()
	await _reload()
	assert(_button("BTN_FINAL") != null and GameState.round_index == 2,
		"The August report must resume at the final-screen button")
	print("TEST_OK round_resume")
	get_tree().quit()
