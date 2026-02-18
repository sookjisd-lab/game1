extends Node
## 게임 진입점. GameManager 상태에 따라 씬을 전환한다.


const STAGE_SCENE: PackedScene = preload("res://scenes/stage.tscn")

var _current_scene: Node = null


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)
	_start_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


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
