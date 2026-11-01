extends RefCounted
const Art = preload("res://tt_models/scripts/models.gd")
const Civic = preload("res://tt_models/scripts/civic_art.gd")
static var templates: Dictionary = {}

static func merge_walk(node: Node3D, transform: Transform3D, groups: Dictionary) -> void:
	var local := transform*node.transform
	if node is MeshInstance3D:
		var material: Material = node.material_override
		if not groups.has(material):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[material] = surface
		groups[material].append_from(node.mesh,0,local)
	for child in node.get_children():
		if child is Node3D: merge_walk(child,local,groups)

static func model(kind: String, level: int, ruined: bool = false) -> Node3D:
	# Cache merged meshes, not hundreds of individual tiles per building.
	var key := kind+str(level)+str(ruined)
	if not templates.has(key):
		var raw := Node3D.new()
		if ruined:
			Art.cylinder(raw,Vector3(0,0.01,0),0.83,0.025,"#514e40")
			for i in 8:
				var rubble := Art.box(raw,Vector3(sin(i*8)*0.7,0.12,cos(i*7)*0.6),Vector3(0.5,0.15+i%3*0.12,0.4),"#645d50")
				rubble.rotation.y = i*0.7
		elif kind == "house":
			Art.house(raw,Vector3.ZERO).scale = Vector3.ONE*0.65
		elif kind == "well":
			Art.well(raw,Vector3.ZERO,false)
			raw.scale = Vector3.ONE*0.75
			if level >= 2:
				var wheel := Art.cylinder(raw,Vector3(0.94,1.38,0),0.34,0.08,"#8c6239")
				wheel.rotation.z = PI/2
				var rim := Art.cylinder(raw,Vector3(0.97,1.38,0),0.24,0.09,"#cfa96b")
				rim.rotation.z = PI/2
				Art.box(raw,Vector3(0,0.28,0.88),Vector3(1.10,0.26,0.34),"#9e9172")
				Art.box(raw,Vector3(0,0.34,0.88),Vector3(0.94,0.16,0.22),"#3a8c99")
			if level >= 3:
				Art.cylinder(raw,Vector3(0.92,0.58,-0.58),0.38,0.96,"#5c8d89")
				Art.cylinder(raw,Vector3(0.92,1.08,-0.58),0.41,0.08,"#3f6965")
				for band in [0.32,0.78]:
					Art.cylinder(raw,Vector3(0.92,band,-0.58),0.395,0.05,"#b89658")
				var pipe := Art.cylinder(raw,Vector3(0.48,0.72,-0.32),0.045,0.62,"#6b7a78")
				pipe.rotation.z = PI/2
		elif kind == "cop":
			Civic.hall(raw,level)
		elif kind == "station":
			Civic.station(raw)
		var groups := {}
		merge_walk(raw,Transform3D.IDENTITY,groups)
		var meshes: Array = []
		for material in groups:
			var merged: ArrayMesh = groups[material].commit()
			merged.surface_set_material(0,material)
			meshes.append(merged)
		templates[key] = meshes
		raw.free()
	var root := Node3D.new()
	for resource in templates[key]:
		var mesh := MeshInstance3D.new()
		mesh.mesh = resource
		root.add_child(mesh)
	return root

static func truck() -> Node3D:
	return preload("res://tt_models/scripts/response_truck.gd").new()
