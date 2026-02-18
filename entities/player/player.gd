extends CharacterBody2D
## 플레이어 이동과 상태를 관리한다.


signal hp_changed(current_hp: float, max_hp: float)
signal player_died
signal leveled_up(new_level: int)
signal xp_changed(current_xp: int, xp_needed: int)

@export var move_speed: float = Constants.PLAYER_BASE_SPEED
@export var max_hp: float = 120.0

var current_hp: float
var current_level: int = 1
var current_xp: int = 0
var damage_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var magnet_radius: float = Constants.BASE_MAGNET_RADIUS
var _damage_cooldown: float = 0.0
var _weapons: Array[WeaponBase] = []

@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	_equip_starting_weapon()
	DropManager.xp_collected.connect(_on_xp_collected)
	GameManager.state_changed.connect(_on_game_state_changed)


func add_weapon(weapon: WeaponBase) -> void:
	if _weapons.size() >= Constants.MAX_WEAPONS:
		return
	weapon.initialize(weapon.data, self)
	_weapons.append(weapon)
	add_child(weapon)


func _equip_starting_weapon() -> void:
	var scissors_data: WeaponData = preload("res://data/weapons/cursed_scissors.tres")
	var weapon := Node2D.new()
	weapon.set_script(preload("res://entities/weapons/cursed_scissors.gd"))
	weapon.name = "CursedScissors"
	add_child(weapon)
	weapon.initialize(scissors_data, self)
	_weapons.append(weapon)


func _physics_process(delta: float) -> void:
	var input_direction := _get_input_direction()
	velocity = input_direction * move_speed
	move_and_slide()

	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta


func take_damage(amount: float) -> void:
	if _damage_cooldown > 0.0:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_damage_cooldown = 0.5
	hp_changed.emit(current_hp, max_hp)
	_flash_hit()
	_shake_camera()
	if current_hp <= 0.0:
		player_died.emit()


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
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var tween := create_tween()
	tween.tween_property(camera, "offset", Vector2(randf_range(-2, 2), randf_range(-2, 2)), 0.05)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)


func _flash_hit() -> void:
	var placeholder := $Placeholder as ColorRect
	placeholder.color = Color(1, 0.3, 0.3, 1)
	get_tree().create_timer(0.1).timeout.connect(
		func() -> void: placeholder.color = Color(0.96, 0.87, 0.7, 1)
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


func _on_xp_collected(amount: int) -> void:
	add_xp(amount)


func _on_game_state_changed(
		old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if old_state == Enums.GameState.LEVEL_UP and new_state == Enums.GameState.PLAYING:
		_check_levelup()
