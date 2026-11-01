class_name Thumbs
extends RefCounted
## 3D modellerden arayüz küçük resmi: ayrı dünyalı SubViewport bir kez çizer, doku önbelleğe alınır.
## Dükkan kartları (bina modeli) ve rol portreleri (karakter modeli) bunu kullanır.

const PORTRAIT_CHARS := {"hasan": "character-male-b", "cop": "character-female-b", "fire": "character-male-c",
	"teacher": "character-female-d", "farmer": "character-female-f", "press": "character-male-a"}

static var _cache := {}
static var _holder: Node


static var _vps := {}  # anahtar → SubViewport (ağaca giremediyse yeniden eklenir)


## Tutucu düğüm köke eklenir. Sahne kurulurken gelen ilk istekte ertelenmiş ekleme kaybolabiliyor;
## her çağrıda kontrol edilip gerekirse yeniden eklenir.
static func _host() -> Node:
	if _holder == null or not is_instance_valid(_holder):
		_holder = Node.new()
		_holder.name = "Thumbs"
		_holder.process_mode = Node.PROCESS_MODE_ALWAYS
	_attach_later(_holder, (Engine.get_main_loop() as SceneTree).root)
	return _holder


static func _ensure(key: String) -> void:
	var vp: SubViewport = _vps.get(key)
	_host()
	if vp and is_instance_valid(vp):
		_attach_later(vp, _holder)


## Ertelenmiş ekleme; aynı düğüm bekliyorken tekrar kuyruğa alınmaz.
static func _attach_later(n: Node, parent: Node) -> void:
	if n.get_parent() != null or n.has_meta("attaching"):
		return
	n.set_meta("attaching", true)
	(func():
		n.remove_meta("attaching")
		if is_instance_valid(n) and is_instance_valid(parent) and n.get_parent() == null:
			parent.add_child(n)).call_deferred()


## Bina kartı resmi (tür + seviye 1). size: piksel.
static func building(type: String, size := Vector2i(220, 150), level := 1, pitch := 30.0) -> Texture2D:
	var key := "b:%s:%d:%d:%d" % [type, level, size.x, int(pitch)]
	_ensure(key)
	if not _cache.has(key):
		var root := Node3D.new()
		if type.begins_with("road"):
			_road(root, type == "road_upgrade")
		elif type == "clear_land":
			BuildingKit.part(root, "nature/stone_largeA", Vector3(-0.6, 0, 0), 0.0, Vector3.ONE * 1.3)
			BuildingKit.part(root, "nature/stump_round", Vector3(0.5, 0, 0.2), 0.0, Vector3.ONE * 1.6)
			BuildingKit.part(root, "nature/log", Vector3(0.6, 0, -0.35), 40.0, Vector3.ONE * 1.4)
		else:
			root.add_child(BuildingKit.build(type, level))
			if type == "field":
				root.add_child(BuildingKit.field_plants(level, 0.8, false))
			elif type == "greenhouse":
				root.add_child(BuildingKit.greenhouse_plants(0.8, false))
		var s: Vector2i = Bal.BUILDINGS[type].size if Bal.BUILDINGS.has(type) else Vector2i(3, 1)
		var span := maxf(s.x, s.y) + 0.6
		var h: float = BuildingView3D.TOP.get(type, 0.6)
		_cache[key] = _render(root, size, Vector3(0, h * 0.4, 0), (span * 1.3 + h * 0.5) * (1.2 if pitch > 35.0 else 1.0), -32.0, pitch, key)
	return _cache[key]


## Rol portresi: karakterin baş-omuz çekimi.
static func portrait(role: String, _size := Vector2i(160, 160)) -> Texture2D:
	var key := "p:" + role
	if not _cache.has(key):
		var path := "res://assets/portraits/%s.svg" % role
		_cache[key] = load(path if ResourceLoader.exists(path) else "res://assets/portraits/hasan.svg")
	return _cache[key]


static func _road(root: Node3D, upgraded: bool) -> void:
	var col := Color(0.7, 0.66, 0.58) if upgraded else Color(0.74, 0.6, 0.42)
	for i in 3:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.96, 0.06, 0.96)
		BuildingKit.prim(root, bm, BuildingKit.mat("road_%s" % upgraded, col), Vector3(i - 1.0, 0.03, 0))
	BuildingKit.part(root, "car/cone", Vector3(1.0, 0.06, 0.2), 0.0, Vector3.ONE * 0.5)
	if upgraded:
		BuildingKit.part(root, "town/lantern", Vector3(-1.0, 0.06, -0.35), 0.0, Vector3.ONE * 0.5)


static func _render(root: Node3D, size: Vector2i, target: Vector3, dist: float, yaw: float, pitch: float, key := "") -> Texture2D:
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_DISABLED if OS.has_feature("web") else Viewport.MSAA_4X
	# ilk 1.5 sn sürekli çiz (model/animasyon yerleşsin), sonra son kareyi dondur
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.tree_entered.connect(func():
		(Engine.get_main_loop() as SceneTree).create_timer(1.5, true, false, true).timeout.connect(func():
			if is_instance_valid(vp):
				vp.render_target_update_mode = SubViewport.UPDATE_DISABLED), CONNECT_ONE_SHOT)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.82, 0.78)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -40, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var basis := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, -deg_to_rad(pitch))
	cam.transform = Transform3D(basis, target + basis * Vector3(0, 0, dist))
	vp.add_child(cam)
	vp.add_child(root)
	if key != "":
		_vps[key] = vp
	_attach_later(vp, _host())
	return vp.get_texture()
