class_name EvolutionData
extends Resource
## 무기 진화 레시피. 무기 Max Lv + 특정 패시브 보유 시 진화 가능.


@export var evolution_name: String = ""
@export var description: String = ""
@export var card_color: Color = Color.GOLD
@export var source_weapon_script: String = ""
@export var required_passive: String = ""
@export var evolved_weapon_script: String = ""
@export var evolved_weapon_data: String = ""
