extends WeaponBase
## 정화의 불꽃: 유령 양초 진화형. 3발 동시 유도 + 착탄 시 범위 폭발.


const FLAME_SPEED: float = 110.0
const FLAME_SIZE: Vector2 = Vector2(8, 8)
const FLAME_LIFETIME: float = 3.5
const TURN_RATE: float = 3.5
const FLAME_COUNT: int = 3
const EXPLOSION_RADIUS: float = 24.0

var _flames: Array[Dictionary] = []


func _attack() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	enemies.shuffle()
	for i in range(mini(FLAME_COUNT, enemies.size())):
		_spawn_flame(enemies[i] as Area2D)
	if enemies.size() < FLAME_COUNT:
		for i in range(FLAME_COUNT - enemies.size()):
			_spawn_flame(enemies[0] as Area2D)


func _process(delta: float) -> void:
	if data == null:
		return

	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_attack()
		var cd_mult: float = _owner_node.cooldown_multiplier if _owner_node else 1.0
		_cooldown_timer = get_effective_cooldown() * cd_mult

	_update_flames(delta)


func _spawn_flame(target: Area2D) -> void:
	var flame := Area2D.new()
	flame.collision_layer = 4
	flame.collision_mask = 2

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	flame.add_child(shape)

	var visual := ColorRect.new()
	visual.color = data.projectile_color
	visual.size = FLAME_SIZE
	visual.position = -FLAME_SIZE / 2.0
	flame.add_child(visual)

	flame.global_position = global_position
	get_tree().current_scene.add_child(flame)

	var effective_damage: float = calc_final_damage()
	var kb: float = data.knockback

	flame.area_entered.connect(
		func(area: Area2D) -> void:
			if area.has_method("take_damage"):
				area.take_damage(effective_damage, kb, flame.global_position)
				_explode_at(flame.global_position, effective_damage * 0.5, kb)
				flame.queue_free()
	)

	var direction: Vector2 = global_position.direction_to(target.global_position)
	_flames.append({
		"node": flame,
		"target": target,
		"direction": direction,
		"lifetime": FLAME_LIFETIME,
	})


func _explode_at(pos: Vector2, dmg: float, kb: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node in enemies:
		if enemy is Area2D and enemy.has_method("take_damage"):
			if pos.distance_to(enemy.global_position) <= EXPLOSION_RADIUS:
				enemy.take_damage(dmg, kb, pos)


func _update_flames(delta: float) -> void:
	for i in range(_flames.size() - 1, -1, -1):
		var info: Dictionary = _flames[i]
		var flame: Area2D = info["node"]

		if not is_instance_valid(flame) or not flame.is_inside_tree():
			_flames.remove_at(i)
			continue

		info["lifetime"] -= delta
		if info["lifetime"] <= 0.0:
			flame.queue_free()
			_flames.remove_at(i)
			continue

		var target: Area2D = info["target"]
		var direction: Vector2 = info["direction"]

		if is_instance_valid(target) and target.visible:
			var desired: Vector2 = flame.global_position.direction_to(target.global_position)
			direction = direction.lerp(desired, TURN_RATE * delta).normalized()
			info["direction"] = direction

		flame.global_position += direction * FLAME_SPEED * delta
