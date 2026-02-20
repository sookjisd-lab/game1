extends CanvasLayer
## 기억의 제단. 영구 업그레이드를 기억 조각으로 구매한다.


signal closed

const UPGRADES: Array[Dictionary] = [
	{ "key": "upgrade_hp", "name": "체력의 기억", "desc": "최대 HP +5", "max": 10, "costs": [10,20,35,55,80,110,145,185,230,280] },
	{ "key": "upgrade_attack", "name": "힘의 기억", "desc": "공격력 +3%", "max": 10, "costs": [10,20,35,55,80,110,145,185,230,280] },
	{ "key": "upgrade_speed", "name": "민첩의 기억", "desc": "이동속도 +2%", "max": 10, "costs": [10,20,35,55,80,110,145,185,230,280] },
	{ "key": "upgrade_xp", "name": "지혜의 기억", "desc": "경험치 +5%", "max": 10, "costs": [15,30,50,75,105,140,180,225,275,330] },
	{ "key": "upgrade_drop", "name": "행운의 기억", "desc": "드롭률 +3%", "max": 10, "costs": [15,30,50,75,105,140,180,225,275,330] },
	{ "key": "upgrade_defense", "name": "끈기의 기억", "desc": "방어력 +2", "max": 5, "costs": [50,100,175,275,400] },
	{ "key": "upgrade_magnet", "name": "수집의 기억", "desc": "자석 범위 +5%", "max": 5, "costs": [20,45,75,110,150] },
	{ "key": "upgrade_revive", "name": "부활의 기억", "desc": "런당 부활 +1", "max": 1, "costs": [500] },
]

var _rows: Array[Dictionary] = []
var _shards_label: Label
var _selected: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func show_altar() -> void:
	_selected = 0
	_refresh()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed):
		return

	match event.keycode:
		KEY_W, KEY_UP:
			_selected = maxi(_selected - 1, 0)
			_refresh()
		KEY_S, KEY_DOWN:
			_selected = mini(_selected + 1, UPGRADES.size() - 1)
			_refresh()
		KEY_SPACE, KEY_ENTER:
			_try_purchase(_selected)
		KEY_ESCAPE:
			visible = false
			closed.emit()


func _try_purchase(idx: int) -> void:
	var info: Dictionary = UPGRADES[idx]
	var current_level: int = GameManager.meta.get(info["key"])
	if current_level >= info["max"]:
		return
	var cost: int = info["costs"][current_level]
	if GameManager.meta.memory_shards < cost:
		return
	GameManager.meta.memory_shards -= cost
	GameManager.meta.set(info["key"], current_level + 1)
	GameManager._save_meta()
	_refresh()


func _refresh() -> void:
	_shards_label.text = LocaleManager.tr_text("memory_shards_fmt") % GameManager.meta.memory_shards
	for i in range(UPGRADES.size()):
		var info: Dictionary = UPGRADES[i]
		var row: Dictionary = _rows[i]
		var current_level: int = GameManager.meta.get(info["key"])
		var level_label: Label = row["level"]
		var cost_label: Label = row["cost"]
		var name_label: Label = row["name"]

		level_label.text = "Lv.%d/%d" % [current_level, info["max"]]

		if current_level >= info["max"]:
			cost_label.text = "MAX"
			cost_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			var cost: int = info["costs"][current_level]
			cost_label.text = "%d" % cost
			var can_afford: bool = GameManager.meta.memory_shards >= cost
			var c: Color = Color.WHITE if can_afford else Color(0.5, 0.5, 0.5, 1)
			cost_label.add_theme_color_override("font_color", c)

		var sel_color: Color = Color.GOLD if i == _selected else Color.WHITE
		name_label.add_theme_color_override("font_color", sel_color)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var title := Label.new()
	title.text = LocaleManager.tr_text("altar_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.GOLD)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	_shards_label = Label.new()
	_shards_label.text = LocaleManager.tr_text("memory_shards_fmt") % 0
	_shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shards_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	vbox.add_child(_shards_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 1)

	for info: Dictionary in UPGRADES:
		var name_label := Label.new()
		name_label.text = info["name"]
		name_label.custom_minimum_size = Vector2(90, 0)
		grid.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = info["desc"]
		desc_label.custom_minimum_size = Vector2(80, 0)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		grid.add_child(desc_label)

		var level_label := Label.new()
		level_label.text = "Lv.0/%d" % info["max"]
		level_label.custom_minimum_size = Vector2(50, 0)
		grid.add_child(level_label)

		var cost_label := Label.new()
		cost_label.text = "0"
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_label.custom_minimum_size = Vector2(30, 0)
		grid.add_child(cost_label)

		_rows.append({
			"name": name_label,
			"level": level_label,
			"cost": cost_label,
		})

	vbox.add_child(grid)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("altar_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(hint)

	margin.add_child(vbox)
	bg.add_child(margin)
	add_child(bg)
