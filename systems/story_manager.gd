extends Node
## 단서 발견 기록, story_flags 갱신, 조건 기반 대사 제공을 담당한다.
## Autoload 싱글톤: StoryManager


signal clue_discovered(clue_id: String)

const CLUES: Dictionary = {
	"lord_diary": {
		"name": "영주의 일기 조각",
		"text": "\"이 마을은... 처음부터 저주받았다. 마녀 모르가나의 봉인이 풀리는 날, 모든 것이 끝날 것이다.\"",
	},
	"witch_seal": {
		"name": "마녀의 봉인 파편",
		"text": "\"주인님이... 탑에서... 기다리고 있다... 봉인의 열쇠는 밤의 기억 속에...\"",
	},
	"village_diary": {
		"name": "마을 주민의 일기",
		"text": "\"밤마다 이상한 소리가 들린다. 꽃들이 이빨을 드러내고, 인형들이 움직인다. 여긴 더 이상 안전하지 않다.\"",
	},
	"wall_painting": {
		"name": "고대 벽화 조각",
		"text": "\"오래 전, 이 마을은 마녀와 계약을 맺었다. 영원한 번영의 대가는... 영원한 밤.\"",
	},
}

## 현재 런에서 발견된 단서
var _discovered_this_run: Array[String] = []


func _ready() -> void:
	GameManager.run_started.connect(_on_run_started)


func discover_clue(clue_id: String) -> void:
	if not CLUES.has(clue_id):
		return
	var meta_key := "clue_" + clue_id
	if GameManager.meta.get(meta_key) == true:
		return
	GameManager.meta.set(meta_key, true)
	GameManager._save_meta()
	_discovered_this_run.append(clue_id)
	clue_discovered.emit(clue_id)


func is_clue_discovered(clue_id: String) -> bool:
	var meta_key := "clue_" + clue_id
	return GameManager.meta.get(meta_key) == true


func get_discovered_clues() -> Array[String]:
	var result: Array[String] = []
	for clue_id: String in CLUES:
		if is_clue_discovered(clue_id):
			result.append(clue_id)
	return result


func get_clue_name(clue_id: String) -> String:
	if CLUES.has(clue_id):
		return CLUES[clue_id]["name"]
	return "???"


func get_clue_text(clue_id: String) -> String:
	if CLUES.has(clue_id):
		return CLUES[clue_id]["text"]
	return ""


func get_run_discoveries() -> Array[String]:
	return _discovered_this_run


func _on_run_started() -> void:
	_discovered_this_run.clear()
