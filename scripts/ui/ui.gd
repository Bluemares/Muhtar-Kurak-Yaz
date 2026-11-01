class_name UI
extends RefCounted
## Kodla arayüz kurmak için küçük yardımcılar ve ortak tema.

const BG := Color(0.13, 0.1, 0.08, 0.92)
const BORDER := Color(0.62, 0.45, 0.24, 0.9)
const ACCENT := Color("f4a261")
const TEXT := Color("fbf3e4")
const BTN := Color("4f8a3a")

static var _theme: Theme
## Net metin fontu. 3D sürümde Alegreya Sans (Google Fonts), pixel sürümde motor varsayılanı.
static var BODY: Font
## Başlık/buton fontu. 3D sürümde Cinzel (Witcher tarzı serif), pixel sürümde pixel font.
static var FONT: Font = preload("res://assets/fonts/cinzel_700.ttf") if Bal.RENDER_3D else preload("res://assets/fonts/muhtar_pixel.fnt")

# 3D sürüm (pixel olmayan) paleti: koyu ceviz panel, eskimiş altın kenar
const DARK := Color(0.08, 0.065, 0.055, 0.9)
const GOLD := Color(0.78, 0.62, 0.36)
const BTN_COLORS := {"green": Color(0.27, 0.42, 0.2), "grey": Color(0.26, 0.26, 0.28), "red": Color(0.55, 0.16, 0.12),
	"yellow": Color(0.66, 0.48, 0.12), "brown": Color(0.36, 0.25, 0.15)}


static func _tex(name: String) -> Texture2D:
	return load("res://assets/ui/%s.png" % name)


## Panel/buton kaplaması. 3D sürümde düz yuvarlak köşeli kutu, pixel sürümde Kenney Pixel UI 9-slice.
## margin: doku kenarı, content: iç boşluk.
static func skin(name: String, margin := 12, content := 14, mod := Color.WHITE) -> StyleBox:
	if Bal.RENDER_3D:
		return _flat(name, content, mod)
	var s := StyleBoxTexture.new()
	s.texture = _tex(name)
	s.set_texture_margin_all(margin)
	s.texture_margin_bottom = margin + (12 if name.begins_with("btn_") and not name.ends_with("_pressed") else 0)
	s.content_margin_left = content
	s.content_margin_right = content + (6 if name.begins_with("btn_") else 0)
	s.content_margin_top = content * 0.6
	s.content_margin_bottom = content * 0.6 + (6 if name.begins_with("btn_") and not name.ends_with("_pressed") else 0)
	s.modulate_color = mod
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return s


static func _flat(name: String, content: float, mod: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(10)
	s.content_margin_left = content
	s.content_margin_right = content
	s.content_margin_top = content * 0.6
	s.content_margin_bottom = content * 0.6
	s.anti_aliasing = true
	if name.begins_with("btn_"):
		var key := name.trim_prefix("btn_").trim_suffix("_pressed")
		var base: Color = BTN_COLORS.get(key, BTN_COLORS.green)
		var pressed := name.ends_with("_pressed")
		s.bg_color = (base.darkened(0.25) if pressed else base) * Color(mod.r, mod.g, mod.b, 1.0)
		s.border_color = GOLD.darkened(0.15)
		s.set_border_width_all(2)
		s.border_width_bottom = 2 if pressed else 4
		s.set_corner_radius_all(8)
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 0 if pressed else 3
		s.shadow_offset = Vector2(0, 2)
		s.content_margin_top = content * 0.45
		s.content_margin_bottom = content * 0.45
	elif name == "parchment":
		s.bg_color = Color(0.93, 0.87, 0.74) * Color(mod.r, mod.g, mod.b, 1.0)
		s.border_color = Color(0.5, 0.36, 0.2)
		s.set_border_width_all(2)
		s.set_corner_radius_all(8)
	elif name == "panel_inlay":
		s.bg_color = Color(0, 0, 0, 0.35)
		s.border_color = Color(GOLD, 0.35)
		s.set_border_width_all(1)
		s.set_corner_radius_all(6)
	else:
		s.bg_color = DARK * Color(mod.r, mod.g, mod.b, 1.0)
		s.border_color = GOLD
		s.set_border_width_all(2)
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = 8
	return s


## Butona renkli pixel kaplama giydirir: "green" | "grey" | "red" | "yellow".
static func skin_button(b: Button, color: String) -> void:
	b.add_theme_stylebox_override("normal", skin("btn_" + color, 12, 14))
	b.add_theme_stylebox_override("hover", skin("btn_" + color, 12, 14, Color(1.15, 1.15, 1.15)))
	b.add_theme_stylebox_override("pressed", skin("btn_%s_pressed" % color, 12, 14))
	b.add_theme_stylebox_override("disabled", skin("btn_green", 12, 14, Color(0.5, 0.55, 0.5)))


static func theme() -> Theme:
	if _theme:
		return _theme
	if BODY == null:
		BODY = load("res://assets/fonts/alegreya_sans_700.ttf") if Bal.RENDER_3D else ThemeDB.fallback_font
	ThemeDB.fallback_font = FONT
	_theme = Theme.new()
	_theme.default_font = FONT
	_theme.default_font_size = 20
	var panel := skin("panel", 12, 16)
	_theme.set_stylebox("panel", "PanelContainer", panel)
	_theme.set_stylebox("panel", "Panel", panel)
	_theme.set_stylebox("normal", "Button", skin("btn_green", 12, 14))
	_theme.set_stylebox("hover", "Button", skin("btn_green", 12, 14, Color(1.15, 1.15, 1.15)))
	_theme.set_stylebox("pressed", "Button", skin("btn_green_pressed", 12, 14))
	_theme.set_stylebox("disabled", "Button", skin("btn_green", 12, 14, Color(0.5, 0.55, 0.5)))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	_theme.set_color("font_color", "Button", TEXT)
	_theme.set_color("font_hover_color", "Button", Color.WHITE)
	_theme.set_color("font_pressed_color", "Button", Color(0.9, 1, 0.9))
	_theme.set_color("font_disabled_color", "Button", Color(0.85, 0.85, 0.85))
	_theme.set_color("font_shadow_color", "Button", Color(0, 0, 0, 0.55))
	_theme.set_constant("shadow_offset_x", "Button", 2)
	_theme.set_constant("shadow_offset_y", "Button", 2)
	_theme.set_constant("icon_max_width", "Button", 26)
	_theme.set_constant("h_separation", "Button", 8)
	_theme.set_color("font_color", "Label", TEXT)
	# bitmap fontta kontur yok: okunaklılık için gölge
	_theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.8))
	_theme.set_constant("shadow_offset_x", "Label", 2)
	_theme.set_constant("shadow_offset_y", "Label", 2)
	_theme.set_stylebox("background", "ProgressBar", skin("panel_inlay", 9, 4))
	_theme.set_stylebox("fill", "ProgressBar", style(Color.WHITE, 2, 0))
	_theme.set_stylebox("panel", "TooltipPanel", skin("panel", 12, 10))
	_theme.set_color("font_color", "TooltipLabel", TEXT)
	for cls in ["OptionButton", "CheckButton"]:
		_theme.set_stylebox("normal", cls, skin("btn_brown", 12, 10))
		_theme.set_stylebox("hover", cls, skin("btn_brown", 12, 10, Color(1.1, 1.1, 1.1)))
		_theme.set_stylebox("pressed", cls, skin("btn_brown_pressed", 12, 10))
	_theme.set_stylebox("panel", "PopupMenu", skin("panel", 12, 10))
	return _theme


## Sahne açılışında siyahtan açılma geçişi.
static func fade_in(parent: Node, dur := 0.5) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var r := ColorRect.new()
	r.color = Color(0.05, 0.03, 0.02)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(r)
	parent.add_child(layer)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, dur)
	tw.tween_callback(layer.queue_free)


static func style(c: Color, radius := 6, margin := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s


static func button(text: String, cb: Callable, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 38)
	b.pressed.connect(Audio.play.bind("click", 0.05))
	b.pressed.connect(cb)
	return b


static func label(text: String, size := 17, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	# 22+ başlık: başlık fontu; altı: net gövde fontu (okunaklılık)
	if size >= 22:
		l.add_theme_font_size_override("font_size", int(round(size * (1.0 if Bal.RENDER_3D else 1.12))))
	else:
		l.add_theme_font_override("font", BODY if BODY else ThemeDB.fallback_font)
		l.add_theme_font_size_override("font_size", maxi(15, size))
	l.add_theme_color_override("font_color", color)
	return l


static func panel() -> PanelContainer:
	return PanelContainer.new()


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


## Kontrolü tek bir çapa noktasına (ax, ay: 0 / 0.5 / 1) ofsetlerle sabitler; içerik büyürse çapadan uzağa büyür.
static func anchor(c: Control, ax: float, ay: float, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN if ax >= 1.0 else (Control.GROW_DIRECTION_BOTH if ax > 0.0 else Control.GROW_DIRECTION_END)
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN if ay >= 1.0 else (Control.GROW_DIRECTION_BOTH if ay > 0.0 else Control.GROW_DIRECTION_END)


## Tam ekran yarı saydam karartma + ortada panel.
static func modal(parent: Node) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var p := panel()
	center.add_child(p)
	var v := vbox(12)
	p.add_child(v)
	# açılış animasyonu
	dim.modulate.a = 0.0
	p.scale = Vector2.ONE * 0.85
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.18)
	p.resized.connect(func(): p.pivot_offset = p.size * 0.5)
	p.create_tween().tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return [dim, v]
