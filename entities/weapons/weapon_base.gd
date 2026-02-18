class_name WeaponBase
extends Node2D
## 모든 무기의 기본 클래스. 쿨다운 관리와 가장 가까운 적 탐색을 담당한다.


var data: WeaponData
var level: int = 1
var _cooldown_timer: float = 0.0
var _owner_node: Node2D = null


func initialize(weapon_data: WeaponData, owner: Node2D) -> void:
	data = weapon_data
	_owner_node = owner
	_cooldown_timer = 0.0


func _process(delta: float) -> void:
	if data == null:
		return
	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_attack()
		var cd_mult: float = _owner_node.cooldown_multiplier if _owner_node else 1.0
		_cooldown_timer = data.cooldown * cd_mult


## 서브클래스에서 오버라이드한다.
func _attack() -> void:
	pass


func _find_nearest_enemy() -> Area2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var nearest: Area2D = null
	var nearest_dist := INF

	for enemy: Node in enemies:
		if enemy is Area2D:
			var dist: float = global_position.distance_squared_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

	return nearest
