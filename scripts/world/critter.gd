class_name Critter
extends Node2D
## Süs hayvanı (tavuk/koyun/inek): köyde rastgele dolaşır, durup yem arar.

var village
var kind := 122
var _path: Array = []
var area := Rect2()
var _target := Vector2.ZERO
var _wait := 0.0
var _t := 0.0
var _left := false


func _ready() -> void:
	_t = randf() * 5.0
	_target = position


func _process(delta: float) -> void:
	_t += delta
	if get_tree().paused:
		return
	if _wait > 0.0:
		_wait -= delta
	elif _path.is_empty():
		_wait = randf_range(1.0, 4.0)
		_target = (position + Vector2(randf_range(-110, 110), randf_range(-80, 80))).clamp(area.position, area.end)
		_path = village.find_path(position, _target) if village else [_target]
	else:
		var next: Vector2 = _path[0]
		_left = next.x < position.x
		var step := position.move_toward(next, 22.0 * delta)
		if village and not village.segment_clear(position, step):
			_path.clear()
			if village.point_blocked(position):
				position = village.walkable_point(position)
			return
		position = step
		if position.distance_to(next) < 1.0:
			_path.pop_front()
	queue_redraw()


func _draw() -> void:
	var moving := _wait <= 0.0
	var bob := absf(sin(_t * 10.0)) * 2.0 if moving else 0.0
	var peck := 0.0 if moving or kind != 122 else maxf(0.0, sin(_t * 6.0)) * 0.35
	draw_texture_rect(Art.soft(), Rect2(-9, 2, 18, 6), false, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -bob), -peck if _left else peck)
	Art.tile(self, Art.FARM, kind, Rect2(-11, -18, 22, 22), Color.WHITE, _left)
