extends WeaponBase
## 인형술사의 비수: 인형의 바늘 진화형. 10방향 + 관통.


const NEEDLE_COUNT: int = 10
const NEEDLE_SPEED: float = 140.0
const NEEDLE_SIZE: Vector2 = Vector2(4, 10)


func _attack() -> void:
	for i in range(NEEDLE_COUNT):
		var angle: float = TAU / NEEDLE_COUNT * i
		var direction := Vector2.from_angle(angle)
		_spawn_needle(direction)


func _spawn_needle(direction: Vector2) -> void:
	var needle := Area2D.new()
	needle.collision_layer = 4
	needle.collision_mask = 2

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = NEEDLE_SIZE
	shape.shape = rect
	shape.rotation = direction.angle() + PI / 2.0
	needle.add_child(shape)

	var visual := ColorRect.new()
	visual.color = data.projectile_color
	visual.size = NEEDLE_SIZE
	visual.position = -NEEDLE_SIZE / 2.0
	visual.rotation = direction.angle() + PI / 2.0
	needle.add_child(visual)

	needle.global_position = global_position
	get_tree().current_scene.add_child(needle)

	var effective_damage: float = calc_final_damage()
	var kb: float = data.knockback
	var hit_set: Dictionary = {}

	needle.area_entered.connect(
		func(area: Area2D) -> void:
			if area.has_method("take_damage"):
				var id: int = area.get_instance_id()
				if not hit_set.has(id):
					hit_set[id] = true
					area.take_damage(effective_damage, kb, needle.global_position)
	)

	var end_pos: Vector2 = needle.global_position + direction * get_effective_range()
	var travel_time: float = get_effective_range() / NEEDLE_SPEED
	var tween := needle.create_tween()
	tween.tween_property(needle, "global_position", end_pos, travel_time)
	tween.tween_callback(needle.queue_free)
