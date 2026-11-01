class_name MenuBackdrop
extends Node
## Menü arka planı: gün batımında yaşayan Antalya köyü (gizli Village mantığı + WorldView3D),
## kamera yavaşça döner. Görüntü sağa kaydırılır, soldaki menüye yer kalır.

const EXTRA := [
	["house", Vector2i(12, 6)], ["house", Vector2i(9, 8)], ["house", Vector2i(10, 13)], ["house", Vector2i(13, 14)],
	["house", Vector2i(18, 7)], ["house", Vector2i(19, 6)], ["greenhouse", Vector2i(18, 14)], ["greenhouse", Vector2i(20, 12)],
	["field", Vector2i(7, 11)], ["field", Vector2i(20, 15)], ["grove", Vector2i(9, 6)], ["grove", Vector2i(8, 9)],
	["grove", Vector2i(13, 6)], ["water_tower", Vector2i(12, 13)], ["well", Vector2i(22, 12)],
]

var village: Village
var world: WorldView3D
var rig
var shift := -3.6  # ekranın sağına kaydırma (Camera3D.h_offset)
var spin := 2.5  # derece/sn
var mood := 0  # 1: altın saat (zafer), 0: gün batımı, -1: gece + yıkıntılar (kayıp)
var _phase := 0.645


func _ready() -> void:
	var result: Dictionary = GameState.final_result  # final ekranı sonucu/istatistikleri okumaya devam edebilsin
	var stats: Dictionary = GameState.stats
	GameState.reset()
	GameState.final_result = result
	GameState.stats = stats
	_phase = {1: 0.5, 0: 0.645, -1: 0.82}[mood]
	village = Village.new()
	village.visible = false
	village.input_locked = true
	add_child(village)
	village.setup_start()
	GameState.find_building("cop31").level = 2
	for e in EXTRA:
		if village.can_place(e[0], e[1]):
			var b := village.spawn_building(e[0], e[1])
			if b.type == "field":
				b.level = 2 + (e[1].x % 2)
				b.harvest_progress = b.harvest_time() * 0.85
	if mood < 0:
		for b in GameState.buildings:
			if b.type != "cop31" and (b.cell.x + b.cell.y) % 3 != 0:
				b.state = "ruined"
		GameState.round_index = 2
	for i in 4:
		village.spawn_worker(GameState.find_building("cop31").center() + Vector2(randf_range(-80, 80), 70)).idle()
	world = WorldView3D.new()
	world.village = village
	add_child(world)
	rig = preload("res://scripts/world3d/camera_rig_3d.gd").new()
	add_child(rig)
	rig.make_current()
	rig.cinematic = true
	rig.fit_to(Rect2(Vector2(9, 6) * Bal.CELL, Vector2(14, 10) * Bal.CELL), Rect2(Vector2.ZERO, village.world_size()))
	rig.pitch = 24.0
	rig.yaw = -40.0
	rig.zoom = Vector2.ONE * 1.25
	rig.cam.h_offset = shift
	View.camera = rig


func _process(delta: float) -> void:
	rig.yaw += spin * delta
	GameState.round_time_left = Bal.ROUND_SECONDS - (_phase - Bal.DAY_START_PHASE) * Bal.DAY_SECONDS


func _exit_tree() -> void:
	if View.camera == rig:
		View.camera = null
	# yalnızca kendi binalarını/köylülerini bırak (oyun sahnesi bizden önce kurulmuş olabilir)
	for b in village.buildings_layer.get_children():
		GameState.buildings.erase(b)
	for w in village.workers_layer.get_children():
		GameState.workers.erase(w)
