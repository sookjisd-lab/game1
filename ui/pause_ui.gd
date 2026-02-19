extends CanvasLayer
## 일시정지 시 표시되는 메뉴. ESC=계속, Q=포기.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.state_changed.connect(_on_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_Q:
			GameManager.change_state(Enums.GameState.MENU)


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	visible = (new_state == Enums.GameState.PAUSED)
