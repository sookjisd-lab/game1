extends CanvasLayer
## 설정 화면. 볼륨, 디스플레이, 키 리바인딩, 언어를 제공한다.


signal closed

const VOLUME_STEP: float = 0.1
const ITEM_KEYS: Array[String] = [
	"master_vol", "bgm_vol", "sfx_vol",
	"indicator_toggle", "shake_toggle", "dmg_num_toggle",
	"fullscreen", "resolution", "keybind_menu", "language",
]
const KEYBIND_KEYS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right", "key_reset",
]
const KEYBIND_ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right",
]
const RESOLUTION_LABELS: Array[String] = [
	"640x360", "960x540", "1280x720", "1600x900", "1920x1080",
]

var _selected: int = 0
var _name_labels: Array[Label] = []
var _value_labels: Array[Label] = []
var _mode: String = "settings"
var _keybind_selected: int = 0
var _keybind_name_labels: Array[Label] = []
var _keybind_value_labels: Array[Label] = []
var _rebinding: bool = false
var _settings_panel: Control = null
var _keybind_panel: Control = null
var _hint_label: Label = null
var _title_label: Label = null
var _keybind_title: Label = null
var _keybind_hint: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	_build_keybind_ui()
	LocaleManager.language_changed.connect(_retranslate)


func show_settings() -> void:
	_selected = 0
	_mode = "settings"
	_rebinding = false
	_settings_panel.visible = true
	_keybind_panel.visible = false
	_retranslate()
	_refresh()
	visible = true


func _retranslate() -> void:
	_title_label.text = LocaleManager.tr_text("settings_title")
	_hint_label.text = LocaleManager.tr_text("settings_hint")
	for i in range(ITEM_KEYS.size()):
		if i < _name_labels.size():
			_name_labels[i].text = LocaleManager.tr_text(ITEM_KEYS[i])
	_keybind_title.text = LocaleManager.tr_text("keybind_title")
	_keybind_hint.text = LocaleManager.tr_text("keybind_hint")
	for i in range(KEYBIND_KEYS.size()):
		if i < _keybind_name_labels.size():
			_keybind_name_labels[i].text = LocaleManager.tr_text(KEYBIND_KEYS[i])


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed):
		return
	get_viewport().set_input_as_handled()

	if _rebinding:
		_handle_rebind_input(event)
		return

	if _mode == "keybinds":
		_handle_keybind_input(event)
		return

	match event.keycode:
		KEY_W, KEY_UP:
			_selected = maxi(_selected - 1, 0)
			_refresh()
		KEY_S, KEY_DOWN:
			_selected = mini(_selected + 1, ITEM_KEYS.size() - 1)
			_refresh()
		KEY_A, KEY_LEFT:
			_adjust(-1)
		KEY_D, KEY_RIGHT:
			_adjust(1)
		KEY_SPACE, KEY_ENTER:
			if _selected == 8:
				_enter_keybind_mode()
		KEY_ESCAPE:
			visible = false
			closed.emit()


func _adjust(direction: int) -> void:
	match _selected:
		0:
			AudioManager.set_master_volume(AudioManager.master_volume + VOLUME_STEP * direction)
		1:
			AudioManager.set_bgm_volume(AudioManager.bgm_volume + VOLUME_STEP * direction)
		2:
			AudioManager.set_sfx_volume(AudioManager.sfx_volume + VOLUME_STEP * direction)
		3:
			AudioManager.set_indicator_enabled(not AudioManager.indicator_enabled)
		4:
			AudioManager.set_screen_shake_enabled(not AudioManager.screen_shake_enabled)
		5:
			AudioManager.set_damage_numbers_enabled(not AudioManager.damage_numbers_enabled)
		6:
			AudioManager.set_fullscreen_enabled(not AudioManager.fullscreen_enabled)
		7:
			var new_scale: int = AudioManager.resolution_scale + direction
			AudioManager.set_resolution_scale(new_scale)
		8:
			_enter_keybind_mode()
		9:
			var new_lang: String = "en" if LocaleManager.current_language == "ko" else "ko"
			LocaleManager.set_language(new_lang)
			AudioManager.save_settings()
			_retranslate()
	_refresh()


func _enter_keybind_mode() -> void:
	_mode = "keybinds"
	_keybind_selected = 0
	_rebinding = false
	_settings_panel.visible = false
	_keybind_panel.visible = true
	_refresh_keybinds()


func _handle_keybind_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_W, KEY_UP:
			_keybind_selected = maxi(_keybind_selected - 1, 0)
			_refresh_keybinds()
		KEY_S, KEY_DOWN:
			_keybind_selected = mini(_keybind_selected + 1, KEYBIND_KEYS.size() - 1)
			_refresh_keybinds()
		KEY_SPACE, KEY_ENTER, KEY_D, KEY_RIGHT:
			if _keybind_selected < KEYBIND_ACTIONS.size():
				_rebinding = true
				_keybind_value_labels[_keybind_selected].text = "..."
			elif _keybind_selected == 4:
				AudioManager.reset_bindings()
				_refresh_keybinds()
		KEY_ESCAPE:
			_mode = "settings"
			_settings_panel.visible = true
			_keybind_panel.visible = false
			_refresh()


func _handle_rebind_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		_rebinding = false
		_refresh_keybinds()
		return
	var new_event := InputEventKey.new()
	new_event.physical_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	var action: String = KEYBIND_ACTIONS[_keybind_selected]
	AudioManager.rebind_action(action, new_event)
	_rebinding = false
	_refresh_keybinds()


func _refresh() -> void:
	_value_labels[0].text = "%d%%" % int(AudioManager.master_volume * 100)
	_value_labels[1].text = "%d%%" % int(AudioManager.bgm_volume * 100)
	_value_labels[2].text = "%d%%" % int(AudioManager.sfx_volume * 100)
	_value_labels[3].text = "ON" if AudioManager.indicator_enabled else "OFF"
	_value_labels[4].text = "ON" if AudioManager.screen_shake_enabled else "OFF"
	_value_labels[5].text = "ON" if AudioManager.damage_numbers_enabled else "OFF"
	_value_labels[6].text = "ON" if AudioManager.fullscreen_enabled else "OFF"
	var scale_index: int = AudioManager.resolution_scale - 2
	if scale_index >= 0 and scale_index < RESOLUTION_LABELS.size():
		_value_labels[7].text = RESOLUTION_LABELS[scale_index]
	else:
		_value_labels[7].text = "%dx" % AudioManager.resolution_scale
	_value_labels[8].text = ">>"
	var lang_key: String = "lang_ko" if LocaleManager.current_language == "ko" else "lang_en"
	_value_labels[9].text = LocaleManager.tr_text(lang_key)

	for i in range(ITEM_KEYS.size()):
		var color := Color(0.9, 0.75, 0.5, 1) if i == _selected else Color(0.6, 0.6, 0.6, 1)
		_value_labels[i].modulate = color
		_name_labels[i].modulate = color


func _refresh_keybinds() -> void:
	for i in range(KEYBIND_ACTIONS.size()):
		if _rebinding and i == _keybind_selected:
			_keybind_value_labels[i].text = "..."
		else:
			_keybind_value_labels[i].text = AudioManager.get_action_key_name(KEYBIND_ACTIONS[i])
	_keybind_value_labels[4].text = "ENTER"

	for i in range(KEYBIND_KEYS.size()):
		var color := Color(0.9, 0.75, 0.5, 1) if i == _keybind_selected else Color(0.6, 0.6, 0.6, 1)
		_keybind_value_labels[i].modulate = color
		_keybind_name_labels[i].modulate = color


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	_settings_panel = Control.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)

	_title_label = Label.new()
	_title_label.text = LocaleManager.tr_text("settings_title")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(_title_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(spacer)

	for i in range(ITEM_KEYS.size()):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)

		var name_label := Label.new()
		name_label.text = LocaleManager.tr_text(ITEM_KEYS[i])
		name_label.custom_minimum_size = Vector2(100, 0)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		row.add_child(name_label)
		_name_labels.append(name_label)

		var val_label := Label.new()
		val_label.text = ""
		val_label.custom_minimum_size = Vector2(50, 0)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		row.add_child(val_label)
		_value_labels.append(val_label)

		vbox.add_child(row)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(spacer2)

	_hint_label = Label.new()
	_hint_label.text = LocaleManager.tr_text("settings_hint")
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(_hint_label)

	center.add_child(vbox)
	_settings_panel.add_child(center)
	bg.add_child(_settings_panel)
	add_child(bg)


func _build_keybind_ui() -> void:
	_keybind_panel = Control.new()
	_keybind_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_keybind_panel.visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	_keybind_title = Label.new()
	_keybind_title.text = LocaleManager.tr_text("keybind_title")
	_keybind_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keybind_title.add_theme_font_size_override("font_size", 14)
	_keybind_title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(_keybind_title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	for i in range(KEYBIND_KEYS.size()):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)

		var name_label := Label.new()
		name_label.text = LocaleManager.tr_text(KEYBIND_KEYS[i])
		name_label.custom_minimum_size = Vector2(80, 0)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		row.add_child(name_label)
		_keybind_name_labels.append(name_label)

		var val_label := Label.new()
		val_label.text = ""
		val_label.custom_minimum_size = Vector2(50, 0)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		row.add_child(val_label)
		_keybind_value_labels.append(val_label)

		vbox.add_child(row)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer2)

	_keybind_hint = Label.new()
	_keybind_hint.text = LocaleManager.tr_text("keybind_hint")
	_keybind_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keybind_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(_keybind_hint)

	center.add_child(vbox)
	bg.add_child(center)
	_keybind_panel.add_child(bg)
	add_child(_keybind_panel)
