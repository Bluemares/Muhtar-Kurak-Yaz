class_name Building
extends Node2D
## Veri odaklı bina. Tip özellikleri Bal.BUILDINGS tablosundan gelir. Görsel Kenney tile'larıyla çizilir (Art).

var C: int = Bal.CELL

var type := "field"
var level := 1
var cell := Vector2i.ZERO
var size := Vector2i.ONE
## normal | burning | ruined | moving
var state := "normal"
var pest := false
var drip := false  # damla sulama kurulu mu (tarla)
var near_river := false  # kuyu nehre yakın mı (su bonusu)
var protect_until := -1.0
var harvest_progress := 0.0
var farm_phase := "prepare"
var farm_steps := 0
var soil_water := 0.0
var pending_harvest := 0.0
var worker = null
var move_timer := 0.0
var selected := false
var hovered := false
var _t := 0.0
var _pop := 1.0
var crop_ready := false  # ürün olgun, toplanmayı bekliyor (balon)
var _ready_t := 0.0
var _drop := 0.0  # düşme animasyonu yüksekliği (px)
var crop := "veg"  # tarla ürünü (Bal.CROPS)
var rot := 0:
	set(value):
		rot = posmod(value, 4)
		if Bal.BUILDINGS.has(type):
			size = footprint(type, rot)
var burst_seq := 0  # 3D görüntü katmanı tek seferlik efektleri bundan izler
var burst_kind := ""
var _variant := 0
var _fire: CPUParticles2D
var _smoke: CPUParticles2D
var _embers: CPUParticles2D
var _light: PointLight2D
var _fire_light: PointLight2D


static func footprint(kind: String, rotation: int) -> Vector2i:
	var base: Vector2i = Bal.BUILDINGS[kind].size
	return Vector2i(base.y, base.x) if rotation % 2 == 1 else base


func setup(t: String, c: Vector2i) -> void:
	type = t
	size = Bal.BUILDINGS[t].size
	set_cell(c)


func data() -> Dictionary:
	return Bal.BUILDINGS[type]


func set_cell(c: Vector2i) -> void:
	cell = c
	position = Vector2(c) * C
	near_river = Terrain.river_distance(c) <= Bal.RIVER_WELL_DIST


## Nehir kenarı kuyu bonusu: kuraklıkla nehir kurudukça azalır.
func river_bonus() -> float:
	return Bal.RIVER_WELL_BONUS * (1.0 - GameState.drought()) if near_river and type == "well" else 0.0


func rect() -> Rect2i:
	return Rect2i(cell, size)


func center() -> Vector2:
	return position + Vector2(size) * C * 0.5


## Yol şartı var mı (COP31 ve koruluk hariç).
func needs_road() -> bool:
	return not type in Bal.NO_ROAD_NEEDED


## Çalışıyor mu: sağlam ve (gerekiyorsa) yola bitişik.
func is_operational() -> bool:
	return state == "normal" and (not needs_road() or road_connected())


func is_protected() -> bool:
	return GameState.time < protect_until


func needs_worker() -> bool:
	return data().workers > 0 and worker == null and state != "ruined" and road_connected()


func has_working_worker() -> bool:
	return is_operational() and is_instance_valid(worker) and worker.job == self and worker.state == Worker.State.WORKING and worker.carry_stage == 0


func can_move() -> bool:
	return data().movable and state == "normal"


func upgrade_cost() -> int:
	var costs: Array = data().upgrade
	if level + 1 >= costs.size():
		return -1
	return costs[level + 1]


func repair_cost() -> int:
	var c := int(data().cost * Bal.REPAIR_FACTOR) if data().cost > 0 else 60
	return c / 2 if GameState.has_policy("crop_insurance") else c


## Tarla büyümesi. Hasat olursa verimi döner.
func is_crop() -> bool:
	return type == "field" or type == "greenhouse"


func harvest_time() -> float:
	return (Bal.GREENHOUSE_TIME if type == "greenhouse" else Bal.HARVEST_TIME[level]) * Bal.CROPS[crop].time


func harvest_yield() -> float:
	return (Bal.GREENHOUSE_YIELD if type == "greenhouse" else Bal.HARVEST_YIELD[level]) * Bal.CROPS[crop].yield


## Su çarpanı (ürüne göre; tarla ve sera).
func crop_water() -> float:
	return Bal.CROPS[crop].water if is_crop() else 1.0


## Bina kenarları arası boşluk (hücre).
func gap_to(o) -> float:
	var ra := rect()
	var rb: Rect2i = o.rect()
	var dx := maxi(0, maxi(rb.position.x - ra.end.x, ra.position.x - rb.end.x))
	var dy := maxi(0, maxi(rb.position.y - ra.end.y, ra.position.y - rb.end.y))
	return sqrt(dx * dx + dy * dy)


## Yola bitişik mi (çevresindeki herhangi bir hücre yol): ürün pazara kolay taşınır.
func road_connected() -> bool:
	var r := rect().grow(1)
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			var c := Vector2i(x, y)
			if not rect().has_point(c) and (x == r.position.x or x == r.end.x - 1 or y == r.position.y or y == r.end.y - 1):
				if GameState.is_road_cell(c):
					return true
	return false


func near_grove() -> bool:
	for o in GameState.buildings:
		if o != self and o.type == "grove" and o.is_operational() and gap_to(o) <= Bal.GROVE_DIST:
			return true
	return false


func grow(dt: float) -> float:
	if not is_crop():
		return 0.0
	if crop_ready:
		_ready_t = minf(Bal.AUTO_HARVEST_DELAY,_ready_t+dt)
		return 0.0
	if farm_phase != "grow": return 0.0
	if drip and GameState.water_coverage > 0.0: soil_water = 1.0
	soil_water = maxf(0.0, soil_water - dt / 45.0)
	dt *= 1.0 if soil_water >= 0.25 else lerpf(0.15, 1.0, soil_water / 0.25)
	var need: float = harvest_time()
	harvest_progress += dt
	if harvest_progress >= need:
		harvest_progress = need
		crop_ready = true
		_ready_t = 0.0
	return 0.0


## Olgun ürünü toplar (mult: dokunma bonusu). Verimi döner.
func take_harvest(mult: float) -> float:
	if not crop_ready:
		return 0.0
	crop_ready = false
	harvest_progress = 0.0
	var y: float = harvest_yield() * mult * (1.15 if GameState.has_policy("seed_bank") else 1.0) * (Bal.ROAD_YIELD_MULT if road_connected() else 1.0)
	if pest:
		y *= Bal.PEST_YIELD_MULT
	return y


## Yukarıdan düşerek yere oturma (inşaat başlangıcı).
func drop_in() -> void:
	_drop = 260.0
	var tw := create_tween()
	tw.tween_property(self, "_drop", 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		burst("dust")
		Audio.play("collapse", 0.1)
		var g = get_tree().get_first_node_in_group("game")
		if g:
			g.camera.shake(3.5, 0.25))


func start_move(new_cell: Vector2i) -> void:
	set_cell(new_cell)
	state = "moving"
	move_timer = Bal.MOVE_DURATION
	burst("dust")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_variant = absi(cell.x * 7 + cell.y * 13) % 2
	var ext := Vector2(size) * C * 0.38
	var mid := Vector2(size) * C * 0.5
	_fire = Art.fire(ext)
	_smoke = Art.smoke(ext)
	_embers = Art.embers(ext)
	for p in [_smoke, _fire, _embers]:
		p.position = mid
		p.emitting = false
		add_child(p)
	# akşam yanan pencere ışığı (ev, COP31, itfaiye) ve yangın parıltısı
	if type in ["house", "cop31", "fire_station", "greenhouse"]:
		_light = _make_light(Color(1.0, 0.8, 0.45), Vector2(size) * C * 2.4)
		_light.position = mid + Vector2(0, C * 0.15)
	_fire_light = _make_light(Color(1.0, 0.45, 0.15), Vector2(size) * C * 3.2)
	_fire_light.position = mid


## Tek seferlik efekt: "dust" | "upgrade" | "repair" | "spray"
func burst(kind: String) -> void:
	burst_seq += 1
	burst_kind = kind
	if not is_inside_tree():
		return
	var ext := Vector2(size) * C * 0.4
	var p: CPUParticles2D
	match kind:
		"dust": p = Art.dust_burst(ext)
		"upgrade": p = Art.sparkle(ext, Color.GOLD)
		"repair": p = Art.sparkle(ext, Color.AQUAMARINE)
		"water": p = Art.sparkle(ext, Color(0.4, 0.75, 1.0))
		_: p = Art.sparkle(ext, Color.GREEN_YELLOW)
	p.position = Vector2(size) * C * 0.5
	add_child(p)
	p.emitting = true
	pop()


func pop() -> void:
	_pop = 1.18
	create_tween().tween_property(self, "_pop", 1.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _make_light(col: Color, px: Vector2) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = Art.soft()
	l.texture_scale = maxf(px.x, px.y) / 64.0
	l.color = col
	l.energy = 0.0
	l.visible = false
	add_child(l)
	return l


func _process(delta: float) -> void:
	_t += delta
	var night := GameState.night_factor()
	if _light:
		_light.energy = night * 1.1 if state == "normal" else 0.0
		_light.visible = _light.energy > 0.01
	if _fire_light:
		_fire_light.energy = (0.6 + night * 1.4) * (0.85 + 0.15 * sin(_t * 13.0)) if state == "burning" else 0.0
		_fire_light.visible = _fire_light.energy > 0.01
	if state == "moving" and not get_tree().paused:
		move_timer -= delta
		if move_timer <= 0.0:
			state = "normal"
			burst("dust")
	if _fire:
		_fire.emitting = state == "burning"
		_embers.emitting = state == "burning"
		_smoke.emitting = state == "burning" or state == "ruined"
	queue_redraw()


# ---------------- Çizim ----------------

const LAYOUTS := {
	"house": [[[52, 54], [84, 87]], [[48, 50], [88, 91]]],
	"fire_station": [[[52, 53, 53, 54], [113, 114, 113, 114]]],
	"cop31": [[[96, 97, 97, 98], [120, 121, 121, 122], [99, 100, 100, 101], [126, 113, 114, 126]]],
}


func _draw() -> void:
	var w := Vector2(size) * C
	var mid := w * 0.5
	if _drop > 0.0:
		# yere düşen gölge büyür
		var k := 1.0 - _drop / 260.0
		draw_texture_rect(Art.soft(), Rect2(Vector2(w.x * (0.5 - 0.45 * k), w.y * 0.6), Vector2(w.x * 0.9 * k, w.y * 0.5)), false, Color(0, 0, 0, 0.4 * k))
	draw_set_transform(mid * (1.0 - _pop) - Vector2(0, _drop), 0.0, Vector2.ONE * _pop)
	var mod := Color.WHITE
	match state:
		"moving": mod = Color(1, 1, 1, 0.5)
		"ruined": mod = Color(0.32, 0.29, 0.27)
		"burning": mod = Color(1.0, 0.62, 0.45).lerp(Color(0.6, 0.3, 0.2), 0.5 + 0.5 * sin(_t * 7.0))
	# yumuşak gölge
	draw_texture_rect(Art.soft(), Rect2(Vector2(w.x * 0.08, w.y * 0.55), Vector2(w.x * 0.95, w.y * 0.55)), false, Color(0, 0, 0, 0.35 * mod.a))
	var T := C * 0.5
	match type:
		"field": _draw_field(T, mod)
		"greenhouse": _draw_greenhouse(w, T, mod)
		"water_tower": _draw_tower(w, mod)
		"grove": _draw_grove(w, T, mod)
		"well": _draw_well(w, T, mod)
		"cop31":
			_draw_layout(LAYOUTS.cop31[0], T, mod)
			_draw_cop_plaque(w, T, mod)
			_draw_flag(Vector2(w.x - 10, T * 0.5), Color("1d70b8"), mod)
			_draw_flag(Vector2(8, T * 0.5), Color("2a9d8f") if level >= 2 else Color("e9c46a"), mod)
			if level >= 3:
				_draw_flag(Vector2(w.x * 0.5 - 4, 2), Color("e76f51"), mod)
		"fire_station":
			_draw_layout(LAYOUTS.fire_station[0], T, mod)
			_draw_station_extras(w, T, mod)
		_:
			var variants: Array = LAYOUTS[type]
			_draw_layout(variants[_variant % variants.size()], T, mod)
	if state == "ruined":
		for i in 3:
			Art.tile(self, Art.FARM, Art.F_ROCK, Rect2(Vector2(6 + i * w.x * 0.3, w.y * 0.55), Vector2(T, T) * 0.9), Color(0.6, 0.55, 0.5))
	if state == "moving":
		_draw_scaffold(w)
	if pest:
		_draw_pests(w)
	if is_protected() and type == "field":
		draw_circle(Vector2(w.x - 12, 12), 8, Color(0.15, 0.6, 0.25, 0.95))
		draw_circle(Vector2(w.x - 12, 12), 4, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	_draw_overlay(w)


## COP31 tabelası: mavi pano, beyaz pixel yazı, yaprak simgesi.
func _draw_cop_plaque(w: Vector2, T: float, mod: Color) -> void:
	var r := Rect2(Vector2(w.x * 0.18, T * 1.55), Vector2(w.x * 0.64, T * 0.8))
	draw_rect(r.grow(2), Color(0.17, 0.11, 0.08, mod.a))
	draw_rect(r, Color(0.11, 0.44, 0.72, mod.a))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color(0.37, 0.69, 0.94, mod.a))
	draw_string(ThemeDB.fallback_font, r.position + Vector2(0, r.size.y * 0.78), "COP31", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(T * 0.62), Color(1, 1, 1, mod.a))


## İtfaiye: kırmızı-beyaz şerit, garajda park etmiş araç, hortum makarası, dönen siren.
func _draw_station_extras(w: Vector2, T: float, mod: Color) -> void:
	var band := Rect2(Vector2(0, T - 2), Vector2(w.x, 7))
	draw_rect(band, Color(0.85, 0.12, 0.1, mod.a))
	for i in int(w.x / 12):
		draw_rect(Rect2(band.position + Vector2(i * 12 + 6, 0), Vector2(6, 7)), Color(1, 1, 1, mod.a))
	# 1. bölme: park etmiş itfaiye aracı (yangında yok — yolda)
	var game = get_tree().get_first_node_in_group("game") if is_inside_tree() else null
	var away: bool = game != null and game.fire_active
	if not away:
		var b := Rect2(Vector2(T * 0.3, T * 1.35), Vector2(T * 1.4, T * 0.55))
		draw_rect(b, Color(0.76, 0.07, 0.12, mod.a))
		draw_rect(Rect2(b.position + Vector2(b.size.x * 0.65, 3), Vector2(b.size.x * 0.28, b.size.y * 0.4)), Color(0.74, 0.88, 1.0, mod.a))
		draw_rect(Rect2(b.position + Vector2(0, b.size.y * 0.55), Vector2(b.size.x, 3)), Color(1, 0.85, 0.2, mod.a))
	# 2. bölme: hortum makarası
	var c := Vector2(T * 3.0, T * 1.55)
	draw_circle(c, T * 0.32, Color(0.25, 0.2, 0.18, mod.a))
	draw_arc(c, T * 0.26, 0, TAU, 16, Color(0.8, 0.25, 0.15, mod.a), 3.0)
	draw_arc(c, T * 0.16, 0, TAU, 12, Color(0.8, 0.25, 0.15, mod.a), 3.0)
	# siren
	if state == "normal":
		var on := int(_t * 3.0) % 2 == 0
		draw_rect(Rect2(Vector2(w.x * 0.5 - 6, -4), Vector2(12, 7)), Color(0.2, 0.2, 0.22, mod.a))
		draw_circle(Vector2(w.x * 0.5, -5), 4.5, Color(1, 0.2, 0.2, mod.a) if on else Color(0.3, 0.45, 1.0, mod.a))


func _draw_layout(rows: Array, T: float, mod: Color) -> void:
	for y in rows.size():
		for x in rows[y].size():
			Art.tile(self, Art.TOWN, rows[y][x], Rect2(Vector2(x, y) * T, Vector2(T, T)), mod)


func _draw_field(T: float, mod: Color) -> void:
	var crops: Array = Art.F_CROPS[level]
	var ripe := clampf(harvest_progress / float(Bal.HARVEST_TIME[level]), 0.0, 1.0)
	var parched := GameState.drought() > 0.6 and not has_working_worker()
	for y in 4:
		var soil: Array = Art.F_SOIL_A if y % 2 == 0 else Art.F_SOIL_B
		for x in 4:
			var r := Rect2(Vector2(x, y) * T, Vector2(T, T))
			Art.tile(self, Art.FARM, soil[x], r, mod)
			var h := (x * 31 + y * 17 + cell.x * 5) % 7
			var stage := clampi(int(ripe * 3.0 + (h - 3) * 0.12), 0, 2)
			var idx: int = crops[stage]
			if state == "ruined" or (pest and h % 2 == 0) or (parched and h % 3 == 0):
				idx = crops[3]
			var sway := sin(_t * 2.0 + x + y * 0.7) * 1.5
			Art.tile(self, Art.FARM, idx, Rect2(r.position + Vector2(sway, -4), r.size), mod)
	if drip and state != "ruined":
		# damla sulama boruları + damlalar
		for y in 4:
			var py := (y + 0.88) * T
			draw_line(Vector2(3, py), Vector2(T * 4 - 3, py), Color(0.2, 0.45, 0.85, 0.9 * mod.a), 2.0)
			for k in 4:
				var ph := fmod(_t * 1.3 + k * 0.37 + y * 0.21, 1.0)
				draw_circle(Vector2((k + 0.5) * T, py + 2.0 + ph * 5.0), 1.8 * (1.0 - ph), Color(0.55, 0.85, 1.0, 0.9 * mod.a))


func _draw_greenhouse(w: Vector2, T: float, mod: Color) -> void:
	var ripe := clampf(harvest_progress / harvest_time(), 0.0, 1.0)
	for x in 4:
		var r := Rect2(Vector2(x * T, T * 0.5), Vector2(T, T))
		Art.tile(self, Art.FARM, Art.F_SOIL_A[x], Rect2(Vector2(x * T, T * 0.6), Vector2(T, T * 0.8)), mod)
		Art.tile(self, Art.FARM, [40, 41, 42][clampi(int(ripe * 3.0 + (x % 2) * 0.3), 0, 2)], Rect2(r.position + Vector2(0, -4), r.size * 0.9), mod)
	# cam çatı ve çerçeve
	var glass := Rect2(Vector2(2, 4), w - Vector2(4, 6))
	draw_rect(glass, Color(0.7, 0.9, 1.0, 0.32 * mod.a))
	draw_rect(glass, Color(1, 1, 1, 0.85 * mod.a), false, 2.0)
	for i in range(1, 4):
		draw_line(Vector2(glass.position.x + glass.size.x * i / 4.0, glass.position.y), Vector2(glass.position.x + glass.size.x * i / 4.0, glass.end.y), Color(1, 1, 1, 0.6 * mod.a), 1.5)
	draw_line(Vector2(glass.position.x, glass.position.y + 10), Vector2(glass.end.x, glass.position.y + 10), Color(1, 1, 1, 0.6 * mod.a), 1.5)
	draw_line(glass.position + Vector2(10, 18), glass.position + Vector2(26, 6), Color(1, 1, 1, 0.55 * mod.a), 2.0)


func _draw_tower(w: Vector2, mod: Color) -> void:
	var leg := Color(0.45, 0.3, 0.16, mod.a)
	for x in [12.0, w.x - 12.0]:
		draw_line(Vector2(x, w.y - 4), Vector2(w.x * 0.5 + (x - w.x * 0.5) * 0.55, 26), leg, 4.0)
	draw_line(Vector2(14, w.y - 18), Vector2(w.x - 14, w.y - 18), leg, 3.0)
	draw_line(Vector2(16, w.y - 18), Vector2(w.x - 18, 30), Color(leg, 0.7), 2.0)
	Art.tile(self, Art.FARM, 85, Rect2(Vector2(w.x * 0.5 - 22, -10), Vector2(44, 44)), mod)
	draw_rect(Rect2(w.x * 0.5 - 14, 8, 28, 5), Color(0.35, 0.65, 0.95, 0.9 * mod.a))


func _draw_grove(w: Vector2, T: float, mod: Color) -> void:
	# sulanan koruluk kuraklıkta bile yeşil kalır
	for p in [[Vector2(-2, 6), 16], [Vector2(T * 0.9, 2), 4], [Vector2(T * 0.4, T * 0.8), 28]]:
		draw_texture_rect(Art.soft(), Rect2(p[0] + Vector2(4, T * 0.8), Vector2(T, T * 0.4)), false, Color(0, 0, 0, 0.3 * mod.a))
		Art.tile(self, Art.TOWN, p[1], Rect2(p[0], Vector2(T, T) * 1.15), mod)


func _draw_well(w: Vector2, T: float, mod: Color) -> void:
	draw_texture_rect(Sprites.well(), Rect2(Vector2(0, -6), w), false, mod)
	if level >= 2:
		Art.tile(self, Art.TOWN, Art.T_BUCKET, Rect2(Vector2(w.x - T * 0.7, w.y - T * 0.75), Vector2(T, T) * 0.7), mod)
	if level >= 3:
		Art.tile(self, Art.FARM, Art.F_TROUGH[0], Rect2(Vector2(-T * 0.2, w.y - T * 0.7), Vector2(T, T) * 0.7), mod)
		Art.tile(self, Art.FARM, Art.F_TROUGH[1], Rect2(Vector2(T * 0.5, w.y - T * 0.7), Vector2(T, T) * 0.7), mod)


func _draw_flag(base: Vector2, col: Color, mod: Color) -> void:
	draw_line(base, base - Vector2(0, 30), Color(0.9, 0.9, 0.9, mod.a), 2.0)
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(base + Vector2(i * 4.0, -30 + sin(_t * 5.0 - i * 0.8) * 1.5))
	for i in range(5, -1, -1):
		pts.append(base + Vector2(i * 4.0, -18 + sin(_t * 5.0 - i * 0.8) * 1.5))
	draw_colored_polygon(pts, Color(col, mod.a))


func _draw_scaffold(w: Vector2) -> void:
	var c := Color(0.55, 0.38, 0.2, 0.9)
	for x in [4.0, w.x * 0.5, w.x - 4.0]:
		draw_line(Vector2(x, 4), Vector2(x, w.y - 4), c, 3.0)
	for y in [w.y * 0.33, w.y * 0.66]:
		draw_line(Vector2(4, y), Vector2(w.x - 4, y), c, 3.0)
	draw_line(Vector2(4, 4), Vector2(w.x - 4, w.y - 4), Color(c, 0.6), 2.0)


func _draw_pests(w: Vector2) -> void:
	for i in 9:
		var p := Vector2(fmod(i * 41.0 + _t * 14.0 * (1 + i % 2), w.x - 12) + 6, fmod(i * 29.0 + 7.0 + sin(_t * 6 + i) * 6, w.y - 12) + 6)
		draw_circle(p, 3.5, Color(0.12, 0.1, 0.05))
		draw_line(p + Vector2(-4, -3), p + Vector2(4, 3), Color(0.12, 0.1, 0.05, 0.6), 1.0)


## Ölçeklenmeyen bilgi katmanı: seviye yıldızları, işçi rozeti, hasat çubuğu, seçim.
func _draw_overlay(w: Vector2) -> void:
	if data().max_level > 1:
		for i in level:
			_star(Vector2(10 + i * 13, w.y - 9), 5.0)
	if data().workers > 0:
		var txt := "%d/%d" % [1 if has_working_worker() else 0, data().workers]
		var p := Vector2(w.x - 32, w.y - 18)
		draw_rect(Rect2(p, Vector2(28, 15)), Color(0, 0, 0, 0.65))
		draw_string(ThemeDB.fallback_font, p + Vector2(4, 12), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	if crop_ready and state == "normal":
		# hasat balonu: zıplar, tıklanınca toplanır
		var by := -26.0 - absf(sin(_t * 4.0)) * 6.0
		var bc := Vector2(w.x * 0.5, by)
		draw_circle(bc + Vector2(2, 3), 19, Color(0, 0, 0, 0.3))
		draw_circle(bc, 19, Color(1, 1, 1, 0.95))
		draw_colored_polygon(PackedVector2Array([bc + Vector2(-6, 15), bc + Vector2(6, 15), bc + Vector2(0, 24)]), Color(1, 1, 1, 0.95))
		Art.tile(self, Art.FARM, 68 if type == "field" else 44, Rect2(bc - Vector2(14, 14), Vector2(28, 28)))
		var left := 1.0 - _ready_t / Bal.AUTO_HARVEST_DELAY
		draw_arc(bc, 21, -PI / 2, -PI / 2 + TAU * left, 24, Color(0.95, 0.75, 0.2), 3.0)
	elif is_crop() and state == "normal":
		var pr := harvest_progress / harvest_time()
		draw_rect(Rect2(Vector2(6, -8), Vector2(w.x - 12, 6)), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(Vector2(7, -7), Vector2((w.x - 14) * pr, 4)), Color(0.95, 0.85, 0.3))
	if state == "moving":
		var mp := 1.0 - move_timer / Bal.MOVE_DURATION
		draw_rect(Rect2(Vector2(6, w.y * 0.5 - 4), Vector2(w.x - 12, 8)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(Vector2(7, w.y * 0.5 - 3), Vector2((w.x - 14) * mp, 6)), Color(1, 1, 1, 0.95))
	if selected:
		_corners(Rect2(Vector2.ZERO, w).grow(2.0 + sin(_t * 6.0) * 1.5), Color.YELLOW, 3.0)
	elif hovered:
		_corners(Rect2(Vector2.ZERO, w).grow(1), Color(1, 1, 1, 0.7), 2.0)


func _corners(r: Rect2, col: Color, wd: float) -> void:
	var l := minf(r.size.x, r.size.y) * 0.25
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var sx := 1.0 if c.x == r.position.x else -1.0
		var sy := 1.0 if c.y == r.position.y else -1.0
		draw_line(c, c + Vector2(l * sx, 0), col, wd)
		draw_line(c, c + Vector2(0, l * sy), col, wd)


func _star(c: Vector2, rad: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * (rad if i % 2 == 0 else rad * 0.45))
	draw_colored_polygon(pts, Color.GOLD)
	pts.append(pts[0])
	draw_polyline(pts, Color(0.4, 0.25, 0, 0.8), 1.0)




func reset_crop_work() -> void:
	if not is_crop(): return
	farm_phase = "deliver" if pending_harvest > 0.0 else "prepare"
	farm_steps = 0
	soil_water = 0.0
	if is_instance_valid(worker):
		worker.farm_activity = "basket" if pending_harvest > 0.0 else "farm"
		worker._farm_work_time = 0.0
		worker.go_to_work()
