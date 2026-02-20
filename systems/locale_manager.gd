extends Node
## 간단한 한국어/영어 번역을 관리한다.
## Autoload 싱글톤: LocaleManager


signal language_changed

var current_language: String = "ko"

var _translations: Dictionary = {
	# 공통
	"game_title": {"ko": "저주받은 밤", "en": "Cursed Night"},
	"memory_shards_fmt": {"ko": "기억 조각: %d", "en": "Shards: %d"},
	# 타이틀
	"start": {"ko": "[SPACE] 시작", "en": "[SPACE] Start"},
	"altar": {"ko": "[A] 기억의 제단", "en": "[A] Altar"},
	"library": {"ko": "[L] 기억의 서재", "en": "[L] Library"},
	"npc_menu": {"ko": "[N] 각성자", "en": "[N] NPCs"},
	"settings_menu": {"ko": "[S] 설정", "en": "[S] Settings"},
	"quit": {"ko": "[Q] 종료", "en": "[Q] Quit"},
	# 캐릭터 선택
	"char_select": {"ko": "캐릭터 선택", "en": "Character Select"},
	"char_locked": {"ko": "??? (10분 이상 생존하여 해금)", "en": "??? (Survive 10+ min to unlock)"},
	"char_hint": {"ko": "[A/D] 선택  [SPACE] 확인  [ESC] 뒤로", "en": "[A/D] Select  [SPACE] OK  [ESC] Back"},
	# 스테이지 선택
	"stage_select": {"ko": "스테이지 선택", "en": "Stage Select"},
	"stage_locked": {"ko": "??? (스테이지 1 보스를 처치하여 해금)", "en": "??? (Defeat Stage 1 boss to unlock)"},
	"stage_hint": {"ko": "[A/D] 선택  [SPACE] 확인  [ESC] 뒤로", "en": "[A/D] Select  [SPACE] OK  [ESC] Back"},
	# 게임오버
	"victory": {"ko": "클리어!", "en": "Victory!"},
	"defeat": {"ko": "밤이 끝났다...", "en": "The night is over..."},
	"weapons_used": {"ko": "사용한 무기", "en": "Weapons Used"},
	"clues_found": {"ko": "발견한 단서", "en": "Clues Found"},
	# 일시정지
	"time_level_fmt": {"ko": "시간: %s  레벨: %d", "en": "Time: %s  Lv. %d"},
	"weapons_label": {"ko": "무기: ", "en": "Weapons: "},
	"passives_label": {"ko": "패시브: ", "en": "Passives: "},
	# 설정
	"settings_title": {"ko": "설정", "en": "Settings"},
	"master_vol": {"ko": "마스터 볼륨", "en": "Master Vol"},
	"bgm_vol": {"ko": "BGM 볼륨", "en": "BGM Vol"},
	"sfx_vol": {"ko": "SFX 볼륨", "en": "SFX Vol"},
	"indicator_toggle": {"ko": "오프스크린 표시", "en": "Offscreen Indicator"},
	"shake_toggle": {"ko": "화면 흔들림", "en": "Screen Shake"},
	"dmg_num_toggle": {"ko": "데미지 숫자", "en": "Damage Numbers"},
	"fullscreen": {"ko": "전체화면", "en": "Fullscreen"},
	"resolution": {"ko": "해상도", "en": "Resolution"},
	"keybind_menu": {"ko": "조작 설정", "en": "Key Bindings"},
	"language": {"ko": "언어", "en": "Language"},
	"lang_ko": {"ko": "한국어", "en": "한국어"},
	"lang_en": {"ko": "English", "en": "English"},
	"settings_hint": {"ko": "[W/S] 선택  [A/D] 조절  [ESC] 닫기", "en": "[W/S] Nav  [A/D] Adjust  [ESC] Close"},
	# 키 리바인딩
	"keybind_title": {"ko": "조작 설정", "en": "Key Bindings"},
	"move_up": {"ko": "위로 이동", "en": "Move Up"},
	"move_down": {"ko": "아래로 이동", "en": "Move Down"},
	"move_left": {"ko": "왼쪽 이동", "en": "Move Left"},
	"move_right": {"ko": "오른쪽 이동", "en": "Move Right"},
	"key_reset": {"ko": "키 초기화", "en": "Reset Keys"},
	"keybind_hint": {"ko": "[W/S] 선택  [ENTER] 변경  [ESC] 뒤로", "en": "[W/S] Nav  [ENTER] Rebind  [ESC] Back"},
	# 제단
	"altar_title": {"ko": "기억의 제단", "en": "Altar of Memories"},
	"altar_hint": {"ko": "[W/S] 선택  [SPACE] 구매  [ESC] 뒤로", "en": "[W/S] Nav  [SPACE] Buy  [ESC] Back"},
	# 서재
	"library_title": {"ko": "기억의 서재", "en": "Library of Memories"},
	"library_locked": {"ko": "아직 발견하지 못한 단서입니다.", "en": "Clue not yet discovered."},
	"library_hint": {"ko": "[W/S] 선택  [ESC] 닫기", "en": "[W/S] Nav  [ESC] Close"},
	# NPC
	"npc_title": {"ko": "각성자들", "en": "Awakened Ones"},
	"npc_locked": {"ko": "아직 만나지 못한 각성자입니다.", "en": "Not yet encountered."},
	"npc_dialogue_fmt": {"ko": "대화 %d개  [SPACE] 대화하기", "en": "%d Lines  [SPACE] Talk"},
	"npc_hint": {"ko": "[W/S] 선택  [ESC] 뒤로", "en": "[W/S] Nav  [ESC] Back"},
	# 보스 경고
	"boss_warning": {"ko": "!! WARNING !!", "en": "!! WARNING !!"},
	# 스테이지
	"curse_weakening": {"ko": "저주가 약해지고 있다...", "en": "The curse is weakening..."},
	# 제단 업그레이드
	"mem_hp": {"ko": "체력의 기억", "en": "Memory of Vitality"},
	"mem_hp_desc": {"ko": "최대 HP +5", "en": "Max HP +5"},
	"mem_atk": {"ko": "힘의 기억", "en": "Memory of Strength"},
	"mem_atk_desc": {"ko": "공격력 +3%", "en": "Attack +3%"},
	"mem_spd": {"ko": "민첩의 기억", "en": "Memory of Agility"},
	"mem_spd_desc": {"ko": "이동속도 +2%", "en": "Move Speed +2%"},
	"mem_xp": {"ko": "지혜의 기억", "en": "Memory of Wisdom"},
	"mem_xp_desc": {"ko": "경험치 +5%", "en": "XP +5%"},
	"mem_drop": {"ko": "행운의 기억", "en": "Memory of Fortune"},
	"mem_drop_desc": {"ko": "드롭률 +3%", "en": "Drop Rate +3%"},
	"mem_def": {"ko": "끈기의 기억", "en": "Memory of Tenacity"},
	"mem_def_desc": {"ko": "방어력 +2", "en": "Defense +2"},
	"mem_mag": {"ko": "수집의 기억", "en": "Memory of Collection"},
	"mem_mag_desc": {"ko": "자석 범위 +5%", "en": "Magnet Range +5%"},
	"mem_rev": {"ko": "부활의 기억", "en": "Memory of Revival"},
	"mem_rev_desc": {"ko": "런당 부활 +1", "en": "Revive +1 per run"},
	# 보스 사망 대사
	"grimholt_death": {"ko": "이 마을은... 처음부터 저주받을 운명이었어...", "en": "This town... was cursed from the very beginning..."},
	"witch_death": {"ko": "주인님이... 기다리고 계신다... 탑에서...", "en": "The mistress... awaits... in the tower..."},
}


func tr_text(key: String) -> String:
	if _translations.has(key):
		return _translations[key].get(current_language, key)
	return key


func set_language(lang: String) -> void:
	if lang != "ko" and lang != "en":
		return
	current_language = lang
	language_changed.emit()
