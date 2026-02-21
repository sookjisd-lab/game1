extends CanvasLayer
## 타이틀 화면. '피 묻은 동화책' 분위기의 배경과 메뉴를 표시한다.


signal start_pressed
signal altar_pressed
signal settings_pressed
signal library_pressed
signal npc_pressed

var _shards_label: Label = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _menu_labels: Array[Label] = []
var _fog_rects: Array[ColorRect] = []
var _fog_time: float = 0.0
var _particle_rects: Array[ColorRect] = []
const MENU_KEYS: Array[String] = ["start", "altar", "library", "npc_menu", "settings_menu", "quit"]
const MENU_ICONS: Array[String] = [">>", "**", "[]", "@@", "~~", "XX"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	LocaleManager.language_changed.connect(_retranslate)


func show_title() -> void:
	_retranslate()
	if _shards_label != null:
		_shards_label.text = LocaleManager.tr_text("memory_shards_fmt") % GameManager.meta.memory_shards
	visible = true
	_fog_time = 0.0
	AudioManager.play_bgm("res://assets/audio/bgm/title.wav")


func _retranslate() -> void:
	_title_label.text = LocaleManager.tr_text("game_title")
	for i in range(MENU_KEYS.size()):
		if i < _menu_labels.size():
			_menu_labels[i].text = "  %s  %s" % [MENU_ICONS[i], LocaleManager.tr_text(MENU_KEYS[i])]


func _process(delta: float) -> void:
	if not visible:
		return
	_fog_time += delta
	_animate_fog()
	_animate_particles(delta)


func _animate_fog() -> void:
	for i in range(_fog_rects.size()):
		var rect: ColorRect = _fog_rects[i]
		var phase: float = _fog_time * (0.3 + i * 0.15) + i * 2.0
		var alpha: float = (sin(phase) + 1.0) * 0.03 + 0.02
		rect.color = Color(0.25, 0.15, 0.35, alpha)


func _animate_particles(delta: float) -> void:
	for rect: ColorRect in _particle_rects:
		rect.position.y -= delta * (8.0 + randf() * 4.0)
		rect.modulate.a -= delta * 0.15
		if rect.position.y < -10 or rect.modulate.a <= 0.0:
			rect.position = Vector2(randf() * 320.0, 160.0 + randf() * 40.0)
			rect.modulate.a = 0.3 + randf() * 0.4


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE, KEY_ENTER:
				AudioManager.play_sfx("res://assets/audio/sfx/ui_confirm.wav")
				visible = false
				start_pressed.emit()
			KEY_A:
				AudioManager.play_sfx("res://assets/audio/sfx/ui_select.wav")
				visible = false
				altar_pressed.emit()
			KEY_S:
				AudioManager.play_sfx("res://assets/audio/sfx/ui_select.wav")
				visible = false
				settings_pressed.emit()
			KEY_L:
				AudioManager.play_sfx("res://assets/audio/sfx/ui_select.wav")
				visible = false
				library_pressed.emit()
			KEY_N:
				AudioManager.play_sfx("res://assets/audio/sfx/ui_select.wav")
				visible = false
				npc_pressed.emit()
			KEY_Q:
				get_tree().quit()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 안개 레이어 (3개 겹침)
	for i in range(3):
		var fog := ColorRect.new()
		fog.color = Color(0.25, 0.15, 0.35, 0.04)
		fog.set_anchors_preset(Control.PRESET_FULL_RECT)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(fog)
		_fog_rects.append(fog)

	# 떠오르는 파티클 (먼지/불씨 느낌)
	for i in range(12):
		var p := ColorRect.new()
		p.size = Vector2(1, 1)
		p.position = Vector2(randf() * 320.0, randf() * 180.0)
		p.color = UITheme.GOLD_DIM
		p.modulate.a = 0.2 + randf() * 0.3
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(p)
		_particle_rects.append(p)

	# 상단 장식선
	var top_line := ColorRect.new()
	top_line.color = UITheme.BORDER_GOLD
	top_line.custom_minimum_size = Vector2(320, 1)
	top_line.position = Vector2(0, 20)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(top_line)

	# 하단 장식선
	var bot_line := ColorRect.new()
	bot_line.color = UITheme.BORDER_GOLD
	bot_line.custom_minimum_size = Vector2(320, 1)
	bot_line.position = Vector2(0, 158)
	bot_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(bot_line)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)

	# 게임 제목
	_title_label = Label.new()
	_title_label.text = LocaleManager.tr_text("game_title")
	UITheme.apply_title_style(_title_label)
	vbox.add_child(_title_label)

	# 영문 부제
	_subtitle_label = Label.new()
	_subtitle_label.text = "Cursed Night"
	UITheme.apply_body_style(_subtitle_label, UITheme.PURPLE_DIM)
	_subtitle_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
	vbox.add_child(_subtitle_label)

	# 구분선
	var sep := UITheme.make_separator()
	sep.custom_minimum_size = Vector2(120, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(sep)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# 메뉴 항목들
	var menu_colors: Array[Color] = [
		UITheme.TEXT_BRIGHT,
		UITheme.GOLD,
		UITheme.PURPLE,
		UITheme.CREAM,
		UITheme.TEXT_NORMAL,
		UITheme.BLOOD_LIGHT,
	]
	for i in range(MENU_KEYS.size()):
		var label := Label.new()
		label.text = "  %s  %s" % [MENU_ICONS[i], LocaleManager.tr_text(MENU_KEYS[i])]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", menu_colors[i])
		vbox.add_child(label)
		_menu_labels.append(label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer2)

	# 기억 조각 표시
	_shards_label = Label.new()
	_shards_label.text = ""
	UITheme.apply_body_style(_shards_label, UITheme.GOLD_DIM)
	_shards_label.add_theme_font_size_override("font_size", UITheme.SMALL_FONT_SIZE)
	vbox.add_child(_shards_label)

	center.add_child(vbox)
	bg.add_child(center)
	add_child(bg)
