extends Control
## 3D binaların üstündeki bilgi göstergeleri, ekran uzayında sabit boyutta çizilir (her açıdan okunur):
## hasat balonu + geri sayım halkası, büyüme/inşaat çubuğu, seviye yıldızları, işçi rozeti, koruma rozeti.

const BUBBLE_UP := 34.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


## Binanın tepesinin ekran konumu (kamera arkasındaysa çok uzak bir nokta).
static func anchor(node: Node, b) -> Vector2:
	return View.to_screen(node, b.center(), BuildingView3D.top(b) + 0.15)


## Hasat balonunun ekran merkezi (tıklama testi de bunu kullanır).
static func bubble_pos(node: Node, b) -> Vector2:
	return anchor(node, b) - Vector2(0, BUBBLE_UP)


func _draw() -> void:
	if View.is_3d() and View.camera.get("_fire_shot") == true:
		return
	if not View.is_3d() or get_tree().paused and not GameState.round_active:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var vs := size
	var detail: bool = View.camera.zoom.x >= 0.8
	for c in GameState.clearing:
		var cp := View.to_screen(self, (Vector2(c) + Vector2(0.5, 0.5)) * Bal.CELL, 1.3)
		_alert(cp - Vector2(0, 14), Color(0.55, 0.4, 0.2), 1.0)
		draw_line(cp + Vector2(-6, -6), cp + Vector2(5, -22), Color(0.85, 0.7, 0.45), 2.5)
		draw_colored_polygon(PackedVector2Array([cp + Vector2(1, -24), cp + Vector2(10, -20), cp + Vector2(6, -13)]), Color(0.92, 0.92, 0.95))
		_bar(cp + Vector2(0, 14), 44.0, clampf(GameState.clearing[c] / Bal.CLEAR_TIME, 0.0, 1.0), Color(0.85, 0.65, 0.35))
	for b in GameState.buildings:
		if not is_instance_valid(b):
			continue
		var a := anchor(self, b)
		if a.x < -60 or a.y < -60 or a.x > vs.x + 60 or a.y > vs.y + 60:
			continue
		var bw := 56.0
		if View.risk_map and Bal.BUILDINGS[b.type].flammable and b.state == "normal":
			_risk_pill(a - Vector2(0, 44), GameState.fire_risk_per_minute(b))
		if View.moist_map and b.is_crop() and b.state == "normal":
			_pill(a - Vector2(0, 44), "%d%%" % int(round(GameState.moisture(b) * 100.0)), View.moist_color(GameState.moisture(b)))
		if b.crop_ready and b.state == "normal":
			_bubble(b, a - Vector2(0, BUBBLE_UP + absf(sin(t * 4.0)) * 6.0))
		elif b.is_crop() and b.state == "normal":
			_bar(a, bw, clampf(b.harvest_progress / b.harvest_time(), 0.0, 1.0), Color(0.95, 0.85, 0.3))
		if b.state == "moving":
			_bar(a, bw, 1.0 - b.move_timer / Bal.MOVE_DURATION, Color(1, 1, 1))
		var pulse := 0.75 + 0.25 * sin(t * 6.0)
		if b.type == "field" and b.pest and b.state == "normal":
			_alert(a + Vector2(-bw * 0.5 - 14, -18), Color(0.85, 0.55, 0.1), pulse)
			_bug(a + Vector2(-bw * 0.5 - 14, -18), 9.0)
		if b.state == "normal" and b.needs_road() and not b.road_connected():
			_alert(a + Vector2(bw * 0.5 + 14, -18), Color(0.85, 0.15, 0.1), pulse)
			_noroad(a + Vector2(bw * 0.5 + 14, -18), 9.0)
		if not detail:
			continue
		var d: Dictionary = b.data()
		if d.max_level > 1:
			for i in b.level:
				_star(a + Vector2(-bw * 0.5 + 6 + i * 13, 12), 5.0)
		if d.workers > 0 and b.state != "ruined":
			var txt := "%d/%d" % [1 if b.has_working_worker() else 0, d.workers]
			var p := a + Vector2(bw * 0.5 - 26, 4)
			draw_rect(Rect2(p, Vector2(28, 15)), Color(0, 0, 0, 0.65))
			draw_string(UI.BODY, p + Vector2(4, 12), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		if b.is_protected() and b.type == "field":
			var c := a + Vector2(bw * 0.5 + 10, -2)
			draw_circle(c, 8, Color(0.15, 0.6, 0.25, 0.95))
			draw_circle(c, 4, Color.WHITE)


func _bar(a: Vector2, w: float, k: float, col: Color) -> void:
	var r := Rect2(a + Vector2(-w * 0.5, -6), Vector2(w, 7))
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2((w - 2) * k, 5)), col)


func _bubble(b, bc: Vector2) -> void:
	draw_circle(bc + Vector2(2, 3), 19, Color(0, 0, 0, 0.3))
	draw_circle(bc, 19, Color(1, 1, 1, 0.95))
	draw_colored_polygon(PackedVector2Array([bc + Vector2(-6, 15), bc + Vector2(6, 15), bc + Vector2(0, 24)]), Color(1, 1, 1, 0.95))
	_crop(bc, b.crop)
	var left: float = 1.0 - b._ready_t / Bal.AUTO_HARVEST_DELAY
	draw_arc(bc, 21, -PI / 2, -PI / 2 + TAU * left, 24, Color(0.95, 0.75, 0.2), 3.0)


func _star(c: Vector2, rad: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(ang), sin(ang)) * (rad if i % 2 == 0 else rad * 0.45))
	draw_colored_polygon(pts, Color.GOLD)
	pts.append(pts[0])
	draw_polyline(pts, Color(0.4, 0.25, 0, 0.8), 1.0)


## Yuvarlak uyarı rozeti (nabız atar).
func _alert(c: Vector2, col: Color, pulse: float) -> void:
	draw_circle(c + Vector2(1, 2), 15.0 * pulse, Color(0, 0, 0, 0.35))
	draw_circle(c, 15.0 * pulse, col)
	draw_arc(c, 15.0 * pulse, 0, TAU, 24, Color(1, 1, 1, 0.9), 2.0)


func _bug(c: Vector2, r: float) -> void:
	var ink := Color(0.12, 0.08, 0.04)
	draw_circle(c, r * 0.7, ink)
	for i in 3:
		var y := -r * 0.4 + i * r * 0.4
		draw_line(c + Vector2(-r * 0.6, y), c + Vector2(-r * 1.05, y - r * 0.2), ink, 1.5)
		draw_line(c + Vector2(r * 0.6, y), c + Vector2(r * 1.05, y - r * 0.2), ink, 1.5)


## Yol yok: üstü çizili yol şeridi.
func _noroad(c: Vector2, r: float) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.3, -r), c + Vector2(r * 0.3, -r), c + Vector2(r * 0.75, r), c + Vector2(-r * 0.75, r)]), Color(0.95, 0.85, 0.7))
	draw_line(c + Vector2(-r, r), c + Vector2(r, -r), Color.WHITE, 3.0)


## Hasat balonunda ürün ikonu (tarlada seçilen ürün; sebze = havuç, tarladaki gibi).
func _crop(c: Vector2, crop: String) -> void:
	match crop:
		"melon":
			draw_circle(c + Vector2(0, 2), 11, Color(0.35, 0.62, 0.22))
			for i in 3:
				draw_arc(c + Vector2(0, 2), 11, -PI * 0.5 + (i - 1) * 0.6, -PI * 0.5 + (i - 1) * 0.6 + PI, 10, Color(0.75, 0.9, 0.45), 1.5)
		"corn":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12), c + Vector2(6, -4), c + Vector2(5, 9), c + Vector2(-5, 9), c + Vector2(-6, -4)]), Color(1.0, 0.82, 0.25))
			for i in 4:
				draw_line(c + Vector2(-5, -6 + i * 4), c + Vector2(5, -6 + i * 4), Color(0.85, 0.6, 0.1), 1.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2, 12), c + Vector2(-11, -2), c + Vector2(-4, 4)]), Color(0.45, 0.7, 0.25))
			draw_colored_polygon(PackedVector2Array([c + Vector2(2, 12), c + Vector2(11, -2), c + Vector2(4, 4)]), Color(0.45, 0.7, 0.25))
		"wheat":
			var gold := Color(0.92, 0.72, 0.25)
			draw_line(c + Vector2(0, 12), c + Vector2(0, -8), gold, 2.0)
			for i in 4:
				var y := -9 + i * 4.5
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, y + 3), c + Vector2(-6, y - 2), c + Vector2(-2, y + 5)]), gold)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, y + 3), c + Vector2(6, y - 2), c + Vector2(2, y + 5)]), gold)
		_:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -5), c + Vector2(5, -5), c + Vector2(0, 12)]), Color(1.0, 0.55, 0.12))
			for i in 3:
				draw_line(c + Vector2(-3, -1 + i * 4), c + Vector2(1, -1 + i * 4), Color(0.8, 0.35, 0.05), 1.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(-6, -13), c + Vector2(-1, -8)]), Color(0.3, 0.65, 0.2))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(6, -13), c + Vector2(1, -8)]), Color(0.3, 0.65, 0.2))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(0, -14), c + Vector2(2, -7)]), Color(0.35, 0.72, 0.25))


## Yangın riski etiketi: renkli hap içinde "%12" (dakika başına olasılık).
func _risk_pill(c: Vector2, r: float) -> void:
	_pill(c, "%d%%" % int(round(r * 100.0)), View.risk_color(r))


func _pill(c: Vector2, txt: String, col: Color) -> void:
	var w := 52.0
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.06, 0.05, 0.85)
	box.border_color = col
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	draw_style_box(box, Rect2(c - Vector2(w * 0.5, 12), Vector2(w, 24)))
	draw_circle(c + Vector2(-w * 0.5 + 11, 0), 5, col)
	draw_string(UI.BODY, c + Vector2(-w * 0.5 + 19, 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
