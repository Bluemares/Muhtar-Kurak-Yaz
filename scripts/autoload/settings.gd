extends Node
## Dil, ses ve ekran ayarlarını yükler, kaydeder ve uygular.

signal language_changed

## Export edilmiş oyunda ayarlar exe'nin yanına yazılır (taşınabilir), web'de tarayıcı deposuna,
## geliştirmede proje klasöründeki .godot/ içine (sistem diskine yazmamak için).
var PATH: String = _settings_path()


static func _settings_path() -> String:
	if OS.has_feature("web"):
		return "user://settings.cfg"
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://.godot/user_settings.cfg")
	return OS.get_executable_path().get_base_dir().path_join("settings.cfg")
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const LANGUAGES := ["tr", "en"]

var language := "tr"
var music_on := true
var music_volume := 0.7
var sfx_on := true
var sfx_volume := 0.8
var fullscreen := false
var resolution_index := 0
var first_launch := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	load_settings()
	apply_all()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	first_launch = false
	language = cfg.get_value("general", "language", language)
	music_on = cfg.get_value("audio", "music_on", music_on)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_on = cfg.get_value("audio", "sfx_on", sfx_on)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	resolution_index = clampi(cfg.get_value("display", "resolution_index", resolution_index), 0, RESOLUTIONS.size() - 1)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "language", language)
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_on", sfx_on)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "resolution_index", resolution_index)
	cfg.save(PATH)
	first_launch = false


func apply_all() -> void:
	apply_language()
	apply_audio()
	apply_display()


func set_language(lang: String) -> void:
	language = lang
	apply_language()
	save_settings()


func apply_language() -> void:
	TranslationServer.set_locale(language)
	language_changed.emit()


func apply_audio() -> void:
	_set_bus("Music", music_on, music_volume)
	_set_bus("SFX", sfx_on, sfx_volume)


func _set_bus(bus_name: String, on: bool, vol: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, not on or vol <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(vol, 0.001)))


func apply_display() -> void:
	if not Startup.display_ready:
		return
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var res: Vector2i = RESOLUTIONS[resolution_index]
	DisplayServer.window_set_size(res)
	var screen := DisplayServer.window_get_current_screen()
	var origin := DisplayServer.screen_get_position(screen)
	var ssize := DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_position(origin + (ssize - res) / 2)
