extends RefCounted
## Original solid meshes; all objects share physical sunlight and real depth.
static var materials: Dictionary = {}

static func material(hex: String) -> StandardMaterial3D:
	if not materials.has(hex):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(hex)
		m.roughness = 0.88
		materials[hex] = m
	return materials[hex]

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material(color)
	node.position = at
	parent.add_child(node)
	return node

static func box(parent: Node3D, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent,shape,at,color)

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: String, top: float = -1.0) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0 else top
	shape.height = height
	shape.radial_segments = 12
	return mesh(parent,shape,at,color)

static func ball(parent: Node3D, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 12
	shape.rings = 6
	var node := mesh(parent,shape,at,color)
	node.scale = size
	return node

static func quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for p in [a,b,c,a,c,d]: surface.add_vertex(p)

## Faceted hip roof / pyramid frustum: base and top are XZ sizes, flat-shaded.
static func hip_roof(parent: Node3D, at: Vector3, base: Vector2, top: Vector2, height: float, color: String) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var bx := base.x*0.5
	var bz := base.y*0.5
	var tx := top.x*0.5
	var tz := top.y*0.5
	var b := [Vector3(-bx,0,-bz),Vector3(bx,0,-bz),Vector3(bx,0,bz),Vector3(-bx,0,bz)]
	var t := [Vector3(-tx,height,-tz),Vector3(tx,height,-tz),Vector3(tx,height,tz),Vector3(-tx,height,tz)]
	for i in 4:
		var j := (i+1)%4
		quad(surface,b[i],b[j],t[j],t[i])
	if top.x > 0.001 and top.y > 0.001:
		quad(surface,t[0],t[1],t[2],t[3])
	quad(surface,b[3],b[2],b[1],b[0])
	surface.generate_normals()
	return mesh(parent,surface.commit(),at,color)

## Round-headed opening facing +Z; `at` is the bottom centre.
static func arch(parent: Node3D, at: Vector3, width: float, height: float, depth: float, color: String) -> void:
	var straight := maxf(0.01,height-width*0.5)
	box(parent,at+Vector3(0,straight*0.5,0),Vector3(width,straight,depth),color)
	var shape := CylinderMesh.new()
	shape.top_radius = width*0.5
	shape.bottom_radius = width*0.5
	shape.height = depth
	shape.radial_segments = 16
	var top := mesh(parent,shape,at+Vector3(0,straight,0),color)
	top.rotation.x = PI/2

static var sign_font: SystemFont
## Language-neutral painted lettering; kept as a separate node when meshes are merged.
static func lettering(parent: Node3D, at: Vector3, text: String, size: float, color: String) -> Label3D:
	if sign_font == null:
		sign_font = SystemFont.new()
		sign_font.font_names = PackedStringArray(["Arial Black","Segoe UI Black","Arial","Sans-Serif"])
		sign_font.font_weight = 900
	var label := Label3D.new()
	label.text = text
	label.font = sign_font
	label.font_size = 96
	label.pixel_size = size/96.0
	label.modulate = Color(color)
	label.outline_size = 0
	label.double_sided = false
	label.shaded = true
	label.position = at
	parent.add_child(label)
	return label

static func roof(parent: Node3D, at: Vector3, width: float, depth: float) -> void:
	# Two pitched planes with individual chunky terracotta courses and ridge caps.
	for side in [-1,1]:
		var wing := Node3D.new()
		parent.add_child(wing)
		wing.position = at
		wing.rotation.z = -side*0.49
		box(wing,Vector3(side*width*0.25,0,0),Vector3(width*0.5,0.13,depth),"#8b442f")
		for row in 4:
			for col in 9:
				var tile := box(wing,Vector3(side*(row+0.5)*width/8.0,0.09,(col-4)*depth/9.0),Vector3(width/8.0+0.025,0.085,depth/9.0-0.025),["#bd6941","#cd7a49","#af5838"][(row+col*7)%3])
				tile.rotation.x = 0.025
	for col in 9:
		var cap := cylinder(parent,at+Vector3(0,0.12,(col-4)*depth/9.0),0.12,depth/9.0-0.015,"#dc9058")
		cap.rotation.x = PI/2

static func house(parent: Node3D, at: Vector3) -> Node3D:
	var home := Node3D.new()
	parent.add_child(home)
	home.position = at
	box(home,Vector3(0,0.12,0),Vector3(2.75,0.24,2.55),"#a29678")
	box(home,Vector3(0,0.34,0),Vector3(2.58,0.24,2.33),"#c8bba0")
	box(home,Vector3(0,1.12,0),Vector3(2.5,1.76,2.25),"#f0e2be")
	box(home,Vector3(0,1.22,0),Vector3(2.56,0.08,2.31),"#8a6744")
	box(home,Vector3(0,1.98,0),Vector3(2.6,0.13,2.35),"#9e7b54")
	# Gable ends close the roof volume, rather than leaving floating roof planes.
	for z in [-1.12,1.12]:
		var shape := PrismMesh.new()
		shape.size = Vector3(2.5,0.65,0.12)
		mesh(home,shape,Vector3(0,2.28,z),"#e9d5aa")
	roof(home,Vector3(0,2.65,0),3.0,2.8)
	for x in [-1.2,1.2]:
		for row in 5:
			box(home,Vector3(x,0.35+row*0.32,1.14),Vector3(0.25,0.24,0.10),"#c9b48b")
	arch(home,Vector3(0.35,0.22,1.13),0.72,1.22,0.10,"#b99d73")
	box(home,Vector3(0.35,0.74,1.15),Vector3(0.64,1.16,0.12),"#65482f")
	for plank in 5:
		box(home,Vector3(0.10+plank*0.125,0.74,1.225),Vector3(0.10,1.12,0.025),"#8d6843")
	ball(home,Vector3(0.56,0.72,1.27),Vector3.ONE*0.07,"#d5ad59")
	# Front porch step and tiled awning over the door
	box(home,Vector3(0.35,0.13,1.48),Vector3(1.15,0.20,0.58),"#d1bf97")
	var awning := box(home,Vector3(0.35,1.52,1.38),Vector3(1.06,0.08,0.48),"#bd653e")
	awning.rotation.x = 0.28
	for post in [-0.08,0.78]:
		box(home,Vector3(post,0.82,1.56),Vector3(0.08,1.34,0.08),"#7c5a3a")
	# Terracotta amphora by the porch
	cylinder(home,Vector3(0.98,0.34,1.36),0.12,0.32,"#b86743",0.16)
	cylinder(home,Vector3(0.98,0.52,1.36),0.09,0.08,"#9e5232",0.11)
	for x in [-0.65]:
		box(home,Vector3(x,1.22,1.15),Vector3(0.55,0.65,0.12),"#374f4c")
		for side in [-1,1]:
			box(home,Vector3(x+side*0.35,1.22,1.22),Vector3(0.24,0.70,0.09),"#3e877d")
			for slat in 5:
				box(home,Vector3(x+side*0.35,1.0+slat*0.11,1.28),Vector3(0.21,0.035,0.04),"#6ca699")
		box(home,Vector3(x,0.85,1.24),Vector3(0.77,0.10,0.24),"#d5c198")
		box(home,Vector3(x,0.92,1.30),Vector3(0.56,0.10,0.14),"#a85d3b")
		for flower in 3:
			ball(home,Vector3(x-0.18+flower*0.18,1.01,1.30),Vector3.ONE*0.11,["#d95f76","#eb9c4d","#dec45b"][flower])
	# Side window & stacked firewood under eaves
	box(home,Vector3(1.27,1.18,-0.20),Vector3(0.10,0.65,0.70),"#397c75")
	box(home,Vector3(1.34,1.18,-0.20),Vector3(0.07,0.60,0.055),"#d8c697")
	for log_i in 4:
		var log_mesh := cylinder(home,Vector3(1.34,0.28+(log_i/2)*0.11,0.55+(log_i%2)*0.14),0.055,0.36,"#7d5938")
		log_mesh.rotation.z = PI/2
	box(home,Vector3(-0.72,2.70,-0.60),Vector3(0.34,0.9,0.38),"#d1b38a")
	box(home,Vector3(-0.72,3.18,-0.60),Vector3(0.46,0.12,0.48),"#9e6a48")
	cylinder(home,Vector3(-0.72,3.32,-0.60),0.10,0.18,"#825034")
	for i in 7:
		var p := Vector3(-1.31,0.35+i*0.26,0.78+sin(i)*0.14)
		ball(home,p,Vector3(0.42,0.42,0.40),"#557e41")
		ball(home,p+Vector3(-0.10,0.08,0.16),Vector3.ONE*0.21,["#b65078","#dc83a1"][i%2])
	return home

static func well(parent: Node3D, at: Vector3, static_bucket: bool = true) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	cylinder(root,Vector3(0,0.08,0),1.02,0.16,"#b7aa86")
	cylinder(root,Vector3(0,0.17,0),0.86,0.06,"#9e9172")
	cylinder(root,Vector3(0,0.28,0),0.56,0.06,"#368894")
	for row in 3:
		for i in 12:
			var angle := (i+row*0.5)*TAU/12
			var stone := box(root,Vector3(cos(angle)*0.65,0.2+row*0.19,sin(angle)*0.65),Vector3(0.35,0.18,0.25),["#d3c5a1","#b7aa89","#e0d2ae"][(i+row)%3])
			stone.rotation.y = -angle-PI/2
	# Carved stone coping rim around the top of the well
	for i in 12:
		var angle := i*TAU/12
		var rim := box(root,Vector3(cos(angle)*0.66,0.75,sin(angle)*0.66),Vector3(0.38,0.09,0.30),"#dfd2b2")
		rim.rotation.y = -angle-PI/2
	for x in [-0.77,0.77]:
		box(root,Vector3(x,1.08,0),Vector3(0.15,1.70,0.17),"#7a5736")
		var brace := box(root,Vector3(x*0.78,1.68,0),Vector3(0.10,0.42,0.12),"#8f6842")
		brace.rotation.z = x*0.55
	roof(root,Vector3(0,2.04,0),1.95,1.5)
	var axle := cylinder(root,Vector3(0,1.38,0),0.065,1.65,"#634c35")
	axle.rotation.z = PI/2
	# Coiled rope drum & iron crank handle on the right post
	var drum := cylinder(root,Vector3(0,1.38,0),0.13,0.42,"#c2a373")
	drum.rotation.z = PI/2
	box(root,Vector3(0.88,1.38,0.14),Vector3(0.05,0.05,0.30),"#4c5452")
	box(root,Vector3(0.95,1.38,0.26),Vector3(0.16,0.05,0.05),"#7a5736")
	# Side stone water trough & terracotta jugs at base
	box(root,Vector3(-0.78,0.22,0.58),Vector3(0.46,0.22,0.32),"#a89b7d")
	box(root,Vector3(-0.78,0.28,0.58),Vector3(0.36,0.12,0.22),"#46929e")
	cylinder(root,Vector3(0.72,0.28,0.62),0.13,0.28,"#b86743",0.16)
	if static_bucket:
		cylinder(root,Vector3(0,0.99,0),0.018,0.75,"#c2a373")
		cylinder(root,Vector3(0,0.68,0),0.17,0.24,"#947853",0.21)

