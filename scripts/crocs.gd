extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

var direction := -1

const SPEED := 30.0


# ==========================================
# SCORE
# ==========================================

const SCORE_REWARD := 100


# ==========================================
# ESTADOS
# ==========================================

var is_dead := false
var is_hurt := false

# Evita ficar virando várias vezes seguidas
var turn_cooldown := 0.0

const TURN_COOLDOWN := 0.20


# ==========================================
# NÓS
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Colisão física normal do inimigo.
@onready var collision: CollisionShape2D = $collision

# RayCast para verificar o chão.
@onready var ray_cast: RayCast2D = $RayCast2D

# Área usada para detectar o player.
@onready var hitbox_area: Area2D = $Area2D

# Colisão da hitbox.
@onready var hitbox: CollisionShape2D = $Area2D/hitbox


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	add_to_group("enemies")


	# ==========================================
	# ANIMAÇÃO INICIAL
	# ==========================================

	animated_sprite.play("walking")


	# ==========================================
	# DIREÇÃO INICIAL
	# ==========================================

	direction = -1

	animated_sprite.flip_h = false


	# ==========================================
	# HITBOX
	# ==========================================

	hitbox_area.monitoring = true
	hitbox_area.monitorable = true


	if not hitbox_area.body_entered.is_connected(
		_on_hitbox_body_entered
	):

		hitbox_area.body_entered.connect(
			_on_hitbox_body_entered
		)


	# ==========================================
	# RAYCAST
	# ==========================================

	ray_cast.enabled = true

	_update_ray_cast()


	print("==============================")
	print("CROCS INICIADO")
	print("==============================")


# ==========================================
# FÍSICA
# ==========================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	# ==========================================
	# COOLDOWN DA VIRADA
	# ==========================================

	if turn_cooldown > 0.0:

		turn_cooldown -= delta


	# ==========================================
	# GRAVIDADE
	# ==========================================

	if not is_on_floor():

		velocity += get_gravity() * delta


	# ==========================================
	# HURT
	# ==========================================

	if is_hurt:

		velocity.x = 0

		move_and_slide()

		return


	# ==========================================
	# ATUALIZA RAYCAST
	# ==========================================

	_update_ray_cast()


	# ==========================================
	# VERIFICA BORDA
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
	# VERIFICA COLISÕES LATERAIS
	# ==========================================

	for i in get_slide_collision_count():

		var slide_collision := get_slide_collision(i)

		var collider := slide_collision.get_collider()

		var normal := slide_collision.get_normal()


		# ==========================================
		# COLISÃO COM OUTRO INIMIGO
		# ==========================================

		if collider != null:

			if collider.is_in_group("enemies"):

				virar()

				# Sai imediatamente para não processar
				# a mesma colisão novamente.
				break


		# ==========================================
		# COLISÃO COM PAREDE
		# ==========================================

		if abs(normal.x) > 0.5:

			virar()

			break


	# ==========================================
	# GARANTE CHÃO
	# ==========================================

	if is_on_floor():

		velocity.y = 0


	# ==========================================
	# WALKING
	# ==========================================

	if animated_sprite.animation != "walking":

		animated_sprite.play("walking")


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


# ==========================================
# VIRAR
# ==========================================

func virar() -> void:

	if is_dead:

		return


	if is_hurt:

		return


	# ==========================================
	# EVITA VIRAR VÁRIAS VEZES
	# ==========================================

	if turn_cooldown > 0.0:

		return


	turn_cooldown = TURN_COOLDOWN


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
	# GARANTE MOVIMENTO
	# ==========================================

	velocity.x = direction * SPEED


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
	# DERROTA
	# ==========================================

	print("==============================")
	print("PLAYER PISOU NO CROCS!")
	print("CROCS DERROTADO!")
	print("==============================")


	matar_crocs()


	# ==========================================
	# REBOTE
	# ==========================================

	body.velocity.y = -220.0


# ==========================================
# RECEBER DANO
# ==========================================

func hurt() -> void:

	take_damage()


func take_damage() -> void:

	if is_dead:

		return


	if is_hurt:

		return


	is_hurt = true


	# ==========================================
	# PARA
	# ==========================================

	velocity.x = 0


	# ==========================================
	# HURT
	# ==========================================

	animated_sprite.play("hurt")


	# ==========================================
	# EFEITO VERMELHO
	# ==========================================

	animated_sprite.modulate = Color(
		1.0,
		0.55,
		0.55,
		1.0
	)


	# ==========================================
	# ESPERA
	# ==========================================

	await get_tree().create_timer(
		0.20
	).timeout


	if is_dead:

		return


	# ==========================================
	# VOLTA AO NORMAL
	# ==========================================

	animated_sprite.modulate = Color(
		1,
		1,
		1,
		1
	)


	is_hurt = false


	if not is_dead:

		animated_sprite.play("walking")


# ==========================================
# MORTE
# ==========================================

func matar_crocs() -> void:

	if is_dead:

		return


	is_dead = true


	# ==========================================
	# +100 SCORE
	# ==========================================

	Globals.score += SCORE_REWARD


	print("==============================")
	print("CROCS DERROTADO!")
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

	hitbox_area.set_deferred(
		"monitoring",
		false
	)

	hitbox.set_deferred(
		"disabled",
		true
	)


	# ==========================================
	# DESATIVA RAYCAST
	# ==========================================

	ray_cast.enabled = false


	# ==========================================
	# MANTÉM VISÍVEL
	# ==========================================

	animated_sprite.visible = true

	animated_sprite.stop()


	# ==========================================
	# GUARDA POSIÇÃO
	# ==========================================

	var original_position: Vector2 = (
		animated_sprite.position
	)


	# ==========================================
	# RESET DA ROTAÇÃO
	# ==========================================

	animated_sprite.rotation_degrees = 0.0


	# ==========================================
	# 1. MICRO PULO + VIRA
	# ==========================================

	var jump_tween := create_tween()

	jump_tween.set_parallel(true)


	# ------------------------------------------
	# SOBE APENAS 5 PIXELS
	# ------------------------------------------

	jump_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			0,
			-5
		),
		0.18
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	# ------------------------------------------
	# VIRA DE CABEÇA PARA BAIXO
	# ------------------------------------------

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
	# 2. PAUSA BEM CURTA
	# ==========================================

	await get_tree().create_timer(
		0.04
	).timeout


	# ==========================================
	# 3. CAI
	# ==========================================

	var fall_tween := create_tween()

	fall_tween.set_parallel(true)


	# ------------------------------------------
	# CAI POUCO
	# ------------------------------------------

	fall_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			0,
			14
		),
		0.20
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	# ------------------------------------------
	# MANTÉM DE CABEÇA PARA BAIXO
	# ------------------------------------------

	fall_tween.tween_property(
		animated_sprite,
		"rotation_degrees",
		180.0,
		0.20
	)


	await fall_tween.finished


	# ==========================================
	# 4. DESAPARECE
	# ==========================================

	var fade_tween := create_tween()

	fade_tween.set_parallel(true)


	# ------------------------------------------
	# DESCE MAIS UM POUQUINHO
	# ------------------------------------------

	fade_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			0,
			18
		),
		0.12
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	# ------------------------------------------
	# SOME
	# ------------------------------------------

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
# MORRER DIRETO
# ==========================================

func die() -> void:

	matar_crocs()
