extends RefCounted
## Shared plaster, terracotta and timber palette for village service buildings.
const Art = preload("res://tt_models/scripts/models.gd")
const Civic = preload("res://tt_models/scripts/civic_art.gd")
const Pack = preload("res://tt_models/scripts/game_models.gd")
static var meshes := {}

static func bake(raw: Node3D, key: String) -> Node3D:
	if not meshes.has(key):
		var groups := {}
		Pack.merge_walk(raw, Transform3D.IDENTITY, groups)
		meshes[key] = []
		for material in groups:
			var mesh: ArrayMesh = groups[material].commit()
			mesh.surface_set_material(0, material)
			meshes[key].append(mesh)
	raw.free()
	var root := Node3D.new()
	for mesh in meshes[key]:
		var part := MeshInstance3D.new()
		part.mesh = mesh
		root.add_child(part)
	return root

static func station() -> Node3D:
	var raw := Node3D.new()
	if not meshes.has("station"):
		Art.box(raw, Vector3(0,0.04,0), Vector3(1.96,0.08,1.98), "#b6a788")
		# Hollow garage: one opening, enough clearance for the 0.52-scale truck.
		for side in [-1,1]:
			Art.box(raw,Vector3(side*0.91,0.68,0),Vector3(0.14,1.28,1.90),"#ecddbd")
			Art.box(raw,Vector3(side*0.76,0.68,0.89),Vector3(0.31,1.28,0.14),"#ecddbd")
			Art.box(raw,Vector3(side*0.91,0.18,0),Vector3(0.16,0.24,1.92),"#b8a181")
			Art.box(raw,Vector3(side*0.61,0.62,0.98),Vector3(0.09,1.18,0.09),"#c3aa84")
			Civic.window(raw,side*0.99,0.79,-0.12,side*PI/2)
		Art.box(raw,Vector3(0,0.68,-0.91),Vector3(1.82,1.28,0.14),"#ecddbd")
		Art.box(raw,Vector3(0,1.30,0.89),Vector3(1.94,0.24,0.17),"#ecddbd")
		Art.box(raw,Vector3(0,1.31,0.995),Vector3(1.20,0.17,0.045),"#993b32")
		Civic.hip_tiled_roof(raw,Vector3(0,1.44,0),2.10,2.12,0.48,0.95)
		for side in [-1,1]:
			Art.box(raw,Vector3(side*0.77,1.09,1.0),Vector3(0.12,0.09,0.08),"#4d594e")
			Art.ball(raw,Vector3(side*0.77,1.09,1.05),Vector3.ONE*0.065,"#e8bc66")
	var root := bake(raw,"station")
	signboard(root,"İTFAİYE 112",Vector3(0,1.67,1.24),Vector2(1.70,0.32),Color("8a302b"))
	var shutter := Node3D.new()
	shutter.name = "GarageDoor"
	root.add_child(shutter)
	# Door is anchored at its lintel and rolls upwards by shrinking towards it.
	shutter.position = Vector3(0,1.19,0.965)
	Art.box(shutter,Vector3(0,-0.55,0),Vector3(1.12,1.10,0.06),"#ae4536")
	for row in 10:
		Art.box(shutter,Vector3(0,-0.06-row*0.108,0.04),Vector3(1.10,0.018,0.018),"#d88962")
	Art.box(shutter,Vector3(0,-0.93,0.05),Vector3(0.25,0.045,0.035),"#e0cba5")
	var parked := Models.spawn("car/firetruck")
	parked.name = "ParkedTruck"
	parked.scale = Vector3.ONE * 0.52
	root.add_child(parked)
	return root

static func granary() -> Node3D:
	var raw := Node3D.new()
	if not meshes.has("granary"):
		Art.box(raw,Vector3(0,0.09,0),Vector3(1.86,0.18,0.94),"#ac987a")
		Art.box(raw,Vector3(0,0.63,0),Vector3(1.72,0.96,0.80),"#ecddbd")
		for y in [0.22,1.04]:
			Art.box(raw,Vector3(0,y,0),Vector3(1.79,0.07,0.86),"#a47d50")
		for side in [-1,1]:
			for row in 4:
				Art.box(raw,Vector3(side*0.79,0.32+row*0.19,0.415),Vector3(0.19,0.14,0.08),"#c6af89")
			Civic.window(raw,side*0.59,0.72,0.43,0.0)
		Art.box(raw,Vector3(0,0.53,0.43),Vector3(0.64,0.76,0.06),"#694e36")
		for i in 6:
			Art.box(raw,Vector3(-0.25+i*0.10,0.53,0.47),Vector3(0.085,0.72,0.03),"#956c43")
		for y in [0.28,0.72]:
			Art.box(raw,Vector3(0,y,0.495),Vector3(0.62,0.045,0.025),"#c6a36b")
		Art.box(raw,Vector3(0,0.98,0.46),Vector3(0.66,0.16,0.035),"#3e7970")
		Civic.hip_tiled_roof(raw,Vector3(0,1.14,0),1.98,1.05,0.43,0.90)
		# Small tied grain sacks instead of an industrial silo.
		for i in 2:
			Art.ball(raw,Vector3(0.57+i*0.20,0.29,0.47),Vector3(0.20,0.33,0.20),"#d7bd83")
			Art.cylinder(raw,Vector3(0.57+i*0.20,0.46,0.47),0.045,0.06,"#887045")
	var root := bake(raw,"granary")
	signboard(root,"AMBAR",Vector3(0,1.07,0.66),Vector2(0.84,0.26),Color("3e5845"))
	return root


static func signboard(root: Node3D, text: String, at: Vector3, size: Vector2, color: Color) -> void:
	var board := Node3D.new()
	board.name = "Signboard"
	board.position = at
	root.add_child(board)
	Art.box(board,Vector3.ZERO,Vector3(size.x,size.y,0.06),"#d8ba7e")
	Art.box(board,Vector3(0,0,0.035),Vector3(size.x-0.035,size.y-0.035,0.025),color.to_html())
	var label := Label3D.new()
	label.name = "Lettering"
	label.text = text
	label.font = preload("res://assets/fonts/alegreya_sans_700.ttf")
	label.font_size = 128
	var text_width := label.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,128).x
	label.pixel_size = minf((size.x-0.12)/text_width,(size.y-0.07)/128.0)
	label.position.z = 0.058
	label.modulate = Color("fff4d8")
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	board.add_child(label)
