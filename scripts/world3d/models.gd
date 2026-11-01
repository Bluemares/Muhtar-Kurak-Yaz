class_name Models
extends RefCounted
## 3D model yükleyici. Modeller `assets/models/<klasör>/<ad>.glb`; Blender modelleri aynı adla konursa
## kod değişmeden onlar yüklenir (bkz. docs/MODELS_3D.md).

const ROOT := "res://assets/models/"

# Kenney Nature Kit malzemeleri metalik ve nane tonlu geliyor: Antalya paleti (malzeme adına göre).
const PALETTE := {
	"stone": "b3ab9c", "stoneDark": "8f887c", "woodBark": "8a5a3a", "wood": "b07d4f", "woodDark": "6b4429",
	"woodBarkDark": "7a3f2a", "woodBirch": "e8dcc6", "woodInner": "d9b88a", "leafsFall": "d98a3a",
	"leafsDark": "3e5f2a", "leafsGreen": "5f8a34", "grass": "7d8f3c", "dirt": "a07a52", "dirtDark": "7a5a3c",
	"corn": "e8c35a", "colorPurple": "9a7ad6", "colorRed": "d9473f", "colorYellow": "f2c744",
	"colorRedDark": "a83a33", "_defaultMat": "cccccc",
}

const TOWN_TEX := "res://assets/models/town/Textures/colormap_antalya.png"  # tools/make_antalya_colormap.py

static var _scenes := {}
static var _meshes := {}
static var _town_tex: Texture2D
static var _skin := "?"


## Test kancası: "-- --skin=tests/_cmp/gpt/" ile model seti denenir (dosya orada yoksa normal klasör).
static func _overlay() -> String:
	if _skin == "?":
		_skin = ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--skin="):
				_skin = "res://" + a.trim_prefix("--skin=")
	return _skin


static func path(name: String) -> String:
	var o := _overlay()
	if o != "" and ResourceLoader.exists(o + name + ".glb"):
		return o + name + ".glb"
	return ROOT + name + ".glb"


static func scene(name: String) -> PackedScene:
	if not _scenes.has(name):
		# Keep animal skin data independent of the editor/export-template version.
		# The raw GLBs are shipped as .source files and parsed by the running engine.
		if name.begins_with("pets/"):
			var document := GLTFDocument.new()
			var state := GLTFState.new()
			var source_path := path(name)+".source"
			var bytes := FileAccess.get_file_as_bytes(source_path) if FileAccess.file_exists(source_path) else PackedByteArray()
			if not bytes.is_empty() and document.append_from_buffer(bytes,path(name).get_base_dir(),state) == OK:
				var root := document.generate_scene(state)
				if root:
					var packed := PackedScene.new()
					var result := packed.pack(root)
					root.free()
					if result == OK:
						_scenes[name] = packed
						return packed
		_scenes[name] = load(path(name)) if ResourceLoader.exists(path(name)) else null
	return _scenes[name]


## Modelin yeni bir kopyası (bulunamazsa boş Node3D).
static func spawn(name: String) -> Node3D:
	var s := scene(name)
	if s == null:
		push_warning("Model yok: " + name)
		return Node3D.new()
	var n := s.instantiate()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		fix(mi.mesh)
	return n


## Malzemeleri bir kez paletle düzeltir (mesh kaynağı paylaşıldığı için tüm kopyalar etkilenir).
static func fix(m: Mesh) -> void:
	if m == null or m.has_meta("fixed"):
		return
	m.set_meta("fixed", true)
	for i in m.get_surface_count():
		var mat := m.surface_get_material(i) as StandardMaterial3D
		if mat == null:
			continue
		mat = mat.duplicate()
		mat.metallic = 0.0
		mat.metallic_specular = 0.25
		if mat.albedo_texture and mat.albedo_texture.resource_path.contains("town/Textures/colormap"):
			if _town_tex == null:
				_town_tex = load(TOWN_TEX)
			mat.albedo_texture = _town_tex
		if PALETTE.has(mat.resource_name):
			mat.albedo_color = Color(PALETTE[mat.resource_name])
		if PALETTE.has(mat.resource_name) or mat.resource_name.begins_with("leafs"):
			mat.vertex_color_use_as_albedo = true  # MultiMesh örnek rengi (kurakta sararma)
		m.surface_set_material(i, mat)


## MultiMesh için tek parça mesh (modeldeki ilk MeshInstance3D, düğüm dönüşümüyle).
static func mesh(name: String) -> Mesh:
	if _meshes.has(name):
		return _meshes[name]
	var m: Mesh = null
	var s := scene(name)
	if s:
		var n := s.instantiate()
		var mis := n.find_children("*", "MeshInstance3D", true, false)
		if mis.size() == 1:
			m = mis[0].mesh
		elif mis.size() > 1:
			m = _merge(mis, n)
		n.free()
	fix(m)
	_meshes[name] = m
	return m


## Birden çok MeshInstance3D'yi tek ArrayMesh'e (yüzey başına malzeme korunarak) birleştirir.
static func _merge(mis: Array, root: Node) -> Mesh:
	var out := ArrayMesh.new()
	for mi: MeshInstance3D in mis:
		var xf := Transform3D.IDENTITY
		var p: Node = mi
		while p and p != root:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		for si in mi.mesh.get_surface_count():
			var st := SurfaceTool.new()
			st.append_from(mi.mesh, si, xf)
			st.set_material(mi.get_active_material(si))
			st.commit(out)
	return out
