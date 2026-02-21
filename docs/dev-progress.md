# 개발 진행 현황

> 최종 업데이트: 2026-02-21

## 구현 상태 요약

| 카테고리 | 진행률 | 비고 |
|----------|--------|------|
| 프로젝트 기반 | 100% | Godot 프로젝트, 폴더구조, Autoload |
| 코어 게임 루프 | 100% | 이동, 스폰, 공격, 드롭, 마그넷, 맵 아이템, 엘리트, 보스 2종, 보물상자 완료 |
| 무기 시스템 | 100% | 8/8종 + 진화 4종 구현, 레벨업 시스템 완료 |
| 적 시스템 | 100% | 8종 일반 적 + 3종 엘리트 + 보스 2종 완료 |
| 패시브 시스템 | 100% | 시스템 완료, 10/10종 패시브 구현, HUD 아이콘 표시 |
| 레벨업 UI | 100% | 카드 3장, 신규무기 금색 헤더, 무기/패시브 업그레이드, 보물상자/진화 |
| 타이틀/UI | 100% | 타이틀, 제단, 캐릭터선택, 스테이지선택, 설정 7종, 서재, 보스경고, 인디케이터 |
| 메타 진행 | 100% | 기억 조각 + 세이브/로드 + 기억의 제단 8종 업그레이드 |
| 캐릭터 | 100% | 로지 + 프릿츠, 캐릭터 선택 UI, 해금 시스템 |
| 스토리 | 100% | StoryManager + 단서 4종 + 기억의 서재 + NPC 대화 3종 |
| 스테이지 | 100% | 2개 스테이지 (광장/묘지) + StageData + 선택 UI |
| 에셋 | 100% | 스프라이트 32종 + 타일셋 4종 + 장식물 13종 + 아이콘 18종 + SFX 19종 + BGM 5종 + FX 2종 |
| 디자인 폴리시 | 100% | UITheme 통합, 비네팅/글로우, 페이드 전환, 스프라이트 개선, idle 애니메이션 |

---

## 완료된 작업

### 1. 프로젝트 초기 세팅
- `project.godot`: 320x180 픽셀퍼펙트, canvas_items + integer 스케일링
- 9개 Autoload 싱글톤 등록
- Input Map: WASD + 방향키 + ESC
- `.gitignore` 설정
- 폴더 구조: `core/`, `entities/`, `systems/`, `ui/`, `data/`, `scenes/`, `shared/`

### 2. 전역 정의
- **`shared/enums.gd`**: `GameState` 열거형 (MENU, PLAYING, PAUSED, LEVEL_UP, TREASURE, GAME_OVER, VICTORY)
- **`shared/constants.gd`**: 시스템 상수 (해상도, FPS, 플레이어 속도, 레벨업, 경험치 등)

### 3. 매니저 시스템 (systems/)

| 매니저 | 상태 | 구현 내용 |
|--------|------|----------|
| GameManager | **완료** | FSM 전환, 런 타이머, start_run/end_run, pause 처리 |
| SpawnManager | **완료** | 시간별 적 스폰, 난이도 곡선(1.5s→0.4s), 화면밖 디스폰, 킬 카운트, 엘리트 웨이브(5분마다), 보스 2종 스폰(10분/20분) |
| PoolManager | **완료** | acquire/release 풀링 (적, 보석, 데미지숫자, 맵 아이템) |
| UpgradeManager | **완료** | 선택지 생성, 무기/패시브 획득·레벨업, 중복 방지 |
| DropManager | **완료** | XP 보석 3티어, 마그넷 흡수, 맵 드롭 아이템 3종 |
| DamageNumberManager | **완료** | 풀링 20개, 데미지/회복 숫자 팝업 |
| StatsManager | 스켈레톤 | 패시브 시스템이 Player 내부에서 처리 (별도 매니저 불필요) |
| StoryManager | **완료** | 단서 4종 발견/기록, NPC 3종 대화, 조건부 해금 |
| AudioManager | **완료** | 볼륨 관리 (마스터/BGM/SFX), 설정 저장 (ConfigFile) |

### 4. 데이터 리소스 (data/)

#### Resource 클래스
| 클래스 | 파일 | 필드 |
|--------|------|------|
| EnemyData | `data/enemy_data.gd` | enemy_name, max_hp, move_speed, contact_damage, xp_reward, sprite_color, sprite_size, sprite_path, spawn_after_seconds, is_elite, is_stationary, attack_interval, attack_range, ability_type |
| WeaponData | `data/weapon_data.gd` | weapon_name, damage, cooldown, attack_range, knockback, max_level, projectile_color |
| UpgradeData | `data/upgrade_data.gd` | upgrade_name, description, card_color, stat_key, value, weapon_script_path, weapon_data_path |
| PassiveData | `data/passive_data.gd` | passive_name, description, icon_color, stat_key, value_per_level, max_level |
| StageData | `data/stage_data.gd` | stage_name, description, bg_color, grid_color, enemy_paths, elite_paths, map_half_size, fog_enabled, fog_color, lightning_enabled, lightning_interval, ground_variant_paths, variant_ratio, vignette_strength, player_glow_color |

#### 적 데이터 (.tres)
| 이름 | 등장시간 | HP | 속도 | 데미지 | XP |
|------|----------|-----|------|--------|-----|
| 이빨꽃 (tooth_flower) | 0s | 10 | 30 | 5 | 1 |
| 그림자고양이 (shadow_cat) | 0s | 6 | 55 | 3 | 1 |
| 거미인형 (spider_doll) | 120s | 8 | 25 | 4 | 1 |
| 양초유령 (candle_ghost) | 120s | 5 | 40 | 6 | 2 |
| 뒤틀린빵 (twisted_bread) | 300s | 12 | 60 | 8 | 5 |
| 책벌레 (bookworm) | 300s | 7 | 35 | 5 | 5 |
| 거울유령 (mirror_ghost) | 600s | 15 | 35 | 7 | 3 |

#### 엘리트 적 데이터 (.tres)
| 이름 | 등장시간 | HP | 속도 | 데미지 | XP |
|------|----------|-----|------|--------|-----|
| 맹독 이빨꽃 (elite_tooth_flower) | 300s | 30 | 25 | 15 | 10 |
| 폭주 거미인형 (elite_spider_doll) | 300s | 24 | 30 | 12 | 10 |
| 화염 양초유령 (elite_candle_ghost) | 300s | 20 | 35 | 18 | 10 |

#### 보스
| 이름 | 등장시간 | HP | 크기 | 페이즈 |
|------|----------|-----|------|--------|
| 영주 그림홀트 (boss_grimholt) | 600s | 300 | 64x64 | 3페이즈 (소환→충격파→돌진+충격파) |
| 마녀의 사자 (boss_witch_messenger) | 1200s | 600 | 96x96 | 3페이즈 (독구름→텔레포트+사격→탄막+독구름) |

#### 무기 데이터 (.tres)
| 이름 | 데미지 | 쿨다운 | 사거리 | 색상 |
|------|--------|--------|--------|------|
| 저주받은 가위 | 15 | 0.8s | 40 | 은색 |
| 뒤틀린 성경 | 8 | 0.5s | 50 | 보라 |
| 유령 양초 | 10 | 1.8s | 120 | 주황 |
| 저주받은 꽃다발 | 6 | 2.0s | 60 | 형광 초록 |
| 인형의 바늘 | 7 | 1.5s | 80 | 분홍 |
| 시계 톱니바퀴 | 10 | 0.4s | 45 | 금색 |
| 깨진 거울 파편 | 12 | 2.2s | 90 | 하늘색 |
| 마녀의 빗자루 | 14 | 1.2s | 55 | 갈색 |

#### 패시브 데이터 (.tres)
| 이름 | 효과 | 레벨당 값 | 최대 Lv |
|------|------|----------|---------|
| 두꺼운 앞치마 | 최대 HP +% | 10% | 5 |
| 달리기 신발 | 이동속도 +% | 10% | 5 |
| 깨진 시계 | 쿨다운 -% | 8% | 5 |
| 저주받은 목걸이 | 공격력 +% | 10% | 5 |
| 돋보기 | 공격 범위 +% | 10% | 5 |
| 자석 브로치 | 마그넷 범위 +% | 30% | 5 |
| 오래된 일기장 | XP 획득 +% | 10% | 5 |
| 행운의 동전 | 크리티컬 확률 | 5% | 5 |
| 재생 허브 | 초당 HP 회복 | 0.2 | 5 |
| 유령 망토 | 회피 확률 | 5% | 5 |

#### 업그레이드 데이터 (.tres)
- 소비형: heal (HP 회복)
- 무기 획득: weapon_cursed_bible, weapon_ghost_candle, weapon_cursed_bouquet, weapon_doll_needle, weapon_clock_gear, weapon_mirror_shard, weapon_witch_broom
- 패시브/무기 레벨업: UpgradeManager가 런타임에 UpgradeData 동적 생성

### 5. 플레이어 (entities/player/)
- **CharacterBody2D** 기반, WASD/방향키 이동
- 기본 스탯: HP(120), 이동속도(80), damage_multiplier(1.0), cooldown_multiplier(1.0), magnet_radius(32), range_multiplier(1.0), xp_multiplier(1.0), crit_chance(0.0), hp_regen(0.0), dodge_chance(0.0)
- 패시브 시스템: `_passives` Dictionary, `_recalculate_stats()` (기본값 기반 재계산)
- HP 리젠: _physics_process에서 accumulator 기반 회복
- 회피: take_damage에서 dodge_chance 확률 적용
- XP 배율: _on_xp_collected에서 xp_multiplier 적용
- 경험치 시스템: XP 커브 (base 5 + level * 5), 다중 레벨업 처리
- 시그널: hp_changed, player_died, leveled_up, xp_changed
- 피격 피드백: 빨간 플래시 + 카메라 흔들림
- 시작 무기: CharacterData 기반 동적 장착
- 캐릭터 시스템: CharacterData 리소스, init_character() 로 스탯/무기/고유패시브 초기화
- 로지: HP 120, 속도 80, 가위, 경험치+15% / 프릿츠: HP 100, 속도 70, 톱니바퀴, 쿨다운-10%

### 6. 적 (entities/enemies/)
- **Area2D** 기반 (가벼운 충돌, CLAUDE.md 8.6절)
- 풀링 대응: `activate()` / `deactivate()` + `_cache_nodes()` 패턴
- 플레이어 추적 이동
- `take_damage()`: 데미지, 넉백, 사망 처리
- 사망 이펙트: 4방향 색상 파편 파티클 + 페이드아웃
- XP 드롭: `DropManager.spawn_xp_gem()`
- 피격 피드백: 흰색 플래시 (0.08s)

### 7. 무기 (entities/weapons/)

#### WeaponBase (기본 클래스)
- 쿨다운 관리, 가장 가까운 적 탐색 (`_find_nearest_enemy`)
- 레벨업 시스템: `level_up()`, 레벨당 데미지+15%, 쿨다운-5%, 사거리+10%
- `get_effective_damage/cooldown/range()` 메서드
- `calc_final_damage()`: 크리티컬 확률 적용 (1.5x 배율)
- `get_effective_range()`: range_multiplier 적용

#### 구현된 무기
| 무기 | 패턴 | 특징 |
|------|------|------|
| 저주받은 가위 (cursed_scissors) | 부채꼴 투사체 | 가장 가까운 적 방향, 넉백 |
| 뒤틀린 성경 (cursed_bible) | 플레이어 주변 회전 오브 2개 | 적별 히트 쿨다운, 넉백 |
| 유령 양초 (ghost_candle) | 유도 불꽃 | 타겟 추적 (lerp), 3초 수명 |
| 저주받은 꽃다발 (cursed_bouquet) | 관통 독구름 | 직선 비행 + 페이드아웃, 적별 1회 히트 |
| 인형의 바늘 (doll_needle) | 전방위 6방향 발사 | 1체 히트 후 소멸, 사거리 비례 비행 |
| 시계 톱니바퀴 (clock_gear) | 플레이어 주변 회전 기어 3개 | cursed_bible 변형, 3개 기어 |
| 깨진 거울 파편 (mirror_shard) | 랜덤 방향 발사 + 반사 | 화면 가장자리 반사 (최대 3회) |
| 마녀의 빗자루 (witch_broom) | 이동 방향 휩쓸기 | 넓은 범위 (SWEEP_WIDTH=0.8), hit_set로 중복 방지 |

### 8. 드롭 (entities/drops/)

#### XP 보석
- 3티어: 소(파랑 6px, 1-4xp), 중(초록 8px, 5-19xp), 대(빨강 10px, 20+xp)
- 마그넷 흡수: 범위 내 진입 시 가속 접근
- 풀링 대응

#### 맵 드롭 아이템
- 적 사망 시 3% 확률로 랜덤 드롭 (XP 보석과 함께)
- 플레이어 접근 시 자동 픽업 (거리 12px)

| 아이템 | 효과 | 색상 |
|--------|------|------|
| 치유의 빵 (heal_bread) | HP 30 회복 | 금색 |
| 마그넷 부적 (magnet_charm) | 화면 내 모든 보석 즉시 흡수 | 파랑 |
| 정화의 종 (purify_bell) | 화면 내 모든 적에게 30 데미지 | 노랑 |

### 9. 패시브 아이템 시스템
- **PassiveData** 리소스: 이름, 설명, 색상, stat_key, value_per_level, max_level
- Player `_passives` Dictionary: 패시브명 → { data, level }
- `_recalculate_stats()`: 기본 스탯(`_base_max_hp`, `_base_move_speed`) 기반으로 패시브 보너스 재계산
- UpgradeManager: 새 패시브 획득 / 기존 패시브 레벨업 선택지 자동 생성
- 지원 stat_key: `max_hp_percent`, `move_speed_percent`, `damage_percent`, `cooldown_percent`, `magnet_percent`, `range_percent`, `xp_percent`, `crit_chance`, `hp_regen`, `dodge_chance`
- 최대 슬롯: 6개 (`Constants.MAX_PASSIVES`)

### 10. UI (ui/)

| UI | 파일 | 설명 |
|----|------|------|
| HUD | hud.gd/tscn | HP바, 타이머, 킬카운트, 레벨, XP바, 무기아이콘, 기억조각 |
| 레벨업 | level_up_ui.gd/tscn | 카드 3장, 1/2/3키 선택, 색상 헤더 |
| 게임오버 | game_over_ui.gd/tscn | 결과 표시 (시간, 킬, 레벨, XP), SPACE로 재시작 |
| 일시정지 | pause_ui.gd/tscn | ESC=계속, Q=포기(메인메뉴) |
| 데미지숫자 | damage_number.gd/tscn | 상승 + 페이드 애니메이션 (0.6s) |
| 보스HP바 | boss_hp_bar.gd/tscn | 화면 하단 보스 이름 + 체력바 (CanvasLayer 15) |
| 보스경고 | boss_warning.gd/tscn | WARNING 텍스트 + 빨간 점멸 (2초, CanvasLayer 16) |
| 보물상자 | treasure_ui.gd/tscn | 진화 선택지 표시 (TREASURE 상태, CanvasLayer 12) |
| 타이틀 | title_ui.gd/tscn | 게임 제목, SPACE=시작, A=제단, S=설정 (CanvasLayer 20) |
| 제단 | altar_ui.gd/tscn | 영구 업그레이드 8종 구매 (CanvasLayer 20) |
| 캐릭터선택 | character_select_ui.gd/tscn | 캐릭터 선택, 해금 표시 (CanvasLayer 20) |
| 설정 | settings_ui.gd/tscn | 볼륨 3종 + 토글 4종 + 해상도 + 키리바인딩 + 언어 (CanvasLayer 22) |
| 인디케이터 | offscreen_indicator.gd/tscn | 화면 밖 적 방향 마커 (CanvasLayer 9) |

### 11. 씬 구성 (scenes/)
- **main.tscn/gd**: 진입점, ESC 일시정지 토글, 타이틀→캐릭터선택→게임 플로우
- **stage.tscn/gd**: 플레이어 배치, CharacterData 기반 초기화, 매니저 등록, UI 셋업, 맵 경계, 번개 효과

---

## 충돌 레이어 구성

| 레이어 | 이름 | 용도 |
|--------|------|------|
| 1 | Player | 플레이어 물리 충돌 |
| 2 | Enemies | 적 Area2D |
| 4 | WeaponHits | 무기 투사체/히트박스 |
| 8 | Drops | XP 보석, 맵 드롭 아이템 |

---

## 미구현 항목 (GDD 대비)

### 적/보스
- [x] ~~뿌리 손~~ (10분+, 고정 위치, 범위 공격) ✅
- [x] ~~엘리트 몬스터 3종~~ (맹독 이빨꽃, 폭주 인형, 화염 양초) ✅
- [x] ~~엘리트 특수 능력~~ (독웅덩이/분열/강화오라) ✅
- [x] ~~보스: 영주 그림홀트~~ (10분, 64x64, 3페이즈) ✅
- [x] ~~보스: 마녀의 사자~~ (20분, 96x96, 3페이즈) ✅

### 무기
- [x] ~~시계 톱니바퀴~~ (프릿츠 초기 무기) ✅
- [x] ~~깨진 거울 파편~~ (반사 투사체) ✅
- [x] ~~마녀의 빗자루~~ (채찍형) ✅

### 패시브 아이템
- [x] ~~6종 추가~~ (돋보기, 자석 브로치, 일기장, 동전, 약초, 망토) ✅
- [x] ~~패시브 아이콘 HUD 표시~~ ✅

### 무기 진화
- [x] ~~무기 + 패시브 조합 진화 시스템~~ ✅ (8종 전종 완료)
  - 가위+목걸이→피의 가위, 성경+시계→심판의 경전, 양초+앞치마→정화의 불꽃, 바늘+동전→인형술사의 비수
  - 꽃다발+돋보기→만개의 독포자, 톱니바퀴+신발→시공의 톱니, 거울파편+망토→환영의 거울, 빗자루+약초→생명의 빗자루

### 맵 드롭 아이템
- [x] ~~금화 주머니~~ (메타 재화) ✅
- [x] ~~보물 상자~~ (엘리트 25%, 보스 100% 드롭) ✅

### 메타 진행
- [x] ~~기억 조각 (골드) 획득 시스템~~ ✅
- [x] ~~기억의 제단 (영구 업그레이드 8종)~~ ✅
- [x] ~~세이브/로드~~ (`user://meta_progress.tres`) ✅

### UI
- [x] ~~타이틀 화면~~ ✅
- [x] ~~캐릭터 선택~~ ✅
- [x] ~~스테이지 선택~~ ✅
- [x] ~~보스 경고 연출~~ ✅
- [x] ~~보물 상자 보상 UI~~ ✅ (진화 선택지 제공)
- [x] ~~설정 화면~~ ✅ (볼륨 3종 + 토글 4종: 인디케이터/흔들림/데미지숫자/전체화면)
- [x] ~~기억의 서재~~ ✅ (단서 4종 열람)
- [x] ~~화면 밖 적 인디케이터~~ ✅

### 스토리
- [x] ~~StoryManager 구현~~ ✅ (단서 4종 발견/기록)
- [x] ~~단서 드롭 시스템~~ ✅ (보스 처치: 영주일기/마녀봉인, 보물상자 20%: 마을일기, 15분 생존: 벽화)
- [x] ~~NPC 대화~~ ✅ (3종 NPC: 노파/대장장이/술집주인, 조건부 대화 해금)

### 캐릭터
- [x] ~~프릿츠 (2번째 캐릭터)~~ ✅
- [x] ~~캐릭터 해금 시스템~~ ✅ (10분 생존 해금)
- [x] ~~캐릭터별 고유 패시브~~ ✅ (로지: XP+15%, 프릿츠: 쿨다운-10%)

### 에셋
- [x] ~~픽셀아트 스프라이트 (모든 엔티티)~~ ✅ (32종 생성 + Sprite2D 통합)
- [x] ~~타일셋~~ ✅ (마을 광장 + 묘지 32x32 심리스 타일, 장식물 9종)
- [x] ~~UI 아이콘~~ ✅ (무기 아이콘 8종 + 패시브 아이콘 10종, 16x16 TextureRect)
- [x] ~~BGM / SFX~~ ✅ (BGM 5종: 타이틀/스테이지2종/보스2종, SFX 19종: 전투/UI/이벤트)

### UX 연출
- [x] ~~설정: 화면 흔들림/데미지 숫자 ON/OFF~~ ✅
- [x] ~~사망 슬로우모션~~ ✅ (Engine.time_scale 0.3, 0.5초)
- [x] ~~클리어/사망 결과 화면 구분~~ ✅ ("클리어!" vs "밤이 끝났다...")
- [x] ~~결과 화면: 무기 목록 + 발견 단서 표시~~ ✅
- [x] ~~일시정지 런 요약~~ ✅ (무기, 패시브, 시간, 레벨)
- [x] ~~HUD 무기 아이콘~~ ✅ (TopBar에 색상 사각형)
- [x] ~~레벨업 카드 신규무기 금색 헤더~~ ✅
- [x] ~~런 시작 3초 카운트다운~~ ✅
- [x] ~~보스2 등장 시 스폰 70% 감소~~ ✅
- [x] ~~기억 조각 공식 수정~~ ✅ (GDD 9.2: 일반1/엘리트10/보스50/분당5)
- [x] ~~일시정지 설정 접근~~ ✅ ([S] 설정, ESC 돌아가기)
- [x] ~~타이틀 종료 버튼~~ ✅ ([Q] 종료)
- [x] ~~타이틀 기억 조각 보유량 표시~~ ✅
- [x] ~~인디케이터 색상 GDD 준수~~ ✅ (일반=적, 엘리트=자홍, 보스=금)
- [x] ~~보스 페이즈 전환 표시~~ ✅ ("Phase X!" 텍스트)
- [x] ~~보스 is_boss_entity()~~ ✅ (인디케이터 금색 표시용)
- [x] ~~승리 슬로우모션 + 메시지~~ ✅ ("저주가 약해지고 있다..." 2초)

### 기타
- [x] ~~AudioManager 구현~~ ✅ (볼륨 관리 + ConfigFile 저장)
- [x] ~~크리티컬 히트 시스템~~ ✅ (calc_final_damage, 1.5x 배율, 금색+1.5x 크기 팝업)
- [x] ~~스테이지 2: 뒤틀린 묘지~~ ✅ (StageData + 안개 + 고유 적 조합)
- [x] ~~메타 업그레이드 방어력~~ ✅ (끈기의 기억 → 고정 데미지 감소)
- [x] ~~메타 업그레이드 드롭률~~ ✅ (행운의 기억 → 맵 아이템 드롭 확률 증가)
- [x] ~~HUD 기억 조각 표시~~ ✅ (금색 라벨, gold_pouch 수집 시 실시간 갱신)
- [x] ~~풀스크린 토글~~ ✅ (설정 7번째 항목, DisplayServer API)
- [x] ~~마을 일기 단서 발견~~ ✅ (보물상자 열 때 20% 확률)
- [x] ~~벽화 단서 발견~~ ✅ (15분 생존 시 자동 발견)
- [x] ~~해상도 선택~~ ✅ (설정 8번째 항목, 2x~6x 스케일)
- [x] ~~보물상자 강화 선택지~~ ✅ (무기 레벨업 우선, generate_treasure_choices)
- [x] ~~패시브 값 GDD 일치~~ ✅ (자석 30%/Lv, 재생 0.2/Lv)
- [x] ~~보스 사망 대사~~ ✅ (그림홀트/마녀의사자 대사 2초 표시, 승리 연출 딜레이 연동)
- [x] ~~석양 카운트다운~~ ✅ (해질녘→밤 색상 전환, Tween 3초)
- [x] ~~적 스폰 유예~~ ✅ (GDD 준수 5초)
- [x] ~~키 리바인딩~~ ✅ (InputMap 기반, 설정→조작 설정 서브메뉴, ConfigFile 저장)
- [x] ~~언어 선택 (한국어/영어)~~ ✅ (LocaleManager 싱글톤, 60+ 번역 키, 전체 UI 적용)
- [x] ~~맵 경계 시스템~~ ✅ (StageData.map_half_size, 플레이어+스폰 클램핑, 경계선 표시)
- [x] ~~스테이지 2 번개 효과~~ ✅ (StageData.lightning_enabled, 8~15초 간격 화면 플래시)

### 디자인 폴리시
- [x] ~~UITheme 공통 스타일~~ ✅ (shared/ui_theme.gd, 색상 팔레트+StyleBox 빌더)
- [x] ~~UI 전체 리디자인~~ ✅ (13개 UI, 패널/테두리/색상 통일, 타이틀 파티클)
- [x] ~~스프라이트 품질 개선~~ ✅ (32종 재생성, 음영 3단계, idle 2프레임 애니메이션)
- [x] ~~비네팅 + 플레이어 글로우~~ ✅ (assets/fx/, CanvasLayer 오버레이)
- [x] ~~타일 변형~~ ✅ (스테이지별 2종 타일 혼합 배치)
- [x] ~~장식물 4종 추가~~ ✅ (우물, 수레, 버섯, 부서진 관)
- [x] ~~사망 파티클 개선~~ ✅ (6개+색상 변형+크기 랜덤)
- [x] ~~피격 스케일 펀치~~ ✅ (1.15x 스케일 충격)
- [x] ~~씬 페이드 전환~~ ✅ (main.gd TransitionLayer, 0.5초 페이드 인/아웃)
- [x] ~~이동 방향 전환~~ ✅ (플레이어/적 flip_h)

### 버그 수정 (QA)
- [x] ~~HP바 색상 테마 불일치~~ ✅ (초록→핏빛 3단계)
- [x] ~~CanvasModulate 안개 알파 버그~~ ✅ (RGB만 반전, 알파 1.0 고정)
- [x] ~~캐릭터 선택 무기명 raw 표시~~ ✅ (WeaponData.weapon_name 사용)
- [x] ~~HUD 킬카운트 잘림~~ ✅ (TopBar 좌우 마진)
- [x] ~~제단/일시정지 색상 테마 불일치~~ ✅ (GOLD/CREAM으로 통일)
- [x] ~~보스 투사체 데미지 미적용~~ ✅ (body_entered 시그널 연결)
---

## 기술적 패턴

### 풀링 패턴
```
PoolManager.acquire(SCENE) → 노드 반환 (새로 생성 or 풀에서 재사용)
activate(data, position, ...) → 초기화 + 표시
deactivate() → 숨김 + 그룹 제거 + 콜리전 비활성화
PoolManager.release(SCENE, node) → 풀에 반환
```

### 노드 캐시 패턴 (풀링 호환)
```gdscript
# @onready 대신 사용 — 풀에서 재활성화 시에도 안전
func _cache_nodes() -> void:
    if _placeholder == null:
        _placeholder = get_node_or_null("Placeholder")
```

### 무기 생성 패턴
```gdscript
var weapon := Node2D.new()
weapon.set_script(load("res://entities/weapons/some_weapon.gd"))
weapon.name = "WeaponName"
owner_node.add_child(weapon)
weapon.initialize(weapon_data, owner_node)
```

### 패시브 스탯 재계산 패턴
```gdscript
# Player._recalculate_stats()
# 기본 스탯(_base_max_hp, _base_move_speed) × 패시브 배율로 최종 스탯 계산
# 패시브 획득/레벨업 시마다 호출
var hp_mult := 1.0
for p_name in _passives:
    var info = _passives[p_name]
    if info["data"].stat_key == "max_hp_percent":
        hp_mult += info["data"].value_per_level * info["level"]
max_hp = _base_max_hp * hp_mult
```

### GDScript 타입 주의사항
```gdscript
# Godot 4는 ternary/혼합 연산에서 타입 추론 실패
var x: float = condition if a else b     # OK
var x := condition if a else b           # ERROR
```
