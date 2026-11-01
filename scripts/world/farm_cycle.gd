extends RefCounted
## Simulation owns the work; presentation reads the same activity.
static func tick(w, dt: float) -> void:
	var b = w.job
	if not is_instance_valid(b) or not b.is_crop(): return
	if not b.is_operational():
		w.farm_activity = ""
		return
	# A ripe plot takes priority over an unfinished water trip (even with no water).
	if b.crop_ready and b._ready_t >= Bal.AUTO_HARVEST_DELAY and b.farm_phase != "harvest":
		b.farm_phase = "harvest"
		b.farm_steps = 0
		w.farm_activity = "harvest"
		w._farm_work_time = 0.0
		w.go_to_work()
	if w.state == Worker.State.IDLE:
		w.go_to_work()
	if w.state != Worker.State.WORKING: return
	if b.farm_phase == "deliver":
		w.farm_activity = "basket"
		var depot = destination(w)
		if depot == null:
			if not b.get_meta("delivery_blocked",false):
				GameState.notify.emit("Ürün sepette bekliyor: ambara veya COP31’e yürüyüş yolunu aç.", Color("ffb347"))
				b.set_meta("delivery_blocked",true)
			return
		b.set_meta("delivery_blocked",false)
		var point: Vector2 = access_point(w, depot)
		if w.position.distance_to(point) > 2.0:
			w.go_to(point, Worker.State.WORKING)
			return
		GameState.harvest_now(depot, b.pending_harvest)
		b.pending_harvest = 0.0
		w._farm_index = (w._farm_index + 1) % maxi(1, w._farm_count)
		b.farm_phase = "prepare"
		b.farm_steps = 0
		w.farm_activity = "farm"
		w.go_to_work()
		return
	if w.farm_activity == "fetch":
		w._carry_t += dt
		if w._carry_t >= Bal.CARRY_FILL_TIME and GameState.water >= 1.0:
			GameState.water -= 1.0
			w.farm_activity = "water_crop"
			w.go_to_work()
		return
	if w.farm_activity == "water_crop":
		w._farm_work_time += dt
		if w._farm_work_time >= 1.8:
			b.soil_water = 1.0
			w.farm_activity = "farm"
			w._farm_work_time = 0.0
		return
	if b.farm_phase == "grow":
		w.farm_activity = "farm"
		if b.crop_ready:
			if b._ready_t < Bal.AUTO_HARVEST_DELAY: return
			b.farm_phase = "harvest"
			b.farm_steps = 0
			w._farm_work_time = 0.0
		elif b.soil_water < 0.25 and not b.drip:
			var well = closest(w, "well")
			if well != null:
				w._carry_well = well
				w._carry_t = 0.0
				w.farm_activity = "fetch"
				w.go_to(access_point(w, well), Worker.State.WORKING)
		else:
			w._farm_work_time += dt
			if w._farm_work_time >= 2.4:
				w._farm_index = (w._farm_index + 1) % maxi(1,w._farm_count)
				w.go_to_work()
		return
	w.farm_activity = "farm" if b.farm_phase == "prepare" else "harvest"
	w._farm_work_time += dt
	if w._farm_work_time < (1.0 if b.farm_phase == "harvest" else 1.2): return
	b.farm_steps += 1
	if b.farm_steps >= mini(4, w._farm_count):
		b.farm_steps = 0
		if b.farm_phase == "prepare":
			w._farm_index = (w._farm_index + 1) % maxi(1, w._farm_count)
			b.farm_phase = "grow"
			w.farm_activity = ""
		else:
			b.pending_harvest = b.take_harvest(1.0)
			b.farm_phase = "deliver"
			w.farm_activity = "basket"
		return
	w._farm_index = (w._farm_index + 1) % maxi(1, w._farm_count)
	w.go_to_work()

static func closest(w, kind: String):
	var best = null
	var distance := INF
	for b in GameState.buildings:
		if b.type != kind or not b.is_operational(): continue
		var p: Vector2 = access_point(w, b)
		if p == Vector2.INF: continue
		var route: Array = w.village.find_path(w.position, p)
		if route.is_empty() or route[-1].distance_to(p) > 1.0: continue
		var d: float = w.position.distance_to(p)
		if d < distance:
			distance = d
			best = b
	return best

static func destination(w):
	var depot = closest(w, "granary")
	return depot if depot != null else closest(w, "cop31")


static func access_point(w, b) -> Vector2:
	var best := Vector2.INF
	var distance := INF
	for i in 16:
		var direction := Vector2.from_angle(i * TAU / 16)
		var p: Vector2 = b.center() + direction * (Vector2(b.size).length() * 0.5 + 0.4) * Bal.CELL
		if w.village.point_blocked(p): continue
		var occupied := false
		for other in GameState.workers:
			if other != w and is_instance_valid(other) and other.position.distance_to(p) < Bal.CELL * 0.5:
				occupied = true
		if occupied: continue
		var route: Array = w.village.find_path(w.position, p)
		if route.is_empty() or route[-1].distance_to(p) > 1.0: continue
		var d: float = w.position.distance_to(p)
		if d < distance:
			distance = d
			best = p
	return best
