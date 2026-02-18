extends CanvasLayer
## 사망 시 결과 화면. 생존 시간, 킬 수, 레벨, XP를 표시한다.


@onready var _time_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/TimeValue
@onready var _kills_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/KillsValue
@onready var _level_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/LevelValue
@onready var _xp_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/XPValue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_results(elapsed_time: float, kills: int, level: int, total_xp: int) -> void:
	var minutes: int = int(elapsed_time) / 60
	var seconds: int = int(elapsed_time) % 60
	_time_value.text = "%02d:%02d" % [minutes, seconds]
	_kills_value.text = str(kills)
	_level_value.text = str(level)
	_xp_value.text = str(total_xp)
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			visible = false
			GameManager.change_state(Enums.GameState.MENU)
