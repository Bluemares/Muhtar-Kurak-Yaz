extends Node
## Ay içi olaylar: köylü karar kartları ve hava olayları (sıcak hava dalgası, yağmur).
## game.gd tarafından her simülasyon saniyesinde tick() ile çağrılır.

## Karar kartları: [id, ilk ay, seçenek A maliyeti metni anahtarı...] — etkiler _apply() içinde.
const DECISIONS := ["neighbor_water", "stubble", "volunteers", "water_saving", "festival", "journalist"]
## Kartı kim getiriyor
const ROLES := {"neighbor_water": "hasan", "stubble": "farmer", "volunteers": "fire", "water_saving": "teacher",
	"festival": "farmer", "journalist": "press"}
const FIRST_EVENT := [50.0, 75.0]  # ay başından ilk olaya kadar (sn)
const GAP := [70.0, 95.0]  # olaylar arası (sn)
const HEAT_WARNING := 15.0
const HEAT_SECONDS := 45.0
const RAIN_SECONDS := 30.0

var game
var pending := ""  # açık karar kartı id'si (botlar için)
var _timer := 0.0
var _heat_in := -1.0
var _used: Array = []


func start_round(resuming := false) -> void:
	if resuming:
		var saved: Dictionary = GameState.resume_context.get("events", {})
		_timer = float(saved.get("timer", randf_range(FIRST_EVENT[0], FIRST_EVENT[1])))
		_heat_in = float(saved.get("heat_in", -1.0))
		_used = saved.get("used", []).duplicate()
		pending = String(saved.get("pending", ""))
		return
	_timer = randf_range(FIRST_EVENT[0], FIRST_EVENT[1])
	_heat_in = -1.0
	GameState.heat_left = 0.0
	GameState.rain_left = 0.0


func save_state() -> Dictionary:
	return {"timer": _timer, "heat_in": _heat_in, "used": _used.duplicate(), "pending": pending}


func resume_pending() -> void:
	if pending in DECISIONS:
		_open(pending)


func tick(dt: float) -> void:
	var gs := GameState
	if _heat_in > 0.0:
		_heat_in -= dt
		if _heat_in <= 0.0:
			gs.heat_left = HEAT_SECONDS
			gs.notify.emit("EV_HEAT_START", Color("ff8a3d"))
			game.camera.shake(3.0, 0.3)
			Audio.play("alert", 0.0)
	if game.fire_active or pending != "":
		return
	_timer -= dt
	if _timer > 0.0:
		return
	_timer = randf_range(GAP[0], GAP[1])
	var r := gs.round_index
	# hava olayı: Temmuz/Ağustos'ta sıcak hava dalgası, Haziran/Temmuz'da yağmur
	if randf() < 0.4:
		if r >= 1 and (r == 2 or randf() < 0.6):
			_heat_in = HEAT_WARNING
			gs.notify.emit("EV_HEAT_WARN", Color("ffb347"))
			Audio.play("alert", 0.0)
			return
		if r <= 1:
			gs.rain_left = RAIN_SECONDS
			gs.notify.emit("EV_RAIN", Color("7fc8ff"))
			return
	var pool := DECISIONS.filter(func(d): return not d in _used)
	if pool.is_empty():
		return
	var id: String = pool.pick_random()
	_used.append(id)
	_open(id)


func _open(id: String) -> void:
	pending = id
	get_tree().paused = true
	game._modal_open = true
	var a := tr("EVC_%s_A" % id.to_upper())
	var b := tr("EVC_%s_B" % id.to_upper())
	game.hud.show_decision(tr("EV_%s_TITLE" % id.to_upper()), tr("EV_%s" % id.to_upper()), a, b, decide, ROLES.get(id, "hasan"))


## choice: 0 = A, 1 = B
func decide(choice: int) -> void:
	var id := pending
	if id.is_empty() or choice not in [0, 1]:
		return
	var lesson := lesson_key(id, choice)
	pending = ""
	game._modal_open = false
	get_tree().paused = false
	_apply(id, choice)
	game.hud.show_learning(lesson)


## Select against the pre-decision state, including failed funding.
func lesson_key(id: String, choice: int) -> String:
	var costs := {"volunteers": 60, "water_saving": 50, "festival": 80}
	if choice == 0 and costs.has(id) and GameState.money < costs[id]:
		return "LEARN_NO_FUNDS"
	if id == "journalist" and choice == 0:
		return "LEARN_JOURNALIST_GOOD" if GameState.stats.prevention >= 200 else "LEARN_JOURNALIST_LOW"
	return "LEARN_%s_%s" % [id.to_upper(), "A" if choice == 0 else "B"]


func _apply(id: String, choice: int) -> void:
	var gs := GameState
	var v = game.village
	var at: Vector2 = v.unlocked_world_rect().get_center()
	match [id, choice]:
		["neighbor_water", 0]:
			gs.water = maxf(0.0, gs.water - 30.0)
			gs.welfare = minf(100.0, gs.welfare + 6.0)
			v.spawn_floating(at, "+6 " + tr("RES_WELFARE"), Color.PINK)
		["neighbor_water", 1]:
			gs.welfare = maxf(0.0, gs.welfare - 3.0)
		["stubble", 0]:
			gs.add_money(50)
			var fields := gs.buildings.filter(func(b): return b.type == "field" and b.state == "normal")
			if not fields.is_empty() and randf() < 0.6:
				game.ignite(fields.pick_random())
		["stubble", 1]:
			gs.welfare = maxf(0.0, gs.welfare - 2.0)
			gs.flags["stubble_banned"] = true
		["volunteers", 0]:
			if gs.spend(60, "prevention"):
				gs.flags["volunteers"] = true
		["water_saving", 0]:
			if gs.spend(50, "prevention"):
				gs.flags["water_saving"] = true
		["festival", 0]:
			if gs.spend(80, "build"):
				gs.welfare = minf(100.0, gs.welfare + 10.0)
				v.spawn_floating(at, "+10 " + tr("RES_WELFARE"), Color.PINK)
		["journalist", 0]:
			if gs.stats.prevention >= 200:
				gs.add_money(120)
				gs.notify.emit("EV_JOURNALIST_GOOD", Color("8fe388"))
			else:
				gs.notify.emit("EV_JOURNALIST_BAD", Color("ffb347"))
	gs.changed.emit()
