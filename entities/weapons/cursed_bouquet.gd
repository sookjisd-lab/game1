extends WeaponBase
## 저주받은 꽃다발: 가장 가까운 적 방향으로 관통 독구름을 발사한다.


const CLOUD_SPEED: float = 70.0
const CLOUD_SIZE: Vector2 = Vector2(14, 14)
const CLOUD_LIFETIME: float = 2.0
const TICK_INTERVAL: float = 0.3
const PROJ_TEXTURE: Texture2D = preload("res://assets/weapons/proj_bouquet.png")


func _attack() -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	var direction: Vector2 = global_position.direction_to(target.global_position)
	_spawn_cloud(direction)


func _spawn_cloud(direction: Vector2) -> void:
	var cloud := Area2D.new()
	cloud.collision_layer = 4
	cloud.collision_mask = 2

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	cloud.add_child(shape)

	var visual := Sprite2D.new()
	visual.texture = PROJ_TEXTURE
	visual.modulate = Color(1, 1, 1, 0.6)
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
