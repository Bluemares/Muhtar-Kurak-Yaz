extends PanelContainer
## Hay Day/CoC tarzı inşa dükkanı: sekmeler + büyük kartlar (görsel, ad, açıklama, fiyat etiketi).
## picked(kind): bina tipi ya da "road_paint" / "road_upgrade".

signal picked(kind: String)

const TABS := [
	["TAB_FARM", ["field", "greenhouse", "grove", "granary"]],
	["TAB_WATER", ["well", "water_tower"]],
	["TAB_HOME", ["house", "lamp"]],
	["TAB_INFRA", ["road_paint", "road_erase", "road_upgrade", "clear_land"]],
]

var cards := {}  # kind -> Button
var _tab := 0
var _tab_buttons: Array = []
var _row: HBoxContainer
var _title: Label
var _open := false


func _ready() -> void:
	add_theme_stylebox_override("panel", UI.skin("panel", 12, 16))
	UI.anchor(self, 0.5, 1, -430, -262, 430, -8)  # ekrana sığsın (1280 genişlikte İnşa butonuna değmez)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var v := UI.vbox(10)
	add_child(v)
	var head := UI.hbox(8)
	v.add_child(head)
	_title = UI.label("", 22 if Bal.RENDER_3D else 26, UI.ACCENT)
	head.add_child(_title)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(8, 0)
	head.add_child(gap)
	for i in TABS.size():
		var b := UI.button("", _show_tab.bind(i), 0)
		b.add_theme_font_size_override("font_size", 15 if Bal.RENDER_3D else 17)
		_tab_buttons.append(b)
		head.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var x := UI.button("X", close, 44)
	UI.skin_button(x, "red")
	head.add_child(x)
	_row = UI.hbox(12)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_row)
	custom_minimum_size.x = 860  # her sekmede aynı genişlik
	refresh_texts()


func is_open() -> bool:
	return _open


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	_open = true
	visible = true
	# önceki açılışın kayma/boyut artığı kalmasın: çapayı yeniden kur, içeriğe göre küçül
	UI.anchor(self, 0.5, 1, -430, -262, 430, -8)
	size = Vector2.ZERO
	_show_tab(_tab)
	modulate.a = 0.0
	var y := position.y
	position.y = y + 60
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position:y", y, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	Audio.play("click", 0.0)


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false


func refresh_texts() -> void:
	_title.text = tr("SHOP_TITLE")
	for i in TABS.size():
		_tab_buttons[i].text = tr(TABS[i][0])
	if _open:
		_show_tab(_tab)


func _show_tab(i: int) -> void:
	_tab = i
	for j in _tab_buttons.size():
		UI.skin_button(_tab_buttons[j], "yellow" if j == i else "brown")
		_tab_buttons[j].add_theme_color_override("font_color", Color("3a2412") if j == i else UI.TEXT)
		_tab_buttons[j].add_theme_color_override("font_hover_color", Color("3a2412") if j == i else Color.WHITE)
	for c in _row.get_children():
		_row.remove_child(c)  # hemen sök: eski kartlar aynı karede genişliği şişirmesin
		c.queue_free()
	cards.clear()
	for kind in TABS[i][1]:
		var card := _make_card(kind)
		_row.add_child(card)
		cards[kind] = card
	refresh()
	size = Vector2.ZERO  # içeriğe göre yeniden küçül (sekme değişince de)


func _cost(kind: String) -> int:
	match kind:
		"road_erase": return 0
		"road_paint": return Bal.ROAD_TILE_COST
		"road_upgrade": return Bal.ROAD_UPGRADE_COST[GameState.road_level + 1] if GameState.road_level < Bal.ROAD_MAX_LEVEL else -1
		"clear_land": return Bal.CLEAR_COST.forest
	return Bal.BUILDINGS[kind].cost


func _name(kind: String) -> String:
	match kind:
		"road_erase": return "Yol sil / sat"
		"road_paint": return tr("SHOP_ROAD_PAINT")
		"road_upgrade": return tr("SHOP_ROAD_UPGRADE") % mini(GameState.road_level + 1, Bal.ROAD_MAX_LEVEL)
		"clear_land": return tr("SHOP_CLEAR_LAND")
	return tr(Bal.BUILDINGS[kind].name)


func _desc(kind: String) -> String:
	match kind:
		"road_erase": return "Yola tıkla veya sürükle. Hücre başına %d altın geri alırsın." % Bal.ROAD_TILE_REFUND
		"road_paint": return tr("TIP_ROAD_PAINT")
		"road_upgrade": return tr("SHOP_ROAD_UPGRADE_DESC")
		"clear_land": return tr("TIP_CLEAR_LAND") % [Bal.CLEAR_COST.rock, Bal.CLEAR_COST.forest]
	return tr("DESC_" + kind.to_upper())


func _make_card(kind: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(190, 188)
	b.tooltip_text = _desc(kind)
	b.add_theme_stylebox_override("normal", UI.skin("parchment", 12, 8))
	b.add_theme_stylebox_override("hover", UI.skin("parchment", 12, 8, Color(1.12, 1.1, 1.0)))
	b.add_theme_stylebox_override("pressed", UI.skin("parchment", 12, 8, Color(0.85, 0.85, 0.85)))
	b.add_theme_stylebox_override("disabled", UI.skin("parchment", 12, 8, Color(0.7, 0.68, 0.66)))
	b.pressed.connect(func():
		Audio.play("click", 0.05)
		picked.emit(kind))
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.offset_right = -10
	v.offset_top = 8
	v.offset_bottom = -8
	b.add_child(v)
	var pv := preload("res://scripts/ui/build_preview.gd").new()
	pv.kind = kind
	pv.custom_minimum_size = Vector2(0, 74)
	v.add_child(pv)
	var n := UI.label(_name(kind), 17, Color("5a2410"))
	_no_shadow(n)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	var d := UI.label(_desc(kind), 13, Color("3a2a1a"))
	_no_shadow(d)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.max_lines_visible = 2
	d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(d)
	var price := UI.hbox(4)
	price.alignment = BoxContainer.ALIGNMENT_CENTER
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.add_child(Icon.drawn("coin", 22))
	var pl := UI.label("", 18)
	_no_shadow(pl)
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pl.name = "Price"
	price.add_child(pl)
	v.add_child(price)
	b.set_meta("price", pl)
	return b


func _no_shadow(l: Label) -> void:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


## Fiyat etiketleri ve uygunluk (para yetmezse kırmızı + devre dışı).
func refresh() -> void:
	for kind in cards:
		var b: Button = cards[kind]
		var pl: Label = b.get_meta("price")
		var c := _cost(kind)
		if c < 0:
			pl.text = tr("BTN_ROAD_MAX")
			b.disabled = true
			continue
		pl.text = "+%d" % Bal.ROAD_TILE_REFUND if kind == "road_erase" else str(c)
		var ok := GameState.can_afford(c)
		pl.add_theme_color_override("font_color", Color("3a2412") if ok else Color("c0392b"))
		b.disabled = not ok
		b.modulate = Color.WHITE if ok else Color(0.6, 0.58, 0.56, 0.85)  # para yetmiyor: belirgin sönük
