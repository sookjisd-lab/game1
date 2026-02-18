extends CanvasLayer
## 인게임 HUD. HP바, 런 타이머, 킬 카운트, 경험치를 표시한다.


@onready var _hp_bar: ProgressBar = $TopBar/HPBar
@onready var _timer_label: Label = $TopBar/TimerLabel
@onready var _kill_label: Label = $TopBar/KillLabel
@onready var _xp_label: Label = $BottomBar/XPLabel

var _kill_count: int = 0


func _ready() -> void:
	GameManager.run_timer_updated.connect(_on_timer_updated)
	DropManager.xp_collected.connect(_on_xp_collected)
	SpawnManager.enemy_killed.connect(_on_enemy_killed)
	_update_timer(0.0)
	_update_kills(0)
	_update_xp(0)


func connect_player(player: CharacterBody2D) -> void:
	player.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(player.current_hp, player.max_hp)


func add_kill() -> void:
	_kill_count += 1
	_update_kills(_kill_count)


func _on_hp_changed(current: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current


func _on_timer_updated(elapsed: float) -> void:
	_update_timer(elapsed)


func _on_enemy_killed() -> void:
	add_kill()


func _on_xp_collected(amount: int) -> void:
	_update_xp(DropManager.total_xp)


func _update_timer(elapsed: float) -> void:
	var minutes: int = int(elapsed) / 60
	var seconds: int = int(elapsed) % 60
	_timer_label.text = "%02d:%02d" % [minutes, seconds]


func _update_kills(count: int) -> void:
	_kill_label.text = str(count)


func _update_xp(total: int) -> void:
	_xp_label.text = "XP: %d" % total
