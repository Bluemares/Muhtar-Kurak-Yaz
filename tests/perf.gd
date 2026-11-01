extends Node
## Run via tools/run_tests.py perf --visual; never against player saves.
var game
var results: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		print("TEST_SKIP perf: requires rendering")
		get_tree().quit()
		return
	seed(31)
	_run()

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func _sample(label: String, seconds := 8.0) -> void:
	var frames: Array[float] = []
	var cpu := 0.0
	var draws := 0.0
	var slow := 0
	var start := Time.get_ticks_usec()
	var last := start
	while Time.get_ticks_usec() - start < seconds * 1000000.0:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		frames.append(ms)
		cpu += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		if ms > 50.0:
			slow += 1
	var elapsed := (last - start) / 1000000.0
	frames.sort()
	var n := frames.size()
	var result := {"scenario": label, "frames": n, "seconds": elapsed,
		"fps": n / elapsed, "p95_ms": frames[int((n - 1) * 0.95)],
		"p99_ms": frames[int((n - 1) * 0.99)], "max_ms": frames[-1],
		"frames_over_50ms": slow, "cpu_ms": cpu / n, "draw_calls": draws / n,
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"window": str(get_window().size), "paused": get_tree().paused,
		"workers": GameState.workers.size(), "buildings": GameState.buildings.size()}
	results.append(result)
	var output := "res://tests/perf.json" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("perf.json")
	FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	print("PERF ", JSON.stringify(result))

func _find_button(n: Node, text: String) -> Button:
	if n is Button and n.text == text and n.is_visible_in_tree():
		return n
	for c in n.get_children():
		var found := _find_button(c, text)
		if found:
			return found
	return null

func _run() -> void:
	await get_tree().process_frame
	print("PERF_DEVICE ", RenderingServer.get_video_adapter_name(), " | ", OS.get_processor_name())
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	Settings.fullscreen = false
	Settings.resolution_index = 0
	Settings.apply_display()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await _wait(4.0)
	await _sample("menu_720p")
	menu.queue_free()
	await get_tree().process_frame
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _wait(3.0)
	game.skip_tutorial()
	await _wait(0.3)
	var start := _find_button(get_tree().root, tr("BTN_START_MONTH"))
	assert(start != null, "Gameplay measurement must start the month")
	start.pressed.emit()
	await _wait(3.0)
	assert(GameState.round_active and not get_tree().paused)
	await _sample("village_720p")
	Settings.resolution_index = 2
	Settings.apply_display()
	await _wait(3.0)
	await _sample("village_1080p")
	for spec in MenuBackdrop.EXTRA:
		if game.village.can_place(spec[0], spec[1]):
			game.village.spawn_building(spec[0], spec[1])
	for i in 12:
		game.village.spawn_worker(GameState.find_building("cop31").center() + Vector2(i * 8, 70)).idle()
	await _wait(3.0)
	await _sample("expanded_village_1080p")
	GameState.flag_once("ilk_yangin_goruldu")
	game.ignite(GameState.find_building("house"))
	await _sample("fire_dispatch_1080p", 6.0)
	if not game._arrived:
		game.skip_cinematic()
	await _wait(2.0)
	assert(game.find_child("FireMinigame", true, false) != null, "Fire minigame must actually be open")
	await _sample("fire_minigame_1080p", 5.0)
	print("TEST_OK perf")
	get_tree().quit()
