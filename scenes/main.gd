extends Node
## 게임 진입점. GameManager 상태에 따라 씬을 전환한다.


const STAGE_SCENE: PackedScene = preload("res://scenes/stage.tscn")
const TITLE_UI_SCENE: PackedScene = preload("res://ui/title_ui.tscn")
const ALTAR_UI_SCENE: PackedScene = preload("res://ui/altar_ui.tscn")
const CHARACTER_SELECT_UI_SCENE: PackedScene = preload("res://ui/character_select_ui.tscn")
const SETTINGS_UI_SCENE: PackedScene = preload("res://ui/settings_ui.tscn")
const LIBRARY_UI_SCENE: PackedScene = preload("res://ui/library_ui.tscn")
const STAGE_SELECT_UI_SCENE: PackedScene = preload("res://ui/stage_select_ui.tscn")
const NPC_DIALOGUE_UI_SCENE: PackedScene = preload("res://ui/npc_dialogue_ui.tscn")

var _current_scene: Node = null
var _title_ui: CanvasLayer = null
var _altar_ui: CanvasLayer = null
var _char_select_ui: CanvasLayer = null
var _settings_ui: CanvasLayer = null
var _library_ui: CanvasLayer = null
var _stage_select_ui: CanvasLayer = null
var _npc_dialogue_ui: CanvasLayer = null
var _selected_character: CharacterData = null
var _transition_layer: CanvasLayer = null
var _transition_rect: ColorRect = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.state_changed.connect(_on_game_state_changed)
	_setup_transition_layer()
	_setup_title_ui()
	_setup_altar_ui()
	_setup_char_select_ui()
	_setup_settings_ui()
	_setup_library_ui()
	_setup_stage_select_ui()
	_setup_npc_dialogue_ui()
	_show_title()


func _setup_transition_layer() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 30
	_transition_layer.name = "TransitionLayer"
	add_child(_transition_layer)
	_transition_rect = ColorRect.new()
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.color = Color(0, 0, 0, 0)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_layer.add_child(_transition_rect)


func _fade_out(duration: float = 0.4) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.tween_property(_transition_rect, "color:a", 1.0, duration)
	await tween.finished


func _fade_in(duration: float = 0.4) -> void:
	_transition_rect.color.a = 1.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_transition_rect, "color:a", 0.0, duration)
	tween.tween_callback(func() -> void: _transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _setup_title_ui() -> void:
	_title_ui = TITLE_UI_SCENE.instantiate()
	add_child(_title_ui)
	_title_ui.start_pressed.connect(_on_title_start)
	_title_ui.altar_pressed.connect(_on_altar_pressed)
	_title_ui.settings_pressed.connect(_on_settings_pressed)
	_title_ui.library_pressed.connect(_on_library_pressed)
	_title_ui.npc_pressed.connect(_on_npc_pressed)


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
	_selected_character = data
	_stage_select_ui.show_select()


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


func _setup_library_ui() -> void:
	_library_ui = LIBRARY_UI_SCENE.instantiate()
	add_child(_library_ui)
	_library_ui.closed.connect(_on_library_closed)


func _on_library_pressed() -> void:
	_library_ui.show_library()


func _on_library_closed() -> void:
	_show_title()


func _setup_npc_dialogue_ui() -> void:
	_npc_dialogue_ui = NPC_DIALOGUE_UI_SCENE.instantiate()
	add_child(_npc_dialogue_ui)
	_npc_dialogue_ui.closed.connect(_on_npc_closed)


func _on_npc_pressed() -> void:
	_npc_dialogue_ui.show_npcs()


func _on_npc_closed() -> void:
	_show_title()


func _setup_stage_select_ui() -> void:
	_stage_select_ui = STAGE_SELECT_UI_SCENE.instantiate()
	add_child(_stage_select_ui)
	_stage_select_ui.stage_selected.connect(_on_stage_selected)
	_stage_select_ui.back_pressed.connect(_on_stage_select_back)


func _on_stage_selected(data: StageData) -> void:
	_start_game(_selected_character, data)


func _on_stage_select_back() -> void:
	_char_select_ui.show_select()


func _start_game(char_data: CharacterData, stg_data: StageData) -> void:
	await _fade_out(0.5)
	_load_stage(char_data, stg_data)
	_fade_in(0.5)


func _load_stage(char_data: CharacterData, stg_data: StageData) -> void:
	_clear_current_scene()
	_current_scene = STAGE_SCENE.instantiate()
	_current_scene.character_data = char_data
	_current_scene.stage_data = stg_data
	add_child(_current_scene)


func _clear_current_scene() -> void:
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null


func _toggle_pause() -> void:
	if _current_scene != null and _current_scene.has_method("is_countdown_active"):
		if _current_scene.is_countdown_active():
			return
	if GameManager.current_state == Enums.GameState.PLAYING:
		GameManager.change_state(Enums.GameState.PAUSED)
	elif GameManager.current_state == Enums.GameState.PAUSED:
		GameManager.change_state(Enums.GameState.PLAYING)


func _transition_to_title() -> void:
	await _fade_out(0.5)
	_clear_current_scene()
	_show_title()
	_fade_in(0.5)


func _on_game_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	match new_state:
		Enums.GameState.MENU:
			_transition_to_title()
