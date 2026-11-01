extends Node

var game

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(31)
	_run()

func _shot(name_: String) -> void:
	await get_tree().create_timer(0.5, true).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var path := "res://tests/" + name_ + ".png" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join(name_ + ".png")
		var result := get_viewport().get_texture().get_image().save_png(path)
		assert(result == OK)

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(3.0).timeout
	game.set_process(false)
	game.village.set_process(false)
	game.hud.hide_dialog()
	for w in GameState.workers:
		w.set_process(false)
	var field = GameState.find_building("field")
	GameState.workers[0].assign(field)
	field.drip = true
	GameState.flags.water_saving = true
	GameState.flags.pol_community_kitchen = true
	GameState.food = 50.0
	GameState.tick(1.0)
	var avoided: float = Bal.FIELD_WATER * (1 + GameState.drought() * Bal.DROUGHT_WATER_FACTOR) * field.crop_water() * (1 - Bal.DRIP_WATER_MULT)
	avoided += GameState.workers.size() * Bal.WORKER_WATER * (1 + GameState.drought() * Bal.DROUGHT_WATER_FACTOR) * 0.3
	assert(is_equal_approx(GameState.stats.water_demand_avoided, avoided))
	assert(is_equal_approx(GameState.stats.food_saved, 0.08))
	GameState.food = 57.6
	GameState.round_stats.produced = 115.2
	assert(is_equal_approx(GameState.food_days(), 2.0), "Kitchen policy must affect food coverage")
	var snap := ClimateReport.snapshot(GameState.round_stats)
	assert(is_equal_approx(snap.stock_days, 2.0))
	assert(is_equal_approx(snap.produced_days, 4.0))
	assert(snap.measures.any(func(m): return m[0] == "REPORT_DRIP"))
	# Old v3 saves omit the new counters: defaults must remain valid.
	GameState.save_game()
	var saved := GameState.read_save()
	GameState.reset()
	GameState.apply_save(saved)
	assert(is_equal_approx(GameState.stats.water_demand_avoided, avoided))
	saved.stats.erase("water_demand_avoided")
	saved.stats.erase("food_saved")
	saved.round_stats.erase("water_demand_avoided")
	saved.round_stats.erase("food_saved")
	GameState.reset()
	GameState.apply_save(saved)
	assert(GameState.stats.water_demand_avoided == 0.0)
	assert(GameState.round_stats.food_saved == 0.0)
	# Reset clears registry references, not nodes: restore those for the UI fixture.
	GameState.buildings = game.village.buildings_layer.get_children()
	GameState.workers = game.village.workers_layer.get_children().filter(func(n): return n is Worker)
	GameState.flags.erase("volunteers")
	GameState.money = 0
	game.events.pending = "volunteers"
	game.events.decide(0)
	assert(not GameState.flags.get("volunteers", false))
	assert(game.events.lesson_key("volunteers", 0) == "LEARN_NO_FUNDS")
	GameState.money = 100
	game.events.pending = "water_saving"
	game.events.decide(0)
	assert(GameState.flags.water_saving and GameState.money == 50)
	assert(not get_tree().paused, "Learning notes must not pause gameplay")
	for locale in ["tr", "en"]:
		TranslationServer.set_locale(locale)
		for id in game.events.DECISIONS:
			for choice in 2:
				var key: String = game.events.lesson_key(id, choice)
				assert(tr(key) != key)
	TranslationServer.set_locale("tr")
	game.hud.show_learning("LEARN_WATER_SAVING_A")
	await _shot("climate_decision")
	game.hud._learning_note.queue_free()
	for id in Bal.POLICIES:
		GameState.flags["pol_" + id] = true
	var summary := GameState.end_round(true)
	assert(GameState.round_stats.water_demand_avoided == 0.0)
	summary.climate_report = snap
	game.hud.show_round_summary(summary, func(): pass)
	await _shot("climate_month")
	# Final report must survive the decorative village resetting GameState.
	GameState.stats.produced = 1200.0
	var report := ClimateReport.snapshot(GameState.stats)
	report.stock = 57.6
	report.stock_days = 2.0
	GameState.final_result = {"lost": false, "won": true, "good": true, "welfare": 92,
		"burned": 1, "produced": 1200, "prevention": 500, "damage": 75, "missions": 2,
		"score": 2500, "stars": 2, "policies": GameState.policies(), "climate_report": report}
	game.queue_free()
	await get_tree().process_frame
	var final = load("res://scenes/final_screen.tscn").instantiate()
	add_child(final)
	await _shot("climate_final")
	assert(GameState.final_result.climate_report.stock_days == 2.0)
	var scroll: ScrollContainer = final.find_children("*", "ScrollContainer", true, false)[0]
	scroll.scroll_vertical = 10000
	await _shot("climate_final_bottom")
	assert(scroll.get_global_rect().end.y < get_viewport().get_visible_rect().size.y)
	print("TEST_OK climate_report")
	get_tree().quit()
