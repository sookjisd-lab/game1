extends Node
## BGM 전환, SFX 재생, 볼륨 관리를 담당한다.
## Autoload 싱글톤: AudioManager


const SETTINGS_PATH := "user://settings.cfg"

var master_volume: float = 1.0
var bgm_volume: float = 1.0
var sfx_volume: float = 1.0
var indicator_enabled: bool = true
var screen_shake_enabled: bool = true
var damage_numbers_enabled: bool = true
var fullscreen_enabled: bool = false
var resolution_scale: int = 3


func _ready() -> void:
	load_settings()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	save_settings()


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	save_settings()


func set_indicator_enabled(value: bool) -> void:
	indicator_enabled = value
	save_settings()


func set_screen_shake_enabled(value: bool) -> void:
	screen_shake_enabled = value
	save_settings()


func set_damage_numbers_enabled(value: bool) -> void:
	damage_numbers_enabled = value
	save_settings()


func set_fullscreen_enabled(value: bool) -> void:
	fullscreen_enabled = value
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_resolution_scale()
	save_settings()


func set_resolution_scale(scale: int) -> void:
	resolution_scale = clampi(scale, 2, 6)
	if not fullscreen_enabled:
		_apply_resolution_scale()
	save_settings()


func _apply_resolution_scale() -> void:
	var w: int = Constants.VIEWPORT_WIDTH * resolution_scale
	var h: int = Constants.VIEWPORT_HEIGHT * resolution_scale
	DisplayServer.window_set_size(Vector2i(w, h))


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = config.get_value("audio", "master", 1.0)
	bgm_volume = config.get_value("audio", "bgm", 1.0)
	sfx_volume = config.get_value("audio", "sfx", 1.0)
	indicator_enabled = config.get_value("display", "indicator", true)
	screen_shake_enabled = config.get_value("display", "screen_shake", true)
	damage_numbers_enabled = config.get_value("display", "damage_numbers", true)
	fullscreen_enabled = config.get_value("display", "fullscreen", false)
	resolution_scale = config.get_value("display", "resolution_scale", 3)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		_apply_resolution_scale()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "bgm", bgm_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "indicator", indicator_enabled)
	config.set_value("display", "screen_shake", screen_shake_enabled)
	config.set_value("display", "damage_numbers", damage_numbers_enabled)
	config.set_value("display", "fullscreen", fullscreen_enabled)
	config.set_value("display", "resolution_scale", resolution_scale)
	config.save(SETTINGS_PATH)
