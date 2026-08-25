extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

var direction: int = -1

const SPEED: float = 30.0


# ==========================================
# ATAQUE
# ==========================================

var is_attacking: bool = false

const ATTACK_TIME: float = 0.45


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
	# WALK
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
	# ATAQUE
	# ==========================================

	if is_attacking:

		velocity.x = 0.0

		move_and_slide()

		return


	# ==========================================
	# RAYCAST
	# ==========================================

	_update_ray_cast()


	# ==========================================
	# BORDA
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
		# PLAYER
		# ==========================================

		if collider != null:

			if collider.is_in_group("player"):

				var player_body: Node2D = (
					collider as Node2D
				)


				# ------------------------------------------
				# PLAYER PELA LATERAL
				# ------------------------------------------

				if (
					player_body.global_position.y
					>= global_position.y
				):

					dar_dano_no_player(
						player_body
					)

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
	# WALK
	# ==========================================

	if not is_attacking and not is_dead:

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

	if is_attacking:
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


	print("PLAYER DETECTADO PELA HITBOX!")


	# ==========================================
	# PISOU EM CIMA
	# ==========================================

	if body.global_position.y < global_position.y:

		print("PLAYER PISOU NO INIMIGO!")

		matar_minhoca()

		body.velocity.y = -120.0

		return


	# ==========================================
	# ENCOSTOU DE LADO
	# ==========================================

	print("PLAYER ENCOSTOU DE LADO!")

	ativar_attack()

	dar_dano_no_player(body)


# ==========================================
# ATTACK
# ==========================================

func ativar_attack() -> void:

	if is_dead:
		return

	if is_attacking:
		return


	print("ATIVANDO ANIMAÇÃO ATTACK!")


	is_attacking = true

	velocity.x = 0.0


	# ==========================================
	# VIRAR PARA O PLAYER
	# ==========================================

	var players: Array[Node] = (
		get_tree().get_nodes_in_group("player")
	)


	if players.size() > 0:

		var player: Node2D = players[0] as Node2D


		if player.global_position.x > global_position.x:

			direction = 1

		else:

			direction = -1


		animated_sprite.flip_h = direction > 0

		_update_ray_cast()


	# ==========================================
	# VERIFICAR SPRITEFRAMES
	# ==========================================

	if animated_sprite.sprite_frames == null:

		print(
			"ERRO: SpriteFrames não existe!"
		)

		is_attacking = false

		return


	# ==========================================
	# VERIFICAR ATTACK
	# ==========================================

	if not animated_sprite.sprite_frames.has_animation(
		"attack"
	):

		print(
			"ERRO: animação 'attack' NÃO EXISTE!"
		)

		print(
			"Animação atual: ",
			animated_sprite.animation
		)

		is_attacking = false

		return


	# ==========================================
	# TOCAR ATTACK
	# ==========================================

	animated_sprite.play("attack")


	print(
		"ANIMAÇÃO ATUAL: ",
		animated_sprite.animation
	)


	# ==========================================
	# ESPERAR
	# ==========================================

	await get_tree().create_timer(
		ATTACK_TIME
	).timeout


	if is_dead:
		return


	is_attacking = false


	# ==========================================
	# VOLTAR WALK
	# ==========================================

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation(
			"walkin"
		):

			animated_sprite.play("walkin")


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
			"INIMIGO: Player não possui take_damage()"
		)

		return


	# ==========================================
	# DIREÇÃO DO KNOCKBACK
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


	print("INIMIGO DEU DANO NO PLAYER!")


# ==========================================
# MORTE
# ==========================================

func matar_minhoca() -> void:

	if is_dead:
		return


	is_dead = true

	is_attacking = false


	# ==========================================
	# SCORE
	# ==========================================

	Globals.score += 50


	print("INIMIGO DERROTADO!")
	print("+50 SCORE")
	print("SCORE ATUAL: ", Globals.score)


	# ==========================================
	# PARAR
	# ==========================================

	velocity = Vector2.ZERO

	set_physics_process(false)


	# ==========================================
	# COLLISION
	# ==========================================

	collision.set_deferred(
		"disabled",
		true
	)


	# ==========================================
	# HITBOX
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
	# RAYCAST
	# ==========================================

	ray_cast.enabled = false


	# ==========================================
	# HURT
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
