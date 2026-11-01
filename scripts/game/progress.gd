class_name Progress
extends RefCounted
## Puan, yıldız, en iyi skor ve başarımlar. Profil kayıttan ayrı tutulur (oyun bitince silinmez).

const ACHIEVEMENTS := ["no_burn", "all_missions", "all_side", "model_village", "prevention_hero",
	"full_valley", "green_village", "no_stubble", "drip_all"]


static func profile_path() -> String:
	return GameState.save_path().get_base_dir().path_join("profile.json")


static func load_profile() -> Dictionary:
	var d := {"best_score": 0, "best_stars": 0, "achievements": []}
	if FileAccess.file_exists(profile_path()):
		var f := FileAccess.open(profile_path(), FileAccess.READ)
		if f:
			var j = JSON.parse_string(f.get_as_text())
			if j is Dictionary:
				for k in d:
					if j.has(k):
						d[k] = j[k]
	return d


static func save_profile(d: Dictionary) -> void:
	var f := FileAccess.open(profile_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


static func score(r: Dictionary) -> int:
	var s := float(r.welfare) * 10.0 + float(r.produced) + int(r.missions) * 300 + int(r.get("side", 0)) * 100
	s += maxf(0.0, float(r.prevention) - float(r.damage)) * 0.5 - int(r.burned) * 50
	if r.lost:
		s *= 0.3
	return maxi(0, int(round(s)))


static func stars(r: Dictionary) -> int:
	if not r.won:
		return 0
	if not r.good:
		return 1
	# 3 yıldız: üç görev + köylüler zamanın en az %90'ında tok + az yangın kaybı
	if int(r.missions) >= 3 and int(r.get("fed_pct", 100)) >= 90 and int(r.burned) <= 2:
		return 3
	return 2 if int(r.missions) >= 2 else 1


## Oyun sonunda kazanılan başarımlar (sahne silinmeden önce, binalar hâlâ erişilebilirken çağrılır).
static func earned(r: Dictionary) -> Array:
	var gs := GameState
	var out: Array = []
	var side_total := 0
	for ms in Bal.SIDE_MISSIONS:
		side_total += ms.size()
	var alive := gs.buildings.filter(func(b): return is_instance_valid(b))
	var fields := alive.filter(func(b): return b.type == "field" and b.state != "ruined")
	var cops := alive.filter(func(b): return b.type == "cop31")
	var cop = cops[0] if not cops.is_empty() else null
	if not r.lost and int(r.burned) == 0:
		out.append("no_burn")
	if int(r.missions) >= 3:
		out.append("all_missions")
	if int(r.get("side", 0)) >= side_total:
		out.append("all_side")
	if r.good:
		out.append("model_village")
	if float(r.prevention) >= 500 and float(r.prevention) >= float(r.damage) * 3.0:
		out.append("prevention_hero")
	if cop and cop.level >= 3:
		out.append("full_valley")
	if alive.filter(func(b): return b.type == "grove").size() >= 3 and alive.any(func(b): return b.type == "greenhouse"):
		out.append("green_village")
	if gs.flags.get("stubble_banned", false):
		out.append("no_stubble")
	if fields.size() >= 3 and fields.all(func(b): return b.drip):
		out.append("drip_all")
	return out


## Sonucu profile işler; final_result'a score/stars/new_best/new_ach ekler.
static func finalize(r: Dictionary) -> void:
	var p := load_profile()
	r.score = score(r)
	r.stars = stars(r)
	r.new_best = r.score > int(p.best_score)
	var new_ach: Array = []
	for a in earned(r):
		if not a in p.achievements:
			p.achievements.append(a)
			new_ach.append(a)
	r.new_ach = new_ach
	r.best_score = maxi(int(p.best_score), r.score)
	p.best_score = r.best_score
	p.best_stars = maxi(int(p.best_stars), r.stars)
	save_profile(p)
