extends Node
const Rocks = preload("res://scripts/world/rock_geometry.gd")

func _ready() -> void:
	GameState.reset()
	var village := Village.new()
	village.visible = false
	add_child(village)
	village.set_process(false)
	village.setup_start()
	GameState.find_building("cop31").level = 3
	for w in GameState.workers: w.set_process(false)
	var road := Vector2i(16,10)
	var before: int = GameState.money
	var nav_before: String = village._nav_signature()
	village.erase_road(road)
	assert(not GameState.is_road_cell(road))
	assert(GameState.money == before+Bal.ROAD_TILE_REFUND)
	assert(village._nav_signature() != nav_before)
	village.erase_road(road)
	assert(GameState.money == before+Bal.ROAD_TILE_REFUND)
	assert(village.paint_road(road))
	assert(GameState.is_road_cell(road) and not GameState.removed_roads.has(road))
	village.erase_road(road)
	var data := {}
	for key in ["money","water","food","welfare","road_level","round_index","round_time_left","time","growth_timer","flags","stats","round_stats"]: data[key] = GameState.get(key)
	data["removed_roads"] = [[16,10]]
	GameState.apply_save(JSON.parse_string(JSON.stringify(data)))
	assert(not GameState.is_road_cell(road),"Deleted base road reappeared after loading")
	var w = GameState.workers[0]
	for other in GameState.workers.duplicate():
		if other != w:
			GameState.workers.erase(other)
			other.free()
	w.position = Vector2(17.5,14.5)*Bal.CELL
	var checked := 0
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x,y)
			if Terrain.kind(c) != "rock": continue
			var rect: Rect2 = Rocks.bounds(c)
			assert(village.point_blocked(rect.get_center()))
			var stand: Vector2 = village.clear_stand(c,w.position)
			if stand == Vector2.INF: continue
			assert(not Rocks.contains(c,stand,Bal.CELL*0.16))
			GameState.money = 10000
			assert(village.clear_preview_ok(c))
			var workers := GameState.workers.duplicate()
			GameState.workers.clear()
			assert(not village.clear_preview_ok(c))
			assert(not village.clear_cell(c))
			GameState.workers.assign(workers)
			w.start_task(c)
			assert(w.farm_target.distance_to(stand) < Bal.CELL*0.60,"Tool cannot reach rock edge")
			for frame in 6000:
				w._process(0.05)
				assert(not Rocks.contains(c,w.position,Bal.CELL*0.12),"Worker entered visible rock")
				if w.state == Worker.State.WORKING: break
			assert(w.state == Worker.State.WORKING,"Worker did not reach rock: "+str([c,w.position/Bal.CELL,stand/Bal.CELL,w._path,w.state,w._pedestrian_detour]))
			var actor := ActorView3D.new(w,"worker")
			add_child(actor)
			for frame in 100: actor.sync(1.0/60)
			actor._t = 1.0
			actor.sync(0.00001)
			var tip: Vector3 = actor.body.get_node("Pickaxe").to_global(Vector3(0,0.735,-0.364))
			var hit := Rocks.contact(c,stand)
			assert(tip.distance_to(hit)<0.012,"Pickaxe misses rock surface: "+str(tip.distance_to(hit)))
			actor.free()
			GameState.clearing[c] = Bal.CLEAR_TIME-0.01
			village._clear_tick(0.02)
			assert(GameState.cleared.has(c),"Clearing did not finish from outside rock")
			checked += 1
			if checked >= 5: break
		if checked >= 5: break
	assert(checked >= 3)
	print("ROADS_ROCKS_OK: base road refund/rebuild/save; ",checked," real rock bounds and approach paths")
	print("TEST_OK roads_rocks")
	get_tree().quit()
