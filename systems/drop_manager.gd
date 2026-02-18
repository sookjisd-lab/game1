extends Node
## 적 사망 시 드롭 생성, 마그넷 흡수 로직을 담당한다.
## Autoload 싱글톤: DropManager


signal xp_collected(amount: int)

const XP_GEM_SCENE: PackedScene = preload("res://entities/drops/xp_gem.tscn")
const GEM_SMALL := { "color": Color(0.45, 0.55, 0.95, 1), "size": Vector2(6, 6) }
const GEM_MEDIUM := { "color": Color(0.3, 0.85, 0.45, 1), "size": Vector2(8, 8) }
const GEM_LARGE := { "color": Color(0.9, 0.25, 0.25, 1), "size": Vector2(10, 10) }

var _player: Node2D = null
var _stage: Node2D = null
var _active_gems: Array[Area2D] = []
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
	gem.activate(value, position, tier["color"], tier["size"])
	_active_gems.append(gem)


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


func _on_gem_collected(gem: Area2D) -> void:
	total_xp += gem.xp_value
	xp_collected.emit(gem.xp_value)
	_active_gems.erase(gem)
	PoolManager.release(XP_GEM_SCENE, gem)


func clear_all() -> void:
	for gem: Area2D in _active_gems.duplicate():
		gem.deactivate()
		PoolManager.release(XP_GEM_SCENE, gem)
	_active_gems.clear()
	total_xp = 0


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if new_state == Enums.GameState.MENU:
		clear_all()
		_player = null
		_stage = null
