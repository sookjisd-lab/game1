extends Node
## 적 사망 시 드롭 생성, 마그넷 흡수 로직, 맵 아이템을 담당한다.
## Autoload 싱글톤: DropManager


signal xp_collected(amount: int)
signal treasure_chest_collected
signal gold_collected(amount: int)

const XP_GEM_SCENE: PackedScene = preload("res://entities/drops/xp_gem.tscn")
const MAP_ITEM_SCENE: PackedScene = preload("res://entities/drops/map_item.tscn")

const GEM_SMALL := { "sprite_path": "res://assets/drops/xp_gem_small.png" }
const GEM_MEDIUM := { "sprite_path": "res://assets/drops/xp_gem_medium.png" }
const GEM_LARGE := { "sprite_path": "res://assets/drops/xp_gem_large.png" }

const MAP_ITEM_DROP_CHANCE: float = 0.03
const MAP_ITEM_TYPES: Array[String] = ["heal_bread", "magnet_charm", "purify_bell", "gold_pouch"]
const ELITE_CHEST_CHANCE: float = 0.25
const MAP_ITEM_PICKUP_DIST: float = 12.0
const HEAL_AMOUNT: float = 30.0
const PURIFY_DAMAGE: float = 30.0
const GOLD_POUCH_AMOUNT: int = 25

var _player: Node2D = null
var _stage: Node2D = null
var _active_gems: Array[Area2D] = []
var _active_items: Array[Area2D] = []
var total_xp: int = 0


func register(stage: Node2D, player: Node2D) -> void:
	_stage = stage
	_player = player


func spawn_xp_gem(position: Vector2, value: int) -> void:
	if _stage == null:
		return

	var gem: Area2D = PoolManager.acquire(XP_GEM_SCENE)
	if gem.get_parent() == null:
		_stage.add_child(gem)

	var tier: Dictionary = _get_gem_tier(value)
	gem.activate(value, position, tier["sprite_path"])
	_active_gems.append(gem)

	_try_spawn_map_item(position)


func _try_spawn_map_item(position: Vector2) -> void:
	var drop_chance: float = MAP_ITEM_DROP_CHANCE + GameManager.get_meta_bonus_drop()
	if randf() > drop_chance:
		return
	var item_type: String = MAP_ITEM_TYPES.pick_random()
	var offset := Vector2(randf_range(-8, 8), randf_range(-8, 8))
	_spawn_map_item(item_type, position + offset)


func _spawn_map_item(item_type: String, position: Vector2) -> void:
	if _stage == null:
		return
	var item: Area2D = PoolManager.acquire(MAP_ITEM_SCENE)
	if item.get_parent() == null:
		_stage.add_child(item)
	item.activate(item_type, position)
	_active_items.append(item)


func _get_gem_tier(xp_value: int) -> Dictionary:
	if xp_value >= 20:
		return GEM_LARGE
	elif xp_value >= 5:
		return GEM_MEDIUM
	return GEM_SMALL


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)


func _process(_delta: float) -> void:
	if _player == null:
		return
	_check_magnet_range()
	_check_item_pickup()


func _check_magnet_range() -> void:
	var magnet_radius: float = _player.magnet_radius
	for gem: Area2D in _active_gems:
		if not gem.visible:
			continue
		if gem._being_attracted:
			continue
		var dist := gem.global_position.distance_to(_player.global_position)
		if dist <= magnet_radius:
			gem.start_attract(_player)
			gem.collected.connect(
				_on_gem_collected, CONNECT_ONE_SHOT
			)


func _check_item_pickup() -> void:
	for i in range(_active_items.size() - 1, -1, -1):
		var item: Area2D = _active_items[i]
		if not item.visible:
			continue
		var dist := item.global_position.distance_to(_player.global_position)
		if dist <= MAP_ITEM_PICKUP_DIST:
			_apply_item_effect(item.item_type)
			item.deactivate()
			_active_items.remove_at(i)
			PoolManager.release(MAP_ITEM_SCENE, item)


func spawn_treasure_chest(position: Vector2) -> void:
	_spawn_map_item("treasure_chest", position)


func _apply_item_effect(item_type: String) -> void:
	match item_type:
		"heal_bread":
			_player.current_hp = minf(_player.current_hp + HEAL_AMOUNT, _player.max_hp)
			_player.hp_changed.emit(_player.current_hp, _player.max_hp)
			DamageNumberManager.spawn_heal(HEAL_AMOUNT, _player.global_position)
			AudioManager.play_sfx("res://assets/audio/sfx/heal.wav")
		"magnet_charm":
			_attract_all_gems()
			AudioManager.play_sfx("res://assets/audio/sfx/item_pickup.wav")
		"purify_bell":
			_damage_all_visible_enemies()
			AudioManager.play_sfx("res://assets/audio/sfx/item_pickup.wav")
		"gold_pouch":
			GameManager.meta.memory_shards += GOLD_POUCH_AMOUNT
			gold_collected.emit(GOLD_POUCH_AMOUNT)
			AudioManager.play_sfx("res://assets/audio/sfx/item_pickup.wav")
		"treasure_chest":
			AudioManager.play_sfx("res://assets/audio/sfx/chest_open.wav")
			treasure_chest_collected.emit()


func _attract_all_gems() -> void:
	for gem: Area2D in _active_gems:
		if gem.visible and not gem._being_attracted:
			gem.start_attract(_player)
			gem.collected.connect(_on_gem_collected, CONNECT_ONE_SHOT)


func _damage_all_visible_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node in enemies:
		if enemy is Area2D and enemy.has_method("take_damage"):
			enemy.take_damage(PURIFY_DAMAGE)


func _on_gem_collected(gem: Area2D) -> void:
	total_xp += gem.xp_value
	xp_collected.emit(gem.xp_value)
	AudioManager.play_sfx("res://assets/audio/sfx/gem_pickup.wav")
	_active_gems.erase(gem)
	PoolManager.release(XP_GEM_SCENE, gem)


func clear_all() -> void:
	for gem: Area2D in _active_gems.duplicate():
		gem.deactivate()
		PoolManager.release(XP_GEM_SCENE, gem)
	_active_gems.clear()
	for item: Area2D in _active_items.duplicate():
		item.deactivate()
		PoolManager.release(MAP_ITEM_SCENE, item)
	_active_items.clear()
	total_xp = 0


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if new_state == Enums.GameState.MENU:
		clear_all()
		_player = null
		_stage = null
