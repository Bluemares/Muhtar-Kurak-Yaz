extends Control
## Ayarlar paneli. Ana menü ve duraklatma menüsünde aynı sahne kullanılır.

signal closed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	Settings.language_changed.connect(_build)
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var m := UI.modal(self)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(460, 0)
	v.add_child(UI.label(tr("SETTINGS_TITLE"), 28, UI.ACCENT))

	# Ses
	v.add_child(_toggle_slider("SETTINGS_MUSIC", "music"))
	v.add_child(_toggle_slider("SETTINGS_SFX", "sfx"))

	# Ekran
	var fs_row := UI.hbox()
	fs_row.add_child(_row_label("SETTINGS_FULLSCREEN"))
	var fs := CheckButton.new()
	fs.button_pressed = Settings.fullscreen
	fs.toggled.connect(_on_fullscreen)
	fs_row.add_child(fs)
	v.add_child(fs_row)

	var res_row := UI.hbox()
	res_row.add_child(_row_label("SETTINGS_RESOLUTION"))
	var res := OptionButton.new()
	for r in Settings.RESOLUTIONS:
		res.add_item("%dx%d" % [r.x, r.y])
	res.selected = Settings.resolution_index
	res.item_selected.connect(_on_resolution)
	res_row.add_child(res)
	v.add_child(res_row)

	v.add_child(UI.button(tr("BTN_CLOSE"), _close))


func _row_label(key: String) -> Label:
	var l := UI.label(tr(key))
	l.custom_minimum_size = Vector2(170, 0)
	return l


## channel: "music" | "sfx" -> Settings.<channel>_on / <channel>_volume
func _toggle_slider(key: String, channel: String) -> HBoxContainer:
	var h := UI.hbox()
	h.add_child(_row_label(key))
	var cb := CheckButton.new()
	cb.button_pressed = Settings.get(channel + "_on")
	cb.toggled.connect(_on_audio.bind(channel + "_on"))
	h.add_child(cb)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = Settings.get(channel + "_volume")
	s.custom_minimum_size = Vector2(160, 0)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(_on_audio.bind(channel + "_volume"))
	h.add_child(s)
	return h


func _on_audio(value, prop: String) -> void:
	Settings.set(prop, value)
	Settings.apply_audio()


func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	Settings.apply_display()


func _on_resolution(i: int) -> void:
	Settings.resolution_index = i
	Settings.apply_display()


func _close() -> void:
	Settings.save_settings()
	closed.emit()
	queue_free()
