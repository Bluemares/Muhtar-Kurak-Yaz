class_name Terrain
extends RefCounted
## Sabit (her oyunda aynı) arazi: nehir, kayalık, orman. Bu hücrelere bina konamaz.
## Köy merkezi (ilk açık alan) ve yollar araziden her zaman temizdir.

static var _cells := {}


static func kind(c: Vector2i) -> String:
	if _cells.is_empty():
		_build()
	if GameState.cleared.has(c):
		return ""
	return _cells.get(c, "")


## Temizlenmeden önceki arazi türü (görsel/maliyet için).
static func original(c: Vector2i) -> String:
	if _cells.is_empty():
		_build()
	return _cells.get(c, "")


static func is_river(c: Vector2i) -> bool:
	return kind(c) == "river"


## Hücreye en yakın nehir hücresinin uzaklığı (hücre). Kuyu bonusu için.
static func river_distance(c: Vector2i) -> float:
	if _cells.is_empty():
		_build()
	var best := INF
	for k in _cells:
		if _cells[k] == "river":
			best = minf(best, Vector2(k - c).length())
	return best


static func river_x(y: int) -> int:
	return 27 + int(round(2.5 * sin(y * 0.33 + 0.6)))


static func _h(x: int, y: int, k: int) -> float:
	var n := (x * 374761393 + y * 668265263 + k * 2147483) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float(n % 10000) / 10000.0


static func _blocked(c: Vector2i) -> bool:
	return Bal.UNLOCK_RECTS[1].has_point(c) or c.y in Bal.ROAD_ROWS or c.x in Bal.ROAD_COLS


static func _build() -> void:
	for y in Bal.GRID_H:
		var x0 := river_x(y)
		for x in [x0, x0 + 1]:
			if x < Bal.GRID_W:
				_cells[Vector2i(x, y)] = "river"
	var rocks := [[Vector2(3, 4), 2.2], [Vector2(4, 18), 2.0], [Vector2(21, 19), 1.6], [Vector2(12, 2), 1.6], [Vector2(31, 3), 1.8]]
	var forests := [[Vector2(5, 11), 3.2], [Vector2(18, 20), 2.6], [Vector2(1, 19), 2.4], [Vector2(31, 17), 2.2], [Vector2(21, 1), 2.4], [Vector2(8, 1), 2.0]]
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x, y)
			if _cells.has(c) or _blocked(c):
				continue
			for r in rocks:
				if Vector2(c).distance_to(r[0]) < r[1] and _h(x, y, 1) < 0.7:
					_cells[c] = "rock"
			if _cells.has(c):
				continue
			for f in forests:
				if Vector2(c).distance_to(f[0]) < f[1] and _h(x, y, 2) < 0.85:
					_cells[c] = "forest"
