extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

var direction: int = -1

const SPEED: float = 30.0


# ==========================================
# DANO NO PLAYER
# ==========================================

const DAMAGE_COOLDOWN: float = 0.7

const KNOCKBACK_X: float = 70.0
const KNOCKBACK_Y: float = -35.0

var damage_cooldown: float = 0.0


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

	direction = -1

	animated_sprite.flip_h = false

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


				# Player pela lateral
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
			# OUTRO INIMIGO
			# ==========================================

			if collider.is_in_group("enemies"):

				virar()

				break


		# ==========================================
		# PAREDE
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
# RAYCAST
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


	direction *= -1

	animated_sprite.flip_h = direction > 0

	_update_ray_cast()


# ==========================================
# HITBOX
# ==========================================

func _on_hitbox_body_entered(body: Node2D) -> void:

	if is_dead:
		return


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
		print("PLAYER PISOU NA MINHOCA!")
		print("MINHOCA DERROTADA!")
		print("==============================")


		matar_minhoca()


		# ==========================================
		# REBOTE
		# ==========================================

		body.velocity.y = -120.0

		return


	# ==========================================
	# COLISÃO LATERAL
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
	# VERIFICAR TAKE_DAMAGE
	# ==========================================

	if not body.has_method("take_damage"):

		print(
			"MINHOCA: Player não possui take_damage()"
		)

		return


	# ==========================================
	# DIREÇÃO
	# ==========================================

	var knockback_direction: float = 1.0


	if body.global_position.x < global_position.x:

		knockback_direction = -1.0


	# ==========================================
	# DANO
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


	print("MINHOCA DEU DANO NO PLAYER!")


# ==========================================
# RECEBER DANO
# ==========================================

func hurt() -> void:

	take_damage()


func take_damage() -> void:

	if is_dead:
		return


	# A minhoca não possui vida própria
	# além do pisão.
	return


# ==========================================
# MORTE
# ==========================================

func matar_minhoca() -> void:

	if is_dead:
		return


	is_dead = true


	# ==========================================
	# +50 SCORE
	# ==========================================

	Globals.score += 50


	print("MINHOCA DERROTADA!")
	print("+50 SCORE")
	print("SCORE ATUAL: ", Globals.score)


	# ==========================================
	# PARAR
	# ==========================================

	velocity = Vector2.ZERO

	set_physics_process(false)


	# ==========================================
	# DESATIVAR COLISÃO
	# ==========================================

	collision.set_deferred(
		"disabled",
		true
	)


	# ==========================================
	# DESATIVAR HITBOX
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
	# DESATIVAR RAYCAST
	# ==========================================

	ray_cast.enabled = false


	# ==========================================
	# ANIMAÇÃO DE MORTE
	# ==========================================

	animated_sprite.visible = true

	animated_sprite.play("hurt")


	var original_position: Vector2 = (
		animated_sprite.position
	)

	animated_sprite.rotation_degrees = 0.0


	# ==========================================
	# PULO
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


	await get_tree().create_timer(
		0.04
	).timeout


	# ==========================================
	# QUEDA
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
	# DESAPARECER
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


	queue_free()


# ==========================================
# MORTE DIRETA
# ==========================================

func die() -> void:

	matar_minhoca()
