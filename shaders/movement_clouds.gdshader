extends Sprite2D

@export var speed = 20

func _process(delta):
	position.x += speed * delta

	if position.x > 1500:
		position.x = -500