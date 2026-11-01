extends Node

func _ready() -> void:
	# Seed 3 reproduces the clearing stall when the other pedestrians are frozen.
	var test_seed := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): test_seed = int(arg.trim_prefix("--seed="))
	seed(test_seed)
	print("FARM_SEED ",test_seed)
	GameState.reset()
	var village := Village.new()
	village.visible = false
	add_child(village)
	village.set_process(false)
	village.setup_start()
	for w in GameState.workers: w.set_process(false)
	var b = GameState.find_building("field")
	if "--greenhouse" in OS.get_cmdline_user_args():
		GameState.buildings.erase(b)
		b.free()
		b = village.spawn_building("greenhouse", Vector2i(17,12))
	var w = GameState.workers[0]
	w.position = Vector2(17.5,14.5) * Bal.CELL
	w.assign(b)
	var phases := {}
	var actions := {}
	var delivered := false
	var food: float = GameState.food
	for frame in 24000:
		w._process(0.05)
		b.grow(0.05)
		phases[b.farm_phase] = true
		actions[w.farm_activity] = true
		if b.farm_phase == "deliver":
			assert(GameState.food == food, "Food credited before delivery")
		if phases.has("deliver") and b.farm_phase == "prepare":
			delivered = true
			break
	assert(delivered, "Cycle stuck: " + str([b.farm_phase,w.farm_activity,w.position,w.state]))
	assert(phases.has("grow") and phases.has("harvest"))
	assert(actions.has("fetch") and actions.has("water_crop") and actions.has("basket"))
	assert(GameState.food > food, "Delivery missing")
	assert(preload("res://scripts/world/farm_cycle.gd").destination(w).type == "cop31")
	var granary = village.spawn_building("granary",Vector2i(18,9))
	assert(preload("res://scripts/world/farm_cycle.gd").destination(w) == granary)
	granary.state = "ruined"
	assert(preload("res://scripts/world/farm_cycle.gd").destination(w).type == "cop31")
	GameState.find_building("cop31").level = 3
	GameState.money = 10000
	# Restore an in-flight delivery without crediting it twice or losing its basket.
	var restored := Village.new()
	restored.visible = false
	add_child(restored)
	restored.setup_from_save({"workers":0,"buildings":[{"type":"field","cell":[17,12],"level":1,"state":"normal","pest":false,"drip":false,"protect":0.0,"harvest":0.0,"farm_phase":"deliver","pending_harvest":18.0,"farm_steps":0,"soil_water":0.3,"crop_ready":false}]})
	var saved = GameState.buildings[-1]
	assert(saved.farm_phase == "deliver" and saved.pending_harvest == 18.0 and is_equal_approx(saved.soil_water,0.3))
	GameState.buildings.erase(saved)
	restored.free()
	var found := false
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x,y)
			if village.can_clear(c) and village.clear_stand(c,w.position) != Vector2.INF:
				if village.clear_cell(c):
					found = true
					w.unassign()
					w.start_task(c)
					for frame in 4000:
						# Simulate peers too: frozen pedestrians are permanent obstacles.
						for peer in GameState.workers: peer._process(0.05)
						village._clear_tick(0.05)
						if GameState.cleared.has(c): break
					assert(GameState.cleared.has(c), "Clearing stalled")
					break
		if found: break
	assert(found, "No reachable obstacle")
	print("FARM_CYCLE_OK prepare/water/harvest/delivery/COP31 fallback/clearing")
	print("TEST_OK farm_cycle")
	get_tree().quit()
