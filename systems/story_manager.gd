extends Node
## 단서 발견 기록, story_flags 갱신, 조건 기반 대사 제공을 담당한다.
## Autoload 싱글톤: StoryManager


signal clue_discovered(clue_id: String)

## NPC 대화 데이터. condition 키는 _check_npc_condition()에서 평가한다.
const NPC_DATA: Dictionary = {
	"elder": {
		"name": "마을 노파",
		"color": Color(0.7, 0.6, 0.9, 1),
		"dialogues": [
			{
				"condition": "always",
				"text": "밤마다 깨어나는구나... 너도 저주를 기억하는 자인가. 조심하거라, 밤이 깊을수록 괴물은 더 강해진다.",
			},
			{
				"condition": "survived_10min",
				"text": "오래 버티는구나. 예전에도 각성자가 있었지... 대부분 미쳐버렸지만. 기억을 모아라. 기억만이 무기다.",
			},
			{
				"condition": "boss1_killed",
				"text": "영주를 쓰러뜨렸다고? 그 영주... 한때는 마을을 지키려 했어. 마녀와 거래한 것도 마을을 위해서였지.",
			},
			{
				"condition": "boss2_killed",
				"text": "마녀의 사자마저... 이제 진실에 가까워지고 있어. 탑에 무엇이 있는지, 곧 알게 될 거다.",
			},
		],
	},
	"blacksmith": {
		"name": "대장장이 견습생",
		"color": Color(0.9, 0.6, 0.3, 1),
		"dialogues": [
			{
				"condition": "fritz_unlocked",
				"text": "프릿츠 영감이 살아 있었구나! 그 시계탑의 비밀을 아는 유일한 사람이야. 무기를 끝까지 갈고닦으면 진화할 수 있다는 거 알지?",
			},
			{
				"condition": "boss1_killed",
				"text": "영주의 왕좌... 저주에 먹힌 거야. 무기와 능력을 잘 조합하면 더 강한 무기로 진화할 수 있어. 한번 시도해봐.",
			},
			{
				"condition": "boss2_killed",
				"text": "마녀의 사자가 쓰던 망토... 특별한 금속으로 만들어진 거였어. 이 마을의 대장간에서 만든 게 아니야.",
			},
		],
	},
	"innkeeper": {
		"name": "술집 주인",
		"color": Color(0.5, 0.8, 0.6, 1),
		"dialogues": [
			{
				"condition": "boss1_killed",
				"text": "영주가 쓰러지다니... 사실 이 마을의 역사는 꽤 어두워. 창시자들이 마녀와 거래한 건 풍요가 아니라 지배력이었어.",
			},
			{
				"condition": "boss2_killed",
				"text": "마녀 모르가나... 원래는 이 마을의 치료사였어. 마을 사람들이 배신하고 봉인한 거지. 저주는 그녀의 분노야.",
			},
			{
				"condition": "all_clues",
				"text": "모든 단서를 모았구나. 이제 진실을 알겠지? 저주를 풀려면 마녀를 처치하는 게 아니라... 용서를 구해야 해.",
			},
		],
	},
}

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


func check_npc_condition(condition: String) -> bool:
	match condition:
		"always":
			return true
		"survived_10min":
			return GameManager.meta.best_survival_time >= 600.0
		"fritz_unlocked":
			return GameManager.meta.fritz_unlocked
		"boss1_killed":
			return GameManager.meta.boss_kills >= 1
		"boss2_killed":
			return GameManager.meta.boss_kills >= 2
		"all_clues":
			return get_discovered_clues().size() >= CLUES.size()
	return false


func get_npc_dialogues(npc_id: String) -> Array[String]:
	if not NPC_DATA.has(npc_id):
		return []
	var result: Array[String] = []
	var dialogues: Array = NPC_DATA[npc_id]["dialogues"]
	for entry: Dictionary in dialogues:
		if check_npc_condition(entry["condition"]):
			result.append(entry["text"])
	return result


func is_npc_unlocked(npc_id: String) -> bool:
	return not get_npc_dialogues(npc_id).is_empty()


func _on_run_started() -> void:
	_discovered_this_run.clear()
