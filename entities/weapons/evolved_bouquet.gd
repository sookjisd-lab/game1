extends WeaponBase
## 만개의 독포자: 저주받은 꽃다발 진화형. 3발 동시 독구름 + 큰 범위.


const CLOUD_SPEED: float = 75.0
const CLOUD_SIZE: Vector2 = Vector2(20, 20)
const CLOUD_LIFETIME: float = 2.5
const CLOUD_COUNT: int = 3
const SPREAD_ANGLE: float = PI / 8.0


func _attack() -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	var base_dir: Vector2 = global_position.direction_to(target.global_position)
	for i in range(CLOUD_COUNT):
		var offset: float = (i - 1) * SPREAD_ANGLE
		_spawn_cloud(base_dir.rotated(offset))


func _spawn_cloud(direction: Vector2) -> void:
	var cloud := Area2D.new()
	cloud.collision_layer = 4
	cloud.collision_mask = 2

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	cloud.add_child(shape)

	var visual := ColorRect.new()
	visual.color = Color(data.projectile_color, 0.6)
	visual.size = CLOUD_SIZE
	visual.position = -CLOUD_SIZE / 2.0
	cloud.add_child(visual)

	cloud.global_position = global_position
	get_tree().current_scene.add_child(cloud)

	var effective_damage: float = calc_final_damage()
	var kb: float = data.knockback
	var hit_enemies: Dictionary = {}

	cloud.area_entered.connect(
		func(area: Area2D) -> void:
			if area.has_method("take_damage"):
				var id: int = area.get_instance_id()
				if not hit_enemies.has(id):
					hit_enemies[id] = true
					area.take_damage(effective_damage, kb, cloud.global_position)
	)

	var tween := cloud.create_tween()
	tween.tween_property(
		cloud, "global_position",
		cloud.global_position + direction * CLOUD_SPEED * CLOUD_LIFETIME,
		CLOUD_LIFETIME
	)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, CLOUD_LIFETIME)
	tween.tween_callback(cloud.queue_free)
