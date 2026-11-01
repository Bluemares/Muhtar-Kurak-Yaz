class_name BuildingView3D
extends Node3D
## Tek binanın 3D görüntüsü: mantıktaki Building'i izler (tür/seviye değişince yeniden kurulur,
## durum → üst malzeme, tarla olgunluğu → bitki evresi, seçim → zemin çerçevesi).

const PAD_SHADER := preload("res://shaders/select_pad.gdshader")

static var _burn: ShaderMaterial
static var _ruin: ShaderMaterial
static var _build: ShaderMaterial

var b  # Building
var model: Node3D
var plants: Node3D
var pad := MeshInstance3D.new()
var _pad_mat := ShaderMaterial.new()
var _key := ""
var _rotation_index := -1
var _display_angle := 0.0
var _target_angle := 0.0
var _turn_tween: Tween
var _plant_key := ""
var _overlay = null
var _overlay_dirty := true
var _fire: CPUParticles3D
var _smoke: CPUParticles3D
var _embers: CPUParticles3D
var _pests: CPUParticles3D
var _fire_light := OmniLight3D.new()
var _window_light: OmniLight3D
var _lamp_light: OmniLight3D
var _lamp_glow: MeshInstance3D
var _burst_seq := 0
var _t := 0.0
var _tt_fire: Node3D
var _well_motion: Node3D
var _garage_open := 0.0

## Bina tepesinin yaklaşık yüksekliği (efekt ve bilgi göstergeleri için).
const TOP := {"granary": 1.5, "lamp": 1.4, "house": 1.24, "cop31": 2.93, "fire_station": 1.92, "well": 1.15, "field": 0.45, "greenhouse": 0.6, "water_tower": 2.15, "grove": 0.8}


static func top(building) -> float:
	var h: float = TOP.get(building.type, 1.0)
	return h


func _init(building) -> void:
	b = building


func _ready() -> void:
	overlays()
	_pad_mat.shader = PAD_SHADER
	var pm := PlaneMesh.new()
	pad.mesh = pm
	pad.material_override = _pad_mat
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pad.position.y = 0.03
	add_child(pad)
	var s: Vector2i = b.size
	var ext := Vector3(s.x * 0.36, 0.15, s.y * 0.36)
	_fire = Fx3D.fire(ext)
	_smoke = Fx3D.smoke(ext)
	_embers = Fx3D.embers(ext)
	var roof := top(b) * 0.72
	for p in [_fire, _smoke, _embers]:
		p.position.y = roof
		p.emitting = false
		add_child(p)
	_fire.emission_box_extents = Vector3(s.x * 0.4, roof * 0.45, s.y * 0.4)
	_smoke.position.y = roof + 0.3
	_fire_light.light_color = Color(1.0, 0.5, 0.15)
	_fire_light.omni_range = 2.5 + s.x
	_fire_light.position.y = 0.9
	_fire_light.light_energy = 0.0
	add_child(_fire_light)
	if b.type in ["house", "cop31", "fire_station", "greenhouse"]:
		_window_light = OmniLight3D.new()
		_window_light.light_color = Color(1.0, 0.78, 0.45)
		_window_light.omni_range = 1.6 + s.x * 0.6
		_window_light.position = Vector3(0, 0.55, 0.65)
		_window_light.light_energy = 0.0
		add_child(_window_light)
	if b.type == "lamp":
		_lamp_light = OmniLight3D.new()
		_lamp_light.light_color = Color(1.0, 0.8, 0.5)
		_lamp_light.omni_range = Bal.LAMP_RANGE
		_lamp_light.position.y = 1.25
		_lamp_light.shadow_enabled = false
		add_child(_lamp_light)
		var gm := StandardMaterial3D.new()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.albedo_color = Color(1.0, 0.85, 0.5)
		_lamp_glow = BuildingKit.prim(self, SphereMesh.new(), gm, Vector3(0, 1.22, 0))
		_lamp_glow.scale = Vector3.ONE * 0.13
		_lamp_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if b.type not in ["field", "greenhouse", "grove"]:
		_tt_fire = preload("res://tt_models/scripts/fire_effect.gd").new()
		add_child(_tt_fire)
		_tt_fire.setup("cop" if b.type == "cop31" else b.type)
		_tt_fire.visible = false
	if b.type == "field":
		_pests = Fx3D.pests(Vector3(0.8, 0.2, 0.8))
		_pests.position.y = 0.45
		_pests.emitting = false
		add_child(_pests)


static func _overlay_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


static func overlays() -> void:
	if _burn:
		return
	_burn = _overlay_mat("shader_type spatial;\nrender_mode unshaded, blend_add, shadows_disabled;\nvoid fragment() {\n\tfloat f = 0.55 + 0.25 * sin(TIME * 13.0) + 0.2 * sin(TIME * 31.0);\n\tALBEDO = vec3(1.0, 0.3, 0.04) * f * 0.5;\n}")
	_ruin = _overlay_mat("shader_type spatial;\nrender_mode unshaded, blend_mul, shadows_disabled;\nvoid fragment() {\n\tALBEDO = vec3(0.24, 0.21, 0.19);\n}")
	_build = _overlay_mat("shader_type spatial;\nrender_mode unshaded, blend_mix, shadows_disabled;\nvoid fragment() {\n\tALBEDO = vec3(1.0, 0.95, 0.75);\n\tALPHA = 0.3 + 0.15 * sin(TIME * 6.0);\n}")


func sync() -> void:
	var key := "%s|%d|%s" % [b.type, b.level, b.state == "ruined"]
	if key != _key:
		_key = key
		if model:
			model.queue_free()
		_well_motion = null
		if b.state == "ruined" and b.type not in ["field", "greenhouse", "grove"]:
			model = Node3D.new()
			var rubble := BuildingKit.TT.model("house", b.level, true)
			var rubble_bounds := BuildingKit._bounds(rubble)
			rubble.scale = Vector3(b.size.x * 0.94 / rubble_bounds.size.x, 1.0, b.size.y * 0.94 / rubble_bounds.size.z)
			model.add_child(rubble)
		else:
			model = BuildingKit.build(b.type, b.level, b._variant)
		add_child(model)
		_well_motion = model.find_child("WellMotion", true, false)
		if _tt_fire:
			var bounds := BuildingKit._bounds(model)
			_tt_fire.roof_height = bounds.end.y * 0.72
			_tt_fire.width = maxf(bounds.size.x, bounds.size.z) * 0.35
		_overlay_dirty = true
		var s: Vector2i = b.size
		(pad.mesh as PlaneMesh).size = Vector2(s.x, s.y) + Vector2(0.2, 0.2)
		_pad_mat.set_shader_parameter("size", Vector2(s.x, s.y) + Vector2(0.2, 0.2))
	position = View.to3(b.center(), b._drop / Bal.CELL)
	_sync_plants()
	var footprint: Vector2 = Vector2(b.size)+Vector2(0.2,0.2)
	(pad.mesh as PlaneMesh).size = footprint
	_pad_mat.set_shader_parameter("size",footprint)
	if _rotation_index < 0:
		_rotation_index = b.rot
		_target_angle = -b.rot*PI*0.5
		_set_display_angle(_target_angle)
	elif _rotation_index != b.rot:
		_target_angle -= posmod(b.rot-_rotation_index,4)*PI*0.5
		_rotation_index = b.rot
		if _turn_tween and _turn_tween.is_valid(): _turn_tween.kill()
		_turn_tween = create_tween()
		_turn_tween.tween_method(_set_display_angle,_display_angle,_target_angle,0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_set_display_angle(_display_angle)
	var st: String = b.state
	var want = null
	if st == "burning":
		want = _burn
	elif st == "ruined":
		want = _ruin
	elif st == "moving":
		want = _build
	if want != _overlay or _overlay_dirty:
		_overlay = want
		_overlay_dirty = false
		_apply_overlay(model, want)
		if plants:
			_apply_overlay(plants, want)
	model.scale = Vector3.ONE * b._pop
	if st == "ruined" and b.type in ["field", "greenhouse", "grove"]:
		model.scale.y = 0.55
	_sync_garage()
	_sync_well()
	_effects(st)
	var risky: bool = View.risk_map and Bal.BUILDINGS[b.type].flammable and st == "normal"
	var wet: bool = View.moist_map and b.is_crop() and st == "normal"
	pad.visible = b.selected or b.hovered or risky or wet
	if b.selected:
		_pad_mat.set_shader_parameter("color", Color(1.0, 0.85, 0.3, 1.0))
	elif wet:
		_pad_mat.set_shader_parameter("color", View.moist_color(GameState.moisture(b)))
	elif risky:
		_pad_mat.set_shader_parameter("color", View.risk_color(GameState.fire_risk_per_minute(b)))
	else:
		_pad_mat.set_shader_parameter("color", Color(1, 1, 1, 0.55))


func _set_display_angle(angle: float) -> void:
	_display_angle = angle
	if is_instance_valid(model): model.basis = Basis(Vector3.UP,angle).scaled(model.scale)
	if is_instance_valid(plants): plants.basis = Basis(Vector3.UP,angle)


func _sync_garage() -> void:
	if b.type != "fire_station" or not model:
		return
	var door := model.get_node_or_null("GarageDoor") as Node3D
	var parked := model.get_node_or_null("ParkedTruck") as Node3D
	if door:
		_garage_open = move_toward(_garage_open, 1.0 if b.get_meta("garage_open", false) else 0.0, get_process_delta_time() * 1.6)
		door.scale.y = maxf(0.015, 1.0 - _garage_open)
	if parked:
		parked.visible = not b.get_meta("truck_away", false)


func _sync_well() -> void:
	if not is_instance_valid(_well_motion):
		return
	var progress := -1.0
	var hand := Vector3.ZERO
	for worker in GameState.workers:
		if is_instance_valid(worker) and worker._carry_well == b and worker.carry_stage == 1 and worker.state == Worker.State.WORKING:
			progress = worker._carry_t / maxf(Bal.CARRY_FILL_TIME, 0.01)
			hand = View.to3(worker.position) + Vector3(0, 0.35, 0)
			break
	_well_motion.update_motion(progress, hand)


func _effects(st: String) -> void:
	_t += get_process_delta_time()
	var night := GameState.night_factor()
	_fire.emitting = st == "burning" and _tt_fire == null
	_embers.emitting = st == "burning" and _tt_fire == null
	_smoke.emitting = (st == "burning" or st == "ruined") and _tt_fire == null
	if _tt_fire:
		_tt_fire.update_effect(get_process_delta_time(), st == "burning", st == "ruined", 1.0)
	_fire_light.light_energy = (0.35 + night * 1.8) * (0.85 + 0.15 * sin(_t * 13.0)) if st == "burning" else 0.0
	_fire_light.visible = _fire_light.light_energy > 0.01
	if _lamp_light:
		var lit: bool = b.is_operational()
		_lamp_light.light_energy = clampf(night * 1.6 + 0.15, 0.0, 2.0) if lit else 0.0
		_lamp_light.visible = lit and night > 0.05
		_lamp_glow.visible = lit
	if _window_light:
		_window_light.light_energy = night * 1.2 if st == "normal" else 0.0
		_window_light.visible = _window_light.light_energy > 0.01
	if _pests:
		_pests.emitting = b.pest and st != "ruined"
	if b.burst_seq != _burst_seq:
		_burst_seq = b.burst_seq
		var s: Vector2i = b.size
		var fx: CPUParticles3D = Fx3D.burst(b.burst_kind, Vector3(s.x * 0.4, 0.3, s.y * 0.4))
		fx.position.y = 0.3
		add_child(fx)


func _sync_plants() -> void:
	if not b.is_crop():
		return
	var ripe := 1.0 if b.crop_ready else clampf(b.harvest_progress / maxf(b.harvest_time(), 0.01), 0.0, 1.0)
	if b.state == "ruined":
		ripe = 0.0
	var pk := "%d|%d|%s|%s|%s" % [b.level, int(ripe * 8.0), b.pest, b.drip, b.crop]
	if pk == _plant_key:
		return
	_plant_key = pk
	if plants:
		plants.queue_free()
	plants = BuildingKit.field_plants(b.level, ripe, b.pest, b.crop) if b.type == "field" else BuildingKit.greenhouse_plants(ripe, b.pest, b.crop)
	if b.drip and b.type == "field":
		var pipe := BoxMesh.new()
		pipe.size = Vector3(1.9, 0.025, 0.025)
		for r in 4:
			BuildingKit.prim(plants, pipe, BuildingKit.mat("drip", Color(0.08, 0.08, 0.09)), Vector3(0, BuildingKit.FIELD_SURFACE + 0.02, r * 0.5 - 0.62))
	add_child(plants)
	_overlay_dirty = true  # yeni bitkilere de üst malzeme uygulansın


func _apply_overlay(n: Node, m) -> void:
	if DisplayServer.get_name() == "headless":
		return  # sahte (dummy) çizici üst malzemede hata basıyor; görsel olmayan testler
	for mi: GeometryInstance3D in n.find_children("*", "GeometryInstance3D", true, false):
		if mi == pad or mi is Label3D or mi is CPUParticles3D:
			continue
		mi.material_overlay = m
