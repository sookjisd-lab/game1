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
	_apply_theme()


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

	_title_label.text = LocaleManager.tr_text("victory") if is_victory else LocaleManager.tr_text("defeat")
	_title_label.add_theme_color_override("font_color", UITheme.GOLD if is_victory else UITheme.BLOOD_LIGHT)
	_title_label.modulate = Color.WHITE

	_time_value.text = GameManager.format_time(elapsed_time)
	_kills_value.text = str(kills)
	_level_value.text = str(level)
	_xp_value.text = str(total_xp)

	var shards: int = GameManager.calculate_shards(kills, SpawnManager.elite_kills, SpawnManager.boss_kills, elapsed_time)
	_shards_value.text = "+%d" % shards

	if not weapon_names.is_empty():
		_add_section(LocaleManager.tr_text("weapons_used"), weapon_names)

	if not discoveries.is_empty():
		var clue_names: Array[String] = []
		for clue_id in discoveries:
			clue_names.append(StoryManager.get_clue_name(clue_id))
		_add_section(LocaleManager.tr_text("clues_found"), clue_names)

	visible = true


func _apply_theme() -> void:
	var overlay: ColorRect = $Overlay
	overlay.color = Color(0.03, 0.01, 0.05, 0.85)

	_title_label.add_theme_font_size_override("font_size", UITheme.HEADING_FONT_SIZE)

	# 스탯 라벨 색상
	var stats: GridContainer = $Overlay/CenterContainer/VBox/StatsContainer
	for i in range(stats.get_child_count()):
		var child: Label = stats.get_child(i) as Label
		if child == null:
			continue
		if child.name.ends_with("Value"):
			child.add_theme_color_override("font_color", UITheme.TEXT_BRIGHT)
		else:
			child.add_theme_color_override("font_color", UITheme.TEXT_NORMAL)

	# 기억 조각은 금색 유지
	var shards_label: Label = $Overlay/CenterContainer/VBox/StatsContainer/ShardsLabel
	shards_label.add_theme_color_override("font_color", UITheme.GOLD_DIM)
	shards_label.modulate = Color.WHITE
	_shards_value.add_theme_color_override("font_color", UITheme.GOLD)
	_shards_value.modulate = Color.WHITE

	var hint_label: Label = $Overlay/CenterContainer/VBox/HintLabel
	UITheme.apply_hint_style(hint_label)
	hint_label.modulate = Color.WHITE


func _add_section(title: String, items: Array[String]) -> void:
	var sep := UITheme.make_separator()
	sep.custom_minimum_size = Vector2(120, 1)
	_vbox.add_child(sep)
	_dynamic_nodes.append(sep)

	var title_label := Label.new()
	title_label.text = title
	UITheme.apply_body_style(title_label, UITheme.GOLD_DIM)
	_vbox.add_child(title_label)
	_dynamic_nodes.append(title_label)

	var items_label := Label.new()
	items_label.text = ", ".join(items)
	items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	items_label.custom_minimum_size = Vector2(200, 0)
	items_label.add_theme_color_override("font_color", UITheme.TEXT_NORMAL)
	items_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
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
