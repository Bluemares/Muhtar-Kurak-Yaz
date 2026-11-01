class_name HowToPlay
extends RefCounted
## "Nasıl Oynanır": oyunun özü 10 kısa kartta, her biri bir ikonla. Ana menü ve duraklatma menüsünden açılır.

## [ikon, renk, başlık anahtarı, metin anahtarı]; ikon "crop_wheat" ise ürün ikonu çizilir.
const CARDS := [
	["heart", Color("b8423a"), "HOW_GOAL_T", "HOW_GOAL_D"],
	["food", Color("6a8a2a"), "HOW_PRODUCE_T", "HOW_PRODUCE_D"],
	["road", Color("8a6a3a"), "HOW_ROAD_T", "HOW_ROAD_D"],
	["crop_wheat", Color("a8862a"), "HOW_CROP_T", "HOW_CROP_D"],
	["fire", Color("c0502a"), "HOW_FIRE_T", "HOW_FIRE_D"],
	["drip", Color("2f6fa8"), "HOW_PREVENT_T", "HOW_PREVENT_D"],
	["sell", Color("a8862a"), "HOW_MARKET_T", "HOW_MARKET_D"],
	["upgrade", Color("4f8a3a"), "HOW_COP_T", "HOW_COP_D"],
	["move", Color("4a6a8a"), "HOW_CONTROLS_T", "HOW_CONTROLS_D"],
	["sun", Color("b08b3a"), "HOW_CLIMATE_T", "HOW_CLIMATE_D"],
]  # 10 kart, 2 sütun


static func open(parent: Node) -> void:
	var m := UI.modal(parent)
	var v: VBoxContainer = m[1]
	v.custom_minimum_size = Vector2(900, 0)
	var title := UI.label(TranslationServer.translate("MENU_HOWTO"), 30, UI.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(940,440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	scroll.add_child(grid)
	for c in CARDS:
		grid.add_child(_card(c))
	var close := UI.button(TranslationServer.translate("BTN_CLOSE"), m[0].queue_free, 200)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(close)


static func _card(c: Array) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.skin("panel_inlay", 8, 10))
	p.custom_minimum_size = Vector2(440, 0)
	var h := UI.hbox(12)
	p.add_child(h)
	# renkli yuvarlak rozet içinde ikon
	var badge := Panel.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := UI.style(c[1], 28, 0)
	st.border_color = UI.GOLD if Bal.RENDER_3D else Color("2b1d14")
	st.set_border_width_all(2)
	badge.add_theme_stylebox_override("panel", st)
	var ic: Control
	if String(c[0]).begins_with("crop_"):
		ic = preload("res://scripts/ui/crop_icon.gd").new()
		ic.crop = String(c[0]).trim_prefix("crop_")
	else:
		ic = Icon.drawn(c[0], 38)
	ic.position = Vector2(9, 9)
	ic.size = Vector2(38, 38)
	badge.add_child(ic)
	h.add_child(badge)
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(TranslationServer.translate(c[2]), 18, UI.ACCENT))
	var d := UI.label(TranslationServer.translate(c[3]), 15)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(350, 0)
	tv.add_child(d)
	h.add_child(tv)
	return p
