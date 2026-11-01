extends RefCounted
const Art = preload("res://tt_models/scripts/models.gd")

static func create(parent: Node3D, variant := 0) -> Node3D:
	var person := preload("res://tt_models/scripts/villager.gd").new()
	person.variant = variant
	parent.add_child(person)
	person.set_process(false)
	person.scale = Vector3.ONE*0.65
	var hoe := Node3D.new()
	hoe.name = "Hoe"
	hoe.visible = false
	person.add_child(hoe)
	Art.box(hoe,Vector3(0,-0.15,0),Vector3(0.04,0.80,0.04),"#a27d4c")
	Art.box(hoe,Vector3(0,-0.55,-0.10),Vector3(0.24,0.035,0.22),"#6c8587")
	Art.box(hoe,Vector3(0,-0.55,-0.21),Vector3(0.24,0.018,0.025),"#c4d3d4")
	var bucket := Node3D.new()
	bucket.name = "Bucket"
	bucket.visible = false
	person.add_child(bucket)
	Art.cylinder(bucket,Vector3(0,-0.16,0),0.11,0.22,"#7b9da0",0.14)
	for side in [-1,1]: Art.box(bucket,Vector3(side*0.12,-0.03,0),Vector3(0.015,0.20,0.015),"#596f70")
	Art.box(bucket,Vector3.ZERO,Vector3(0.25,0.018,0.018),"#596f70")
	var surface := Art.cylinder(bucket,Vector3(0,-0.06,0),0.11,0.01,"#70b6c1")
	surface.name = "Water"
	var drops := Node3D.new()
	drops.name = "Pour"
	drops.visible = false
	person.add_child(drops)
	for i in 7:
		Art.ball(drops, Vector3.ZERO, Vector3(0.025, 0.055, 0.025), "#70b6c1")
	var basket := Node3D.new()
	basket.name = "Basket"
	basket.visible = false
	person.add_child(basket)
	basket.position = Vector3(-0.37, 0.29, 0.18)
	Art.cylinder(basket, Vector3.ZERO, 0.17, 0.21, "#996432", 0.20)
	# Basket handle: the shared pose rig grips its centre at y=0.30.
	for side in [-1,1]:
		Art.box(basket,Vector3(side*0.17,0.20,0),Vector3(0.028,0.22,0.035),"#c09256")
	Art.box(basket,Vector3(0,0.30,0),Vector3(0.36,0.035,0.035),"#c09256")
	for i in 5:
		Art.ball(basket, Vector3(sin(i * 2.4) * 0.10, 0.12, cos(i * 2.4) * 0.10), Vector3.ONE * 0.09, "#dd9c3d")
	var job := Art.ball(person,Vector3(0,1.57,0),Vector3.ONE*0.13,"#edcf7a")
	job.name = "Job"
	preload("res://tt_models/scripts/equipment_pose.gd").setup(person)
	return person
