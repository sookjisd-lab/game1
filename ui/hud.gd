extends CanvasLayer
## 인게임 HUD. HP바, 런 타이머, 킬 카운트, 경험치를 표시한다.


@onready var _hp_bar: ProgressBar = $TopBar/HPBar
@onready var _timer_label: Label = $TopBar/TimerLabel
@onready var _kill_label: Label = $TopBar/KillLabel
@onready var _level_label: Label = $BottomBar/LevelLabel
@onready var _xp_bar: ProgressBar = $BottomBar/XPBar
@onready var _passive_bar: HBoxContainer = $PassiveBar

var _kill_count: int = 0
var _gold_count: int = 0
var _gold_label: Label = null
var _passive_icons: Array[Control] = []
var _weapon_bar: HBoxContainer = null
var _weapon_icons: Array[Control] = []


func _ready() -> void:
	GameManager.run_timer_updated.connect(_on_timer_updated)
	SpawnManager.enemy_killed.connect(_on_enemy_killed)
	DropManager.gold_collected.connect(_on_gold_collected)
	_build_weapon_bar()
	_build_gold_label()
	_update_timer(0.0)
	_update_kills(0)
	_update_gold(0)
	_update_level(1)
	_update_xp_bar(0, Constants.XP_BASE)


func connect_player(player: CharacterBody2D) -> void:
	player.hp_changed.connect(_on_hp_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.passives_changed.connect(_on_passives_changed.bind(player))
	UpgradeManager.upgrade_applied.connect(_on_upgrade_applied.bind(player))
	_on_hp_changed(player.current_hp, player.max_hp)
	_update_level(player.current_level)
	_update_xp_bar(player.current_xp, player.xp_to_next_level())
	_update_weapon_icons(player._weapons)


func add_kill() -> void:
	_kill_count += 1
	_update_kills(_kill_count)


func _on_hp_changed(current: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current


func _on_timer_updated(elapsed: float) -> void:
	_update_timer(elapsed)


func _on_enemy_killed() -> void:
	add_kill()


func _on_xp_changed(current: int, needed: int) -> void:
	_update_xp_bar(current, needed)


func _on_leveled_up(new_level: int) -> void:
	_update_level(new_level)


func _update_timer(elapsed: float) -> void:
	_timer_label.text = GameManager.format_time(elapsed)


func _update_kills(count: int) -> void:
	_kill_label.text = str(count)


func _update_gold(count: int) -> void:
	if _gold_label != null:
		_gold_label.text = str(count)


func _on_gold_collected(amount: int) -> void:
	_gold_count += amount
	_update_gold(_gold_count)


func _build_gold_label() -> void:
	_gold_label = Label.new()
	_gold_label.text = "0"
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4, 1))
	var top_bar: HBoxContainer = $TopBar
	top_bar.add_child(_gold_label)


func _update_level(level: int) -> void:
	_level_label.text = "Lv.%d" % level


func _update_xp_bar(current: int, needed: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = current


func _on_passives_changed(player: CharacterBody2D) -> void:
	_update_passive_icons(player._passives)


func _on_upgrade_applied(_data: UpgradeData, player: CharacterBody2D) -> void:
	_update_weapon_icons(player._weapons)


func _build_weapon_bar() -> void:
	_weapon_bar = HBoxContainer.new()
	_weapon_bar.add_theme_constant_override("separation", 1)
	var top_bar: HBoxContainer = $TopBar
	top_bar.add_child(_weapon_bar)
	top_bar.move_child(_weapon_bar, 1)


func _update_weapon_icons(weapons: Array[WeaponBase]) -> void:
	for icon in _weapon_icons:
		icon.queue_free()
	_weapon_icons.clear()

	for weapon: WeaponBase in weapons:
		var container := Control.new()
		container.custom_minimum_size = Vector2(10, 10)

		if weapon.data.icon_path != "":
			var tex_rect := TextureRect.new()
			tex_rect.texture = load(weapon.data.icon_path)
			tex_rect.custom_minimum_size = Vector2(8, 8)
			tex_rect.size = Vector2(8, 8)
			tex_rect.position = Vector2(1, 1)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(tex_rect)
		else:
			var color_rect := ColorRect.new()
			color_rect.color = weapon.data.projectile_color
			color_rect.size = Vector2(8, 8)
			color_rect.position = Vector2(1, 1)
			container.add_child(color_rect)

		_weapon_bar.add_child(container)
		_weapon_icons.append(container)


func _update_passive_icons(passives: Dictionary) -> void:
	for icon in _passive_icons:
		icon.queue_free()
	_passive_icons.clear()

	for p_name: String in passives:
		var info: Dictionary = passives[p_name]
		var p_data: PassiveData = info["data"]
		var p_level: int = info["level"]

		var container := Control.new()
		container.custom_minimum_size = Vector2(14, 10)

		if p_data.icon_path != "":
			var tex_rect := TextureRect.new()
			tex_rect.texture = load(p_data.icon_path)
			tex_rect.custom_minimum_size = Vector2(8, 8)
			tex_rect.size = Vector2(8, 8)
			tex_rect.position = Vector2(3, 0)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(tex_rect)
		else:
			var color_rect := ColorRect.new()
			color_rect.color = p_data.icon_color
			color_rect.size = Vector2(8, 8)
			color_rect.position = Vector2(3, 0)
			container.add_child(color_rect)

		var lv_label := Label.new()
		lv_label.text = str(p_level)
		lv_label.position = Vector2(2, -1)
		lv_label.add_theme_font_size_override("font_size", 8)
		lv_label.add_theme_color_override("font_color", Color.WHITE)
		container.add_child(lv_label)

		_passive_bar.add_child(container)
		_passive_icons.append(container)
