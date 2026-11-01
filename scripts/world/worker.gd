class_name Worker
extends Node2D
## Köylü işçi. Yol bulmayla binaların etrafından yürür, yolda hızlanır. Kıyafet rengi her işçide farklı.

enum State { IDLE, WALKING, WORKING, SHELTER }
const NO_TASK := Vector2i(-999, -999)

const COLORS := [Color("e74c3c"), Color("f1c40f"), Color("9b59b6"), Color("1abc9c"), Color("e67e22"), Color("ecf0f1")]

var visual_variant := 0
var village  # Village (yol bulma)
var state := State.IDLE
var job = null  # atandığı bina
var home_pos := Vector2.ZERO  # COP31 sığınak noktası
var _path: Array = []
var _goal := State.IDLE
var _speed_jitter := 1.0
var _wander_timer := 0.0
var _color := Color.WHITE
var _t := 0.0
var _skin := 0
var _face_left := false
var _variant := 0
var _dark_skin := false
var task_cell := NO_TASK  # arazi temizleme görevi
var carry_stage := 0  # su taşıma: 0 yok, 1 kuyuya gidiyor/dolduruyor, 2 depoya taşıyor
var _carry_well = null  # Source for the visual rope/bucket animation.
var _carry_to = null
var _carry_t := 0.0
var farm_activity := ""
var farm_target := Vector2.ZERO
var _destination := Vector2.ZERO
var _route_version := ""
var _work_cell := Vector2i(-999,-999)
var _farm_index := -1
var _farm_work_time := 0.0
var _farm_count := 0
var _pedestrian_detour: Array = []
var _pedestrian_retry := 0.0
var _pedestrian_repath := false


func _ready() -> void:
	_speed_jitter = randf_range(0.88, 1.12)
	_color = COLORS[randi() % COLORS.size()]
	_skin = randi() % Art.F_FARMERS.size()
	_variant = randi() % Art.FARMER_PALETTES.size()
	_dark_skin = randf() < 0.35
	_t = randf() * 10.0


func go_to(target: Vector2, goal: State) -> void:
	_pedestrian_detour.clear()
	_pedestrian_repath = false
	_goal = goal
	_destination = target
	if village:
		if village.point_blocked(position):
			position = village.walkable_point(position)
		_path = village.find_path(position, target)
		_route_version = village._nav_signature()
	else:
		_path = [target]
	state = State.WALKING if not _path.is_empty() else State.IDLE


## Enter the plot and work along its rows, aiming at each real plant.
func go_to_work() -> void:
	if not is_instance_valid(job):
		return
	_work_cell = job.cell
	if farm_activity == "fetch" and is_instance_valid(_carry_well):
		var source_point: Vector2 = preload("res://scripts/world/farm_cycle.gd").access_point(self, _carry_well)
		if source_point != Vector2.INF: go_to(source_point, State.WORKING)
		return
	if not job.type in ["field", "greenhouse"]:
		farm_target = job.center()
		go_to(village.walkable_point(job.center()) if village else job.center(), State.WORKING)
		return
	var best := INF
	var stand := Vector2.ZERO
	var found := false
	var candidates: Array = []
	if job.type == "field":
		for row in 4:
			for index in 4:
				var col := index if row%2==0 else 3-index
				var plant := Vector2(-0.75+col*0.5,-0.75+row*0.5)
				candidates.append([plant,plant+Vector2(0,0.38 if row%2==0 else -0.38)])
	else:
		for col in 4:
			for side in [-1,1]:
				candidates.append([Vector2(-0.6+col*0.4,side*0.18),Vector2(-0.94+col*0.4,0)])
	_farm_count = candidates.size()
	var chosen := _farm_index
	for index in candidates.size():
		if _farm_index >= 0 and index != _farm_index%_farm_count:
			continue
		var candidate: Array = candidates[index]
		var target_local: Vector2 = candidate[0]
		var stand_local: Vector2 = candidate[1]
		var point: Vector2 = job.center() + stand_local.rotated(job.rot * PI * 0.5) * Bal.CELL
		if village and village.point_blocked(point):
			continue
		var route: Array = village.find_path(position, point) if village else [point]
		if route.is_empty() or route[-1].distance_to(point) > 1.0:
			continue
		var length := 0.0
		var prev := position
		for next in route:
			length += prev.distance_to(next)
			prev = next
		if length < best:
			best = length
			stand = point
			farm_target = job.center() + target_local.rotated(job.rot * PI * 0.5) * Bal.CELL
			found = true
			chosen = index
	if found:
		_farm_index = chosen
		_farm_work_time = 0.0
		go_to(stand, State.WORKING)
	else:
		go_to(village.walkable_point(job.center()), State.IDLE)



func assign(b) -> void:
	_farm_index = -1
	carry_stage = 0
	farm_activity = ""
	job = b
	b.worker = self
	go_to_work()


func unassign() -> void:
	if job and job.worker == self:
		job.worker = null
	job = null
	farm_activity = ""
	idle()


func idle() -> void:
	var p := home_pos + Vector2(randf_range(-90, 90), randf_range(-10, 60))
	if village:
		p = village.walkable_point(p)  # bina içine dolaşma hedefi seçme
	go_to(p, State.IDLE)


func shelter() -> void:
	carry_stage = 0
	go_to(home_pos, State.SHELTER)


func start_task(c: Vector2i) -> void:
	task_cell = c
	carry_stage = 0
	farm_target = (Vector2(c) + Vector2(0.5, 0.5)) * Bal.CELL
	var stand: Vector2 = village.clear_stand(c, position)
	if stand != Vector2.INF:
		if Terrain.kind(c) == "rock":
			var hit: Vector3 = preload("res://scripts/world/rock_geometry.gd").contact(c,stand)
			farm_target = Vector2(hit.x,hit.z)*Bal.CELL

		go_to(stand, State.WORKING)


## Kuyudan depoya (su kulesi ya da COP31) bir kova su. Başlarsa true.
func start_carry(well, depot) -> bool:
	if well == null or depot == null or village == null:
		return false
	_carry_well = well
	carry_stage = 1
	_carry_t = 0.0
	_carry_to = depot
	go_to(village.walkable_point(well.center()), State.WORKING)  # kuyunun dibine kadar
	return true


func return_to_work() -> void:
	if task_cell != NO_TASK:
		start_task(task_cell)
		return
	if job and job.state != "ruined":
		go_to_work()
	else:
		unassign()


func _process(delta: float) -> void:
	_t += delta
	if get_tree().paused:
		return
	if village and state != State.SHELTER and village.point_blocked(position):
		position = village.walkable_point(position)
		if is_instance_valid(job):
			go_to_work()
	if state == State.WORKING and is_instance_valid(job) and job.cell != _work_cell:
		go_to_work()
	preload("res://scripts/world/farm_cycle.gd").tick(self, delta)
	if village and state == State.WALKING and _route_version != village._nav_signature():
		go_to(_destination, _goal)
	if _pedestrian_repath:
		go_to(_destination,_goal)
	if state == State.WALKING and not _path.is_empty():
		var speed: float = Bal.WORKER_SPEED * _speed_jitter * (village.walk_speed_mult(position) if village else 1.0)
		if _goal == State.SHELTER:
			speed *= 1.6
		var next: Vector2 = _path[0]
		if village and _path.size()>1 and position.distance_to(next)<Bal.CELL:
			for other in village.workers_layer.get_children():
				if other is Worker and other!=self and other.state!=State.SHELTER and other.position.distance_to(next)<Bal.CELL*0.32:
					if village.segment_clear(position,_path[1]):
						_path.pop_front()
						next = _path[0]
					break
		if absf(next.x - position.x) > 1.0:
			_face_left = next.x < position.x
		var step := preload("res://scripts/world/pedestrian_motion.gd").step(self,next,speed*delta,delta)
		if village and not village.segment_clear(position, step):
			go_to(_destination, _goal)
			return
		position = step
		if position.distance_to(next) < 0.5:
			_path.pop_front()
			if _path.is_empty():
				state = _goal
	elif carry_stage > 0 and state == State.WORKING:
		if carry_stage == 1:
			_carry_t += delta
			if _carry_t >= Bal.CARRY_FILL_TIME:
				carry_stage = 2
				if is_instance_valid(_carry_to):
					go_to(village.walkable_point(_carry_to.center()), State.WORKING)
				else:
					carry_stage = 0
					idle()
		else:
			carry_stage = 0
			GameState.water = minf(GameState.water_cap, GameState.water + Bal.CARRY_WATER)
			village.spawn_floating(position, "+%d" % int(Bal.CARRY_WATER), Color(0.55, 0.85, 1.0))
			idle()
	elif state == State.IDLE:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(3.0, 7.0)
			if not (village and randf() < Bal.CARRY_CHANCE and village.water_run(self)):
				idle()
	queue_redraw()


func _draw() -> void:
	if state == State.SHELTER:
		return
	var bob := 0.0
	var tilt := 0.0
	if state == State.WALKING:
		bob = absf(sin(_t * 12.0)) * 3.0
		tilt = sin(_t * 12.0) * 0.08
	elif state == State.WORKING:
		bob = absf(sin(_t * 4.0)) * 2.0
	draw_texture_rect(Art.soft(), Rect2(-10, 4, 20, 8), false, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, -bob), tilt)
	draw_texture_rect(Art.farmer(Art.F_FARMERS[_skin], _variant, _dark_skin, _face_left), Rect2(-14, -24, 28, 28), false)
	draw_set_transform(Vector2.ZERO)
	if state == State.WORKING:
		# tırpan sallama
		var a := -0.6 + absf(sin(_t * 4.0)) * 1.2
		draw_set_transform(Vector2(10, -8), a)
		Art.tile(self, Art.FARM, 88, Rect2(-6, -14, 14, 14))
		draw_set_transform(Vector2.ZERO)
	if _goal == State.SHELTER and state == State.WALKING:
		draw_circle(Vector2(0, -32 - bob), 7, Color(0.85, 0.1, 0.1))
		draw_string(ThemeDB.fallback_font, Vector2(-3, -27 - bob), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
