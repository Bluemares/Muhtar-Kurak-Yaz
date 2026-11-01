extends CanvasLayer
## Oyun içi arayüz: kaynak çubuğu, inşa menüsü, seçili bina paneli, diyalog, ok, bildirimler, modallar.

var game  # game.gd

var _chips := {}
var _welfare_bar: ProgressBar
var _welfare_label: Label
var _time_label: Label
var _temp_label: Label
var _warn_label: Label
var _hint_label: Label
var _weather_label: Label
var _mission_title: Label
var _mission_desc: Label
var _ledger_prev: Label
var _ledger_dmg: Label
var _ledger_box: Control
var _side_title: Label
var _side_rows: Array = []  # [id, Icon, Label]
var _side_round := -1
var _side_box: VBoxContainer
var _day_icon: Icon
var _shop
var _build_btn: Button
var _build_label: Label
var _pause_btn: Button
var _sel_panel: PanelContainer
var _sel_title: Label
var _sel_info: Label
var _sel_buttons: HBoxContainer
var _float_bar: HBoxContainer
var _float_target = null
var _spray_btn: Button
var _move_btn: Button
var _sel_key := ""
var _mode_btn: Button
var _erase_btn: Button
var _risk_btn: Button
var _moist_btn: Button
var _risk_legend: PanelContainer
var _legend_title: Label
var _legend_keys: Array = []
var _legend_tip: Label
var _food_label: Label
var _food_bar: ProgressBar
var _div_label: Label
var _crop_pick := false  # bina üstü butonlar yerine ürün seçici açık
var _tooltip: Label
var _toasts: VBoxContainer
var _dialog: PanelContainer
var _dialog_text: Label
var _dialog_name: Label
var _dialog_portrait: Control
var _dialog_role := "hasan"
var _dialog_continue: Button
var _dialog_skip: Button
var _dialog_cb := Callable()
var _arrow: Control
var _skip_btn: Button
var _modal_layer: Control
var _root: Control
var _cinema_root: Control
var _learning_note: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI.theme()
	add_child(_root)
	_build_top()
	_build_bottom()
	_build_selection()
	_build_dialog()
	_arrow = preload("res://scripts/ui/arrow.gd").new()
	_root.add_child(_arrow)
	_tooltip = UI.label("", 15)
	_tooltip.add_theme_constant_override("outline_size", 4)
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_tooltip)
	_toasts = UI.vbox(4)
	_toasts.position = Vector2(12, 70)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toasts)
	_skip_btn = UI.button(tr("BTN_SKIP"), _on_skip, 120)
	UI.anchor(_skip_btn, 1, 1, -160, -130, -20, -90)
	_skip_btn.visible = false
	_cinema_root = Control.new()
	_cinema_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cinema_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinema_root.theme = _root.theme
	add_child(_cinema_root)
	_cinema_root.add_child(_skip_btn)
	_modal_layer = Control.new()
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_modal_layer)
	GameState.notify.connect(toast)
	GameState.fly.connect(_fly)
	Settings.language_changed.connect(_refresh_static)
	_refresh_static()


# ---------------- Kurulum ----------------

func _build_top() -> void:
	var bar := UI.panel()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.add_theme_stylebox_override("panel", UI.skin("panel", 12, 14))
	_root.add_child(bar)
	var h := UI.hbox(10)
	bar.add_child(h)
	_add_chip(h, "money", Icon.drawn("coin"))
	if Bal.RENDER_3D:
		_add_chip(h, "water", Icon.drawn("water"))
		_add_chip(h, "food", Icon.drawn("food"))
		_add_chip(h, "workers", Icon.drawn("people"))
	else:
		_add_chip(h, "water", Icon.tile(Art.FARM, 73))
		_add_chip(h, "food", Icon.tile(Art.FARM, 68))
		_add_chip(h, "workers", Icon.tile(Art.FARM, 108))
	_chips.food.box.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			open_market())
	var wbox := UI.hbox(6)
	wbox.add_child(Icon.drawn("heart"))
	_welfare_label = UI.label("", 18)
	wbox.add_child(_welfare_label)
	_welfare_bar = ProgressBar.new()
	_welfare_bar.custom_minimum_size = Vector2(130, 18)
	_welfare_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_welfare_bar.show_percentage = false
	wbox.add_child(_welfare_bar)
	h.add_child(wbox)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)
	h.add_child(Icon.drawn("sun"))
	_temp_label = UI.label("", 18)
	h.add_child(_temp_label)
	_day_icon = Icon.drawn("sun")
	h.add_child(_day_icon)
	_time_label = UI.label("", 19, UI.ACCENT)
	h.add_child(_time_label)
	_pause_btn = UI.button("II", game.toggle_pause, 40)
	_pause_btn.custom_minimum_size.y = 30
	h.add_child(_pause_btn)

	_warn_label = UI.label("", 22, Color("ff4d4d"))
	_warn_label.add_theme_constant_override("outline_size", 5)
	UI.anchor(_warn_label, 0.5, 0, -240, 62, 240, 92)
	_warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_warn_label)
	_hint_label = UI.label("", 16, Color(1, 0.93, 0.7))
	_hint_label.add_theme_constant_override("outline_size", 5)
	UI.anchor(_hint_label, 0.5, 0, -300, 92, 300, 116)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_hint_label)
	_weather_label = UI.label("", 17)
	_weather_label.add_theme_constant_override("outline_size", 5)
	UI.anchor(_weather_label, 0.5, 0, -300, 116, 300, 140)
	_weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_weather_label)

	var card := UI.panel()
	UI.anchor(card, 1, 0, -262, 62, -12, 120)
	card.add_theme_stylebox_override("panel", UI.skin("panel_inlay", 12, 14))
	_root.add_child(card)
	var cv := UI.vbox(2)
	card.add_child(cv)
	_mission_title = UI.label("", 17, UI.ACCENT)
	cv.add_child(_mission_title)
	_mission_desc = UI.label("", 14)
	_mission_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_desc.custom_minimum_size = Vector2(228, 0)
	cv.add_child(_mission_desc)
	# gıda güvenliği: kaç günlük yiyecek + ürün çeşitliliği (pazar için yiyecek ikonuna tıkla)
	cv.add_child(HSeparator.new())
	_food_label = UI.label("", 14, Color(0.95, 0.85, 0.5))
	cv.add_child(_food_label)
	_food_bar = ProgressBar.new()
	_food_bar.max_value = 3.0
	_food_bar.show_percentage = false
	_food_bar.custom_minimum_size = Vector2(228, 10)
	cv.add_child(_food_bar)
	_div_label = UI.label("", 13, Color(0.75, 0.95, 0.7))
	cv.add_child(_div_label)
	# yan görevler (ay değişince yeniden kurulur)
	cv.add_child(HSeparator.new())
	_side_title = UI.label("", 14, Color(0.8, 0.9, 1.0))
	cv.add_child(_side_title)
	_side_box = UI.vbox(2)
	cv.add_child(_side_box)
	# canlı önlem / hasar defteri: oyunun mesajı oynarken de görünsün
	cv.add_child(HSeparator.new())
	var lh := UI.hbox(10)
	lh.mouse_filter = Control.MOUSE_FILTER_STOP
	_ledger_prev = UI.label("", 14, Color(0.55, 0.82, 1.0))
	_ledger_dmg = UI.label("", 14, Color(1.0, 0.5, 0.42))
	lh.add_child(_ledger_prev)
	lh.add_child(_ledger_dmg)
	_ledger_box = lh
	cv.add_child(lh)


func _build_bottom() -> void:
	# Hay Day/CoC tarzı: sağ altta büyük yuvarlak İnşa butonu, dükkan paneli aşağıdan açılır
	_shop = preload("res://scripts/ui/build_shop.gd").new()
	_root.add_child(_shop)
	_shop.picked.connect(_on_shop_pick)
	_build_btn = Button.new()
	if Bal.RENDER_3D:
		var hm := Icon.drawn("hammer", 58)
		hm.position = Vector2(19, 17)
		hm.size = Vector2(58, 58)
		_build_btn.add_child(hm)
	else:
		_build_btn.icon = Icon.atlas(Art.TOWN, 128)
	_build_btn.expand_icon = true
	_build_btn.custom_minimum_size = Vector2(96, 96)
	_build_btn.add_theme_constant_override("icon_max_width", 56)
	var circle := UI.style(Color("4f8a3a"), 48, 18)
	circle.border_color = Color("2b1d14")
	circle.set_border_width_all(4)
	circle.shadow_color = Color(0, 0, 0, 0.4)
	circle.shadow_size = 6
	circle.shadow_offset = Vector2(0, 4)
	_build_btn.add_theme_stylebox_override("normal", circle)
	var hov: StyleBoxFlat = circle.duplicate()
	hov.bg_color = Color("62a548")
	_build_btn.add_theme_stylebox_override("hover", hov)
	var pr: StyleBoxFlat = circle.duplicate()
	pr.bg_color = Color("3d6e2c")
	_build_btn.add_theme_stylebox_override("pressed", pr)
	UI.anchor(_build_btn, 1, 1, -118, -128, -22, -32)
	_build_btn.pressed.connect(func():
		Audio.play("click", 0.05)
		game.village.cancel_mode()
		game.village.clear_selection()
		_shop.toggle())
	_root.add_child(_build_btn)
	# yol/temizleme modundan çıkış: büyük "Bitti" butonu (inşa/taşımada "Vazgeç")
	_mode_btn = UI.button("", func(): game.village.cancel_mode(), 200)
	_mode_btn.custom_minimum_size.y = 48
	_mode_btn.add_theme_font_size_override("font_size", 22)
	UI.anchor(_mode_btn, 0.5, 1, -110, -76, 110, -24)
	_mode_btn.visible = false
	_root.add_child(_mode_btn)
	_erase_btn = UI.button("", func(): game.village.road_erase = not game.village.road_erase, 170)
	_erase_btn.custom_minimum_size.y = 48
	_erase_btn.add_theme_font_size_override("font_size", 20)
	UI.anchor(_erase_btn, 0.5, 1, -300, -76, -124, -24)
	_erase_btn.visible = false
	_root.add_child(_erase_btn)
	if Bal.RENDER_3D:
		_build_risk()
	_build_label = UI.label("", 22, Color("ffe08a"))
	_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.anchor(_build_label, 1, 1, -130, -34, -10, -4)
	_root.add_child(_build_label)


## Yangın riski haritası: İnşa'nın solunda yuvarlak buton (F) + üstte açıklama.
func _build_risk() -> void:
	_risk_btn = Button.new()
	_risk_btn.toggle_mode = true
	_risk_btn.custom_minimum_size = Vector2(64, 64)
	var circ := UI.style(Color("7a3a1a"), 32, 0)
	circ.border_color = UI.GOLD
	circ.set_border_width_all(3)
	_risk_btn.add_theme_stylebox_override("normal", circ)
	var on: StyleBoxFlat = circ.duplicate()
	on.bg_color = Color("c0502a")
	on.border_color = Color(1, 0.9, 0.5)
	_risk_btn.add_theme_stylebox_override("pressed", on)
	_risk_btn.add_theme_stylebox_override("hover", on)
	var fi := Icon.drawn("fire", 40)
	fi.position = Vector2(12, 11)
	fi.size = Vector2(40, 40)
	_risk_btn.add_child(fi)
	UI.anchor(_risk_btn, 1, 1, -200, -100, -136, -36)
	_risk_btn.toggled.connect(set_risk_map)
	_root.add_child(_risk_btn)
	_risk_btn.toggled.disconnect(set_risk_map)
	_risk_btn.pressed.connect(func(): set_map_mode(0 if map_mode() == 1 else 1))
	# nem haritası: ayrı damla butonu
	_moist_btn = _risk_btn.duplicate(0)
	for c in _moist_btn.get_children():
		c.queue_free()
	var mst: StyleBoxFlat = UI.style(Color("1d4f7a"), 32, 0)
	mst.border_color = UI.GOLD
	mst.set_border_width_all(3)
	_moist_btn.add_theme_stylebox_override("normal", mst)
	var mon: StyleBoxFlat = mst.duplicate()
	mon.bg_color = Color("2f7fc0")
	mon.border_color = Color(0.7, 0.95, 1.0)
	_moist_btn.add_theme_stylebox_override("pressed", mon)
	_moist_btn.add_theme_stylebox_override("hover", mon)
	var di := Icon.drawn("water", 40)
	di.position = Vector2(12, 11)
	di.size = Vector2(40, 40)
	_moist_btn.add_child(di)
	UI.anchor(_moist_btn, 1, 1, -272, -100, -208, -36)
	_moist_btn.pressed.connect(func(): set_map_mode(0 if map_mode() == 2 else 2))
	_root.add_child(_moist_btn)
	var ml := UI.label("", 15, Color("bfe4ff"))
	ml.name = "MoistLabel"
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.anchor(ml, 1, 1, -286, -34, -194, -10)
	_root.add_child(ml)
	var rl := UI.label("", 15, Color("ffe08a"))
	rl.name = "RiskLabel"
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.anchor(rl, 1, 1, -214, -34, -122, -10)
	_root.add_child(rl)
	_risk_legend = UI.panel()
	_risk_legend.add_theme_stylebox_override("panel", UI.skin("panel", 12, 10))
	UI.anchor(_risk_legend, 0.5, 0, -260, 142, 260, 200)
	_risk_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_risk_legend.visible = false
	_root.add_child(_risk_legend)
	var lv := UI.vbox(4)
	_risk_legend.add_child(lv)
	var lh := UI.hbox(14)
	lh.alignment = BoxContainer.ALIGNMENT_CENTER
	_legend_title = UI.label(tr("RISK_TITLE"), 17, UI.ACCENT)
	lh.add_child(_legend_title)
	for k in [["RISK_LOW", View.risk_color(0.0)], ["RISK_MID", View.risk_color(0.08)], ["RISK_HIGH", View.risk_color(0.5)]]:
		var kl := UI.label("• " + tr(k[0]), 15, k[1])
		_legend_keys.append(kl)
		lh.add_child(kl)
	lv.add_child(lh)
	var tip := UI.label(tr("RISK_TIP"), 14)
	_legend_tip = tip
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(500, 0)
	lv.add_child(tip)


func set_risk_map(on: bool) -> void:
	set_map_mode(1 if on else 0)


## 0 kapalı, 1 yangın riski, 2 toprak nemi. F ve alev butonu sırayla gezer.
func set_map_mode(m: int) -> void:
	View.risk_map = m == 1
	View.moist_map = m == 2
	if _risk_btn:
		_risk_btn.set_pressed_no_signal(m == 1)
	if _moist_btn:
		_moist_btn.set_pressed_no_signal(m == 2)
	if _risk_legend:
		_risk_legend.visible = m != 0
		_legend_title.text = tr("RISK_TITLE") if m == 1 else tr("MOIST_TITLE")
		var keys: Array = [["RISK_LOW", View.risk_color(0.0)], ["RISK_MID", View.risk_color(0.08)], ["RISK_HIGH", View.risk_color(0.5)]] if m == 1 \
			else [["MOIST_WET", View.moist_color(1.0)], ["MOIST_MID", View.moist_color(0.5)], ["MOIST_DRY", View.moist_color(0.0)]]
		for i in 3:
			_legend_keys[i].text = "• " + tr(keys[i][0])
			_legend_keys[i].add_theme_color_override("font_color", keys[i][1])
		_legend_tip.text = tr("RISK_TIP") if m == 1 else tr("MOIST_TIP")
	Audio.play("click", 0.05)


func map_mode() -> int:
	return 1 if View.risk_map else (2 if View.moist_map else 0)


## Ambar ve pazar: stok, kaç gün, fiyatlar; 10'luk al/sat.
func open_market() -> void:
	var m := UI.modal(_modal_layer)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(440, 0)
	var gs := GameState
	v.add_child(UI.label(tr("MARKET_TITLE"), 26, UI.ACCENT))
	v.add_child(UI.label(tr("MARKET_STOCK") % [int(gs.food), int(gs.food_cap), gs.food_days()], 17))
	v.add_child(UI.label(tr("MARKET_PRICE") % [gs.market_price(), gs.buy_price()], 16, Color(1, 0.88, 0.5)))
	var tip := UI.label(tr("MARKET_TIP"), 14, Color(1, 1, 1, 0.85))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(420, 0)
	v.add_child(tip)
	var h := UI.hbox(8)
	var lot := float(Bal.MARKET_LOT)
	var sell := UI.button(tr("MARKET_SELL") % [Bal.MARKET_LOT, int(round(lot * gs.market_price()))], func():
		gs.sell_food(lot)
		m[0].queue_free()
		open_market(), 0)
	sell.disabled = gs.food < lot
	UI.skin_button(sell, "yellow")
	var cost := int(ceil(lot * gs.buy_price()))
	var buy := UI.button(tr("MARKET_BUY") % [Bal.MARKET_LOT, cost], func():
		gs.buy_food(lot)
		m[0].queue_free()
		open_market(), 0)
	buy.disabled = gs.money < cost or gs.food + lot > gs.food_cap
	h.add_child(sell)
	h.add_child(buy)
	v.add_child(h)
	v.add_child(UI.button(tr("BTN_CLOSE"), m[0].queue_free))


func _on_shop_pick(kind: String) -> void:
	_shop.close()
	match kind:
		"road_erase":
			game.village.begin_road()
			game.village.road_erase = true
			GameState.notify.emit("Yola tıklayarak veya sürükleyerek sil: hücre başına +%d altın." % Bal.ROAD_TILE_REFUND,Color.GOLD)
		"road_paint": game.request_road_paint()
		"road_upgrade": game.request_road_upgrade()
		"clear_land": game.request_clear()
		_: game.request_build(kind)


func _unhandled_input(event: InputEvent) -> void:
	if _shop and _shop.is_open() and event.is_action_pressed("ui_cancel"):
		_shop.close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F and not get_tree().paused and Bal.RENDER_3D:
		set_map_mode(0 if map_mode() == 1 else 1)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N and not get_tree().paused and Bal.RENDER_3D:
		set_map_mode(0 if map_mode() == 2 else 2)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and not get_tree().paused \
			and game.village.mode == "none" and game.village.selected:
		game.request_rotate(game.village.selected)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B and not get_tree().paused:
		game.village.cancel_mode()
		game.village.clear_selection()
		_shop.toggle()
		get_viewport().set_input_as_handled()


func _build_selection() -> void:
	_sel_panel = UI.panel()
	if Bal.RENDER_3D:
		var st := UI.skin("panel", 12, 10) as StyleBoxFlat
		st.shadow_size = 4
		_sel_panel.add_theme_stylebox_override("panel", st)
		_sel_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		UI.anchor(_sel_panel, 0, 1, 12, -200, 372, -12)
	_sel_panel.visible = false
	_root.add_child(_sel_panel)
	var v := UI.vbox(6)
	_sel_panel.add_child(v)
	_sel_title = UI.label("", 18 if Bal.RENDER_3D else 20, UI.ACCENT)
	v.add_child(_sel_title)
	_sel_info = UI.label("", 14 if Bal.RENDER_3D else 15)
	_sel_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sel_info.custom_minimum_size = Vector2(250 if Bal.RENDER_3D else 340, 0)
	v.add_child(_sel_info)
	_sel_buttons = UI.hbox(6)
	v.add_child(_sel_buttons)
	_float_bar = UI.hbox(8)
	_float_bar.visible = false
	_root.add_child(_float_bar)


func _build_dialog() -> void:
	_dialog = UI.panel()
	UI.anchor(_dialog, 0.5, 1, -340, -240, 340, -80)
	_dialog.add_theme_stylebox_override("panel", UI.skin("panel", 12, 18))
	_dialog.visible = false
	_root.add_child(_dialog)
	var h := UI.hbox(14)
	_dialog.add_child(h)
	var portrait := preload("res://scripts/ui/portrait.gd").new()
	portrait.custom_minimum_size = Vector2(110, 110)
	h.add_child(portrait)
	_dialog_portrait = portrait
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	_dialog_name = UI.label("", 18, UI.ACCENT)
	v.add_child(_dialog_name)
	_dialog_text = UI.label("", 17)
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_text.custom_minimum_size = Vector2(500, 60)
	v.add_child(_dialog_text)
	var bh := UI.hbox(8)
	bh.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(bh)
	_dialog_skip = UI.button("", _on_dialog_skip, 140)
	UI.skin_button(_dialog_skip, "brown")
	bh.add_child(_dialog_skip)
	_dialog_continue = UI.button("", _on_dialog_continue, 140)
	bh.add_child(_dialog_continue)


func _refresh_static() -> void:
	_shop.refresh_texts()
	_build_label.text = tr("SHOP_TITLE")
	if _risk_btn:
		_risk_btn.tooltip_text = tr("RISK_TITLE") + " (F)"
		_root.get_node("RiskLabel").text = tr("RISK_BTN")
		_moist_btn.tooltip_text = tr("MOIST_TITLE") + " (N)"
		_root.get_node("MoistLabel").text = tr("MOIST_BTN")
	_build_btn.tooltip_text = tr("SHOP_TITLE") + " (B)"
	_pause_btn.tooltip_text = tr("BTN_PAUSE") + " (Esc)"

	_ledger_box.tooltip_text = tr("HUD_LEDGER_TIP")
	for k in _chips:
		_chips[k].box.tooltip_text = tr(CHIP_KEYS[k])
	_skip_btn.text = tr("BTN_SKIP")
	_dialog_name.text = tr("NAME_" + _dialog_role.to_upper())
	_dialog_continue.text = tr("BTN_CONTINUE")
	_dialog_skip.text = tr("BTN_SKIP_TUTORIAL")
	if game and game.village.selected:
		show_selection(game.village.selected)


# ---------------- Güncelleme ----------------

const CHIP_KEYS := {"money": "RES_MONEY", "water": "RES_WATER", "food": "RES_FOOD", "workers": "RES_WORKERS"}
const BUILD_ICONS := {"field": [Art.FARM, 66], "well": [Art.TOWN, Art.T_WELL], "house": [Art.TOWN, 67],
	"greenhouse": [Art.FARM, 42], "water_tower": [Art.FARM, 85], "grove": [Art.TOWN, 16]}


func _add_chip(parent: Control, key: String, icon: Control) -> void:
	var pill := PanelContainer.new()
	var ps := UI.style(Color(0.1, 0.07, 0.05, 0.85), 14, 8)
	ps.border_color = Color(0.62, 0.45, 0.24)
	ps.set_border_width_all(2)
	pill.add_theme_stylebox_override("panel", ps)
	var box := UI.hbox(5)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	pill.add_child(box)
	box.add_child(icon)
	var l := UI.label("", 19)
	l.custom_minimum_size = Vector2(36, 0)
	box.add_child(l)
	parent.add_child(pill)
	_chips[key] = {"box": box, "l": l, "v": null}


## Hasat ödülü: ikonlar dünyadan üst çubuktaki sayaca kavisle uçar, varınca sayaç zıplar.
func _fly(world_pos: Vector2, kind: String, amount: int) -> void:
	var chip: Dictionary = _chips.get(kind, {})
	if chip.is_empty():
		return
	var start: Vector2 = View.to_screen(self, world_pos, 0.8)
	var box: Control = chip.box
	var end := box.get_global_rect().get_center()
	for i in amount:
		var ic: Icon = Icon.drawn("coin", 26) if kind == "money" else (Icon.drawn("food", 26) if Bal.RENDER_3D else Icon.tile(Art.FARM, 68, 26))
		ic.size = Vector2(26, 26)
		ic.position = start + Vector2(randf_range(-20, 20), randf_range(-14, 10))
		_root.add_child(ic)
		var mid := (ic.position + end) * 0.5 + Vector2(randf_range(-80, 80), -140)
		var from := ic.position
		var tw := ic.create_tween()
		tw.tween_interval(i * 0.06)
		tw.tween_method(func(t: float):
			ic.position = from.lerp(mid, t).lerp(mid.lerp(end - Vector2(13, 13), t), t)
			ic.scale = Vector2.ONE * lerpf(1.2, 0.7, t), 0.0, 1.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			_bump(box)
			ic.queue_free())


func _bump(c: Control) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * 1.18
	c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Değer değişince sayı kısa süre yeşil/kırmızı parlar ve zıplar (para/su/erzak geri bildirimi).
func _set_chip(key: String, v: int, text: String) -> void:
	var c: Dictionary = _chips[key]
	var l: Label = c.l
	l.text = text
	if c.v != null and key != "water" and v != c.v and absi(v - c.v) >= 2:
		l.modulate = Color(0.5, 1, 0.5) if v > c.v else Color(1, 0.45, 0.4)
		l.pivot_offset = Vector2(0, l.size.y * 0.5)
		l.scale = Vector2.ONE * 1.25
		var tw := l.create_tween().set_parallel()
		tw.tween_property(l, "modulate", Color.WHITE, 0.6)
		tw.tween_property(l, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	c.v = v

func _process(_delta: float) -> void:
	if not game:
		return
	var gs := GameState
	_set_chip("money", gs.money, str(gs.money))
	_set_chip("water", int(gs.water), "%d/%d" % [int(gs.water), int(gs.water_cap)])
	_set_chip("food", int(gs.food), "%d/%d" % [int(gs.food), int(gs.food_cap)])
	if _food_label:
		var days := gs.food_days()
		_food_label.text = tr("FOOD_DAYS") % days
		_food_bar.value = minf(days, 3.0)
		_food_bar.modulate = Color(1, 0.35, 0.3) if days < 0.5 or gs.hungry else (Color(1, 0.85, 0.3) if days < Bal.JULY_FOOD_DAYS else Color(0.5, 1, 0.5))
		_div_label.text = tr("FOOD_KINDS") % [gs.crop_kinds(), Bal.DIVERSITY_BONUS[mini(gs.crop_kinds(), Bal.DIVERSITY_BONUS.size() - 1)]]
		var hs := gs.heat_stress()
		if hs >= 1.0:
			_div_label.text += "  ·  " + tr("HEAT_STRESS") % int(round(hs))
	_set_chip("workers", gs.workers.size(), "%d/%d" % [gs.workers.size(), gs.max_workers()])
	_welfare_label.text = "%s %d%%" % [tr("RES_WELFARE"), int(gs.welfare)]
	_welfare_bar.value = gs.welfare
	var crisis := gs.hungry or gs.thirsty or gs.welfare < 30
	_welfare_bar.modulate = Color(1, 0.3, 0.3) if crisis else (Color(0.5, 1, 0.5) if gs.welfare >= Bal.WIN_WELFARE else Color(1, 0.9, 0.4))
	var secs := int(ceil(gs.round_time_left))
	_time_label.text = "%s  %d:%02d" % [tr(Bal.MONTH_KEYS[gs.round_index]), secs / 60, secs % 60]
	var ds := "moon" if gs.night_factor() > 0.5 else "sun"
	if _day_icon.shape != ds:
		_day_icon.shape = ds
		_day_icon.queue_redraw()
	_temp_label.text = tr("HUD_CLIMATE") % [gs.temperature(), int(gs.drought() * 100)]
	_temp_label.tooltip_text = "%s / %s" % [tr("RES_TEMP"), tr("RES_DROUGHT")]
	_temp_label.mouse_filter = Control.MOUSE_FILTER_STOP
	var warns: Array = []
	if gs.thirsty:
		warns.append(tr("WARN_THIRSTY"))
	if gs.hungry:
		warns.append(tr("WARN_HUNGRY"))
	_warn_label.text = "  ".join(warns)
	if gs.heat_left > 0.0:
		_weather_label.text = tr("WX_HEAT") % ceili(gs.heat_left)
		_weather_label.modulate = Color(1, 0.6, 0.3)
	elif gs.rain_left > 0.0:
		_weather_label.text = tr("WX_RAIN") % ceili(gs.rain_left)
		_weather_label.modulate = Color(0.6, 0.85, 1.0)
	else:
		_weather_label.text = ""
	var vm: String = game.village.mode
	_mode_btn.visible = vm != "none" and not get_tree().paused
	if _mode_btn.visible:
		_mode_btn.text = tr("BTN_DONE") if vm in ["road", "clear"] else tr("BTN_CANCEL_PLACE")
		UI.skin_button(_mode_btn, "green" if vm in ["road", "clear"] else "red")
	_erase_btn.visible = vm == "road" and not get_tree().paused
	if _erase_btn.visible:
		_erase_btn.text = tr("BTN_ROAD_LAY") if game.village.road_erase else "Yol sil / sat (+%d)" % Bal.ROAD_TILE_REFUND
		UI.skin_button(_erase_btn, "yellow" if game.village.road_erase else "brown")
	var hk := _hint_key()
	if vm in ["build", "move"] and not game.village.ghost_type in Bal.NO_ROAD_NEEDED and game.village.can_place(game.village.ghost_type, game.village.ghost_cell, game.village.moving_building) \
			and not game.village.road_adjacent(game.village.ghost_type, game.village.ghost_cell):
		hk = "GHOST_NO_ROAD"
	elif vm in ["build", "move"] and game.village.ghost_type == "well" and Terrain.river_distance(game.village.ghost_cell) <= Bal.RIVER_WELL_DIST:
		hk = "GHOST_RIVER"
	_hint_label.text = "→ " + tr(hk) if hk != "" else ""
	_warn_label.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008) if not warns.is_empty() else 1.0
	_mission_title.text = tr(Bal.MISSION_KEYS[gs.round_index])
	_mission_desc.text = tr(Bal.MISSION_DESC_KEYS[gs.round_index])
	_update_side()
	_ledger_prev.text = tr("HUD_PREVENTION") % gs.stats.prevention
	_ledger_dmg.text = tr("HUD_DAMAGE") % gs.stats.damage
	if _shop.is_open():
		_shop.refresh()
	_place_float_bar()
	_update_tooltip()
	var sel = game.village.selected
	if _sel_panel.visible and sel:
		if _sel_key != _state_key(sel) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			show_selection(sel)  # basılıyken yeniden kurma: tıklama kaybolmasın
		else:
			_update_sel_info(sel)


func _update_side() -> void:
	var ri := GameState.round_index
	if ri != _side_round:
		_side_round = ri
		for c in _side_box.get_children():
			c.queue_free()
		_side_rows.clear()
		for m in Bal.SIDE_MISSIONS[ri]:
			var h := UI.hbox(4)
			var ic := Icon.drawn("box", 18)
			var l := UI.label("", 13)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(200, 0)
			h.add_child(ic)
			h.add_child(l)
			_side_box.add_child(h)
			_side_rows.append([m[0], m[1], ic, l])
	_side_title.text = tr("SIDE_TITLE")
	for row in _side_rows:
		var done: bool = game.side_completed(row[0])
		var ic: Icon = row[2]
		var l: Label = row[3]
		var shape := "check" if done else "box"
		if ic.shape != shape:
			ic.shape = shape
			ic.queue_redraw()
		l.text = "%s  +%d" % [tr("SIDE_" + row[0]), row[1]]
		l.modulate = Color(0.65, 1.0, 0.65, 0.75) if done else Color.WHITE


## Oyuncunun o an yapabileceği en önemli tek eylem (öncelik sırasıyla).
func _hint_key() -> String:
	var gs := GameState
	if not gs.round_active or get_tree().paused or game.fire_active:
		return ""
	var ruined := false
	var pest := false
	var fields := 0
	for b in gs.buildings:
		if b.state == "ruined":
			ruined = true
		if b.type == "field" and b.state == "normal":
			fields += 1
			if b.pest:
				pest = true
	if gs.hungry and fields == 0:
		return "HINT_NO_FIELD"
	if ruined:
		return "HINT_REPAIR"
	if gs.thirsty:
		return "HINT_THIRSTY"
	if gs.hungry:
		return "HINT_HUNGRY"
	if pest:
		return "HINT_PEST"
	if gs.buildings.any(func(b): return b.needs_road() and b.state == "normal" and not b.road_connected()):
		return "HINT_NO_ROAD"
	return ""


func _update_tooltip() -> void:
	var h = game.village.hovered
	if h == null or not is_instance_valid(h) or game.village.mode != "none" or get_tree().paused:
		_tooltip.visible = false
		return
	var txt := tr(Bal.BUILDINGS[h.type].name)
	var risk := GameState.fire_risk_per_minute(h)
	if Bal.BUILDINGS[h.type].flammable:
		txt += "\n" + tr("TIP_FIRE_RISK") % int(risk * 100.0)
	if h.state != "normal":
		txt += "\n" + tr("STATE_" + h.state.to_upper())
	_tooltip.text = txt
	_tooltip.visible = true
	_tooltip.position = _root.get_local_mouse_position() + Vector2(18, 12)


# ---------------- Seçili bina ----------------

func _state_key(b) -> String:
	var uc: int = b.upgrade_cost()
	return "%s|%d|%s|%s|%s|%s" % [b.state, b.level, b.pest, b.drip, uc > 0 and GameState.can_afford(uc), GameState.can_afford(b.repair_cost())]


func show_selection(b) -> void:
	_sel_key = _state_key(b)
	_sel_panel.visible = true
	_sel_title.text = tr(Bal.BUILDINGS[b.type].name)
	if _shop.is_open():
		_shop.close()
	# CoC tarzı: işlem butonları binanın altında yuvarlak, sırayla zıplayarak çıkar
	for c in _float_bar.get_children():
		c.queue_free()
	_float_target = b
	if _crop_pick and b.is_crop():
		_crop_picker(b)
		_update_sel_info(b)
		return
	_crop_pick = false
	var d: Dictionary = Bal.BUILDINGS[b.type]
	var uc: int = b.upgrade_cost()
	if uc > 0:
		_action("upgrade", tr("BTN_UPGRADE") % uc, str(uc), game.request_upgrade.bind(b), b.state != "normal" or not GameState.can_afford(uc), Color("4f8a3a"))
	_spray_btn = null
	if b.type == "field":
		_spray_btn = _action("spray", tr("BTN_SPRAY") % Bal.SPRAY_COST, str(Bal.SPRAY_COST), game.request_spray.bind(b), b.state == "ruined" or b.state == "burning" or not GameState.can_afford(Bal.SPRAY_COST), Color("8a6a2a"))
		if not b.drip:
			_action("drip", tr("TIP_DRIP"), str(Bal.DRIP_COST), game.request_drip.bind(b), b.state != "normal" or not GameState.can_afford(Bal.DRIP_COST), Color("2f6fa8"))
	if b.is_crop():
		_action("crop", tr("BTN_CROP"), tr(Bal.CROPS[b.crop].name), func():
			_crop_pick = true
			show_selection(b), b.state == "ruined" or b.state == "burning", Color("6a8a2a"))
	if b.state == "ruined":
		_action("repair", tr("BTN_REPAIR") % b.repair_cost(), str(b.repair_cost()), game.request_repair.bind(b), not GameState.can_afford(b.repair_cost()), Color("b0843a"))
	_move_btn = null
	if d.movable:
		_move_btn = _action("move", tr("BTN_MOVE"), tr("BTN_MOVE"), game.request_move.bind(b), not game.can_move(b), Color("5a6e8a"))
	if b.type in ["cop31", "granary"]:
		_action("food", tr("BTN_MARKET"), tr("BTN_MARKET"), open_market, false, Color("8a6a2a"))
	if game.can_sell(b):
		var val: int = game.sell_value(b)
		_action("sell", tr("BTN_SELL") % val, "+%d" % val, func(): _confirm_sell(b), false, Color("7a5a2a"))
	if Bal.RENDER_3D:
		_action("rotate", tr("BTN_ROTATE"), tr("BTN_ROTATE"), func():
			game.request_rotate(b), b.state != "normal", Color("4a6a8a"))
	_action("close", tr("BTN_CLOSE"), "", game.village.clear_selection, false, Color("a8322a"))
	_pop_in()
	_update_sel_info(b)


func _confirm_sell(b) -> void:
	var m := UI.modal(_modal_layer)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(380, 0)
	v.add_child(UI.label(tr("SELL_TITLE") % tr(Bal.BUILDINGS[b.type].name), 22, UI.ACCENT))
	var t := UI.label(tr("SELL_BODY") % game.sell_value(b), 16)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var h := UI.hbox(8)
	var yes := UI.button(tr("BTN_SELL") % game.sell_value(b), func():
		m[0].queue_free()
		game.request_sell(b), 0)
	UI.skin_button(yes, "red")
	h.add_child(yes)
	h.add_child(UI.button(tr("BTN_CANCEL_PLACE"), m[0].queue_free, 0))
	v.add_child(h)


## Tarla ürün seçici: 4 ürün + geri. Su ve verim çarpanı ipucunda.
func _crop_picker(b) -> void:
	for id in Bal.CROP_ORDER:
		var c: Dictionary = Bal.CROPS[id]
		var tip: String = tr(c.name) + "\n" + tr("CROP_TIP") % [int(round(c.water * 100.0)), int(round(c.yield * 100.0))]
		var rec: bool = id == GameState.recommended_crop()
		_action("crop_" + id, tip, ("» " if rec else "") + tr(c.name), func():
			_crop_pick = false
			game.request_crop(b, id)
			show_selection(b), b.crop == id, Color("4f8a3a") if b.crop != id else Color("8a7a3a"))
	_action("close", tr("BTN_CLOSE"), "", func():
		_crop_pick = false
		show_selection(b), false, Color("a8322a"))
	_pop_in()


func _pop_in() -> void:
	var i := 0
	for c in _float_bar.get_children():
		c.scale = Vector2.ONE * 0.3
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c, "modulate:a", 1.0, 0.12)
		i += 1


## Yuvarlak işlem butonu + altında fiyat/etiket. Döndürür: Button (öğretici oku için).
func _action(icon: String, tip: String, caption: String, cb: Callable, disabled: bool, col: Color) -> Button:
	var v := UI.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var b := Button.new()
	if Bal.RENDER_3D:
		var ic: Control
		if icon.begins_with("crop_"):
			ic = _crop_icon(icon.trim_prefix("crop_"))
		else:
			ic = Icon.drawn(icon, 40)
		ic.position = Vector2(9, 9)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
	else:
		b.icon = Sprites.icon(icon)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(58, 58)
	b.add_theme_constant_override("icon_max_width", 34)
	b.tooltip_text = tip
	b.disabled = disabled
	var st := UI.style(col, 29, 10)
	st.border_color = Color("2b1d14")
	st.set_border_width_all(3)
	st.shadow_color = Color(0, 0, 0, 0.4)
	st.shadow_size = 4
	st.shadow_offset = Vector2(0, 3)
	b.add_theme_stylebox_override("normal", st)
	var hv: StyleBoxFlat = st.duplicate()
	hv.bg_color = col.lightened(0.18)
	b.add_theme_stylebox_override("hover", hv)
	var pr: StyleBoxFlat = st.duplicate()
	pr.bg_color = col.darkened(0.2)
	b.add_theme_stylebox_override("pressed", pr)
	var ds: StyleBoxFlat = st.duplicate()
	ds.bg_color = col.darkened(0.5)
	b.add_theme_stylebox_override("disabled", ds)
	b.pressed.connect(Audio.play.bind("click", 0.05))
	b.pressed.connect(cb)
	v.add_child(b)
	var l := UI.label(caption, 15, Color("ffe08a") if not disabled else Color(1, 0.6, 0.55))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	if disabled:
		b.modulate = Color(0.55, 0.55, 0.55, 0.8)  # para yetmiyor / yapılamaz: belirgin sönük
	v.pivot_offset = Vector2(36, 30)
	_float_bar.add_child(v)
	return b


## Buton dizisini binanın altına (ekran koordinatı) yerleştirir; kamera kayınca takip eder.
func _place_float_bar() -> void:
	var b = _float_target
	if b == null or not is_instance_valid(b) or not _sel_panel.visible or get_tree().paused:
		_float_bar.visible = false
		return
	_float_bar.visible = true
	var w := Vector2(b.size) * Bal.CELL
	var sp: Vector2 = View.to_screen(self, b.position + Vector2(w.x * 0.5, w.y + 6))
	if View.is_3d():
		sp = View.to_screen(self, b.center()) + Vector2(0, 36)
	var bw := _float_bar.get_combined_minimum_size()
	var vs := _root.size
	_float_bar.size = bw
	_float_bar.position = Vector2(clampf(sp.x - bw.x * 0.5, 8, vs.x - bw.x - 8), clampf(sp.y, 70, vs.y - bw.y - 8))
	if View.is_3d():
		var top: Vector2 = View.to_screen(self, b.center(), BuildingView3D.top(b) + 0.35)
		var ps := _sel_panel.get_combined_minimum_size()
		_sel_panel.size = ps
		_sel_panel.position = Vector2(clampf(top.x - ps.x * 0.5, 8, vs.x - ps.x - 8), clampf(top.y - ps.y - 40, 64, vs.y - ps.y - 8))


func _update_sel_info(b) -> void:
	var d: Dictionary = Bal.BUILDINGS[b.type]
	if Bal.RENDER_3D:
		_sel_info.text = "\n".join(_short_info(b, d))
		return
	var lines: Array = []
	lines.append(tr("SEL_LEVEL") % [b.level, d.max_level])
	lines.append(tr("SEL_STATE") % tr("STATE_" + b.state.to_upper()))
	match b.type:
		"field":
			lines.append(tr("SEL_FIELD") % [Bal.HARVEST_YIELD[b.level], Bal.HARVEST_TIME[b.level]])
			lines.append(tr("SEL_WORKER") % (1 if b.has_working_worker() else 0))
			if b.pest:
				lines.append(tr("SEL_PEST"))
			elif b.is_protected():
				lines.append(tr("SEL_PROTECTED"))
			if b.drip:
				lines.append(tr("SEL_DRIP"))
			lines.append(tr("SEL_ROAD_ON") if b.road_connected() else tr("SEL_ROAD_OFF"))
		"well":
			lines.append(tr("SEL_WELL") % [Bal.WELL_WATER[b.level] * (1.0 + b.river_bonus()), Bal.HOSE_TANK[b.level]])
			if b.near_river:
				lines.append(tr("SEL_RIVER") % int(round(b.river_bonus() * 100.0)))
		"house":
			lines.append(tr("SEL_HOUSE") % Bal.WORKERS_PER_HOUSE)
		"greenhouse":
			lines.append(tr("SEL_FIELD") % [b.harvest_yield(), b.harvest_time()])
			lines.append(tr("SEL_ROAD_ON") if b.road_connected() else tr("SEL_ROAD_OFF"))
			lines.append(tr("SEL_WORKER") % (1 if b.has_working_worker() else 0))
			lines.append(tr("DESC_GREENHOUSE"))
		"water_tower":
			lines.append(tr("DESC_WATER_TOWER"))
		"grove":
			lines.append(tr("DESC_GROVE"))
		"cop31":
			lines.append(tr("SEL_COP") % Bal.MAX_WORKERS_BY_COP_LEVEL[b.level])
		"fire_station":
			lines.append(tr("SEL_STATION"))
	_sel_info.text = "\n".join(lines)


## 3D sürümün küçük kartı: seviye/durum + tek ana bilgi + uyarılar.
func _short_info(b, d: Dictionary) -> Array:
	if _crop_pick and b.is_crop():
		var out: Array = []
		var rec: String = GameState.recommended_crop()
		for id in Bal.CROP_ORDER:
			var c: Dictionary = Bal.CROPS[id]
			out.append(tr("CROP_ROW") % [("» " if id == rec else "") + tr(c.name), int(round(c.water * 100.0)), int(round(c.yield * 100.0)),
				(Bal.GREENHOUSE_TIME if b.type == "greenhouse" else Bal.HARVEST_TIME[b.level]) * c.time])
		out.append(tr("CROP_REC") % [tr(Bal.CROPS[rec].name), tr("REC_" + rec.to_upper())])
		return out
	var lines: Array = ["%s · %s" % [tr("SEL_LEVEL") % [b.level, d.max_level], tr("STATE_" + b.state.to_upper())]]
	match b.type:
		"field":
			lines.append(tr("SEL_CROP") % tr(Bal.CROPS[b.crop].name) + " · " + tr("SEL_FIELD") % [b.harvest_yield(), b.harvest_time()])
		"greenhouse":
			lines.append(tr("SEL_CROP") % tr(Bal.CROPS[b.crop].name) + " · " + tr("SEL_FIELD") % [b.harvest_yield(), b.harvest_time()])
		"well":
			lines.append(tr("SEL_WELL") % [Bal.WELL_WATER[b.level] * (1.0 + b.river_bonus()), Bal.HOSE_TANK[b.level]])
		"house":
			lines.append(tr("SEL_HOUSE") % Bal.WORKERS_PER_HOUSE)
		"cop31":
			lines.append(tr("SEL_COP") % Bal.MAX_WORKERS_BY_COP_LEVEL[b.level])
	if b.needs_road() and not b.road_connected():
		lines.append("[!] " + tr("SEL_NO_ROAD"))
	if b.pest:
		lines.append("[!] " + tr("SEL_PEST"))
	return lines


func _crop_icon(id: String) -> Control:
	var c := preload("res://scripts/ui/crop_icon.gd").new()
	c.crop = id
	c.custom_minimum_size = Vector2(40, 40)
	c.size = Vector2(40, 40)
	return c


func hide_selection() -> void:
	_sel_panel.visible = false
	_float_target = null
	if _float_bar:
		_float_bar.visible = false


# ---------------- Diyalog & ok ----------------

## role: konuşan kişi (hasan | cop | fire | teacher | farmer | press)
func show_dialog(text: String, on_continue := Callable(), show_skip := false, role := "hasan") -> void:
	_dialog_role = role
	_dialog_portrait.role = role
	_dialog_name.text = tr("NAME_" + role.to_upper())
	if not _dialog.visible:
		_dialog.modulate.a = 0.0
		_dialog.create_tween().tween_property(_dialog, "modulate:a", 1.0, 0.2)
	_dialog.visible = true
	_dialog_text.text = text
	# daktilo efekti
	_dialog_text.visible_ratio = 0.0
	_dialog_text.create_tween().tween_property(_dialog_text, "visible_ratio", 1.0, minf(1.6, text.length() * 0.022))
	_dialog_cb = on_continue
	_dialog_continue.visible = on_continue.is_valid()
	_dialog_skip.visible = show_skip


func hide_dialog() -> void:
	_dialog.visible = false
	_dialog_cb = Callable()


func dialog_visible() -> bool:
	return _dialog.visible


func _on_dialog_continue() -> void:
	var cb := _dialog_cb
	hide_dialog()
	if cb.is_valid():
		cb.call()


func _on_dialog_skip() -> void:
	game.skip_tutorial()


func point_world(pos: Vector2) -> void:
	_arrow.target_world = pos
	_arrow.target_control = null
	_arrow.visible = true


func point_control(c: Control) -> void:
	_arrow.target_control = c
	_arrow.visible = true


func clear_arrow() -> void:
	_arrow.visible = false
	_arrow.target_control = null


func control_for(name: String) -> Control:
	match name:
		"spray_btn": return _spray_btn
		"move_btn": return _move_btn
		"water": return _chips.water.box
		"road_btn", "build": return _build_btn
	if Bal.BUILDINGS.has(name):
		return _shop.cards[name] if _shop.is_open() and _shop.cards.has(name) else _build_btn
	return null


# ---------------- Sinematik ----------------

func show_skip(on: bool) -> void:
	_skip_btn.visible = on
	_root.visible = not on


func _on_skip() -> void:
	game.skip_cinematic()


# ---------------- Bildirim ----------------

func toast(key: String, color := Color.WHITE) -> void:
	var l := UI.label(tr(key), 18, color)
	l.add_theme_constant_override("outline_size", 5)
	_toasts.add_child(l)
	if key in ["NOTE_PEST", "NOTE_NO_MONEY", "NOTE_CANT_MOVE", "NOTE_NEED_HOUSE"]:
		Audio.play("alert", 0.0)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.tween_interval(3.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)


## Ekranı geçen büyük başlık (ay başı).
func banner(title: String, sub := "") -> void:
	var v := UI.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor(v, 0.5, 0.4, -400, -60, 400, 60)
	var t := UI.label(title.to_upper(), 72, Color("ffd166"))
	t.add_theme_constant_override("outline_size", 14)
	t.add_theme_color_override("font_outline_color", Color("5a2410"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if sub != "":
		var s := UI.label(sub, 30, Color(1, 0.6, 0.35))
		s.add_theme_constant_override("outline_size", 8)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	_root.add_child(v)
	v.modulate.a = 0.0
	v.pivot_offset = Vector2(400, 60)
	v.scale = Vector2.ONE * 1.4
	var tw := v.create_tween()
	tw.tween_property(v, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(v, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_property(v, "modulate:a", 0.0, 0.5)
	tw.tween_callback(v.queue_free)
	Audio.play("alert", 0.0)


# ---------------- Modallar ----------------

func show_round_summary(s: Dictionary, on_next: Callable) -> void:
	var m := UI.modal(_modal_layer)
	var outer: VBoxContainer = m[1]
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 480)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	v.add_child(UI.label(tr("SUM_TITLE") % tr(Bal.MONTH_KEYS[s.round]), 26, UI.ACCENT))
	v.add_child(UI.label(tr("SUM_CROPS") % [int(s.produced), int(s.eaten), int(s.sold)]))
	v.add_child(UI.label(tr("SUM_MONEY") % [s.earned, s.spent]))
	v.add_child(UI.label(tr("SUM_FIRES") % [s.fires, s.burned]))
	var side_done := 0
	for sm in Bal.SIDE_MISSIONS[s.round]:
		if GameState.flags.get("side_%d_%s" % [s.round, sm[0]], false):
			side_done += 1
	v.add_child(UI.label(tr("SUM_SIDE") % [side_done, Bal.SIDE_MISSIONS[s.round].size()], 17, Color(0.8, 0.9, 1.0)))
	if s.mission_ok:
		v.add_child(UI.label(tr("SUM_MISSION_OK") % Bal.MISSION_REWARD_MONEY, 17, Color.LIGHT_GREEN))
	else:
		v.add_child(UI.label(tr("SUM_MISSION_FAIL"), 17, Color.ORANGE))
	if s.penalty > 0:
		v.add_child(UI.label(tr("SUM_HUNGER_PENALTY") % int(s.penalty), 17, Color("ff6b6b")))
	v.add_child(UI.label(tr("SUM_WELFARE") % int(GameState.welfare)))
	ClimateReport.add_to(v, s.get("climate_report", {}), 570)
	v.add_child(_climate_note("CLIMATE_NOTE_%d" % s.round))
	var last: bool = s.round >= Bal.MONTH_KEYS.size() - 1
	var btn := UI.button(tr("BTN_FINAL") if last else tr("BTN_NEXT_MONTH"), func():
		m[0].queue_free()
		on_next.call())
	outer.add_child(btn)


## Brief, non-modal explanation; stays visible during fire camera transitions.
func show_learning(key: String) -> void:
	if is_instance_valid(_learning_note):
		_learning_note.queue_free()
	var panel := UI.panel()
	_learning_note = panel
	panel.name = "LearningNote"
	panel.position = Vector2(12, 116)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinema_root.add_child(panel)
	var box := UI.vbox(5)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	var title := UI.label(tr("LEARN_TITLE"), 18, UI.ACCENT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var body := UI.label(tr(key), 16)
	body.custom_minimum_size.x = 350
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(body)
	var tween := panel.create_tween()
	tween.tween_interval(10.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)


## Ay sonu "İklim notu" kutusu: oyunda yaşananı gerçek dünyaya bağlar.
func _climate_note(key: String) -> Control:
	var box := UI.panel()
	box.add_theme_stylebox_override("panel", UI.skin("panel_inlay", 12, 14))
	var h := UI.hbox(10)
	box.add_child(h)
	h.add_child(Icon.drawn("sun", 30))
	var v := UI.vbox(2)
	h.add_child(v)
	v.add_child(UI.label(tr("CLIMATE_NOTE_TITLE"), 15, Color(0.6, 0.85, 1.0)))
	var l := UI.label(tr(key), 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(380, 0)
	v.add_child(l)
	return box


## Kart başında konuşan kişi: küçük portre + ad + alt başlık.
func _speaker_row(role: String, sub: String) -> Control:
	var h := UI.hbox(10)
	var p := preload("res://scripts/ui/portrait.gd").new()
	p.custom_minimum_size = Vector2(64, 64)
	p.role = role
	h.add_child(p)
	var v := UI.vbox(0)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_child(UI.label(tr("NAME_" + role.to_upper()), 16, Color(1, 0.85, 0.55)))
	v.add_child(UI.label(sub, 15, Color(0.8, 0.9, 1.0)))
	h.add_child(v)
	return h


## COP31 politika seçimi: 3 kart yan yana, cb(i) çağrılır.
func show_policy_choice(ids: Array, cb: Callable) -> void:
	var m := UI.modal(_modal_layer)
	var v: VBoxContainer = m[1]
	v.add_child(_speaker_row("cop", tr("POL_FROM")))
	v.add_child(UI.label(tr("POL_TITLE"), 28, UI.ACCENT))
	var d := UI.label(tr("POL_DESC"), 15)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(720, 0)
	v.add_child(d)
	var row := UI.hbox(12)
	v.add_child(row)
	for i in ids.size():
		var id: String = ids[i]
		var card := UI.panel()
		card.add_theme_stylebox_override("panel", UI.skin("panel_inlay", 12, 14))
		card.custom_minimum_size = Vector2(236, 230)
		row.add_child(card)
		var cv := UI.vbox(8)
		card.add_child(cv)
		var ic: Array = Bal.POLICY_ICONS[id]
		var icon: Icon = Icon.drawn(ic[0], 40) if ic[0] != "" else Icon.tile(Art.FARM if ic[1] != 83 else Art.TOWN, ic[1], 40)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cv.add_child(icon)
		var t := UI.label(tr("POL_" + id.to_upper()), 19, UI.ACCENT)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(t)
		var desc := UI.label(tr("POL_%s_DESC" % id.to_upper()), 14)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(desc)
		cv.add_child(UI.button(tr("POL_PICK"), func():
			m[0].queue_free()
			cb.call(i)))


## Köylü karar kartı: portre + metin + iki seçenek. cb(0|1) çağrılır.
func show_decision(title: String, body: String, a_text: String, b_text: String, cb: Callable, role := "hasan") -> void:
	var m := UI.modal(_modal_layer)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(560, 0)
	v.add_child(UI.label(tr("NAME_" + role.to_upper()), 16, Color(1, 0.85, 0.55)))
	v.add_child(UI.label(title, 26, UI.ACCENT))
	var h := UI.hbox(14)
	v.add_child(h)
	var portrait := preload("res://scripts/ui/portrait.gd").new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.role = role
	h.add_child(portrait)
	var l := UI.label(body, 17)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(440, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var bh := UI.hbox(10)
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(bh)
	for i in 2:
		var b := UI.button(a_text if i == 0 else b_text, func():
			m[0].queue_free()
			cb.call(i), 250)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(250, 56)
		if i == 1:
			UI.skin_button(b, "brown")
		bh.add_child(b)
	Audio.play("alert", 0.0)


func show_pause_menu(on_resume: Callable, on_menu: Callable) -> Control:
	var m := UI.modal(_modal_layer)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(300, 0)
	v.add_child(UI.label(tr("PAUSE_TITLE"), 28, UI.ACCENT))
	v.add_child(UI.button(tr("BTN_RESUME"), on_resume))
	v.add_child(UI.button(tr("MENU_HOWTO"), func(): HowToPlay.open(_modal_layer)))
	v.add_child(UI.button(tr("MENU_SETTINGS"), func():
		var sp = preload("res://scenes/settings_panel.tscn").instantiate()
		_modal_layer.add_child(sp)))
	v.add_child(UI.button(tr("BTN_MAIN_MENU"), on_menu))
	var lang := UI.hbox(8)
	lang.alignment = BoxContainer.ALIGNMENT_CENTER
	lang.add_child(UI.label(tr("SETTINGS_LANGUAGE") + ":"))
	for code in Settings.LANGUAGES:
		var b := UI.button(code.to_upper(), game.set_language_paused.bind(code), 60)
		b.disabled = code == Settings.language
		lang.add_child(b)
	v.add_child(lang)
	return m[0]


func show_mission_card(round_i: int, on_ok: Callable) -> void:
	var m := UI.modal(_modal_layer)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(440, 0)
	v.add_child(_speaker_row("cop", tr("CARD_FROM_COP")))
	v.add_child(UI.label(tr(Bal.MONTH_KEYS[round_i]) + " — " + tr(Bal.MISSION_KEYS[round_i]), 26, UI.ACCENT))
	var d := UI.label(tr(Bal.MISSION_DESC_KEYS[round_i]) + "\n\n" + tr("CARD_DROUGHT") % [int(Bal.DROUGHT[round_i] * 100), Bal.TEMPERATURE[round_i]])
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(420, 0)
	v.add_child(d)
	v.add_child(UI.button(tr("BTN_START_MONTH"), func():
		m[0].queue_free()
		on_ok.call()))
