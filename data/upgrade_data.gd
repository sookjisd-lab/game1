class_name UpgradeData
extends Resource
## 레벨업 시 선택 가능한 업그레이드 1종을 정의한다.


@export var upgrade_name: String = ""
@export var description: String = ""
@export var card_color: Color = Color(0.3, 0.5, 0.8, 1)
@export var stat_key: String = ""
@export var value: float = 0.0
@export var weapon_script_path: String = ""
@export var weapon_data_path: String = ""
