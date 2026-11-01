class_name FireTruck
extends Node2D
## İtfaiye aracı. Sinematik sırasında oyun duraklatılmışken de hareket eder.

var _t := 0.0
var siren := false
var _left := false
var _last := Vector2.ZERO
var _dust: CPUParticles2D
var village: Village
var _drive: Tween
var _route: Array = []
var _route_index := 0
var _yielders := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 5
	_dust = CPUParticles2D.new()
	_dust.amount = 30
	_dust.lifetime = 0.9
	_dust.texture = Art.soft()
	_dust.local_coords = false
	_dust.position = Vector2(0, 10)
	_dust.direction = Vector2.UP
	_dust.spread = 60
	_dust.gravity = Vector2(0, -10)
	_dust.initial_velocity_min = 10
	_dust.initial_velocity_max = 25
	_dust.scale_amount_min = 0.2
	_dust.scale_amount_max = 0.45
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.72, 0.5, 0.6))
	g.set_color(1, Color(0.85, 0.72, 0.5, 0.0))
	_dust.color_ramp = g
	_dust.z_index = -1
	_dust.emitting = false
	add_child(_dust)


## L şeklinde rota boyunca dur saniyede gider.
func drive(points: Array, dur: float) -> Tween:
	_route = points.duplicate()
	_route_index = 0
	siren = true
	Audio.siren(true)
	var total := 0.0
	var prev := position
	for p in points:
		total += prev.distance_to(p)
		prev = p
	var tw := create_tween()
	_drive = tw
	prev = position
	for p in points:
		var seg := prev.distance_to(p)
		tw.tween_property(self, "position", p, dur * (seg / maxf(total, 1.0)))
		tw.tween_callback(func(): _route_index += 1)
		prev = p
	tw.finished.connect(stop)
	return tw


func stop() -> void:
	siren = false
	Audio.siren(false)
	for actor in _yielders:
		if not is_instance_valid(actor): continue
		actor.remove_meta("traffic_yield")
		if actor is Worker:
			actor.go_to(actor._destination,actor._goal)
		elif actor is Critter and village:
			actor._path = village.find_path(actor.position,actor._target)
	_yielders.clear()
	_route.clear()


func _ahead(distance: float) -> Array:
	var points: Array = [position]
	var left := distance
	var previous := position
	for i in range(_route_index,_route.size()):
		var next: Vector2 = _route[i]
		var length := previous.distance_to(next)
		if length > left:
			points.append(previous.move_toward(next,left))
			break
		points.append(next)
		left -= length
		previous = next
	return points


func _route_distance(at: Vector2, points: Array) -> float:
	var nearest := INF
	for i in range(1,points.size()):
		nearest = minf(nearest,at.distance_to(Geometry2D.get_closest_point_to_segment(at,points[i-1],points[i])))
	return nearest


func _yield_path(actor: Node2D, corridor: Array) -> Array:
	var best: Array = []
	var shortest := INF
	for radius in [1.25,1.75,2.5]:
		for direction in 12:
			var target: Vector2 = actor.position+Vector2.from_angle(direction*TAU/12.0)*Bal.CELL*radius
			if village.point_blocked(target) or village.is_road(village.cell_of(target)) or _route_distance(target,corridor)<Bal.CELL*1.1:
				continue
			var occupied := false
			for other in _yielders:
				var path: Array = _yielders[other]
				if not path.is_empty() and path[-1].distance_to(target)<Bal.CELL*0.4:
					occupied = true
			if occupied: continue
			var path: Array = village.find_path(actor.position,target)
			if path.is_empty() or path[-1].distance_to(target)>1.0: continue
			var previous: Vector2 = actor.position
			var length := 0.0
			var valid := true
			for point in path:
				if not village.segment_clear(previous,point): valid = false
				length += previous.distance_to(point)
				previous = point
			if valid and length < shortest:
				shortest = length
				best = path
		if not best.is_empty(): break
	return best


func _clear_traffic(delta: float) -> void:
	if not siren or village == null or not is_instance_valid(_drive) or not _drive.is_valid(): return
	var warning := _ahead(Bal.CELL*5.0)
	var imminent := _ahead(Bal.CELL*1.8)
	var corridor: Array = [position]
	corridor.append_array(_route.slice(_route_index))
	var blocked := false
	for actor in village.workers_layer.get_children():
		if not (actor is Worker or actor is Critter): continue
		if actor is Worker and actor.state == Worker.State.SHELTER: continue
		if not _yielders.has(actor) and _route_distance(actor.position,warning)<Bal.CELL*0.95:
			var path := _yield_path(actor,corridor)
			if not path.is_empty():
				_yielders[actor] = path
				if actor is Worker:
					actor._pedestrian_detour.clear()
					actor._pedestrian_repath = false
				actor.set_meta("traffic_yield",true)
		if _yielders.has(actor):
			var path: Array = _yielders[actor]
			if not path.is_empty():
				var step: Vector2 = actor.position.move_toward(path[0],Bal.CELL*1.9*delta)
				if actor is Worker:
					step = preload("res://scripts/world/pedestrian_motion.gd").step(actor,path[0],Bal.CELL*1.9*delta,delta)
				if village.segment_clear(actor.position,step): actor.position = step
				if actor.position.distance_to(path[0])<0.5: path.pop_front()
		if _route_distance(actor.position,imminent)<Bal.CELL*0.95:
			blocked = true
	if blocked:
		_drive.pause()
	elif not _drive.is_running():
		_drive.play()


func _process(delta: float) -> void:
	_clear_traffic(delta)
	_t += delta
	var moved := position - _last
	if absf(moved.x) > 0.1:
		_left = moved.x < 0
	_dust.emitting = moved.length() > 0.2 and GameState.road_level < 3
	_last = position
	queue_redraw()


func _draw() -> void:
	var s := -1.0 if _left else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, 1))
	var bounce := sin(_t * 30.0) * 0.6 if siren else 0.0
	draw_texture_rect(Art.soft(), Rect2(-26, 4, 54, 16), false, Color(0, 0, 0, 0.4))
	# gövde
	draw_rect(Rect2(-24, -14 + bounce, 34, 22), Color("c1121f"))
	draw_rect(Rect2(-24, -14 + bounce, 34, 4), Color("e63946"))
	# kabin
	draw_rect(Rect2(10, -10 + bounce, 14, 18), Color("d62828"))
	draw_rect(Rect2(13, -8 + bounce, 9, 7), Color("bde0fe"))
	# merdiven
	draw_line(Vector2(-22, -17 + bounce), Vector2(8, -17 + bounce), Color(0.85, 0.85, 0.85), 2.0)
	for i in 6:
		draw_line(Vector2(-20 + i * 5, -19 + bounce), Vector2(-20 + i * 5, -15 + bounce), Color(0.85, 0.85, 0.85), 1.5)
	# şerit
	draw_rect(Rect2(-24, -1 + bounce, 48, 3), Color(1, 0.85, 0.2))
	# tekerlekler
	for x in [-15.0, 15.0]:
		draw_circle(Vector2(x, 9), 5.5, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(x, 9), 2.5, Color(0.6, 0.6, 0.6))
	draw_set_transform(Vector2.ZERO)
	if siren:
		var on := int(_t * 8.0) % 2 == 0
		var col := Color(0.3, 0.5, 1.0) if on else Color(1.0, 0.2, 0.2)
		draw_texture_rect(Art.soft(), Rect2(-18, -36, 36, 36), false, Color(col, 0.55))
		draw_circle(Vector2(0, -18 + bounce), 3.5, col)
