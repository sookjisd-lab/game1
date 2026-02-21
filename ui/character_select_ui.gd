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
		var unlocked: bool = _is_unlocked(i)

		if is_sel and unlocked:
			card.add_theme_stylebox_override("panel", UITheme.make_card_style(true))
		elif is_sel:
			card.add_theme_stylebox_override("panel", UITheme.make_panel_style(
				Color(0.1, 0.06, 0.14, 0.9),
				UITheme.BLOOD_RED, 1, 2
			))
		else:
			card.add_theme_stylebox_override("panel", UITheme.make_card_style(false))

		card.modulate = Color.WHITE if is_sel else Color(0.6, 0.55, 0.5, 1)

	var data: CharacterData = _characters[_selected]
	if _is_unlocked(_selected):
		_desc_label.text = "%s\nHP:%d SPD:%d ATK:x%.2f\n%s\n%s" % [
			data.description,
			int(data.base_hp),
			int(data.base_speed),
			data.base_damage_mult,
			data.starting_weapon_data.get_file().get_basename(),
			data.passive_desc,
		]
		_desc_label.add_theme_color_override("font_color", UITheme.TEXT_NORMAL)
	else:
		_desc_label.text = LocaleManager.tr_text("char_locked")
		_desc_label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)


func _load_characters() -> void:
	_characters.append(preload("res://data/characters/rosie.tres"))
	_characters.append(preload("res://data/characters/fritz.tres"))


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = LocaleManager.tr_text("char_select")
	UITheme.apply_heading_style(title, UITheme.GOLD)
	vbox.add_child(title)

	var sep := UITheme.make_separator()
	sep.custom_minimum_size = Vector2(140, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(sep)

	_container = HBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 10)

	for i in range(_characters.size()):
		var data: CharacterData = _characters[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(80, 80)
		card.add_theme_stylebox_override("panel", UITheme.make_card_style(false))

		var card_vbox := VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 2)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(32, 32)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if _is_unlocked(i) and data.sprite_path != "":
			portrait.texture = load(data.sprite_path)
		else:
			portrait.modulate = Color(0.2, 0.2, 0.2, 1)
			if data.sprite_path != "":
				portrait.texture = load(data.sprite_path)
		card_vbox.add_child(portrait)

		var name_label := Label.new()
		name_label.text = data.character_name if _is_unlocked(i) else "???"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", UITheme.CREAM if _is_unlocked(i) else UITheme.TEXT_DISABLED)
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
	_desc_label.add_theme_color_override("font_color", UITheme.TEXT_NORMAL)
	_desc_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
	vbox.add_child(_desc_label)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("char_hint")
	UITheme.apply_hint_style(hint)
	vbox.add_child(hint)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
