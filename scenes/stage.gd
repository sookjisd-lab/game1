extends Node2D
## 기본 스테이지 씬. 플레이어 배치와 카메라 추적을 담당한다.


const HUD_SCENE: PackedScene = preload("res://ui/hud.tscn")
const LEVEL_UP_UI_SCENE: PackedScene = preload("res://ui/level_up_ui.tscn")
const GAME_OVER_UI_SCENE: PackedScene = preload("res://ui/game_over_ui.tscn")
const PAUSE_UI_SCENE: PackedScene = preload("res://ui/pause_ui.tscn")

@onready var _player: CharacterBody2D = $Player
var _hud: CanvasLayer = null
var _level_up_ui: CanvasLayer = null
var _game_over_ui: CanvasLayer = null


func _ready() -> void:
	_player.global_position = Vector2(
		Constants.VIEWPORT_WIDTH / 2.0,
		Constants.VIEWPORT_HEIGHT / 2.0
	)
	SpawnManager.register_stage(self, _player)
	DropManager.register(self, _player)
	UpgradeManager.register_player(_player)
	DamageNumberManager.register_stage(self)
	_player.player_died.connect(_on_player_died)
	_player.leveled_up.connect(_on_player_leveled_up)
	_setup_hud()
	_setup_level_up_ui()
	_setup_game_over_ui()
	_setup_pause_ui()
	_draw_debug_grid()


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


func _setup_game_over_ui() -> void:
	_game_over_ui = GAME_OVER_UI_SCENE.instantiate()
	add_child(_game_over_ui)


func _on_player_died() -> void:
	GameManager.end_run(false)
	_game_over_ui.show_results(
		GameManager.run_elapsed_time,
		SpawnManager.total_kills,
		_player.current_level,
		DropManager.total_xp,
	)


func _on_player_leveled_up(_new_level: int) -> void:
	GameManager.change_state(Enums.GameState.LEVEL_UP)
	var choices := UpgradeManager.generate_choices(Constants.LEVEL_UP_CHOICES)
	_level_up_ui.show_choices(choices)


## 이동 확인용 디버그 격자를 생성한다. 에셋 완성 후 제거 예정.
func _draw_debug_grid() -> void:
	var grid_color := Color(0.25, 0.15, 0.35, 1.0)
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
