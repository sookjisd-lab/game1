extends Node2D
## 기본 스테이지 씬. 플레이어 배치와 카메라 추적을 담당한다.


const HUD_SCENE: PackedScene = preload("res://ui/hud.tscn")
const LEVEL_UP_UI_SCENE: PackedScene = preload("res://ui/level_up_ui.tscn")
const GAME_OVER_UI_SCENE: PackedScene = preload("res://ui/game_over_ui.tscn")
const PAUSE_UI_SCENE: PackedScene = preload("res://ui/pause_ui.tscn")
const BOSS_HP_BAR_SCENE: PackedScene = preload("res://ui/boss_hp_bar.tscn")
const TREASURE_UI_SCENE: PackedScene = preload("res://ui/treasure_ui.tscn")
const BOSS_WARNING_SCENE: PackedScene = preload("res://ui/boss_warning.tscn")
const OFFSCREEN_INDICATOR_SCENE: PackedScene = preload("res://ui/offscreen_indicator.tscn")

var character_data: CharacterData = null
var stage_data: StageData = null

@onready var _player: CharacterBody2D = $Player
var _hud: CanvasLayer = null
var _level_up_ui: CanvasLayer = null
var _game_over_ui: CanvasLayer = null
var _boss_hp_bar: CanvasLayer = null
var _treasure_ui: CanvasLayer = null
var _boss_warning: CanvasLayer = null
var _pending_boss_name: String = ""
var _countdown_active: bool = false
var _wall_painting_discovered: bool = false


func _ready() -> void:
	if character_data == null:
		character_data = preload("res://data/characters/rosie.tres")
	if stage_data == null:
		stage_data = preload("res://data/stages/stage1_town.tres")
	_player.global_position = Vector2(
		Constants.VIEWPORT_WIDTH / 2.0,
		Constants.VIEWPORT_HEIGHT / 2.0
	)
	_setup_hud()
	_player.init_character(character_data)
	SpawnManager.register_stage(self, _player, stage_data)
	_apply_stage_visuals()
	DropManager.register(self, _player)
	UpgradeManager.register_player(_player, character_data.starting_weapon_script)
	DamageNumberManager.register_stage(self)
	GameManager.run_timer_updated.connect(_on_run_timer_updated)
	SpawnManager.boss_warning.connect(_on_boss_warning)
	SpawnManager.boss_spawned.connect(_on_boss_spawned)
	SpawnManager.boss_defeated.connect(_on_boss_defeated)
	_player.player_died.connect(_on_player_died)
	_player.leveled_up.connect(_on_player_leveled_up)
	UpgradeManager.upgrade_applied.connect(_on_upgrade_applied)
	DropManager.treasure_chest_collected.connect(_on_treasure_chest_collected)
	_setup_level_up_ui()
	_setup_game_over_ui()
	_setup_pause_ui()
	_setup_boss_hp_bar()
	_setup_treasure_ui()
	_setup_boss_warning()
	_setup_offscreen_indicator()
	_draw_debug_grid()
	_start_countdown()


func _setup_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.connect_player(_player)


func _setup_level_up_ui() -> void:
	_level_up_ui = LEVEL_UP_UI_SCENE.instantiate()
	add_child(_level_up_ui)


func _setup_pause_ui() -> void:
	var pause_ui := PAUSE_UI_SCENE.instantiate()
	add_child(pause_ui)
	pause_ui.register_player(_player)


func _setup_game_over_ui() -> void:
	_game_over_ui = GAME_OVER_UI_SCENE.instantiate()
	add_child(_game_over_ui)


func _setup_boss_hp_bar() -> void:
	_boss_hp_bar = BOSS_HP_BAR_SCENE.instantiate()
	add_child(_boss_hp_bar)


func _setup_treasure_ui() -> void:
	_treasure_ui = TREASURE_UI_SCENE.instantiate()
	add_child(_treasure_ui)


func _on_run_timer_updated(elapsed: float) -> void:
	if not _wall_painting_discovered and elapsed >= 900.0:
		_wall_painting_discovered = true
		StoryManager.discover_clue("wall_painting")


func _on_player_died() -> void:
	GameManager.end_run(false)
	Engine.time_scale = 0.3
	get_tree().create_timer(0.5 * 0.3).timeout.connect(_show_death_results)


func _show_death_results() -> void:
	Engine.time_scale = 1.0
	_game_over_ui.show_results(
		GameManager.run_elapsed_time,
		SpawnManager.total_kills,
		_player.current_level,
		DropManager.total_xp,
		false,
		_get_weapon_names(),
		StoryManager.get_run_discoveries(),
	)


func _on_player_leveled_up(_new_level: int) -> void:
	GameManager.change_state(Enums.GameState.LEVEL_UP)
	var choices := UpgradeManager.generate_choices(Constants.LEVEL_UP_CHOICES)
	_level_up_ui.show_choices(choices)


func _setup_offscreen_indicator() -> void:
	var indicator := OFFSCREEN_INDICATOR_SCENE.instantiate()
	add_child(indicator)
	indicator.register_player(_player)


func _setup_boss_warning() -> void:
	_boss_warning = BOSS_WARNING_SCENE.instantiate()
	add_child(_boss_warning)
	_boss_warning.warning_finished.connect(_on_boss_warning_finished)


func _on_boss_warning(boss_name: String) -> void:
	_pending_boss_name = boss_name
	_boss_warning.play_warning(boss_name)


func _on_boss_warning_finished() -> void:
	SpawnManager.trigger_boss_spawn()


func _on_upgrade_applied(_data: UpgradeData) -> void:
	if not UpgradeManager.has_pending_evolutions():
		return
	if GameManager.current_state != Enums.GameState.PLAYING:
		return
	call_deferred("_show_treasure")


func _show_treasure() -> void:
	var evolutions := UpgradeManager.get_available_evolutions()
	if evolutions.is_empty():
		return
	GameManager.change_state(Enums.GameState.TREASURE)
	_treasure_ui.show_choices(evolutions)


func _on_treasure_chest_collected() -> void:
	if GameManager.current_state != Enums.GameState.PLAYING:
		return
	if randf() < 0.2:
		StoryManager.discover_clue("village_diary")
	var choices := UpgradeManager.generate_treasure_choices(Constants.LEVEL_UP_CHOICES)
	if choices.is_empty():
		return
	GameManager.change_state(Enums.GameState.TREASURE)
	_treasure_ui.show_choices(choices)


func _on_boss_spawned(boss: Area2D) -> void:
	_boss_hp_bar.show_boss(_pending_boss_name, boss.current_hp, boss.max_hp)
	boss.boss_hp_changed.connect(_boss_hp_bar.update_hp)
	if boss.has_signal("boss_phase_changed"):
		boss.boss_phase_changed.connect(_boss_hp_bar.show_phase)


func _on_boss_defeated(is_victory: bool) -> void:
	_boss_hp_bar.hide_boss()
	if _pending_boss_name == "영주 그림홀트":
		StoryManager.discover_clue("lord_diary")
	elif _pending_boss_name == "마녀의 사자":
		StoryManager.discover_clue("witch_seal")
	if is_victory:
		GameManager.end_run(true)
		Engine.time_scale = 0.3
		_show_victory_message()
		get_tree().create_timer(2.0, true, false, true).timeout.connect(_show_victory_results)


func _show_victory_message() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 25
	overlay.name = "VictoryMessage"
	add_child(overlay)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	label.text = "저주가 약해지고 있다..."
	overlay.add_child(label)


func _show_victory_results() -> void:
	Engine.time_scale = 1.0
	var msg := get_node_or_null("VictoryMessage")
	if msg != null:
		msg.queue_free()
	_game_over_ui.show_results(
		GameManager.run_elapsed_time,
		SpawnManager.total_kills,
		_player.current_level,
		DropManager.total_xp,
		true,
		_get_weapon_names(),
		StoryManager.get_run_discoveries(),
	)


func _get_weapon_names() -> Array[String]:
	var names: Array[String] = []
	for weapon: WeaponBase in _player._weapons:
		names.append("%s Lv.%d" % [weapon.data.weapon_name, weapon.level])
	return names


func is_countdown_active() -> bool:
	return _countdown_active


func _start_countdown() -> void:
	_countdown_active = true
	var overlay := CanvasLayer.new()
	overlay.layer = 25
	overlay.name = "CountdownOverlay"
	add_child(overlay)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.1, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	overlay.add_child(label)

	get_tree().paused = true
	label.text = "3"
	await get_tree().create_timer(1.0, true, false, true).timeout
	label.text = "2"
	await get_tree().create_timer(1.0, true, false, true).timeout
	label.text = "1"
	await get_tree().create_timer(1.0, true, false, true).timeout
	overlay.queue_free()
	_countdown_active = false
	GameManager.start_run()


func _apply_stage_visuals() -> void:
	if stage_data.fog_enabled:
		var fog := CanvasModulate.new()
		fog.color = Color(1, 1, 1, 1) - stage_data.fog_color
		add_child(fog)


## 이동 확인용 디버그 격자를 생성한다. 에셋 완성 후 제거 예정.
func _draw_debug_grid() -> void:
	var grid_color: Color = stage_data.grid_color if stage_data != null else Color(0.25, 0.15, 0.35, 1.0)
	var grid_size := 32
	var map_size := 640

	for x in range(-map_size, map_size + 1, grid_size):
		var line := Line2D.new()
		line.points = [Vector2(x, -map_size), Vector2(x, map_size)]
		line.width = 1
		line.default_color = grid_color
		add_child(line)

	for y in range(-map_size, map_size + 1, grid_size):
		var line := Line2D.new()
		line.points = [Vector2(-map_size, y), Vector2(map_size, y)]
		line.width = 1
		line.default_color = grid_color
		add_child(line)

	# 원점 표시 (빨간 십자)
	var origin_color := Color(0.55, 0.1, 0.1, 1.0)
	for data in [
		[Vector2(-16, 0), Vector2(16, 0)],
		[Vector2(0, -16), Vector2(0, 16)],
	]:
		var line := Line2D.new()
		line.points = data
		line.width = 2
		line.default_color = origin_color
		add_child(line)
