class_name WorldView3D
extends Node3D
## 3D görüntü katmanı: 2D Village mantığının aynası. Zemin, nehir, bitki örtüsü, ışık/gökyüzü;
## binalar ve köylüler her karede mantıktaki konumlarından eşitlenir. Oyun kuralları burada değil.

const M := 12  # ızgara dışındaki doğa kuşağı (hücre)
const PX := 4  # zemin dokusunda hücre başı piksel
const GROUND_SHADER := preload("res://shaders/ground.gdshader")
const WATER_SHADER := preload("res://shaders/water.gdshader")
const DAYLIGHT := preload("res://scripts/world/daylight.gd")

const PINES := ["nature/tree_pineTallA", "nature/tree_pineTallB", "nature/tree_pineTallC", "nature/tree_pineTallD", "nature/tree_pineRoundA", "nature/tree_pineRoundB", "nature/tree_pineRoundC"]
const OLIVES := ["nature/tree_fat", "nature/tree_plateau"]
const ROCKS := ["nature/stone_largeA", "nature/stone_largeB", "nature/stone_largeC", "nature/stone_tallA", "nature/stone_tallB"]
const PALMS := ["nature/tree_palm", "nature/tree_palmTall", "nature/tree_palmShort", "nature/tree_palmBend"]
const SEA_SHADER := preload("res://shaders/sea.gdshader")
const SHORE := Bal.GRID_H + M + 2.0  # kumsalın denize değdiği z
const DRY_TINT := Color(1.0, 0.76, 0.42)
const DECOR := ["nature/grass", "nature/grass_large", "nature/flower_redA", "nature/flower_yellowA", "nature/plant_bushSmall"]


var village: Village
var truck: Node2D
var env := Environment.new()
var sun := DirectionalLight3D.new()
var sky_mat := ProceduralSkyMaterial.new()
var _heat: CPUParticles3D
var _ground_img: Image
var _ground_tex: ImageTexture
var _ground_mat := ShaderMaterial.new()
var _ground_key := ""
var _water := MeshInstance3D.new()
var _water_mat := ShaderMaterial.new()
var _water_key := -1
var _ghost := MeshInstance3D.new()
var _ghost_mat := StandardMaterial3D.new()
var _ghost_holo := StandardMaterial3D.new()
var _ghost_model: Node3D
var _ghost_type := ""
var _b3 := {}  # Building → BuildingView3D
var _actors := {}
var _veg_nodes: Array = []  # temizlemede yeniden kurulan MultiMeshInstance3D'ler
var _cleared_n := 0
var _tree_mms: Array = []  # sararabilen ağaç MultiMesh'leri
var _dry_key := -1  # 2D düğüm → ActorView3D
var _rng := RandomNumberGenerator.new()


func _exit_tree() -> void:
	Audio.loop("cicada", false)


func _ready() -> void:
	add_to_group("world3d")
	process_mode = Node.PROCESS_MODE_ALWAYS  # yangın sinematiği oyunu duraklatır; araç ve alevler yine görünsün
	_rng.seed = 31
	_build_env()
	_build_ground()
	_build_water()
	_build_bridges()
	_build_mountains()
	_build_coast()
	_build_vegetation()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.material_override = _ghost_mat
	_ghost_holo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_holo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ghost)


# ---------------- Işık / gökyüzü ----------------

func _build_env() -> void:
	sky_mat.sky_top_color = Color(0.32, 0.56, 0.86)
	sky_mat.sky_horizon_color = Color(0.86, 0.84, 0.76)
	sky_mat.ground_horizon_color = Color(0.78, 0.74, 0.62)
	sky_mat.ground_bottom_color = Color(0.4, 0.38, 0.3)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.tonemap_exposure = 0.92
	env.fog_enabled = true
	env.fog_light_color = Color(0.86, 0.8, 0.68)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.25
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_blur = 1.5
	if OS.has_feature("web"):
		# web: tek bölmeli gölge, kısa mesafe (Compatibility/WebGL2'de ucuz)
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = 45.0
		sun.shadow_blur = 0.0
	sun.light_energy = 1.0
	add_child(sun)
	_update_clear_animation()
	_update_sun()
	# kuraklıkta havada uçuşan sıcak toz
	_heat = Fx3D._base(70 if OS.has_feature("web") else 140, 7.0, 0.08, true, Vector3(Bal.GRID_W * 0.5, 1.2, Bal.GRID_H * 0.5))
	_heat.position = Vector3(Bal.GRID_W * 0.5, 1.4, Bal.GRID_H * 0.5)
	_heat.direction = Vector3(1, 0.1, 0.2)
	_heat.spread = 25.0
	_heat.gravity = Vector3.ZERO
	_heat.initial_velocity_min = 0.15
	_heat.initial_velocity_max = 0.4
	_heat.preprocess = 7.0
	_heat.color_ramp = Fx3D._ramp([Color(1, 0.92, 0.7, 0.0), Color(1, 0.92, 0.7, 0.8), Color(1, 0.92, 0.7, 0.0)])
	(_heat.mesh as QuadMesh).material = Fx3D.mat(true).duplicate()
	add_child(_heat)


## Güneş günün saatine göre döner; gece ay ışığı (mavi, zayıf).
func _update_sun() -> void:
	var p := GameState.day_phase()
	var tint: Color = DAYLIGHT.tint(p)
	var day_t := clampf(p / 0.75, 0.0, 1.0)
	var night := p >= 0.75 or GameState.night_factor() > 0.6
	var elev := 12.0 + sin(day_t * PI) * 48.0
	var az := lerpf(-60.0, 200.0, day_t)
	if night:
		elev = 38.0
		az = 120.0
	sun.rotation_degrees = Vector3(-elev, az, 0)
	sun.light_color = tint
	sun.light_energy = (0.42 if night else 1.0) * (1.0 + GameState.drought() * 0.15)
	env.ambient_light_energy = 0.5 if night else 0.6  # gece okunaklı kalsın
	env.ambient_light_color = tint
	var heat := GameState.drought()
	var n := GameState.night_factor()
	var rain := 1.0 if GameState.rain_left > 0.0 else 0.0
	env.fog_light_color = Color(0.86, 0.8, 0.68).lerp(Color(0.88, 0.78, 0.62), heat).lerp(Color(0.55, 0.58, 0.62), rain) * tint
	env.fog_density = 0.005 + heat * 0.0015 + rain * 0.02
	sky_mat.sky_top_color = Color(0.32, 0.56, 0.86).lerp(Color(0.45, 0.5, 0.56), rain).lerp(Color(0.04, 0.06, 0.16), n)
	sky_mat.sky_horizon_color = (Color(0.86, 0.84, 0.76) * tint).lerp(Color(0.6, 0.62, 0.64), rain).lerp(Color(0.12, 0.13, 0.25), n)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	if rain > 0.0:
		sun.light_energy *= 0.22
		env.ambient_light_energy *= 0.75
	if _heat:
		((_heat.mesh as QuadMesh).material as StandardMaterial3D).albedo_color.a = clampf(0.15 + heat, 0.0, 1.0) * (1.0 - rain)


# ---------------- Zemin ----------------

func _build_ground() -> void:
	var size := Vector2i(Bal.GRID_W + M * 2, Bal.GRID_H + M * 2)
	_ground_img = Image.create(size.x * PX, size.y * PX, false, Image.FORMAT_RGBA8)
	_paint_ground()
	_ground_tex = ImageTexture.create_from_image(_ground_img)
	_ground_mat.shader = GROUND_SHADER
	_ground_mat.set_shader_parameter("cells", _ground_tex)
	_ground_mat.set_shader_parameter("origin", Vector2(-M, -M))
	_ground_mat.set_shader_parameter("extent", Vector2(size))
	_ground_mat.set_shader_parameter("grid_size", Vector2(Bal.GRID_W, Bal.GRID_H))
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	pm.subdivide_width = 0
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = _ground_mat
	mi.position = Vector3(Bal.GRID_W * 0.5, 0, Bal.GRID_H * 0.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Nehir yatağının orta çizgisi: mantıktaki satır merkezleri arasında yumuşak geçiş.
static func river_center(z: float) -> float:
	var y0 := floori(z - 0.5)
	var t := (z - 0.5) - y0
	t = t * t * (3.0 - 2.0 * t)
	return lerpf(Terrain.river_x(y0) + 1.0, Terrain.river_x(y0 + 1) + 1.0, t)


## RGB: zemin rengi, A: yol maskesi (desen shader'da yol seviyesine göre).
func _ground_color(c: Vector2i, dr: float) -> Color:
	var inside := c.x >= 0 and c.y >= 0 and c.x < Bal.GRID_W and c.y < Bal.GRID_H
	if not inside:
		return Color(Color(0.42, 0.46, 0.24).lerp(Color(0.5, 0.46, 0.28), dr), 0.0)
	if GameState.is_road_cell(c):
		match GameState.road_level:
			1: return Color(0.74, 0.6, 0.42, 1.0)
			2: return Color(0.7, 0.66, 0.58, 1.0)
			_: return Color(0.27, 0.27, 0.29, 1.0)
	match Terrain.kind(c):
		"rock": return Color(0.66, 0.62, 0.54, 0.0)
		"forest": return Color(0.45, 0.47, 0.26, 0.0)
	return Color(Color(0.5, 0.55, 0.27).lerp(Color(0.6, 0.54, 0.33), dr), 0.0)


func _paint_ground() -> void:
	var dr := GameState.drought()
	var bed := Color(0.62, 0.5, 0.36).lerp(Color(0.74, 0.6, 0.42), dr)
	bed.a = 0.0
	for gx in Bal.GRID_W + M * 2:
		for gy in Bal.GRID_H + M * 2:
			var c := Vector2i(gx - M, gy - M)
			_ground_img.fill_rect(Rect2i(gx * PX, gy * PX, PX, PX), _ground_color(c, dr))
			if absf(c.x + 0.5 - river_center(c.y + 0.5)) < 2.5:
				for px in PX:
					for py in PX:
						var w := Vector2(c.x + (px + 0.5) / PX, c.y + (py + 0.5) / PX)
						var d := absf(w.x - river_center(w.y))
						if d < 1.05:
							_ground_img.set_pixel(gx * PX + px, gy * PX + py, bed)
						elif d < 1.3:
							var base := _ground_img.get_pixel(gx * PX + px, gy * PX + py)
							_ground_img.set_pixel(gx * PX + px, gy * PX + py, base.lerp(Color(0.5, 0.46, 0.3, base.a), 0.5))


# ---------------- Nehir ----------------

func _build_water() -> void:
	_water_mat.shader = WATER_SHADER
	_water.material_override = _water_mat
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water)
	_rebuild_water()


func _rebuild_water() -> void:
	var dr := GameState.drought()
	var hw := 0.92 - dr * 0.42
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z := float(-M)
	var step := 0.25
	while z < SHORE + 0.6:
		var a := river_center(z)
		var b := river_center(z + step)
		var v := [Vector3(a - hw, 0.04, z), Vector3(a + hw, 0.04, z), Vector3(b + hw, 0.04, z + step), Vector3(b - hw, 0.04, z + step)]
		var uv := [Vector2(0, z * 0.5), Vector2(1, z * 0.5), Vector2(1, (z + step) * 0.5), Vector2(0, (z + step) * 0.5)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uv[i])
			st.add_vertex(v[i])
		z += step
	_water.mesh = st.commit()
	_water_mat.set_shader_parameter("murk", dr * 0.35)


func _build_bridges() -> void:
	for row in Bal.ROAD_ROWS:
		var cx := river_center(row + 0.5)
		for i in 3:
			var br := Models.spawn("nature/bridge_wood")
			br.position = Vector3(cx - 1.0 + i, 0.0, row + 0.5)
			br.rotation_degrees.y = 90.0
			br.scale = Vector3(1.0, 0.8, 1.0)
			add_child(br)


# ---------------- Bitki örtüsü ----------------

func _build_vegetation() -> void:
	var inner := {}  # model → [Transform3D] (gölge düşürür)
	var outer := {}  # uzak kuşak (gölgesiz, performans)
	var start_cells := {}
	for e in Bal.START_LAYOUT:
		var s: Vector2i = Bal.BUILDINGS[e[0]].size
		for x in s.x:
			for y in s.y:
				start_cells[e[1] + Vector2i(x, y)] = true
	for gx in range(-M + 1, Bal.GRID_W + M - 1):
		for gy in range(-M + 1, Bal.GRID_H + M - 1):
			var c := Vector2i(gx, gy)
			var inside := gx >= 0 and gy >= 0 and gx < Bal.GRID_W and gy < Bal.GRID_H
			var near_river := absf(gx + 0.5 - river_center(gy + 0.5)) < 1.6
			if near_river:
				continue
			if not inside:
				if gy in Bal.ROAD_ROWS or gx in Bal.ROAD_COLS:
					continue
				if OS.has_feature("web") and _h(gx, gy, 9) < 0.45:
					continue  # web: uzak orman daha seyrek
				var edge := mini(mini(gx + 1, Bal.GRID_W - gx), mini(gy + 1, Bal.GRID_H - gy))  # negatif: dışarıda
				var depth := -edge
				if _h(gx, gy, 1) > clampf(0.25 + depth * 0.12, 0.25, 0.9):
					continue
				# Antalya: yamaçta kızılçam, ovada (güney) zeytinlik, kıyıda palmiye
				var olive_chance := 0.65 if gy > Bal.GRID_H * 0.55 else 0.12
				var pool: Array = OLIVES if _h(gx, gy, 2) < olive_chance else PINES
				if gy > Bal.GRID_H + M - 4:
					pool = PALMS
				var bag: Dictionary = inner if depth <= 2 else outer
				_add(bag, pool[int(_h(gx, gy, 3) * pool.size())], c, 1.2 + _h(gx, gy, 4) * 0.7)
				if _h(gx, gy, 5) < 0.12:
					_add(bag, ROCKS[int(_h(gx, gy, 6) * 3)], c, 1.5 + _h(gx, gy, 7))
				continue
			match Terrain.kind(c):
				"forest":
					for k in 2:
						_add(inner, PINES[int(_h(gx, gy, 10 + k) * PINES.size())], c, 1.15 + _h(gx, gy, 20 + k) * 0.6, k)
				"rock":
					_add(inner, ROCKS[int(_h(gx, gy, 12) * ROCKS.size())], c, 1.3 + _h(gx, gy, 13) * 0.8)
				"":
					if not GameState.is_road_cell(c) and not start_cells.has(c) and _h(gx, gy, 14) < 0.1:
						_add(inner, DECOR[int(_h(gx, gy, 15) * DECOR.size())], c, 1.2 + _h(gx, gy, 16) * 0.6)
	_veg_nodes.append_array(_commit(inner, true))
	_veg_nodes.append_array(_commit(outer, false))


func _add(bag: Dictionary, model: String, c: Vector2i, sc: float, k := 0) -> void:
	var off := Vector2(_h(c.x, c.y, 40 + k), _h(c.x, c.y, 50 + k)) * 0.6 + Vector2(0.2, 0.2)
	var b := Basis(Vector3.UP, _h(c.x, c.y, 60 + k) * TAU).scaled(Vector3.ONE * sc)
	if not bag.has(model):
		bag[model] = []
	bag[model].append(Transform3D(b, Vector3(c.x + off.x, 0, c.y + off.y)))


## Arazi temizlenince bitki örtüsü yeniden kurulur (kesilen ağaç/kaya kaybolur).
func _rebuild_vegetation() -> void:
	for n in _veg_nodes:
		_tree_mms.erase(n.multimesh)
		n.queue_free()
	_veg_nodes.clear()
	_build_vegetation()
	_dry_key = -1


func _commit(bag: Dictionary, shadows: bool) -> Array:
	var made: Array = []
	for model in bag:
		var mesh := Models.mesh(model)
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var tree: bool = model.begins_with("nature/tree")
		mm.use_colors = tree
		mm.mesh = mesh
		mm.instance_count = bag[model].size()
		for i in mm.instance_count:
			mm.set_instance_transform(i, bag[model][i])
			if tree:
				mm.set_instance_color(i, Color.WHITE)
		if tree:
			_tree_mms.append(mm)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.set_meta("rest_transforms", bag[model])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		made.append(mmi)
	return made


## Kuraklık arttıkça ağaçların bir kısmı sararır (aynı ağaçlar, kuraklıkla çoğalarak).
func _update_dry(dr: float) -> void:
	var key := int(dr * 10.0)
	if key == _dry_key:
		return
	_dry_key = key
	var share := maxf(0.0, dr - 0.15) * 0.65
	for mm: MultiMesh in _tree_mms:
		for i in mm.instance_count:
			var dry := _h(i, mm.instance_count, 77) < share
			mm.set_instance_color(i, DRY_TINT if dry else Color.WHITE)


# ---------------- Toroslar ve Akdeniz ----------------

## Vadiyi kuzey, doğu ve batıdan saran low-poly dağlar (nehir için geçit), güneyde deniz.
func _build_mountains() -> void:
	var lo := Vector2(-M, -M)
	var hi := Vector2(Bal.GRID_W + M, Bal.GRID_H + M)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 2.5
	var x0 := -70.0
	var z0 := -75.0
	var nx := int(220.0 / step)
	var nz := int(115.0 / step)
	var hmap := []
	for i in nx + 1:
		var col := []
		for j in nz + 1:
			col.append(_mountain_h(x0 + i * step, z0 + j * step, lo, hi))
		hmap.append(col)
	for i in nx:
		for j in nz:
			var p := [Vector2(i, j), Vector2(i + 1, j), Vector2(i + 1, j + 1), Vector2(i, j + 1)]
			var hs := [hmap[i][j], hmap[i + 1][j], hmap[i + 1][j + 1], hmap[i][j + 1]]
			if hs.max() < 0.15:
				continue
			var v: Array = []
			for k in 4:
				v.append(Vector3(x0 + p[k].x * step, hs[k] - 0.1, z0 + p[k].y * step))
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Vector3 = v[tri[0]]
				var b: Vector3 = v[tri[1]]
				var c: Vector3 = v[tri[2]]
				var n := (c - a).cross(b - a).normalized()
				var col := _rock_color((a.y + b.y + c.y) / 3.0, n.y, a.x + a.z)
				for q in [a, b, c]:
					st.set_color(col)
					st.set_normal(n)
					st.add_vertex(q)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _mountain_h(x: float, z: float, lo: Vector2, hi: Vector2) -> float:
	var dx := maxf(lo.x - x, x - hi.x)
	var dz := lo.y - z
	var d := maxf(maxf(dx, dz), 0.0)
	if z > hi.y - 4.0:
		d *= clampf((SHORE + 6.0 - z) / 10.0, 0.0, 1.0)  # kıyıya doğru alçalır
	var n := sin(x * 0.21 + z * 0.13) * 0.5 + sin(x * 0.07 - 1.3) * 0.8 + sin(x * 0.43 + z * 0.37) * 0.25 + sin(z * 0.09 + 2.0) * 0.5
	var h := smoothstep(0.0, 9.0, d) * (13.0 + 8.0 * n) + smoothstep(9.0, 40.0, d) * 16.0
	var gorge := absf(x - river_center(clampf(z, -M, Bal.GRID_H + M)))
	h *= smoothstep(1.5, 9.0, gorge) if z < lo.y + 2.0 else 1.0
	return maxf(h, 0.0)


## Yükseklik + eğim: eteklerde kızılçam yeşili, ortada çıplak toprak, tepede kireçtaşı.
func _rock_color(y: float, up: float, seed: float) -> Color:
	var v := 0.92 + 0.08 * sin(seed * 1.7)
	var pine := Color(0.27, 0.38, 0.19)
	var earth := Color(0.55, 0.47, 0.36)
	var lime := Color(0.8, 0.77, 0.7)
	var c := pine.lerp(earth, smoothstep(6.0, 13.0, y + (1.0 - up) * 6.0))
	c = c.lerp(lime, smoothstep(15.0, 24.0, y))
	return c * v


func _build_coast() -> void:
	var sand := MeshInstance3D.new()
	var sp := PlaneMesh.new()
	sp.size = Vector2(400, 6.5)
	sand.mesh = sp
	sand.material_override = BuildingKit.mat("sand", Color(0.86, 0.78, 0.6))
	sand.position = Vector3(Bal.GRID_W * 0.5, 0.02, SHORE - 2.6)
	sand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sand)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 160)
	pm.subdivide_depth = 0
	sea.mesh = pm
	var sm := ShaderMaterial.new()
	sm.shader = SEA_SHADER
	sm.set_shader_parameter("shore_z", SHORE)
	sea.material_override = sm
	sea.position = Vector3(Bal.GRID_W * 0.5, 0.05, SHORE + 80.0)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
	var palms := {}
	for i in 60:
		var x := -M - 20.0 + i * 1.6 + _h(i, 3, 5) * 1.2
		if absf(x - river_center(SHORE)) < 2.0:
			continue
		var mdl: String = PALMS[int(_h(i, 4, 6) * PALMS.size())]
		if not palms.has(mdl):
			palms[mdl] = []
		var b := Basis(Vector3.UP, _h(i, 5, 7) * TAU).scaled(Vector3.ONE * (1.3 + _h(i, 6, 8) * 0.6))
		palms[mdl].append(Transform3D(b, Vector3(x, 0.02, SHORE - 3.8 + _h(i, 7, 9) * 2.0)))
	_commit(palms, false)


func _h(x: int, y: int, k := 0) -> float:
	var n := (x * 374761393 + y * 668265263 + k * 2147483) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float(n % 10000) / 10000.0


# ---------------- Eşitleme ----------------

func _process(delta: float) -> void:
	_update_clear_animation()
	_update_sun()
	var dr := GameState.drought()
	var key := "%d|%d|%d|%d|%d" % [GameState.road_level, village.cop_level(), int(dr * 10.0), GameState.extra_roads.hash()+GameState.removed_roads.hash(), GameState.cleared.size()]
	if GameState.cleared.size() != _cleared_n:
		_cleared_n = GameState.cleared.size()
		_rebuild_vegetation()
	if key != _ground_key:
		_ground_key = key
		_paint_ground()
		_ground_tex.update(_ground_img)
	var wk := int(dr * 20.0)
	if wk != _water_key:
		_water_key = wk
		_rebuild_water()
	var open := village.unlocked_world_rect()
	_ground_mat.set_shader_parameter("open_rect", Color(open.position.x / Bal.CELL, open.position.y / Bal.CELL, open.size.x / Bal.CELL, open.size.y / Bal.CELL))
	_ground_mat.set_shader_parameter("grid_alpha", 0.35 if village.mode != "none" else 0.0)
	_ground_mat.set_shader_parameter("drought", dr)
	_ground_mat.set_shader_parameter("road_level", GameState.road_level)
	_ground_mat.set_shader_parameter("dim", 0.55 if View.risk_map or View.moist_map else 0.0)
	_sync_buildings()
	_sync_actors(delta)
	_update_dry(dr)
	# ağustos böceği: gündüz, sıcak arttıkça yüksek; gece ve yağmurda susar
	var sing := GameState.night_factor() < 0.3 and GameState.rain_left <= 0.0 and not get_tree().paused
	Audio.loop("cicada", sing, -22.0 + dr * 8.0)
	if sing:
		Audio.loop_volume("cicada", -22.0 + dr * 8.0)
	_sync_ghost()


func _sync_buildings() -> void:
	for b in _b3.keys():
		if not is_instance_valid(b) or not GameState.buildings.has(b):
			_b3[b].queue_free()
			_b3.erase(b)
	for b in GameState.buildings:
		if not is_instance_valid(b):
			continue
		if not _b3.has(b):
			var v := BuildingView3D.new(b)
			add_child(v)
			_b3[b] = v
		_b3[b].sync()


## Köylüler, süs hayvanları ve itfaiye aracı: mantık düğümü başına bir ActorView3D.
func _sync_actors(delta: float) -> void:
	for src in _actors.keys():
		if not is_instance_valid(src):
			_actors[src].queue_free()
			_actors.erase(src)
	var list: Array = []
	for w in GameState.workers:
		if is_instance_valid(w):
			list.append([w, "worker"])
	for c in village.workers_layer.get_children():
		if c is Critter:
			list.append([c, "critter"])
	if truck and is_instance_valid(truck):
		list.append([truck, "truck"])
	for e in list:
		if not _actors.has(e[0]):
			var v := ActorView3D.new(e[0], e[1])
			add_child(v)
			_actors[e[0]] = v
		_actors[e[0]].sync(delta)


func _sync_ghost() -> void:
	var m := village.mode
	var show := m != "none"
	_ghost.visible = show
	if _ghost_model:
		_ghost_model.visible = show and m in ["build", "move"]
	if not show:
		return
	var bm := _ghost.mesh as BoxMesh
	if bm == null:
		bm = BoxMesh.new()
		_ghost.mesh = bm
	var ok: bool
	var warn := false  # konabilir ama yola bitişik değil → çalışmaz
	var s := Vector2i.ONE
	if m == "road" and village.road_erase:
		ok = village.is_road(village.ghost_cell) and not village.is_locked(village.ghost_cell)
		warn = not ok
	elif m == "road":
		ok = village.can_paint(village.ghost_cell) and GameState.can_afford(Bal.ROAD_TILE_COST)
	elif m == "clear":
		var k := Terrain.kind(village.ghost_cell)
		ok = village.clear_preview_ok(village.ghost_cell)
	else:
		s = Building.footprint(village.ghost_type, village.ghost_rot)
		ok = village.can_place(village.ghost_type, village.ghost_cell, village.moving_building)
		warn = ok and not village.ghost_type in Bal.NO_ROAD_NEEDED and not village.road_adjacent(village.ghost_type, village.ghost_cell)
		if village.ghost_type != _ghost_type:
			_ghost_type = village.ghost_type
			if _ghost_model:
				_ghost_model.queue_free()
			_ghost_model = BuildingKit.build(_ghost_type, 1)
			if _ghost_type == "field":
				_ghost_model.add_child(BuildingKit.field_plants(1, 0.7, false))
			elif _ghost_type == "greenhouse":
				_ghost_model.add_child(BuildingKit.greenhouse_plants(0.7, false))
			for gi: GeometryInstance3D in _ghost_model.find_children("*", "GeometryInstance3D", true, false):
				gi.material_override = _ghost_holo
				gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(_ghost_model)
	bm.size = Vector3(s.x * 0.98, 0.04 if m != "clear" else 1.2, s.y * 0.98)
	var center := Vector3(village.ghost_cell.x + s.x * 0.5, 0.0, village.ghost_cell.y + s.y * 0.5)
	_ghost.position = center + Vector3(0, bm.size.y * 0.5 + 0.02, 0)
	var col := Color(0.3, 1.0, 0.4) if ok and not warn else (Color(1.0, 0.7, 0.15) if warn else Color(1.0, 0.25, 0.2))
	_ghost_mat.albedo_color = Color(col, 0.35 if m == "clear" else 0.5)
	if _ghost_model and m in ["build", "move"]:
		_ghost_model.position = center
		_ghost_model.basis = Basis(Vector3.UP,-village._fit_rot(village.ghost_type, village.ghost_rot)*PI*0.5)
		_ghost_holo.albedo_color = Color(col.lerp(Color.WHITE, 0.2), 0.68)


# ---------------- Uçan yazılar ----------------

func float_text(world_pos: Vector2, text: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 56
	l.outline_size = 14
	l.pixel_size = 0.006
	l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.position = View.to3(world_pos, 1.2)
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.8, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2)
	tw.tween_callback(l.queue_free)


func _update_clear_animation() -> void:
	if GameState.clearing.is_empty(): return
	for node in _veg_nodes:
		var poses: Array = node.get_meta("rest_transforms", [])
		for i in poses.size():
			var base: Transform3D = poses[i]
			var c := Vector2i(floori(base.origin.x), floori(base.origin.z))
			if not GameState.clearing.has(c): continue
			var progress := clampf((float(GameState.clearing[c]) - Bal.CLEAR_TIME + 1.2) / 1.2, 0.0, 1.0)
			if progress <= 0.0: continue
			var pose := base
			if Terrain.kind(c) == "forest":
				pose.basis = Basis(Vector3.RIGHT, progress * progress * PI * 0.48) * base.basis
			else:
				pose.basis = base.basis.scaled(Vector3.ONE * (1.0 - progress * 0.85))
				pose.origin.y += sin(progress * 40.0) * 0.03
			node.multimesh.set_instance_transform(i, pose)
