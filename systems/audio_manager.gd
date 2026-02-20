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

var _bgm_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_bgm_path: String = ""
const SFX_POOL_SIZE: int = 8


func _ready() -> void:
	_setup_audio_players()
	load_settings()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	save_settings()


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	if _bgm_player != null:
		_bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
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


func _setup_audio_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	for i in range(SFX_POOL_SIZE):
		var sfx := AudioStreamPlayer.new()
		sfx.bus = "Master"
		add_child(sfx)
		_sfx_pool.append(sfx)


func play_bgm(path: String) -> void:
	if path == _current_bgm_path and _bgm_player.playing:
		return
	_current_bgm_path = path
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()
	_current_bgm_path = ""


func play_sfx(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * master_volume)
			player.play()
			return


const REBIND_ACTIONS: Array[String] = ["move_up", "move_down", "move_left", "move_right"]
const REBIND_LABELS: Dictionary = {
	"move_up": "위로 이동",
	"move_down": "아래로 이동",
	"move_left": "왼쪽 이동",
	"move_right": "오른쪽 이동",
}
var _default_bindings: Dictionary = {}


func _save_default_bindings() -> void:
	for action: String in REBIND_ACTIONS:
		var events := InputMap.action_get_events(action)
		_default_bindings[action] = events.duplicate()


func rebind_action(action: String, new_event: InputEventKey) -> void:
	var events := InputMap.action_get_events(action)
	if not events.is_empty():
		InputMap.action_erase_event(action, events[0])
	InputMap.action_add_event(action, new_event)
	save_settings()


func reset_bindings() -> void:
	for action: String in REBIND_ACTIONS:
		InputMap.action_erase_events(action)
		for event: InputEvent in _default_bindings[action]:
			InputMap.action_add_event(action, event)
	save_settings()


func get_action_key_name(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "없음"
	var event: InputEvent = events[0]
	if event is InputEventKey:
		return event.as_text().split(" (")[0]
	return "???"


func load_settings() -> void:
	_save_default_bindings()
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
	for action: String in REBIND_ACTIONS:
		var keycode: int = config.get_value("keybinds", action, 0)
		if keycode != 0:
			var events := InputMap.action_get_events(action)
			if not events.is_empty():
				InputMap.action_erase_event(action, events[0])
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	var lang: String = config.get_value("display", "language", "ko")
	if lang == "en":
		LocaleManager.current_language = "en"


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
	config.set_value("display", "language", LocaleManager.current_language)
	for action: String in REBIND_ACTIONS:
		var events := InputMap.action_get_events(action)
		if not events.is_empty() and events[0] is InputEventKey:
			config.set_value("keybinds", action, events[0].physical_keycode)
	config.save(SETTINGS_PATH)
