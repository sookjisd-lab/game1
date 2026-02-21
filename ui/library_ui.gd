extends CanvasLayer
## 기억의 서재. 발견된 스토리 단서를 열람한다.


signal closed

var _selected: int = 0
var _clue_ids: Array[String] = []
var _name_labels: Array[Label] = []
var _detail_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_library() -> void:
	_clue_ids.clear()
	for clue_id: String in StoryManager.CLUES:
		_clue_ids.append(clue_id)
	_selected = 0
	_refresh()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed):
		return

	match event.keycode:
		KEY_W, KEY_UP:
			_selected = maxi(_selected - 1, 0)
			_refresh()
		KEY_S, KEY_DOWN:
			_selected = mini(_selected + 1, _clue_ids.size() - 1)
			_refresh()
		KEY_ESCAPE:
			visible = false
			closed.emit()


func _refresh() -> void:
	for i in range(_name_labels.size()):
		var clue_id: String = _clue_ids[i]
		var discovered: bool = StoryManager.is_clue_discovered(clue_id)
		var is_sel: bool = i == _selected
		_name_labels[i].text = StoryManager.get_clue_name(clue_id) if discovered else "???"
		var color: Color
		if is_sel and discovered:
			color = UITheme.SELECT_ACTIVE
		elif is_sel:
			color = UITheme.BLOOD_LIGHT
		elif discovered:
			color = UITheme.TEXT_NORMAL
		else:
			color = UITheme.TEXT_DISABLED
		_name_labels[i].add_theme_color_override("font_color", color)

	if _selected >= 0 and _selected < _clue_ids.size():
		var clue_id: String = _clue_ids[_selected]
		if StoryManager.is_clue_discovered(clue_id):
			_detail_label.text = StoryManager.get_clue_text(clue_id)
			_detail_label.add_theme_color_override("font_color", UITheme.CREAM)
		else:
			_detail_label.text = LocaleManager.tr_text("library_locked")
			_detail_label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = LocaleManager.tr_text("library_title")
	UITheme.apply_heading_style(title, UITheme.GOLD)
	vbox.add_child(title)

	var sep := UITheme.make_separator()
	sep.custom_minimum_size = Vector2(120, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(sep)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(spacer)

	for clue_id: String in StoryManager.CLUES:
		var label := Label.new()
		label.text = "???"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
		vbox.add_child(label)
		_name_labels.append(label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer2)

	# 상세 텍스트 패널
	var detail_panel := PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel", UITheme.make_panel_style(
		UITheme.BG_PANEL, UITheme.BORDER_DIM, 1, 2
	))
	detail_panel.custom_minimum_size = Vector2(280, 50)

	_detail_label = Label.new()
	_detail_label.text = ""
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_label.add_theme_color_override("font_color", UITheme.CREAM)
	_detail_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
	detail_panel.add_child(_detail_label)
	vbox.add_child(detail_panel)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("library_hint")
	UITheme.apply_hint_style(hint)
	vbox.add_child(hint)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
