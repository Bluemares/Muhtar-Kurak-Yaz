extends Node
## Ses yöneticisi. Dosyalar yoksa sessizce atlar; asset eklemek için dosyayı doğru isimle klasöre koymak yeter.
## Efektler: assets/audio/sfx/<isim>.ogg|.wav  (click, coin, harvest, fire, build, upgrade, spray, alert, ...)
## Döngüler: hose, siren, crackle (loop() ile)
## Müzik:    assets/audio/music/chill.wav (özgün ambient piyano döngüsü)

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music/chill.wav"

var _players: Array = []
var _music: AudioStreamPlayer
var _loops := {}
var _duck := 0.0
## Ses başına düzeltme (dB): sık çalanlar kısık, önemli uyarılar belirgin.
const VOLUMES := {"click": -8.0, "coin": -7.0, "harvest": -9.0, "build": -3.0, "spray": -5.0,
	"sizzle": -10.0, "saved": -3.0, "alert": -4.0, "upgrade": -3.0, "collapse": -2.0, "fire": 0.0}
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	play_music()


func _load(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var s: AudioStream = null
	for ext in [".ogg", ".wav", ".mp3"]:
		if ResourceLoader.exists(SFX_DIR + name + ext):
			s = load(SFX_DIR + name + ext)
			break
	_cache[name] = s
	return s


func play(name: String, pitch_var := 0.08) -> void:
	var s := _load(name)
	if s == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.volume_db = VOLUMES.get(name, 0.0)
			p.play()
			return


func hose(on: bool) -> void:
	loop("hose", on)


func siren(on: bool) -> void:
	loop("siren", on)


## Döngüsel ses (hose, siren, fire). Aynı isim tekrar açılırsa baştan başlamaz.
func loop(name: String, on: bool, volume_db := 0.0) -> void:
	var p: AudioStreamPlayer = _loops.get(name)
	if not on:
		if p:
			p.stop()
		return
	if p and p.playing:
		return
	var s := _load(name)
	if s == null:
		return
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_loops[name] = p
	if s is AudioStreamOggVorbis:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
	p.stream = s
	p.volume_db = volume_db
	p.play()


func loop_volume(name: String, volume_db: float) -> void:
	var p: AudioStreamPlayer = _loops.get(name)
	if p:
		p.volume_db = volume_db


func stop_loops() -> void:
	for p in _loops.values():
		p.stop()


## Sakin müziğin temposu sabit kalır; yangında ses kısılır.
func set_intensity(month: int) -> void:
	_music.pitch_scale = 1.0


func duck(on: bool) -> void:
	_duck = -9.0 if on else 0.0
	create_tween().tween_property(_music, "volume_db", -9.0 + _duck, 0.6)


func play_music() -> void:
	var path := MUSIC_PATH
	if not ResourceLoader.exists(path):
		path = MUSIC_PATH.get_basename() + ".wav"
		if not ResourceLoader.exists(path):
			return
	var s = load(path)
	if s is AudioStreamOggVorbis:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
	_music.stream = s
	_music.volume_db = -9.0
	_music.play()
