extends Node
## WaveData 기반 적/엘리트 시간 스폰, 보스 등장, 화면 밖 적 제거를 담당한다.
## Autoload 싱글톤: SpawnManager


signal enemy_killed

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const SPAWN_MARGIN: float = 32.0
const DESPAWN_DISTANCE: float = 400.0

var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.5
var _player: Node2D = null
var _stage: Node2D = null
var _enemy_data_pool: Array[EnemyData] = []
var _active_enemies: Array[Area2D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	GameManager.run_started.connect(_on_run_started)
	GameManager.state_changed.connect(_on_state_changed)
	_load_enemy_data()


func _process(delta: float) -> void:
	if _player == null:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_enemy()
		_spawn_timer = _spawn_interval

	_despawn_far_enemies()
	_adjust_difficulty()


func register_stage(stage: Node2D, player: Node2D) -> void:
	_stage = stage
	_player = player


func _load_enemy_data() -> void:
	var tooth_flower := preload("res://data/enemies/tooth_flower.tres")
	_enemy_data_pool.append(tooth_flower)


func _spawn_enemy() -> void:
	if _player == null or _stage == null:
		return

	var enemy: Area2D = PoolManager.acquire(ENEMY_SCENE)
	var spawn_pos := _get_spawn_position()
	var enemy_data: EnemyData = _enemy_data_pool.pick_random()

	enemy.activate(enemy_data, spawn_pos, _player)
	enemy.died.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)
	_active_enemies.append(enemy)

	if enemy.get_parent() == null:
		_stage.add_child(enemy)


func _get_spawn_position() -> Vector2:
	var half_w := Constants.VIEWPORT_WIDTH / 2.0 + SPAWN_MARGIN
	var half_h := Constants.VIEWPORT_HEIGHT / 2.0 + SPAWN_MARGIN
	var side := randi() % 4
	var offset := Vector2.ZERO

	match side:
		0: offset = Vector2(randf_range(-half_w, half_w), -half_h)
		1: offset = Vector2(randf_range(-half_w, half_w), half_h)
		2: offset = Vector2(-half_w, randf_range(-half_h, half_h))
		3: offset = Vector2(half_w, randf_range(-half_h, half_h))

	return _player.global_position + offset


func _despawn_far_enemies() -> void:
	for i in range(_active_enemies.size() - 1, -1, -1):
		var enemy: Area2D = _active_enemies[i]
		if enemy.global_position.distance_to(_player.global_position) > DESPAWN_DISTANCE:
			_release_enemy(enemy)


func _adjust_difficulty() -> void:
	var elapsed := GameManager.run_elapsed_time
	if elapsed < 120.0:
		_spawn_interval = 1.5
	elif elapsed < 300.0:
		_spawn_interval = 1.0
	else:
		_spawn_interval = 0.6


func _release_enemy(enemy: Area2D) -> void:
	enemy.deactivate()
	_active_enemies.erase(enemy)
	PoolManager.release(ENEMY_SCENE, enemy)


func _on_enemy_died(enemy: Area2D) -> void:
	_active_enemies.erase(enemy)
	PoolManager.release(ENEMY_SCENE, enemy)
	enemy_killed.emit()


func _on_run_started() -> void:
	_spawn_timer = 2.0


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if new_state == Enums.GameState.MENU:
		_clear_all_enemies()


func _clear_all_enemies() -> void:
	for enemy: Area2D in _active_enemies.duplicate():
		_release_enemy(enemy)
	_active_enemies.clear()
