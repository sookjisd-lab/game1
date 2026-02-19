class_name MetaProgress
extends Resource
## 영구 진행 데이터. user://meta_progress.tres에 저장된다.


@export var memory_shards: int = 0

## 영구 업그레이드 레벨 (기억의 제단)
@export var upgrade_hp: int = 0          # 체력의 기억 (max 10)
@export var upgrade_attack: int = 0      # 힘의 기억 (max 10)
@export var upgrade_speed: int = 0       # 민첩의 기억 (max 10)
@export var upgrade_xp: int = 0          # 지혜의 기억 (max 10)
@export var upgrade_drop: int = 0        # 행운의 기억 (max 10)
@export var upgrade_defense: int = 0     # 끈기의 기억 (max 5)
@export var upgrade_magnet: int = 0      # 수집의 기억 (max 5)
@export var upgrade_revive: int = 0      # 부활의 기억 (max 1)

## 해금 기록
@export var fritz_unlocked: bool = false
@export var best_survival_time: float = 0.0
@export var total_kills_all_time: int = 0
@export var boss_kills: int = 0
