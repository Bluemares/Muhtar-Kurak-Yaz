extends Control
## Her konuşmacı için ayrı, 2D SVG karakter çizimi.
## role: hasan | cop | fire | teacher | farmer | press

const BG := {"hasan": Color("6b8f4e"), "cop": Color("2f6fa8"), "fire": Color("a8322a"),
	"teacher": Color("7a5aa0"), "farmer": Color("b0843a"), "press": Color("4a5560")}

var role := "hasan":
	set(v):
		role = v
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	process_mode = Node.PROCESS_MODE_ALWAYS  # diyaloglar çoğu zaman oyun duraklatılmışken açılır


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("2b1d14"))
	draw_rect(r.grow(-3), BG.get(role, Color.GRAY))
	draw_rect(Rect2(r.position + Vector2(3, r.size.y * 0.62), Vector2(r.size.x - 6, r.size.y * 0.38 - 3)), BG.get(role, Color.GRAY).darkened(0.2))
	draw_texture_rect(Thumbs.portrait(role), r.grow(-3), false)
