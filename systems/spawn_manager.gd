extends Node
## WaveData 기반 적/엘리트 시간 스폰, 보스 등장, 화면 밖 적 제거를 담당한다.
## Autoload 싱글톤: SpawnManager


signal enemy_killed
signal boss_warning(boss_name: String)
signal boss_spawned(boss: Area2D)
signal boss_defeated(is_victory: bool)

const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const BOSS1_SCENE: PackedScene = preload("res://entities/bosses/boss_grimholt.tscn")
const BOSS2_SCENE: PackedScene = preload("res://entities/bosses/boss_witch_messenger.tscn")
const SPAWN_MARGIN: float = 32.0
const DESPAWN_DISTANCE: float = 400.0
const ELITE_INTERVAL: float = 300.0
const ELITE_BATCH: int = 2
const BOSS1_SPAWN_TIME: float = 600.0
const BOSS2_SPAWN_TIME: float = 1200.0

var total_kills: int = 0
var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.5
var _elite_timer: float = 0.0
var _boss1_spawned: bool = false
var _boss1_warning_sent: bool = false
var _boss2_spawned: bool = false
var _boss2_warning_sent: bool = false
var _current_boss: Area2D = null
var _pending_boss_scene: PackedScene = null
var _player: Node2D = null
var _stage: Node2D = null
var _all_enemy_data: Array[EnemyData] = []
var _elite_data: Array[EnemyData] = []
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

	_elite_timer -= delta
	if _elite_timer <= 0.0 and GameManager.run_elapsed_time >= ELITE_INTERVAL:
		_spawn_elite_wave()
		_elite_timer = ELITE_INTERVAL

	if not _boss1_spawned and not _boss1_warning_sent and GameManager.run_elapsed_time >= BOSS1_SPAWN_TIME:
		_boss1_warning_sent = true
		_pending_boss_scene = BOSS1_SCENE
		boss_warning.emit("영주 그림홀트")

	if _boss1_spawned and not _boss2_spawned and not _boss2_warning_sent and GameManager.run_elapsed_time >= BOSS2_SPAWN_TIME:
		_boss2_warning_sent = true
		_pending_boss_scene = BOSS2_SCENE
		boss_warning.emit("마녀의 사자")

	_despawn_far_enemies()
	_adjust_difficulty()


func register_stage(stage: Node2D, player: Node2D) -> void:
	_stage = stage
	_player = player


func _load_enemy_data() -> void:
	_all_enemy_data.append(preload("res://data/enemies/tooth_flower.tres"))
	_all_enemy_data.append(preload("res://data/enemies/shadow_cat.tres"))
	_all_enemy_data.append(preload("res://data/enemies/spider_doll.tres"))
	_all_enemy_data.append(preload("res://data/enemies/candle_ghost.tres"))
	_all_enemy_data.append(preload("res://data/enemies/twisted_bread.tres"))
	_all_enemy_data.append(preload("res://data/enemies/bookworm.tres"))
	_all_enemy_data.append(preload("res://data/enemies/mirror_ghost.tres"))

	_elite_data.append(preload("res://data/enemies/elite_tooth_flower.tres"))
	_elite_data.append(preload("res://data/enemies/elite_spider_doll.tres"))
	_elite_data.append(preload("res://data/enemies/elite_candle_ghost.tres"))


func _get_available_enemies() -> Array[EnemyData]:
	var elapsed: float = GameManager.run_elapsed_time
	var available: Array[EnemyData] = []
	for data in _all_enemy_data:
		if elapsed >= data.spawn_after_seconds:
			available.append(data)
	return available


func _get_available_elites() -> Array[EnemyData]:
	var elapsed: float = GameManager.run_elapsed_time
	var available: Array[EnemyData] = []
	for data in _elite_data:
		if elapsed >= data.spawn_after_seconds:
			available.append(data)
	return available


func _spawn_enemy() -> void:
	if _player == null or _stage == null:
		return

	var pool := _get_available_enemies()
	if pool.is_empty():
		return

	var enemy: Area2D = PoolManager.acquire(ENEMY_SCENE)
	var spawn_pos := _get_spawn_position()
	var enemy_data: EnemyData = pool.pick_random()

	if enemy.get_parent() == null:
		_stage.add_child(enemy)

	enemy.activate(enemy_data, spawn_pos, _player)
	enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	_active_enemies.append(enemy)


func _spawn_elite_wave() -> void:
	var pool := _get_available_elites()
	if pool.is_empty():
		return

	for i in range(ELITE_BATCH):
		var enemy: Area2D = PoolManager.acquire(ENEMY_SCENE)
		var spawn_pos := _get_spawn_position()
		var elite_data: EnemyData = pool.pick_random()

		if enemy.get_parent() == null:
			_stage.add_child(enemy)

		enemy.activate(elite_data, spawn_pos, _player)
		enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
		_active_enemies.append(enemy)


func trigger_boss_spawn() -> void:
	_spawn_boss()


func _spawn_boss() -> void:
	if _player == null or _stage == null or _pending_boss_scene == null:
		return
	if not _boss1_spawned:
		_boss1_spawned = true
	else:
		_boss2_spawned = true
	var boss: Area2D = _pending_boss_scene.instantiate()
	_pending_boss_scene = null
	_stage.add_child(boss)
	var spawn_pos := _get_spawn_position()
	boss.activate(spawn_pos, _player)
	boss.boss_died.connect(_on_boss_died)
	_current_boss = boss
	boss_spawned.emit(boss)


func _on_boss_died() -> void:
	_current_boss = null
	total_kills += 1
	enemy_killed.emit()
	boss_defeated.emit(_boss2_spawned)


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
	elif elapsed < 600.0:
		_spawn_interval = 0.6
	else:
		_spawn_interval = 0.4


func _release_enemy(enemy: Area2D) -> void:
	enemy.deactivate()
	_active_enemies.erase(enemy)
	PoolManager.release(ENEMY_SCENE, enemy)


func _on_enemy_died(enemy: Area2D) -> void:
	_active_enemies.erase(enemy)
	PoolManager.release(ENEMY_SCENE, enemy)
	total_kills += 1
	enemy_killed.emit()


func _on_run_started() -> void:
	_spawn_timer = 2.0
	_elite_timer = ELITE_INTERVAL
	_boss1_spawned = false
	_boss1_warning_sent = false
	_boss2_spawned = false
	_boss2_warning_sent = false
	_pending_boss_scene = null
	_current_boss = null
	total_kills = 0


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if new_state == Enums.GameState.MENU:
		_clear_all_enemies()
		if _current_boss != null and is_instance_valid(_current_boss):
			_current_boss.queue_free()
			_current_boss = null
		_boss1_spawned = false
		_boss1_warning_sent = false
		_boss2_spawned = false
		_boss2_warning_sent = false
		_pending_boss_scene = null
		_player = null
		_stage = null
		_spawn_timer = 0.0


func _clear_all_enemies() -> void:
	for enemy: Area2D in _active_enemies.duplicate():
		_release_enemy(enemy)
	_active_enemies.clear()
