extends CanvasLayer
## 런 종료 시 결과 화면. 클리어/사망 구분, 무기 목록, 발견 단서를 표시한다.


@onready var _title_label: Label = $Overlay/CenterContainer/VBox/TitleLabel
@onready var _time_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/TimeValue
@onready var _kills_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/KillsValue
@onready var _level_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/LevelValue
@onready var _xp_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/XPValue
@onready var _shards_value: Label = $Overlay/CenterContainer/VBox/StatsContainer/ShardsValue
@onready var _vbox: VBoxContainer = $Overlay/CenterContainer/VBox

var _dynamic_nodes: Array[Control] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_results(
	elapsed_time: float,
	kills: int,
	level: int,
	total_xp: int,
	is_victory: bool = false,
	weapon_names: Array[String] = [],
	discoveries: Array[String] = [],
) -> void:
	_clear_dynamic()

	_title_label.text = "클리어!" if is_victory else "밤이 끝났다..."
	_title_label.modulate = Color(1, 0.84, 0, 1) if is_victory else Color(0.9, 0.3, 0.3, 1)

	var minutes: int = int(elapsed_time) / 60
	var seconds: int = int(elapsed_time) % 60
	_time_value.text = "%02d:%02d" % [minutes, seconds]
	_kills_value.text = str(kills)
	_level_value.text = str(level)
	_xp_value.text = str(total_xp)

	var shards: int = kills + int(elapsed_time / 60.0) * 5
	if is_victory:
		shards += 50
	_shards_value.text = "+%d" % shards

	if not weapon_names.is_empty():
		_add_section("사용한 무기", weapon_names)

	if not discoveries.is_empty():
		var clue_names: Array[String] = []
		for clue_id in discoveries:
			clue_names.append(StoryManager.get_clue_name(clue_id))
		_add_section("발견한 단서", clue_names)

	visible = true


func _add_section(title: String, items: Array[String]) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 2)
	_vbox.add_child(spacer)
	_dynamic_nodes.append(spacer)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5, 1))
	_vbox.add_child(title_label)
	_dynamic_nodes.append(title_label)

	var items_label := Label.new()
	items_label.text = ", ".join(items)
	items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	items_label.custom_minimum_size = Vector2(200, 0)
	_vbox.add_child(items_label)
	_dynamic_nodes.append(items_label)


func _clear_dynamic() -> void:
	for node in _dynamic_nodes:
		node.queue_free()
	_dynamic_nodes.clear()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			visible = false
			GameManager.change_state(Enums.GameState.MENU)
