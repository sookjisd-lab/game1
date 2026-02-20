extends WeaponBase
## 환영의 거울: 깨진 거울 파편 진화형. 3발 동시 + 반사 5회 + 관통.


const SHARD_SPEED: float = 130.0
const SHARD_SIZE: Vector2 = Vector2(6, 6)
const SHARD_LIFETIME: float = 4.0
const MAX_BOUNCES: int = 5
const SHARD_COUNT: int = 3
const PROJ_TEXTURE: Texture2D = preload("res://assets/weapons/proj_mirror.png")

var _shards: Array[Dictionary] = []


func _attack() -> void:
	for i in range(SHARD_COUNT):
		var angle: float = randf() * TAU
		_spawn_shard(Vector2.from_angle(angle))


func _process(delta: float) -> void:
	if data == null:
		return

	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_attack()
		var cd_mult: float = _owner_node.cooldown_multiplier if _owner_node else 1.0
		_cooldown_timer = get_effective_cooldown() * cd_mult

	_update_shards(delta)


func _spawn_shard(direction: Vector2) -> void:
	var shard := Area2D.new()
	shard.collision_layer = 4
	shard.collision_mask = 2

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SHARD_SIZE
	shape.shape = rect
	shard.add_child(shape)

	var visual := Sprite2D.new()
	visual.texture = PROJ_TEXTURE
	shard.add_child(visual)

	shard.global_position = global_position
	get_tree().current_scene.add_child(shard)

	var effective_damage: float = calc_final_damage()
	var kb: float = data.knockback
	var hit_set: Dictionary = {}

	shard.area_entered.connect(
		func(area: Area2D) -> void:
			if area.has_method("take_damage"):
				var id: int = area.get_instance_id()
				if not hit_set.has(id):
					hit_set[id] = true
					area.take_damage(effective_damage, kb, shard.global_position)
	)

	_shards.append({
		"node": shard,
		"direction": direction,
		"lifetime": SHARD_LIFETIME,
		"bounces": 0,
	})


func _update_shards(delta: float) -> void:
	var player_pos: Vector2 = _owner_node.global_position if _owner_node else Vector2.ZERO
	var half_w: float = Constants.VIEWPORT_WIDTH / 2.0
	var half_h: float = Constants.VIEWPORT_HEIGHT / 2.0

	for i in range(_shards.size() - 1, -1, -1):
		var info: Dictionary = _shards[i]
		var shard: Area2D = info["node"]

		if not is_instance_valid(shard) or not shard.is_inside_tree():
			_shards.remove_at(i)
			continue

		info["lifetime"] -= delta
		if info["lifetime"] <= 0.0:
			shard.queue_free()
			_shards.remove_at(i)
			continue

		var direction: Vector2 = info["direction"]
		shard.global_position += direction * SHARD_SPEED * delta

		if info["bounces"] < MAX_BOUNCES:
			var rel: Vector2 = shard.global_position - player_pos
			var bounced := false
			if absf(rel.x) > half_w:
				direction.x = -direction.x
				bounced = true
			if absf(rel.y) > half_h:
				direction.y = -direction.y
				bounced = true
			if bounced:
				info["direction"] = direction
				info["bounces"] += 1
