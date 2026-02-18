extends Node
## 게임 상태 머신, 런 타이머, 시작/종료 생명주기를 관리한다.
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

var current_state: Enums.GameState = Enums.GameState.MENU
var run_elapsed_time: float = 0.0
var _is_run_active: bool = false
var _last_reported_second: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


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
	if is_victory:
		change_state(Enums.GameState.VICTORY)
	else:
		change_state(Enums.GameState.GAME_OVER)
	run_ended.emit(is_victory)


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
