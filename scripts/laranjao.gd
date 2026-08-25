extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

var direction: int = -1

const SPEED: float = 50.0


# ==========================================
# DANO NO PLAYER
# ==========================================

const DAMAGE_COOLDOWN: float = 0.7

const KNOCKBACK_X: float = 70.0
const KNOCKBACK_Y: float = -35.0

var damage_cooldown: float = 0.0


# ==========================================
# TEMPO PARA EVITAR VÁRIAS VIRADAS
# ==========================================

const TURN_COOLDOWN: float = 0.20

var turn_timer: float = 0.0


# ==========================================
# ESTADO
# ==========================================

var is_dead: bool = false


# ==========================================
# NÓS
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $collision
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var hitbox: Area2D = $Area2D
@onready var hitbox_collision: CollisionShape2D = $Area2D/hitbox


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	add_to_group("enemies")


	# ==========================================
	# DIREÇÃO INICIAL
	# ==========================================

	direction = -1

	animated_sprite.flip_h = false


	# ==========================================
	# RAYCAST
	# ==========================================

	ray_cast.enabled = true

	_update_ray_cast()


	# ==========================================
	# ANIMAÇÃO
	# ==========================================

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("walkin"):

			animated_sprite.play("walkin")


	# ==========================================
	# HITBOX
	# ==========================================

	hitbox.monitoring = true
	hitbox.monitorable = true


	if not hitbox.body_entered.is_connected(
		_on_hitbox_body_entered
	):

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
	# COOLDOWN DO DANO
	# ==========================================

	if damage_cooldown > 0.0:

		damage_cooldown -= delta


	# ==========================================
	# TIMER DA VIRADA
	# ==========================================

	if turn_timer > 0.0:

		turn_timer -= delta


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
	# DETECTA FIM DO PISO
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
	# COLISÕES
	# ==========================================

	for i in get_slide_collision_count():

		var slide_collision: KinematicCollision2D = (
			get_slide_collision(i)
		)

		var collider: Object = (
			slide_collision.get_collider()
		)

		var normal: Vector2 = (
			slide_collision.get_normal()
		)


		# ==========================================
		# COLISÃO COM PLAYER
		# ==========================================

		if collider != null:

			if collider.is_in_group("player"):

				var player_body: Node2D = (
					collider as Node2D
				)


				# ==========================================
				# PLAYER ABAIXO/LATERAL
				# ==========================================

				if (
					player_body.global_position.y
					>= global_position.y
				):

					dar_dano_no_player(
						player_body
					)


					virar()

					break


			# ==========================================
			# COLISÃO COM OUTRO INIMIGO
			# ==========================================

			if collider.is_in_group("enemies"):

				if not is_dead:

					virar()


				break


		# ==========================================
		# COLISÃO COM PAREDE
		# ==========================================

		if abs(normal.x) > 0.5:

			virar()

			break


	# ==========================================
	# ANIMAÇÃO
	# ==========================================

	if not is_dead:

		if animated_sprite.sprite_frames != null:

			if animated_sprite.sprite_frames.has_animation("walkin"):

				if animated_sprite.animation != "walkin":

					animated_sprite.play("walkin")


# ==========================================
# ATUALIZA RAYCAST
# ==========================================

func _update_ray_cast() -> void:

	if ray_cast == null:
		return


	ray_cast.target_position = Vector2(
		float(direction) * 18.0,
		24.0
	)


	ray_cast.force_raycast_update()


# ==========================================
# VIRAR
# ==========================================

func virar() -> void:

	if is_dead:
		return


	# ==========================================
	# EVITA VIRADAS INSTANTÂNEAS
	# ==========================================

	if turn_timer > 0.0:

		return


	turn_timer = TURN_COOLDOWN


	# ==========================================
	# MUDA DIREÇÃO
	# ==========================================

	direction *= -1


	# ==========================================
	# VIRA SPRITE
	# ==========================================

	animated_sprite.flip_h = direction > 0


	# ==========================================
	# ATUALIZA RAYCAST
	# ==========================================

	_update_ray_cast()


	# ==========================================
	# IMPULSO NA NOVA DIREÇÃO
	# ==========================================

	velocity.x = direction * SPEED


# ==========================================
# HITBOX
# ==========================================

func _on_hitbox_body_entered(body: Node2D) -> void:

	if is_dead:
		return


	# ==========================================
	# SÓ PLAYER
	# ==========================================

	if not body.is_in_group("player"):

		return


	# ==========================================
	# PLAYER ESTÁ ACIMA
	# ==========================================

	if body.global_position.y < global_position.y:

		# ==========================================
		# PISÃO
		# ==========================================

		print("==============================")
		print("PLAYER PISOU NO LARANJA!")
		print("LARANJA DERROTADO!")
		print("==============================")


		matar_laranja()


		# ==========================================
		# REBATE PLAYER
		# ==========================================

		body.velocity.y = -200.0

		return


	# ==========================================
	# PLAYER ENCOSTOU DE LADO
	# ==========================================

	dar_dano_no_player(body)


# ==========================================
# DAR DANO NO PLAYER
# ==========================================

func dar_dano_no_player(body: Node2D) -> void:

	if is_dead:
		return


	if damage_cooldown > 0.0:

		return


	if body == null:

		return


	if not is_instance_valid(body):

		return


	# ==========================================
	# PLAYER ACIMA NÃO TOMA DANO
	# ==========================================

	if body.global_position.y < global_position.y:

		return


	# ==========================================
	# PLAYER PRECISA TER TAKE_DAMAGE
	# ==========================================

	if not body.has_method("take_damage"):

		print(
			"LARANJA: Player não possui take_damage()"
		)

		return


	# ==========================================
	# DIREÇÃO DO KNOCKBACK
	# ==========================================

	var knockback_direction: float = 1.0


	if body.global_position.x < global_position.x:

		knockback_direction = -1.0


	# ==========================================
	# CAUSA DANO
	# ==========================================

	body.take_damage(
		Vector2(
			knockback_direction * KNOCKBACK_X,
			KNOCKBACK_Y
		)
	)


	# ==========================================
	# COOLDOWN
	# ==========================================

	damage_cooldown = DAMAGE_COOLDOWN


	print("LARANJA DEU DANO NO PLAYER!")


# ==========================================
# RECEBER DANO
# ==========================================

func hurt() -> void:

	take_damage()


func take_damage() -> void:

	if is_dead:

		return


	# ==========================================
	# O LARANJA NÃO USA DANO PRÓPRIO
	# ==========================================

	return


# ==========================================
# MORTE
# ==========================================

func matar_laranja() -> void:

	if is_dead:
		return


	is_dead = true


	# ==========================================
	# +100 SCORE
	# ==========================================

	Globals.score += 100


	print("==============================")
	print("LARANJA DERROTADO!")
	print("+100 SCORE")
	print(
		"SCORE ATUAL: ",
		Globals.score
	)
	print("==============================")


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

	hitbox_collision.set_deferred(
		"disabled",
		true
	)


	# ==========================================
	# DESATIVA RAYCAST
	# ==========================================

	ray_cast.enabled = false


	# ==========================================
	# ANIMAÇÃO DE MORTE
	# ==========================================

	animated_sprite.play("hurt")


	# ==========================================
	# POSIÇÃO ORIGINAL
	# ==========================================

	var original_position: Vector2 = (
		animated_sprite.position
	)


	# ==========================================
	# ROTAÇÃO ZERO
	# ==========================================

	animated_sprite.rotation_degrees = 0.0


	# ==========================================
	# SOBE UM POUCO
	# ==========================================

	var jump_tween: Tween = create_tween()

	jump_tween.set_parallel(true)


	jump_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			0.0,
			-5.0
		),
		0.18
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	# ==========================================
	# VIRA DE CABEÇA PARA BAIXO
	# ==========================================

	jump_tween.tween_property(
		animated_sprite,
		"rotation_degrees",
		180.0,
		0.18
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	await jump_tween.finished


	# ==========================================
	# PAUSA
	# ==========================================

	await get_tree().create_timer(
		0.04
	).timeout


	# ==========================================
	# CAI
	# ==========================================

	var fall_tween: Tween = create_tween()

	fall_tween.set_parallel(true)


	fall_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			0.0,
			14.0
		),
		0.20
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	fall_tween.tween_property(
		animated_sprite,
		"rotation_degrees",
		180.0,
		0.20
	)


	await fall_tween.finished


	# ==========================================
	# DESAPARECE
	# ==========================================

	var fade_tween: Tween = create_tween()

	fade_tween.set_parallel(true)


	fade_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			0.0,
			18.0
		),
		0.12
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	fade_tween.tween_property(
		animated_sprite,
		"modulate:a",
		0.0,
		0.12
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	await fade_tween.finished


	# ==========================================
	# REMOVE
	# ==========================================

	queue_free()


# ==========================================
# MORTE DIRETA
# ==========================================

func die() -> void:

	matar_laranja()
