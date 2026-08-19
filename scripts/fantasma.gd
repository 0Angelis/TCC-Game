extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

var direction := -1

const SPEED := 30.0


# ==========================================
# ESTADOS
# ==========================================

var is_dead := false


# ==========================================
# NÓS
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	add_to_group("enemies")

	animated_sprite.play("idle")

	direction = -1
	animated_sprite.flip_h = false

	hitbox.monitoring = true

	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):

		hitbox.body_entered.connect(
			_on_hitbox_body_entered
		)


# ==========================================
# FÍSICA
# ==========================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	# ==========================================
	# GRAVIDADE
	# ==========================================

	if not is_on_floor():

		velocity += get_gravity() * delta


	# ==========================================
	# MOVIMENTO
	# ==========================================

	velocity.x = direction * SPEED

	move_and_slide()


	# ==========================================
	# COLISÕES
	# ==========================================

	for i in get_slide_collision_count():

		var collision := get_slide_collision(i)

		var normal := collision.get_normal()

		if abs(normal.x) > 0.5:

			virar()

			break


	# ==========================================
	# IDLE
	# ==========================================

	if animated_sprite.animation != "idle":

		animated_sprite.play("idle")


# ==========================================
# VIRAR
# ==========================================

func virar() -> void:

	if is_dead:
		return

	direction *= -1

	animated_sprite.flip_h = direction > 0


# ==========================================
# HITBOX DA CABEÇA
# ==========================================

func _on_hitbox_body_entered(body: Node2D) -> void:

	if is_dead:
		return


	if not body.is_in_group("player"):
		return


	# ==========================================
	# PLAYER PRECISA ESTAR ACIMA
	# ==========================================

	if body.global_position.y >= global_position.y:

		return


	# ==========================================
	# MORTE
	# ==========================================

	print("==============================")
	print("PLAYER PISOU NA CABEÇA!")
	print("FANTASMA DERROTADO!")
	print("==============================")


	matar_fantasma()


	# ==========================================
	# REBOTE
	# ==========================================

	body.velocity.y = -220.0


# ==========================================
# MORTE
# ==========================================

func matar_fantasma() -> void:

	if is_dead:
		return


	is_dead = true


	# ==========================================
	# PARA TUDO
	# ==========================================

	velocity = Vector2.ZERO

	set_physics_process(false)


	# ==========================================
	# DESATIVA COLISÕES
	# ==========================================

	$collision.set_deferred(
		"disabled",
		true
	)

	hitbox.set_deferred(
		"monitoring",
		false
	)


	# ==========================================
	# MANTÉM SPRITE VISÍVEL
	# ==========================================

	animated_sprite.visible = true


	# ==========================================
	# ANIMAÇÃO DE MORTE
	# ==========================================

	var tween := create_tween()

	tween.set_parallel(true)

	# Gira suavemente 360 graus
	tween.tween_property(
		animated_sprite,
		"rotation_degrees",
		360.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# Cai um pouco
	tween.tween_property(
		animated_sprite,
		"position:y",
		animated_sprite.position.y + 28.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Vai ficando transparente
	tween.tween_property(
		animated_sprite,
		"modulate:a",
		0.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


	# ==========================================
	# ESPERA A ANIMAÇÃO
	# ==========================================

	await tween.finished


	# ==========================================
	# REMOVE
	# ==========================================

	queue_free()
