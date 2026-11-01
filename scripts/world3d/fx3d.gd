class_name Fx3D
extends RefCounted
## 3D parçacık efektleri (CPUParticles3D: web/Compatibility uyumlu). Yumuşak daire dokulu kameraya dönük kareler.

static var _mats := {}


static func mat(additive: bool) -> StandardMaterial3D:
	var key := "add" if additive else "mix"
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = Art.soft()
		m.disable_receive_shadows = true
		_mats[key] = m
	return _mats[key]


static func _ramp(cols: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for i in cols.size():
		g.add_point(float(i) / (cols.size() - 1), cols[i])
	return g


static func _curve(a: float, b: float) -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0, a))
	c.add_point(Vector2(1, b))
	return c


static func _base(amount: int, life: float, size: float, additive: bool, ext: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = mat(additive)
	p.mesh = q
	p.amount = amount
	p.lifetime = life
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3.UP
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## Alev: sarıdan kırmızıya, yukarı ve küçülerek.
static func fire(ext: Vector3) -> CPUParticles3D:
	var p := _base(70, 0.9, 0.42, false, ext)
	p.spread = 12.0
	p.gravity = Vector3(0, 0.6, 0)
	p.initial_velocity_min = 0.9
	p.initial_velocity_max = 1.8
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.4
	p.scale_amount_curve = _curve(1.0, 0.15)
	p.color_ramp = _ramp([Color(1, 0.95, 0.55, 0.0), Color(1, 0.82, 0.25, 1.0), Color(1, 0.42, 0.08, 0.95), Color(0.75, 0.15, 0.04, 0.0)])
	return p


static func smoke(ext: Vector3) -> CPUParticles3D:
	var p := _base(26, 3.2, 0.7, false, ext)
	p.spread = 18.0
	p.gravity = Vector3(0.25, 0.15, 0.1)
	p.initial_velocity_min = 0.45
	p.initial_velocity_max = 0.8
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.5
	p.scale_amount_curve = _curve(0.5, 2.4)
	p.color_ramp = _ramp([Color(0.2, 0.18, 0.17, 0.0), Color(0.22, 0.2, 0.19, 0.85), Color(0.42, 0.4, 0.38, 0.55), Color(0.6, 0.58, 0.56, 0.0)])
	return p


static func embers(ext: Vector3) -> CPUParticles3D:
	var p := _base(24, 1.6, 0.07, true, ext)
	p.spread = 35.0
	p.gravity = Vector3(0, 0.4, 0)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.2
	p.color_ramp = _ramp([Color(1, 0.9, 0.4, 1.0), Color(1, 0.4, 0.1, 0.8), Color(1, 0.2, 0.05, 0.0)])
	return p


## Böcek sürüsü: tarla üstünde vızıldayan koyu noktalar.
static func pests(ext: Vector3) -> CPUParticles3D:
	var p := _base(34, 1.2, 0.11, false, ext)
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.7
	p.orbit_velocity_min = 0.4
	p.orbit_velocity_max = 0.8
	p.color_ramp = _ramp([Color(0.1, 0.08, 0.04, 0.0), Color(0.1, 0.08, 0.04, 1.0), Color(0.1, 0.08, 0.04, 0.0)])
	return p


## Tek seferlik patlama: dust | upgrade | repair | water | diğer (yeşil parıltı). Bitince kendini siler.
static func burst(kind: String, ext: Vector3) -> CPUParticles3D:
	var p: CPUParticles3D
	if kind == "dust":
		p = _base(40, 1.1, 0.5, false, Vector3(ext.x, 0.05, ext.z))
		p.direction = Vector3(0, 0.3, 0)
		p.spread = 90.0
		p.gravity = Vector3(0, -0.5, 0)
		p.initial_velocity_min = 1.0
		p.initial_velocity_max = 2.0
		p.scale_amount_curve = _curve(0.6, 1.8)
		p.color_ramp = _ramp([Color(0.85, 0.75, 0.55, 0.8), Color(0.85, 0.75, 0.55, 0.0)])
	else:
		var col: Color = {"upgrade": Color.GOLD, "repair": Color.AQUAMARINE, "water": Color(0.4, 0.75, 1.0)}.get(kind, Color.GREEN_YELLOW)
		p = _base(36, 1.0, 0.16, true, ext)
		p.spread = 30.0
		p.gravity = Vector3(0, -1.0, 0)
		p.initial_velocity_min = 1.2
		p.initial_velocity_max = 2.4
		p.color_ramp = _ramp([Color(col, 1.0), Color(col, 0.0)])
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p
