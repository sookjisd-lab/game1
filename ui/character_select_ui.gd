extends CanvasLayer
## 캐릭터 선택 화면. 해금된 캐릭터 중 하나를 선택한다.


signal character_selected(data: CharacterData)
signal back_pressed

var _characters: Array[CharacterData] = []
var _selected: int = 0
var _cards: Array[PanelContainer] = []
var _container: HBoxContainer
var _desc_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_load_characters()
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
			_selected = mini(_selected + 1, _characters.size() - 1)
			_refresh()
		KEY_SPACE, KEY_ENTER:
			_confirm()
		KEY_ESCAPE:
			visible = false
			back_pressed.emit()


func _confirm() -> void:
	var data: CharacterData = _characters[_selected]
	if not _is_unlocked(_selected):
		return
	visible = false
	character_selected.emit(data)


func _is_unlocked(idx: int) -> bool:
	if idx == 0:
		return true
	if idx == 1:
		return GameManager.meta.fritz_unlocked
	return false


func _refresh() -> void:
	for i in range(_cards.size()):
		var card: PanelContainer = _cards[i]
		var is_sel: bool = i == _selected
		card.modulate = Color.WHITE if is_sel else Color(0.5, 0.5, 0.5, 1)

	var data: CharacterData = _characters[_selected]
	if _is_unlocked(_selected):
		_desc_label.text = "%s\nHP:%d 속도:%d 공격:x%.2f\n초기무기: %s\n고유: %s" % [
			data.description,
			int(data.base_hp),
			int(data.base_speed),
			data.base_damage_mult,
			data.starting_weapon_data.get_file().get_basename(),
			data.passive_desc,
		]
	else:
		_desc_label.text = LocaleManager.tr_text("char_locked")


func _load_characters() -> void:
	_characters.append(preload("res://data/characters/rosie.tres"))
	_characters.append(preload("res://data/characters/fritz.tres"))


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
	title.text = LocaleManager.tr_text("char_select")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(title)

	_container = HBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 10)

	for i in range(_characters.size()):
		var data: CharacterData = _characters[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(80, 80)

		var card_vbox := VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 2)

		var portrait := ColorRect.new()
		portrait.color = data.sprite_color if _is_unlocked(i) else Color(0.2, 0.2, 0.2, 1)
		portrait.custom_minimum_size = Vector2(32, 32)
		card_vbox.add_child(portrait)

		var name_label := Label.new()
		name_label.text = data.character_name if _is_unlocked(i) else "???"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(name_label)

		card.add_child(card_vbox)
		_container.add_child(card)
		_cards.append(card)

	vbox.add_child(_container)

	_desc_label = Label.new()
	_desc_label.text = ""
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.custom_minimum_size = Vector2(280, 40)
	_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(_desc_label)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("char_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(hint)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
