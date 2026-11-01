extends Node3D

func _ready() -> void:
	GameState.reset()
	var village := Village.new()
	village.visible = false
	add_child(village)
	var game = preload("res://scripts/game/game.gd").new()
	game.village = village
	for x in range(9,16):
		for y in range(11,16): GameState.cleared[Vector2i(x,y)] = true
	for kind in Bal.BUILDINGS:
		var building := village.spawn_building(kind,Vector2i(12,13))
		var view := BuildingView3D.new(building)
		add_child(view)
		view.sync()
		var original_model := view.model
		for turn in 4:
			game.request_rotate(building)
			assert(building.rot==(turn+1)%4,"Placed building does not rotate 90 degrees: "+kind)
			assert(building.size==Building.footprint(kind,building.rot))
			view.sync()
			assert(view.model == original_model,"Rotation recreated model")
			assert(is_equal_approx(view._target_angle,-(turn+1)*PI*0.5),"Rotation reverses instead of continuing")
			var previous_angle: float = view._display_angle
			for frame in 22:
				await get_tree().process_frame
				assert(view._display_angle<=previous_angle+0.00001,"Turn animation moves backward")
				previous_angle = view._display_angle
			view._set_display_angle(view._target_angle)
			assert(view.model.basis.orthonormalized().is_equal_approx(Basis(Vector3.UP,-building.rot*PI*0.5)))
			assert(village.can_place(kind,building.cell,building,building.rot))
		if building.can_move(): village.begin_move(building)
		else:
			village.mode = "build"
			village.ghost_type = kind
			village.ghost_rot = 0
		var key := InputEventKey.new()
		key.keycode = KEY_R
		key.pressed = true
		village._unhandled_input(key)
		assert(village.ghost_rot==1,"Move preview skips quarter turn")
		assert(village._fit_rot(kind,1)==1)
		village.cancel_mode()
		GameState.buildings.erase(building)
		view.free()
		building.free()
	var barn := village.spawn_building("granary",Vector2i(12,13))
	# With a road below, pivot toward the free space above instead of refusing.
	for x in [12,13]: GameState.extra_roads[Vector2i(x,14)] = true
	game.request_rotate(barn)
	assert(barn.rot==1 and barn.cell.y==12,"Free corner anchor was not used")
	barn.rot = 0
	barn.set_cell(Vector2i(12,13))
	for x in [12,13]: GameState.extra_roads[Vector2i(x,12)] = true
	game.request_rotate(barn)
	assert(barn.rot==0 and barn.cell==Vector2i(12,13),"Blocked rotation mutated building")
	assert(village.mode=="move" and village.ghost_rot==1,"No rotated reposition preview")
	game.request_rotate(barn)
	assert(village.ghost_rot==2,"Rotate button cannot turn reposition preview")
	var world := WorldView3D.new()
	world.village = village
	for turn in 8:
		village.ghost_rot = turn%4
		world._sync_ghost()
		assert(world._ghost_model.basis.is_equal_approx(Basis(Vector3.UP,-turn*PI*0.5)),"Preview flips after half turn")
	world._ghost.free()
	world.free()
	village.cancel_mode()
	assert(barn.rot==0 and barn.size==Vector2i(2,1),"Cancel changed building")
	game.free()
	print("BUILDING_ROTATION_OK: all placed types, four 90-degree turns, footprints, move preview, road-aware pivot and blocked/cancel flow")
	print("TEST_OK building_rotation")
	get_tree().quit()
