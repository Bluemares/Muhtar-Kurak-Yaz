extends Control
## Final ekranı: sonuç, refah, yanan bina, ürün, önlem/hasar karşılaştırması, iklim cümlesi.


func _ready() -> void:
	get_tree().paused = false
	Audio.stop_loops()
	Audio.duck(false)
	Audio.set_intensity(0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var r: Dictionary = GameState.final_result
	if r.is_empty():
		r = {"lost": true, "good": false, "won": false, "welfare": 0.0, "burned": 0, "produced": 0.0, "prevention": 0, "damage": 0, "missions": 0}
	var key := "END_LOST"
	var col := Color("ff6b6b")
	if r.good:
		key = "END_GOOD"
		col = Color("90ee90")
	elif r.won:
		key = "END_WON"
		col = Color("ffd166")
	elif not r.lost:
		key = "END_FAIL"
	if Bal.RENDER_3D:
		var bd := MenuBackdrop.new()
		bd.mood = 1 if (r.good or r.won) else (-1 if r.lost else 0)
		bd.shift = 0.0
		add_child(bd)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.35)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
	else:
		var bg := Landscape.new()
		bg.mood = 1 if (r.good or r.won) else (-1 if r.lost else 0)
		add_child(bg)
	if r.good or r.won:
		var conf := Art.sparkle(Vector2(640, 10), Color.GOLD)
		conf.one_shot = false
		conf.amount = 80
		conf.lifetime = 4.0
		conf.gravity = Vector2(0, 60)
		conf.direction = Vector2.DOWN
		conf.initial_velocity_min = 20
		conf.initial_velocity_max = 60
		conf.hue_variation_min = -1.0
		conf.hue_variation_max = 1.0
		conf.position = Vector2(640, -10)
		add_child(conf)
		conf.emitting = true
		Audio.play("upgrade", 0.0)
	UI.fade_in(self, 0.7)
	var m := UI.modal(self)
	m[0].color = Color(0, 0, 0, 0.35)
	var outer: VBoxContainer = m[1]
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	v.add_theme_constant_override("separation", 6)
	v.add_child(UI.label(tr(key + "_TITLE"), 34, col))
	# yıldızlar + sayarak artan puan
	var star_row := Control.new()
	star_row.custom_minimum_size = Vector2(840, 60)
	star_row.draw.connect(_draw_stars.bind(star_row, int(r.get("stars", 0))))
	v.add_child(star_row)
	_stars_box = star_row
	var sc := UI.label("", 26, Color("ffd166"))
	sc.add_theme_constant_override("outline_size", 6)
	v.add_child(sc)
	_score_label = sc
	_score_target = int(r.get("score", 0))
	_best_text = tr("END_NEW_BEST") if r.get("new_best", false) else tr("END_BEST") % int(r.get("best_score", 0))
	var tw := create_tween()
	tw.tween_method(_set_score, 0, _score_target, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var na: Array = r.get("new_ach", [])
	if not na.is_empty():
		var al := UI.label(tr("END_NEW_ACH") % ", ".join(na.map(func(a): return tr("ACH_" + String(a).to_upper()))), 17, Color(0.6, 1.0, 0.6))
		al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		al.custom_minimum_size = Vector2(840, 0)
		v.add_child(al)
	var desc := UI.label(tr(key + "_DESC"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(840, 0)
	v.add_child(desc)
	# istatistikler iki sütunda (panel 720p ekrana sığsın)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	grid.add_child(UI.label(tr("END_WELFARE") % int(r.welfare), 18))
	grid.add_child(UI.label(tr("END_PRODUCED") % int(r.produced), 16))
	grid.add_child(UI.label(tr("END_FED") % int(r.get("fed_pct", 100)), 16, Color(0.75, 1.0, 0.7)))
	grid.add_child(UI.label(tr("END_BURNED") % r.burned, 16))
	grid.add_child(UI.label(tr("END_MISSIONS") % [r.missions, Bal.MONTH_KEYS.size()], 16))
	var side_total := 0
	for ms in Bal.SIDE_MISSIONS:
		side_total += ms.size()
	grid.add_child(UI.label(tr("END_SIDE") % [int(r.get("side", 0)), side_total], 16))
	grid.add_child(UI.label(tr("END_PREVENTION") % [r.prevention, r.damage], 16, Color(0.7, 0.9, 1.0)))
	var pols: Array = r.get("policies", [])
	if not pols.is_empty():
		var names := pols.map(func(p): return tr("POL_" + String(p).to_upper()))
		var pl := UI.label(tr("END_POLICIES") % ", ".join(names), 16, Color(0.7, 0.85, 1.0))
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pl.custom_minimum_size = Vector2(840, 0)
		v.add_child(pl)
	var bars := Control.new()
	bars.custom_minimum_size = Vector2(840, 44)
	bars.draw.connect(_draw_bars.bind(bars, float(r.prevention), float(r.damage)))
	v.add_child(bars)
	ClimateReport.add_to(v, r.get("climate_report", {}), 800)
	var climate := UI.label(tr("END_CLIMATE"), 19, Color("ffe08a"))
	climate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	climate.custom_minimum_size = Vector2(840, 0)
	v.add_child(climate)
	var h := UI.hbox(10)
	h.add_child(UI.button(tr("BTN_REPLAY"), _replay, 180))
	h.add_child(UI.button(tr("BTN_MAIN_MENU"), _menu, 180))
	outer.add_child(h)


var _stars_box: Control
var _score_label: Label
var _score_target := 0
var _best_text := ""
var _star_t := 0.0


func _process(delta: float) -> void:
	_star_t += delta
	if _stars_box:
		_stars_box.queue_redraw()


func _set_score(v: int) -> void:
	_score_label.text = tr("END_SCORE") % v + "   " + (_best_text if v >= _score_target else "")


## 3 yıldız; kazanılanlar sırayla büyüyerek dolar.
func _draw_stars(c: Control, n: int) -> void:
	for i in 3:
		var appear := clampf((_star_t - 0.4 - i * 0.35) / 0.3, 0.0, 1.0)
		var on := i < n and appear > 0.0
		var k := 1.0 + (0.4 * (1.0 - appear) if on else 0.0)
		var center := Vector2(c.size.x * 0.5 + (i - 1) * 64.0, 32)
		var pts := PackedVector2Array()
		for j in 10:
			var a := -PI / 2 + j * PI / 5
			pts.append(center + Vector2(cos(a), sin(a)) * (26.0 if j % 2 == 0 else 11.0) * k)
		c.draw_colored_polygon(pts, Color("ffd166") if on else Color(0.3, 0.27, 0.25))
		pts.append(pts[0])
		c.draw_polyline(pts, Color(0.35, 0.2, 0.05), 2.0)


func _replay() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


## Önleme (mavi) ve hasar (kırmızı) çubukları: mesajı tek bakışta gösterir.
func _draw_bars(c: Control, prev: float, dmg: float) -> void:
	var mx := maxf(1.0, maxf(prev, dmg))
	var w := c.size.x
	c.draw_rect(Rect2(0, 4, w, 14), Color(0, 0, 0, 0.35))
	c.draw_rect(Rect2(0, 4, w * prev / mx, 14), Color(0.35, 0.7, 1.0))
	c.draw_rect(Rect2(0, 26, w, 14), Color(0, 0, 0, 0.35))
	c.draw_rect(Rect2(0, 26, w * dmg / mx, 14), Color(1.0, 0.4, 0.3))
