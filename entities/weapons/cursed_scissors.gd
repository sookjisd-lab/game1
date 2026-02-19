extends WeaponBase
## 저주받은 가위: 가장 가까운 적 방향으로 부채꼴 베기 공격.


const HIT_DURATION: float = 0.15


func _attack() -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return

	var direction: Vector2 = global_position.direction_to(target.global_position)
	_create_slash(direction)


func _create_slash(direction: Vector2) -> void:
	var atk_range: float = get_effective_range()
	var slash := Area2D.new()
	slash.collision_layer = 4
	slash.collision_mask = 2
	slash.global_position = global_position + direction * (atk_range * 0.5)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(atk_range, atk_range * 0.6)
	shape.shape = rect
	shape.rotation = direction.angle()
	slash.add_child(shape)

	var visual := ColorRect.new()
	visual.color = Color(data.projectile_color, 0.7)
	visual.size = Vector2(atk_range, atk_range * 0.6)
	visual.position = -visual.size / 2.0
	visual.rotation = direction.angle()
	slash.add_child(visual)

	get_tree().current_scene.add_child(slash)

	var effective_damage: float = calc_final_damage()
	var kb: float = data.knockback
	var origin: Vector2 = global_position
	slash.area_entered.connect(
		func(area: Area2D) -> void:
			if area.has_method("take_damage"):
				area.take_damage(effective_damage, kb, origin)
	)

	# 짧은 시간 후 제거
	get_tree().create_timer(HIT_DURATION).timeout.connect(slash.queue_free)
