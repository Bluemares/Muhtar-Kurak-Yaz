extends Node3D
## One reusable well bucket; the job's progress drives presentation, never rewards.
const Art = preload("res://tt_models/scripts/models.gd")
var bucket: Node3D
var rope: MeshInstance3D
var water: MeshInstance3D

func _ready() -> void:
	bucket = Node3D.new()
	add_child(bucket)
	Art.cylinder(bucket,Vector3(0,-0.09,0),0.12,0.18,"#947853",0.15)
	water = Art.cylinder(bucket,Vector3(0,-0.015,0),0.12,0.012,"#70b6c1")
	for side in [-1,1]: Art.box(bucket,Vector3(side*0.13,0.04,0),Vector3(0.018,0.12,0.018),"#596f70")
	Art.box(bucket,Vector3(0,0.10,0),Vector3(0.27,0.018,0.018),"#596f70")
	rope = Art.box(self,Vector3.ZERO,Vector3(0.015,1,0.015),"#c2a373")
	update_motion(-1,Vector3.ZERO)

func update_motion(progress: float, hand_world: Vector3) -> void:
	var q := clampf(progress,0,1)
	var hanging := Vector3(0,0.60,0)
	if progress < 0:
		bucket.position = hanging
	elif q < 0.25:
		bucket.position = hanging.lerp(Vector3(0,0.28,0),smoothstep(0,0.25,q))
	elif q < 0.75:
		bucket.position = Vector3(0,0.28,0).lerp(Vector3(0,0.82,0),smoothstep(0.25,0.75,q))
	else:
		var t := smoothstep(0.75,1,q)
		bucket.position = Vector3(0,0.82,0).lerp(to_local(hand_world),t)+Vector3.UP*sin(t*PI)*0.3
	water.visible = progress >= 0.25
	var top := Vector3(0,1.035,0)
	var end := bucket.position+Vector3(0,0.10,0)
	rope.visible = progress < 0.90
	rope.position = (top+end)*0.5
	rope.quaternion = Quaternion(Vector3.UP,(top-end).normalized())
	rope.scale.y = top.distance_to(end)
