class_name Icon
extends Control
## Küçük HUD ikonu: atlas tile'ı ya da çizilmiş şekil (coin, heart, sun, clock).

var sheet: Texture2D
var idx := -1
var shape := ""


static func tile(s: Texture2D, i: int, px := 26) -> Icon:
	var ic := Icon.new()
	ic.sheet = s
	ic.idx = i
	ic.custom_minimum_size = Vector2(px, px)
	return ic


static func drawn(sh: String, px := 26) -> Icon:
	var ic := Icon.new()
	ic.shape = sh
	ic.custom_minimum_size = Vector2(px, px)
	return ic


## Buton ikonu olarak kullanılacak AtlasTexture.
static func atlas(s: Texture2D, i: int) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = s
	a.region = Art.region(i)
	return a


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var c := r.get_center()
	var rad := minf(size.x, size.y) * 0.42
	if sheet:
		Art.tile(self, sheet, idx, r)
		return
	match shape:
		"box":
			draw_rect(r.grow(-3), Color(0, 0, 0, 0.35))
			draw_rect(r.grow(-3), Color(1, 1, 1, 0.7), false, 2.0)
		"check":
			draw_rect(r.grow(-3), Color(0.3, 0.75, 0.35))
			draw_polyline(PackedVector2Array([r.position + size * Vector2(0.25, 0.5), r.position + size * Vector2(0.43, 0.7), r.position + size * Vector2(0.75, 0.3)]), Color.WHITE, 2.5)
		"coin":
			draw_circle(c + Vector2(1, 1.5), rad, Color(0.45, 0.3, 0.05))
			draw_circle(c, rad, Color(1.0, 0.8, 0.2))
			draw_circle(c, rad * 0.7, Color(0.95, 0.68, 0.12))
			draw_arc(c, rad * 0.55, PI * 1.1, PI * 1.6, 8, Color(1, 0.95, 0.7), 2.0)
		"heart":
			var pts := PackedVector2Array()
			for i in 24:
				var t := i / 24.0 * TAU
				pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * rad / 17.0)
			draw_colored_polygon(pts, Color(0.92, 0.25, 0.3))
		"sun":
			for i in 8:
				var a := i * TAU / 8.0
				draw_line(c + Vector2(cos(a), sin(a)) * rad * 0.65, c + Vector2(cos(a), sin(a)) * rad * 1.05, Color(1, 0.6, 0.15), 2.5)
			draw_circle(c, rad * 0.5, Color(1, 0.8, 0.25))
		"moon":
			draw_circle(c, rad * 0.8, Color(0.95, 0.93, 0.8))
			draw_circle(c + Vector2(rad * 0.38, -rad * 0.25), rad * 0.7, Color(0.16, 0.13, 0.11))
		"upgrade", "spray", "drip", "repair", "move", "close", "rotate", "crop", "axe", "hammer", "water", "food", "people", "bug", "road", "info", "fire", "sell":
			_vector(shape, c, rad)
		"clock":
			draw_circle(c, rad, Color(0.95, 0.9, 0.8))
			draw_arc(c, rad, 0, TAU, 24, Color(0.3, 0.2, 0.1), 2.0)
			draw_line(c, c + Vector2(0, -rad * 0.7), Color(0.3, 0.2, 0.1), 2.0)
			draw_line(c, c + Vector2(rad * 0.5, 0), Color(0.3, 0.2, 0.1), 2.0)


const INK := Color(0.12, 0.08, 0.05, 0.85)
const WHITE := Color(1, 0.98, 0.92)


## Düz vektör ikonlar (3D sürüm arayüzü; pixel ikonların yerine). Beyaz dolgu + koyu kontur.
func _vector(sh: String, c: Vector2, r: float) -> void:
	var w := maxf(2.0, r * 0.16)
	match sh:
		"upgrade":
			var arrow := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.1), c + Vector2(r * 0.32, -r * 0.1),
				c + Vector2(r * 0.32, r * 0.85), c + Vector2(-r * 0.32, r * 0.85), c + Vector2(-r * 0.32, -r * 0.1), c + Vector2(-r * 0.8, -r * 0.1)])
			_poly(arrow, WHITE)
		"spray":
			_poly(PackedVector2Array([c + Vector2(-r * 0.45, -r * 0.35), c + Vector2(r * 0.15, -r * 0.35), c + Vector2(r * 0.15, r * 0.9), c + Vector2(-r * 0.45, r * 0.9)]), WHITE)
			draw_rect(Rect2(c + Vector2(-r * 0.3, -r * 0.7), Vector2(r * 0.3, r * 0.35)), WHITE)
			for i in 3:
				draw_circle(c + Vector2(r * 0.45 + i * r * 0.18, -r * 0.55 + (i - 1) * r * 0.28), r * 0.09, Color(0.75, 0.95, 0.6))
		"drip", "water":
			var pts := PackedVector2Array([c + Vector2(0, -r)])
			for i in 13:
				var a := PI * 0.15 + i * PI * 0.7 / 12.0 * 1.0
				a = lerpf(-0.2, PI + 0.2, i / 12.0)
				pts.append(c + Vector2(cos(a) * r * 0.62, r * 0.25 + sin(a) * r * 0.62))
			_poly(pts, Color(0.45, 0.78, 1.0) if sh == "water" else WHITE)
			draw_arc(c + Vector2(-r * 0.15, r * 0.25), r * 0.35, PI * 0.6, PI * 1.0, 6, Color(1, 1, 1, 0.8), w * 0.6)
		"repair":
			draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.25, -r * 0.25), INK, w * 2.4)
			draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.25, -r * 0.25), WHITE, w * 1.5)
			draw_arc(c + Vector2(r * 0.4, -r * 0.4), r * 0.42, PI * 0.9, PI * 2.6, 12, INK, w * 1.6)
			draw_arc(c + Vector2(r * 0.4, -r * 0.4), r * 0.42, PI * 0.9, PI * 2.6, 12, WHITE, w)
		"move":
			for a in [0.0, PI * 0.5, PI, PI * 1.5]:
				var d := Vector2(cos(a), sin(a))
				var t := Vector2(-d.y, d.x)
				draw_line(c, c + d * r * 0.8, WHITE, w)
				_poly(PackedVector2Array([c + d * r, c + d * r * 0.6 + t * r * 0.28, c + d * r * 0.6 - t * r * 0.28]), WHITE)
		"close":
			for d in [Vector2(1, 1), Vector2(1, -1)]:
				draw_line(c - d * r * 0.6, c + d * r * 0.6, INK, w * 2.2)
				draw_line(c - d * r * 0.6, c + d * r * 0.6, WHITE, w * 1.4)
		"rotate":
			draw_arc(c, r * 0.62, -PI * 0.15, PI * 1.45, 18, INK, w * 1.9)
			draw_arc(c, r * 0.62, -PI * 0.15, PI * 1.45, 18, WHITE, w * 1.2)
			var e := c + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * r * 0.62
			_poly(PackedVector2Array([e + Vector2(-r * 0.35, -r * 0.05), e + Vector2(r * 0.3, -r * 0.05), e + Vector2(0, r * 0.38)]), WHITE)
		"crop", "food":
			var stem := Color(0.95, 0.85, 0.4) if sh == "food" else WHITE
			draw_line(c + Vector2(0, r * 0.9), c + Vector2(0, -r * 0.6), stem, w)
			for i in 3:
				var y := -r * 0.45 + i * r * 0.38
				for sgn in [-1.0, 1.0]:
					_poly(PackedVector2Array([c + Vector2(0, y + r * 0.2), c + Vector2(sgn * r * 0.5, y - r * 0.05), c + Vector2(sgn * r * 0.22, y + r * 0.35)]), stem)
			_poly(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.16, -r * 0.62), c + Vector2(-r * 0.16, -r * 0.62)]), stem)
		"axe":
			draw_line(c + Vector2(-r * 0.6, r * 0.8), c + Vector2(r * 0.35, -r * 0.6), Color(0.85, 0.65, 0.4), w * 1.4)
			_poly(PackedVector2Array([c + Vector2(r * 0.05, -r * 0.85), c + Vector2(r * 0.85, -r * 0.45), c + Vector2(r * 0.55, r * 0.15), c + Vector2(r * 0.15, -r * 0.3)]), WHITE)
		"hammer":
			draw_line(c + Vector2(-r * 0.55, r * 0.85), c + Vector2(r * 0.2, -r * 0.2), Color(0.85, 0.65, 0.4), w * 1.6)
			_poly(PackedVector2Array([c + Vector2(-r * 0.25, -r * 0.55), c + Vector2(r * 0.35, -r * 0.95), c + Vector2(r * 0.95, -r * 0.1), c + Vector2(r * 0.4, r * 0.25)]), Color(0.85, 0.87, 0.9))
		"people":
			for p in [Vector2(-r * 0.38, 0.0), Vector2(r * 0.38, 0.0)]:
				draw_circle(c + p + Vector2(0, -r * 0.45), r * 0.28, WHITE)
				_poly(PackedVector2Array([c + p + Vector2(-r * 0.36, r * 0.85), c + p + Vector2(-r * 0.3, -r * 0.05), c + p + Vector2(r * 0.3, -r * 0.05), c + p + Vector2(r * 0.36, r * 0.85)]), WHITE)
		"bug":
			draw_circle(c, r * 0.55, Color(0.25, 0.18, 0.08))
			draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.55), Color(0.6, 0.45, 0.2), w * 0.6)
			for i in 3:
				var y := -r * 0.3 + i * r * 0.3
				draw_line(c + Vector2(-r * 0.5, y), c + Vector2(-r * 0.9, y - r * 0.15), Color(0.25, 0.18, 0.08), w * 0.6)
				draw_line(c + Vector2(r * 0.5, y), c + Vector2(r * 0.9, y - r * 0.15), Color(0.25, 0.18, 0.08), w * 0.6)
		"road":
			_poly(PackedVector2Array([c + Vector2(-r * 0.35, -r), c + Vector2(r * 0.35, -r), c + Vector2(r * 0.9, r), c + Vector2(-r * 0.9, r)]), Color(0.75, 0.6, 0.42))
			for i in 3:
				draw_line(c + Vector2(0, -r * 0.8 + i * r * 0.6), c + Vector2(0, -r * 0.5 + i * r * 0.6), WHITE, w)
		"sell":
			draw_circle(c, r * 0.72, Color(1.0, 0.8, 0.2))
			draw_circle(c, r * 0.5, Color(0.95, 0.68, 0.12))
			draw_line(c + Vector2(-r * 0.8, r * 0.8), c + Vector2(r * 0.8, -r * 0.8), INK, w * 1.8)
			draw_line(c + Vector2(-r * 0.8, r * 0.8), c + Vector2(r * 0.8, -r * 0.8), WHITE, w)
		"fire":
			var outer := PackedVector2Array()
			var inner := PackedVector2Array()
			for i in 17:
				var a := lerpf(0.0, TAU, i / 16.0)
				var k := 1.0 + 0.35 * maxf(0.0, -sin(a)) * (0.6 + 0.4 * cos(a * 3.0))
				outer.append(c + Vector2(sin(a) * r * 0.62, -cos(a) * r * 0.62 * k + r * 0.25))
				inner.append(c + Vector2(sin(a) * r * 0.32, -cos(a) * r * 0.36 * k + r * 0.45))
			_poly(outer, Color(1.0, 0.45, 0.12))
			draw_colored_polygon(inner, Color(1.0, 0.85, 0.3))
		"info":
			draw_circle(c, r * 0.9, WHITE)
			draw_circle(c + Vector2(0, -r * 0.42), r * 0.13, Color(0.2, 0.35, 0.6))
			draw_line(c + Vector2(0, -r * 0.15), c + Vector2(0, r * 0.55), Color(0.2, 0.35, 0.6), w * 1.3)


func _poly(pts: PackedVector2Array, col: Color) -> void:
	var o := pts.duplicate()
	o.append(pts[0])
	draw_colored_polygon(pts, col)
	draw_polyline(o, INK, 1.6, true)
