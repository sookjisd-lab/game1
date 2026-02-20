extends CanvasLayer
## 스테이지 선택 화면. 해금된 스테이지 중 하나를 선택한다.


signal stage_selected(data: StageData)
signal back_pressed

var _stages: Array[StageData] = []
var _selected: int = 0
var _cards: Array[PanelContainer] = []
var _desc_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_load_stages()
	_build_ui()


func show_select() -> void:
	_selected = 0
	_refresh()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed):
		return

	match event.keycode:
		KEY_A, KEY_LEFT:
			_selected = maxi(_selected - 1, 0)
			_refresh()
		KEY_D, KEY_RIGHT:
			_selected = mini(_selected + 1, _stages.size() - 1)
			_refresh()
		KEY_SPACE, KEY_ENTER:
			_confirm()
		KEY_ESCAPE:
			visible = false
			back_pressed.emit()


func _confirm() -> void:
	if not _is_unlocked(_selected):
		return
	visible = false
	stage_selected.emit(_stages[_selected])


func _is_unlocked(idx: int) -> bool:
	if idx == 0:
		return true
	if idx == 1:
		return GameManager.meta.stage2_unlocked
	return false


func _refresh() -> void:
	for i in range(_cards.size()):
		var card: PanelContainer = _cards[i]
		var is_sel: bool = i == _selected
		card.modulate = Color.WHITE if is_sel else Color(0.5, 0.5, 0.5, 1)

	var data: StageData = _stages[_selected]
	if _is_unlocked(_selected):
		_desc_label.text = "%s\n%s" % [data.stage_name, data.description]
	else:
		_desc_label.text = LocaleManager.tr_text("stage_locked")


func _load_stages() -> void:
	_stages.append(preload("res://data/stages/stage1_town.tres"))
	_stages.append(preload("res://data/stages/stage2_cemetery.tres"))


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
	title.text = LocaleManager.tr_text("stage_select")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(title)

	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)

	for i in range(_stages.size()):
		var data: StageData = _stages[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(100, 60)

		var card_vbox := VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 2)

		var preview := ColorRect.new()
		preview.color = data.bg_color if _is_unlocked(i) else Color(0.15, 0.15, 0.15, 1)
		preview.custom_minimum_size = Vector2(40, 24)
		card_vbox.add_child(preview)

		var name_label := Label.new()
		name_label.text = data.stage_name if _is_unlocked(i) else "???"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(name_label)

		card.add_child(card_vbox)
		container.add_child(card)
		_cards.append(card)

	vbox.add_child(container)

	_desc_label = Label.new()
	_desc_label.text = ""
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.custom_minimum_size = Vector2(280, 30)
	_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(_desc_label)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("stage_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(hint)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
