extends CanvasLayer
## 설정 화면. 볼륨 조절과 인디케이터 토글을 제공한다.


signal closed

const VOLUME_STEP: float = 0.1
const ITEMS: Array[String] = ["마스터 볼륨", "BGM 볼륨", "SFX 볼륨", "오프스크린 표시", "화면 흔들림", "데미지 숫자"]

var _selected: int = 0
var _value_labels: Array[Label] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_settings() -> void:
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
			_selected = mini(_selected + 1, ITEMS.size() - 1)
			_refresh()
		KEY_A, KEY_LEFT:
			_adjust(-1)
		KEY_D, KEY_RIGHT:
			_adjust(1)
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
	_refresh()


func _refresh() -> void:
	_value_labels[0].text = "%d%%" % int(AudioManager.master_volume * 100)
	_value_labels[1].text = "%d%%" % int(AudioManager.bgm_volume * 100)
	_value_labels[2].text = "%d%%" % int(AudioManager.sfx_volume * 100)
	_value_labels[3].text = "ON" if AudioManager.indicator_enabled else "OFF"
	_value_labels[4].text = "ON" if AudioManager.screen_shake_enabled else "OFF"
	_value_labels[5].text = "ON" if AudioManager.damage_numbers_enabled else "OFF"

	for i in range(ITEMS.size()):
		var color := Color(0.9, 0.75, 0.5, 1) if i == _selected else Color(0.6, 0.6, 0.6, 1)
		_value_labels[i].modulate = color
		_value_labels[i].get_parent().get_child(0).modulate = color


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "설정"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	for i in range(ITEMS.size()):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)

		var name_label := Label.new()
		name_label.text = ITEMS[i]
		name_label.custom_minimum_size = Vector2(100, 0)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		row.add_child(name_label)

		var val_label := Label.new()
		val_label.text = ""
		val_label.custom_minimum_size = Vector2(40, 0)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		row.add_child(val_label)
		_value_labels.append(val_label)

		vbox.add_child(row)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer2)

	var hint := Label.new()
	hint.text = "[W/S] 선택  [A/D] 조절  [ESC] 닫기"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(hint)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
