extends Area2D
## 기본 적 엔티티. EnemyData 리소스를 주입받아 동작한다.
## Area2D 기반 (CharacterBody2D보다 가벼움, CLAUDE.md 8.6절).


signal died(enemy: Area2D)

var data: EnemyData
var current_hp: float
var _target: Node2D = null
var _is_active: bool = false

@onready var _placeholder: ColorRect = $Placeholder
@onready var _collision: CollisionShape2D = $CollisionShape2D


## 풀에서 꺼낼 때 호출한다. 데이터와 위치를 설정한다.
func activate(enemy_data: EnemyData, spawn_position: Vector2, target: Node2D) -> void:
	data = enemy_data
	current_hp = data.max_hp
	_target = target
	global_position = spawn_position
	_is_active = true
	visible = true
	_collision.set_deferred("disabled", false)
	add_to_group("enemies")
	_apply_visuals()


## 풀에 반환할 때 호출한다.
func deactivate() -> void:
	_is_active = false
	visible = false
	_collision.set_deferred("disabled", true)
	_target = null
	if is_in_group("enemies"):
		remove_from_group("enemies")


func _physics_process(delta: float) -> void:
	if not _is_active or _target == null:
		return
	var direction := global_position.direction_to(_target.global_position)
	global_position += direction * data.move_speed * delta


func take_damage(amount: float) -> void:
	current_hp -= amount
	_flash_white()
	if current_hp <= 0.0:
		_die()


func _die() -> void:
	DropManager.spawn_xp_gem(global_position, data.xp_reward)
	died.emit(self)
	deactivate()


func _apply_visuals() -> void:
	_placeholder.color = data.sprite_color
	_placeholder.size = data.sprite_size
	_placeholder.position = -data.sprite_size / 2.0
	var shape := _collision.shape as RectangleShape2D
	shape.size = data.sprite_size * 0.8


func _flash_white() -> void:
	_placeholder.color = Color.WHITE
	get_tree().create_timer(0.08).timeout.connect(
		func() -> void:
			if _is_active and data != null:
				_placeholder.color = data.sprite_color
	)
