extends "res://tests/hoe_clearance.gd"

func _ready() -> void:
	for activity in ["axe","pickaxe","basket","water_crop"]:
		var person := preload("res://tt_models/scripts/worker_model.gd").create(self)
		person.position = Vector3.ZERO
		person.set_meta("settling",1.0)
		for frame in 240:
			var t := frame/60.0
			preload("res://tt_models/scripts/worker_pose.gd").apply(person,{"state":"working"},0,0,t,1.0/60,activity,Vector3.ZERO,activity=="water_crop",false)
			var rig := person.get_node("FarmRig")
			for side in 2:
				if activity == "basket" and side == 1: continue
				for part in 2:
					var bone: Node3D = rig.get_node("Bone%d%d"%[side,part])
					assert(bone.scale.y <= 0.305, "Stretched arm: "+activity+str(bone.scale.y))
					for sample in range(1,10):
						assert(not inside_body(person,bone.to_global(Vector3(0,-0.5+sample/10.0,0)),0.025),"Equipment arm enters torso/head: "+activity+str([frame,side,part]))
			if activity == "basket":
				assert(person.get_node("Basket").to_global(Vector3(0,0.30,0)).distance_to(rig.get_node("Grip0").global_position)<0.0001)
			if activity == "water_crop":
				assert(not person.get_node("Bucket").visible)
				assert(person.get_node("WateringCan").visible)
				if frame == 0:
					assert(person.get_node("Pour").get_child(0).global_position.distance_to(person.get_node("WateringCan/Outlet").global_position)<0.0001)
		person.free()
	print("EQUIPMENT_OK: full strokes, arm reach/clearance, handle grip, nozzle origin")
	print("TEST_OK equipment_motion")
	get_tree().quit()
