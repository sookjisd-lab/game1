extends Node
## 게임 진입점. GameManager 상태에 따라 씬을 전환한다.


const STAGE_SCENE: PackedScene = preload("res://scenes/stage.tscn")
const TITLE_UI_SCENE: PackedScene = preload("res://ui/title_ui.tscn")
const ALTAR_UI_SCENE: PackedScene = preload("res://ui/altar_ui.tscn")
const CHARACTER_SELECT_UI_SCENE: PackedScene = preload("res://ui/character_select_ui.tscn")
const SETTINGS_UI_SCENE: PackedScene = preload("res://ui/settings_ui.tscn")

var _current_scene: Node = null
var _title_ui: CanvasLayer = null
var _altar_ui: CanvasLayer = null
var _char_select_ui: CanvasLayer = null
var _settings_ui: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.state_changed.connect(_on_game_state_changed)
	_setup_title_ui()
	_setup_altar_ui()
	_setup_char_select_ui()
	_setup_settings_ui()
	_show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _setup_title_ui() -> void:
	_title_ui = TITLE_UI_SCENE.instantiate()
	add_child(_title_ui)
	_title_ui.start_pressed.connect(_on_title_start)
	_title_ui.altar_pressed.connect(_on_altar_pressed)
	_title_ui.settings_pressed.connect(_on_settings_pressed)


func _setup_altar_ui() -> void:
	_altar_ui = ALTAR_UI_SCENE.instantiate()
	add_child(_altar_ui)
	_altar_ui.closed.connect(_on_altar_closed)


func _setup_char_select_ui() -> void:
	_char_select_ui = CHARACTER_SELECT_UI_SCENE.instantiate()
	add_child(_char_select_ui)
	_char_select_ui.character_selected.connect(_on_character_selected)
	_char_select_ui.back_pressed.connect(_on_char_select_back)


func _show_title() -> void:
	_title_ui.show_title()


func _on_title_start() -> void:
	_char_select_ui.show_select()


func _on_character_selected(data: CharacterData) -> void:
	_start_game(data)


func _on_char_select_back() -> void:
	_show_title()


func _on_altar_pressed() -> void:
	_altar_ui.show_altar()


func _on_altar_closed() -> void:
	_show_title()


func _setup_settings_ui() -> void:
	_settings_ui = SETTINGS_UI_SCENE.instantiate()
	add_child(_settings_ui)
	_settings_ui.closed.connect(_on_settings_closed)


func _on_settings_pressed() -> void:
	_settings_ui.show_settings()


func _on_settings_closed() -> void:
	_show_title()


func _start_game(data: CharacterData) -> void:
	_load_stage(data)
	GameManager.start_run()


func _load_stage(data: CharacterData) -> void:
	_clear_current_scene()
	_current_scene = STAGE_SCENE.instantiate()
	_current_scene.character_data = data
	add_child(_current_scene)


func _clear_current_scene() -> void:
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null


func _toggle_pause() -> void:
	if GameManager.current_state == Enums.GameState.PLAYING:
		GameManager.change_state(Enums.GameState.PAUSED)
	elif GameManager.current_state == Enums.GameState.PAUSED:
		GameManager.change_state(Enums.GameState.PLAYING)


func _on_game_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	match new_state:
		Enums.GameState.MENU:
			_clear_current_scene()
			call_deferred("_show_title")
