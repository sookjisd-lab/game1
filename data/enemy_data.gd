class_name EnemyData
extends Resource
## 적 1종의 스탯과 속성을 정의하는 데이터 리소스.
## 새 적 추가 시 이 리소스의 .tres 파일만 추가하면 된다 (OCP).


@export var enemy_name: String = ""
@export var max_hp: float = 10.0
@export var move_speed: float = 30.0
@export var contact_damage: float = 5.0
@export var xp_reward: int = 1
@export var sprite_color: Color = Color.WHITE
@export var sprite_size: Vector2 = Vector2(16, 16)
@export var sprite_path: String = ""
@export var spawn_after_seconds: float = 0.0
@export var is_elite: bool = false
@export var is_stationary: bool = false
@export var attack_interval: float = 0.0
@export var attack_range: float = 0.0
@export var ability_type: String = ""
