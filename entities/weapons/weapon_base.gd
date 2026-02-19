class_name WeaponBase
extends Node2D
## 모든 무기의 기본 클래스. 쿨다운 관리와 가장 가까운 적 탐색을 담당한다.


var data: WeaponData
var level: int = 1
var _cooldown_timer: float = 0.0
var _owner_node: Node2D = null


const DAMAGE_PER_LEVEL: float = 0.15
const COOLDOWN_PER_LEVEL: float = 0.05
const RANGE_PER_LEVEL: float = 0.10


func initialize(weapon_data: WeaponData, owner: Node2D) -> void:
	data = weapon_data
	_owner_node = owner
	_cooldown_timer = 0.0


func level_up() -> void:
	if level >= data.max_level:
		return
	level += 1


func get_effective_damage() -> float:
	var mult: float = 1.0 + DAMAGE_PER_LEVEL * (level - 1)
	return data.damage * mult


func calc_final_damage() -> float:
	var base: float = get_effective_damage() * _owner_node.damage_multiplier
	if _owner_node.crit_chance > 0.0 and randf() < _owner_node.crit_chance:
		return base * 1.5
	return base


func get_effective_cooldown() -> float:
	var mult: float = 1.0 - COOLDOWN_PER_LEVEL * (level - 1)
	return data.cooldown * maxf(mult, 0.3)


func get_effective_range() -> float:
	var level_mult: float = 1.0 + RANGE_PER_LEVEL * (level - 1)
	var owner_mult: float = _owner_node.range_multiplier if _owner_node else 1.0
	return data.attack_range * level_mult * owner_mult


func _process(delta: float) -> void:
	if data == null:
		return
	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_attack()
		var cd_mult: float = _owner_node.cooldown_multiplier if _owner_node else 1.0
		_cooldown_timer = get_effective_cooldown() * cd_mult


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
