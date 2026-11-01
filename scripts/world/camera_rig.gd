extends Camera2D
## Köy kamerası: tekerlek zoom, orta/sağ tık sürükleme, WASD. Sinematiklerde dışarıdan tween edilir.

var base_zoom := 1.0
var cinematic := false
var world_rect := Rect2()
var _dragging := false
var _shake := 0.0
var _shake_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


var view_rect := Rect2()


## view: başlangıç görünümü (açık alan), bounds: kameranın gezebileceği tüm dünya.
func fit_to(view: Rect2, bounds := Rect2(), snap := true) -> void:
	view_rect = view
	world_rect = bounds if bounds.size != Vector2.ZERO else view
	var vs := get_viewport_rect().size
	base_zoom = minf((vs.x - 60.0) / view.size.x, (vs.y - 190.0) / view.size.y)
	if snap:
		zoom = Vector2.ONE * base_zoom
		position = home_position()


## HUD üst/alt çubukları için hafif aşağı kaydırılmış merkez.
func home_position() -> Vector2:
	return view_rect.get_center() + Vector2(0, 20.0 / base_zoom)


func focus(target: Vector2, z: float, dur := 0.6) -> Tween:
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", target, dur)
	tw.tween_property(self, "zoom", Vector2.ONE * z, dur)
	return tw


func reset_view(dur := 0.6) -> Tween:
	return focus(home_position(), base_zoom, dur)


## Ekran sarsıntısı: güç (piksel), süre (sn). Duraklatmada da çalışır.
func shake(power: float, dur: float) -> void:
	_shake = maxf(_shake, power)
	_shake_t = maxf(_shake_t, dur)


func _process(delta: float) -> void:
	if _shake_t > 0.0:
		_shake_t -= delta
		var k := _shake * clampf(_shake_t / 0.3, 0.0, 1.0)
		offset = Vector2(randf_range(-k, k), randf_range(-k, k))
		if _shake_t <= 0.0:
			_shake = 0.0
			offset = Vector2.ZERO
	if cinematic or get_tree().paused:
		return
	var dir := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1
	if Input.is_physical_key_pressed(KEY_W): dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.y += 1
	if dir != Vector2.ZERO:
		position += dir.normalized() * 500.0 * delta / zoom.x
	_clamp()


func _clamp() -> void:
	if world_rect.size == Vector2.ZERO:
		return
	var r := world_rect.grow(120)
	position = position.clamp(r.position, r.end)


func _unhandled_input(event: InputEvent) -> void:
	if cinematic or get_tree().paused:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = (zoom * 1.1).clamp(Vector2.ONE * base_zoom * 0.5, Vector2.ONE * 2.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = (zoom / 1.1).clamp(Vector2.ONE * base_zoom * 0.5, Vector2.ONE * 2.5)
		elif event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom.x
		_clamp()
