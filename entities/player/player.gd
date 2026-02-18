extends CharacterBody2D
## 플레이어 이동과 상태를 관리한다.


signal hp_changed(current_hp: float, max_hp: float)
signal player_died

@export var move_speed: float = Constants.PLAYER_BASE_SPEED
@export var max_hp: float = 120.0

var current_hp: float
var _damage_cooldown: float = 0.0
var _weapons: Array[WeaponBase] = []

@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	_equip_starting_weapon()


func add_weapon(weapon: WeaponBase) -> void:
	if _weapons.size() >= Constants.MAX_WEAPONS:
		return
	weapon.initialize(weapon.data, self)
	_weapons.append(weapon)
	add_child(weapon)


func _equip_starting_weapon() -> void:
	var scissors_data: WeaponData = preload("res://data/weapons/cursed_scissors.tres")
	var scissors_scene := preload("res://entities/weapons/cursed_scissors.gd")
	var weapon: WeaponBase = WeaponBase.new()
	weapon.set_script(scissors_scene)
	weapon.data = scissors_data
	add_weapon(weapon)


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


func _flash_hit() -> void:
	var placeholder := $Placeholder as ColorRect
	placeholder.color = Color(1, 0.3, 0.3, 1)
	get_tree().create_timer(0.1).timeout.connect(
		func() -> void: placeholder.color = Color(0.96, 0.87, 0.7, 1)
	)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		take_damage(area.data.contact_damage)
