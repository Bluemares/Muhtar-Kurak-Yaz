extends Control
## Ürün ikonu (ürün seçici butonları): sebze/domates, kavun, mısır, buğday. Vektör çizim.

var crop := "veg"


func _draw() -> void:
	var c := size * 0.5
	var k := minf(size.x, size.y) / 28.0
	draw_set_transform(c, 0.0, Vector2.ONE * k)
	match crop:
		"melon":
			draw_circle(Vector2(0, 2), 11, Color(0.35, 0.62, 0.22))
			for i in 3:
				draw_arc(Vector2(0, 2), 11, -PI * 0.5 + (i - 1) * 0.6, -PI * 0.5 + (i - 1) * 0.6 + PI, 10, Color(0.75, 0.9, 0.45), 1.5)
		"corn":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -12), Vector2(6, -4), Vector2(5, 9), Vector2(-5, 9), Vector2(-6, -4)]), Color(1.0, 0.82, 0.25))
			for i in 4:
				draw_line(Vector2(-5, -6 + i * 4), Vector2(5, -6 + i * 4), Color(0.85, 0.6, 0.1), 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-2, 12), Vector2(-11, -2), Vector2(-4, 4)]), Color(0.45, 0.7, 0.25))
			draw_colored_polygon(PackedVector2Array([Vector2(2, 12), Vector2(11, -2), Vector2(4, 4)]), Color(0.45, 0.7, 0.25))
		"wheat":
			var gold := Color(0.95, 0.78, 0.3)
			draw_line(Vector2(0, 12), Vector2(0, -8), gold, 2.0)
			for i in 4:
				var y := -9.0 + i * 4.5
				draw_colored_polygon(PackedVector2Array([Vector2(0, y + 3), Vector2(-6, y - 2), Vector2(-2, y + 5)]), gold)
				draw_colored_polygon(PackedVector2Array([Vector2(0, y + 3), Vector2(6, y - 2), Vector2(2, y + 5)]), gold)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(0, 12)]), Color(1.0, 0.55, 0.12))
			for i in 3:
				draw_line(Vector2(-3, -1 + i * 4), Vector2(1, -1 + i * 4), Color(0.8, 0.35, 0.05), 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -5), Vector2(-6, -13), Vector2(-1, -8)]), Color(0.3, 0.65, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -5), Vector2(6, -13), Vector2(1, -8)]), Color(0.3, 0.65, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -5), Vector2(0, -14), Vector2(2, -7)]), Color(0.35, 0.72, 0.25))
	draw_set_transform(Vector2.ZERO)
