extends CanvasLayer
## NPC 대화 UI. 각성자 NPC 목록과 대화 내용을 표시한다.


signal closed

var _selected_npc: int = 0
var _selected_line: int = 0
var _npc_ids: Array[String] = []
var _npc_labels: Array[Label] = []
var _dialogue_label: Label
var _npc_name_label: Label
var _current_dialogues: Array[String] = []
var _mode: String = "npc_list"  # "npc_list" or "dialogue"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_npcs() -> void:
	_npc_ids.clear()
	for npc_id: String in StoryManager.NPC_DATA:
		_npc_ids.append(npc_id)
	_selected_npc = 0
	_selected_line = 0
	_mode = "npc_list"
	_refresh_npc_list()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed):
		return
	get_viewport().set_input_as_handled()

	if _mode == "npc_list":
		_handle_npc_list_input(event)
	else:
		_handle_dialogue_input(event)


func _handle_npc_list_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_W, KEY_UP:
			_selected_npc = maxi(_selected_npc - 1, 0)
			_refresh_npc_list()
		KEY_S, KEY_DOWN:
			_selected_npc = mini(_selected_npc + 1, _npc_ids.size() - 1)
			_refresh_npc_list()
		KEY_SPACE, KEY_ENTER:
			_open_dialogue()
		KEY_ESCAPE:
			visible = false
			closed.emit()


func _handle_dialogue_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_W, KEY_UP:
			_selected_line = maxi(_selected_line - 1, 0)
			_refresh_dialogue()
		KEY_S, KEY_DOWN:
			_selected_line = mini(_selected_line + 1, _current_dialogues.size() - 1)
			_refresh_dialogue()
		KEY_ESCAPE:
			_mode = "npc_list"
			_refresh_npc_list()


func _open_dialogue() -> void:
	if _selected_npc < 0 or _selected_npc >= _npc_ids.size():
		return
	var npc_id: String = _npc_ids[_selected_npc]
	if not StoryManager.is_npc_unlocked(npc_id):
		return
	_current_dialogues = StoryManager.get_npc_dialogues(npc_id)
	if _current_dialogues.is_empty():
		return
	_selected_line = 0
	_mode = "dialogue"
	_npc_name_label.text = StoryManager.NPC_DATA[npc_id]["name"]
	_npc_name_label.add_theme_color_override("font_color", StoryManager.NPC_DATA[npc_id]["color"])
	_refresh_dialogue()


func _refresh_npc_list() -> void:
	_npc_name_label.text = LocaleManager.tr_text("npc_title")
	_npc_name_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))

	for i in range(_npc_labels.size()):
		if i >= _npc_ids.size():
			_npc_labels[i].visible = false
			continue
		_npc_labels[i].visible = true
		var npc_id: String = _npc_ids[i]
		var unlocked: bool = StoryManager.is_npc_unlocked(npc_id)
		var is_sel: bool = i == _selected_npc
		var npc_info: Dictionary = StoryManager.NPC_DATA[npc_id]
		_npc_labels[i].text = npc_info["name"] if unlocked else "???"

		var color: Color
		if is_sel and unlocked:
			color = npc_info["color"]
		elif is_sel:
			color = Color(0.5, 0.4, 0.4, 1)
		elif unlocked:
			color = Color(0.7, 0.7, 0.7, 1)
		else:
			color = Color(0.4, 0.4, 0.4, 1)
		_npc_labels[i].modulate = color

	if _selected_npc >= 0 and _selected_npc < _npc_ids.size():
		var npc_id: String = _npc_ids[_selected_npc]
		if StoryManager.is_npc_unlocked(npc_id):
			var count: int = StoryManager.get_npc_dialogues(npc_id).size()
			_dialogue_label.text = LocaleManager.tr_text("npc_dialogue_fmt") % count
		else:
			_dialogue_label.text = LocaleManager.tr_text("npc_locked")
	else:
		_dialogue_label.text = ""


func _refresh_dialogue() -> void:
	if _selected_line >= 0 and _selected_line < _current_dialogues.size():
		_dialogue_label.text = "(%d/%d)\n%s" % [
			_selected_line + 1,
			_current_dialogues.size(),
			_current_dialogues[_selected_line],
		]


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	_npc_name_label = Label.new()
	_npc_name_label.text = LocaleManager.tr_text("npc_title")
	_npc_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_npc_name_label.add_theme_font_size_override("font_size", 14)
	_npc_name_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(_npc_name_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	for i in range(StoryManager.NPC_DATA.size()):
		var label := Label.new()
		label.text = "???"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		vbox.add_child(label)
		_npc_labels.append(label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer2)

	_dialogue_label = Label.new()
	_dialogue_label.text = ""
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_dialogue_label.custom_minimum_size = Vector2(280, 60)
	_dialogue_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55, 1))
	vbox.add_child(_dialogue_label)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("npc_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(hint)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
