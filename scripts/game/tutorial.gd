extends Node
## Öğretici: adım listesi (kamera hedefi + ok + metin anahtarı + bekleme koşulu).
## target: bina tipi | "road" | "btn:<hud kontrolü>" ; wait: continue | select:<tip> | move | build:<tip> | crop

signal finished

const STEPS := [
	{"text": "TUT_COP", "target": "cop31", "wait": "select:cop31"},
	{"text": "TUT_CAMERA", "target": "", "wait": "continue"},
	{"text": "TUT_FIELD", "target": "field", "wait": "continue"},
	{"text": "TUT_WELL", "target": "well", "wait": "continue"},
	{"text": "TUT_WATER", "target": "btn:water", "wait": "continue"},
	{"text": "TUT_ROAD", "target": "road", "wait": "continue"},
	{"text": "TUT_CROP", "target": "field", "wait": "crop"},
	{"text": "TUT_MOVE", "target": "well", "wait": "move"},
	{"text": "TUT_BUILD", "target": "btn:field", "wait": "build:field"},
	{"text": "TUT_DONE", "target": "", "wait": "continue"},
]

var game
var step := -1
var active := false
var _move_hint := ""  # taşıma adımında okun gösterdiği alt hedef
var _crop0 := ""  # ürün adımı başladığında tarlanın ürünü (değişince ilerler)


func start() -> void:
	active = true
	game.village.building_selected.connect(_on_selected)
	game.village.move_finished.connect(_on_moved)
	game.village.building_placed.connect(_on_built)
	_next()


func _next() -> void:
	step += 1
	if step >= STEPS.size():
		_finish()
		return
	var s: Dictionary = STEPS[step]
	var target: String = s.target
	game.hud.clear_arrow()
	if target.begins_with("btn:"):
		game.hud.point_control(game.hud.control_for(target.substr(4)))
		game.camera.reset_view()
	elif target == "road":
		var p := Vector2(Bal.ROAD_COLS[0] + 0.5, Bal.ROAD_ROWS[0] + 2.5) * Bal.CELL
		game.hud.point_world(p)
		game.camera.focus(p, game.camera.base_zoom * 1.25)
	elif target != "":
		var b = GameState.find_building(target)
		game.hud.point_world(b.center() - Vector2(0, b.size.y * Bal.CELL * 0.5))
		game.camera.focus(b.center(), game.camera.base_zoom * 1.25)
	else:
		game.camera.reset_view()
	if s.wait == "crop":
		_crop0 = GameState.find_building("field").crop
	var cb := Callable(self, "_next") if s.wait == "continue" else Callable()
	game.hud.show_dialog(tr(s.text), cb, true)


## Taşıma adımı üç alt adımlı: kuyuyu seç → Taşı'ya bas → yeşil kareye koy. Ok her birini sırayla gösterir.
func _process(_delta: float) -> void:
	if active and step >= 0 and step < STEPS.size() and String(STEPS[step].target).begins_with("btn:") and STEPS[step].wait != "continue":
		var c: Control = game.hud.control_for(String(STEPS[step].target).substr(4))
		if c and game.hud._arrow.target_control != c:
			game.hud.point_control(c)
	if _waiting("crop"):
		var f = GameState.find_building("field")
		if f and f.crop != _crop0:
			_next()
		return
	if not _waiting("move"):
		return
	var v = game.village
	var well = GameState.find_building("well")
	var hint := "well"
	if v.mode == "move":
		hint = "cell"
	elif v.selected == well and game.hud.control_for("move_btn") != null:
		hint = "btn"
	if hint == _move_hint and (hint != "btn" or game.hud._arrow.target_control == game.hud.control_for("move_btn")):
		return
	_move_hint = hint
	match hint:
		"well": game.hud.point_world(well.center() - Vector2(0, Bal.CELL * 0.5))
		"btn": game.hud.point_control(game.hud.control_for("move_btn"))
		"cell":
			var c := _free_cell_near(well.cell)
			game.hud.point_world((Vector2(c) + Vector2(0.5, 0.0)) * Bal.CELL)


func _free_cell_near(from: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var c := from + Vector2i(dx, dy)
				if game.village.can_place("well", c, GameState.find_building("well")) and game.village.road_adjacent("well", c):
					return c
	return from


func _waiting(kind: String) -> bool:
	return active and step >= 0 and step < STEPS.size() and STEPS[step].wait == kind


func _on_selected(b) -> void:
	if _waiting("select:" + b.type):
		_next()


func _on_moved(_b) -> void:
	if _waiting("move"):
		_next()


func _on_built(b) -> void:
	if _waiting("build:" + b.type):
		_next()


func skip() -> void:
	if active:
		_finish()


func _finish() -> void:
	active = false
	game.hud.hide_dialog()
	game.hud.clear_arrow()
	game.camera.reset_view()
	finished.emit()
