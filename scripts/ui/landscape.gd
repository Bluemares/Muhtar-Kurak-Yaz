class_name Landscape
extends Control
## Menü / final ekranı arka planı: Kenney tile'larıyla küçük köy manzarası.
## mood: 0 kurak yaz, 1 yeşeren köy (iyi son), -1 yanmış köy (kayıp)

var mood := 0
var _t := 0.0
var _sky_top := Color("d9603b")
var _sky_bottom := Color("f6d58e")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if mood > 0:
		_sky_top = Color("4a90c2")
		_sky_bottom = Color("f2d7a0")
	elif mood < 0:
		_sky_top = Color("2b1a1a")
		_sky_bottom = Color("8a3b22")
	var dust := CPUParticles2D.new()
	dust.amount = 50
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.texture = Art.soft()
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(700, 380)
	dust.position = Vector2(640, 360)
	dust.direction = Vector2(1, -0.1)
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 10
	dust.initial_velocity_max = 30
	dust.scale_amount_min = 0.05
	dust.scale_amount_max = 0.12
	dust.color = Color(1, 0.55, 0.2, 0.8) if mood < 0 else Color(1, 0.95, 0.75, 0.6)
	add_child(dust)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Kurak yaz manzarası: Kenney tile'larıyla küçük bir köy.
func _draw() -> void:
	var s := size
	if s.x < 10.0:
		return
	var gy := s.y * 0.74
	# gökyüzü degrade
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), Vector2(s.x, gy), Vector2(0, gy)]),
		PackedColorArray([_sky_top, _sky_top, _sky_bottom, _sky_bottom]))
	# güneş
	var sun := Vector2(s.x * 0.8, s.y * 0.2)
	var pulse := 1.0 + sin(_t * 1.3) * 0.05
	draw_texture_rect(Art.soft(), Rect2(sun - Vector2(260, 260) * pulse, Vector2(520, 520) * pulse), false, Color(1, 0.9, 0.5, 0.55))
	draw_circle(sun, 64 * pulse, Color("fff1b8"))
	# tepeler
	for layer in 2:
		var pts := PackedVector2Array([Vector2(0, gy)])
		for i in 33:
			var x := s.x * i / 32.0
			pts.append(Vector2(x, gy - 70 - layer * -30 - sin(x * 0.006 + layer * 2.0) * 40 - sin(x * 0.017) * 15))
		pts.append(Vector2(s.x, gy))
		draw_colored_polygon(pts, Color("c98b4f") if layer == 0 else Color("b5793f"))
	# zemin
	var T := 48.0
	var tint: Color = [Color(0.45, 0.4, 0.38), Color(1.0, 0.8, 0.45), Color(0.9, 1.0, 0.85)][mood + 1]
	for x in int(s.x / T) + 1:
		for y in int((s.y - gy) / T) + 1:
			Art.tile(self, Art.TOWN, Art.T_GRASS[(x * 7 + y * 3) % 5 / 4], Rect2(Vector2(x * T, gy + y * T), Vector2(T, T)), tint)
	# köy
	var base := gy - T * 1.6
	_layout(Building.LAYOUTS.house[0], Vector2(s.x * 0.08, base), T)
	_layout(Building.LAYOUTS.house[1], Vector2(s.x * 0.19, base + 10), T)
	_layout(Building.LAYOUTS.cop31[0], Vector2(s.x * 0.74, base - T * 2.0), T)
	draw_texture_rect(Sprites.well(), Rect2(Vector2(s.x * 0.31, base + T * 0.1), Vector2(T, T) * 1.6), false)
	for i in 7:
		var x := s.x * 0.42 + i * T
		for row in 2:
			Art.tile(self, Art.FARM, Art.F_SOIL_A[clampi(i, 0, 3) if i < 3 else (3 if i == 6 else 1)] if row == 0 else Art.F_SOIL_B[1], Rect2(Vector2(x, gy - T * 0.6 + row * T * 0.8), Vector2(T, T)), tint)
			var dead := mood < 0 or (mood == 0 and (i * 3 + row) % 4 == 0)
			Art.tile(self, Art.FARM, 67 if dead else 66, Rect2(Vector2(x + sin(_t * 2.0 + i) * 2.0, gy - T * 0.8 + row * T * 0.8), Vector2(T, T)))
	for i in 6:
		var tx := fmod(i * 237.0 + 40.0, s.x)
		if tx > s.x * 0.36 and tx < s.x * 0.72:
			continue
		Art.tile(self, Art.TOWN, Art.T_TREES_DRY[i % 3] if (i % 2 and mood <= 0) or mood < 0 else Art.T_TREES_GREEN[i % 4], Rect2(Vector2(tx, gy - T * 1.1), Vector2(T, T) * 1.3))
	# gezen çiftçi ve tavuklar
	var fx := fmod(_t * 45.0, s.x + 120.0) - 60.0
	Art.tile(self, Art.FARM, 108, Rect2(Vector2(fx, gy + T * 0.6 - absf(sin(_t * 10.0)) * 3.0), Vector2(T, T)))
	for i in 3:
		var cx := s.x * (0.25 + i * 0.22) + sin(_t * 0.7 + i) * 30.0
		Art.tile(self, Art.FARM, 122, Rect2(Vector2(cx, gy + T * 1.6), Vector2(T, T) * 0.8), Color.WHITE)
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.03, 0.0, 0.45) if mood < 0 else Color(0.15, 0.05, 0.0, 0.12))


func _layout(rows: Array, at: Vector2, T: float) -> void:
	for y in rows.size():
		for x in rows[y].size():
			Art.tile(self, Art.TOWN, rows[y][x], Rect2(at + Vector2(x, y) * T, Vector2(T, T)))
