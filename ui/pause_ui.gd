extends CanvasLayer
## 일시정지 시 표시되는 오버레이.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.state_changed.connect(_on_state_changed)


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	visible = (new_state == Enums.GameState.PAUSED)
