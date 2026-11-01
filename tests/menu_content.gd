extends Node

func _ready() -> void:
	TranslationServer.set_locale("tr")
	assert(not ProjectSettings.get_setting("application/boot_splash/show_image",true))
	assert(Audio._music.stream.resource_path == "res://assets/audio/music/chill.wav")
	Audio.set_intensity(2)
	assert(Audio._music.pitch_scale == 1.0)
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().create_timer(0.5).timeout
	HowToPlay.open(menu)
	await get_tree().create_timer(0.5).timeout
	for c in HowToPlay.CARDS:
		assert(tr(c[3]) != c[3],"Missing help translation")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/howto_current.png")
	menu.get_child(menu.get_child_count()-1).queue_free()
	await get_tree().process_frame
	menu._credits()
	await get_tree().create_timer(0.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/credits_current.png")
	print("TEST_OK menu_content")
	get_tree().quit()
