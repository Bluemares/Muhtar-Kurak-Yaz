extends Node
## SADECE GELİŞTİRME İÇİN test tuşları. Kaldırmak için: bu dosyayı sil ve project.godot [autoload] altındaki DebugTools satırını sil.
## F1: tur süresi 30 sn | F2: yangın çıkar | F3: böcek | F4: +500 para | F5: turu bitir | F6: refah -20 | F7: HUD gizle/göster (video çekimi)
## F9: FPS göstergesi (release'te de açık; web performansını ölçmek için)

## Release export'ta otomatik kapalı.
var ENABLED := OS.is_debug_build()


var _fps: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _fps and _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()


func _toggle_fps() -> void:
	if _fps == null:
		var layer := CanvasLayer.new()
		layer.layer = 120
		add_child(layer)
		_fps = Label.new()
		_fps.position = Vector2(8, 64)
		_fps.add_theme_font_size_override("font_size", 20)
		_fps.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		_fps.add_theme_constant_override("outline_size", 6)
		_fps.add_theme_color_override("font_outline_color", Color.BLACK)
		layer.add_child(_fps)
	else:
		_fps.visible = not _fps.visible


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and event.keycode == KEY_F9:
		_toggle_fps()
		return
	if not ENABLED or not event.pressed or event.echo:
		return
	var game = get_tree().get_first_node_in_group("game")
	if game == null:
		return
	match event.keycode:
		KEY_F1:
			GameState.round_time_left = minf(GameState.round_time_left, 30.0)
		KEY_F2:
			if not game.fire_active and not get_tree().paused:
				var c := GameState.buildings.filter(func(b): return Bal.BUILDINGS[b.type].flammable and b.state == "normal")
				if not c.is_empty():
					game.ignite(c.pick_random())
		KEY_F3:
			var f := GameState.buildings.filter(func(b): return b.type == "field" and b.state == "normal")
			if not f.is_empty():
				f.pick_random().pest = true
		KEY_F4:
			GameState.add_money(500)
		KEY_F5:
			GameState.round_time_left = 0.1
		KEY_F6:
			GameState.welfare = maxf(0.0, GameState.welfare - 20.0)
		KEY_F7:
			game.hud.visible = not game.hud.visible
