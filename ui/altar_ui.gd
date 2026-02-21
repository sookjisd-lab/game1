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
var _selector_rect: ColorRect = null


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
		var bar: ColorRect = row["bar"]

		level_label.text = "Lv.%d/%d" % [current_level, info["max"]]

		# 레벨 바 너비 업데이트
		var ratio: float = float(current_level) / float(info["max"])
		bar.custom_minimum_size.x = int(40 * ratio)

		if current_level >= info["max"]:
			cost_label.text = "MAX"
			cost_label.add_theme_color_override("font_color", UITheme.GOLD)
			bar.color = UITheme.GOLD_DIM
		else:
			var cost: int = info["costs"][current_level]
			cost_label.text = "%d" % cost
			var can_afford: bool = GameManager.meta.memory_shards >= cost
			cost_label.add_theme_color_override("font_color", UITheme.GOLD if can_afford else UITheme.TEXT_DISABLED)
			bar.color = UITheme.PURPLE_DIM

		var is_sel: bool = i == _selected
		name_label.add_theme_color_override("font_color", UITheme.SELECT_ACTIVE if is_sel else UITheme.TEXT_NORMAL)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
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
	UITheme.apply_heading_style(title, UITheme.GOLD)
	vbox.add_child(title)

	_shards_label = Label.new()
	_shards_label.text = LocaleManager.tr_text("memory_shards_fmt") % 0
	UITheme.apply_body_style(_shards_label, UITheme.GOLD_DIM)
	_shards_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
	vbox.add_child(_shards_label)

	var sep := UITheme.make_separator()
	sep.custom_minimum_size = Vector2(200, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(sep)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 1)

	for info: Dictionary in UPGRADES:
		var name_label := Label.new()
		name_label.text = info["name"]
		name_label.custom_minimum_size = Vector2(80, 0)
		name_label.add_theme_color_override("font_color", UITheme.TEXT_NORMAL)
		grid.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = info["desc"]
		desc_label.custom_minimum_size = Vector2(70, 0)
		desc_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		desc_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
		grid.add_child(desc_label)

		# 레벨 진행 바
		var bar_bg := ColorRect.new()
		bar_bg.color = Color(0.15, 0.1, 0.2, 0.5)
		bar_bg.custom_minimum_size = Vector2(40, 6)
		var bar_fill := ColorRect.new()
		bar_fill.color = UITheme.PURPLE_DIM
		bar_fill.custom_minimum_size = Vector2(0, 6)
		bar_bg.add_child(bar_fill)
		grid.add_child(bar_bg)

		var level_label := Label.new()
		level_label.text = "Lv.0/%d" % info["max"]
		level_label.custom_minimum_size = Vector2(42, 0)
		level_label.add_theme_color_override("font_color", UITheme.TEXT_NORMAL)
		level_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
		grid.add_child(level_label)

		var cost_label := Label.new()
		cost_label.text = "0"
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_label.custom_minimum_size = Vector2(30, 0)
		cost_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
		grid.add_child(cost_label)

		_rows.append({
			"name": name_label,
			"level": level_label,
			"cost": cost_label,
			"bar": bar_fill,
		})

	vbox.add_child(grid)

	var hint := Label.new()
	hint.text = LocaleManager.tr_text("altar_hint")
	UITheme.apply_hint_style(hint)
	vbox.add_child(hint)

	margin.add_child(vbox)
	bg.add_child(margin)
	add_child(bg)
