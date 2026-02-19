extends Area2D
## 영주 그림홀트: 10분 등장 보스. 3페이즈 패턴.


signal boss_died
signal boss_hp_changed(current_hp: float, max_hp: float)

const SIZE: Vector2 = Vector2(64, 64)
const MOVE_SPEED: float = 20.0
const CHARGE_SPEED: float = 80.0
const CONTACT_DAMAGE: float = 20.0
const XP_REWARD: int = 50
const SHOCKWAVE_DAMAGE: float = 15.0
const SHOCKWAVE_RADIUS: float = 80.0
const SUMMON_COUNT: int = 4
const PATTERN_INTERVAL: float = 4.0

var max_hp: float = 300.0
var current_hp: float = 300.0
var _target: Node2D = null
var _is_active: bool = false
var _pattern_timer: float = 0.0
var _is_charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_timer: float = 0.0
var _placeholder: ColorRect
var _collision: CollisionShape2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_cache_nodes()


func activate(spawn_position: Vector2, target: Node2D) -> void:
	_target = target
	global_position = spawn_position
	current_hp = max_hp
	_is_active = true
	_is_charging = false
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
	_placeholder.color = Color(0.4, 0.15, 0.5, 1)
	_placeholder.size = SIZE
	_placeholder.position = -SIZE / 2.0
	var shape := _collision.shape as RectangleShape2D
	shape.size = SIZE * 0.8


func _physics_process(delta: float) -> void:
	if not _is_active or _target == null:
		return

	if _is_charging:
		global_position += _charge_direction * CHARGE_SPEED * delta
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_is_charging = false
	else:
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
	if hp_ratio > 0.6:
		_pattern_summon()
	elif hp_ratio > 0.3:
		_pattern_shockwave()
	else:
		_pattern_charge()
		if randf() < 0.5:
			_pattern_shockwave()


func _pattern_summon() -> void:
	for i in range(SUMMON_COUNT):
		var angle: float = TAU / SUMMON_COUNT * i
		var offset := Vector2.from_angle(angle) * 60.0
		var spawn_pos := global_position + offset
		var pool := SpawnManager._get_available_enemies()
		if not pool.is_empty():
			var enemy: Area2D = PoolManager.acquire(SpawnManager.ENEMY_SCENE)
			if enemy.get_parent() == null and SpawnManager._stage != null:
				SpawnManager._stage.add_child(enemy)
			enemy.activate(pool.pick_random(), spawn_pos, _target)
			enemy.died.connect(SpawnManager._on_enemy_died, CONNECT_ONE_SHOT)
			SpawnManager._active_enemies.append(enemy)


func _pattern_shockwave() -> void:
	var wave := Area2D.new()
	wave.collision_layer = 2
	wave.collision_mask = 1
	wave.global_position = global_position

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = SHOCKWAVE_RADIUS
	shape.shape = circle
	wave.add_child(shape)

	var visual := ColorRect.new()
	var vis_size := Vector2(SHOCKWAVE_RADIUS * 2, SHOCKWAVE_RADIUS * 2)
	visual.color = Color(0.6, 0.2, 0.8, 0.4)
	visual.size = vis_size
	visual.position = -vis_size / 2.0
	wave.add_child(visual)

	get_tree().current_scene.add_child(wave)

	var tween := wave.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.5)
	tween.tween_callback(wave.queue_free)


func _pattern_charge() -> void:
	if _target == null:
		return
	_is_charging = true
	_charge_direction = global_position.direction_to(_target.global_position)
	_charge_timer = 0.8


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
	_placeholder.color = Color.WHITE
	get_tree().create_timer(0.08).timeout.connect(
		func() -> void:
			if _is_active and _placeholder != null:
				_placeholder.color = Color(0.4, 0.15, 0.5, 1)
	)


func _cache_nodes() -> void:
	if _placeholder == null:
		_placeholder = get_node_or_null("Placeholder")
	if _collision == null:
		_collision = get_node_or_null("CollisionShape2D")
