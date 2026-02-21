extends CanvasLayer
## 레벨업 시 3장의 업그레이드 카드를 표시하고 선택을 처리한다.


var _choices: Array[UpgradeData] = []
var _card_nodes: Array[PanelContainer] = []


@onready var _card_container: HBoxContainer = $Overlay/CenterContainer/VBox/CardContainer
@onready var _title_label: Label = $Overlay/CenterContainer/VBox/TitleLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_apply_theme()


func show_choices(choices: Array[UpgradeData]) -> void:
	_choices = choices
	_clear_cards()
	for i in range(choices.size()):
		_create_card(choices[i], i)
	visible = true


func _apply_theme() -> void:
	# 오버레이 배경 어둡게
	var overlay: ColorRect = $Overlay
	overlay.color = UITheme.BG_OVERLAY

	# 타이틀 스타일
	_title_label.add_theme_font_size_override("font_size", UITheme.HEADING_FONT_SIZE)
	_title_label.add_theme_color_override("font_color", UITheme.GOLD)


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
	AudioManager.play_sfx("res://assets/audio/sfx/ui_confirm.wav")
	UpgradeManager.apply_upgrade(_choices[index])
	visible = false
	_clear_cards()
	GameManager.change_state(Enums.GameState.PLAYING)


func _create_card(data: UpgradeData, index: int) -> void:
	var is_new: bool = data.stat_key == "new_weapon" or data.stat_key == "new_passive"
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(88, 95)
	card.add_theme_stylebox_override("panel", UITheme.make_card_style(is_new))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	# 색상 헤더 바
	var header := ColorRect.new()
	header.color = UITheme.GOLD if is_new else data.card_color
	header.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(header)

	# 번호 뱃지 + 이름
	var name_label := Label.new()
	name_label.text = "[%d] %s" % [index + 1, data.upgrade_name]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.add_theme_color_override("font_color", UITheme.GOLD if is_new else UITheme.TEXT_BRIGHT)
	vbox.add_child(name_label)

	# 구분선
	var sep := UITheme.make_separator()
	vbox.add_child(sep)

	# 설명
	var desc_label := Label.new()
	desc_label.text = data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_color_override("font_color", UITheme.TEXT_NORMAL)
	desc_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
	vbox.add_child(desc_label)

	card.add_child(vbox)
	_card_container.add_child(card)
	_card_nodes.append(card)


func _clear_cards() -> void:
	for card in _card_nodes:
		card.queue_free()
	_card_nodes.clear()
	_choices.clear()
