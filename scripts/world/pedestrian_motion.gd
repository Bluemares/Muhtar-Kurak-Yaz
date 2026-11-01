extends RefCounted
## Swept personal space: route following, right-hand passing and narrow-lane yielding.
const GAP := Bal.CELL*0.32

static func clear(actor: Worker, a: Vector2, b: Vector2) -> bool:
	if actor.village and not actor.village.segment_clear(a,b): return false
	if not actor.village: return true
	for other in actor.village.workers_layer.get_children():
		if not other is Worker or other==actor or other.state==Worker.State.SHELTER: continue
		var nearest := Geometry2D.get_closest_point_to_segment(other.position,a,b)
		if nearest.distance_to(other.position)<GAP:
			# Recover from overlapping old saves without pushing or teleporting anyone.
			if a.distance_to(other.position)<GAP and (a-other.position).dot(b-a)>=0.0 and b.distance_to(other.position)>a.distance_to(other.position)+0.001: continue
			return false
	return true

static func free_spot(village, at: Vector2) -> Vector2:
	for ring in 9:
		for i in (1 if ring==0 else 16):
			var p := at+Vector2.from_angle(i*TAU/16.0)*ring*GAP
			if village.point_blocked(p): continue
			var available := true
			for other in village.workers_layer.get_children():
				if other is Worker and other.state!=Worker.State.SHELTER and p.distance_to(other.position)<GAP*1.05:
					available = false
			if available: return p
	return at

static func retreat(actor: Worker, direction: Vector2) -> Array:
	for radius in [0.8,1.4,2.2,3.0]:
		for angle in [100,140,180,220,260]:
			var target: Vector2 = actor.position+direction.rotated(deg_to_rad(angle))*Bal.CELL*radius
			if actor.village.point_blocked(target) or not clear(actor,target,target): continue
			var path: Array = actor.village.find_path(actor.position,target)
			if path.is_empty() or path[-1].distance_to(target)>1.0: continue
			var previous := actor.position
			var valid := true
			for point in path:
				if not clear(actor,previous,point): valid = false
				previous = point
			if valid: return path
	return []

static func step(actor: Worker, target: Vector2, distance: float, delta: float) -> Vector2:
	if not actor.village: return actor.position.move_toward(target,distance)
	actor._pedestrian_retry = maxf(0.0,actor._pedestrian_retry-delta)
	if not actor._pedestrian_detour.is_empty():
		var point: Vector2 = actor._pedestrian_detour[0]
		var next := actor.position.move_toward(point,distance)
		if not clear(actor,actor.position,next):
			actor._pedestrian_detour.clear()
			return actor.position
		if next.distance_to(point)<0.5:
			actor._pedestrian_detour.pop_front()
			if actor._pedestrian_detour.is_empty(): actor._pedestrian_repath = true
		return next
	var direction := actor.position.direction_to(target)
	var wanted := actor.position.move_toward(target,distance)
	if actor.position.distance_to(target)<GAP and clear(actor,actor.position,wanted): return wanted
	var lookahead := actor.position+direction*maxf(distance,GAP*2.0)
	var near_other := false
	var must_yield := false
	for other in actor.village.workers_layer.get_children():
		if not other is Worker or other==actor or other.state==Worker.State.SHELTER: continue
		if Geometry2D.get_closest_point_to_segment(other.position,actor.position,lookahead).distance_to(other.position)<GAP*1.15:
			near_other = true
			if other.state!=Worker.State.WALKING or actor.get_instance_id()>other.get_instance_id(): must_yield = true
	if not near_other and clear(actor,actor.position,wanted): return wanted
	# Both pedestrians keep right relative to their own heading.
	for angle in [40,65,85,0,-40,-65,-85]:
		var heading := direction.rotated(deg_to_rad(angle))
		var probe := actor.position+heading*maxf(distance,GAP*1.4)
		var next := actor.position+heading*minf(distance,actor.position.distance_to(target))
		if clear(actor,actor.position,probe) and clear(actor,actor.position,next):
			return next
	if must_yield and actor._pedestrian_retry<=0.0:
		actor._pedestrian_retry = 0.6
		actor._pedestrian_detour = retreat(actor,direction)
	return actor.position
