extends CanvasLayer
## 일시정지 시 표시되는 메뉴. ESC=계속, S=설정, Q=포기. 런 요약을 함께 표시한다.


const SETTINGS_UI_SCENE: PackedScene = preload("res://ui/settings_ui.tscn")

var _player: CharacterBody2D = null
var _summary_label: Label = null
var _settings_ui: CanvasLayer = null
@onready var _vbox: VBoxContainer = $Overlay/CenterContainer/VBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.state_changed.connect(_on_state_changed)
	_build_summary()


func register_player(player: CharacterBody2D) -> void:
	_player = player


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_Q:
			GameManager.change_state(Enums.GameState.MENU)
		elif event.physical_keycode == KEY_S:
			_open_settings()


func _open_settings() -> void:
	if _settings_ui == null:
		_settings_ui = SETTINGS_UI_SCENE.instantiate()
		get_parent().add_child(_settings_ui)
		_settings_ui.closed.connect(_on_settings_closed)
	visible = false
	_settings_ui.show_settings()


func _on_settings_closed() -> void:
	visible = true


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	visible = (new_state == Enums.GameState.PAUSED)
	if visible:
		_refresh_summary()


func _build_summary() -> void:
	_summary_label = Label.new()
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_summary_label.custom_minimum_size = Vector2(200, 0)
	_summary_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	_vbox.add_child(_summary_label)


func _refresh_summary() -> void:
	if _player == null or _summary_label == null:
		return

	var time_text := GameManager.format_time(GameManager.run_elapsed_time)

	var weapon_names: Array[String] = []
	for weapon: WeaponBase in _player._weapons:
		weapon_names.append("%s Lv.%d" % [weapon.data.weapon_name, weapon.level])

	var passive_names: Array[String] = []
	for p_name: String in _player._passives:
		var info: Dictionary = _player._passives[p_name]
		passive_names.append("%s Lv.%d" % [p_name, info["level"]])

	var lines: Array[String] = []
	lines.append(LocaleManager.tr_text("time_level_fmt") % [time_text, _player.current_level])
	if not weapon_names.is_empty():
		lines.append(LocaleManager.tr_text("weapons_label") + ", ".join(weapon_names))
	if not passive_names.is_empty():
		lines.append(LocaleManager.tr_text("passives_label") + ", ".join(passive_names))
	_summary_label.text = "\n".join(lines)
