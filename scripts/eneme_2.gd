extends CharacterBody2D

var direction :=-1

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

		velocity.x = direction * SPEED * delta 

	move_and_slide()
