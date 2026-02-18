extends Node
## 데미지/회복 숫자 팝업 풀링 및 표시를 담당한다 (최대 20개).
## Autoload 싱글톤: DamageNumberManager


const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://ui/damage_number.tscn")
const DAMAGE_COLOR := Color(1, 1, 1, 1)
const HEAL_COLOR := Color(0.3, 1, 0.4, 1)

var _pool: Array[Node2D] = []
var _index: int = 0
var _stage: Node2D = null


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)


func register_stage(stage: Node2D) -> void:
	_stage = stage
	_prewarm()


func spawn_damage(value: float, pos: Vector2) -> void:
	if _stage == null:
		return
	var num: Node2D = _pool[_index]
	_index = (_index + 1) % _pool.size()
	num.show_number(value, pos, DAMAGE_COLOR)


func spawn_heal(value: float, pos: Vector2) -> void:
	if _stage == null:
		return
	var num: Node2D = _pool[_index]
	_index = (_index + 1) % _pool.size()
	num.show_number(value, pos, HEAL_COLOR)


func _prewarm() -> void:
	for existing in _pool:
		existing.queue_free()
	_pool.clear()
	_index = 0
	for i in range(Constants.MAX_DAMAGE_NUMBERS):
		var num: Node2D = DAMAGE_NUMBER_SCENE.instantiate()
		num.visible = false
		_stage.add_child(num)
		_pool.append(num)


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if new_state == Enums.GameState.MENU:
		_pool.clear()
		_stage = null
		_index = 0
