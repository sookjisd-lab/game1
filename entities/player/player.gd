extends CharacterBody2D
## 플레이어 이동과 상태를 관리한다.


signal hp_changed(current_hp: float, max_hp: float)
signal player_died
signal leveled_up(new_level: int)
signal xp_changed(current_xp: int, xp_needed: int)
signal passives_changed

@export var move_speed: float = Constants.PLAYER_BASE_SPEED
@export var max_hp: float = 120.0

var current_hp: float
var current_level: int = 1
var current_xp: int = 0
var damage_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var magnet_radius: float = Constants.BASE_MAGNET_RADIUS
var range_multiplier: float = 1.0
var xp_multiplier: float = 1.0
var crit_chance: float = 0.0
var hp_regen: float = 0.0
var dodge_chance: float = 0.0
var _regen_accumulator: float = 0.0
var _base_max_hp: float = 120.0
var _base_move_speed: float = Constants.PLAYER_BASE_SPEED
var _base_damage_mult: float = 1.0
var _base_xp_mult: float = 1.0
var _base_magnet: float = Constants.BASE_MAGNET_RADIUS
var _innate_stat_key: String = ""
var _innate_stat_value: float = 0.0
var _character_data: CharacterData = null
var _damage_cooldown: float = 0.0
var _revives_remaining: int = 0
var _weapons: Array[WeaponBase] = []
var _passives: Dictionary = {}  # passive_name → { "data": PassiveData, "level": int }

@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	DropManager.xp_collected.connect(_on_xp_collected)
	GameManager.state_changed.connect(_on_game_state_changed)


func init_character(data: CharacterData) -> void:
	_character_data = data
	_base_max_hp = data.base_hp + GameManager.get_meta_bonus_hp()
	_base_move_speed = data.base_speed * (1.0 + GameManager.get_meta_bonus_speed())
	_base_damage_mult = data.base_damage_mult + GameManager.get_meta_bonus_attack()
	_base_xp_mult = 1.0 + GameManager.get_meta_bonus_xp()
	_base_magnet = Constants.BASE_MAGNET_RADIUS * (1.0 + GameManager.get_meta_bonus_magnet())
	_innate_stat_key = data.passive_stat_key
	_innate_stat_value = data.passive_value
	max_hp = _base_max_hp
	move_speed = _base_move_speed
	damage_multiplier = _base_damage_mult
	xp_multiplier = _base_xp_mult
	magnet_radius = _base_magnet
	current_hp = max_hp
	_revives_remaining = GameManager.get_meta_revive_count()
	var placeholder := $Placeholder as ColorRect
	placeholder.color = data.sprite_color
	_equip_starting_weapon()
	hp_changed.emit(current_hp, max_hp)


func add_weapon(weapon: WeaponBase) -> void:
	if _weapons.size() >= Constants.MAX_WEAPONS:
		return
	weapon.initialize(weapon.data, self)
	_weapons.append(weapon)
	add_child(weapon)


func _equip_starting_weapon() -> void:
	if _character_data == null:
		return
	var weapon_data: WeaponData = load(_character_data.starting_weapon_data)
	var weapon_script: GDScript = load(_character_data.starting_weapon_script)
	var weapon := Node2D.new()
	weapon.set_script(weapon_script)
	weapon.name = weapon_data.weapon_name
	add_child(weapon)
	weapon.initialize(weapon_data, self)
	_weapons.append(weapon)


func _physics_process(delta: float) -> void:
	var input_direction := _get_input_direction()
	velocity = input_direction * move_speed
	move_and_slide()

	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta

	if hp_regen > 0.0 and current_hp < max_hp:
		_regen_accumulator += hp_regen * delta
		if _regen_accumulator >= 1.0:
			var heal_amount: float = floorf(_regen_accumulator)
			_regen_accumulator -= heal_amount
			current_hp = minf(current_hp + heal_amount, max_hp)
			hp_changed.emit(current_hp, max_hp)


func take_damage(amount: float) -> void:
	if _damage_cooldown > 0.0:
		return
	if dodge_chance > 0.0 and randf() < dodge_chance:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_damage_cooldown = 0.5
	hp_changed.emit(current_hp, max_hp)
	_flash_hit()
	_shake_camera()
	if current_hp <= 0.0:
		if _revives_remaining > 0:
			_revive()
		else:
			player_died.emit()


func _revive() -> void:
	_revives_remaining -= 1
	current_hp = max_hp * 0.5
	_damage_cooldown = 2.0
	hp_changed.emit(current_hp, max_hp)
	_flash_revive()


func _get_sprite_color() -> Color:
	return _character_data.sprite_color if _character_data != null else Color(0.96, 0.87, 0.7, 1)


func _flash_revive() -> void:
	var placeholder := $Placeholder as ColorRect
	placeholder.color = Color(1, 1, 0.5, 1)
	var original := _get_sprite_color()
	get_tree().create_timer(0.3).timeout.connect(
		func() -> void: placeholder.color = original
	)


func _get_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	return direction.normalized()


func _shake_camera() -> void:
	if not AudioManager.screen_shake_enabled:
		return
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var tween := create_tween()
	tween.tween_property(camera, "offset", Vector2(randf_range(-2, 2), randf_range(-2, 2)), 0.05)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)


func _flash_hit() -> void:
	var placeholder := $Placeholder as ColorRect
	var original_color := _get_sprite_color()
	placeholder.color = Color(1, 0.3, 0.3, 1)
	get_tree().create_timer(0.1).timeout.connect(
		func() -> void: placeholder.color = original_color
	)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		take_damage(area.data.contact_damage)


func xp_to_next_level() -> int:
	return Constants.XP_BASE + (current_level - 1) * Constants.XP_GROWTH


func add_xp(amount: int) -> void:
	current_xp += amount
	_check_levelup()


func _check_levelup() -> void:
	var needed := xp_to_next_level()
	if current_xp >= needed:
		current_xp -= needed
		current_level += 1
		xp_changed.emit(current_xp, xp_to_next_level())
		leveled_up.emit(current_level)
	else:
		xp_changed.emit(current_xp, needed)


func add_passive(passive_data: PassiveData) -> bool:
	if _passives.size() >= Constants.MAX_PASSIVES:
		return false
	if _passives.has(passive_data.passive_name):
		return false
	_passives[passive_data.passive_name] = { "data": passive_data, "level": 1 }
	_recalculate_stats()
	return true


func levelup_passive(passive_name: String) -> bool:
	if not _passives.has(passive_name):
		return false
	var info: Dictionary = _passives[passive_name]
	var data: PassiveData = info["data"]
	if info["level"] >= data.max_level:
		return false
	info["level"] += 1
	_recalculate_stats()
	return true


func _recalculate_stats() -> void:
	var hp_mult := 1.0
	var speed_mult := 1.0
	var damage_add := 0.0
	var cooldown_sub := 0.0
	var magnet_add := 0.0
	var range_add := 0.0
	var xp_add := 0.0
	var crit_add := 0.0
	var regen_add := 0.0
	var dodge_add := 0.0

	# 캐릭터 고유 패시브 적용
	match _innate_stat_key:
		"max_hp_percent":
			hp_mult += _innate_stat_value
		"move_speed_percent":
			speed_mult += _innate_stat_value
		"damage_percent":
			damage_add += _innate_stat_value
		"cooldown_percent":
			cooldown_sub += _innate_stat_value
		"magnet_percent":
			magnet_add += _innate_stat_value
		"range_percent":
			range_add += _innate_stat_value
		"xp_percent":
			xp_add += _innate_stat_value
		"crit_chance":
			crit_add += _innate_stat_value
		"hp_regen":
			regen_add += _innate_stat_value
		"dodge_chance":
			dodge_add += _innate_stat_value

	for p_name: String in _passives:
		var info: Dictionary = _passives[p_name]
		var data: PassiveData = info["data"]
		var lvl: int = info["level"]
		match data.stat_key:
			"max_hp_percent":
				hp_mult += data.value_per_level * lvl
			"move_speed_percent":
				speed_mult += data.value_per_level * lvl
			"damage_percent":
				damage_add += data.value_per_level * lvl
			"cooldown_percent":
				cooldown_sub += data.value_per_level * lvl
			"magnet_percent":
				magnet_add += data.value_per_level * lvl
			"range_percent":
				range_add += data.value_per_level * lvl
			"xp_percent":
				xp_add += data.value_per_level * lvl
			"crit_chance":
				crit_add += data.value_per_level * lvl
			"hp_regen":
				regen_add += data.value_per_level * lvl
			"dodge_chance":
				dodge_add += data.value_per_level * lvl

	var old_max_hp := max_hp
	max_hp = _base_max_hp * hp_mult
	move_speed = _base_move_speed * speed_mult
	damage_multiplier = _base_damage_mult + damage_add
	cooldown_multiplier = maxf(1.0 - cooldown_sub, 0.2)
	magnet_radius = _base_magnet * (1.0 + magnet_add)
	range_multiplier = 1.0 + range_add
	xp_multiplier = _base_xp_mult + xp_add
	crit_chance = crit_add
	dodge_chance = dodge_add
	hp_regen = regen_add

	if max_hp > old_max_hp:
		current_hp += max_hp - old_max_hp
	current_hp = minf(current_hp, max_hp)
	hp_changed.emit(current_hp, max_hp)
	passives_changed.emit()


func _on_xp_collected(amount: int) -> void:
	var modified: int = int(amount * xp_multiplier)
	add_xp(maxi(modified, 1))


func _on_game_state_changed(
		old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if old_state == Enums.GameState.LEVEL_UP and new_state == Enums.GameState.PLAYING:
		_check_levelup()
