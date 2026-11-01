extends Node
## Keep the native boot window invisible; reveal only after the menu is drawn.
## Windows-only settings follow Godot's documented transparent 1px boot method.
var display_ready := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless" or not OS.has_feature("windows"):
		display_ready = true
		return
	# Embedded editor runs own their window; do not resize/reposition that host.
	if Engine.has_method("is_embedded_in_editor") and Engine.call("is_embedded_in_editor"):
		display_ready = true
		get_window().transparent_bg = false
		get_window().unfocusable = false
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	display_ready = true
	var window := get_window()
	window.transparent_bg = false
	window.transparent = false
	window.borderless = false
	window.unfocusable = false
	Settings.apply_display()
	window.grab_focus()
	print("STARTUP_MENU_VISIBLE_MS ", Time.get_ticks_msec())
