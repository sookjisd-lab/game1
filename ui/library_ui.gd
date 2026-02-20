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
		if is_sel:
			color = Color(0.9, 0.75, 0.5, 1)
		elif discovered:
			color = Color(0.7, 0.7, 0.7, 1)
		else:
			color = Color(0.4, 0.4, 0.4, 1)
		_name_labels[i].modulate = color

	if _selected >= 0 and _selected < _clue_ids.size():
		var clue_id: String = _clue_ids[_selected]
		if StoryManager.is_clue_discovered(clue_id):
			_detail_label.text = StoryManager.get_clue_text(clue_id)
		else:
			_detail_label.text = LocaleManager.tr_text("library_locked")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = LocaleManager.tr_text("library_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	for clue_id: String in StoryManager.CLUES:
		var label := Label.new()
		label.text = "???"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		vbox.add_child(label)
		_name_labels.append(label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer2)

	_detail_label = Label.new()
	_detail_label.text = ""
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_label.custom_minimum_size = Vector2(280, 50)
	_detail_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55, 1))
	vbox.add_child(_detail_label)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("library_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(hint)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
