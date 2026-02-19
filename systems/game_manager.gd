extends Node
## 게임 상태 머신, 런 타이머, 시작/종료 생명주기, 메타 진행을 관리한다.
## Autoload 싱글톤: GameManager


# --- 시그널 ---

## 게임 상태가 변경될 때 발행한다.
signal state_changed(old_state: Enums.GameState, new_state: Enums.GameState)

## 런 타이머가 갱신될 때 매 초 발행한다.
signal run_timer_updated(elapsed_seconds: float)

## 런이 시작될 때 발행한다.
signal run_started

## 런이 종료될 때 발행한다.
signal run_ended(is_victory: bool)


# --- 상태 ---

const SAVE_PATH: String = "user://meta_progress.tres"

var current_state: Enums.GameState = Enums.GameState.MENU
var run_elapsed_time: float = 0.0
var meta: MetaProgress = null
var _is_run_active: bool = false
var _last_reported_second: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_meta()


func _process(delta: float) -> void:
	if not _is_run_active:
		return
	if current_state != Enums.GameState.PLAYING:
		return

	run_elapsed_time += delta
	var current_second: int = int(run_elapsed_time)
	if current_second != _last_reported_second:
		_last_reported_second = current_second
		run_timer_updated.emit(run_elapsed_time)


## 상태를 전환한다. 동일 상태 전환은 무시한다.
func change_state(new_state: Enums.GameState) -> void:
	if new_state == current_state:
		return
	var old_state := current_state
	current_state = new_state
	_handle_state_transition(old_state, new_state)
	state_changed.emit(old_state, new_state)


## 새 런을 시작한다.
func start_run() -> void:
	run_elapsed_time = 0.0
	_last_reported_second = -1
	_is_run_active = true
	get_tree().paused = false
	change_state(Enums.GameState.PLAYING)
	run_started.emit()


## 런을 종료한다.
func end_run(is_victory: bool) -> void:
	_is_run_active = false
	_settle_run(is_victory)
	if is_victory:
		change_state(Enums.GameState.VICTORY)
	else:
		change_state(Enums.GameState.GAME_OVER)
	run_ended.emit(is_victory)


## 기억 조각 획득량을 계산한다 (GDD 9.2: 일반=1, 엘리트=10, 보스=50, 분당=5).
static func calculate_shards(total_kills: int, elite_kills_count: int, boss_kills_count: int, elapsed_time: float) -> int:
	var normal_kills: int = total_kills - elite_kills_count - boss_kills_count
	return maxi(normal_kills, 0) + elite_kills_count * 10 + boss_kills_count * 50 + int(elapsed_time / 60.0) * 5


## 경과 시간을 "MM:SS" 형식으로 변환한다.
static func format_time(elapsed_seconds: float) -> String:
	var minutes: int = int(elapsed_seconds) / 60
	var seconds: int = int(elapsed_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]


## 런 종료 시 기억 조각을 정산하고 기록을 갱신한다.
func _settle_run(is_victory: bool) -> void:
	var shards: int = calculate_shards(SpawnManager.total_kills, SpawnManager.elite_kills, SpawnManager.boss_kills, run_elapsed_time)

	meta.memory_shards += shards
	meta.total_kills_all_time += SpawnManager.total_kills
	if is_victory:
		meta.boss_kills += 1

	if run_elapsed_time > meta.best_survival_time:
		meta.best_survival_time = run_elapsed_time

	if run_elapsed_time >= 600.0 and not meta.fritz_unlocked:
		meta.fritz_unlocked = true

	if meta.boss_kills >= 1 and not meta.stage2_unlocked:
		meta.stage2_unlocked = true

	_save_meta()


## 영구 업그레이드로 인한 기본 스탯 보너스를 반환한다.
func get_meta_bonus_hp() -> float:
	return meta.upgrade_hp * 5.0


func get_meta_bonus_attack() -> float:
	return meta.upgrade_attack * 0.03


func get_meta_bonus_speed() -> float:
	return meta.upgrade_speed * 0.02


func get_meta_bonus_xp() -> float:
	return meta.upgrade_xp * 0.05


func get_meta_bonus_drop() -> float:
	return meta.upgrade_drop * 0.03


func get_meta_bonus_defense() -> float:
	return meta.upgrade_defense * 2.0


func get_meta_bonus_magnet() -> float:
	return meta.upgrade_magnet * 0.05


func get_meta_revive_count() -> int:
	return meta.upgrade_revive


func _load_meta() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded := ResourceLoader.load(SAVE_PATH)
		if loaded is MetaProgress:
			meta = loaded
			return
	meta = MetaProgress.new()


func _save_meta() -> void:
	ResourceSaver.save(meta, SAVE_PATH)


func _handle_state_transition(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	match new_state:
		Enums.GameState.PAUSED, \
		Enums.GameState.LEVEL_UP, \
		Enums.GameState.TREASURE, \
		Enums.GameState.GAME_OVER, \
		Enums.GameState.VICTORY:
			get_tree().paused = true
		Enums.GameState.PLAYING:
			get_tree().paused = false
		Enums.GameState.MENU:
			get_tree().paused = false
			_is_run_active = false
