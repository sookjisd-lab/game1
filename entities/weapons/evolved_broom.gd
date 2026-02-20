extends WeaponBase
## 생명의 빗자루: 마녀의 빗자루 진화형. 양방향 휩쓸기 + 넓은 범위.


const SWEEP_DURATION: float = 0.25
const SWEEP_WIDTH: float = 1.0
const HEAL_PER_HIT: float = 1.0

var _last_direction: Vector2 = Vector2.RIGHT


func _process(delta: float) -> void:
	if data == null or _owner_node == null:
		return

	var vel: Vector2 = _owner_node.velocity
	if vel.length_squared() > 1.0:
		_last_direction = vel.normalized()

	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_attack()
		var cd_mult: float = _owner_node.cooldown_multiplier if _owner_node else 1.0
		_cooldown_timer = get_effective_cooldown() * cd_mult


func _attack() -> void:
	_create_sweep(_last_direction)
	_create_sweep(-_last_direction)


func _create_sweep(direction: Vector2) -> void:
	var atk_range: float = get_effective_range()
	var sweep := Area2D.new()
	sweep.collision_layer = 4
	sweep.collision_mask = 2
	sweep.global_position = global_position + direction * (atk_range * 0.5)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(atk_range, atk_range * SWEEP_WIDTH)
	shape.shape = rect
	shape.rotation = direction.angle()
	sweep.add_child(shape)

	var visual := ColorRect.new()
	visual.color = Color(data.projectile_color, 0.7)
	visual.size = Vector2(atk_range, atk_range * SWEEP_WIDTH)
	visual.position = -visual.size / 2.0
	visual.rotation = direction.angle()
	sweep.add_child(visual)

	get_tree().current_scene.add_child(sweep)

	var effective_damage: float = calc_final_damage()
	var kb: float = data.knockback
	var origin: Vector2 = global_position
	var hit_set: Dictionary = {}
	var owner_ref: Node2D = _owner_node

	sweep.area_entered.connect(
		func(area: Area2D) -> void:
			if area.has_method("take_damage"):
				var id: int = area.get_instance_id()
				if not hit_set.has(id):
					hit_set[id] = true
					area.take_damage(effective_damage, kb, origin)
					if is_instance_valid(owner_ref):
						owner_ref.current_hp = minf(
							owner_ref.current_hp + HEAL_PER_HIT, owner_ref.max_hp
						)
						owner_ref.hp_changed.emit(owner_ref.current_hp, owner_ref.max_hp)
	)

	get_tree().create_timer(SWEEP_DURATION).timeout.connect(sweep.queue_free)
