extends "res://tests/farm_visual.gd"
var phases := {}

func _process(delta: float) -> void:
	if not is_instance_valid(actor): return
	actor.sync(delta)
	actor.visible = true
	var cycle := fposmod(float(actor.body.get_meta("farm_time",0.0))/1.2,1.0)
	for key in {"lift":0.29,"impact":0.51,"pull":0.78}:
		var target: float = {"lift":0.29,"impact":0.51,"pull":0.78}[key]
		if not phases.has(key) and absf(cycle-target)<0.025:
			phases[key] = true
			var rig := actor.body.get_node("FarmRig")
			for limb in 2:
				for part in 2:
					assert(rig.get_node("Bone%d%d"%[limb,part]).scale.y<=0.305,"Hoe arms stretch")
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://tests/shots/hoe_"+key+".png")
	if phases.size()==3:
		set_process(false)
		print("HOE_MOTION_OK: lift, impact, soil pull; arm reach bounded")
		for player in Audio.get_children():
			if player is AudioStreamPlayer: player.stop()
		print("TEST_OK hoe_motion")
		get_tree().quit()
