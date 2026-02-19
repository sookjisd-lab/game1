extends CanvasLayer
## 화면 밖 적의 방향을 가장자리에 화살표로 표시한다.


const INDICATOR_SIZE: float = 6.0
const MARGIN: float = 8.0
const NORMAL_COLOR: Color = Color(0.5, 0.5, 0.5, 0.4)
const ELITE_COLOR: Color = Color(1.0, 0.85, 0.0, 0.8)
const BOSS_COLOR: Color = Color(1.0, 0.15, 0.15, 0.9)
const MAX_INDICATORS: int = 12

var _indicators: Array[ColorRect] = []
var _container: Control
var _player: Node2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()


func register_player(player: Node2D) -> void:
	_player = player


func _process(_delta: float) -> void:
	if _player == null or not AudioManager.indicator_enabled:
		_hide_all()
		return
	_update_indicators()


func _update_indicators() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var half_w: float = Constants.VIEWPORT_WIDTH / 2.0 - MARGIN
	var half_h: float = Constants.VIEWPORT_HEIGHT / 2.0 - MARGIN
	var cam_pos: Vector2 = _player.global_position

	var idx: int = 0
	for enemy: Node in enemies:
		if idx >= MAX_INDICATORS:
			break
		if not enemy is Area2D:
			continue
		var offset: Vector2 = enemy.global_position - cam_pos
		if absf(offset.x) <= half_w and absf(offset.y) <= half_h:
			continue

		var direction: Vector2 = offset.normalized()
		var edge_x: float = half_w if direction.x > 0 else -half_w
		var edge_y: float = half_h if direction.y > 0 else -half_h

		var t_x: float = INF
		var t_y: float = INF
		if absf(direction.x) > 0.001:
			t_x = edge_x / direction.x
		if absf(direction.y) > 0.001:
			t_y = edge_y / direction.y

		var t: float = minf(t_x, t_y)
		var screen_pos: Vector2 = direction * t
		screen_pos.x += Constants.VIEWPORT_WIDTH / 2.0
		screen_pos.y += Constants.VIEWPORT_HEIGHT / 2.0

		var indicator: ColorRect = _get_indicator(idx)
		indicator.visible = true
		indicator.position = screen_pos - Vector2(INDICATOR_SIZE / 2.0, INDICATOR_SIZE / 2.0)
		indicator.color = _get_enemy_color(enemy)
		idx += 1

	for i in range(idx, _indicators.size()):
		_indicators[i].visible = false


func _get_enemy_color(enemy: Node) -> Color:
	if enemy.has_method("is_boss_entity"):
		return BOSS_COLOR
	if enemy.has_meta("is_elite") and enemy.get_meta("is_elite"):
		return ELITE_COLOR
	if "data" in enemy and enemy.data != null and enemy.data is EnemyData:
		if enemy.data.is_elite:
			return ELITE_COLOR
	return NORMAL_COLOR


func _get_indicator(idx: int) -> ColorRect:
	if idx < _indicators.size():
		return _indicators[idx]
	var rect := ColorRect.new()
	rect.size = Vector2(INDICATOR_SIZE, INDICATOR_SIZE)
	rect.visible = false
	_container.add_child(rect)
	_indicators.append(rect)
	return rect


func _hide_all() -> void:
	for indicator in _indicators:
		indicator.visible = false


func _build_ui() -> void:
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
