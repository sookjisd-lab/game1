extends CharacterBody2D
## 플레이어 이동과 상태를 관리한다.


@export var move_speed: float = Constants.PLAYER_BASE_SPEED


func _physics_process(_delta: float) -> void:
	var input_direction := _get_input_direction()
	velocity = input_direction * move_speed
	move_and_slide()


func _get_input_direction() -> Vector2:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	return direction.normalized()
