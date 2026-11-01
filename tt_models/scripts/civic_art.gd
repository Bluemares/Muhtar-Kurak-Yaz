extends RefCounted
## Civic silhouettes use the existing footprints; all detail is cosmetic geometry.
const Art = preload("res://tt_models/scripts/models.gd")

static func clock(parent: Node3D, at: Vector3, rot_y: float = 0.0) -> void:
	var dial := Node3D.new()
	parent.add_child(dial)
	dial.position = at
	dial.rotation.y = rot_y
	var rim := Art.cylinder(dial,Vector3.ZERO,0.28,0.06,"#8c6b42")
	rim.rotation.x = PI/2
	var inner_rim := Art.cylinder(dial,Vector3(0,0,0.02),0.25,0.05,"#c9a664")
	inner_rim.rotation.x = PI/2
	var face := Art.cylinder(dial,Vector3(0,0,0.04),0.225,0.035,"#f5ead0")
	face.rotation.x = PI/2
	for mark in 12:
		var angle := mark*TAU/12.0
		var is_quarter := mark % 3 == 0
		Art.box(dial,Vector3(sin(angle)*0.18,cos(angle)*0.18,0.062),Vector3(0.022 if is_quarter else 0.015,0.042 if is_quarter else 0.022,0.015),"#3d4a44").rotation.z = -angle
	Art.ball(dial,Vector3(0,0,0.075),Vector3.ONE*0.04,"#b8924d")
	Art.box(dial,Vector3(0,0.065,0.07),Vector3(0.024,0.145,0.018),"#2d3b36")
	var hand := Art.box(dial,Vector3(0.055,-0.015,0.07),Vector3(0.125,0.022,0.018),"#2d3b36")
	hand.rotation.z = -0.28

static func window(parent: Node3D, x: float, y: float, z: float, rot_y: float = 0.0, shutters: bool = true) -> void:
	var w := Node3D.new()
	parent.add_child(w)
	w.position = Vector3(x,y,z)
	w.rotation.y = rot_y
	Art.box(w,Vector3.ZERO,Vector3(0.46,0.58,0.08),"#c7b48b")
	Art.arch(w,Vector3(0,0.29,0.01),0.46,0.14,0.09,"#d4c29a")
	Art.box(w,Vector3(0,0,0.045),Vector3(0.35,0.47,0.035),"#2f6661")
	Art.box(w,Vector3(0,0,0.07),Vector3(0.032,0.47,0.03),"#e8dcc0")
	Art.box(w,Vector3(0,0.04,0.07),Vector3(0.35,0.032,0.03),"#e8dcc0")
	Art.box(w,Vector3(0,-0.31,0.065),Vector3(0.56,0.075,0.18),"#d7c59f")
	if shutters:
		for side in [-1,1]:
			Art.box(w,Vector3(side*0.27,0,0.055),Vector3(0.13,0.49,0.045),"#3b827a")
			for slat in 4:
				Art.box(w,Vector3(side*0.27,-0.15+slat*0.10,0.08),Vector3(0.10,0.025,0.02),"#66a39b")

static func hip_tiled_roof(parent: Node3D, at: Vector3, width: float, depth: float, height: float, ridge: float = 0.9) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	Art.box(root,Vector3(0,-0.04,0),Vector3(width+0.12,0.09,depth+0.12),"#7d583a")
	Art.hip_roof(root,Vector3(0,0,0),Vector2(width+0.06,depth+0.06),Vector2(ridge,0.16),height,"#a65238")
	for step in 4:
		var t0 := float(step)/4.0
		var t1 := float(step+0.82)/4.0
		var w0 := lerpf(width+0.02,ridge+0.08,t0)
		var d0 := lerpf(depth+0.02,0.22,t0)
		var w1 := lerpf(width+0.02,ridge+0.08,t1)
		var d1 := lerpf(depth+0.02,0.22,t1)
		var palette := ["#bf6640","#cf774c","#b05737","#c76e45"]
		Art.hip_roof(root,Vector3(0,t0*height+0.015,0),Vector2(w0,d0),Vector2(w1,d1),(t1-t0)*height,palette[step%4])
	for col in 7:
		var cap := Art.cylinder(root,Vector3(-ridge*0.42+col*(ridge*0.84/6.0),height+0.03,0),0.09,ridge/6.2,"#de925a")
		cap.rotation.z = PI/2

static func hall(parent: Node3D, level: int) -> void:
	# Plinth and terraced steps
	Art.box(parent,Vector3(0,0.11,0),Vector3(2.82,0.22,2.76),"#9e9176")
	Art.box(parent,Vector3(0,0.24,0),Vector3(2.68,0.08,2.60),"#bfb092")
	# Ground floor rusticated stone & upper warm stucco (cumba style)
	Art.box(parent,Vector3(0,0.68,-0.08),Vector3(2.44,0.84,2.14),"#d6c6a5")
	Art.box(parent,Vector3(0,1.12,-0.08),Vector3(2.54,0.09,2.24),"#8a6845")
	Art.box(parent,Vector3(0,1.58,-0.08),Vector3(2.50,0.86,2.18),"#f0e4c8")
	Art.box(parent,Vector3(0,2.03,-0.08),Vector3(2.60,0.10,2.28),"#8a6845")
	# Corner stone quoins and timber framing
	for sx in [-1,1]:
		for sz in [-1,1]:
			for row in 4:
				Art.box(parent,Vector3(sx*1.20,0.36+row*0.20,-0.08+sz*1.04),Vector3(0.18,0.15,0.16),["#bfb08e","#cfc09e"][row%2])
			Art.box(parent,Vector3(sx*1.23,1.58,-0.08+sz*1.07),Vector3(0.10,0.84,0.10),"#7d5c3b")
	# Front colonnade arcade (+Z) with 3 arches and wooden terrace
	Art.box(parent,Vector3(0,0.23,1.18),Vector3(2.16,0.08,0.48),"#c8ba9b")
	for step in 3:
		Art.box(parent,Vector3(0,0.04+step*0.055,1.46-step*0.10),Vector3(1.24-step*0.06,0.07,0.18),"#d4c6a8")
	for px in [-0.92,-0.34,0.34,0.92]:
		Art.box(parent,Vector3(px,0.29,1.30),Vector3(0.18,0.10,0.18),"#9e9176")
		Art.cylinder(parent,Vector3(px,0.68,1.30),0.068,0.70,"#dfd2b5")
		Art.box(parent,Vector3(px,1.04,1.30),Vector3(0.17,0.07,0.17),"#b8a786")
	for ax in [-0.63,0.0,0.63]:
		Art.box(parent,Vector3(ax,1.08,1.30),Vector3(0.58,0.10,0.14),"#c9b998")
	# Double arched main entrance door
	Art.arch(parent,Vector3(0,0.26,0.99),0.68,0.82,0.08,"#593e25")
	for side in [-1,1]:
		Art.box(parent,Vector3(side*0.15,0.58,1.03),Vector3(0.26,0.62,0.04),"#785536")
		Art.ball(parent,Vector3(side*0.06,0.56,1.06),Vector3.ONE*0.045,"#dfb965")
	# COP31 plaque & emblem above the central arch
	Art.box(parent,Vector3(0,1.22,1.34),Vector3(0.76,0.22,0.06),"#275952")
	Art.box(parent,Vector3(0,1.22,1.32),Vector3(0.82,0.27,0.04),"#c7a45e")
	Art.ball(parent,Vector3(-0.24,1.22,1.38),Vector3(0.13,0.13,0.05),"#5cb892")
	Art.box(parent,Vector3(0.08,1.25,1.38),Vector3(0.38,0.04,0.03),"#f2e5c4")
	Art.box(parent,Vector3(0.08,1.18,1.38),Vector3(0.28,0.03,0.03),"#d9c493")
	# Projecting upper wooden bay (cumba) in the center
	Art.box(parent,Vector3(0,1.56,1.14),Vector3(0.84,0.78,0.34),"#f4ead2")
	Art.box(parent,Vector3(0,1.14,1.16),Vector3(0.88,0.08,0.38),"#7d5c3b")
	for side in [-1,1]:
		Art.box(parent,Vector3(side*0.34,1.02,1.14),Vector3(0.08,0.22,0.28),"#7d5c3b")
	window(parent,0,1.58,1.31,0.0,false)
	# Front, side and back windows
	for side in [-1,1]:
		window(parent,side*0.82,0.68,0.99,0.0,false)
		window(parent,side*0.82,1.58,1.01)
		for z_off in [-0.52,0.36]:
			window(parent,side*1.25,1.58,z_off,side*PI/2,false)
			window(parent,side*1.22,0.68,z_off,side*PI/2,false)
		window(parent,side*0.68,1.58,-1.17,PI)
	#Mediterranean hipped tiled roof
	hip_tiled_roof(parent,Vector3(0,2.08,-0.08),2.76,2.44,0.72,0.95)
	# Octagonal/belvedere clock tower with open belfry arches
	var tz := -0.2
	Art.box(parent,Vector3(0,2.78,tz),Vector3(0.92,0.12,0.92),"#8a6845")
	Art.box(parent,Vector3(0,3.18,tz),Vector3(0.84,0.72,0.84),"#efe2c4")
	for sx in [-1,1]:
		for sz in [-1,1]:
			Art.box(parent,Vector3(sx*0.40,3.18,tz+sz*0.40),Vector3(0.10,0.74,0.10),"#b8a47e")
	clock(parent,Vector3(0,3.22,tz+0.43),0.0)
	clock(parent,Vector3(0.43,3.22,tz),PI/2)
	clock(parent,Vector3(-0.43,3.22,tz),-PI/2)
	clock(parent,Vector3(0,3.22,tz-0.43),PI)
	Art.box(parent,Vector3(0,3.57,tz),Vector3(0.96,0.09,0.96),"#8a6845")
	# Belfry lantern pillars & brass bell
	for sx in [-1,1]:
		for sz in [-1,1]:
			Art.box(parent,Vector3(sx*0.35,3.77,tz+sz*0.35),Vector3(0.09,0.32,0.09),"#dfd1b2")
	Art.cylinder(parent,Vector3(0,3.76,tz),0.14,0.20,"#d4ac55",0.08)
	Art.ball(parent,Vector3(0,3.66,tz),Vector3.ONE*0.06,"#9e7832")
	hip_tiled_roof(parent,Vector3(0,3.94,tz),1.08,1.08,0.38,0.18)
	Art.cylinder(parent,Vector3(0,4.38,tz),0.03,0.26,"#c7a362")
	Art.ball(parent,Vector3(0,4.52,tz),Vector3.ONE*0.09,"#e3c376")
	# Twin flags at the porch
	for side in [-1,1]:
		Art.cylinder(parent,Vector3(side*1.08,1.88,1.22),0.024,1.35,"#bf9f61")
		Art.box(parent,Vector3(side*1.22,2.38,1.22),Vector3(0.30,0.22,0.025),"#2e857a" if side == 1 else "#d45546")
	# Level upgrades: solar panels, rainwater pergola, climate sensors & lanterns
	if level >= 2:
		Art.box(parent,Vector3(0,1.16,1.38),Vector3(1.88,0.07,0.24),"#6b8f82")
		for post in 7:
			Art.box(parent,Vector3(-0.84+post*0.28,1.32,1.46),Vector3(0.035,0.28,0.035),"#4c6e63")
		Art.box(parent,Vector3(0,1.46,1.46),Vector3(1.88,0.045,0.05),"#4c6e63")
		for side in [-1,1]:
			var solar := Art.box(parent,Vector3(side*0.66,2.50,0.44),Vector3(0.58,0.05,0.44),"#24495e")
			solar.rotation.x = 0.49
			Art.box(parent,Vector3(side*0.66,2.52,0.44),Vector3(0.52,0.055,0.38),"#376c8a").rotation.x = 0.49
	if level >= 3:
		Art.cylinder(parent,Vector3(-1.12,0.58,-0.88),0.26,0.76,"#588c87")
		Art.cylinder(parent,Vector3(-1.12,0.98,-0.88),0.28,0.06,"#3f6965")
		for side in [-1,1]:
			Art.ball(parent,Vector3(side*1.12,0.36,1.36),Vector3(0.28,0.32,0.28),"#4d7d47")
			Art.cylinder(parent,Vector3(side*1.12,0.18,1.36),0.14,0.22,"#b56745",0.18)
	for i in mini(level-1,5):
		Art.ball(parent,Vector3(-0.36+i*0.18,1.08,1.48),Vector3.ONE*0.07,"#ebc86b")

static func station(parent: Node3D) -> void:
	# Concrete apron with red-and-white safety curbs and yellow bay guide lines
	Art.box(parent,Vector3(0,0.06,0.05),Vector3(2.86,0.12,1.94),"#9e9784")
	for side in [-1,1]:
		for seg in 4:
			Art.box(parent,Vector3(side*1.38,0.13,-0.65+seg*0.44),Vector3(0.08,0.04,0.22),"#c9493b" if seg%2 == 0 else "#ede6d5")
	for x in [-0.96,-0.06,0.84]:
		Art.box(parent,Vector3(x,0.122,0.88),Vector3(0.05,0.01,0.28),"#dfb854")
	# Main stone & warm plaster apparatus hall (shifted slightly right to balance left watchtower)
	Art.box(parent,Vector3(0.18,0.82,-0.02),Vector3(2.38,1.44,1.62),"#e8dac0")
	Art.box(parent,Vector3(0.18,0.26,-0.02),Vector3(2.44,0.32,1.68),"#b8aa8e")
	# bold crimson firehouse fascia & cornice band
	Art.box(parent,Vector3(0.18,1.42,0.02),Vector3(2.48,0.22,1.72),"#b83d32")
	Art.box(parent,Vector3(0.18,1.56,0.02),Vector3(2.54,0.08,1.78),"#d9cab0")
	# Left stone & timber hose-drying / siren watchtower
	var tx := -1.02
	var tz := -0.28
	Art.box(parent,Vector3(tx,1.18,tz),Vector3(0.68,2.16,0.72),"#d1c1a1")
	for row in 6:
		Art.box(parent,Vector3(tx-0.31,0.28+row*0.32,tz+0.32),Vector3(0.12,0.16,0.12),"#b09e7e")
	Art.box(parent,Vector3(tx,2.24,tz),Vector3(0.80,0.10,0.84),"#876443")
	# Open wooden lookout gallery at top of tower with hanging red drying hoses & siren
	for sx in [-1,1]:
		for sz in [-1,1]:
			Art.box(parent,Vector3(tx+sx*0.28,2.52,tz+sz*0.30),Vector3(0.07,0.46,0.07),"#755436")
	Art.box(parent,Vector3(tx,2.38,tz),Vector3(0.74,0.05,0.78),"#755436")
	for h in [-0.10,0.10]:
		Art.box(parent,Vector3(tx+h,1.85,tz+0.37),Vector3(0.055,0.92,0.03),"#c95140")
	hip_tiled_roof(parent,Vector3(tx,2.75,tz),0.88,0.92,0.34,0.16)
	# Rooftop siren horn & flashing beacon on tower
	Art.cylinder(parent,Vector3(tx,3.16,tz),0.04,0.18,"#6e7573")
	var horn := Art.cylinder(parent,Vector3(tx+0.08,3.24,tz+0.06),0.04,0.18,"#c9493b",0.11)
	horn.rotation.z = -PI/2
	Art.ball(parent,Vector3(tx,3.30,tz),Vector3.ONE*0.10,"#ff6b4a")
	# Twin arched fire-engine bays with glazed red bi-fold doors & truck nose peeking in bay 1
	for i in 2:
		var bx := -0.36+i*0.92
		Art.arch(parent,Vector3(bx,0.12,0.78),0.84,1.20,0.12,"#e8dac0")
		Art.arch(parent,Vector3(bx,0.12,0.80),0.76,1.15,0.12,"#7a261e")
		Art.arch(parent,Vector3(bx,0.12,0.75),0.68,1.08,0.10,"#242220")
		if i == 0:
			# Open bay with fire truck cab, bumper, windshield & beacon visible inside
			Art.box(parent,Vector3(bx,0.44,0.68),Vector3(0.54,0.46,0.38),"#d13b2e")
			Art.box(parent,Vector3(bx,0.62,0.76),Vector3(0.48,0.20,0.20),"#92c4c9")
			Art.box(parent,Vector3(bx,0.38,0.87),Vector3(0.32,0.14,0.04),"#d8dbd6")
			Art.box(parent,Vector3(bx,0.24,0.88),Vector3(0.58,0.09,0.08),"#e6e1d3")
			Art.ball(parent,Vector3(bx,0.76,0.72),Vector3.ONE*0.07,"#ff7747")
			for light in [-1,1]:
				Art.ball(parent,Vector3(bx+light*0.20,0.36,0.88),Vector3.ONE*0.075,"#ffe078")
			for side in [-1,1]:
				Art.box(parent,Vector3(bx+side*0.33,0.62,0.86),Vector3(0.11,0.92,0.05),"#c44739")
				Art.box(parent,Vector3(bx+side*0.33,0.82,0.89),Vector3(0.07,0.24,0.03),"#92c4c9")
		else:
			# Closed red bi-fold glazed bay doors with windows, panels and brass handles
			for side in [-1,1]:
				Art.box(parent,Vector3(bx+side*0.17,0.62,0.84),Vector3(0.31,0.94,0.05),"#c9493b")
				Art.box(parent,Vector3(bx+side*0.17,0.84,0.875),Vector3(0.23,0.25,0.03),"#8ec0c4")
				Art.box(parent,Vector3(bx+side*0.17,0.84,0.89),Vector3(0.25,0.025,0.02),"#e8dac0")
				Art.box(parent,Vector3(bx+side*0.17,0.42,0.875),Vector3(0.23,0.34,0.025),"#9e3125")
				Art.box(parent,Vector3(bx+side*0.04,0.58,0.89),Vector3(0.025,0.12,0.03),"#e6c36a")
	# Central fire crest (shield + "112" emergency bars) & alarm lights
	Art.box(parent,Vector3(0.10,1.42,0.90),Vector3(0.96,0.22,0.06),"#f5ead0")
	Art.box(parent,Vector3(0.10,1.42,0.93),Vector3(0.88,0.15,0.04),"#b83428")
	for d in [-0.20,-0.06,0.10]:
		Art.box(parent,Vector3(0.10+d,1.42,0.955),Vector3(0.045 if d < 0 else 0.12,0.09,0.02),"#f5ead0")
	Art.cylinder(parent,Vector3(-0.56,1.42,0.91),0.14,0.06,"#e3b859").rotation.x = PI/2
	Art.ball(parent,Vector3(-0.56,1.42,0.94),Vector3(0.16,0.18,0.05),"#d13b2e")
	for x in [-0.82,0.10,1.02]:
		Art.box(parent,Vector3(x,1.28,0.87),Vector3(0.14,0.10,0.12),"#4a4742")
		Art.ball(parent,Vector3(x,1.25,0.92),Vector3.ONE*0.08,"#f5c85b")
	# Main roof over apparatus hall + solar water heater tank
	hip_tiled_roof(parent,Vector3(0.18,1.60,-0.02),2.56,1.82,0.52,1.15)
	var tank := Art.cylinder(parent,Vector3(0.68,2.14,-0.25),0.16,0.52,"#d8dbd6")
	tank.rotation.z = PI/2
	# Right & rear equipment: emergency water tank, coiled hose reel, ladders & extinguishers
	var shape := TorusMesh.new()
	shape.inner_radius = 0.14
	shape.outer_radius = 0.22
	shape.rings = 16
	shape.ring_segments = 8
	var hose := Art.mesh(parent,shape,Vector3(1.40,0.72,0.22),"#cfad6e")
	hose.rotation.z = PI/2
	Art.box(parent,Vector3(1.38,0.72,0.22),Vector3(0.10,0.10,0.52),"#5c5242")
	for z in [-0.52,-0.28]:
		Art.cylinder(parent,Vector3(1.40,0.42,z),0.075,0.48,"#c43e31")
		Art.box(parent,Vector3(1.40,0.68,z),Vector3(0.06,0.06,0.08),"#4f5750")
	# Side mounted wooden rescue ladder on rear/side wall
	for rail in [-0.12,0.12]:
		Art.box(parent,Vector3(0.25,0.88+rail,-0.85),Vector3(1.45,0.04,0.04),"#b88b52")
	for rung in 7:
		Art.box(parent,Vector3(-0.36+rung*0.20,0.88,-0.86),Vector3(0.03,0.26,0.03),"#cfa266")
