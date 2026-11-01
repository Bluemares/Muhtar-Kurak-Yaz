extends Control
## Yangın söndürme minigame'i (ayrı sahne). Fareyi basılı tut, hortumla alevleri söndür.
## setup() ile yanan binalar verilir, bitince finished(results) yayılır: {bina: kurtarıldı_mı}.

signal finished(results: Dictionary)

const PANEL := Vector2(320, 320)

var targets: Array = []
var panels: Array = []  # Rect2 her bina için
var flames: Array = []  # {pos, i (yoğunluk), b (panel idx), fx (CPUParticles2D)}
var spawn_timers: Array = []
var time_left := Bal.MINIGAME_SECONDS
var tank_max := 100.0
var tank := 100.0
var radius := 50.0
var spraying := false
var _empty_lock := false  # tank bitince fare bırakılana kadar sprey kilitli
var done := false
var _t := 0.0
var _font: Font
var _spray: CPUParticles2D
var _saved_flash: Array = []
var _live: Array = []  # panel başına canlı 3D görüntü (ana dünyayı paylaşan SubViewport)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_font = UI.BODY if Bal.RENDER_3D and UI.BODY else ThemeDB.fallback_font
	var vs := get_viewport_rect().size
	# arka planda uçuşan kıvılcımlar
	var emb := Art.embers(Vector2(vs.x * 0.5, 10))
	emb.amount = 40
	emb.position = Vector2(vs.x * 0.5, vs.y + 10)
	emb.initial_velocity_min = 60
	emb.initial_velocity_max = 140
	emb.lifetime = 4.0
	emb.emitting = true
	add_child(emb)
	# hortum suyu
	_spray = CPUParticles2D.new()
	_spray.amount = 70
	_spray.lifetime = 0.35
	_spray.texture = Art.soft()
	_spray.local_coords = false
	_spray.spread = 9
	_spray.gravity = Vector2(0, 260)
	_spray.initial_velocity_min = 650
	_spray.initial_velocity_max = 900
	_spray.scale_amount_min = 0.12
	_spray.scale_amount_max = 0.28
	_spray.color_ramp = _ramp(Color(0.75, 0.9, 1.0, 0.95), Color(0.4, 0.7, 1.0, 0.0))
	_spray.emitting = false
	_spray.z_index = 8
	add_child(_spray)


func _ramp(a: Color, b: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	return g


func setup(burning: Array, well_level: int) -> void:
	targets = burning
	tank_max = Bal.HOSE_TANK[clampi(well_level, 1, 3)]
	radius = Bal.HOSE_RADIUS[clampi(well_level, 1, 3)]
	tank = tank_max
	_layout.call_deferred()


func _layout() -> void:
	var vs := get_viewport_rect().size
	var n := targets.size()
	var gap := 30.0
	var total := n * PANEL.x + (n - 1) * gap
	var scale_f := minf(1.0, (vs.x - 80.0) / total)
	var ps := PANEL * scale_f
	total = n * ps.x + (n - 1) * gap * scale_f
	var x0 := (vs.x - total) * 0.5
	for i in n:
		var r := Rect2(Vector2(x0 + i * (ps.x + gap * scale_f), vs.y * 0.5 - ps.y * 0.5 + 20), ps)
		panels.append(r)
		spawn_timers.append(Bal.FLAME_SPAWN_INTERVAL)
		_saved_flash.append(0.0)
		for k in Bal.FLAME_START:
			_spawn_flame(i)
		if Bal.RENDER_3D and View.is_3d():
			_live.append(_live_view(targets[i], Vector2i(r.size)))


## Binanın anlık 3D görüntüsü: aynı dünyaya bakan ikinci kamera (alevler, seviye, yön canlı görünür).
func _live_view(b, px: Vector2i) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = px
	vp.world_3d = get_viewport().world_3d
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	cam.fov = 34.0
	var s: Vector2i = b.size
	var span := maxf(s.x, s.y) + 0.8
	var target := View.to3(b.center(), 0.35)
	var basis := Basis(Vector3.UP, deg_to_rad(-32.0)) * Basis(Vector3.RIGHT, -deg_to_rad(40.0))
	cam.transform = Transform3D(basis, target + basis * Vector3(0, 0, span * 1.9 + 0.8))
	vp.add_child(cam)
	add_child(vp)
	cam.make_current()
	return vp.get_texture()


func _spawn_flame(i: int) -> void:
	var r: Rect2 = panels[i]
	var p := Vector2(randf_range(r.position.x + 30, r.end.x - 30), randf_range(r.position.y + 50, r.end.y - 30))
	var fx := Art.fire(Vector2(14, 6))
	fx.amount = 24
	fx.scale_amount_min = 0.5
	fx.scale_amount_max = 0.9
	fx.initial_velocity_max = 90
	fx.position = p
	fx.emitting = true
	add_child(fx)
	flames.append({"pos": p, "i": randf_range(0.5, 0.8), "b": i, "fx": fx})


func _flames_of(i: int) -> int:
	var n := 0
	for f in flames:
		if f.b == i:
			n += 1
	return n


func _steam(p: Vector2) -> void:
	var s := Art.smoke(Vector2(10, 4), 0.85)
	s.one_shot = true
	s.explosiveness = 0.8
	s.amount = 10
	s.lifetime = 1.2
	s.position = p
	s.finished.connect(s.queue_free)
	add_child(s)
	s.emitting = true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if done or panels.is_empty():
		_spray.emitting = false
		return
	time_left -= delta
	var vs := get_viewport_rect().size
	var mouse := get_local_mouse_position()
	var nozzle := Vector2(vs.x * 0.5, vs.y - 40)
	var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if tank <= 0.0:
		_empty_lock = true
	elif not pressed:
		_empty_lock = false
	spraying = pressed and tank > 0.0 and not _empty_lock
	Audio.hose(spraying)
	_spray.emitting = spraying
	_spray.position = nozzle
	var dir := (mouse - nozzle).normalized()
	_spray.direction = dir
	var dist := nozzle.distance_to(mouse)
	_spray.initial_velocity_min = dist * 2.4
	_spray.initial_velocity_max = dist * 3.0
	if spraying:
		tank = maxf(0.0, tank - Bal.HOSE_DRAIN * delta)
	elif tank < tank_max:
		# araç tankı köyün su deposundan dolar; depo boşsa kuyudan yavaş
		var take := minf(minf(Bal.DEPOT_REFILL * delta, tank_max - tank), GameState.water)
		if take > 0.0:
			tank += take
			GameState.water -= take
		else:
			tank = minf(tank_max, tank + Bal.HOSE_REFILL * 0.5 * delta)
	for f in flames:
		if spraying and f.pos.distance_to(mouse) < radius:
			f.i -= Bal.FLAME_DOUSE * delta
			if randf() < delta * 6.0:
				_steam(f.pos)
		else:
			f.i = minf(1.5, f.i + Bal.FLAME_GROW * delta)
		f.fx.scale = Vector2.ONE * clampf(0.4 + f.i * 0.7, 0.3, 1.5)
	for f in flames:
		if f.i <= 0.0:
			_steam(f.pos)
			f.fx.emitting = false
			get_tree().create_timer(1.0, true).timeout.connect(f.fx.queue_free)
			Audio.play("sizzle", 0.15)
	var before := []
	for i in panels.size():
		before.append(_flames_of(i))
	flames = flames.filter(func(f): return f.i > 0.0)
	for i in panels.size():
		if before[i] > 0 and _flames_of(i) == 0:
			_saved_flash[i] = 1.0
			Audio.play("saved", 0.0)
		_saved_flash[i] = maxf(0.0, _saved_flash[i] - delta * 1.5)
		if _flames_of(i) == 0:
			continue
		spawn_timers[i] -= delta
		if spawn_timers[i] <= 0.0:
			spawn_timers[i] = Bal.FLAME_SPAWN_INTERVAL
			_spawn_flame(i)
	if flames.is_empty() or time_left <= 0.0:
		_finish()


func _finish() -> void:
	done = true
	Audio.hose(false)
	_spray.emitting = false
	var results := {}
	var saved := 0
	for i in targets.size():
		var ok := _flames_of(i) == 0
		results[targets[i]] = ok
		if ok:
			saved += 1
	for f in flames:
		f.fx.emitting = false
	var banner := UI.label(tr("MG_RESULT") % [saved, targets.size()], 40, Color.WHITE if saved == targets.size() else Color(1, 0.8, 0.6))
	banner.add_theme_constant_override("outline_size", 10)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(banner)
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2.ONE * 2.0
	banner.create_tween().tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play("upgrade" if saved == targets.size() else "collapse", 0.0)
	await get_tree().create_timer(1.8, true).timeout
	finished.emit(results)
	queue_free()


func _draw() -> void:
	var vs := get_viewport_rect().size
	# duman kaplı gökyüzü (3D'de yanan köy arkada seçilir)
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.07, 0.04, 0.04, 0.87 if Bal.RENDER_3D else 0.93))
	draw_texture_rect(Art.soft(), Rect2(Vector2(-vs.x * 0.2, vs.y * 0.35), Vector2(vs.x * 1.4, vs.y * 1.2)), false, Color(0.9, 0.3, 0.05, 0.22 + 0.05 * sin(_t * 3.0)))
	draw_string(UI.FONT, Vector2(0, 58), tr("MG_TITLE"), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 34, Color(1, 0.85, 0.5))
	draw_string(_font, Vector2(0, 88), tr("MG_HINT"), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 17, Color(1, 0.9, 0.8, 0.85))
	# süre
	var tw := 420.0
	var tx := (vs.x - tw) * 0.5
	var tp := clampf(time_left / Bal.MINIGAME_SECONDS, 0, 1)
	draw_rect(Rect2(tx - 2, 104, tw + 4, 18), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(tx, 106, tw * tp, 14), Color(1, 0.75, 0.2).lerp(Color(1, 0.15, 0.1), 1.0 - tp))
	draw_string(_font, Vector2(tx + tw + 12, 120), "%ds" % ceili(maxf(time_left, 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	# binalar
	for i in panels.size():
		var r: Rect2 = panels[i]
		var b = targets[i]
		var saved := _flames_of(i) == 0
		draw_texture_rect(Art.soft(), Rect2(r.position - Vector2(30, 10), r.size + Vector2(60, 50)), false, Color(0, 0, 0, 0.5))
		var heat := 0.0 if saved else clampf(_flames_of(i) / 6.0, 0.2, 1.0)
		if Bal.RENDER_3D:
			var card := UI.skin("panel", 12, 10) as StyleBoxFlat
			card.bg_color = Color(0.16, 0.22, 0.12, 0.95) if saved else Color(0.2, 0.12, 0.08, 0.95)
			card.border_color = Color(0.5, 1.0, 0.6) if saved else Color(1.0, 0.45, 0.15).lerp(UI.GOLD, 0.5 + 0.5 * sin(_t * 6.0))
			draw_style_box(card, r)
			var tex: Texture2D = _live[i] if i < _live.size() else Thumbs.building(b.type, Vector2i(300, 300), b.level, 42.0)
			draw_texture_rect(tex, r.grow(-8), false, Color.WHITE.lerp(Color(1.0, 0.8, 0.7), heat * 0.5))
		else:
			draw_rect(r, Color(0.2, 0.3, 0.15) if saved else Color(0.22, 0.17, 0.12))
			_draw_building(b, r.grow(-28), Color.WHITE.lerp(Color(0.85, 0.4, 0.25), heat))
			draw_rect(r, Color(1, 1, 1, 0.25), false, 2.0)
		if _saved_flash[i] > 0.0:
			draw_rect(r, Color(0.5, 1.0, 0.6, _saved_flash[i] * 0.5))
		var title_r := Rect2(r.position + Vector2(0, -34), Vector2(r.size.x, 28))
		if Bal.RENDER_3D:
			var tb := UI.skin("panel_inlay", 8, 4) as StyleBoxFlat
			tb.bg_color = Color(0, 0, 0, 0.7)
			draw_style_box(tb, title_r)
		else:
			draw_rect(title_r, Color(0, 0, 0, 0.55))
		draw_string(UI.FONT, r.position + Vector2(0, -13), tr(Bal.BUILDINGS[b.type].name), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 19, Color.WHITE)
		if saved:
			draw_string(UI.FONT, r.position + Vector2(0, r.size.y - 16), tr("MG_SAVED"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Color(0.6, 1.0, 0.6))
	# alev çekirdeği parıltısı
	for f in flames:
		var k: float = f.i * (0.85 + 0.15 * sin(_t * 11.0 + f.pos.x))
		draw_texture_rect(Art.soft(), Rect2(f.pos - Vector2(40, 46) * k, Vector2(80, 80) * k), false, Color(1, 0.45, 0.1, 0.3))
	# su tankı
	var th := 200.0
	var tank_r := Rect2(28, vs.y - 60 - th, 34, th)
	var fill := th * tank / tank_max
	if Bal.RENDER_3D:
		var shell := UI.skin("panel", 12, 4) as StyleBoxFlat
		shell.set_corner_radius_all(17)
		draw_style_box(shell, tank_r.grow(5))
		var water := StyleBoxFlat.new()
		water.bg_color = Color(0.25, 0.6, 1.0)
		water.set_corner_radius_all(14)
		if fill > 2:
			draw_style_box(water, Rect2(tank_r.position.x, tank_r.end.y - fill, tank_r.size.x, fill))
	else:
		draw_rect(tank_r.grow(3), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(tank_r.position.x, tank_r.end.y - fill, tank_r.size.x, fill), Color(0.25, 0.6, 1.0))
	if fill > 4:
		var wave := sin(_t * 5.0) * 2.0
		draw_rect(Rect2(tank_r.position.x, tank_r.end.y - fill + wave, tank_r.size.x, 4), Color(0.7, 0.9, 1.0, 0.8))
	draw_string(_font, Vector2(14, vs.y - 32), tr("MG_WATER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(_font, Vector2(14, vs.y - 12), tr("MG_DEPOT") % int(GameState.water), HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Color(0.6, 0.85, 1.0) if GameState.water > 1.0 else Color(1, 0.5, 0.4))
	if _empty_lock:
		var a := 0.6 + 0.4 * sin(_t * 8.0)
		draw_string(_font, Vector2(72, vs.y - 120), tr("MG_EMPTY"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.5, 0.4, a))
	# hortum + nişangah
	var mouse := get_local_mouse_position()
	var nozzle := Vector2(vs.x * 0.5, vs.y - 40)
	var ctrl := Vector2(vs.x * 0.5, vs.y + 60)
	var pts := PackedVector2Array()
	for s in 13:
		var tt := s / 12.0
		pts.append(Vector2(vs.x * 0.35, vs.y + 30).lerp(ctrl, tt).lerp(ctrl.lerp(nozzle, tt), tt))
	draw_polyline(pts, Color(0.35, 0.08, 0.04), 15.0)
	draw_polyline(pts, Color(0.75, 0.2, 0.1), 11.0)
	draw_polyline(pts, Color(1.0, 0.45, 0.3, 0.5), 3.0)
	draw_circle(nozzle, 12, Color(0.45, 0.35, 0.1))
	draw_circle(nozzle, 9, Color(0.85, 0.72, 0.3))
	draw_circle(nozzle + Vector2(-3, -3), 3, Color(1, 0.95, 0.7, 0.8))
	var col := Color(0.55, 0.85, 1.0, 0.8) if spraying else Color(1, 1, 1, 0.35)
	draw_arc(mouse, radius, 0, TAU, 40, col, 2.5 if spraying else 1.5)
	draw_line(mouse - Vector2(8, 0), mouse + Vector2(8, 0), col, 2.0)
	draw_line(mouse - Vector2(0, 8), mouse + Vector2(0, 8), col, 2.0)


func _draw_building(b, r: Rect2, mod: Color) -> void:
	var T: float = minf(r.size.x / b.size.x, r.size.y / b.size.y) * 0.5
	var origin: Vector2 = r.get_center() - Vector2(b.size) * T
	if b.type == "field":
		var crops: Array = Art.F_CROPS[b.level]
		for y in 4:
			var soil: Array = Art.F_SOIL_A if y % 2 == 0 else Art.F_SOIL_B
			for x in 4:
				var tr_ := Rect2(origin + Vector2(x, y) * T, Vector2(T, T))
				Art.tile(self, Art.FARM, soil[x], tr_, mod)
				Art.tile(self, Art.FARM, crops[2 if (x + y) % 3 else 3], tr_, mod)
	elif b.type == "well":
		draw_texture_rect(Sprites.well(), Rect2(origin, Vector2(T, T) * 2.0), false, mod)
	elif Building.LAYOUTS.has(b.type):
		var variants: Array = Building.LAYOUTS[b.type]
		var rows: Array = variants[b._variant % variants.size()]
		var ts: float = T * 2.0 * b.size.x / rows[0].size()
		for y in rows.size():
			for x in rows[y].size():
				Art.tile(self, Art.TOWN, rows[y][x], Rect2(origin + Vector2(x, y) * ts, Vector2(ts, ts)), mod)
