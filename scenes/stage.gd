extends Node2D
## 기본 스테이지 씬. 플레이어 배치와 카메라 추적을 담당한다.


@onready var _player: CharacterBody2D = $Player


func _ready() -> void:
	_player.global_position = Vector2(
		Constants.VIEWPORT_WIDTH / 2.0,
		Constants.VIEWPORT_HEIGHT / 2.0
	)
	_draw_debug_grid()


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
