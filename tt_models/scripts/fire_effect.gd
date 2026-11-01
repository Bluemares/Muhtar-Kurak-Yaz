extends Node3D
## Reusable cosmetic fire; never changes damage, spread, or water consumption.
const Art = preload("res://tt_models/scripts/models.gd")
var tongues: Array[Node3D] = []
var smoke: Array[MeshInstance3D] = []
var embers: Array[MeshInstance3D] = []
var clock := 0.0
var roof_height := 0.5
var width := 0.7

func setup(kind: String) -> void:
	roof_height = 0.12 if kind == "field" else (2.6 if kind == "cop" else 1.5)
	width = 0.75 if kind == "field" else 0.9
	for i in 5:
		var flame := Node3D.new()
		add_child(flame)
		var outer := Art.cylinder(flame,Vector3(0,0.36,0),0.20,0.85,"#eb7130",0.01)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#ed7838")
		material.emission_enabled = true
		material.emission = Color("#b83c0d")
		outer.material_override = material
		Art.cylinder(flame,Vector3(0,0.22,0.06),0.11,0.48,"#ffe09a",0.01)
		tongues.append(flame)
	for i in 7:
		var puff := Art.ball(self,Vector3.ZERO,Vector3.ONE,"#77766c")
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.32,0.33,0.30,0.45)
		material.roughness = 1
		puff.material_override = material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		smoke.append(puff)
	for i in 8:
		var ember := Art.ball(self,Vector3.ZERO,Vector3.ONE*0.035,"#f7bd62")
		ember.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		embers.append(ember)

func update_effect(delta: float, burning: bool, ruined: bool, intensity: float) -> void:
	visible = burning or ruined
	if not visible: return
	clock += delta
	var strength := clampf(intensity,0.25,1.0)
	for i in tongues.size():
		var flame := tongues[i]
		flame.visible = burning
		flame.position = Vector3(sin(i*2.4)*width,roof_height+(i%2)*0.13,cos(i*2.4)*width*0.6)
		flame.scale = Vector3(0.8,0.75+sin(clock*8+i*2)*0.25,0.8)*strength
		flame.rotation.z = sin(clock*5+i)*0.12
	for i in smoke.size():
		var rise := fmod(clock*0.28+i/7.0,1.0)
		var puff := smoke[i]
		puff.visible = burning or i < 3
		puff.position = Vector3(sin(i*5)*0.35+rise*0.65,(roof_height if burning else 0.15)+rise*2.6,cos(i*3)*0.3)
		puff.scale = Vector3.ONE*(0.35+rise*1.15)*(strength if burning else 0.45)
		var tint := Color(0.32,0.33,0.30,(1-rise)*0.68*(strength if burning else 0.30))
		puff.material_override.albedo_color = tint
	for i in embers.size():
		var rise := fmod(clock*0.7+i/8.0,1.0)
		embers[i].visible = burning and rise < 0.8
		embers[i].position = Vector3(sin(i*4+clock)*width,roof_height+rise*1.8,cos(i*3)*width*0.6)
