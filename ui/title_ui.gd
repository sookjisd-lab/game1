extends CanvasLayer
## 타이틀 화면. 게임 제목과 메뉴를 표시한다.


signal start_pressed
signal altar_pressed
signal settings_pressed
signal library_pressed
signal npc_pressed

var _shards_label: Label = null
var _title_label: Label = null
var _menu_labels: Array[Label] = []
const MENU_KEYS: Array[String] = ["start", "altar", "library", "npc_menu", "settings_menu", "quit"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	LocaleManager.language_changed.connect(_retranslate)


func show_title() -> void:
	_retranslate()
	if _shards_label != null:
		_shards_label.text = LocaleManager.tr_text("memory_shards_fmt") % GameManager.meta.memory_shards
	visible = true


func _retranslate() -> void:
	_title_label.text = LocaleManager.tr_text("game_title")
	for i in range(MENU_KEYS.size()):
		if i < _menu_labels.size():
			_menu_labels[i].text = LocaleManager.tr_text(MENU_KEYS[i])


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

	_title_label = Label.new()
	_title_label.text = LocaleManager.tr_text("game_title")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(_title_label)

	var subtitle := Label.new()
	subtitle.text = "Cursed Night"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7, 1))
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	var colors: Array[Color] = [
		Color(0.8, 0.8, 0.8, 1),
		Color(1, 0.84, 0, 0.8),
		Color(0.7, 0.65, 0.8, 1),
		Color(0.6, 0.8, 0.7, 1),
		Color(0.7, 0.7, 0.8, 1),
		Color(0.6, 0.5, 0.5, 1),
	]
	for i in range(MENU_KEYS.size()):
		var label := Label.new()
		label.text = LocaleManager.tr_text(MENU_KEYS[i])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", colors[i])
		vbox.add_child(label)
		_menu_labels.append(label)

	_shards_label = Label.new()
	_shards_label.text = ""
	_shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shards_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4, 1))
	vbox.add_child(_shards_label)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
