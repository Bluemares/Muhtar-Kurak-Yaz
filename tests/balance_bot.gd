extends Node
## Denge botu: oyunu hızlandırılmış oynar, refah/para/erzak eğrisini loglar.
## Çalıştır: godot --headless --path . res://tests/balance_bot.tscn -- smart|passive|greedy [seed]
## smart: önlem alır (ilaç, onarım, kuyu, yol); greedy: sadece tarla/para; passive: hiçbir şey yapmaz.

const SCALE := 10.0

var game
var policy := "smart"
var save_rate := 0.75
var _next_log := 0.0
var _next_novice_action := 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		policy = args[0]
	if args.size() > 1:
		seed(int(args[1]))
	save_rate = {"smart": 0.75, "greedy": 0.5, "passive": 0.0}.get(policy, 0.5)
	if policy == "chaos":
		save_rate = 0.5
	Engine.time_scale = SCALE
	game = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	get_tree().current_scene = game
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _find_button(n: Node, text: String) -> Button:
	if n is Button and n.text == text and n.is_visible_in_tree() and not n.disabled:
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r:
			return r
	return null


func _press(key: String) -> bool:
	var b := _find_button(get_tree().root, tr(key))
	if b:
		b.pressed.emit()
		return true
	return false


func _log(msg: String) -> void:
	var gs := GameState
	printerr("BAL %s | ay=%d t=%3.0f | refah=%3.0f para=%4d erzak=%3.0f su=%3.0f (+%.1f/-%.1f) isci=%d/%d tarla=%d ac=%s susuz=%s | %s" % [
		policy, gs.round_index, Bal.ROUND_SECONDS - gs.round_time_left, gs.welfare, gs.money, gs.food, gs.water,
		gs.water_prod, gs.water_demand, gs.workers.size(), gs.max_workers(), _alive("field"), gs.hungry, gs.thirsty, msg])


func _alive(type: String) -> int:
	return GameState.buildings.filter(func(b): return b.type == type and b.state != "ruined").size()


func _handle_interrupts() -> void:
	if not is_instance_valid(game):
		return
	if not game.policy_offer.is_empty():
		_log("politika " + str(game.policy_offer[0]))
		_press("POL_PICK")
		await _wait(0.15)
		if not is_instance_valid(game):
			return
	for k in ["BTN_SKIP_TUTORIAL", "BTN_CONTINUE", "BTN_START_MONTH", "BTN_NEXT_MONTH", "BTN_FINAL"]:
		if _press(k):
			await _wait(0.15)
	if not is_instance_valid(game):
		return
	if game.events.pending != "":
		var id: String = game.events.pending
		var pick := randi() % 2
		if policy == "smart":
			pick = 1 if id == "stubble" or (id == "festival" and GameState.money < 250) else 0
		elif policy == "greedy":
			pick = 0 if id == "stubble" else 1
		_log("karar %s -> %d" % [id, pick])
		_press("EVC_%s_%s" % [id.to_upper(), "A" if pick == 0 else "B"])
		await _wait(0.15)
		if not is_instance_valid(game):
			return
	if game.fire_active and not game._arrived:
		game.skip_cinematic()
		await _wait(0.1)
	var mg := get_tree().root.find_child("FireMinigame", true, false)
	if mg and not mg.done and not mg.panels.is_empty():
		for i in mg.panels.size():
			if randf() < save_rate:
				for f in mg.flames:
					if f.b == i:
						f.i = 0.0
		mg.time_left = 0.05
		await _wait(0.4)


func _free_cell(type: String):
	var cells: Array = []
	var connected: Array = []  # yol şartı: yola bitişik yerler öncelikli
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x, y)
			if game.village.can_place(type, c):
				cells.append(c)
				if game.village.road_adjacent(type, c):
					connected.append(c)
	if policy != "chaos" and not connected.is_empty():
		return connected[randi() % connected.size()]
	return null if cells.is_empty() else cells[randi() % cells.size()]


func _build(type: String) -> bool:
	var c = _free_cell(type)
	if c == null or not GameState.can_afford(Bal.BUILDINGS[type].cost):
		return false
	game.request_build(type)
	game.village.ghost_cell = c
	game.village._try_place()
	_log("insa " + type)
	return true


func _act() -> void:
	if get_tree().paused or not GameState.round_active:
		return
	var gs := GameState
	if policy == "chaos":
		_chaos()
		return
	if policy == "passive":
		return
	if policy == "novice":
		_novice()
		return
	for b in gs.buildings:
		if policy == "smart" and b.state == "ruined" and gs.can_afford(b.repair_cost()):
			game.request_repair(b)
			_log("onarim " + b.type)
		if policy == "smart" and b.type == "field" and b.pest and gs.can_afford(Bal.SPRAY_COST):
			game.request_spray(b)
			_log("ilac")
	if policy in ["smart", "chaos"]:
		for b in gs.buildings:
			if is_instance_valid(b) and b.crop_ready and b.state == "normal":
				game.village.tap_harvest(b)
	if policy == "smart" and gs.round_index >= 1:
		for b in gs.buildings:
			if b.type == "field" and b.state == "normal" and not b.drip and gs.money >= Bal.DRIP_COST + 90:
				game.request_drip(b)
				_log("damla")
	var well = gs.find_building("well")
	if policy == "smart" and gs.water_prod < gs.water_demand * 1.1:
		if well and well.upgrade_cost() > 0 and gs.can_afford(well.upgrade_cost()):
			game.request_upgrade(well)
			_log("kuyu sv%d" % well.level)
		elif gs.money >= 260:
			_build("well")
	if policy == "smart" and gs.round_index >= 1 and gs.count("granary") == 0 and gs.money >= 240:
		_build("granary")
	if policy == "smart" and gs.round_index >= 1:
		# çeşitlilik + kuraklıkta buğday
		var fl: Array = gs.buildings.filter(func(b): return b.type == "field" and b.state == "normal")
		var plan := ["wheat", "veg", "corn", "wheat"]
		for i in fl.size():
			var want: String = plan[i % plan.size()]
			if fl[i].crop != want and not fl[i].get_meta("bot_crop", false):
				fl[i].set_meta("bot_crop", true)
				game.request_crop(fl[i], want)
	if policy == "smart" and gs.round_index >= 1 and gs.count("water_tower") == 0 and gs.money >= 300:
		_build("water_tower")
	if policy == "smart" and gs.round_index >= 1 and gs.count("grove") < 3 and gs.money >= 200:
		_build("grove")
	if policy == "smart" and gs.round_index >= 2 and gs.count("greenhouse") == 0 and gs.money >= 400:
		_build("greenhouse")
	if _alive("field") < gs.workers.size() and gs.money >= 150 + (60 if policy == "smart" else 0):
		_build("field")
	if gs.workers.size() >= gs.max_workers() and gs.money >= 200 and gs.housing() < Bal.MAX_WORKERS_BY_COP_LEVEL[gs.find_building("cop31").level]:
		_build("house")
	if policy == "smart" and gs.road_level < Bal.ROAD_MAX_LEVEL and gs.money >= Bal.ROAD_UPGRADE_COST[gs.road_level + 1] + 120:
		game.request_road_upgrade()
		_log("yol sv%d" % gs.road_level)
	if gs.money >= 450:
		for b in gs.buildings:
			if b.type == "field" and b.state == "normal" and b.upgrade_cost() > 0 and gs.money >= b.upgrade_cost() + 150:
				game.request_upgrade(b)
				_log("tarla sv%d" % b.level)


## Rastgele eylemler: hata avı için. Her çağrıda birkaç rastgele şey yapar.
func _chaos() -> void:
	var gs := GameState
	for i in 3:
		var bs: Array = gs.buildings.filter(func(b): return is_instance_valid(b))
		if bs.is_empty():
			return
		var b = bs.pick_random()
		match randi() % 15:
			0: _build(Bal.BUILDABLE.pick_random())
			1: game.request_upgrade(b)
			2: game.request_spray(b)
			3: game.request_repair(b)
			4: game.request_drip(b)
			5: game.request_road_upgrade()
			6:
				game.request_move(b)
				if game.village.mode == "move":
					game.village.ghost_cell = Vector2i(randi() % Bal.GRID_W, randi() % Bal.GRID_H)
					game.village._try_place()
					game.village.cancel_mode()
			7: game.village.select(b)
			8: game.village.clear_selection()
			9: Settings.set_language(["tr", "en"].pick_random())
			10:
				if not game.fire_active and randf() < 0.3 and Bal.BUILDINGS[b.type].flammable and b.state == "normal":
					game.ignite(b)
			11: gs.add_money(randi() % 200)
			12:
				game.request_rotate(b)
				if randf() < 0.5:
					gs.sell_food(Bal.MARKET_LOT)
				else:
					gs.buy_food(Bal.MARKET_LOT)
			13:
				if b.type == "field":
					game.request_crop(b, Bal.CROP_ORDER.pick_random())
			14:
				game.request_clear()
				for k in 3:
					game.village.clear_cell(Vector2i(randi() % Bal.GRID_W, randi() % Bal.GRID_H))
				game.village.cancel_mode()
		if randf() < 0.3:
			var rc := Vector2i(randi() % Bal.GRID_W, randi() % Bal.GRID_H)
			if randf() < 0.8:
				game.village.paint_road(rc)
			else:
				game.village.erase_road(rc)


func _run() -> void:
	await _wait(0.6)
	while not GameState.game_over and GameState.final_result.is_empty():
		await _handle_interrupts()
		if not is_instance_valid(game) or game.get_parent() == null:
			break
		_act()
		var t := GameState.round_index * Bal.ROUND_SECONDS + Bal.ROUND_SECONDS - GameState.round_time_left
		if t >= _next_log:
			_next_log = t + 15.0
			_log("")
		await _wait(0.12)
	await _wait(0.5)
	printerr("BAL %s FINAL fires=%d %s" % [policy, GameState.stats.fires, GameState.final_result])
	print("TEST_OK balance_bot")
	get_tree().quit()


## Slower, basic reactions suggested by the help cards; no optimal build order.
func _novice() -> void:
	if GameState.time < _next_novice_action: return
	_next_novice_action = GameState.time+18.0
	for b in GameState.buildings:
		if b.crop_ready: game.village.tap_harvest(b)
		if b.state == "ruined" and GameState.can_afford(b.repair_cost()): game.request_repair(b)
	if _alive("field") < 2: _build("field")
	var well = GameState.find_building("well")
	if well and GameState.water_prod < GameState.water_demand and well.upgrade_cost()>0 and GameState.can_afford(well.upgrade_cost()):
		game.request_upgrade(well)
	if GameState.food < 12 and GameState.money > 30: GameState.buy_food(10)
	if GameState.round_index > 0:
		for b in GameState.buildings:
			if b.type == "field" and b.pest and GameState.can_afford(Bal.SPRAY_COST): game.request_spray(b)
			if b.type == "field" and not b.drip and GameState.money > 120: game.request_drip(b)
