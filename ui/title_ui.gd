extends CanvasLayer
## 타이틀 화면. 게임 제목과 시작 버튼을 표시한다.


signal start_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_title() -> void:
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			visible = false
			start_pressed.emit()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "저주받은 밤"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Cursed Night"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7, 1))
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var start_label := Label.new()
	start_label.text = "[SPACE] 시작"
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(start_label)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
