extends Area2D
## 마녀의 사자: 20분 등장 보스. 독구름 + 텔레포트 + 탄막 3페이즈.


signal boss_died
signal boss_hp_changed(current_hp: float, max_hp: float)
signal boss_phase_changed(phase: int)

const SIZE: Vector2 = Vector2(96, 96)
const MOVE_SPEED: float = 25.0
const CONTACT_DAMAGE: float = 25.0
const XP_REWARD: int = 100
const PATTERN_INTERVAL: float = 3.5

const POISON_CLOUD_DAMAGE: float = 8.0
const POISON_CLOUD_RADIUS: float = 40.0
const POISON_CLOUD_DURATION: float = 4.0
const POISON_CLOUD_COUNT: int = 3

const BULLET_DAMAGE: float = 12.0
const BULLET_SPEED: float = 100.0
const BULLET_COUNT_P2: int = 5
const BULLET_COUNT_P3: int = 12

const TELEPORT_DISTANCE: float = 80.0

var max_hp: float = 600.0
var current_hp: float = 600.0
var _target: Node2D = null
var _is_active: bool = false
var _current_phase: int = 1
var _pattern_timer: float = 0.0
var _placeholder: Sprite2D
var _collision: CollisionShape2D


func is_boss_entity() -> bool:
	return true


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_cache_nodes()


func activate(spawn_position: Vector2, target: Node2D) -> void:
	_target = target
	global_position = spawn_position
	current_hp = max_hp
	_is_active = true
	_current_phase = 1
	_pattern_timer = PATTERN_INTERVAL
	visible = true
	_cache_nodes()
	_collision.set_deferred("disabled", false)
	add_to_group("enemies")
	_apply_visuals()
	boss_hp_changed.emit(current_hp, max_hp)


func _apply_visuals() -> void:
	if _placeholder == null:
		return
	_placeholder.texture = preload("res://assets/bosses/boss_witch_messenger.png")
	_placeholder.modulate = Color(1, 1, 1, 1)
	var shape := _collision.shape as RectangleShape2D
	shape.size = SIZE * 0.8


func _physics_process(delta: float) -> void:
	if not _is_active or _target == null:
		return

	var direction := global_position.direction_to(_target.global_position)
	global_position += direction * MOVE_SPEED * delta

	_pattern_timer -= delta
	if _pattern_timer <= 0.0:
		_execute_pattern()
		_pattern_timer = PATTERN_INTERVAL


func take_damage(amount: float, knockback_force: float = 0.0, knockback_origin: Vector2 = Vector2.ZERO) -> void:
	current_hp -= amount
	DamageNumberManager.spawn_damage(amount, global_position)
	_flash_white()
	boss_hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		call_deferred("_die")


func _execute_pattern() -> void:
	var hp_ratio: float = current_hp / max_hp
	var new_phase: int = 1
	if hp_ratio <= 0.3:
		new_phase = 3
	elif hp_ratio <= 0.6:
		new_phase = 2
	if new_phase != _current_phase:
		_current_phase = new_phase
		boss_phase_changed.emit(new_phase)

	match _current_phase:
		1:
			_pattern_poison_clouds()
		2:
			_pattern_teleport_shoot()
		3:
			_pattern_poison_clouds()
			_pattern_barrage()


func _pattern_poison_clouds() -> void:
	if _target == null:
		return
	for i in range(POISON_CLOUD_COUNT):
		var offset := Vector2(randf_range(-60, 60), randf_range(-60, 60))
		var cloud_pos := _target.global_position + offset
		_spawn_poison_cloud(cloud_pos)


func _pattern_teleport_shoot() -> void:
	if _target == null:
		return
	var angle := randf() * TAU
	var new_pos := _target.global_position + Vector2.from_angle(angle) * TELEPORT_DISTANCE
	global_position = new_pos
	_flash_teleport()
	_shoot_bullets(BULLET_COUNT_P2)


func _pattern_barrage() -> void:
	_shoot_bullets(BULLET_COUNT_P3)


func _spawn_poison_cloud(pos: Vector2) -> void:
	var cloud := Area2D.new()
	cloud.collision_layer = 2
	cloud.collision_mask = 1
	cloud.global_position = pos

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = POISON_CLOUD_RADIUS
	shape.shape = circle
	cloud.add_child(shape)

	var vis_size := Vector2(POISON_CLOUD_RADIUS * 2, POISON_CLOUD_RADIUS * 2)
	var visual := ColorRect.new()
	visual.color = Color(0.15, 0.5, 0.2, 0.35)
	visual.size = vis_size
	visual.position = -vis_size / 2.0
	cloud.add_child(visual)

	var _hit_bodies: Dictionary = {}
	cloud.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("take_damage") and not _hit_bodies.has(body):
			_hit_bodies[body] = true
			body.take_damage(POISON_CLOUD_DAMAGE)
	)
	get_tree().current_scene.add_child(cloud)

	var tween := cloud.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, POISON_CLOUD_DURATION)
	tween.tween_callback(cloud.queue_free)


func _shoot_bullets(count: int) -> void:
	if _target == null:
		return
	var base_angle: float
	if count <= BULLET_COUNT_P2:
		base_angle = global_position.angle_to_point(_target.global_position) + PI
	else:
		base_angle = randf() * TAU

	for i in range(count):
		var angle := base_angle + TAU / count * i
		var dir := Vector2.from_angle(angle)
		_spawn_bullet(global_position, dir)


func _spawn_bullet(pos: Vector2, direction: Vector2) -> void:
	var bullet := Area2D.new()
	bullet.collision_layer = 2
	bullet.collision_mask = 1
	bullet.global_position = pos

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	bullet.add_child(shape)

	var visual := ColorRect.new()
	visual.color = Color(0.3, 0.8, 0.2, 1)
	visual.size = Vector2(8, 8)
	visual.position = Vector2(-4, -4)
	bullet.add_child(visual)

	bullet.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("take_damage"):
			body.take_damage(BULLET_DAMAGE)
			bullet.queue_free()
	)
	get_tree().current_scene.add_child(bullet)

	var tween := bullet.create_tween()
	var end_pos := pos + direction * 200.0
	tween.tween_property(bullet, "global_position", end_pos, 200.0 / BULLET_SPEED)
	tween.tween_callback(bullet.queue_free)


func _die() -> void:
	DropManager.spawn_xp_gem(global_position, XP_REWARD)
	boss_died.emit()
	_is_active = false
	visible = false
	if _collision != null:
		_collision.set_deferred("disabled", true)
	if is_in_group("enemies"):
		remove_from_group("enemies")


func _flash_white() -> void:
	if _placeholder == null:
		return
	_placeholder.modulate = Color(5, 5, 5, 1)
	get_tree().create_timer(0.08).timeout.connect(
		func() -> void:
			if _is_active and _placeholder != null:
				_placeholder.modulate = Color(1, 1, 1, 1)
	)


func _flash_teleport() -> void:
	if _placeholder == null:
		return
	_placeholder.modulate = Color(1.5, 3, 1.5, 1)
	get_tree().create_timer(0.15).timeout.connect(
		func() -> void:
			if _is_active and _placeholder != null:
				_placeholder.modulate = Color(1, 1, 1, 1)
	)


func _cache_nodes() -> void:
	if _placeholder == null:
		_placeholder = get_node_or_null("Placeholder")
	if _collision == null:
		_collision = get_node_or_null("CollisionShape2D")
