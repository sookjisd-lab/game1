extends CanvasLayer
## 인게임 HUD. HP바, 런 타이머, 킬 카운트, 경험치를 표시한다.


@onready var _hp_bar: ProgressBar = $TopBar/HPBar
@onready var _timer_label: Label = $TopBar/TimerLabel
@onready var _kill_label: Label = $TopBar/KillLabel
@onready var _level_label: Label = $BottomBar/LevelLabel
@onready var _xp_bar: ProgressBar = $BottomBar/XPBar
@onready var _passive_bar: HBoxContainer = $PassiveBar

var _kill_count: int = 0
var _passive_icons: Array[Control] = []


func _ready() -> void:
	GameManager.run_timer_updated.connect(_on_timer_updated)
	SpawnManager.enemy_killed.connect(_on_enemy_killed)
	_update_timer(0.0)
	_update_kills(0)
	_update_level(1)
	_update_xp_bar(0, Constants.XP_BASE)


func connect_player(player: CharacterBody2D) -> void:
	player.hp_changed.connect(_on_hp_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.passives_changed.connect(_on_passives_changed.bind(player))
	_on_hp_changed(player.current_hp, player.max_hp)
	_update_level(player.current_level)
	_update_xp_bar(player.current_xp, player.xp_to_next_level())


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


func _on_xp_changed(current: int, needed: int) -> void:
	_update_xp_bar(current, needed)


func _on_leveled_up(new_level: int) -> void:
	_update_level(new_level)


func _update_timer(elapsed: float) -> void:
	var minutes: int = int(elapsed) / 60
	var seconds: int = int(elapsed) % 60
	_timer_label.text = "%02d:%02d" % [minutes, seconds]


func _update_kills(count: int) -> void:
	_kill_label.text = str(count)


func _update_level(level: int) -> void:
	_level_label.text = "Lv.%d" % level


func _update_xp_bar(current: int, needed: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = current


func _on_passives_changed(player: CharacterBody2D) -> void:
	_update_passive_icons(player._passives)


func _update_passive_icons(passives: Dictionary) -> void:
	for icon in _passive_icons:
		icon.queue_free()
	_passive_icons.clear()

	for p_name: String in passives:
		var info: Dictionary = passives[p_name]
		var p_data: PassiveData = info["data"]
		var p_level: int = info["level"]

		var container := Control.new()
		container.custom_minimum_size = Vector2(14, 10)

		var color_rect := ColorRect.new()
		color_rect.color = p_data.icon_color
		color_rect.size = Vector2(8, 8)
		color_rect.position = Vector2(3, 0)
		container.add_child(color_rect)

		var lv_label := Label.new()
		lv_label.text = str(p_level)
		lv_label.position = Vector2(2, -1)
		lv_label.add_theme_font_size_override("font_size", 8)
		lv_label.add_theme_color_override("font_color", Color.WHITE)
		container.add_child(lv_label)

		_passive_bar.add_child(container)
		_passive_icons.append(container)
