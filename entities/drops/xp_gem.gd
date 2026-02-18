extends Area2D
## 경험치 보석. 적 사망 시 드롭되며, 마그넷 범위 내 플레이어에게 흡수된다.


signal collected(gem: Area2D)

var xp_value: int = 1
var _is_active: bool = false
var _being_attracted: bool = false
var _attract_target: Node2D = null
var _attract_speed: float = 0.0
var _visual: ColorRect
var _collision: CollisionShape2D

const ATTRACT_ACCELERATION: float = 400.0
const MAX_ATTRACT_SPEED: float = 250.0


func _ready() -> void:
	_cache_nodes()


func activate(value: int, spawn_position: Vector2, color: Color) -> void:
	xp_value = value
	global_position = spawn_position
	_is_active = true
	_being_attracted = false
	_attract_speed = 0.0
	visible = true
	_cache_nodes()
	if _collision != null:
		_collision.set_deferred("disabled", false)
	if _visual != null:
		_visual.color = color


func deactivate() -> void:
	_is_active = false
	_being_attracted = false
	_attract_target = null
	visible = false
	if _collision != null:
		_collision.set_deferred("disabled", true)


func start_attract(target: Node2D) -> void:
	_being_attracted = true
	_attract_target = target
	_attract_speed = 30.0


func _physics_process(delta: float) -> void:
	if not _is_active or not _being_attracted:
		return
	if _attract_target == null:
		return

	_attract_speed = minf(_attract_speed + ATTRACT_ACCELERATION * delta, MAX_ATTRACT_SPEED)
	var direction := global_position.direction_to(_attract_target.global_position)
	global_position += direction * _attract_speed * delta

	if global_position.distance_to(_attract_target.global_position) < 4.0:
		_collected()


func _collected() -> void:
	collected.emit(self)
	deactivate()


func _cache_nodes() -> void:
	if _visual == null:
		_visual = get_node_or_null("Visual")
	if _collision == null:
		_collision = get_node_or_null("CollisionShape2D")
