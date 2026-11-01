extends Node

func _ready() -> void:
	Settings.fullscreen = "--fullscreen-test" in OS.get_cmdline_user_args()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		await get_tree().process_frame
		assert(Startup.display_ready)
		assert(not get_window().transparent)
		assert(not get_window().transparent_bg)
		assert(not get_window().unfocusable)
		assert(not get_window().borderless)
		if Settings.fullscreen:
			assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			assert(get_window().size == Settings.RESOLUTIONS[Settings.resolution_index])
		await RenderingServer.frame_post_draw
		assert(get_viewport().get_texture().get_image().save_png("res://tests/startup_menu.png") == OK)
	assert(not ProjectSettings.get_setting("application/boot_splash/show_image"))
	for child in menu.get_children():
		assert(not child is CanvasLayer, "No opaque startup fade should cover the menu")
	print("TEST_OK startup")
	get_tree().quit()
