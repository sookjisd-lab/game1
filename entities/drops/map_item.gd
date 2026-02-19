extends Area2D
## 맵 드롭 아이템 (빵, 자석, 종 등). 플레이어 접촉 시 효과 발동.


signal picked_up(item: Area2D)

var item_type: String = ""
var _is_active: bool = false
var _visual: ColorRect
var _collision: CollisionShape2D

const PICKUP_DISTANCE: float = 12.0
const ITEM_CONFIGS: Dictionary = {
	"heal_bread": { "color": Color(0.96, 0.87, 0.5, 1), "size": Vector2(10, 10) },
	"magnet_charm": { "color": Color(0.45, 0.55, 0.95, 1), "size": Vector2(10, 10) },
	"purify_bell": { "color": Color(0.9, 0.85, 0.3, 1), "size": Vector2(10, 10) },
	"gold_pouch": { "color": Color(1.0, 0.84, 0.0, 1), "size": Vector2(10, 10) },
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
	_visual.color = config["color"]
	var item_size: Vector2 = config["size"]
	_visual.size = item_size
	_visual.position = -item_size / 2.0


func _cache_nodes() -> void:
	if _visual == null:
		_visual = get_node_or_null("Visual")
	if _collision == null:
		_collision = get_node_or_null("CollisionShape2D")
