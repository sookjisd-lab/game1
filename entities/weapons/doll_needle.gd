extends WeaponBase
## 인형의 바늘: 전방위로 바늘 투사체를 발사한다.


const NEEDLE_COUNT: int = 6
const NEEDLE_SPEED: float = 120.0
const NEEDLE_SIZE: Vector2 = Vector2(3, 8)
const NEEDLE_LIFETIME: float = 1.5
const PROJ_TEXTURE: Texture2D = preload("res://assets/weapons/proj_needle.png")


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

	var visual := Sprite2D.new()
	visual.texture = PROJ_TEXTURE
	visual.rotation = direction.angle() + PI / 2.0
	needle.add_child(visual)

	needle.global_position = global_position
	get_tree().current_scene.add_child(needle)

	var effective_damage: float = calc_final_damage()
	var kb: float = data.knockback

	needle.area_entered.connect(
		func(area: Area2D) -> void:
			if area.has_method("take_damage"):
				area.take_damage(effective_damage, kb, needle.global_position)
				needle.queue_free()
	)

	var end_pos: Vector2 = needle.global_position + direction * get_effective_range()
	var travel_time: float = get_effective_range() / NEEDLE_SPEED
	var tween := needle.create_tween()
	tween.tween_property(needle, "global_position", end_pos, travel_time)
	tween.tween_callback(needle.queue_free)
