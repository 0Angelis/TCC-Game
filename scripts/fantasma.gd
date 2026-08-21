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
@onready var collision: CollisionShape2D = $collision
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var hitbox: Area2D = $Area2D


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	add_to_group("enemies")

	direction = -1

	animated_sprite.flip_h = false

	ray_cast.enabled = true

	_update_ray_cast()

	hitbox.monitoring = true
	hitbox.monitorable = true

	if not hitbox.body_entered.is_connected(
		_on_hitbox_body_entered
	):

		hitbox.body_entered.connect(
			_on_hitbox_body_entered
		)

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("idle"):

			animated_sprite.play("idle")


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
	# ATUALIZA RAYCAST
	# ==========================================

	_update_ray_cast()


	# ==========================================
	# FIM DA PLATAFORMA
	# ==========================================

	if is_on_floor():

		if not ray_cast.is_colliding():

			virar()


	# ==========================================
	# MOVIMENTO
	# ==========================================

	velocity.x = direction * SPEED

	move_and_slide()


	# ==========================================
	# COLISÃO COM PAREDE
	# ==========================================

	for i in get_slide_collision_count():

		var slide_collision := get_slide_collision(i)

		var normal := slide_collision.get_normal()

		if abs(normal.x) > 0.5:

			virar()

			break


	# ==========================================
	# ANIMAÇÃO
	# ==========================================

	if not is_dead:

		if animated_sprite.sprite_frames != null:

			if animated_sprite.sprite_frames.has_animation("idle"):

				if animated_sprite.animation != "idle":

					animated_sprite.play("idle")


# ==========================================
# ATUALIZA RAYCAST
# ==========================================

func _update_ray_cast() -> void:

	if ray_cast == null:
		return


	ray_cast.target_position = Vector2(
		direction * 18.0,
		24.0
	)

	ray_cast.force_raycast_update()


# ==========================================
# VIRAR
# ==========================================

func virar() -> void:

	if is_dead:
		return


	direction *= -1

	animated_sprite.flip_h = direction > 0

	_update_ray_cast()


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
	print("PLAYER PISOU NO FANTASMA!")
	print("FANTASMA DERROTADO!")
	print("==============================")


	matar_fantasma()


	# ==========================================
	# REBOTE DO PLAYER
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
	# SCORE
	# ==========================================

	Globals.score += 50


	# ==========================================
	# PARA TUDO
	# ==========================================

	velocity = Vector2.ZERO

	set_physics_process(false)


	# ==========================================
	# DESATIVA COLISÃO
	# ==========================================

	collision.set_deferred(
		"disabled",
		true
	)


	# ==========================================
	# DESATIVA HITBOX
	# ==========================================

	hitbox.set_deferred(
		"monitoring",
		false
	)


	# ==========================================
	# DESATIVA RAYCAST
	# ==========================================

	ray_cast.enabled = false


	# ==========================================
	# MANTÉM SPRITE VISÍVEL
	# ==========================================

	animated_sprite.visible = true


	# ==========================================
	# ANIMAÇÃO DE MORTE
	# ==========================================

	var tween := create_tween()

	tween.set_parallel(true)


	# Gira

	tween.tween_property(
		animated_sprite,
		"rotation_degrees",
		360.0,
		0.9
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN_OUT
	)


	# Cai um pouco

	tween.tween_property(
		animated_sprite,
		"position:y",
		animated_sprite.position.y + 28.0,
		0.9
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	# Fica transparente

	tween.tween_property(
		animated_sprite,
		"modulate:a",
		0.0,
		0.9
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	# ==========================================
	# ESPERA
	# ==========================================

	await tween.finished


	# ==========================================
	# REMOVE
	# ==========================================

	queue_free()


# ==========================================
# MORTE DIRETA
# ==========================================

func die() -> void:

	matar_fantasma()
