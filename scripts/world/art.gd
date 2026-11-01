class_name Art
extends RefCounted
## Kenney Tiny Town / Tiny Farm (CC0) atlas yardımcıları ve parçacık efekti fabrikası.
## Atlaslar 4x büyütülmüş: her tile atlasta 64 px, sahnede genelde 32 px (hücre = 2x2 tile).

const TOWN := preload("res://assets/tiles/town.png")
const FARM := preload("res://assets/tiles/farm.png")
## Yatay aynalanmış atlaslar: negatif bölgeyle çizim mipmap'te bozuk (kare) göründüğü için.
const TOWN_FLIP := preload("res://assets/tiles/town_flip.png")
const FARM_FLIP := preload("res://assets/tiles/farm_flip.png")
const TS := 64.0  # atlas içindeki tile boyu
const COLS := 12

# --- Tiny Town indeksleri ---
const T_GRASS := [0, 1, 2]
const T_TREES_GREEN := [4, 5, 16, 28]
const T_TREES_DRY := [3, 15, 27]
const T_DIRT := [25, 40, 41]
const T_COBBLE := 109  # düz taş döşeme (yol sv2)
const T_WELL := 104
const T_BUCKET := 131
const T_SIGN := 83
const T_LOG := 106
const T_HAY := 93
# --- Tiny Farm indeksleri ---
const F_SOIL_A := [48, 49, 50, 51]
const F_SOIL_B := [60, 61, 62, 63]
## Seviyeye göre ekin: [filiz, büyüyor, olgun, kurumuş]
const F_CROPS := [[], [64, 65, 66, 67], [28, 29, 30, 31], [40, 41, 42, 43]]
const F_FARMERS := [108, 109]
const F_CRITTERS := [122, 122, 120, 121]
const F_DECOR := [83, 77, 89, 39]
const F_ROCK := 89
const F_TROUGH := [110, 111]

## Çiftçi kıyafet paletleri: [tulum, gömlek]
const FARMER_PALETTES := [
	[Color("52607c"), Color("f28462")], [Color("3e7a3c"), Color("f2d462")], [Color("7a3c3c"), Color("8fc4f2")],
	[Color("4a4a8a"), Color("f2f2f2")], [Color("8a6a3c"), Color("c46ad1")], [Color("2f5f6f"), Color("f2a0b0")],
]
static var _farmers := {}
static var _soft: Texture2D
static var _grass: Texture2D


## Kıyafet/ten rengi değiştirilmiş çiftçi dokusu (önbellekli).
static func farmer(idx: int, variant: int, dark: bool, flip: bool) -> Texture2D:
	var key := "%d_%d_%s_%s" % [idx, variant, dark, flip]
	if _farmers.has(key):
		return _farmers[key]
	var img := FARM.get_image().get_region(Rect2i(region(idx)))
	img.decompress()
	var pal: Array = FARMER_PALETTES[variant]
	var swaps := {Color("52607c").to_html(false): pal[0], Color("f28462").to_html(false): pal[1]}
	if dark:
		swaps[Color("f7c282").to_html(false)] = Color("b97a4e")
		swaps[Color("e19a65").to_html(false)] = Color("9a603a")
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				var k := c.to_html(false)
				if swaps.has(k):
					img.set_pixel(x, y, Color(swaps[k], c.a))
	if flip:
		img.flip_x()
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_farmers[key] = t
	return t


## Tek çimen tile'ı ayrı doku: draw_texture_rect(tile=true) ile tek komutta büyük alan döşenir.
static func grass() -> Texture2D:
	if _grass:
		return _grass
	var img := TOWN.get_image().get_region(Rect2i(region(T_GRASS[0])))
	img.decompress()
	img.generate_mipmaps()
	_grass = ImageTexture.create_from_image(img)
	return _grass


static func region(idx: int) -> Rect2:
	return Rect2((idx % COLS) * TS, (idx / COLS) * TS, TS, TS)


static func tile(ci: CanvasItem, sheet: Texture2D, idx: int, r: Rect2, mod := Color.WHITE, flip := false) -> void:
	if flip:
		var col := COLS - 1 - idx % COLS
		var reg := Rect2(col * TS, (idx / COLS) * TS, TS, TS)
		ci.draw_texture_rect_region(TOWN_FLIP if sheet == TOWN else FARM_FLIP, r, reg, mod)
		return
	ci.draw_texture_rect_region(sheet, r, region(idx), mod)


## Kenarı yumuşak beyaz daire; parçacıklar ve gölgeler için.
static func soft() -> Texture2D:
	if _soft:
		return _soft
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 64
	t.height = 64
	_soft = t
	return _soft


static func _ramp(cols: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(range(cols.size()).map(func(i): return float(i) / (cols.size() - 1)))
	g.colors = PackedColorArray(cols)
	return g


static func _base(amount: int, life: float, extents: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.texture = soft()
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.local_coords = false
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	return p


static func fire(extents: Vector2) -> CPUParticles2D:
	var p := _base(int(clampf(extents.x * extents.y / 40.0, 24, 90)), 0.9, extents)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = m
	p.direction = Vector2.UP
	p.spread = 18
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 20
	p.initial_velocity_max = 55
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.8
	p.scale_amount_curve = _curve([1.0, 0.7, 0.0])
	p.color_ramp = _ramp([Color(1, 0.8, 0.3, 0.55), Color(1, 0.42, 0.06, 0.5), Color(0.7, 0.12, 0.03, 0.3), Color(0.2, 0.03, 0.0, 0)])
	p.z_index = 3
	return p


static func smoke(extents: Vector2, dark := 0.25) -> CPUParticles2D:
	var p := _base(18, 2.6, extents)
	p.direction = Vector2(0.3, -1)
	p.spread = 15
	p.gravity = Vector2(8, -18)
	p.initial_velocity_min = 15
	p.initial_velocity_max = 30
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.scale_amount_curve = _curve([0.5, 1.2, 1.8])
	p.color_ramp = _ramp([Color(dark, dark, dark, 0.0), Color(dark, dark, dark, 0.55), Color(dark + 0.2, dark + 0.2, dark + 0.2, 0.0)])
	p.z_index = 4
	return p


static func embers(extents: Vector2) -> CPUParticles2D:
	var p := _base(14, 1.6, extents)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = m
	p.direction = Vector2.UP
	p.spread = 40
	p.gravity = Vector2(10, -30)
	p.initial_velocity_min = 30
	p.initial_velocity_max = 70
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.1
	p.color = Color(1, 0.7, 0.2)
	p.z_index = 5
	return p


## Tek seferlik toz bulutu (inşaat, yerleştirme).
static func dust_burst(extents: Vector2) -> CPUParticles2D:
	var p := _base(26, 0.9, extents)
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector2.UP
	p.spread = 180
	p.gravity = Vector2(0, 30)
	p.initial_velocity_min = 25
	p.initial_velocity_max = 70
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.6
	p.color_ramp = _ramp([Color(0.85, 0.75, 0.55, 0.8), Color(0.8, 0.7, 0.5, 0.0)])
	p.z_index = 4
	p.finished.connect(p.queue_free)
	return p


## Tek seferlik parıltı (yükseltme, onarım, ilaçlama).
static func sparkle(extents: Vector2, col: Color) -> CPUParticles2D:
	var p := _base(22, 1.0, extents)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = m
	p.one_shot = true
	p.explosiveness = 0.8
	p.direction = Vector2.UP
	p.spread = 60
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 30
	p.initial_velocity_max = 80
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.25
	p.color_ramp = _ramp([Color(col, 1.0), Color(col, 0.0)])
	p.z_index = 6
	p.finished.connect(p.queue_free)
	return p


static func _curve(vals: Array) -> Curve:
	var c := Curve.new()
	c.max_value = 2.0
	for i in vals.size():
		c.add_point(Vector2(float(i) / (vals.size() - 1), vals[i]))
	return c
