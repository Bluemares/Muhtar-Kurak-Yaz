extends Control
## İnşa dükkanı kart görseli: binanın küçük çizimi (oyundaki çizimle aynı tile'lar).

var kind := "field"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if Bal.RENDER_3D and is_visible_in_tree() and Engine.get_process_frames() % 15 == 0:
		queue_redraw()  # 3D küçük resim birkaç kare sonra hazır olur


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if Bal.RENDER_3D:
		var tex := Thumbs.building(kind)
		var k := minf(r.size.x / tex.get_width(), r.size.y / tex.get_height())
		var ts := Vector2(tex.get_size()) * k
		draw_texture_rect(tex, Rect2(r.get_center() - ts * 0.5, ts), false)
		if kind == "road_upgrade":
			var a := r.get_center() + Vector2(r.size.x * 0.3, -r.size.y * 0.2)
			draw_colored_polygon(PackedVector2Array([a + Vector2(0, -14), a + Vector2(-11, 0), a + Vector2(11, 0)]), Color(0.45, 0.85, 0.35))
			draw_rect(Rect2(a + Vector2(-5, 0), Vector2(10, 11)), Color(0.45, 0.85, 0.35))
		return
	var c := r.get_center()
	draw_texture_rect(Art.soft(), Rect2(Vector2(r.size.x * 0.1, r.size.y * 0.7), Vector2(r.size.x * 0.8, r.size.y * 0.3)), false, Color(0, 0, 0, 0.35))
	var T := minf(r.size.y * 0.5, r.size.x * 0.25)
	match kind:
		"field":
			var o := c - Vector2(T * 2, T)
			for y in 2:
				for x in 4:
					var rr := Rect2(o + Vector2(x, y) * T, Vector2(T, T))
					Art.tile(self, Art.FARM, (Art.F_SOIL_A if y == 0 else Art.F_SOIL_B)[x], rr)
					Art.tile(self, Art.FARM, 66, rr.grow(-1))
		"greenhouse":
			var o := c - Vector2(T * 2, T * 0.6)
			for x in 4:
				Art.tile(self, Art.FARM, Art.F_SOIL_A[x], Rect2(o + Vector2(x * T, T * 0.3), Vector2(T, T * 0.8)))
				Art.tile(self, Art.FARM, 42, Rect2(o + Vector2(x * T, 0), Vector2(T, T)))
			var g := Rect2(o - Vector2(2, 6), Vector2(T * 4 + 4, T * 1.3))
			draw_rect(g, Color(0.7, 0.9, 1.0, 0.32))
			draw_rect(g, Color(1, 1, 1, 0.85), false, 2.0)
			for i in range(1, 4):
				draw_line(g.position + Vector2(g.size.x * i / 4.0, 0), g.position + Vector2(g.size.x * i / 4.0, g.size.y), Color(1, 1, 1, 0.6), 1.5)
		"grove":
			for p in [[Vector2(-1.2, -0.6), 16], [Vector2(0.1, -0.9), 4], [Vector2(-0.5, -0.2), 28]]:
				Art.tile(self, Art.TOWN, p[1], Rect2(c + p[0] * T, Vector2(T, T) * 1.3))
		"well":
			draw_texture_rect(Sprites.well(), Rect2(c - Vector2(T, T), Vector2(T, T) * 2.0), false)
		"water_tower":
			var leg := Color(0.45, 0.3, 0.16)
			draw_line(c + Vector2(-T * 0.7, T), c + Vector2(-T * 0.3, -T * 0.2), leg, 4.0)
			draw_line(c + Vector2(T * 0.7, T), c + Vector2(T * 0.3, -T * 0.2), leg, 4.0)
			Art.tile(self, Art.FARM, 85, Rect2(c - Vector2(T * 0.75, T * 1.3), Vector2(T, T) * 1.5))
		"house":
			var o := c - Vector2(T, T)
			Art.tile(self, Art.TOWN, 52, Rect2(o, Vector2(T, T)))
			Art.tile(self, Art.TOWN, 54, Rect2(o + Vector2(T, 0), Vector2(T, T)))
			Art.tile(self, Art.TOWN, 84, Rect2(o + Vector2(0, T), Vector2(T, T)))
			Art.tile(self, Art.TOWN, 87, Rect2(o + Vector2(T, T), Vector2(T, T)))
		"road_paint", "road_erase":
			var o := c - Vector2(T * 1.5, T * 0.5)
			for x in 3:
				Art.tile(self, Art.TOWN, Art.T_DIRT[x % 3], Rect2(o + Vector2(x * T, 0), Vector2(T, T)))
			draw_line(c + Vector2(T * 0.6, -T * 0.9), c + Vector2(T * 1.3, -T * 1.6), Color(0.55, 0.36, 0.2), 4.0)
			draw_rect(Rect2(c + Vector2(T * 0.35, -T * 0.95), Vector2(T * 0.5, T * 0.35)), Color(0.9, 0.85, 0.7))
		"road_upgrade":
			var o := c - Vector2(T * 1.5, T * 0.5)
			for x in 3:
				Art.tile(self, Art.TOWN, Art.T_COBBLE, Rect2(o + Vector2(x * T, 0), Vector2(T, T)), Color(0.78, 0.74, 0.68))
			var a := c + Vector2(0, -T * 0.9)
			draw_colored_polygon(PackedVector2Array([a + Vector2(0, -T * 0.6), a + Vector2(-T * 0.5, 0), a + Vector2(T * 0.5, 0)]), Color(0.45, 0.85, 0.35))
			draw_rect(Rect2(a + Vector2(-T * 0.2, 0), Vector2(T * 0.4, T * 0.5)), Color(0.45, 0.85, 0.35))
