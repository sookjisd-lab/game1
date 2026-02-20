extends WeaponBase
## 시공의 톱니: 시계 톱니바퀴 진화형. 5개 기어 + 빠른 회전 + 넓은 궤도.


const GEAR_COUNT: int = 5
const ROTATION_SPEED: float = 4.5
const GEAR_SIZE: Vector2 = Vector2(12, 12)
const HIT_COOLDOWN: float = 0.3

var _angle: float = 0.0
var _gears: Array[Area2D] = []
var _hit_timers: Dictionary = {}


func initialize(weapon_data: WeaponData, owner: Node2D) -> void:
	super.initialize(weapon_data, owner)
	_create_gears()


func _create_gears() -> void:
	for i in range(GEAR_COUNT):
		var gear := Area2D.new()
		gear.collision_layer = 4
		gear.collision_mask = 2

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = GEAR_SIZE
		shape.shape = rect
		gear.add_child(shape)

		var visual := ColorRect.new()
		visual.color = data.projectile_color
		visual.size = GEAR_SIZE
		visual.position = -GEAR_SIZE / 2.0
		gear.add_child(visual)

		gear.area_entered.connect(_on_gear_hit)
		add_child(gear)
		_gears.append(gear)


func _process(delta: float) -> void:
	if data == null or _owner_node == null:
		return
	_angle += ROTATION_SPEED * delta
	_update_gear_positions()
	_update_hit_timers(delta)


func _attack() -> void:
	pass


func _update_gear_positions() -> void:
	var radius: float = get_effective_range()
	for i in range(_gears.size()):
		var offset_angle: float = _angle + (TAU / _gears.size()) * i
		_gears[i].position = Vector2(
			cos(offset_angle) * radius,
			sin(offset_angle) * radius,
		)


func _on_gear_hit(area: Area2D) -> void:
	if not area.has_method("take_damage"):
		return
	var id: int = area.get_instance_id()
	if _hit_timers.has(id):
		return
	var effective_damage: float = calc_final_damage()
	area.take_damage(effective_damage, data.knockback, _owner_node.global_position)
	_hit_timers[id] = HIT_COOLDOWN


func _update_hit_timers(delta: float) -> void:
	var expired: Array = []
	for id: int in _hit_timers:
		_hit_timers[id] -= delta
		if _hit_timers[id] <= 0.0:
			expired.append(id)
	for id: int in expired:
		_hit_timers.erase(id)
