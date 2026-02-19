extends Node
## 게임 진입점. GameManager 상태에 따라 씬을 전환한다.


const STAGE_SCENE: PackedScene = preload("res://scenes/stage.tscn")
const TITLE_UI_SCENE: PackedScene = preload("res://ui/title_ui.tscn")

var _current_scene: Node = null
var _title_ui: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.state_changed.connect(_on_game_state_changed)
	_setup_title_ui()
	_show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _setup_title_ui() -> void:
	_title_ui = TITLE_UI_SCENE.instantiate()
	add_child(_title_ui)
	_title_ui.start_pressed.connect(_on_title_start)


func _show_title() -> void:
	_title_ui.show_title()


func _on_title_start() -> void:
	_start_game()


func _start_game() -> void:
	_load_stage()
	GameManager.start_run()


func _load_stage() -> void:
	_clear_current_scene()
	_current_scene = STAGE_SCENE.instantiate()
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
