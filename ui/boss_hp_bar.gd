extends CanvasLayer
## 보스 HP바. 화면 하단에 보스 이름과 체력바를 표시한다.


var _name_label: Label
var _hp_bar: ProgressBar
var _phase_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_boss(boss_name: String, current_hp: float, max_hp: float) -> void:
	_name_label.text = boss_name
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_phase_label.text = ""
	_phase_label.modulate.a = 0.0
	visible = true


func update_hp(current_hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp


func show_phase(phase: int) -> void:
	_phase_label.text = "Phase %d!" % phase
	_phase_label.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_phase_label, "modulate:a", 0.0, 0.5)


func hide_boss() -> void:
	_phase_label.text = ""
	_phase_label.modulate.a = 0.0
	visible = false


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	panel.anchor_top = 0.9
	panel.anchor_bottom = 1.0
	panel.anchor_left = 0.2
	panel.anchor_right = 0.8
	panel.offset_top = 0
	panel.offset_bottom = 0

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	_phase_label.text = ""
	vbox.add_child(_phase_label)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.text = "BOSS"
	vbox.add_child(_name_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(0, 6)
	_hp_bar.show_percentage = false
	vbox.add_child(_hp_bar)

	panel.add_child(vbox)
	add_child(panel)
