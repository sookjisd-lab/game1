extends WeaponBase
## 저주받은 성경: 플레이어 주위를 회전하는 오브젝트가 적에게 데미지를 준다.


const ORB_COUNT: int = 2
const ROTATION_SPEED: float = 2.5
const ORB_SIZE: Vector2 = Vector2(10, 10)
const HIT_COOLDOWN: float = 0.5

var _angle: float = 0.0
var _orbs: Array[Area2D] = []
var _hit_timers: Dictionary = {}


func initialize(weapon_data: WeaponData, owner: Node2D) -> void:
	super.initialize(weapon_data, owner)
	_create_orbs()


func _create_orbs() -> void:
	for i in range(ORB_COUNT):
		var orb := Area2D.new()
		orb.collision_layer = 4
		orb.collision_mask = 2

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = ORB_SIZE
		shape.shape = rect
		orb.add_child(shape)

		var visual := ColorRect.new()
		visual.color = data.projectile_color
		visual.size = ORB_SIZE
		visual.position = -ORB_SIZE / 2.0
		orb.add_child(visual)

		orb.area_entered.connect(_on_orb_hit)
		add_child(orb)
		_orbs.append(orb)


func _process(delta: float) -> void:
	if data == null or _owner_node == null:
		return
	_angle += ROTATION_SPEED * delta
	_update_orb_positions()
	_update_hit_timers(delta)


func _attack() -> void:
	pass


func _update_orb_positions() -> void:
	var radius: float = data.attack_range
	for i in range(_orbs.size()):
		var offset_angle: float = _angle + (TAU / _orbs.size()) * i
		_orbs[i].position = Vector2(
			cos(offset_angle) * radius,
			sin(offset_angle) * radius,
		)


func _on_orb_hit(area: Area2D) -> void:
	if not area.has_method("take_damage"):
		return
	var id: int = area.get_instance_id()
	if _hit_timers.has(id):
		return
	var effective_damage: float = data.damage * _owner_node.damage_multiplier
	area.take_damage(effective_damage)
	_hit_timers[id] = HIT_COOLDOWN


func _update_hit_timers(delta: float) -> void:
	var expired: Array = []
	for id: int in _hit_timers:
		_hit_timers[id] -= delta
		if _hit_timers[id] <= 0.0:
			expired.append(id)
	for id: int in expired:
		_hit_timers.erase(id)
