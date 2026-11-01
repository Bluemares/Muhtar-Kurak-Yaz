class_name BuildingKit
extends RefCounted
## Antalya köyü binaları: Kenney parçalarından kodla kurulur (1 hücre = 1 birim, kök = taban merkezi, ön yüz +z).
## Blender: `assets/models/buildings/<tür>_l<seviye>.glb` ya da `<tür>.glb` varsa kit yerine o yüklenir.

const VILLAGE_ART = preload("res://scripts/world3d/village_art.gd")
const TT = preload("res://tt_models/scripts/game_models.gd")
const TT_TYPES := {"house": "house", "well": "well", "cop31": "cop", "fire_station": "station"}

const FIELD_SURFACE := 0.09

const CUSTOM := "res://assets/models/buildings/"

static var _mats := {}


## Binanın görünür modeli. Tarla/sera bitkileri ayrı (plants) kurulur.
static func build(type: String, level: int, variant := 0) -> Node3D:
	if type == "fire_station":
		return VILLAGE_ART.station()
	if type == "granary":
		return VILLAGE_ART.granary()
	var root := Node3D.new()
	if TT_TYPES.has(type):
		var visual := TT.model(TT_TYPES[type], level)
		# Keep the replacement inside the simulation's existing building footprint.
		var bounds := _bounds(visual)
		var size: Vector2i = Bal.BUILDINGS[type].size
		var fit := minf(size.x / maxf(bounds.size.x, 0.01), size.y / maxf(bounds.size.z, 0.01)) * 0.94
		if type == "house":
			fit *= 1.22
		visual.scale = Vector3.ONE * fit
		root.add_child(visual)
		if type == "well":
			var motion = preload("res://tt_models/scripts/well_motion.gd").new()
			motion.name = "WellMotion"
			visual.add_child(motion)
		if type == "cop31":
			VILLAGE_ART.signboard(visual, "COP31", Vector3(0, 1.27, 1.65), Vector2(1.25, 0.34), Color("244c43"))
		return root
	var custom := _custom(type, level)
	if custom:
		root.add_child(custom)
		return root
	match type:
		"house": _house(root, variant)
		"cop31": _cop31(root, level)
		"fire_station": _fire_station(root)
		"well": _well(root, level)
		"field": _field(root)
		"greenhouse": _greenhouse(root)
		"water_tower": _water_tower(root)
		"grove": _grove(root, variant)
		"lamp": _lamp(root)
		"granary": _granary(root)
	return root


static func _bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var xf := mi.transform
		var parent := mi.get_parent()
		while parent != root:
			xf = parent.transform * xf
			parent = parent.get_parent()
		var box: AABB = xf * mi.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds


static func _custom(type: String, level: int) -> Node3D:
	for n: String in ["%s_l%d" % [type, level], type]:
		if ResourceLoader.exists(Models.path("buildings/" + n)):
			return Models.spawn("buildings/" + n)
	return null


# ---------------- yardımcılar ----------------

static func part(root: Node3D, name: String, pos: Vector3, rot := 0.0, sc := Vector3.ONE) -> Node3D:
	var n := Models.spawn(name)
	n.position = pos
	n.rotation_degrees.y = rot
	n.scale = sc
	root.add_child(n)
	return n


static func mat(key: String, col: Color, alpha := false) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = 0.85
		if alpha:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.25
		_mats[key] = m
	return _mats[key]


static func prim(root: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	root.add_child(mi)
	return mi


static func cyl(r: float, h: float, top := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r
	c.top_radius = r if top < 0.0 else top
	c.height = h
	c.radial_segments = 16
	c.rings = 1
	return c


## w×d hücrelik duvar bloğu (y: kat tabanı). Kenarlara parça listeleri sırayla dizilir.
static func walls(root: Node3D, w: int, d: int, y: float, front: Array, sides: Array, back: Array) -> void:
	for i in w:
		var x := i - (w - 1) * 0.5
		part(root, "town/" + front[i % front.size()], Vector3(x, y, (d - 1) * 0.5), -90.0)
		part(root, "town/" + back[i % back.size()], Vector3(x, y, -(d - 1) * 0.5), 90.0)
	for j in d:
		var z := j - (d - 1) * 0.5
		part(root, "town/" + sides[j % sides.size()], Vector3((w - 1) * 0.5, y, z), 0.0)
		part(root, "town/" + sides[(j + 1) % sides.size()], Vector3(-(w - 1) * 0.5, y, z), 180.0)


static func label(root: Node3D, text: String, pos: Vector3, col: Color, outline: Color, size := 40) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 10
	l.pixel_size = 0.005
	l.modulate = col
	l.outline_modulate = outline
	l.position = pos
	l.double_sided = false
	root.add_child(l)
	return l


## Bir modelin tüm yüzeylerini renk çarpanıyla boyar (badana yerine kırmızı sıva gibi).
static func tint(n: Node, col: Color) -> void:
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D:
				var t: StandardMaterial3D = m.duplicate()
				t.albedo_color = col
				mi.set_surface_override_material(i, t)


# ---------------- binalar ----------------

static func _house(root: Node3D, variant: int) -> void:
	var body := Node3D.new()
	body.scale = Vector3.ONE * 0.86
	root.add_child(body)
	walls(body, 1, 1, 0.0, ["wall-door"], ["wall-window-shutters", "wall-window-small"], ["wall"])
	part(body, "town/roof-point", Vector3(0, 1.0, 0), 0.0, Vector3(1.0, 0.9, 1.0))
	if variant % 2 == 1:
		part(body, "town/chimney", Vector3(0.22, 0.95, -0.2), 0.0, Vector3.ONE * 0.45)
	part(root, "nature/pot_large", Vector3(0.38, 0, 0.47), 0.0, Vector3.ONE * 0.45)


static func _cop31(root: Node3D, level: int) -> void:
	var floors := 2 if level >= 2 else 1
	walls(root, 2, 2, 0.0, ["wall-window-round", "wall-doorway-round"], ["wall-window-stone"], ["wall", "wall-window-stone"])
	if floors == 2:
		walls(root, 2, 2, 1.0, ["wall-window-glass"], ["wall-window-glass", "wall"], ["wall"])
	part(root, "town/roof-point", Vector3(0, floors, 0), 0.0, Vector3(2.0, 1.1, 2.0))
	for x in [-0.98, 0.98]:
		part(root, "town/pillar-stone", Vector3(x, 0, 0.98), 0.0, Vector3(1, float(floors), 1))
	label(root, "COP31", Vector3(0, floors - 0.12, 1.06), Color(0.2, 0.45, 0.85), Color(1, 1, 1), 46)
	if level >= 3:
		for x in [-0.55, 0.55]:
			part(root, "town/banner-green", Vector3(x, 1.0, 1.02), -90.0, Vector3.ONE * 0.8)
	if level >= 2:
		var pole := prim(root, cyl(0.025, 1.2), mat("pole", Color(0.85, 0.85, 0.88)), Vector3(0.7, floors + 0.9, -0.5))
		prim(pole, QuadMesh.new(), mat("flag_tr", Color(0.85, 0.1, 0.12)), Vector3(0.22, 0.42, 0), Vector3(0, 0, 0)).scale = Vector3(0.42, 0.28, 1)


static func _fire_station(root: Node3D) -> void:
	var body := Node3D.new()
	root.add_child(body)
	walls(body, 2, 1, 0.0, ["wall-doorway-square-wide"], ["wall-window-small"], ["wall"])
	part(body, "town/roof-flat", Vector3(0, 1.0, 0), 0.0, Vector3(2.0, 1.0, 1.0))
	tint(body, Color(1.0, 0.42, 0.36))
	label(root, "İTFAİYE  112", Vector3(0, 0.86, 0.56), Color(1, 1, 1), Color(0.6, 0.05, 0.05), 34)
	prim(root, cyl(0.03, 0.9), mat("siren_pole", Color(0.8, 0.8, 0.82)), Vector3(0.85, 1.4, -0.3))
	prim(root, SphereMesh.new(), mat("siren", Color(1, 0.15, 0.1)), Vector3(0.85, 1.88, -0.3)).scale = Vector3.ONE * 0.12


static func _well(root: Node3D, level: int) -> void:
	part(root, "town/fountain-round", Vector3.ZERO, 0.0, Vector3(0.36, 0.9, 0.36))
	part(root, "town/poles", Vector3(0, 0, 0), 0.0, Vector3(0.62, 0.8, 0.62))
	part(root, "town/roof-point", Vector3(0, 0.78, 0), 0.0, Vector3(0.62, 0.55, 0.62))
	prim(root, cyl(0.035, 0.6), mat("rope", Color(0.45, 0.3, 0.18)), Vector3(0, 0.62, 0), Vector3(0, 0, 90))
	if level >= 2:
		part(root, "town/lantern", Vector3(0.38, 0, 0.36), 0.0, Vector3.ONE * 0.45)
	if level >= 3:
		prim(root, cyl(0.12, 0.14), mat("bucket", Color(0.55, 0.55, 0.6)), Vector3(-0.32, 0.07, 0.32))


static func _field(root: Node3D) -> void:
	var soil := BoxMesh.new()
	soil.size = Vector3(1.98, 0.06, 1.98)
	prim(root, soil, mat("raised_field_soil", Color("876746")), Vector3(0, 0.035, 0))
	for r in 4:
		for c in 2:
			var row := part(root, "nature/crops_dirtRow", Vector3(c - 0.5, 0.0, r * 0.5 - 0.75), 0.0, Vector3(0.98, 1.0, 0.75))
			var bounds := _bounds(row)
			row.position.y = FIELD_SURFACE - bounds.end.y


## Tarla bitkileri: oyuncunun seçtiği ürün (Bal.CROPS), olgunluk evresi; seviye bitkiyi gürleştirir.
## pest: böcekli tarla sararır, kahverengileşir.
const CROP_STAGES := {
	"veg": ["crops_leafsStageA", "crops_leafsStageB", "crop_carrot", "crop_turnip"],
	"melon": ["crops_leafsStageA", "crops_leafsStageB", "crop_melon"],
	"corn": ["crops_cornStageA", "crops_cornStageB", "crops_cornStageC", "crops_cornStageD"],
	"wheat": ["crops_wheatStageA", "crops_wheatStageB"],
}


static func field_plants(level: int, ripe: float, pest: bool, crop := "veg") -> Node3D:
	var root := Node3D.new()
	var stages: Array = CROP_STAGES.get(crop, CROP_STAGES.veg)
	var si := mini(int(ripe * stages.size()), stages.size() - 1)
	var sc := lerpf(0.35, 1.0, ripe) * (0.8 if crop == "corn" else 1.0) * (1.0 + (level - 1) * 0.08)
	for r in 4:
		for c in 4:
			var st: String = stages[si]
			if crop == "veg" and si >= 2:
				st = stages[2 + (r + c) % 2]  # olgun sebze bahçesi: havuç + şalgam karışık
			var n := part(root, "nature/" + st, Vector3(c * 0.5 - 0.75, FIELD_SURFACE, r * 0.5 - 0.75), (r * 4 + c) * 37.0, Vector3.ONE * sc)
			if pest:
				tint(n, Color(0.62, 0.45, 0.22))
	return root


static func _greenhouse(root: Node3D) -> void:
	prim(root, BoxMesh.new(), mat("gh_base", Color(0.62, 0.52, 0.4)), Vector3(0, 0.01, 0)).scale = Vector3(1.92, 0.02, 0.9)
	for x in [-0.9, -0.45, 0.0, 0.45, 0.9]:
		var rib := TorusMesh.new()
		rib.inner_radius = 0.43
		rib.outer_radius = 0.455
		rib.rings = 24
		rib.ring_segments = 4
		prim(root, rib, mat("gh_rib", Color(0.85, 0.86, 0.88)), Vector3(x, 0, 0), Vector3(0, 0, 90)).scale = Vector3(1.75, 1, 1)
	for x in [-0.6, -0.2, 0.2, 0.6]:
		for z in [-0.18, 0.18]:
			part(root, "nature/crops_leafsStageB", Vector3(x, 0.02, z), x * 90.0, Vector3.ONE * 0.75)
	var cover := prim(root, cyl(0.45, 1.86), mat("gh_cover", Color(0.94, 0.97, 1.0, 0.45), true), Vector3(0, 0, 0), Vector3(0, 0, 90))
	cover.scale = Vector3(1.75, 1, 1)  # yüksek tünel: köylü içinde ayakta durabilsin
	cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _water_tower(root: Node3D) -> void:
	for p in [Vector2(-0.26, -0.26), Vector2(0.26, -0.26), Vector2(-0.26, 0.26), Vector2(0.26, 0.26)]:
		part(root, "town/pillar-wood", Vector3(p.x, 0, p.y), 0.0, Vector3(0.7, 1.35, 0.7))
	prim(root, cyl(0.38, 0.5), mat("tank", Color(0.93, 0.93, 0.9)), Vector3(0, 1.62, 0))
	prim(root, cyl(0.385, 0.08), mat("tank_band", Color(0.2, 0.45, 0.8)), Vector3(0, 1.52, 0))
	prim(root, cyl(0.02, 0.42, 0.4), mat("tank_lid", Color(0.75, 0.38, 0.22)), Vector3(0, 2.07, 0))


static func _grove(root: Node3D, variant: int) -> void:
	prim(root, cyl(0.46, 0.012), mat("grove_soil", Color(0.36, 0.26, 0.17)), Vector3(0, 0.006, 0))
	var orange := mat("orange", Color(1.0, 0.55, 0.08))
	orange.emission_enabled = true
	orange.emission = Color(0.5, 0.2, 0.0)
	var spots := [Vector3(-0.22, 0, -0.2), Vector3(0.24, 0, -0.12), Vector3(0.0, 0, 0.24)]
	for i in spots.size():
		var t := part(root, "nature/tree_default", spots[i], (i + variant) * 70.0, Vector3.ONE * 0.5)
		for k in 4:
			var a := k * TAU / 4.0 + i
			var fruit := prim(root, SphereMesh.new(), orange, spots[i] + Vector3(cos(a) * 0.13, 0.42 + (k % 2) * 0.1, sin(a) * 0.13))
			fruit.scale = Vector3.ONE * 0.07
			fruit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		t.set_meta("tree", true)


## Sokak lambası: taş kaide, ahşap direk, fener (ışık BuildingView'da).
static func _lamp(root: Node3D) -> void:
	prim(root, cyl(0.16, 0.12), mat("lamp_base", Color(0.72, 0.68, 0.6)), Vector3(0, 0.06, 0))
	prim(root, cyl(0.045, 1.0), mat("lamp_pole", Color(0.35, 0.24, 0.15)), Vector3(0, 0.6, 0))
	part(root, "town/lantern", Vector3(0, 1.0, 0), 0.0, Vector3.ONE * 0.75)


## Ambar: ahşap duvarlı, kiremit çatılı depo; kapı önünde çuvallar.
static func _granary(root: Node3D) -> void:
	walls(root, 2, 1, 0.0, ["wall-wood-door", "wall-wood-window-small"], ["wall-wood"], ["wall-wood", "wall-wood-window-small"])
	part(root, "town/roof-point", Vector3(0, 1.0, 0), 0.0, Vector3(2.0, 0.85, 1.0))
	var sack := mat("sack", Color(0.82, 0.72, 0.52))
	for p in [Vector3(0.75, 0.12, 0.62), Vector3(0.55, 0.12, 0.68), Vector3(0.66, 0.3, 0.64)]:
		prim(root, cyl(0.11, 0.24, 0.08), sack, p)


## Sera bitkileri: 2 sıra × 4, seçilen ürün ve olgunluğa göre büyür (tünelin içinde, biraz küçük).
static func greenhouse_plants(ripe: float, pest: bool, crop := "veg") -> Node3D:
	var root := Node3D.new()
	var stages: Array = CROP_STAGES.get(crop, CROP_STAGES.veg)
	var si := mini(int(ripe * stages.size()), stages.size() - 1)
	var sc := lerpf(0.3, 0.75, ripe) * (0.7 if crop == "corn" else 1.0)
	var i := 0
	for x in [-0.6, -0.2, 0.2, 0.6]:
		for z in [-0.18, 0.18]:
			var st: String = stages[si]
			if crop == "veg" and si >= 2:
				st = stages[2 + i % 2]
			var n := part(root, "nature/" + st, Vector3(x, 0.02, z), i * 47.0, Vector3.ONE * sc)
			if pest:
				tint(n, Color(0.62, 0.45, 0.22))
			i += 1
	return root
