class_name ActorView3D
extends Node3D
## Hareket eden bir 2D mantık düğümünün (köylü, hayvan, itfaiye aracı) 3D görüntüsü:
## konumu izler, gidiş yönüne döner, duruma göre animasyon oynatır.

const CHARACTERS := ["character-male-a", "character-female-a", "character-male-b", "character-female-b", "character-male-c",
	"character-female-c", "character-male-d", "character-female-d", "character-male-e", "character-female-e", "character-male-f", "character-female-f"]
const PETS := {122: ["pets/animal-chick", 0.17], 120: ["pets/animal-cow", 0.36], 121: ["pets/animal-dog", 0.24]}

var src: Node2D
var kind := ""  # worker | critter | truck
var body: Node3D
var anim: AnimationPlayer
var alert: Label3D
var siren: OmniLight3D
var bucket: Node3D
var tool: Node3D  # çapa / balta (elde)
var _tool_kind := ""
var _last := Vector3.ZERO
var _speed := 0.0
var _t := 0.0
var _stride := 0.0
var _animal_rig: Skeleton3D
var _animal_phase := 0.0
var _animal_rest := {}
var _animal_positions := {}


func _init(source: Node2D, k: String) -> void:
	src = source
	kind = k


func _ready() -> void:
	match kind:
		"worker":
			body = preload("res://tt_models/scripts/worker_model.gd").create(self, src.visual_variant)
			body.position = Vector3.ZERO
			body.scale = Vector3.ONE * 0.46
			alert = Label3D.new()
			alert.text = "!"
			alert.font_size = 72
			alert.outline_size = 16
			alert.pixel_size = 0.005
			alert.modulate = Color(1, 0.2, 0.15)
			alert.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			alert.no_depth_test = true
			alert.position.y = 0.75
			alert.visible = false
			add_child(alert)
		"critter":
			var spec: Array = PETS.get(src.kind, PETS[122])
			body = Models.spawn(spec[0])
			body.scale = Vector3.ONE * spec[1]
		"truck":
			body = Models.spawn("car/firetruck")
			body.scale = Vector3.ONE * 0.52
			siren = OmniLight3D.new()
			siren.omni_range = 3.0
			siren.light_energy = 0.0
			siren.position = Vector3(0, 0.8, 0)
			add_child(siren)
	if body.get_parent() == null:
		add_child(body)
	var aps := body.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		anim = aps[0]
	if kind == "critter":
		var rigs := body.find_children("*", "Skeleton3D", true, false)
		if not rigs.is_empty():
			_animal_rig = rigs[0]
			if anim and anim.has_animation("idle"):
				anim.play("idle")
				anim.seek(0.0, true)
				anim.advance(0.0)
				anim.pause()
			for bone in _animal_rig.get_bone_count():
				_animal_rest[bone] = _animal_rig.get_bone_pose_rotation(bone)
				_animal_positions[bone] = _animal_rig.get_bone_pose_position(bone)
	if kind == "critter" and anim:
		# Advance the imported skinned animation explicitly from traveled distance.
		# Paused AnimationPlayers can otherwise reapply their cached idle pose after our update.
		anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var library: AnimationLibrary = anim.get_animation_library("").duplicate()
		anim.remove_animation_library("")
		anim.add_animation_library("", library)
		for clip in ["walk", "idle", "eat"]:
			if not anim.has_animation(clip):
				continue
			var source := anim.get_animation(clip)
			var copy: Animation = source.duplicate()
			copy.loop_mode = Animation.LOOP_LINEAR
			for track in range(copy.get_track_count()-1,-1,-1):
				var path := copy.track_get_path(track)
				var bone := String(path.get_subname(0)) if path.get_subname_count() > 0 else ""
				if copy.track_get_type(track) == Animation.TYPE_POSITION_3D and bone in ["root", "body"]:
					copy.remove_track(track)
			library.remove_animation(clip)
			library.add_animation(clip,copy)
	position = View.to3(src.position)
	_last = position


## Sıradaki ilk var olan animasyonu oynatır (Blender'dan gelen yeni adlar önce, Kenney yedekleri sonra).
func _play_any(names: Array, speed := 1.0) -> void:
	if anim == null:
		return
	for n: String in names:
		if anim.has_animation(n):
			_play(n, speed)
			return


func _play(name: String, speed := 1.0) -> void:
	if anim == null or not anim.has_animation(name):
		return
	var a := anim.get_animation(name)
	if a.loop_mode == Animation.LOOP_NONE:
		a.loop_mode = Animation.LOOP_LINEAR
	if anim.current_animation != name:
		anim.play(name, 0.15)
	anim.speed_scale = speed


func sync(delta: float) -> void:
	_t += delta
	var p := View.to3(src.position)
	if kind == "worker" and is_instance_valid(src.job) and src.job.is_crop():
		if Rect2(Vector2(src.job.cell)*Bal.CELL,Vector2(src.job.size)*Bal.CELL).has_point(src.position):
			p.y = BuildingKit.FIELD_SURFACE if src.job.type == "field" else 0.02
	var d := p - _last
	d.y = 0.0
	var moving := d.length() > 0.0005
	_speed = lerpf(_speed, d.length() / maxf(delta, 0.0001), 0.2)
	if moving:
		rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), clampf(delta * 12.0, 0.0, 1.0))
	position = p
	_last = p
	match kind:
		"worker":
			visible = src.visible and src.state != Worker.State.SHELTER
			var shelter: bool = src._goal == Worker.State.SHELTER
			alert.visible = shelter and src.state == Worker.State.WALKING
			var activity := ""
			if src.state == Worker.State.WORKING:
				if src.carry_stage == 1:
					activity = "water"
				elif src.job and src.job.is_crop() and src.job.is_operational():
					activity = "water" if src.farm_activity == "fetch" else src.farm_activity
			if src.get_meta("traffic_yield",false): activity = ""
			var clearing: bool = src.state == Worker.State.WORKING and src.task_cell != Worker.NO_TASK
			_set_tool("")
			if clearing: activity = "pickaxe" if Terrain.kind(src.task_cell) == "rock" else "axe"
			_stride += d.length() * 16.0
			if moving:
				body.rotation.y = lerp_angle(body.rotation.y, 0.0, clampf(delta * 12.0, 0.0, 1.0))
			var work := {"state": "sheltering" if shelter else "working", "draw_progress": src._carry_t / maxf(Bal.CARRY_FILL_TIME, 0.01) * 3.0}
			work["equipment"] = src.farm_activity if src.farm_activity in ["basket","water_crop"] else activity
			var facing := Vector3.ZERO
			if clearing:
				facing = to_local(View.to3(src.farm_target))
				facing.y = 0.0
			if not moving and activity == "water" and is_instance_valid(src._carry_well):
				facing = to_local(View.to3(src._carry_well.center()))
				facing.y = 0.0
			if activity in ["farm", "harvest", "water_crop"]:
				var target := View.to3(src.farm_target, BuildingKit.FIELD_SURFACE if src.job.type == "field" else 0.02)
				facing = to_local(target)
				facing.y = 0.0
				if position.distance_to(target) < 0.58:
					body.set_meta("farm_contact_world", target)
				else:
					activity = ""
			preload("res://tt_models/scripts/worker_pose.gd").apply(body, work, 1.0 if moving else 0.0, _stride, _t, delta, activity, facing, src.carry_stage == 2 or src.farm_activity == "water_crop", get_tree().paused)
			body.get_node("Job").visible = false
		"critter":
			_animate_animal(d.length(), delta)
		"truck":
			visible = src.visible
			if not moving and not src.siren:
				rotation.y = float(src.get_meta("heading", rotation.y))
			siren.light_energy = 2.5 if src.siren else 0.0
			if src.siren:
				siren.light_color = Color(0.3, 0.5, 1.0) if int(_t * 8.0) % 2 == 0 else Color(1.0, 0.2, 0.2)
				position.y = absf(sin(_t * 30.0)) * 0.01


## Eldeki alet: çapa (tarla/sera), balta (arazi temizliği). Basit modeller; Blender'dan gelince değişir.
func _set_tool(kind: String) -> void:
	if kind == _tool_kind:
		return
	_tool_kind = kind
	if tool:
		tool.queue_free()
		tool = null
	if kind == "":
		return
	tool = Node3D.new()
	tool.position = Vector3(0.14, 0.22, 0.08)
	tool.rotation_degrees = Vector3(-35, 0, -15)
	add_child(tool)
	if Models.scene("props/" + kind):
		tool.add_child(Models.spawn("props/" + kind))  # Blender modeli (sap ucu orijinde, +Y yönünde)
		return
	BuildingKit.prim(tool, BuildingKit.cyl(0.012, 0.42), BuildingKit.mat("tool_handle", Color(0.55, 0.38, 0.22)), Vector3(0, 0.12, 0))
	var head := BoxMesh.new()
	head.size = Vector3(0.27, 0.035, 0.035) if kind == "pickaxe" else Vector3(0.12, 0.09, 0.025)
	BuildingKit.prim(tool, head, BuildingKit.mat("tool_head", Color(0.7, 0.72, 0.75)), Vector3(0.04, 0.32, 0))


## Drive the actual skinned legs by traveled distance, so feet stop when the animal does.
func _animate_animal(distance: float, delta: float) -> void:
	if (get_tree().paused and distance <= 0.00001) or anim == null:
		return
	var walking := distance > 0.00001
	var stride_length := 0.18 if src.kind == 122 else (0.36 if src.kind == 120 else 0.28)
	_animal_phase += distance / stride_length * TAU
	var clip := "walk" if walking else ("idle" if src.kind == 121 else "eat")
	_play(clip)
	var duration := anim.get_animation(clip).length if anim.has_animation(clip) else 1.0
	anim.advance(distance / stride_length * duration if walking else delta)
	if _animal_rig:
		if walking:
			for bone in _animal_rig.get_bone_count():
				if not _animal_rig.get_bone_name(bone).begins_with("leg-"): continue
				var rest: Quaternion = _animal_rest[bone]
				var rotation_delta := rest.inverse()*_animal_rig.get_bone_pose_rotation(bone)
				if rotation_delta.get_angle() > 0.001:
					_animal_rig.set_bone_pose_rotation(bone,rest*Quaternion(rotation_delta.get_axis().normalized(),rotation_delta.get_angle()*1.65))
		_animal_rig.force_update_all_bone_transforms()
	body.position.y = 0.0
