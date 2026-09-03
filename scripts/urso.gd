extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

const SPEED: float = 30.0
const CHASE_SPEED: float = 55.0
const ATTACK_SPEED: float = 48.0

var direction: int = -1


# ==========================================
# DETECÇÃO
# ==========================================

const DETECTION_DISTANCE: float = 90.0
const SLEEP_DISTANCE: float = 160.0

const ATTACK_TRIGGER_DISTANCE: float = 38.0
const ATTACK_STOP_DISTANCE: float = 14.0


# ==========================================
# DANO DO CORPO
# ==========================================

const ATTACK_DAMAGE_COOLDOWN: float = 0.7

const ATTACK_KNOCKBACK_X: float = 100.0
const ATTACK_KNOCKBACK_Y: float = -120.0

var attack_damage_cooldown: float = 0.0


# ==========================================
# PISÃO
# ==========================================

const STOMP_VERTICAL_DISTANCE: float = 24.0
const STOMP_HORIZONTAL_DISTANCE: float = 28.0

# Força do pulo depois de pisar no urso
const STOMP_BOUNCE_FORCE: float = -220.0

# Pequeno empurrão lateral depois do pisão
const STOMP_BOUNCE_X: float = 35.0

# Impede vários pisões enquanto o player
# continua sobre a cabeça.
var player_on_head: bool = false


# ==========================================
# PLAYER
# ==========================================

var player: Node2D = null


# ==========================================
# ESTADOS
# ==========================================

var is_dead: bool = false
var is_awake: bool = false
var is_attacking: bool = false
var is_hurt: bool = false
var returning_to_sleep: bool = false


# ==========================================
# VIDA
# ==========================================

var stomp_count: int = 0

const MAX_STOMPS: int = 3

var stomp_cooldown: float = 0.0


# ==========================================
# ATAQUE
# ==========================================

var can_attack: bool = true

const ATTACK_COOLDOWN: float = 0.7

var attack_cooldown_timer: float = 0.0


# ==========================================
# ÚLTIMA VIDA
# ==========================================

var last_life: bool = false
var blink_time: float = 0.0

const LAST_LIFE_SPEED_MULTIPLIER: float = 1.25


# ==========================================
# NÓS
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 🔵 CORPO
@onready var collision: CollisionShape2D = $collision

@onready var ray_cast: RayCast2D = $RayCast2D

# 🔴 CABEÇA
@onready var hitbox: Area2D = $Area2D

@onready var hitbox_collision: CollisionShape2D = $Area2D/hitbox


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	add_to_group("enemies")

	is_dead = false
	is_awake = false
	is_attacking = false
	is_hurt = false
	returning_to_sleep = false

	stomp_count = 0
	stomp_cooldown = 0.0

	can_attack = true
	attack_cooldown_timer = 0.0

	attack_damage_cooldown = 0.0

	last_life = false
	blink_time = 0.0

	player_on_head = false

	direction = -1

	animated_sprite.flip_h = false
	animated_sprite.speed_scale = 1.0


	# ==========================================
	# RAYCAST
	# ==========================================

	ray_cast.enabled = true

	_update_ray_cast()


	# ==========================================
	# DORMINDO
	# ==========================================

	deixar_dormindo()


	# ==========================================
	# HITBOX DA CABEÇA
	# ==========================================

	hitbox.monitoring = true
	hitbox.monitorable = true


	if not hitbox.body_entered.is_connected(
		_on_hitbox_body_entered
	):

		hitbox.body_entered.connect(
			_on_hitbox_body_entered
	)


	if not hitbox.body_exited.is_connected(
		_on_hitbox_body_exited
	):

		hitbox.body_exited.connect(
			_on_hitbox_body_exited
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
	# COOLDOWNS
	# ==========================================

	if stomp_cooldown > 0.0:

		stomp_cooldown -= delta


	if attack_cooldown_timer > 0.0:

		attack_cooldown_timer -= delta

	else:

		can_attack = true


	if attack_damage_cooldown > 0.0:

		attack_damage_cooldown -= delta


	# ==========================================
	# ÚLTIMA VIDA
	# ==========================================

	if last_life and not is_hurt:

		blink_time += delta

		var blink_value: float = abs(
			sin(
				blink_time * 10.0
			)
		)


		if blink_value < 0.5:

			animated_sprite.modulate = Color(
				1.0,
				0.35,
				0.35,
				1.0
			)

		else:

			animated_sprite.modulate = Color(
				1.0,
				1.0,
				1.0,
				1.0
			)


	# ==========================================
	# PLAYER
	# ==========================================

	if (
		player == null
		or not is_instance_valid(player)
	):

		var players: Array[Node] = (
			get_tree().get_nodes_in_group(
				"player"
			)
		)


		if players.size() > 0:

			player = players[0] as Node2D


	# ==========================================
	# DORMINDO
	# ==========================================

	if not is_awake:

		velocity.x = 0.0

		move_and_slide()

		deixar_dormindo()


		if player != null:

			var distance: float = (
				global_position.distance_to(
					player.global_position
				)
			)


			if distance <= DETECTION_DISTANCE:

				acordar()


		return


	# ==========================================
	# MACHUCADO
	# ==========================================

	if is_hurt:

		velocity.x = 0.0

		move_and_slide()

		return


	# ==========================================
	# VOLTANDO A DORMIR
	# ==========================================

	if returning_to_sleep:

		velocity.x = 0.0

		move_and_slide()

		return


	# ==========================================
	# PLAYER FUGIU
	# ==========================================

	if player != null:

		var distance_from_player: float = (
			global_position.distance_to(
				player.global_position
			)
		)


		if distance_from_player >= SLEEP_DISTANCE:

			voltar_a_dormir()

			return


	# ==========================================
	# PERSEGUIR
	# ==========================================

	if player != null:

		perseguir_player()

	else:

		movimento_normal()


	# ==========================================
	# MOVIMENTO
	# ==========================================

	move_and_slide()


	# ==========================================
	# CORPO AZUL
	# ==========================================

	verificar_colisao_corpo()


	# ==========================================
	# VERIFICAR SE PLAYER AINDA ESTÁ NA CABEÇA
	# ==========================================

	verificar_player_na_cabeca()


	# ==========================================
	# PAREDE
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


		if collider != null:

			if collider.is_in_group("enemies"):

				if not is_attacking:

					virar()

				break


		if abs(normal.x) > 0.5:

			if not is_attacking:

				virar()

			break


	# ==========================================
	# WALKING
	# ==========================================

	if (
		not is_attacking
		and not is_hurt
		and not is_dead
	):

		if animated_sprite.sprite_frames != null:

			if animated_sprite.sprite_frames.has_animation(
				"walking"
			):

				if animated_sprite.animation != "walking":

					animated_sprite.play(
						"walking"
					)


# ==========================================
# CORPO AZUL
# ==========================================

func verificar_colisao_corpo() -> void:

	if is_dead:
		return


	if is_hurt:
		return


	if attack_damage_cooldown > 0.0:
		return


	var collision_count: int = (
		get_slide_collision_count()
	)


	for i in collision_count:

		var slide_collision: KinematicCollision2D = (
			get_slide_collision(i)
		)


		var collider: Object = (
			slide_collision.get_collider()
		)


		if collider == null:
			continue


		if not collider is Node2D:
			continue


		var other_body: Node2D = (
			collider as Node2D
		)


		if not other_body.is_in_group("player"):
			continue


		var normal: Vector2 = (
			slide_collision.get_normal()
		)


		# ==========================================
		# PLAYER POR CIMA
		# ==========================================
		#
		# Se o jogador estiver em cima do urso,
		# não recebe dano pelo corpo.
		#
		# O dano do urso nesse caso é o pisão.
		# ==========================================

		if normal.y < -0.5:

			return


		# ==========================================
		# PLAYER PELA LATERAL
		# ==========================================

		if abs(normal.x) > 0.5:

			if other_body is CharacterBody2D:

				dar_dano_no_player(
					other_body as CharacterBody2D
				)

			return


# ==========================================
# DANO NO PLAYER
# ==========================================

func dar_dano_no_player(
	player_body: CharacterBody2D
) -> void:

	if is_dead:
		return


	if player_body == null:
		return


	if not is_instance_valid(player_body):
		return


	if attack_damage_cooldown > 0.0:
		return


	if not player_body.has_method(
		"receber_dano_inimigo"
	):

		return


	var knockback_direction: float = 1.0


	if player_body.global_position.x < global_position.x:

		knockback_direction = -1.0


	player_body.receber_dano_inimigo(
		Vector2(
			knockback_direction
			* ATTACK_KNOCKBACK_X,
			ATTACK_KNOCKBACK_Y
		)
	)


	attack_damage_cooldown = (
		ATTACK_DAMAGE_COOLDOWN
	)


# ==========================================
# DORMIR
# ==========================================

func deixar_dormindo() -> void:

	if is_dead:
		return


	if animated_sprite.sprite_frames == null:
		return


	if not animated_sprite.sprite_frames.has_animation(
		"sleep"
	):

		return


	animated_sprite.animation = "sleep"
	animated_sprite.frame = 0
	animated_sprite.pause()


# ==========================================
# ACORDAR
# ==========================================

func acordar() -> void:

	if is_dead:
		return


	if is_awake:
		return


	if returning_to_sleep:
		return


	is_awake = true

	velocity.x = 0.0


	print("URSO ACORDOU!")


	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation(
			"sleep"
		):

			animated_sprite.play(
				"sleep"
			)

			await animated_sprite.animation_finished


	if is_dead:
		return


	if returning_to_sleep:
		return


	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation(
			"walking"
		):

			animated_sprite.play(
				"walking"
			)


# ==========================================
# VOLTAR A DORMIR
# ==========================================

func voltar_a_dormir() -> void:

	if is_dead:
		return


	if not is_awake:
		return


	if returning_to_sleep:
		return


	returning_to_sleep = true

	is_awake = false
	is_attacking = false
	is_hurt = false

	velocity = Vector2.ZERO

	deixar_dormindo()


	await get_tree().create_timer(
		0.1
	).timeout


	if is_dead:
		return


	returning_to_sleep = false


# ==========================================
# PERSEGUIR
# ==========================================

func perseguir_player() -> void:

	if player == null:
		return


	if is_hurt:
		return


	var distancia_x: float = (
		player.global_position.x
		- global_position.x
	)


	var distancia_y: float = abs(
		player.global_position.y
		- global_position.y
	)


	# ==========================================
	# VIRAR
	# ==========================================

	if distancia_x > 2.0:

		direction = 1

	elif distancia_x < -2.0:

		direction = -1


	animated_sprite.flip_h = direction > 0

	_update_ray_cast()


	# ==========================================
	# ATTACK
	# ==========================================

	if (
		abs(distancia_x)
		<= ATTACK_TRIGGER_DISTANCE
		and distancia_y <= 32.0
	):

		entrar_attack()

		return


	# ==========================================
	# WALK
	# ==========================================

	is_attacking = false

	var speed: float = CHASE_SPEED


	if last_life:

		speed *= LAST_LIFE_SPEED_MULTIPLIER


	velocity.x = direction * speed


	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation(
			"walking"
		):

			if animated_sprite.animation != "walking":

				animated_sprite.play(
					"walking"
				)


# ==========================================
# ATTACK
# ==========================================

func entrar_attack() -> void:

	if is_dead:
		return


	if is_hurt:
		return


	if player == null:
		return


	var distancia_x: float = (
		player.global_position.x
		- global_position.x
	)


	var distancia_y: float = abs(
		player.global_position.y
		- global_position.y
	)


	if (
		abs(distancia_x)
		> ATTACK_TRIGGER_DISTANCE
		or distancia_y > 32.0
	):

		is_attacking = false

		return


	var previous_direction: int = direction


	if player.global_position.x > global_position.x:

		direction = 1

	else:

		direction = -1


	animated_sprite.flip_h = direction > 0

	_update_ray_cast()


	is_attacking = true


	var distancia_para_player: float = abs(
		player.global_position.x
		- global_position.x
	)


	var speed: float = ATTACK_SPEED


	if last_life:

		speed *= LAST_LIFE_SPEED_MULTIPLIER


	if distancia_para_player > ATTACK_STOP_DISTANCE:

		velocity.x = direction * speed

	else:

		velocity.x = 0.0


	# ==========================================
	# ATTACK
	# ==========================================

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation(
			"attack"
		):

			if (
				animated_sprite.animation != "attack"
				or previous_direction != direction
			):

				animated_sprite.play(
					"attack"
				)

				animated_sprite.frame = 0


	if can_attack:

		can_attack = false

		attack_cooldown_timer = ATTACK_COOLDOWN


# ==========================================
# MOVIMENTO NORMAL
# ==========================================

func movimento_normal() -> void:

	if is_attacking:
		return


	if is_hurt:
		return


	_update_ray_cast()


	if is_on_floor():

		if not ray_cast.is_colliding():

			virar()


	velocity.x = direction * SPEED


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


	if is_hurt:
		return


	if returning_to_sleep:
		return


	direction *= -1

	animated_sprite.flip_h = direction > 0

	_update_ray_cast()


# ==========================================
# HITBOX VERMELHA
# ==========================================

func _on_hitbox_body_entered(
	body: Node2D
) -> void:

	if is_dead:
		return


	if is_hurt:
		return


	if not body.is_in_group("player"):
		return


	if not body is CharacterBody2D:
		return


	var player_body: CharacterBody2D = (
		body as CharacterBody2D
	)


	player = player_body


	# ==========================================
	# PLAYER ENTROU NA CABEÇA
	# ==========================================

	var vertical_difference: float = (
		global_position.y
		- player_body.global_position.y
	)


	var horizontal_difference: float = abs(
		global_position.x
		- player_body.global_position.x
	)


	var player_above: bool = (
		vertical_difference > 0.0
		and vertical_difference
		<= STOMP_VERTICAL_DISTANCE
		and horizontal_difference
		<= STOMP_HORIZONTAL_DISTANCE
	)


	if not player_above:
		return


	# ==========================================
	# JÁ FOI PISADO?
	# ==========================================

	if player_on_head:
		return


	# ==========================================
	# MARCA QUE ESTÁ NA CABEÇA
	# ==========================================

	player_on_head = true


	# ==========================================
	# PISÃO
	# ==========================================

	print("==============================")
	print("PLAYER PISOU NA CABEÇA!")
	print("URSO TOMOU DANO!")
	print("==============================")


	pisar_no_urso()


# ==========================================
# PLAYER SAIU DA CABEÇA
# ==========================================

func _on_hitbox_body_exited(
	body: Node2D
) -> void:

	if not body.is_in_group("player"):
		return


	player_on_head = false


# ==========================================
# VERIFICAR PLAYER NA CABEÇA
# ==========================================

func verificar_player_na_cabeca() -> void:

	if is_dead:
		return


	if player == null:
		return


	if not is_instance_valid(player):
		return


	var vertical_difference: float = (
		global_position.y
		- player.global_position.y
	)


	var horizontal_difference: float = abs(
		global_position.x
		- player.global_position.x
	)


	var player_above: bool = (
		vertical_difference > 0.0
		and vertical_difference
		<= STOMP_VERTICAL_DISTANCE
		and horizontal_difference
		<= STOMP_HORIZONTAL_DISTANCE
	)


	if not player_above:

		player_on_head = false

		return


	if player_on_head:

		# ==========================================
		# GARANTE QUE O PLAYER NÃO FIQUE
		# PARADO EM CIMA DO URSO
		# ==========================================

		if player is CharacterBody2D:

			var player_body: CharacterBody2D = (
				player as CharacterBody2D
			)

			if player_body.velocity.y > -40.0:

				player_body.velocity.y = STOMP_BOUNCE_FORCE

		return


	# ==========================================
	# PLAYER ESTÁ PARADO NA CABEÇA
	# ==========================================

	player_on_head = true

	print("==============================")
	print("PLAYER ESTÁ NA CABEÇA!")
	print("PISÃO CONFIRMADO!")
	print("==============================")


	pisar_no_urso()


# ==========================================
# PISAR NO URSO
# ==========================================

func pisar_no_urso() -> void:

	if is_dead:
		return


	if stomp_cooldown > 0.0:
		return


	stomp_cooldown = 0.45


	stomp_count += 1


	is_attacking = false

	can_attack = false

	attack_cooldown_timer = 0.9


	print(
		"URSO FOI PISADO: ",
		stomp_count,
		"/",
		MAX_STOMPS
	)


	# ==========================================
	# REBATE PLAYER
	# ==========================================

	if player != null:

		if player is CharacterBody2D:

			var player_body: CharacterBody2D = (
				player as CharacterBody2D
			)


			# ==========================================
			# FORÇA O PLAYER PARA CIMA
			# ==========================================

			player_body.velocity.y = STOMP_BOUNCE_FORCE


			# Pequeno afastamento lateral

			var bounce_direction: float = 1.0

			if player_body.global_position.x < global_position.x:

				bounce_direction = -1.0


			player_body.velocity.x += (
				bounce_direction * STOMP_BOUNCE_X
			)


	# ==========================================
	# TERCEIRA VIDA
	# ==========================================

	if stomp_count >= MAX_STOMPS:

		matar_urso()

		return


	# ==========================================
	# REAÇÃO
	# ==========================================

	reagir_ao_dano()


# ==========================================
# REAÇÃO AO DANO
# ==========================================

func reagir_ao_dano() -> void:

	if is_dead:
		return


	is_hurt = true
	is_attacking = false

	velocity.x = 0.0


	animated_sprite.stop()


	var original_position: Vector2 = (
		animated_sprite.position
	)


	var original_scale: Vector2 = (
		animated_sprite.scale
	)


	var original_rotation: float = (
		animated_sprite.rotation
	)


	# ==========================================
	# IMPACTO
	# ==========================================

	var damage_tween: Tween = create_tween()

	damage_tween.set_parallel(true)


	damage_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			-direction * 5.0,
			-3.0
		),
		0.08
	)


	damage_tween.tween_property(
		animated_sprite,
		"scale",
		original_scale * Vector2(
			1.12,
			0.78
		),
		0.08
	)


	damage_tween.tween_property(
		animated_sprite,
		"rotation",
		0.12 * float(-direction),
		0.08
	)


	await damage_tween.finished


	# ==========================================
	# FLASH
	# ==========================================

	for i in range(3):

		if is_dead:
			return


		animated_sprite.modulate = Color(
			1.0,
			0.2,
			0.2,
			1.0
		)


		await get_tree().create_timer(
			0.06
		).timeout


		animated_sprite.modulate = Color(
			1.0,
			1.0,
			1.0,
			1.0
		)


		await get_tree().create_timer(
			0.06
		).timeout


	# ==========================================
	# RECUPERAR
	# ==========================================

	var recover_tween: Tween = create_tween()

	recover_tween.set_parallel(true)


	recover_tween.tween_property(
		animated_sprite,
		"position",
		original_position,
		0.12
	)


	recover_tween.tween_property(
		animated_sprite,
		"scale",
		original_scale,
		0.12
	)


	recover_tween.tween_property(
		animated_sprite,
		"rotation",
		original_rotation,
		0.12
	)


	await recover_tween.finished


	if is_dead:
		return


	# ==========================================
	# ÚLTIMA VIDA
	# ==========================================

	if stomp_count == 2:

		entrar_ultima_vida()


	is_hurt = false


# ==========================================
# ÚLTIMA VIDA
# ==========================================

func entrar_ultima_vida() -> void:

	if last_life:
		return


	last_life = true

	blink_time = 0.0

	animated_sprite.speed_scale = 1.25


	print(
		"URSO ESTÁ NA ÚLTIMA VIDA!"
	)


	animated_sprite.modulate = Color(
		1.0,
		0.2,
		0.2,
		1.0
	)


	await get_tree().create_timer(
		0.2
	).timeout


	if is_dead:
		return


	animated_sprite.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0
	)


# ==========================================
# MORTE
# ==========================================

func matar_urso() -> void:

	if is_dead:
		return


	is_dead = true

	is_awake = false
	is_attacking = false
	is_hurt = false
	last_life = false
	returning_to_sleep = false
	player_on_head = false


	# ==========================================
	# SCORE
	# ==========================================

	Globals.score += 1000


	print("URSO DERROTADO!")
	print("+1000 SCORE")
	print(
		"SCORE ATUAL: ",
		Globals.score
	)


	# ==========================================
	# PARAR
	# ==========================================

	velocity = Vector2.ZERO

	set_physics_process(false)


	# ==========================================
	# DESATIVAR AZUL
	# ==========================================

	collision.set_deferred(
		"disabled",
		true
	)


	# ==========================================
	# DESATIVAR VERMELHO
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
	# RESET VISUAL
	# ==========================================

	animated_sprite.speed_scale = 1.0

	animated_sprite.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0
	)


	var original_position: Vector2 = (
		animated_sprite.position
	)


	var original_scale: Vector2 = (
		animated_sprite.scale
	)


	# ==========================================
	# MORTE
	# ==========================================

	var death_tween: Tween = create_tween()

	death_tween.set_parallel(true)


	death_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			-direction * 10.0,
			-3.0
		),
		0.18
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	death_tween.tween_property(
		animated_sprite,
		"rotation",
		0.45 * float(direction),
		0.18
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	death_tween.tween_property(
		animated_sprite,
		"scale",
		original_scale * Vector2(
			1.12,
			0.82
		),
		0.14
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	await death_tween.finished


	await get_tree().create_timer(
		0.08
	).timeout


	# ==========================================
	# QUICADA
	# ==========================================

	var bounce_tween: Tween = create_tween()

	bounce_tween.set_parallel(true)


	bounce_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			-direction * 7.0,
			5.0
		),
		0.12
	)


	bounce_tween.tween_property(
		animated_sprite,
		"rotation",
		0.55 * float(direction),
		0.12
	)


	await bounce_tween.finished


	# ==========================================
	# ESPERA
	# ==========================================

	await get_tree().create_timer(
		0.18
	).timeout


	# ==========================================
	# DESAPARECER
	# ==========================================

	var fade_tween: Tween = create_tween()

	fade_tween.set_parallel(true)


	fade_tween.tween_property(
		animated_sprite,
		"modulate:a",
		0.0,
		0.25
	)


	fade_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			-direction * 10.0,
			10.0
		),
		0.25
	)


	await fade_tween.finished


	queue_free()


# ==========================================
# MORTE DIRETA
# ==========================================

func die() -> void:

	matar_urso()
