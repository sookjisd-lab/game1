extends CanvasLayer
## 타이틀 화면. 게임 제목과 메뉴를 표시한다.


signal start_pressed
signal altar_pressed
signal settings_pressed
signal library_pressed
signal npc_pressed

var _shards_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_title() -> void:
	if _shards_label != null:
		_shards_label.text = "기억 조각: %d" % GameManager.meta.memory_shards
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE, KEY_ENTER:
				visible = false
				start_pressed.emit()
			KEY_A:
				visible = false
				altar_pressed.emit()
			KEY_S:
				visible = false
				settings_pressed.emit()
			KEY_L:
				visible = false
				library_pressed.emit()
			KEY_N:
				visible = false
				npc_pressed.emit()
			KEY_Q:
				get_tree().quit()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)

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
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	var start_label := Label.new()
	start_label.text = "[SPACE] 시작"
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(start_label)

	var altar_label := Label.new()
	altar_label.text = "[A] 기억의 제단"
	altar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	altar_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 0.8))
	vbox.add_child(altar_label)

	var library_label := Label.new()
	library_label.text = "[L] 기억의 서재"
	library_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	library_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.8, 1))
	vbox.add_child(library_label)

	var npc_label := Label.new()
	npc_label.text = "[N] 각성자"
	npc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7, 1))
	vbox.add_child(npc_label)

	var settings_label := Label.new()
	settings_label.text = "[S] 설정"
	settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1))
	vbox.add_child(settings_label)

	var quit_label := Label.new()
	quit_label.text = "[Q] 종료"
	quit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quit_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5, 1))
	vbox.add_child(quit_label)

	_shards_label = Label.new()
	_shards_label.text = ""
	_shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shards_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4, 1))
	vbox.add_child(_shards_label)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
