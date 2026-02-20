class_name CharacterData
extends Resource
## 플레이어블 캐릭터 1종의 스탯과 속성을 정의한다.


@export var character_name: String = ""
@export var description: String = ""
@export var sprite_color: Color = Color.WHITE
@export var sprite_path: String = ""
@export var base_hp: float = 120.0
@export var base_speed: float = 80.0
@export var base_damage_mult: float = 1.0
@export var starting_weapon_script: String = ""
@export var starting_weapon_data: String = ""
@export var passive_name: String = ""
@export var passive_desc: String = ""
@export var passive_stat_key: String = ""
@export var passive_value: float = 0.0
