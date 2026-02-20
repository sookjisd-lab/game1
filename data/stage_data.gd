class_name StageData
extends Resource
## 스테이지 1종의 설정을 정의한다.


@export var stage_name: String = ""
@export var description: String = ""
@export var bg_color: Color = Color(0.05, 0.03, 0.1, 1)
@export var grid_color: Color = Color(0.25, 0.15, 0.35, 1)
@export var enemy_paths: Array[String] = []
@export var elite_paths: Array[String] = []
@export var map_half_size: Vector2 = Vector2(1280, 720)
@export var fog_enabled: bool = false
@export var fog_color: Color = Color(0.1, 0.1, 0.15, 0.4)
@export var lightning_enabled: bool = false
@export var lightning_interval: Vector2 = Vector2(8.0, 15.0)
