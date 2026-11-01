class_name Village
extends Node2D
## Köy haritası: grid, yollar, bina/işçi yönetimi, yerleştirme ve taşıma.

signal building_selected(b)
signal selection_cleared
signal building_placed(b)
signal move_finished(b)
signal hover_changed(b)
signal focus_requested(b)  # binaya çift tık: kamera ona yaklaşır

var C: int = Bal.CELL
var buildings_layer := Node2D.new()
var workers_layer := Node2D.new()
var fx_layer := Node2D.new()

var mode := "none"  # none | build | move | road | clear
var ghost_rot := 0  # yerleştirirken R ile döner
var road_erase := false  # yol modunda sol tık siler
var ghost_type := ""
var ghost_cell := Vector2i.ZERO
var moving_building = null
var selected = null
var hovered = null
var input_locked := false
var _rng := RandomNumberGenerator.new()
var overlay := Node2D.new()
var water_layer := Node2D.new()
var _dust: CPUParticles2D
var _ground_key := ""
var nav := AStarGrid2D.new()
var walk_graph := AStar2D.new()
var road_nav := AStarGrid2D.new()  # itfaiye: yalnız düz gider, yolu güçlü tercih eder
var _road_nav_key := ""
var _nav_key := ""
var _painting := false
var _cloud_t := 0.0


func _ready() -> void:
	_rng.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	buildings_layer.y_sort_enabled = true
	add_child(water_layer)
	water_layer.draw.connect(_draw_water)
	add_child(buildings_layer)
	add_child(workers_layer)
	add_child(overlay)
	add_child(fx_layer)
	overlay.draw.connect(_draw_overlay)
	# havada uçuşan sıcak toz: kuraklıkla yoğunlaşır
	var ws := world_size()
	_dust = CPUParticles2D.new()
	_dust.amount = 160
	_dust.lifetime = 8.0
	_dust.preprocess = 8.0
	_dust.texture = Art.soft()
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = ws * 0.5
	_dust.position = ws * 0.5
	_dust.direction = Vector2(1, -0.2)
	_dust.spread = 25
	_dust.gravity = Vector2.ZERO
	_dust.initial_velocity_min = 8
	_dust.initial_velocity_max = 22
	_dust.scale_amount_min = 0.04
	_dust.scale_amount_max = 0.1
	_dust.color = Color(1.0, 0.92, 0.7, 0.7)
	overlay.add_child(_dust)
	GameState.floating.connect(spawn_floating)


func world_size() -> Vector2:
	return Vector2(Bal.GRID_W, Bal.GRID_H) * C


func setup_start() -> void:
	for c in Bal.START_ROADS:
		GameState.extra_roads[c] = true
	for entry in Bal.START_LAYOUT:
		spawn_building(entry[0], entry[1])
	var cop = GameState.find_building("cop31")
	for i in Bal.START_WORKERS:
		var w := spawn_worker(cop.center() + Vector2(randf_range(-30, 30), 50))
		w.idle()
	_spawn_critters()


## Kayıttan köyü kurar.
func setup_from_save(d: Dictionary) -> void:
	for e in d.buildings:
		var b := spawn_building(e.type, Vector2i(int(e.cell[0]), int(e.cell[1])))
		b.level = int(e.level)
		b.state = e.state
		b.pest = e.pest
		b.drip = e.drip
		b.protect_until = GameState.time + float(e.protect) if float(e.protect) > 0.0 else -1.0
		b.harvest_progress = e.harvest
		b.crop = e.get("crop", "veg")
		b.farm_phase = e.get("farm_phase", "grow" if b.harvest_progress > 0 else "prepare")
		b.farm_steps = int(e.get("farm_steps", 0))
		b.soil_water = float(e.get("soil_water", 0.0))
		b.pending_harvest = float(e.get("pending_harvest", 0.0))
		b.crop_ready = e.get("crop_ready", b.harvest_progress >= b.harvest_time())
		b.rot = int(e.get("rot", 0))
	var cop = GameState.find_building("cop31")
	for i in int(d.workers):
		var w := spawn_worker(cop.center() + Vector2(randf_range(-30, 30), 50))
		w.idle()
	_spawn_critters()


func spawn_building(type: String, c: Vector2i) -> Building:
	var b := Building.new()
	b.setup(type, c)
	buildings_layer.add_child(b)
	GameState.buildings.append(b)
	return b


func spawn_worker(at: Vector2) -> Worker:
	var w := Worker.new()
	w.visual_variant = GameState.workers.size() % 6
	w.village = self
	w.position = preload("res://scripts/world/pedestrian_motion.gd").free_spot(self,walkable_point(at))
	var cop = GameState.find_building("cop31")
	w.home_pos = cop.center() + Vector2(0, cop.size.y * C * 0.5 + C * 0.5)  # binanın önü (içi değil)
	workers_layer.add_child(w)
	GameState.workers.append(w)
	return w


## Boştaki köylüye su taşıma işi: en yakın çalışan kuyudan en yakın depoya (su kulesi, yoksa COP31).
func water_run(w) -> bool:
	var well = null
	var tower = null
	var bw := INF
	var bt := INF
	for b in GameState.buildings:
		if not is_instance_valid(b) or not b.is_operational():
			continue
		var d: float = w.position.distance_to(b.center())
		if b.type == "well" and d < bw:
			bw = d
			well = b
		elif b.type == "water_tower" and d < bt:
			bt = d
			tower = b
	# su kulesine taşır; kule yoksa COP31'in sarnıcına
	return w.start_carry(well, tower if tower else GameState.find_building("cop31"))


func spawn_worker_at_house() -> void:
	var houses := GameState.buildings.filter(func(b): return b.type == "house" and b.state != "ruined")
	var at: Vector2 = houses[_rng.randi() % houses.size()].center() if not houses.is_empty() else GameState.find_building("cop31").center()
	var w := spawn_worker(at)
	w.idle()
	spawn_floating(at, tr("FLOAT_NEW_VILLAGER"), Color.SKY_BLUE)


## Boş işçileri işçi bekleyen en yakın tarlaya gönderir.
func assign_workers() -> void:
	for b in GameState.buildings:
		if not b.needs_worker() or b.state == "burning":
			continue
		var best = null
		var best_d := INF
		for w in GameState.workers:
			if w.job == null and w.task_cell == Worker.NO_TASK and w.state != Worker.State.SHELTER:
				var d: float = w.position.distance_to(b.center())
				if d < best_d:
					best_d = d
					best = w
		if best:
			best.assign(b)


# ---------------- Grid sorguları ----------------

func is_road(c: Vector2i) -> bool:
	return GameState.is_road_cell(c)


# ---------------- Yol bulma ----------------

func _nav_signature() -> String:
	var k := GameState.extra_roads.hash() * 7 + GameState.removed_roads.hash() * 17 + GameState.cleared.hash() * 131
	for b in GameState.buildings:
		if is_instance_valid(b):
			k = k * 31 + b.cell.x * 97 + b.cell.y * 13 + b.size.x * 3 + b.size.y * 7 + b.rot
	return str(k)


func _rebuild_nav() -> void:
	nav.region = Rect2i(0, 0, Bal.GRID_W, Bal.GRID_H)
	nav.cell_size = Vector2(C, C)
	nav.offset = Vector2(C, C) * 0.5
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.update()
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x, y)
			var road := is_road(c)
			var t := Terrain.kind(c)
			nav.set_point_solid(c, t != "" and not road)
			nav.set_point_weight_scale(c, 0.5 if road else 1.0)
	for b in GameState.buildings:
		if not is_instance_valid(b) or b.type in ["field", "greenhouse"]:
			continue
		var r: Rect2i = b.rect()
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				if nav.is_in_boundsv(Vector2i(x, y)):
					nav.set_point_solid(Vector2i(x, y), true)
	# Greenhouses have open ends and a central aisle, not walk-through side walls.
	walk_graph.clear()
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x,y)
			var p := (Vector2(c)+Vector2.ONE*0.5)*C
			if not nav.is_point_solid(c) and not point_blocked(p):
				walk_graph.add_point(y*Bal.GRID_W+x,p,0.5 if is_road(c) else 1.0)
	for id in walk_graph.get_point_ids():
		var c := Vector2i(id%Bal.GRID_W,id/Bal.GRID_W)
		for neighbor in [c+Vector2i.RIGHT,c+Vector2i.DOWN]:
			var other: int = neighbor.y*Bal.GRID_W+neighbor.x
			if nav.is_in_boundsv(neighbor) and walk_graph.has_point(other) and segment_clear(walk_graph.get_point_position(id),walk_graph.get_point_position(other)):
				walk_graph.connect_points(id,other)


## Dünya noktasına en yakın yürünebilir hücrenin merkezi (bina içine hedef verilmesin).
func walkable_point(p: Vector2) -> Vector2:
	if _nav_key != _nav_signature():
		_nav_key = _nav_signature()
		_rebuild_nav()
	var c := _nearest_walkable(cell_of(p))
	return (Vector2(c) + Vector2(0.5, 0.5)) * C


func _nearest_walkable(c: Vector2i) -> Vector2i:
	c = c.clamp(Vector2i.ZERO, Vector2i(Bal.GRID_W - 1, Bal.GRID_H - 1))
	if not nav.is_point_solid(c):
		return c
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				for p in [c + Vector2i(dx, dy), c + Vector2i(dy, dx)]:
					if nav.is_in_boundsv(p) and not nav.is_point_solid(p):
						return p
	return c


## Keep actors outside solid footprints, with clearance for their body and roof overhangs.
func point_blocked(p: Vector2) -> bool:
	if preload("res://scripts/world/rock_geometry.gd").blocked(p): return true
	var c := cell_of(p)
	if c.x < 0 or c.y < 0 or c.x >= Bal.GRID_W or c.y >= Bal.GRID_H:
		return true
	if Terrain.kind(c) != "" and not is_road(c):
		return true
	for building in GameState.buildings:
		if is_instance_valid(building):
			if building.type == "field":
				continue
			if building.type == "greenhouse":
				var local: Vector2 = ((p-building.center())/C).rotated(-building.rot*PI*0.5)
				if absf(local.y) < 0.13:
					continue
			var footprint := Rect2(Vector2(building.cell) * C, Vector2(building.size) * C).grow(C * 0.10)
			if footprint.has_point(p):
				return true
	return false


func segment_clear(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / (C * 0.08)))
	for i in range(1, steps + 1):
		if point_blocked(a.lerp(b, float(i) / steps)):
			return false
	return true


## End at a reachable exterior point; never append an obstructed destination or a failed-path shortcut.
func find_path(from: Vector2, to: Vector2) -> Array:
	if from.distance_to(to) <= C and not point_blocked(from) and segment_clear(from,to):
		return [to]
	var key := _nav_signature()
	if key != _nav_key:
		_nav_key = key
		_rebuild_nav()
	var a := _nearest_walkable(cell_of(from))
	var b := _nearest_walkable(cell_of(to))
	if nav.is_point_solid(a) or nav.is_point_solid(b):
		return []
	var aid := a.y*Bal.GRID_W+a.x
	var bid := b.y*Bal.GRID_W+b.x
	if not walk_graph.has_point(aid) or not walk_graph.has_point(bid):
		return []
	var out: Array = Array(walk_graph.get_point_path(aid, bid))
	if out.is_empty():
		return []
	if out.size() > 1 and a == cell_of(from) and segment_clear(from, out[1]):
		out.pop_front()
	if not point_blocked(to) and segment_clear(out[-1], to):
		out.append(to)
	return out


## Vehicle half-width. Longitudinal clearance is checked along each segment.
const TRUCK_RADIUS := 0.42

func truck_point_blocked(p: Vector2, ignore = null) -> bool:
	var c := cell_of(p)
	if c.x < 0 or c.y < 0 or c.x >= Bal.GRID_W or c.y >= Bal.GRID_H:
		return true
	if Terrain.kind(c) != "" and not is_road(c):
		return true
	for building in GameState.buildings:
		if is_instance_valid(building) and building != ignore:
			var box := Rect2(Vector2(building.cell)*C,Vector2(building.size)*C).grow(TRUCK_RADIUS*C)
			if box.has_point(p):
				return true
	return false


func truck_segment_clear(a: Vector2, b: Vector2, ignore = null) -> bool:
	var steps := maxi(1,ceili(a.distance_to(b)/(C*0.10)))
	var nose := a.direction_to(b)*C*0.40
	for i in range(steps+1):
		var center := a.lerp(b,float(i)/steps)
		for offset in [-nose,Vector2.ZERO,nose]:
			if truck_point_blocked(center+offset,ignore):
				return false
	return true


func truck_segment_cost(a: Vector2, b: Vector2) -> float:
	var length := a.distance_to(b)
	var steps := maxi(1,ceili(length/(C*0.10)))
	var cost := 0.0
	for i in steps:
		cost += length/steps*(1.0 if is_road(cell_of(a.lerp(b,(i+0.5)/steps))) else 30.0)
	return cost


## Clearance includes the entire vehicle, not just its center. Straight clear routes win.
func road_path(from: Vector2, to_b) -> Array:
	if truck_point_blocked(from):
		return []
	var box := Rect2(Vector2(to_b.cell)*C,Vector2(to_b.size)*C).grow(0.5*C)
	var targets: Array[Vector2] = []
	for i in 5:
		var fraction := float(i)/4.0
		for point in [Vector2(lerpf(box.position.x,box.end.x,fraction),box.position.y),Vector2(lerpf(box.position.x,box.end.x,fraction),box.end.y),Vector2(box.position.x,lerpf(box.position.y,box.end.y,fraction)),Vector2(box.end.x,lerpf(box.position.y,box.end.y,fraction))]:
			if not truck_point_blocked(point): targets.append(point)
	targets.sort_custom(func(a,b): return from.distance_squared_to(a)<from.distance_squared_to(b))
	var best: Array = []
	var best_length := INF
	var fallback: Array = []
	var fallback_cost := INF
	for target in targets:
		if truck_segment_clear(from,target):
			var cost := truck_segment_cost(from,target)
			if cost < fallback_cost:
				fallback = [target]
				fallback_cost = cost
			if cost <= from.distance_to(target)*1.01 and (is_equal_approx(from.x,target.x) or is_equal_approx(from.y,target.y)):
				return [target]
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0,0,Bal.GRID_W*2,Bal.GRID_H*2)
	grid.cell_size = Vector2.ONE*C*0.5
	grid.offset = Vector2.ZERO
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var id := Vector2i(x,y)
			var point := Vector2(id)*C*0.5
			grid.set_point_solid(id,truck_point_blocked(point))
			grid.set_point_weight_scale(id,1.0 if is_road(cell_of(point)) else 30.0)
	var graph := AStar2D.new()
	var width := grid.region.size.x
	for x in width:
		for y in grid.region.size.y:
			var id := Vector2i(x,y)
			if not grid.is_point_solid(id):
				graph.add_point(y*width+x,grid.get_point_position(id),grid.get_point_weight_scale(id))
	for id in graph.get_point_ids():
		var cell := Vector2i(id%width,id/width)
		for offset in [Vector2i.RIGHT,Vector2i.DOWN]:
			var neighbor: Vector2i = cell+offset
			var other: int = neighbor.y*width+neighbor.x
			if grid.is_in_boundsv(neighbor) and graph.has_point(other) and truck_segment_clear(graph.get_point_position(id),graph.get_point_position(other)):
				graph.connect_points(id,other)
	var start := Vector2i(floori(from.x/(C*0.5)),floori(from.y/(C*0.5)))
	var starts: Array[Vector2i] = []
	for x in range(start.x-2,start.x+3):
		for y in range(start.y-2,start.y+3):
			var id := Vector2i(x,y)
			if grid.is_in_boundsv(id) and not grid.is_point_solid(id) and truck_segment_clear(from,grid.get_point_position(id)):
				starts.append(id)
	starts.sort_custom(func(a,b):return from.distance_squared_to(grid.get_point_position(a))<from.distance_squared_to(grid.get_point_position(b)))
	if starts.is_empty(): return fallback
	start = starts[0]
	for target in targets:
		var end := Vector2i(floori(target.x/(C*0.5)),floori(target.y/(C*0.5)))
		if not grid.is_in_boundsv(end) or grid.is_point_solid(end): continue
		var raw: Array = Array(graph.get_point_path(start.y*width+start.x,end.y*width+end.x))
		if raw.is_empty() or not truck_segment_clear(raw[-1],target): continue
		raw.append(target)
		var smooth: Array = []
		var previous := from
		var index := 0
		while index < raw.size():
			var far := raw.size()-1
			while far > index:
				var road_cost := 0.0
				var last := previous
				for j in range(index,far+1):
					road_cost += truck_segment_cost(last,raw[j])
					last = raw[j]
				var aligned := is_equal_approx(previous.x,raw[far].x) or is_equal_approx(previous.y,raw[far].y)
				var on_road := is_road(cell_of(previous)) and is_road(cell_of(raw[far]))
				if (aligned or not on_road) and truck_segment_clear(previous,raw[far]) and truck_segment_cost(previous,raw[far]) <= road_cost*1.01:
					break
				far -= 1
			if not truck_segment_clear(previous,raw[far]):
				smooth.clear()
				break
			smooth.append(raw[far])
			previous = raw[far]
			index = far+1
		var length := 0.0
		previous = from
		for point in smooth:
			length += truck_segment_cost(previous,point)
			previous = point
		if not smooth.is_empty() and length < best_length:
			best_length = length
			best = smooth
	return best if not best.is_empty() else fallback


## Hücreye (ya da binanın çevresine) en yakın yol hücresi; yoksa yürünebilir hücre.
func _road_near(c: Vector2i, bld) -> Vector2i:
	var ring: Array = []
	var r: Rect2i = bld.rect() if bld else Rect2i(c, Vector2i.ONE)
	for d in range(1, 7):
		var g := r.grow(d)
		for x in range(g.position.x, g.end.x):
			for y in range(g.position.y, g.end.y):
				var p := Vector2i(x, y)
				if road_nav.is_in_boundsv(p) and not road_nav.is_point_solid(p) and not r.has_point(p):
					if is_road(p):
						return p
					ring.append(p)
		if not ring.is_empty() and d >= 3:
			return ring[0]
	return ring[0] if not ring.is_empty() else c


func walk_speed_mult(p: Vector2) -> float:
	return GameState.road_speed() * Bal.ONROAD_SPEED if is_road(cell_of(p)) else Bal.OFFROAD_SPEED


# ---------------- Yol döşeme ----------------

func begin_road() -> void:
	clear_selection()
	road_erase = false
	mode = "road"
	ghost_type = ""
	GameState.notify.emit("NOTE_ROAD_MODE", Color("ffe08a"))


func can_paint(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= Bal.GRID_W or c.y >= Bal.GRID_H:
		return false
	return not is_road(c) and not is_locked(c) and Terrain.kind(c) == "" and building_at(c) == null


func paint_road(c: Vector2i) -> bool:
	if not can_paint(c) or not GameState.spend(Bal.ROAD_TILE_COST, "build"):
		return false
	GameState.extra_roads[c] = true
	GameState.removed_roads.erase(c)
	queue_redraw()
	spawn_floating(Vector2(c) * C + Vector2(C * 0.3, 0), "-%d" % Bal.ROAD_TILE_COST, Color(1, 0.85, 0.5))
	Audio.play("build", 0.2)
	return true


func erase_road(c: Vector2i) -> void:
	if not is_road(c) or is_locked(c): return
	GameState.extra_roads.erase(c)
	GameState.removed_roads[c] = true
	GameState.add_money(Bal.ROAD_TILE_REFUND)
	spawn_floating((Vector2(c)+Vector2.ONE*0.5)*C,"+%d" % Bal.ROAD_TILE_REFUND,Color.GOLD)
	queue_redraw()
	Audio.play("click",0.1)



## type binası c hücresine konursa yola bitişik olur mu (yol şartı, bot ve hayalet için).
func road_adjacent(type: String, c: Vector2i) -> bool:
	var s: Vector2i = Building.footprint(type, ghost_rot if type == ghost_type and mode in ["build", "move"] else 0)
	var r := Rect2i(c, s)
	for x in range(c.x - 1, c.x + s.x + 1):
		for y in range(c.y - 1, c.y + s.y + 1):
			var p := Vector2i(x, y)
			if not r.has_point(p) and GameState.is_road_cell(p):
				return true
	return false


# ---------------- Arazi temizleme ----------------

func begin_clear() -> void:
	clear_selection()
	mode = "clear"
	ghost_type = ""
	GameState.notify.emit("NOTE_CLEAR_MODE", Color("ffe08a"))


func can_clear(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= Bal.GRID_W or c.y >= Bal.GRID_H or is_locked(c) or GameState.clearing.has(c):
		return false
	var k := Terrain.kind(c)
	return k == "rock" or k == "forest"


## No road requirement: use a reachable stance beside the obstacle.
func clear_stand(c: Vector2i, origin: Vector2) -> Vector2:
	var target := (Vector2(c) + Vector2.ONE * 0.5) * C
	var candidates: Array[Vector2] = []
	if Terrain.kind(c) == "rock":
		for spot in preload("res://scripts/world/rock_geometry.gd").spots(c): candidates.append(spot.stand)
	else:
		for i in 8: candidates.append(target+Vector2.from_angle(i*TAU/8)*C*0.65)
	candidates.sort_custom(func(a,b): return origin.distance_squared_to(a)<origin.distance_squared_to(b))
	for p in candidates:
		if point_blocked(p): continue
		var route := find_path(origin,p)
		if not route.is_empty() and route[-1].distance_to(p)<1.0: return p
	return Vector2.INF



## Shared by the placement preview and the actual command.
func clear_reachable(c: Vector2i) -> bool:
	if not can_clear(c): return false
	for w in GameState.workers:
		if is_instance_valid(w) and clear_stand(c,w.position) != Vector2.INF: return true
	return false

var _clear_preview_key := ""
var _clear_preview_until := 0
var _clear_preview_result := false

func clear_preview_ok(c: Vector2i) -> bool:
	var positions := []
	for w in GameState.workers:
		if is_instance_valid(w): positions.append(cell_of(w.position))
	var key := str([c,_nav_signature(),GameState.money,GameState.clearing.hash(),positions])
	if key != _clear_preview_key or Time.get_ticks_msec() >= _clear_preview_until:
		_clear_preview_key = key
		_clear_preview_until = Time.get_ticks_msec()+200
		_clear_preview_result = can_clear(c) and GameState.can_afford(Bal.CLEAR_COST.get(Terrain.kind(c),0)) and clear_reachable(c)
	return _clear_preview_result



func clear_cell(c: Vector2i) -> bool:
	if not can_clear(c):
		return false
	var k := Terrain.kind(c)
	if not clear_reachable(c):
		GameState.notify.emit("Köylüler buraya yürüyerek ulaşamıyor.", Color("ffb347"))
		return false
	if not GameState.spend(Bal.CLEAR_COST[k], "build"):
		return false
	GameState.clearing[c] = 0.0  # boş bir köylü gelip kaldıracak
	spawn_floating(Vector2(c) * C + Vector2(C * 0.3, 0), "-%d" % Bal.CLEAR_COST[k], Color(1, 0.85, 0.5))
	Audio.play("click", 0.1)
	if GameState.flag_once("ilk_temizlik"):
		GameState.notify.emit("NOTE_CLEAR_WORKER", Color("ffe08a"))
	return true


## Köylü hücreye vardı ve süre doldu: kaya/ağaç kalkar.
func _finish_clear(c: Vector2i, w) -> void:
	var k := Terrain.kind(c)
	GameState.clearing.erase(c)
	GameState.cleared[c] = true
	if k == "forest":
		GameState.welfare = maxf(0.0, GameState.welfare - Bal.FOREST_CLEAR_WELFARE)
		if GameState.flag_once("ilk_orman_kesimi"):
			GameState.notify.emit("NOTE_FOREST_CUT", Color("ffb347"))
	Audio.play("collapse", 0.2)
	queue_redraw()
	if w:
		w.task_cell = Worker.NO_TASK
		w.idle()


## Temizlik işleri: boştaki köylüye ata, varan köylü ilerletir.
func _clear_tick(delta: float) -> void:
	for c in GameState.clearing.keys():
		var w = null
		for x in GameState.workers:
			if is_instance_valid(x) and x.task_cell == c:
				w = x
		if w == null:
			var best_d := INF
			for x in GameState.workers:
				if is_instance_valid(x) and x.job == null and x.task_cell == Worker.NO_TASK and x.state != Worker.State.SHELTER:
					var d: float = x.position.distance_to((Vector2(c) + Vector2(0.5, 0.5)) * C)
					if d < best_d and clear_stand(c, x.position) != Vector2.INF:
						best_d = d
						w = x
			if w:
				w.start_task(c)
			continue
		if w.state == Worker.State.WORKING and w.position.distance_to(w._destination) < 2.0 and not point_blocked(w.position):
			GameState.clearing[c] += delta
			if GameState.clearing[c] >= Bal.CLEAR_TIME:
				_finish_clear(c, w)


func _clear_input(event: InputEvent) -> void:
	var c := cell_of(View.mouse_world(self))
	ghost_cell = c
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clear_cell(c)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_mode()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancel_mode()
		get_viewport().set_input_as_handled()


func cop_level() -> int:
	var cop = GameState.find_building("cop31")
	return cop.level if cop else 1


func is_locked(c: Vector2i) -> bool:
	return not Bal.UNLOCK_RECTS[clampi(cop_level(), 1, Bal.UNLOCK_RECTS.size() - 1)].has_point(c)


func unlocked_world_rect() -> Rect2:
	var r: Rect2i = Bal.UNLOCK_RECTS[clampi(cop_level(), 1, Bal.UNLOCK_RECTS.size() - 1)]
	return Rect2(Vector2(r.position) * C, Vector2(r.size) * C)


func building_at(c: Vector2i):
	for b in GameState.buildings:
		if b.rect().has_point(c):
			return b
	return null


func can_place(type: String, c: Vector2i, ignore = null, rotation := -1) -> bool:
	var r := rotation if rotation >= 0 else (ghost_rot if mode in ["build", "move"] and type == ghost_type else 0)
	var s: Vector2i = Building.footprint(type, r)
	for x in s.x:
		for y in s.y:
			var p := c + Vector2i(x, y)
			if p.x < 0 or p.y < 0 or p.x >= Bal.GRID_W or p.y >= Bal.GRID_H:
				return false
			var already_occupied: bool = ignore != null and ignore.rect().has_point(p)
			if not already_occupied and (is_road(p) or is_locked(p) or Terrain.kind(p) != ""):
				return false
			var other = building_at(p)
			if other and other != ignore:
				return false
	return true


func cell_of(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / C), floori(world_pos.y / C))


## Bina kenarları arası boşluk (hücre). Komşuluk/yangın sıçraması için.
func gap_cells(a, b) -> float:
	var ra: Rect2i = a.rect()
	var rb: Rect2i = b.rect()
	var dx := maxi(0, maxi(rb.position.x - ra.end.x, ra.position.x - rb.end.x))
	var dy := maxi(0, maxi(rb.position.y - ra.end.y, ra.position.y - rb.end.y))
	return sqrt(dx * dx + dy * dy)


func neighbors(b) -> Array:
	return GameState.buildings.filter(func(o): return o != b and gap_cells(b, o) <= Bal.FIRE_SPREAD_DIST)


# ---------------- Yerleştirme / taşıma ----------------

func begin_build(type: String) -> void:
	if not GameState.can_afford(Bal.BUILDINGS[type].cost):
		GameState.notify.emit("NOTE_NO_MONEY", Color.ORANGE_RED)
		return
	clear_selection()
	mode = "build"
	ghost_type = type
	ghost_rot = 0


## All footprints support quarter turns, including rectangular buildings.
func _fit_rot(_type: String, r: int) -> int:
	return posmod(r,4)


func rotation_cell(b, rotation: int) -> Vector2i:
	var size := Building.footprint(b.type,rotation)
	var difference: Vector2i = b.size-size
	# Try each old corner as an anchor before asking the player to reposition.
	for offset in [Vector2i.ZERO,Vector2i(difference.x,0),Vector2i(0,difference.y),difference]:
		var candidate: Vector2i = b.cell+offset
		if can_place(b.type,candidate,b,rotation): return candidate
	return Vector2i(-999,-999)


func begin_move(b) -> void:
	if not b.can_move():
		GameState.notify.emit("NOTE_CANT_MOVE", Color.ORANGE_RED)
		return
	ghost_rot = b.rot
	mode = "move"
	ghost_type = b.type
	moving_building = b


func cancel_mode() -> void:
	mode = "none"
	ghost_type = ""
	moving_building = null
	_painting = false


func _try_place() -> void:
	if mode == "build":
		if not can_place(ghost_type, ghost_cell):
			return
		if not GameState.spend(Bal.BUILDINGS[ghost_type].cost, "build"):
			cancel_mode()
			return
		var b := spawn_building(ghost_type, ghost_cell)
		b.rot = _fit_rot(b.type, ghost_rot)
		b.state = "moving"  # inşaat süresi taşıma süresiyle aynı
		b.move_timer = Bal.MOVE_DURATION
		b.drop_in()
		cancel_mode()
		Audio.play("build")
		building_placed.emit(b)
		select(b)
	elif mode == "move":
		var b = moving_building
		if not can_place(ghost_type, ghost_cell, b):
			return
		b.start_move(ghost_cell)
		b.rot = _fit_rot(b.type, ghost_rot)
		Audio.play("build")
		if b.worker:
			b.worker.go_to_work()
		cancel_mode()
		move_finished.emit(b)
		select(b)


## Hasat balonu dahil tıklama alanı: balon binanın üstünde durduğu için ayrıca kontrol edilir.
func _ready_at(p: Vector2):
	if View.is_3d():
		# 3D: balon ekran uzayında çizilir; fareye ekranda yakınlığa bak
		var mouse := get_viewport().get_mouse_position()
		for b in GameState.buildings:
			if is_instance_valid(b) and b.crop_ready and b.state == "normal":
				if mouse.distance_to(preload("res://scripts/world3d/info_overlay.gd").bubble_pos(self, b)) < 30.0 or b.rect().has_point(cell_of(p)):
					return b
		return null
	for b in GameState.buildings:
		if is_instance_valid(b) and b.crop_ready and b.state == "normal":
			var w: Vector2 = Vector2(b.size) * C
			var bubble: Vector2 = b.position + Vector2(w.x * 0.5, -30)
			if p.distance_to(bubble) < 26.0 or Rect2(b.position, w).has_point(p):
				return b
	return null


func tap_harvest(b) -> void:
	if not is_instance_valid(b) or not b.crop_ready or b.state != "normal": return
	var amount: float = b.take_harvest(Bal.TAP_HARVEST_BONUS)
	if amount <= 0: return
	b.pending_harvest = 0.0
	b.reset_crop_work()
	GameState.harvest_now(b,amount)
	spawn_floating(b.center(), "+%d erzak" % int(amount),Color("bfe8a0"))



func select(b) -> void:
	if selected and is_instance_valid(selected):
		selected.selected = false
	selected = b
	b.selected = true
	building_selected.emit(b)


func clear_selection() -> void:
	if selected and is_instance_valid(selected):
		selected.selected = false
	selected = null
	selection_cleared.emit()


func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if mode == "road":
		_road_input(event)
		return
	if mode == "clear":
		_clear_input(event)
		return
	if mode != "none" and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		ghost_rot = (ghost_rot + 1) % 4
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var c := cell_of(View.mouse_world(self))
		ghost_cell = c
		if mode != "none":
			var s: Vector2i = Building.footprint(ghost_type, ghost_rot)
			ghost_cell = c - Vector2i((s.x - 1) / 2, (s.y - 1) / 2)
		var h = building_at(c)
		if h != hovered:
			if hovered and is_instance_valid(hovered):
				hovered.hovered = false
			hovered = h
			if h:
				h.hovered = true
			hover_changed.emit(h)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if mode != "none":
				_try_place()
			else:
				var mp := View.mouse_world(self)
				var b = building_at(cell_of(mp))
				if b and event.double_click:
					focus_requested.emit(b)
				var rb = _ready_at(mp)
				if rb:
					tap_harvest(rb)
					clear_selection()
				elif b:
					select(b)
				else:
					clear_selection()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and mode != "none":
			cancel_mode()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and mode != "none":
		cancel_mode()
		get_viewport().set_input_as_handled()


func _road_input(event: InputEvent) -> void:
	var c := cell_of(View.mouse_world(self))
	ghost_cell = c
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_painting = event.pressed
			if event.pressed:
				if road_erase:
					erase_road(c)
				else:
					paint_road(c)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			erase_road(c)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _painting:
		if road_erase:
			erase_road(c)
		else:
			paint_road(c)
	elif event.is_action_pressed("ui_cancel"):
		cancel_mode()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_cloud_t += delta
	if not get_tree().paused:
		_clear_tick(delta)
	var key := "%d|%d|%d|%d" % [GameState.road_level, cop_level(), int(GameState.drought() * 10.0), GameState.extra_roads.hash()+GameState.removed_roads.hash()]
	if key != _ground_key:
		_ground_key = key
		queue_redraw()
	_dust.modulate.a = 0.25 + GameState.drought() * 0.75
	overlay.queue_redraw()
	water_layer.queue_redraw()


# ---------------- Çizim ----------------

## Hash tabanlı deterministik rastgele [0,1): zemin her yeniden çizimde aynı kalsın.
func _h(x: int, y: int, k := 0) -> float:
	var n := (x * 374761393 + y * 668265263 + k * 2147483) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float(n % 10000) / 10000.0


## Zemin aynı dokuyu kullanan katmanlar hâlinde çizilir (çizim çağrıları birleşsin, web'de hızlı olsun).
## Sadece yol seviyesi, COP31 seviyesi ya da kuraklık değişince yeniden çizilir.
func _draw() -> void:
	var ws := world_size()
	var dr := GameState.drought()
	var T := C * 0.5
	var tint := Color.WHITE.lerp(Color(0.95, 0.72, 0.4), dr)
	var trees: Array = []  # [konum, x, y, renk]
	var rocks: Array = []  # [idx, rect]
	var decor: Array = []
	for x in range(-5, Bal.GRID_W + 5):
		for y in range(-5, Bal.GRID_H + 5):
			var c := Vector2i(x, y)
			var inside := x >= 0 and y >= 0 and x < Bal.GRID_W and y < Bal.GRID_H
			var base := Vector2(c) * C
			if not inside:
				var n := sin(x * 0.45) + sin(y * 0.37 + 1.3) + sin((x + y) * 0.21 + 0.7)
				if n > -0.9:
					for k in 2:
						if _h(x, y, k) < 0.85:
							trees.append([base + Vector2(_h(x, y, k + 5), _h(x, y, k + 9)) * T * 1.1 - Vector2(4, 8), x * 3 + k, y + k, Color(0.78, 0.84, 0.78), 1.0 + _h(x, y, k + 30) * 0.6])
				else:
					for k in 2:
						var dk := _h(x, y, k + 40)
						if dk < 0.5:
							decor.append([[39, 83, 77, 29][int(_h(x, y, k + 50) * 4)], Rect2(base + Vector2(_h(x, y, k + 60), _h(x, y, k + 70)) * T, Vector2(T, T) * 0.9)])
				continue
			match Terrain.kind(c):
				"forest":
					for k in 3:
						trees.append([base + Vector2(_h(x, y, k + 5), _h(x, y, k + 9)) * T * 0.9, x * 3 + k, y, Color.WHITE, 1.0 + _h(x, y, k + 30) * 0.4])
				"rock":
					for k in 2:
						rocks.append([Art.F_ROCK if _h(x, y, k + 3) < 0.6 else 77, Rect2(base + Vector2(_h(x, y, k + 13), _h(x, y, k + 17)) * T * 0.8, Vector2(T, T) * 1.1)])
				"":
					if not is_road(c) and _h(x, y, 21) < 0.08:
						decor.append([[39, 83, 77, 89, 17][int(_h(x, y, 2) * 5)], Rect2(base + Vector2(_h(x, y, 22), _h(x, y, 23)) * T, Vector2(T, T) * 0.75)])
	# 1) köy dışı zemin
	draw_rect(Rect2(Vector2(-C * 6, -C * 6), ws + Vector2(C * 12, C * 12)), Color(0.24, 0.36, 0.2).lerp(Color(0.42, 0.38, 0.2), dr))
	# 2) çimen (town)
	# temel çimen tek komutla döşenir (dış halka koyu); çeşitler sadece köy içinde, seyrek
	var outer_tint := tint * Color(0.72, 0.8, 0.7)
	draw_texture_rect(Art.grass(), Rect2(Vector2(-40, -40) * T, (Vector2(Bal.GRID_W, Bal.GRID_H) * 2 + Vector2(80, 80)) * T), true, outer_tint)
	draw_texture_rect(Art.grass(), Rect2(Vector2.ZERO, ws), true, tint)
	for x in Bal.GRID_W * 2:
		for y in Bal.GRID_H * 2:
			var hv := _h(x, y, 3)
			if hv <= 0.7:
				continue
			var idx: int = Art.T_GRASS[1]
			if hv > 0.975 - (0.0 if dr < 0.6 else 0.1):
				idx = Art.T_GRASS[2] if dr < 0.6 else Art.T_GRASS[1]
			Art.tile(self, Art.TOWN, idx, Rect2(Vector2(x, y) * T, Vector2(T, T)), tint)
	# 3) dokusuz: nehir yatağı (kuraklıkta çatlak toprak görünür), asfalt
	var roads: Array = []
	for x in Bal.GRID_W:
		for y in Bal.GRID_H:
			var c := Vector2i(x, y)
			var r := Rect2(Vector2(c) * C, Vector2(C, C))
			if is_road(c):
				roads.append([r, c])
				if GameState.road_level >= 3:
					draw_rect(r, Color(0.24, 0.24, 0.27))
			elif Terrain.is_river(c):
				draw_rect(r, Color(0.55, 0.42, 0.28).lerp(Color(0.7, 0.55, 0.35), dr))
				for k in 3:
					var p := r.position + Vector2(_h(x, y, 30 + k), _h(x, y, 40 + k)) * (C - 16) + Vector2(8, 8)
					draw_line(p, p + Vector2(10, 6).rotated(_h(x, y, 50 + k) * TAU), Color(0.35, 0.25, 0.15, 0.4 + dr * 0.4), 1.5)
	# 4) yol tile'ları (town)
	if GameState.road_level < 3:
		for rd in roads:
			var r: Rect2 = rd[0]
			var c: Vector2i = rd[1]
			for i in 4:
				var o := Vector2(i % 2, i / 2) * T
				var idx: int = Art.T_COBBLE
				if GameState.road_level == 1:
					idx = Art.T_DIRT[int(_h(c.x * 2 + i % 2, c.y * 2 + i / 2, 4) * Art.T_DIRT.size())]
				Art.tile(self, Art.TOWN, idx, Rect2(r.position + o, Vector2(T, T)), Color.WHITE if GameState.road_level == 1 else Color(0.78, 0.74, 0.68))
	# 5) yol detayları (dokusuz): çukur, parke derzi ya da şerit
	for rd in roads:
		var r: Rect2 = rd[0]
		var c: Vector2i = rd[1]
		if GameState.road_level == 1:
			for i in 2:
				var p := r.position + Vector2(_h(c.x, c.y, 20 + i), _h(c.x, c.y, 30 + i)) * (C - 20) + Vector2(10, 10)
				draw_circle(p, 4.0 + _h(c.x, c.y, 40 + i) * 3.0, Color(0.36, 0.25, 0.15, 0.85))
		elif GameState.road_level == 2:
			for k in 4:
				var off := (k % 2) * T * 0.5
				draw_line(r.position + Vector2(0, k * T * 0.5), r.position + Vector2(C, k * T * 0.5), Color(0.35, 0.3, 0.25, 0.35), 1.5)
				for j in 2:
					var x := off + j * T + T * 0.25
					draw_line(r.position + Vector2(x, k * T * 0.5), r.position + Vector2(x, (k + 1) * T * 0.5), Color(0.35, 0.3, 0.25, 0.35), 1.5)
		else:
			if c.y in Bal.ROAD_ROWS:
				draw_line(r.position + Vector2(10, C * 0.5), r.position + Vector2(C - 10, C * 0.5), Color(1, 0.95, 0.6), 3.0)
			else:
				draw_line(r.position + Vector2(C * 0.5, 10), r.position + Vector2(C * 0.5, C - 10), Color(1, 0.95, 0.6), 3.0)
	# 6) gölgeler (soft), 7) ağaçlar (town), 8) kaya + süs (farm)
	for t in trees:
		if t[3] != Color.WHITE:
			continue  # dış ormanda tek tek gölge yok (performans)
		var sc: float = t[4] if t.size() > 4 else 1.0
		draw_texture_rect(Art.soft(), Rect2(t[0] + Vector2(4, T * 0.75 * sc), Vector2(T * sc, T * 0.4 * sc)), false, Color(0, 0, 0, 0.3))
	for rk in rocks:
		var rr: Rect2 = rk[1]
		draw_texture_rect(Art.soft(), Rect2(rr.position + Vector2(2, rr.size.y * 0.6), Vector2(rr.size.x, rr.size.y * 0.4)), false, Color(0, 0, 0, 0.3))
	for t in trees:
		_tree(t[0], t[1], t[2], t[3], t[4] if t.size() > 4 else 1.0)
	for rk in rocks:
		Art.tile(self, Art.FARM, rk[0], rk[1], tint)
	for d in decor:
		Art.tile(self, Art.FARM, d[0], d[1], tint)
	# 9) kilitli alan sisi (açık alanın dışı) + sınır
	var open := unlocked_world_rect()
	var fog := Color(0.03, 0.05, 0.02, 0.5)
	draw_rect(Rect2(0, 0, ws.x, open.position.y), fog)
	draw_rect(Rect2(0, open.end.y, ws.x, ws.y - open.end.y), fog)
	draw_rect(Rect2(0, open.position.y, open.position.x, open.size.y), fog)
	draw_rect(Rect2(open.end.x, open.position.y, ws.x - open.end.x, open.size.y), fog)
	draw_rect(open, Color(0.98, 0.92, 0.7, 0.6), false, 2.0)


## Nehir: her karede çizilir (dalga animasyonu). Kuraklıkta su daralır, yatak görünür.
func _draw_water() -> void:
	var dr := GameState.drought()
	var shrink := dr * 0.42 * C
	for y in Bal.GRID_H:
		var x0 := Terrain.river_x(y)
		var r := Rect2(Vector2(x0, y) * C + Vector2(shrink, 0), Vector2(C * 2 - shrink * 2, C))
		var fogged := is_locked(Vector2i(x0, y))
		var wc := Color(0.22, 0.5, 0.82).lerp(Color(0.35, 0.5, 0.55), dr)
		water_layer.draw_rect(r, wc.darkened(0.45) if fogged else wc)
		for k in 3:
			var wy := r.position.y + 10 + k * 20 + sin(_cloud_t * 2.0 + y + k) * 3.0
			var wx := r.position.x + fmod(_cloud_t * 18.0 + k * 23.0 + y * 11.0, maxf(r.size.x - 16, 1.0))
			water_layer.draw_line(Vector2(wx, wy), Vector2(wx + 12, wy), Color(0.75, 0.9, 1.0, 0.6), 2.0)
		if y in Bal.ROAD_ROWS:
			# köprü
			var br := Rect2(Vector2(x0 - 0.15, y + 0.1) * C, Vector2(2.3, 0.8) * C)
			water_layer.draw_rect(br, Color(0.55, 0.36, 0.2))
			for i in 9:
				var px := br.position.x + i * br.size.x / 9.0
				water_layer.draw_line(Vector2(px, br.position.y), Vector2(px, br.end.y), Color(0.38, 0.24, 0.12), 2.0)
			water_layer.draw_line(br.position, Vector2(br.end.x, br.position.y), Color(0.3, 0.18, 0.1), 3.0)
			water_layer.draw_line(Vector2(br.position.x, br.end.y), br.end, Color(0.3, 0.18, 0.1), 3.0)


func _tree(p: Vector2, x: int, y: int, mod: Color, sc := 1.0) -> void:
	var T := C * 0.5
	var dry := _h(x, y, 11) < GameState.drought() * 0.8
	var pool: Array = Art.T_TREES_DRY if dry else Art.T_TREES_GREEN
	var idx: int = pool[int(_h(x, y, 12) * pool.size())]
	Art.tile(self, Art.TOWN, idx, Rect2(p - Vector2(0, T * (sc - 1.0)), Vector2(T, T) * 1.15 * sc), mod)


## Üst katman: yerleştirme hayaleti + kayan bulut gölgeleri.
func _draw_overlay() -> void:
	var ws := world_size()
	var cloud_a := 0.16 * (1.0 - GameState.drought() * 0.8)
	for i in 3:
		var span := ws.x + 700.0
		var x := fmod(_cloud_t * (14.0 + i * 5.0) + i * 420.0, span) - 350.0
		var y := ws.y * (0.2 + i * 0.3)
		overlay.draw_texture_rect(Art.soft(), Rect2(Vector2(x, y) - Vector2(220, 120), Vector2(440, 240)), false, Color(0, 0, 0.05, cloud_a))
	if mode == "road":
		var ok := can_paint(ghost_cell) and GameState.can_afford(Bal.ROAD_TILE_COST)
		var col := Color(0.3, 1.0, 0.4, 0.45) if ok else (Color(1, 0.85, 0.3, 0.35) if GameState.extra_roads.has(ghost_cell) else Color(1.0, 0.2, 0.2, 0.4))
		var gr := Rect2(Vector2(ghost_cell) * C, Vector2(C, C))
		overlay.draw_rect(gr, col)
		overlay.draw_rect(gr, Color(col, 0.95), false, 3.0)
	elif mode != "none":
		var s: Vector2i = Building.footprint(ghost_type, ghost_rot)
		var ok := can_place(ghost_type, ghost_cell, moving_building)
		var col := Color(0.3, 1.0, 0.4, 0.4) if ok else Color(1.0, 0.2, 0.2, 0.4)
		var gr := Rect2(Vector2(ghost_cell) * C, Vector2(s) * C)
		overlay.draw_rect(gr, col)
		overlay.draw_rect(gr, Color(col, 0.95), false, 3.0)
		if ghost_type == "well" and ok and Terrain.river_distance(ghost_cell) <= Bal.RIVER_WELL_DIST:
			var pct := int(round(Bal.RIVER_WELL_BONUS * (1.0 - GameState.drought()) * 100.0))
			overlay.draw_string(ThemeDB.fallback_font, gr.position + Vector2(-8, -8), tr("GHOST_RIVER") % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.9, 1.0))


func _spawn_critters() -> void:
	var area := unlocked_world_rect().grow(-C)
	for i in Art.F_CRITTERS.size():
		var c := Critter.new()
		c.village = self
		c.kind = Art.F_CRITTERS[i]
		c.area = area
		c.position = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		workers_layer.add_child(c)


# ---------------- Uçan yazılar ----------------

func spawn_floating(world_pos: Vector2, text: String, color: Color) -> void:
	if View.is_3d():
		var w3 = get_tree().get_first_node_in_group("world3d")
		if w3:
			w3.float_text(world_pos, text, color)
			return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.position = world_pos + Vector2(-20, -30)
	fx_layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2)
	tw.tween_callback(l.queue_free)
