extends Area2D
## 기본 적 엔티티. EnemyData 리소스를 주입받아 동작한다.
## Area2D 기반 (CharacterBody2D보다 가벼움, CLAUDE.md 8.6절).


signal died(enemy: Area2D)

var data: EnemyData
var current_hp: float
var _target: Node2D = null
var _is_active: bool = false
var _placeholder: ColorRect
var _collision: CollisionShape2D


func _ready() -> void:
	_cache_nodes()


## 풀에서 꺼낼 때 호출한다. 데이터와 위치를 설정한다.
func activate(enemy_data: EnemyData, spawn_position: Vector2, target: Node2D) -> void:
	data = enemy_data
	current_hp = data.max_hp
	_target = target
	global_position = spawn_position
	_is_active = true
	visible = true
	_cache_nodes()
	_collision.set_deferred("disabled", false)
	add_to_group("enemies")
	_apply_visuals()


## 풀에 반환할 때 호출한다.
func deactivate() -> void:
	_is_active = false
	visible = false
	if _collision != null:
		_collision.set_deferred("disabled", true)
	_target = null
	if is_in_group("enemies"):
		remove_from_group("enemies")


func _physics_process(delta: float) -> void:
	if not _is_active or _target == null:
		return
	var direction := global_position.direction_to(_target.global_position)
	global_position += direction * data.move_speed * delta


func take_damage(amount: float, knockback_force: float = 0.0, knockback_origin: Vector2 = Vector2.ZERO) -> void:
	current_hp -= amount
	_flash_white()
	DamageNumberManager.spawn_damage(amount, global_position)
	if knockback_force > 0.0 and knockback_origin != Vector2.ZERO:
		var direction: Vector2 = knockback_origin.direction_to(global_position)
		global_position += direction * knockback_force
	if current_hp <= 0.0:
		call_deferred("_die")


func _die() -> void:
	_spawn_death_particles()
	DropManager.spawn_xp_gem(global_position, data.xp_reward)
	died.emit(self)
	deactivate()


func _spawn_death_particles() -> void:
	var color: Color = data.sprite_color if data != null else Color.WHITE
	for i in range(4):
		var particle := ColorRect.new()
		particle.color = color
		particle.size = Vector2(3, 3)
		particle.position = -Vector2(1.5, 1.5)
		particle.z_index = 5
		var container := Node2D.new()
		container.global_position = global_position
		get_tree().current_scene.add_child(container)
		container.add_child(particle)
		var dir := Vector2.from_angle(TAU / 4.0 * i + randf_range(-0.3, 0.3))
		var tween := container.create_tween()
		tween.set_parallel(true)
		tween.tween_property(container, "position", container.position + dir * randf_range(8, 16), 0.3)
		tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(container.queue_free)


func _cache_nodes() -> void:
	if _placeholder == null:
		_placeholder = get_node_or_null("Placeholder")
	if _collision == null:
		_collision = get_node_or_null("CollisionShape2D")


func _apply_visuals() -> void:
	if _placeholder == null or _collision == null:
		return
	_placeholder.color = data.sprite_color
	_placeholder.size = data.sprite_size
	_placeholder.position = -data.sprite_size / 2.0
	var shape := _collision.shape as RectangleShape2D
	shape.size = data.sprite_size * 0.8


func _flash_white() -> void:
	if _placeholder == null:
		return
	_placeholder.color = Color.WHITE
	get_tree().create_timer(0.08).timeout.connect(
		func() -> void:
			if _is_active and data != null and _placeholder != null:
				_placeholder.color = data.sprite_color
	)
