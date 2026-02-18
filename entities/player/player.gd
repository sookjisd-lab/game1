extends CharacterBody2D
## 플레이어 이동과 상태를 관리한다.


@export var move_speed: float = Constants.PLAYER_BASE_SPEED


func _physics_process(_delta: float) -> void:
	var input_direction := _get_input_direction()
	velocity = input_direction * move_speed
	move_and_slide()


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
