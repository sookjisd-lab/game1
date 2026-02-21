extends CanvasLayer
## 보스 등장 경고 연출. WARNING 텍스트 + 화면 빨간 점멸.


signal warning_finished

const DURATION: float = 2.0
const FLASH_SPEED: float = 6.0

var _warning_label: Label
var _border: ColorRect
var _vignette_top: ColorRect
var _vignette_bot: ColorRect
var _timer: float = 0.0
var _active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func play_warning(boss_name: String) -> void:
	_warning_label.text = "!! WARNING !!\n%s" % boss_name
	_timer = DURATION
	_active = true
	visible = true


func _process(delta: float) -> void:
	if not _active:
		return

	_timer -= delta
	var flash: float = (sin(_timer * FLASH_SPEED * TAU) + 1.0) * 0.5
	_border.color = Color(0.6, 0.0, 0.0, flash * 0.35)
	_warning_label.modulate.a = 0.6 + flash * 0.4

	# 비네트 효과 강도 연동
	var vig_alpha: float = 0.3 + flash * 0.2
	_vignette_top.color = Color(0.0, 0.0, 0.0, vig_alpha)
	_vignette_bot.color = Color(0.0, 0.0, 0.0, vig_alpha)

	if _timer <= 0.0:
		_active = false
		visible = false
		warning_finished.emit()


func _build_ui() -> void:
	_border = ColorRect.new()
	_border.color = Color(0.6, 0.0, 0.0, 0.3)
	_border.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 상단 비네트 그라데이션 (어두운 테두리 느낌)
	_vignette_top = ColorRect.new()
	_vignette_top.color = Color(0.0, 0.0, 0.0, 0.3)
	_vignette_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_vignette_top.custom_minimum_size = Vector2(0, 20)
	_vignette_top.offset_bottom = 20
	_vignette_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border.add_child(_vignette_top)

	# 하단 비네트
	_vignette_bot = ColorRect.new()
	_vignette_bot.color = Color(0.0, 0.0, 0.0, 0.3)
	_vignette_bot.anchor_top = 0.88
	_vignette_bot.anchor_bottom = 1.0
	_vignette_bot.anchor_left = 0.0
	_vignette_bot.anchor_right = 1.0
	_vignette_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border.add_child(_vignette_bot)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	_warning_label = Label.new()
	_warning_label.text = "!! WARNING !!"
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.add_theme_font_size_override("font_size", UITheme.HEADING_FONT_SIZE)
	_warning_label.add_theme_color_override("font_color", UITheme.BLOOD_LIGHT)

	center.add_child(_warning_label)
	_border.add_child(center)
	add_child(_border)
