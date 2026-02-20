extends Area2D
## 맵 드롭 아이템 (빵, 자석, 종 등). 플레이어 접촉 시 효과 발동.


signal picked_up(item: Area2D)

var item_type: String = ""
var _is_active: bool = false
var _visual: Sprite2D
var _collision: CollisionShape2D

const PICKUP_DISTANCE: float = 12.0
const ITEM_CONFIGS: Dictionary = {
	"heal_bread": { "sprite_path": "res://assets/drops/heal_bread.png" },
	"magnet_charm": { "sprite_path": "res://assets/drops/magnet_charm.png" },
	"purify_bell": { "sprite_path": "res://assets/drops/purify_bell.png" },
	"gold_pouch": { "sprite_path": "res://assets/drops/gold_pouch.png" },
	"treasure_chest": { "sprite_path": "res://assets/drops/treasure_chest.png" },
}


func _ready() -> void:
	_cache_nodes()


func activate(type: String, spawn_position: Vector2) -> void:
	item_type = type
	global_position = spawn_position
	_is_active = true
	visible = true
	_cache_nodes()
	if _collision != null:
		_collision.set_deferred("disabled", false)
	_apply_visuals()


func deactivate() -> void:
	_is_active = false
	visible = false
	if _collision != null:
		_collision.set_deferred("disabled", true)


func _apply_visuals() -> void:
	if _visual == null:
		return
	var config: Dictionary = ITEM_CONFIGS.get(item_type, ITEM_CONFIGS["heal_bread"])
	_visual.texture = load(config["sprite_path"])


func _cache_nodes() -> void:
	if _visual == null:
		_visual = get_node_or_null("Visual")
	if _collision == null:
		_collision = get_node_or_null("CollisionShape2D")
