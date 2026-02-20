extends Area2D
## 기본 적 엔티티. EnemyData 리소스를 주입받아 동작한다.
## Area2D 기반 (CharacterBody2D보다 가벼움, CLAUDE.md 8.6절).


signal died(enemy: Area2D)

const POISON_INTERVAL: float = 1.5
const POISON_PUDDLE_LIFETIME: float = 3.2
const POISON_TICK_INTERVAL: float = 0.8
const POISON_DAMAGE: float = 3.0
const POISON_RADIUS: float = 10.0
const AURA_INTERVAL: float = 1.0
const AURA_RADIUS: float = 48.0
const DEATH_PARTICLE_TEXTURE: Texture2D = preload("res://assets/particles/death_particle.png")
const AURA_BUFF: float = 1.5
const SPLIT_COUNT: int = 3

var data: EnemyData
var current_hp: float
var contact_damage_multiplier: float = 1.0
var _target: Node2D = null
var _is_active: bool = false
var _attack_timer: float = 0.0
var _ability_timer: float = 0.0
var _placeholder: Sprite2D
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
	_attack_timer = data.attack_interval
	_ability_timer = 0.0
	contact_damage_multiplier = 1.0
	visible = true
	_cache_nodes()
	_collision.set_deferred("disabled", false)
	add_to_group("enemies")
	_apply_visuals()
	_update_aura_visual()


## 풀에 반환할 때 호출한다.
func deactivate() -> void:
	_is_active = false
	visible = false
	if _collision != null:
		_collision.set_deferred("disabled", true)
	_target = null
	if is_in_group("enemies"):
		remove_from_group("enemies")
	var aura := get_node_or_null("AuraVisual")
	if aura != null:
		aura.visible = false


func _physics_process(delta: float) -> void:
	if not _is_active or _target == null:
		return

	if not data.is_stationary:
		var direction := global_position.direction_to(_target.global_position)
		global_position += direction * data.move_speed * delta

	if data.attack_interval > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = data.attack_interval
			_ground_attack()

	if data.ability_type != "":
		_process_ability(delta)


func _process_ability(delta: float) -> void:
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	match data.ability_type:
		"poison_trail":
			_spawn_poison_puddle()
			_ability_timer = POISON_INTERVAL
		"damage_aura":
			_apply_damage_aura()
			_ability_timer = AURA_INTERVAL


func take_damage(amount: float, knockback_force: float = 0.0, knockback_origin: Vector2 = Vector2.ZERO) -> void:
	current_hp -= amount
	_flash_white()
	DamageNumberManager.spawn_damage(amount, global_position)
	if knockback_force > 0.0 and knockback_origin != Vector2.ZERO:
		var direction: Vector2 = knockback_origin.direction_to(global_position)
		global_position += direction * knockback_force
	if current_hp <= 0.0:
		call_deferred("_die")


func _ground_attack() -> void:
	if _target == null or data.attack_range <= 0.0:
		return
	var dist: float = global_position.distance_to(_target.global_position)
	if dist > data.attack_range * 1.5:
		return
	var wave := Area2D.new()
	wave.collision_layer = 2
	wave.collision_mask = 1
	wave.global_position = global_position
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = data.attack_range
	shape.shape = circle
	wave.add_child(shape)
	var vis_size := Vector2(data.attack_range * 2, data.attack_range * 2)
	var visual := ColorRect.new()
	visual.color = Color(data.sprite_color, 0.3)
	visual.size = vis_size
	visual.position = -vis_size / 2.0
	wave.add_child(visual)
	get_tree().current_scene.add_child(wave)
	var tween := wave.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.6)
	tween.tween_callback(wave.queue_free)


func _die() -> void:
	_spawn_death_particles()
	DropManager.spawn_xp_gem(global_position, data.xp_reward)
	if data.ability_type == "split_on_death":
		_split_on_death()
	died.emit(self)
	deactivate()


## 독 웅덩이를 현재 위치에 생성한다. 일정 시간 동안 접촉한 플레이어에게 데미지를 준다.
func _spawn_poison_puddle() -> void:
	var puddle := Node2D.new()
	puddle.global_position = global_position

	var visual := ColorRect.new()
	visual.color = Color(0.3, 0.75, 0.1, 0.3)
	var puddle_size := Vector2(20, 20)
	visual.size = puddle_size
	visual.position = -puddle_size / 2.0
	puddle.add_child(visual)

	get_tree().current_scene.add_child(puddle)

	var target_ref: Node2D = _target
	var tween := puddle.create_tween()
	var ticks: int = int(POISON_PUDDLE_LIFETIME / POISON_TICK_INTERVAL)
	for i in range(ticks):
		tween.tween_interval(POISON_TICK_INTERVAL)
		tween.tween_callback(func() -> void:
			if is_instance_valid(target_ref) and is_instance_valid(puddle):
				if puddle.global_position.distance_to(target_ref.global_position) <= POISON_RADIUS:
					target_ref.take_damage(POISON_DAMAGE)
		)
	tween.tween_property(visual, "modulate:a", 0.0, 0.5)
	tween.tween_callback(puddle.queue_free)


## 사망 시 소형 적 3마리로 분열한다.
func _split_on_death() -> void:
	var mini_data := _create_mini_data()
	for i in range(SPLIT_COUNT):
		var offset := Vector2.from_angle(TAU / float(SPLIT_COUNT) * i) * 10.0
		SpawnManager.spawn_enemy_at(mini_data, global_position + offset)


func _create_mini_data() -> EnemyData:
	var mini := EnemyData.new()
	mini.enemy_name = data.enemy_name + " 조각"
	mini.max_hp = maxf(data.max_hp * 0.25, 3.0)
	mini.move_speed = data.move_speed * 1.3
	mini.contact_damage = maxf(data.contact_damage * 0.4, 2.0)
	mini.xp_reward = 2
	mini.sprite_color = data.sprite_color.lightened(0.2)
	mini.sprite_size = (data.sprite_size * 0.5).round()
	mini.sprite_path = data.sprite_path
	return mini


## 주변 적의 접촉 데미지를 강화한다.
func _apply_damage_aura() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node in enemies:
		if enemy == self or not (enemy is Area2D):
			continue
		if enemy.global_position.distance_to(global_position) <= AURA_RADIUS:
			enemy.contact_damage_multiplier = AURA_BUFF


## 데미지 오라 시각 효과를 관리한다.
func _update_aura_visual() -> void:
	var aura := get_node_or_null("AuraVisual")
	if data.ability_type == "damage_aura":
		if aura == null:
			aura = ColorRect.new()
			aura.name = "AuraVisual"
			aura.color = Color(1, 0.4, 0.15, 0.15)
			var aura_size := Vector2(96, 96)
			aura.size = aura_size
			aura.position = -aura_size / 2.0
			aura.z_index = -1
			add_child(aura)
		else:
			aura.visible = true
	elif aura != null:
		aura.visible = false


func _spawn_death_particles() -> void:
	for i in range(4):
		var particle := Sprite2D.new()
		particle.texture = DEATH_PARTICLE_TEXTURE
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
	if data.sprite_path != "":
		_placeholder.texture = load(data.sprite_path)
	_placeholder.modulate = Color(1, 1, 1, 1)
	var shape := _collision.shape as RectangleShape2D
	shape.size = data.sprite_size * 0.8


func _flash_white() -> void:
	if _placeholder == null:
		return
	_placeholder.modulate = Color(5, 5, 5, 1)
	get_tree().create_timer(0.08).timeout.connect(
		func() -> void:
			if _is_active and data != null and _placeholder != null:
				_placeholder.modulate = Color(1, 1, 1, 1)
	)
