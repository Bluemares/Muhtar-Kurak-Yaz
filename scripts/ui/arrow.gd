extends Control
## Öğretici oku. Dünya konumunu ya da bir arayüz kontrolünü gösterir, zıplar.

var target_world := Vector2.ZERO
var target_control: Control = null
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var tip: Vector2
	if target_control and is_instance_valid(target_control) and target_control.is_visible_in_tree():
		var r := target_control.get_global_rect()
		tip = r.position + Vector2(r.size.x * 0.5, 0) - global_position
	elif target_control:
		return
	else:
		tip = View.to_screen(self, target_world, 0.9) - global_position
	tip.y -= 6 + abs(sin(_t * 5.0)) * 12.0
	var pts := PackedVector2Array([tip, tip + Vector2(-18, -26), tip + Vector2(-7, -26), tip + Vector2(-7, -56),
		tip + Vector2(7, -56), tip + Vector2(7, -26), tip + Vector2(18, -26)])
	var outline := pts.duplicate()
	outline.append(tip)
	draw_colored_polygon(pts, Color("ffd166"))
	draw_polyline(outline, Color.BLACK, 3.0)
