extends Control
## Ana menü: Yeni Oyun, Ayarlar, Çıkış ve dil seçimi.
## 3D sürüm: Witcher tarzı solda dikey yazı menüsü, arkada gün batımında dönen köy.

const GOLD := Color(0.92, 0.78, 0.48)
const CREAM := Color(0.93, 0.89, 0.8)

var _t := 0.0
var _box: VBoxContainer
var _title: Label
var _root3: Control


func _ready() -> void:
	get_tree().paused = false
	Audio.stop_loops()
	Audio.duck(false)
	Audio.set_intensity(0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	if Bal.RENDER_3D:
		add_child(MenuBackdrop.new())
		_shade()
	else:
		add_child(Landscape.new())
	Settings.language_changed.connect(_build)
	_build()


## Soldan sağa karartma + alt kenar gölgesi (menü okunaklı, köy sağda parlak).
func _shade() -> void:
	for spec in [[Vector2(0, 0.5), Vector2(0.62, 0.5), 0.88], [Vector2(0.5, 1.0), Vector2(0.5, 0.7), 0.6]]:
		var g := GradientTexture2D.new()
		var gr := Gradient.new()
		gr.set_color(0, Color(0.03, 0.02, 0.02, spec[2]))
		gr.set_color(1, Color(0.03, 0.02, 0.02, 0.0))
		g.gradient = gr
		g.fill_from = spec[0]
		g.fill_to = spec[1]
		var tr_ := TextureRect.new()
		tr_.texture = g
		tr_.stretch_mode = TextureRect.STRETCH_SCALE
		tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr_.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(tr_)


func _menu_button(text: String, cb: Callable, big := false) -> Button:
	var b := UI.button(text, cb, 380)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 50 if big else 44
	b.add_theme_font_size_override("font_size", 30 if big else 25)
	var normal := StyleBoxEmpty.new()
	normal.content_margin_left = 18
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(GOLD, 0.13)
	hover.border_color = GOLD
	hover.border_width_left = 3
	hover.content_margin_left = 24
	for st in ["normal", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, normal if st != "focus" else StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", GOLD.lightened(0.15))
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	b.mouse_entered.connect(Audio.play.bind("click", 0.02))
	return b


func _build_3d() -> void:
	if _root3:
		_root3.queue_free()
	_root3 = Control.new()
	_root3.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root3)
	_box = UI.vbox(4)
	UI.anchor(_box, 0, 0, 84, 70, 560, 680)
	_root3.add_child(_box)
	_title = UI.label("MUHTAR", 80, GOLD)
	var big := FontVariation.new()
	big.base_font = load("res://assets/fonts/cinzel_900.ttf")
	big.spacing_glyph = 4
	_title.add_theme_font_override("font", big)
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_title.add_theme_constant_override("shadow_offset_y", 4)
	_box.add_child(_title)
	var sub := UI.label("KURAK YAZ", 34, CREAM)
	var spaced := FontVariation.new()
	spaced.base_font = UI.FONT
	spaced.spacing_glyph = 12
	sub.add_theme_font_override("font", spaced)
	_box.add_child(sub)
	var line := TextureRect.new()
	var lg := GradientTexture2D.new()
	var lgr := Gradient.new()
	lgr.set_color(0, Color(GOLD, 0.95))
	lgr.set_color(1, Color(GOLD, 0.0))
	lg.gradient = lgr
	lg.height = 2
	line.texture = lg
	line.stretch_mode = TextureRect.STRETCH_SCALE
	line.custom_minimum_size = Vector2(380, 2)
	_box.add_child(line)
	var tag := UI.label(tr("MENU_SUBTITLE"), 17, Color(CREAM, 0.85))
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = 420
	_box.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size.y = 34
	_box.add_child(gap)
	var items: Array = []
	var save := GameState.read_save()
	if not save.is_empty():
		var month: String = tr(Bal.MONTH_KEYS[clampi(int(save.round_index), 0, Bal.MONTH_KEYS.size() - 1)])
		items.append(_menu_button(tr("MENU_CONTINUE") % month, _continue.bind(save), true))
	items.append(_menu_button(tr("MENU_NEW_GAME"), _new_game, save.is_empty()))
	items.append(_menu_button(tr("MENU_HOWTO"), func(): HowToPlay.open(self)))
	items.append(_menu_button(tr("MENU_SETTINGS"), _settings))
	items.append(_menu_button(tr("MENU_ACHIEVEMENTS"), _achievements))
	items.append(_menu_button(tr("MENU_CREDITS"), _credits))
	if not OS.has_feature("web"):
		items.append(_menu_button(tr("MENU_QUIT"), get_tree().quit))
	for i in items.size():
		var b: Button = items[i]
		_box.add_child(b)
	# alt: dil + künye
	var foot := UI.vbox(6)
	UI.anchor(foot, 0, 1, 84, -86, 700, -24)
	_root3.add_child(foot)
	var lang := UI.hbox(4)
	for code in Settings.LANGUAGES:
		var lb := _menu_button(code.to_upper(), Settings.set_language.bind(code))
		lb.custom_minimum_size = Vector2(64, 30)
		lb.add_theme_font_size_override("font_size", 18)
		if code == Settings.language:
			lb.add_theme_color_override("font_color", GOLD)
		lang.add_child(lb)
	foot.add_child(lang)
	foot.add_child(UI.label(tr("MENU_FOOTER"), 14, Color(CREAM, 0.7)))


func _build() -> void:
	if Bal.RENDER_3D:
		_build_3d()
		return
	if _box:
		_box.get_parent().queue_free()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box = UI.vbox(14)
	_box.custom_minimum_size = Vector2(700, 0)
	center.add_child(_box)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 76)
	_box.add_child(holder)
	_title = UI.label("MUHTAR: KURAK YAZ", 60, Color("ffd166"))
	_title.add_theme_constant_override("outline_size", 14)
	_title.add_theme_color_override("font_outline_color", Color("5a2410"))
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	_title.add_theme_constant_override("shadow_offset_y", 5)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(_title)
	var sub := UI.label(tr("MENU_SUBTITLE"), 18)
	sub.add_theme_constant_override("outline_size", 5)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(sub)
	var panel := UI.panel()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(400, 0)
	_box.add_child(panel)
	var pv := UI.vbox(12)
	panel.add_child(pv)
	var save := GameState.read_save()
	if not save.is_empty():
		var month: String = tr(Bal.MONTH_KEYS[clampi(int(save.round_index), 0, Bal.MONTH_KEYS.size() - 1)])
		var cont := UI.button(tr("MENU_CONTINUE") % month, _continue.bind(save))
		cont.custom_minimum_size.y = 50
		cont.add_theme_font_size_override("font_size", 22)
		pv.add_child(cont)
	var ng := UI.button(tr("MENU_NEW_GAME"), _new_game)
	ng.custom_minimum_size.y = 50
	ng.add_theme_font_size_override("font_size", 22)
	pv.add_child(ng)
	pv.add_child(UI.button(tr("MENU_HOWTO"), func(): HowToPlay.open(self)))
	pv.add_child(UI.button(tr("MENU_SETTINGS"), _settings))
	pv.add_child(UI.button(tr("MENU_ACHIEVEMENTS"), _achievements))
	pv.add_child(UI.button(tr("MENU_CREDITS"), _credits))
	if not OS.has_feature("web"):
		pv.add_child(UI.button(tr("MENU_QUIT"), get_tree().quit))
	var lang := UI.hbox(8)
	lang.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl := UI.label(tr("SETTINGS_LANGUAGE") + ":")
	lbl.add_theme_constant_override("outline_size", 4)
	lang.add_child(lbl)
	for code in Settings.LANGUAGES:
		var b := UI.button(code.to_upper(), Settings.set_language.bind(code), 60)
		b.disabled = code == Settings.language
		lang.add_child(b)
	pv.add_child(lang)
	var foot := UI.label(tr("MENU_FOOTER"), 14, Color(1, 1, 1, 0.8))
	foot.add_theme_constant_override("outline_size", 4)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(foot)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 150)
	_box.add_child(spacer)


func _continue(save: Dictionary) -> void:
	GameState.pending_load = save
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _achievements() -> void:
	var p := Progress.load_profile()
	var m := UI.modal(self)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(560, 0)
	v.add_child(UI.label(tr("MENU_ACHIEVEMENTS"), 28, UI.ACCENT))
	v.add_child(UI.label(tr("ACH_BEST") % [int(p.best_score), int(p.best_stars)], 18, Color("ffd166")))
	for a in Progress.ACHIEVEMENTS:
		var got: bool = a in p.achievements
		var h := UI.hbox(10)
		h.add_child(Icon.drawn("check" if got else "box", 26))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(tr("ACH_" + a.to_upper()), 17, UI.ACCENT if got else Color(0.75, 0.72, 0.68)))
		var d := UI.label(tr("ACH_%s_DESC" % a.to_upper()), 14, Color(1, 1, 1, 0.85 if got else 0.55))
		tv.add_child(d)
		h.add_child(tv)
		v.add_child(h)
	v.add_child(UI.button(tr("BTN_CLOSE"), m[0].queue_free))


func _credits() -> void:
	var m := UI.modal(self)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(520, 0)
	v.add_child(UI.label(tr("MENU_CREDITS"), 28, UI.ACCENT))
	for k in ["CREDITS_TEAM", "CREDITS_ART", "CREDITS_CUSTOM", "CREDITS_ICON", "CREDITS_MUSIC", "CREDITS_ENGINE", "CREDITS_JAM"]:
		var l := UI.label(tr(k), 17)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	v.add_child(UI.button(tr("BTN_CLOSE"), m[0].queue_free))


func _settings() -> void:
	add_child(preload("res://scenes/settings_panel.tscn").instantiate())


func _process(delta: float) -> void:
	_t += delta
	if _title and not Bal.RENDER_3D:
		_title.position.y = sin(_t * 1.5) * 4.0
