extends Node2D
## 기본 스테이지 씬. 플레이어 배치와 카메라 추적을 담당한다.


const HUD_SCENE: PackedScene = preload("res://ui/hud.tscn")
const LEVEL_UP_UI_SCENE: PackedScene = preload("res://ui/level_up_ui.tscn")
const GAME_OVER_UI_SCENE: PackedScene = preload("res://ui/game_over_ui.tscn")
const PAUSE_UI_SCENE: PackedScene = preload("res://ui/pause_ui.tscn")
const BOSS_HP_BAR_SCENE: PackedScene = preload("res://ui/boss_hp_bar.tscn")
const TREASURE_UI_SCENE: PackedScene = preload("res://ui/treasure_ui.tscn")
const BOSS_WARNING_SCENE: PackedScene = preload("res://ui/boss_warning.tscn")
const OFFSCREEN_INDICATOR_SCENE: PackedScene = preload("res://ui/offscreen_indicator.tscn")

var character_data: CharacterData = null
var stage_data: StageData = null

@onready var _player: CharacterBody2D = $Player
var _hud: CanvasLayer = null
var _level_up_ui: CanvasLayer = null
var _game_over_ui: CanvasLayer = null
var _boss_hp_bar: CanvasLayer = null
var _treasure_ui: CanvasLayer = null
var _boss_warning: CanvasLayer = null
var _pending_boss_name: String = ""
var _countdown_active: bool = false
var _wall_painting_discovered: bool = false
var _lightning_rect: ColorRect = null
var _lightning_timer: float = 0.0
var _player_glow: Sprite2D = null


func _ready() -> void:
	if character_data == null:
		character_data = preload("res://data/characters/rosie.tres")
	if stage_data == null:
		stage_data = preload("res://data/stages/stage1_town.tres")
	_player.global_position = Vector2(
		Constants.VIEWPORT_WIDTH / 2.0,
		Constants.VIEWPORT_HEIGHT / 2.0
	)
	_setup_hud()
	_player.init_character(character_data)
	_player.set_map_bounds(stage_data.map_half_size)
	SpawnManager.register_stage(self, _player, stage_data)
	_apply_stage_visuals()
	DropManager.register(self, _player)
	UpgradeManager.register_player(_player, character_data.starting_weapon_script)
	DamageNumberManager.register_stage(self)
	GameManager.run_timer_updated.connect(_on_run_timer_updated)
	SpawnManager.boss_warning.connect(_on_boss_warning)
	SpawnManager.boss_spawned.connect(_on_boss_spawned)
	SpawnManager.boss_defeated.connect(_on_boss_defeated)
	_player.player_died.connect(_on_player_died)
	_player.leveled_up.connect(_on_player_leveled_up)
	UpgradeManager.upgrade_applied.connect(_on_upgrade_applied)
	DropManager.treasure_chest_collected.connect(_on_treasure_chest_collected)
	_setup_level_up_ui()
	_setup_game_over_ui()
	_setup_pause_ui()
	_setup_boss_hp_bar()
	_setup_treasure_ui()
	_setup_boss_warning()
	_setup_offscreen_indicator()
	_setup_lightning()
	_build_map()
	_setup_vignette()
	_setup_player_glow()
	_start_bgm()
	_start_countdown()


func _setup_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.connect_player(_player)


func _setup_level_up_ui() -> void:
	_level_up_ui = LEVEL_UP_UI_SCENE.instantiate()
	add_child(_level_up_ui)


func _setup_pause_ui() -> void:
	var pause_ui := PAUSE_UI_SCENE.instantiate()
	add_child(pause_ui)
	pause_ui.register_player(_player)


func _setup_game_over_ui() -> void:
	_game_over_ui = GAME_OVER_UI_SCENE.instantiate()
	add_child(_game_over_ui)


func _setup_boss_hp_bar() -> void:
	_boss_hp_bar = BOSS_HP_BAR_SCENE.instantiate()
	add_child(_boss_hp_bar)


func _setup_treasure_ui() -> void:
	_treasure_ui = TREASURE_UI_SCENE.instantiate()
	add_child(_treasure_ui)


func _on_run_timer_updated(elapsed: float) -> void:
	if not _wall_painting_discovered and elapsed >= 900.0:
		_wall_painting_discovered = true
		StoryManager.discover_clue("wall_painting")


func _on_player_died() -> void:
	GameManager.end_run(false)
	AudioManager.play_sfx("res://assets/audio/sfx/game_over.wav")
	AudioManager.stop_bgm()
	Engine.time_scale = 0.3
	get_tree().create_timer(0.5 * 0.3).timeout.connect(_show_death_results)


func _show_death_results() -> void:
	Engine.time_scale = 1.0
	_game_over_ui.show_results(
		GameManager.run_elapsed_time,
		SpawnManager.total_kills,
		_player.current_level,
		DropManager.total_xp,
		false,
		_get_weapon_names(),
		StoryManager.get_run_discoveries(),
	)


func _on_player_leveled_up(_new_level: int) -> void:
	GameManager.change_state(Enums.GameState.LEVEL_UP)
	var choices := UpgradeManager.generate_choices(Constants.LEVEL_UP_CHOICES)
	_level_up_ui.show_choices(choices)


func _setup_offscreen_indicator() -> void:
	var indicator := OFFSCREEN_INDICATOR_SCENE.instantiate()
	add_child(indicator)
	indicator.register_player(_player)


func _setup_boss_warning() -> void:
	_boss_warning = BOSS_WARNING_SCENE.instantiate()
	add_child(_boss_warning)
	_boss_warning.warning_finished.connect(_on_boss_warning_finished)


func _on_boss_warning(boss_name: String) -> void:
	_pending_boss_name = boss_name
	_boss_warning.play_warning(boss_name)
	AudioManager.play_sfx("res://assets/audio/sfx/boss_warning.wav")


func _on_boss_warning_finished() -> void:
	SpawnManager.trigger_boss_spawn()


func _on_upgrade_applied(_data: UpgradeData) -> void:
	if not UpgradeManager.has_pending_evolutions():
		return
	if GameManager.current_state != Enums.GameState.PLAYING:
		return
	call_deferred("_show_treasure")


func _show_treasure() -> void:
	var evolutions := UpgradeManager.get_available_evolutions()
	if evolutions.is_empty():
		return
	GameManager.change_state(Enums.GameState.TREASURE)
	_treasure_ui.show_choices(evolutions)


func _on_treasure_chest_collected() -> void:
	if GameManager.current_state != Enums.GameState.PLAYING:
		return
	if randf() < 0.2:
		StoryManager.discover_clue("village_diary")
	var choices := UpgradeManager.generate_treasure_choices(Constants.LEVEL_UP_CHOICES)
	if choices.is_empty():
		return
	GameManager.change_state(Enums.GameState.TREASURE)
	_treasure_ui.show_choices(choices)


func _on_boss_spawned(boss: Area2D) -> void:
	_boss_hp_bar.show_boss(_pending_boss_name, boss.current_hp, boss.max_hp)
	boss.boss_hp_changed.connect(_boss_hp_bar.update_hp)
	if boss.has_signal("boss_phase_changed"):
		boss.boss_phase_changed.connect(_boss_hp_bar.show_phase)
	if _pending_boss_name == "영주 그림홀트":
		AudioManager.play_bgm("res://assets/audio/bgm/boss_grimholt.wav")
	elif _pending_boss_name == "마녀의 사자":
		AudioManager.play_bgm("res://assets/audio/bgm/boss_witch.wav")


func _on_boss_defeated(is_victory: bool) -> void:
	_boss_hp_bar.hide_boss()
	AudioManager.play_sfx("res://assets/audio/sfx/boss_death.wav")
	if not is_victory and stage_data.bgm_path != "":
		AudioManager.play_bgm(stage_data.bgm_path)
	var death_line: String = ""
	if _pending_boss_name == "영주 그림홀트":
		StoryManager.discover_clue("lord_diary")
		death_line = LocaleManager.tr_text("grimholt_death")
	elif _pending_boss_name == "마녀의 사자":
		StoryManager.discover_clue("witch_seal")
		death_line = LocaleManager.tr_text("witch_death")
	if death_line != "":
		_show_boss_death_line(death_line)
	if is_victory:
		GameManager.end_run(true)
		AudioManager.play_sfx("res://assets/audio/sfx/victory.wav")
		AudioManager.stop_bgm()
		Engine.time_scale = 0.3
		var death_delay: float = 2.0 if death_line != "" else 0.0
		get_tree().create_timer(death_delay + 1.5, true, false, true).timeout.connect(_show_victory_message)
		get_tree().create_timer(death_delay + 3.5, true, false, true).timeout.connect(_show_victory_results)


func _show_boss_death_line(text: String) -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 25
	overlay.name = "BossDeathLine"
	add_child(overlay)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3, 1))
	label.text = text
	overlay.add_child(label)

	get_tree().create_timer(2.0, true, false, true).timeout.connect(
		func() -> void: overlay.queue_free()
	)


func _show_victory_message() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 25
	overlay.name = "VictoryMessage"
	add_child(overlay)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	label.text = LocaleManager.tr_text("curse_weakening")
	overlay.add_child(label)


func _show_victory_results() -> void:
	Engine.time_scale = 1.0
	var msg := get_node_or_null("VictoryMessage")
	if msg != null:
		msg.queue_free()
	_game_over_ui.show_results(
		GameManager.run_elapsed_time,
		SpawnManager.total_kills,
		_player.current_level,
		DropManager.total_xp,
		true,
		_get_weapon_names(),
		StoryManager.get_run_discoveries(),
	)


func _get_weapon_names() -> Array[String]:
	var names: Array[String] = []
	for weapon: WeaponBase in _player._weapons:
		names.append("%s Lv.%d" % [weapon.data.weapon_name, weapon.level])
	return names


func is_countdown_active() -> bool:
	return _countdown_active


func _start_countdown() -> void:
	_countdown_active = true
	var overlay := CanvasLayer.new()
	overlay.layer = 25
	overlay.name = "CountdownOverlay"
	add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	overlay.add_child(label)

	var sunset_color := Color(0.45, 0.2, 0.1, 0.7)
	var night_color := Color(0.05, 0.02, 0.1, 0.6)
	var sunset_text := Color(0.95, 0.85, 0.6, 1)
	var night_text := Color(0.9, 0.75, 0.5, 1)

	get_tree().paused = true
	bg.color = sunset_color
	label.add_theme_color_override("font_color", sunset_text)
	label.text = "3"
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bg, "color", night_color, 3.0)
	await get_tree().create_timer(1.0, true, false, true).timeout
	label.add_theme_color_override("font_color", night_text.lerp(sunset_text, 0.5))
	label.text = "2"
	await get_tree().create_timer(1.0, true, false, true).timeout
	label.add_theme_color_override("font_color", night_text)
	label.text = "1"
	await get_tree().create_timer(1.0, true, false, true).timeout
	overlay.queue_free()
	_countdown_active = false
	GameManager.start_run()


func _process(delta: float) -> void:
	if _player_glow != null:
		_player_glow.global_position = _player.global_position

	if _lightning_rect == null:
		return
	_lightning_timer -= delta
	if _lightning_timer <= 0.0:
		_flash_lightning()
		_lightning_timer = randf_range(
			stage_data.lightning_interval.x,
			stage_data.lightning_interval.y,
		)


func _setup_lightning() -> void:
	if not stage_data.lightning_enabled:
		return
	var overlay := CanvasLayer.new()
	overlay.layer = 5
	overlay.name = "LightningOverlay"
	add_child(overlay)
	_lightning_rect = ColorRect.new()
	_lightning_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lightning_rect.color = Color(0.9, 0.9, 1.0, 0.0)
	_lightning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_lightning_rect)
	_lightning_timer = randf_range(
		stage_data.lightning_interval.x,
		stage_data.lightning_interval.y,
	)


func _flash_lightning() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/thunder.wav")
	var tween := create_tween()
	tween.tween_property(_lightning_rect, "color:a", 0.3, 0.05)
	tween.tween_property(_lightning_rect, "color:a", 0.0, 0.15)


func _start_bgm() -> void:
	if stage_data.bgm_path != "":
		AudioManager.play_bgm(stage_data.bgm_path)


func _apply_stage_visuals() -> void:
	if stage_data.fog_enabled:
		var fog := CanvasModulate.new()
		fog.color = Color(1, 1, 1, 1) - stage_data.fog_color
		add_child(fog)


func _setup_vignette() -> void:
	if stage_data.vignette_strength <= 0.0:
		return
	var overlay := CanvasLayer.new()
	overlay.layer = 4
	overlay.name = "VignetteOverlay"
	add_child(overlay)
	var rect := TextureRect.new()
	rect.texture = preload("res://assets/fx/vignette.png")
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.modulate.a = stage_data.vignette_strength
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(rect)


func _setup_player_glow() -> void:
	if stage_data.player_glow_color.a <= 0.0:
		return
	_player_glow = Sprite2D.new()
	_player_glow.texture = preload("res://assets/fx/player_glow.png")
	_player_glow.modulate = stage_data.player_glow_color
	_player_glow.z_index = -7
	_player_glow.global_position = _player.global_position
	add_child(_player_glow)


## 배경 타일을 깔고 장식물을 배치한다.
func _build_map() -> void:
	var half: Vector2 = stage_data.map_half_size
	var hw: int = int(half.x)
	var hh: int = int(half.y)

	# 배경색
	var bg := ColorRect.new()
	bg.color = stage_data.bg_color
	bg.size = Vector2(hw * 2, hh * 2)
	bg.position = Vector2(-hw, -hh)
	bg.z_index = -10
	add_child(bg)

	# 타일 배경 (메인 + 변형 혼합)
	if stage_data.ground_texture_path != "":
		var tile_tex: Texture2D = load(stage_data.ground_texture_path)
		var variant_textures: Array[Texture2D] = []
		for vpath: String in stage_data.ground_variant_paths:
			variant_textures.append(load(vpath))
		var tile_size: int = 32
		var tile_rng := RandomNumberGenerator.new()
		tile_rng.seed = 99999
		for tx in range(-hw, hw, tile_size):
			for ty in range(-hh, hh, tile_size):
				var tile := Sprite2D.new()
				if not variant_textures.is_empty() and tile_rng.randf() < stage_data.variant_ratio:
					tile.texture = variant_textures[tile_rng.randi() % variant_textures.size()]
				else:
					tile.texture = tile_tex
				tile.centered = false
				tile.position = Vector2(tx, ty)
				tile.z_index = -9
				add_child(tile)

	# 장식물 배치
	if not stage_data.decoration_paths.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 12345
		var deco_count: int = int((hw * hh * 4.0) / (300.0 * 300.0))
		deco_count = clampi(deco_count, 20, 120)
		var deco_textures: Array[Texture2D] = []
		for path: String in stage_data.decoration_paths:
			deco_textures.append(load(path))
		for i in range(deco_count):
			var tex: Texture2D = deco_textures[rng.randi() % deco_textures.size()]
			var deco := Sprite2D.new()
			deco.texture = tex
			deco.position = Vector2(
				rng.randf_range(-hw + 16, hw - 16),
				rng.randf_range(-hh + 16, hh - 16),
			)
			deco.z_index = -8
			add_child(deco)

	# 맵 경계 표시
	var border_color := Color(0.6, 0.15, 0.15, 0.8)
	for border in [
		[Vector2(-hw, -hh), Vector2(hw, -hh)],
		[Vector2(-hw, hh), Vector2(hw, hh)],
		[Vector2(-hw, -hh), Vector2(-hw, hh)],
		[Vector2(hw, -hh), Vector2(hw, hh)],
	]:
		var line := Line2D.new()
		line.points = border
		line.width = 2
		line.default_color = border_color
		add_child(line)
