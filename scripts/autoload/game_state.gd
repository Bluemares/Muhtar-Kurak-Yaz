extends Node
## Oyunun tek doğruluk kaynağı. Ekonomi tick'i (su, ürün, para, refah) yalnızca burada hesaplanır.

signal changed
signal notify(key: String, color: Color)
signal floating(world_pos: Vector2, text: String, color: Color)
signal worker_born
signal welfare_zero
## Hasat ödülü ekrana uçar: kind "money" | "food", amount ikon sayısını belirler.
signal fly(world_pos: Vector2, kind: String, amount: int)

var money := 0
var water := 0.0
var water_cap := 0.0
var food := 0.0
var welfare := 0.0
var welfare_target := 0.0
var road_level := 1
var round_index := 0
var round_time_left := 0.0
var round_active := false
var time := 0.0
var hungry := false
var thirsty := false
var game_over := false
var growth_timer := 0.0
var water_prod := 0.0
var removed_roads := {}
var extra_roads := {}  # oyuncunun döşediği yol hücreleri (Vector2i -> true)
var food_cap := Bal.FOOD_CAP_BASE  # ambar kapasitesi (kiler + ambarlar)
var water_coverage := 1.0  # son tik su karşılama oranı (nem haritası)
var cleared := {}  # temizlenmiş kaya/orman hücreleri (Vector2i -> true)
var clearing := {}  # sırada/kesilmekte olan hücreler (Vector2i -> ilerleme sn); bir köylü gidip kaldırır
var heat_left := 0.0  # sıcak hava dalgası kalan süre
var rain_left := 0.0  # yağmur kalan süre
var water_demand := 0.0

var buildings: Array = []
var workers: Array = []
var flags := {}

var stats := {}
var round_stats := {}
var final_result := {}
## Ana menüde "Devam et" seçilince doldurulur; game.gd yüklemeyi bundan yapar.
var pending_load := {}


func _ready() -> void:
	reset()


func reset() -> void:
	money = Bal.START_MONEY
	water = Bal.START_WATER
	water_cap = Bal.WATER_CAP_BASE
	food = Bal.START_FOOD
	welfare = Bal.START_WELFARE
	welfare_target = welfare
	road_level = 1
	round_index = 0
	round_time_left = Bal.ROUND_SECONDS
	round_active = false
	time = 0.0
	hungry = false
	thirsty = false
	game_over = false
	growth_timer = 0.0
	heat_left = 0.0
	rain_left = 0.0
	extra_roads.clear()
	removed_roads.clear()
	cleared.clear()
	clearing.clear()
	buildings.clear()
	workers.clear()
	flags.clear()
	stats = {"produced": 0.0, "eaten": 0.0, "sold": 0.0, "earned": 0, "burned": 0, "fires": 0,
		"prevention": 0, "damage": 0, "missions": 0, "side": 0, "hunger_secs": 0.0, "play_secs": 0.0,
		"water_demand_avoided": 0.0, "food_saved": 0.0}
	food_cap = Bal.FOOD_CAP_BASE
	water_coverage = 1.0
	_reset_round_stats()
	final_result = {}


func _reset_round_stats() -> void:
	round_stats = {"produced": 0.0, "eaten": 0.0, "sold": 0.0, "earned": 0, "spent": 0, "fires": 0,
		"burned": 0, "hunger_secs": 0.0, "thirst_seen": false, "water_demand_avoided": 0.0, "food_saved": 0.0}


func drought() -> float:
	return minf(1.0, Bal.DROUGHT[round_index] + (0.2 if heat_left > 0.0 else 0.0))


func temperature() -> int:
	return Bal.TEMPERATURE[round_index]


func road_speed() -> float:
	return Bal.ROAD_SPEED[road_level]


func housing() -> int:
	var cap := 0
	for b in buildings:
		if b.type == "house" and b.state != "ruined" and b.road_connected():
			cap += Bal.WORKERS_PER_HOUSE
	return cap


func max_workers() -> int:
	var cop = find_building("cop31")
	var lvl: int = cop.level if cop else 1
	return mini(Bal.MAX_WORKERS_BY_COP_LEVEL[lvl], housing())


func find_building(type: String):
	for b in buildings:
		if b.type == type:
			return b
	return null


func count(type: String) -> int:
	var n := 0
	for b in buildings:
		if b.type == type:
			n += 1
	return n


func can_afford(cost: int) -> bool:
	return money >= cost


## category: build | upgrade | prevention | repair
func spend(cost: int, category: String) -> bool:
	if money < cost:
		notify.emit("NOTE_NO_MONEY", Color.ORANGE_RED)
		return false
	money -= cost
	round_stats.spent += cost
	if category == "prevention":
		stats.prevention += cost
	changed.emit()
	return true


func flag_once(name: String) -> bool:
	if flags.get(name, false):
		return false
	flags[name] = true
	return true


func is_road_cell(c: Vector2i) -> bool:
	return not removed_roads.has(c) and (c.y in Bal.ROAD_ROWS or c.x in Bal.ROAD_COLS or extra_roads.has(c))


func has_policy(id: String) -> bool:
	return flags.get("pol_" + id, false)


func policies() -> Array:
	return Bal.POLICIES.filter(func(p): return has_policy(p))


## Saniyede bir çağrılır.
func tick(dt: float) -> void:
	if game_over:
		return
	time += dt
	heat_left = maxf(0.0, heat_left - dt)
	if rain_left > 0.0:
		rain_left = maxf(0.0, rain_left - dt)
		water += (4.0 if has_policy("rain_harvest") else 2.5) * dt
	var dm := 1.0 + drought() * Bal.DROUGHT_WATER_FACTOR

	# Su
	var prod := 0.0
	var demand := 0.0
	var avoided := 0.0
	var cap := Bal.WATER_CAP_BASE
	var fcap := Bal.FOOD_CAP_BASE
	var fields: Array = []
	for b in buildings:
		if b.type == "well" and b.is_operational():
			prod += Bal.WELL_WATER[b.level] * Bal.WELL_SEASON_MULT[clampi(round_index,0,2)] * (1.0 + b.river_bonus()) + (0.6 if has_policy("solar_pump") else 0.0)
			cap += Bal.WATER_CAP_PER_WELL_LEVEL * b.level + (40.0 if has_policy("rain_harvest") else 0.0)
		elif b.type == "water_tower" and b.is_operational():
			cap += Bal.TOWER_CAP
		elif b.type == "granary" and b.is_operational():
			fcap += Bal.GRANARY_CAP
		elif b.type == "field" and b.is_operational() and is_instance_valid(b.worker):
			var use: float = Bal.FIELD_WATER * dm * (Bal.DRIP_WATER_MULT if b.drip else 1.0) * b.crop_water()
			if b.near_grove():
				use *= Bal.GROVE_WATER_MULT
			avoided += Bal.FIELD_WATER * dm * b.crop_water() - use
			demand += use
			fields.append(b)
		elif b.type == "greenhouse" and b.is_operational() and is_instance_valid(b.worker):
			demand += Bal.GREENHOUSE_WATER * b.crop_water()
			fields.append(b)
	demand += workers.size() * Bal.WORKER_WATER * dm * (0.7 if flags.get("water_saving", false) else 1.0)
	if flags.get("water_saving", false):
		avoided += workers.size() * Bal.WORKER_WATER * dm * 0.3
	_add_stat("water_demand_avoided", avoided * dt)
	water_prod = prod
	water_demand = demand
	water_cap = cap
	food_cap = fcap
	food = minf(food, food_cap)  # ambar yıkıldıysa taşan bozulur
	var available := water + prod * dt
	var coverage := 1.0
	if available >= demand * dt:
		water = minf(available - demand * dt, cap)
	else:
		coverage = available / (demand * dt) if demand > 0.0 else 1.0
		water = 0.0
	thirsty = coverage < 0.999
	water_coverage = coverage
	if round_index >= 1 and water < cap * 0.2 and flag_once("dry_%d" % round_index):
		notify.emit("NOTE_DRY", Color("ffb347"))

	# Ürün (tarla büyür, hasat anında köylüye ve pazara gider). Kuru tarla yavaş büyür.
	for f in fields:
		var amount: float = f.grow(dt if f.crop_ready else dt * lerpf(Bal.MOIST_GROWTH_MIN, 1.0, moisture(f)))
		if amount > 0.0:
			_harvest(f, amount)

	# Köylü tüketimi
	var need := food_consumption_per_second() * dt
	_add_stat("food_saved", (workers.size() * Bal.FOOD_PER_WORKER - food_consumption_per_second()) * dt)
	var fed := 1.0
	if food >= need:
		food -= need
		_add_stat("eaten", need)
	else:
		fed = food / need if need > 0.0 else 1.0
		_add_stat("eaten", food)
		food = 0.0
	hungry = fed < 0.999
	stats.play_secs = float(stats.get("play_secs", 0.0)) + dt
	if hungry:
		round_stats.hunger_secs += dt
		stats.hunger_secs = float(stats.get("hunger_secs", 0.0)) + dt
	if thirsty:
		round_stats.thirst_seen = true

	# Refah
	var total := 0
	var intact := 0
	for b in buildings:
		total += 1
		if b.state != "ruined" and b.state != "burning":
			intact += 1
	var intact_ratio := float(intact) / maxf(total, 1)
	# kriz eksikle orantılı: %5 su açığı küçük, tam açlık büyük düşüş
	var severity := clampf((1.0 - fed) + (1.0 - coverage), 0.0, 1.0)
	var homeless := clampf(float(workers.size() - housing()) / maxf(workers.size(), 1), 0.0, 1.0)
	welfare_target = clampf((fed + coverage + intact_ratio) / 3.0 * 100.0 - severity * Bal.CRISIS_TARGET_DROP - homeless * Bal.HOMELESS_DROP
		+ Bal.DIVERSITY_BONUS[mini(crop_kinds(), Bal.DIVERSITY_BONUS.size() - 1)] - heat_stress(), 0.0, 100.0)
	var rate := Bal.WELFARE_RATE if welfare_target > welfare else Bal.WELFARE_FALL_RATE
	welfare = clampf(move_toward(welfare, welfare_target, rate * dt), 0.0, 100.0)
	_check_aid()

	# Nüfus artışı
	if welfare > Bal.WELFARE_GROWTH_THRESHOLD:
		growth_timer += dt
		if growth_timer >= Bal.GROWTH_INTERVAL:
			growth_timer = 0.0
			if workers.size() < max_workers():
				worker_born.emit()
			elif flag_once("need_house_%d" % round_index):
				notify.emit("NOTE_NEED_HOUSE", Color.SKY_BLUE)
	else:
		growth_timer = 0.0

	if welfare <= 0.0:
		game_over = true
		welfare_zero.emit()
	changed.emit()


## Kayıp ve Zarar Fonu: köy üretemez ve kendini toparlayamaz hâle gelirse tur başına bir kez acil yardım.
func _check_aid() -> void:
	if not hungry or money >= 150:
		return
	for b in buildings:
		if b.type == "field" and b.state == "normal":
			return
	if flag_once("aid_%d" % round_index):
		money += Bal.AID_MONEY
		notify.emit("NOTE_AID", Color("7fd1ff"))
		Audio.play("saved", 0.0)


func harvest_now(f, amount: float) -> void:
	_harvest(f, amount)
	changed.emit()


func _harvest(f, amount: float) -> void:
	_add_stat("produced", amount)
	Audio.play("harvest")
	f.pop()
	# ürün önce ambara; ambar doluysa fazlası o anki pazar fiyatından satılır
	var to_food := clampf(food_cap - food, 0.0, amount)
	food += to_food
	if to_food >= 1.0:
		fly.emit(f.center(), "food", clampi(int(to_food / 3.0), 1, 4))
	var sold := amount - to_food
	if sold > 0.0:
		var gain := int(round(sold * market_price()))
		money += gain
		_add_stat("sold", sold)
		stats.earned += gain
		round_stats.earned += gain
		floating.emit(f.center(), "+%d" % gain, Color.GOLD)
		fly.emit(f.center(), "money", clampi(gain / 4, 1, 6))
		Audio.play("coin")
	else:
		floating.emit(f.center(), "+%d" % int(round(amount)), Color.LIGHT_GREEN)


# ---------------- Gıda güvenliği ----------------

## Sıcak stresi (refah hedefinden düşülür): kuraklık arttıkça artar; dolu su deposu ve koruluklar hafifletir.
func heat_stress() -> float:
	var fill := clampf(water / maxf(water_cap, 1.0), 0.0, 1.0)
	var groves := 0
	for b in buildings:
		if is_instance_valid(b) and b.type == "grove" and b.is_operational():
			groves += 1
	var relief := clampf(fill * 0.6 + groves * 0.08, 0.0, 0.85)
	return drought() * Bal.HEAT_STRESS * (1.0 - relief) + (6.0 if heat_left > 0.0 else 0.0)


## Ambardaki yiyecek kaç güne yeter (1 gün = DAY_SECONDS).
func food_days() -> float:
	return food / maxf(food_consumption_per_second() * Bal.DAY_SECONDS, 0.01)


func food_consumption_per_second() -> float:
	return workers.size() * Bal.FOOD_PER_WORKER * (0.8 if has_policy("community_kitchen") else 1.0)


## Pazarın ürün başına satış fiyatı: kuraklıkla yükselir.
func market_price() -> float:
	return Bal.CROP_PRICE * (1.0 + drought() * Bal.SELL_DROUGHT) * (1.25 if has_policy("local_market") else 1.0)


func buy_price() -> float:
	return market_price() * Bal.BUY_MULT


func sell_food(n: float) -> bool:
	n = minf(n, food)
	if n < 1.0:
		return false
	var gain := int(round(n * market_price()))
	food -= n
	money += gain
	stats.earned += gain
	_add_stat("sold", n)
	Audio.play("coin")
	return true


func buy_food(n: float) -> bool:
	n = minf(n, food_cap - food)
	var cost := int(ceil(n * buy_price()))
	if n < 1.0 or money < cost:
		return false
	money -= cost
	food += n
	Audio.play("harvest")
	return true


## Yetişen farklı ürün sayısı (çalışan tarlalar + sera "sera sebzesi" olarak).
func crop_kinds() -> int:
	var kinds := {}
	for b in buildings:
		if is_instance_valid(b) and b.is_operational():
			if b.is_crop():
				kinds[b.crop] = true
	return kinds.size()


## Bu koşullarda önerilen ürün: kuraklık ve su deposuna göre.
func recommended_crop() -> String:
	var fill := water / maxf(water_cap, 1.0)
	var dr := drought()
	if dr >= 0.5 or fill < 0.3:
		return "wheat"
	if fill > 0.65 and dr < 0.3:
		return "melon"
	if fill > 0.5:
		return "corn"
	return "veg"


## Tarlanın nemi 0..1 (nem haritası): ürünün su ihtiyacı, damla sulama, koruluk, kuraklık, depo.
func moisture(b) -> float:
	if not b.is_operational():
		return 0.0
	if b.type == "greenhouse":
		return clampf(water_coverage, 0.0, 1.0)
	var need: float = b.crop_water() * (Bal.DRIP_WATER_MULT if b.drip else 1.0) * (Bal.GROVE_WATER_MULT if b.near_grove() else 1.0)
	return clampf(water_coverage * (1.25 - 0.5 * need - 0.35 * drought()), 0.0, 1.0)


func _add_stat(key: String, v: float) -> void:
	stats[key] += v
	round_stats[key] += v


func add_money(v: int) -> void:
	money += v
	changed.emit()


## Tur sonu: özet sözlüğü döner, cezaları uygular.
func end_round(mission_ok: bool) -> Dictionary:
	var summary := round_stats.duplicate()
	summary.climate_report = ClimateReport.snapshot(round_stats)
	summary.round = round_index
	summary.mission_ok = mission_ok
	summary.penalty = 0.0
	if hungry or round_stats.hunger_secs >= 15.0:
		welfare = clampf(welfare - Bal.HUNGER_ROUND_PENALTY, 0.0, 100.0)
		summary.penalty = Bal.HUNGER_ROUND_PENALTY
	if mission_ok:
		stats.missions += 1
		money += Bal.MISSION_REWARD_MONEY
		welfare = clampf(welfare + Bal.MISSION_REWARD_WELFARE, 0.0, 100.0)
	_reset_round_stats()
	changed.emit()
	if welfare <= 0.0:
		game_over = true
		welfare_zero.emit()
	return summary


# ---------------- Kayıt ----------------

## Export: exe'nin yanında, web: tarayıcı deposu, geliştirme: proje .godot/ klasörü (sistem diskine yazmamak için).
static func save_path() -> String:
	if OS.has_feature("web"):
		return "user://savegame.json"
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://.godot/savegame.json")
	return OS.get_executable_path().get_base_dir().path_join("savegame.json")


func has_save() -> bool:
	return FileAccess.file_exists(save_path())


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path())


func save_game() -> void:
	if game_over:
		return
	var bl: Array = []
	for b in buildings:
		if not is_instance_valid(b):
			continue
		var st: String = b.state
		if st == "burning" or st == "moving":
			st = "normal"  # yarım kalan yangın/inşaat yüklemede temiz başlar
		bl.append({"type": b.type, "level": b.level, "cell": [b.cell.x, b.cell.y], "state": st, "pest": b.pest,
			"drip": b.drip, "protect": maxf(0.0, b.protect_until - time), "harvest": b.harvest_progress,
			"crop": b.crop, "rot": b.rot, "farm_phase": b.farm_phase, "farm_steps": b.farm_steps, "soil_water": b.soil_water, "pending_harvest": b.pending_harvest, "crop_ready": b.crop_ready})
	var roads: Array = []
	for c in extra_roads:
		roads.append([c.x, c.y])
	var removed: Array = []
	for c in removed_roads: removed.append([c.x,c.y])
	var cl: Array = []
	for c in cleared:
		cl.append([c.x, c.y])
	var cq: Array = []
	for c in clearing:
		cq.append([c.x, c.y])
	var data := {"v": 3, "removed_roads": removed, "roads": roads, "cleared": cl, "clearing": cq, "money": money, "water": water, "food": food, "welfare": welfare, "road_level": road_level,
		"round_index": round_index, "round_time_left": round_time_left, "time": time, "growth_timer": growth_timer,
		"flags": flags, "stats": stats, "round_stats": round_stats, "workers": workers.size(), "buildings": bl}
	var f := FileAccess.open(save_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func read_save() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(save_path(), FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary and d.get("v", 0) == 3 else {}


## Kayıttan sayısal durumu geri yükler (binalar/işçiler village tarafından kurulur).
func apply_save(d: Dictionary) -> void:
	money = int(d.money)
	water = d.water
	food = d.food
	welfare = d.welfare
	welfare_target = welfare
	road_level = int(d.road_level)
	round_index = int(d.round_index)
	round_time_left = d.round_time_left
	time = d.time
	growth_timer = d.growth_timer
	flags = d.flags
	extra_roads.clear()
	removed_roads.clear()
	for r in d.get("removed_roads", []):
		removed_roads[Vector2i(int(r[0]),int(r[1]))] = true
	for r in d.get("roads", []):
		extra_roads[Vector2i(int(r[0]), int(r[1]))] = true
	cleared.clear()
	for r in d.get("cleared", []):
		cleared[Vector2i(int(r[0]), int(r[1]))] = true
	clearing.clear()
	for r in d.get("clearing", []):
		clearing[Vector2i(int(r[0]), int(r[1]))] = 0.0
	for k in d.stats:
		stats[k] = d.stats[k]
	for k in d.round_stats:
		round_stats[k] = d.round_stats[k]


# ---------------- Gündüz-gece ----------------

func round_elapsed() -> float:
	return Bal.ROUND_SECONDS - round_time_left


## 0..1 gün içi faz (0 şafak, 0.3 öğle, 0.85 gece yarısı).
func day_phase() -> float:
	return fmod(round_elapsed() / Bal.DAY_SECONDS + Bal.DAY_START_PHASE, 1.0)


func day_number() -> int:
	return int((round_elapsed() / Bal.DAY_SECONDS + Bal.DAY_START_PHASE)) + 1


## 0 gündüz, 1 gece (yumuşak geçiş).
func night_factor() -> float:
	var p := day_phase()
	if p < 0.6:
		return clampf((0.08 - p) / 0.08, 0.0, 1.0)
	if p < 0.75:
		return (p - 0.6) / 0.15
	if p < 0.93:
		return 1.0
	return 1.0 - (p - 0.93) / 0.07


func fire_risk_per_minute(b) -> float:
	if not Bal.BUILDINGS[b.type].flammable or b.state != "normal":
		return 0.0
	return 1.0 - pow(1.0 - fire_chance(b), 60.0)


## Saniyelik yangın olasılığı: kuraklıkla artar, köyün su deposu doluysa azalır (nemli toprak).
func fire_chance(b) -> float:
	if not Bal.BUILDINGS[b.type].flammable or b.state != "normal":
		return 0.0
	var wet := clampf(water / maxf(water_cap, 1.0), 0.0, 1.0)
	var grove: float = Bal.GROVE_FIRE_MULT if b.near_grove() else 1.0
	grove *= lerpf(Bal.NOON_FIRE_MULT, Bal.NIGHT_FIRE_MULT, night_factor())
	if rain_left > 0.0:
		grove *= 0.3
	if has_policy("fire_watch"):
		grove *= 0.75
	return Bal.FIRE_BASE.get(b.type, 0.0) * drought() * Bal.FIRE_DROUGHT_MULT * lerpf(Bal.FIRE_DRY_MULT, Bal.FIRE_WET_MULT, wet) * grove
