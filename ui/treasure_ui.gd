extends CanvasLayer
## 보물 상자 UI. 진화 선택지 또는 강력한 보상을 표시한다.


var _choices: Array[UpgradeData] = []
var _card_nodes: Array[PanelContainer] = []

var _overlay: ColorRect
var _card_container: HBoxContainer
var _title_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_choices(choices: Array[UpgradeData]) -> void:
	_choices = choices
	_clear_cards()
	for i in range(choices.size()):
		_create_card(choices[i], i)
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _select(0)
			KEY_2: _select(1)
			KEY_3: _select(2)


func _select(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return
	UpgradeManager.apply_upgrade(_choices[index])
	visible = false
	_clear_cards()
	GameManager.change_state(Enums.GameState.PLAYING)


func _create_card(data: UpgradeData, index: int) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(86, 90)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var header := ColorRect.new()
	header.color = data.card_color
	header.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(header)

	# 진화 아이콘 표시 (금색 테두리 느낌)
	var star := Label.new()
	star.text = "★"
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(star)

	var name_label := Label.new()
	name_label.text = "[%d] %s" % [index + 1, data.upgrade_name]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(desc_label)

	card.add_child(vbox)
	_card_container.add_child(card)
	_card_nodes.append(card)


func _clear_cards() -> void:
	for card in _card_nodes:
		card.queue_free()
	_card_nodes.clear()
	_choices.clear()


func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	_title_label = Label.new()
	_title_label.text = "-- TREASURE --"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(_title_label)

	_card_container = HBoxContainer.new()
	_card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_card_container)

	center.add_child(vbox)
	_overlay.add_child(center)
	add_child(_overlay)
