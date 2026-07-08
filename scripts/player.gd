extends CharacterBody2D

const SPEED = 150.0
const JUMP_FORCE = -300.0

var knockback_vector := Vector2.ZERO

var taking_damage := false
var can_take_damage := true
var can_move := true

@onready var animation = $Anim as AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D

func _ready():
	Globals.player_life = 3

func _physics_process(delta: float) -> void:

	# gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# aplica knockback suave
	velocity += knockback_vector

	# pulo
	if (
		Input.is_key_pressed(KEY_W) or
		Input.is_key_pressed(KEY_SPACE) or
		Input.is_key_pressed(KEY_UP)
	) and is_on_floor() and can_move:

		velocity.y = JUMP_FORCE

	# movimento
	var direction = 0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction = -1

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction = 1

	# andar
	if direction != 0 and can_move:

		velocity.x = direction * SPEED

		# virar personagem
		animation.flip_h = direction < 0

	elif can_move:

		velocity.x = move_toward(velocity.x, 0, SPEED)

	# animações
	if not is_on_floor():
		animation.play("jump")

	elif direction != 0:
		animation.play("run")

	else:
		animation.play("idle")

	# última vida piscando vermelho
	if Globals.player_life == 1 and not taking_damage:

		var blink = abs(sin(Time.get_ticks_msec() * 0.005))

		animation.modulate = Color(1, blink, blink, 1)

	elif not taking_damage:

		animation.modulate = Color(1, 1, 1, 1)

	move_and_slide()


func _on_hurtbox_body_entered(body: Node2D) -> void:

	if body.is_in_group("enemies"):

		var direction = (global_position - body.global_position).normalized()

		take_damage(Vector2(direction.x * 230, -80))

	if Globals.player_life <= 0:
		queue_free()


func take_damage(knockback_force := Vector2.ZERO, duration := 0.1):

	# impede múltiplos danos
	if not can_take_damage:
		return

	can_take_damage = false
	can_move = false
	taking_damage = true

	Globals.player_life -= 1

	print("Vida:", Globals.player_life)

	# vermelho ao tomar dano
	animation.modulate = Color(1.0, 0.0, 0.0, 1.0)

	# aplica knockback
	if knockback_force != Vector2.ZERO:

		knockback_vector = knockback_force

		var knockback_tween := get_tree().create_tween()

		knockback_tween.tween_property(
			self,
			"knockback_vector",
			Vector2.ZERO,
			duration
		)

	# pequeno stun
	await get_tree().create_timer(0.08).timeout

	can_move = true

	# invencibilidade
	await get_tree().create_timer(0.4).timeout

	can_take_damage = true
	taking_damage = false

	# volta cor normal
	animation.modulate = Color(1, 1, 1, 1)


func follow_camera(camera):

	var camera_path = camera.get_path()

	remote_transform.remote_path = camera_path
