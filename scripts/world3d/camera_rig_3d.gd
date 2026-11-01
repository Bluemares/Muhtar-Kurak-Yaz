extends Node
## Diorama kamerası. 2D kamera ile aynı arayüz (position/zoom dünya pikselinde, focus, shake, fit_to),
## böylece oyun akışı ve sinematikler değişmeden çalışır.
## Kontroller: sağ tık sürükle → döndür/eğ, orta tık sürükle / WASD → kaydır, Q/E → döndür, tekerlek → yakınlaş.

const FOV := 34.0
const PITCH_MIN := 28.0
const PITCH_MAX := 72.0

var position := Vector2.ZERO  # bakılan nokta (dünya pikseli)
var zoom := Vector2.ONE       # base_zoom'a göre; büyüdükçe yaklaşır
var offset := Vector2.ZERO
var base_zoom := 1.0
var cinematic := false
var world_rect := Rect2()
var view_rect := Rect2()
var yaw := -32.0
var pitch := 52.0

var cam := Camera3D.new()
var _base_dist := 30.0
var _rotating := false
var _panning := false
var _press_pos := Vector2.ZERO
var _shake := 0.0
var _shake_t := 0.0
var _focus_tween: Tween
var _fire_shot := false
var _fire_saved := {}
var _fire_eye := Vector3.ZERO
var _fire_target := Vector3.ZERO
var _fire_heading := 0.0
var _fire_last := Vector2.ZERO
var _fire_origin := Vector2.ZERO
var _fire_pullback := 0.0
var _fire_subject: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cam.fov = FOV
	cam.near = 0.3
	cam.far = 400.0
	add_child(cam)
	_apply()


func make_current() -> void:
	cam.make_current()


## view: başlangıç görünümü (açık alan), bounds: kameranın gezebileceği tüm dünya.
func fit_to(view: Rect2, bounds := Rect2(), snap := true) -> void:
	view_rect = view
	world_rect = bounds if bounds.size != Vector2.ZERO else view
	var s := view.size / Bal.CELL
	var t := tan(deg_to_rad(FOV * 0.5))
	var vs := cam.get_viewport().get_visible_rect().size if cam.is_inside_tree() else Vector2(1280, 720)
	var aspect := vs.x / maxf(vs.y, 1.0)
	_base_dist = maxf(s.x / (2.0 * t * aspect), s.y * 1.25 / (2.0 * t)) * 1.05
	base_zoom = 1.0
	if snap:
		zoom = Vector2.ONE * base_zoom
		position = home_position()
	_apply()


func home_position() -> Vector2:
	return view_rect.get_center()


func focus(target: Vector2, z: float, dur := 0.6) -> Tween:
	if _focus_tween and _focus_tween.is_valid():
		_focus_tween.kill()
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_focus_tween = tw
	tw.tween_property(self, "position", target, dur)
	tw.tween_property(self, "zoom", Vector2.ONE * z, dur)
	return tw


func reset_view(dur := 0.6) -> Tween:
	return focus(home_position(), base_zoom, dur)


func shake(power: float, dur: float) -> void:
	_shake = maxf(_shake, power)
	_shake_t = maxf(_shake_t, dur)


func distance() -> float:
	return _base_dist * base_zoom / maxf(zoom.x, 0.05)


## Dünya pikseli → ekran koordinatı.
func world_to_screen(p: Vector2, h := 0.0) -> Vector2:
	var v := View.to3(p, h)
	if cam.is_position_behind(v):
		return Vector2(-9999, -9999)
	return cam.unproject_position(v)


## Ekran → zemin düzlemindeki dünya pikseli.
func screen_to_world(sp: Vector2) -> Vector2:
	var o := cam.project_ray_origin(sp)
	var d := cam.project_ray_normal(sp)
	if absf(d.y) < 0.0001:
		return Vector2(-99999, -99999)
	var t := -o.y / d.y
	return View.to2(o + d * t)


func _process(delta: float) -> void:
	if _fire_shot and is_instance_valid(_fire_subject):
		track_fire_shot(_fire_subject.position, delta)
	offset = Vector2.ZERO
	if _shake_t > 0.0:
		_shake_t -= delta
		var k := _shake * clampf(_shake_t / 0.3, 0.0, 1.0)
		offset = Vector2(randf_range(-k, k), randf_range(-k, k))
		if _shake_t <= 0.0:
			_shake = 0.0
	if not cinematic and not get_tree().paused:
		var dir := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
		if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
		if Input.is_physical_key_pressed(KEY_D): dir.x += 1
		if Input.is_physical_key_pressed(KEY_W): dir.y -= 1
		if Input.is_physical_key_pressed(KEY_S): dir.y += 1
		if dir != Vector2.ZERO:
			position += dir.normalized().rotated(-deg_to_rad(yaw)) * distance() * 0.9 * Bal.CELL * delta
		var r := 0.0
		if Input.is_physical_key_pressed(KEY_Q): r -= 1
		if Input.is_physical_key_pressed(KEY_E): r += 1
		yaw += r * 90.0 * delta
		_clamp()
	_apply()


func _clamp() -> void:
	if world_rect.size == Vector2.ZERO:
		return
	var r := world_rect.grow(Bal.CELL * 2)
	position = position.clamp(r.position, r.end)
	zoom = zoom.clamp(Vector2.ONE * base_zoom * 0.45, Vector2.ONE * base_zoom * 4.0)


func _apply() -> void:
	if _fire_shot:
		cam.position = _fire_eye
		cam.look_at(_fire_target, Vector3.UP)
		return
	var target := View.to3(position)
	var d := distance()
	var basis := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, -deg_to_rad(pitch))
	var eye := target + basis * Vector3(0, 0, d)
	cam.transform = Transform3D(basis, eye)
	if offset != Vector2.ZERO:
		cam.position += basis * Vector3(offset.x, offset.y, 0) * 0.004 * d


func _unhandled_input(event: InputEvent) -> void:
	if cinematic or get_tree().paused:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom *= 1.1
			_clamp()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom /= 1.1
			_clamp()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_rotating = event.pressed
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
	elif event is InputEventMouseMotion:
		if _rotating:
			yaw -= event.relative.x * 0.35
			pitch = clampf(pitch + event.relative.y * 0.25, PITCH_MIN, PITCH_MAX)
		elif _panning:
			var k := distance() * 0.0016 * Bal.CELL
			position -= event.relative.rotated(-deg_to_rad(yaw)) * k
			_clamp()


## A dedicated front-facing shot, independent of the player's previous orbit/zoom.
func begin_fire_shot(at: Vector2, heading: float) -> void:
	if _focus_tween and _focus_tween.is_valid():
		_focus_tween.kill()
	if not _fire_shot:
		_fire_saved = {"position": position, "zoom": zoom, "yaw": yaw, "pitch": pitch}
	_fire_shot = true
	cinematic = true
	_fire_heading = heading
	_fire_last = at
	_fire_origin = at
	_fire_pullback = 0.0
	_fire_target = View.to3(at, 0.8)
	_fire_eye = View.to3(at, 2.15) + Vector3(sin(heading),0,cos(heading)) * 5.5
	_apply()


func track_fire_shot(at: Vector2, delta: float) -> void:
	if not _fire_shot:
		return
	var motion := at - _fire_last
	_fire_last = at
	if motion.length() > 0.05:
		_fire_heading = lerp_angle(_fire_heading, atan2(motion.x, motion.y), minf(delta * 4.0, 1.0))
	var focus := View.to3(at, 0.65)
	if at.distance_to(_fire_origin) > Bal.CELL * 1.6:
		_fire_pullback = move_toward(_fire_pullback,1.0,delta*0.45)
	var distance_back := lerpf(5.5,10.5,smoothstep(0.0,1.0,_fire_pullback))
	var elevation := lerpf(2.15,6.0,smoothstep(0.0,1.0,_fire_pullback))
	var eye := View.to3(at, elevation) + Vector3(sin(_fire_heading+_fire_pullback*0.28),0,cos(_fire_heading+_fire_pullback*0.28)) * distance_back
	_fire_target = _fire_target.lerp(focus, 1.0-exp(-delta*7.0))
	_fire_eye = _fire_eye.lerp(eye, 1.0-exp(-delta*5.0))


func end_fire_shot() -> void:
	_fire_subject = null
	if not _fire_shot:
		return
	_fire_shot = false
	cinematic = false
	position = _fire_saved.position
	zoom = _fire_saved.zoom
	yaw = _fire_saved.yaw
	pitch = _fire_saved.pitch
	_apply()


func follow_fire_subject(subject: Node2D) -> void:
	_fire_subject = subject
