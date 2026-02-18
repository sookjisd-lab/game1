extends Node2D
## 데미지/회복 숫자 팝업. 위로 떠오르며 페이드아웃한다.


var _label: Label
var _velocity: Vector2
var _lifetime: float = 0.0
const DURATION: float = 0.6
const RISE_SPEED: float = 30.0


func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-20, -8)
	_label.size = Vector2(40, 16)
	add_child(_label)


func show_number(value: float, pos: Vector2, color: Color) -> void:
	global_position = pos
	_lifetime = DURATION
	_velocity = Vector2(randf_range(-10, 10), -RISE_SPEED)
	visible = true
	_label.text = str(int(value))
	_label.add_theme_color_override("font_color", color)
	_label.modulate.a = 1.0


func _process(delta: float) -> void:
	if _lifetime <= 0.0:
		return
	_lifetime -= delta
	global_position += _velocity * delta
	_label.modulate.a = maxf(_lifetime / DURATION, 0.0)
	if _lifetime <= 0.0:
		visible = false
