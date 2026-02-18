class_name Constants
## 시스템 레벨 전역 상수
## 밸런스 수치(HP, 데미지 등)는 Resource(.tres)에 분리한다 (OCP)


## -- 해상도 --
const VIEWPORT_WIDTH: int = 320
const VIEWPORT_HEIGHT: int = 180

## -- 물리/프레임 --
const TARGET_FPS: int = 60

## -- 런 타이머 --
const RUN_DURATION_SECONDS: float = 1200.0  # 20분

## -- 플레이어 기본 --
const PLAYER_BASE_SPEED: float = 80.0  # px/s

## -- 레벨업 --
const LEVEL_UP_CHOICES: int = 3
const MAX_WEAPONS: int = 6
const MAX_PASSIVES: int = 6

## -- 데미지 숫자 --
const MAX_DAMAGE_NUMBERS: int = 20

## -- 경험치 흡수 --
const BASE_MAGNET_RADIUS: float = 32.0  # px
