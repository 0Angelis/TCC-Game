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
# DISTÂNCIA DO PISÃO
# ==========================================

# Quanto o player pode estar acima do urso
# para ser considerado um pisão.
const STOMP_VERTICAL_DISTANCE: float = 24.0

# Quanto o player pode estar deslocado
# horizontalmente.
const STOMP_HORIZONTAL_DISTANCE: float = 26.0


# ==========================================
# PLAYER
# ==========================================

var player: Node2D = null


# ==========================================
# ESTADO
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
# DANO
# ==========================================

const HURT_TIME: float = 0.55


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

	is_dead = false
	is_awake = false
	is_attacking = false
	is_hurt = false
	returning_to_sleep = false

	stomp_count = 0
	stomp_cooldown = 0.0

	can_attack = true
	attack_cooldown_timer = 0.0

	last_life = false
	blink_time = 0.0

	direction = -1

	animated_sprite.flip_h = false
	animated_sprite.speed_scale = 1.0


	# ==========================================
	# RAYCAST
	# ==========================================

	ray_cast.enabled = true

	_update_ray_cast()


	# ==========================================
	# COMEÇA DEITADO
	# ==========================================

	deixar_dormindo()


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
	# GRAVIDADE
	# ==========================================

	if not is_on_floor():

		velocity += get_gravity() * delta


	# ==========================================
	# COOLDOWN DO PISÃO
	# ==========================================

	if stomp_cooldown > 0.0:

		stomp_cooldown -= delta


	# ==========================================
	# COOLDOWN DO ATAQUE
	# ==========================================

	if attack_cooldown_timer > 0.0:

		attack_cooldown_timer -= delta

	else:

		can_attack = true


	# ==========================================
	# ÚLTIMA VIDA
	# ==========================================

	if last_life and not is_hurt:

		blink_time += delta

		var blink_value: float = abs(
			sin(blink_time * 10.0)
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
	# ENCONTRAR PLAYER
	# ==========================================

	if player == null or not is_instance_valid(player):

		var players: Array[Node] = get_tree().get_nodes_in_group("player")

		if players.size() > 0:

			player = players[0] as Node2D


	# ==========================================
	# VERIFICAR PISÃO
	# ==========================================

	verificar_pisao()


	if is_dead:
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
	# DORMINDO
	# ==========================================

	if not is_awake:

		velocity.x = 0.0

		move_and_slide()

		deixar_dormindo()


		if player != null:

			var distance: float = global_position.distance_to(
				player.global_position
			)


			if distance <= DETECTION_DISTANCE:

				acordar()


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
	# COLISÃO COM PAREDE
	# ==========================================

	for i in get_slide_collision_count():

		var slide_collision: KinematicCollision2D = (
			get_slide_collision(i)
		)

		var normal: Vector2 = slide_collision.get_normal()


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
		and is_awake
	):

		if animated_sprite.sprite_frames != null:

			if animated_sprite.sprite_frames.has_animation("walking"):

				if animated_sprite.animation != "walking":

					animated_sprite.play("walking")


# ==========================================
# DEIXAR DORMINDO
# ==========================================

func deixar_dormindo() -> void:

	if is_dead:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation("sleep"):
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

		if animated_sprite.sprite_frames.has_animation("sleep"):

			animated_sprite.play("sleep")

			await animated_sprite.animation_finished


	if is_dead:
		return


	if returning_to_sleep:
		return


	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("walking"):

			animated_sprite.play("walking")


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


	print("URSO PERDEU O PLAYER E VAI DORMIR!")


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
# PERSEGUIR PLAYER
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
	# ATAQUE
	# ==========================================

	if (
		abs(distancia_x) <= ATTACK_TRIGGER_DISTANCE
		and distancia_y <= 32.0
	):

		entrar_attack()

		return


	# ==========================================
	# PERSEGUIÇÃO
	# ==========================================

	is_attacking = false

	var speed: float = CHASE_SPEED


	if last_life:

		speed *= LAST_LIFE_SPEED_MULTIPLIER


	velocity.x = direction * speed


	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("walking"):

			if animated_sprite.animation != "walking":

				animated_sprite.play("walking")


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
		abs(distancia_x) > ATTACK_TRIGGER_DISTANCE
		or distancia_y > 32.0
	):

		is_attacking = false

		return


	is_attacking = true


	# ==========================================
	# VIRAR
	# ==========================================

	if player.global_position.x > global_position.x:

		direction = 1

	else:

		direction = -1


	animated_sprite.flip_h = direction > 0

	_update_ray_cast()


	# ==========================================
	# IR PARA O PLAYER
	# ==========================================

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
	# ANIMAÇÃO ATTACK
	# ==========================================

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("attack"):

			if animated_sprite.animation != "attack":

				animated_sprite.play("attack")


	# ==========================================
	# COOLDOWN
	# ==========================================

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
# VERIFICAR PISÃO
# ==========================================

func verificar_pisao() -> void:

	if player == null:
		return


	if not is_instance_valid(player):
		return


	if is_dead:
		return


	if is_hurt:
		return


	if returning_to_sleep:
		return


	if stomp_cooldown > 0.0:
		return


	# ==========================================
	# DISTÂNCIA HORIZONTAL
	# ==========================================

	var distancia_x: float = abs(
		player.global_position.x
		- global_position.x
	)


	# ==========================================
	# DIFERENÇA VERTICAL
	# ==========================================
	#
	# Aqui está a correção principal.
	#
	# O valor precisa ser pequeno.
	# Se estiver muito acima, NÃO é pisão.
	#

	var diferenca_vertical: float = (
		global_position.y
		- player.global_position.y
	)


	# ==========================================
	# PLAYER ESTÁ ACIMA
	# ==========================================

	var player_above: bool = (
		diferenca_vertical > 0.0
		and diferenca_vertical <= STOMP_VERTICAL_DISTANCE
	)


	# ==========================================
	# PLAYER ESTÁ CAINDO
	# ==========================================

	var player_falling: bool = false


	if player is CharacterBody2D:

		var player_body: CharacterBody2D = (
			player as CharacterBody2D
		)

		player_falling = player_body.velocity.y > 0.0


	# ==========================================
	# PISÃO REAL
	# ==========================================

	if (
		player_above
		and player_falling
		and distancia_x <= STOMP_HORIZONTAL_DISTANCE
	):

		print("PISÃO REAL DETECTADO!")

		pisar_no_urso()


# ==========================================
# PISÃO
# ==========================================

func pisar_no_urso() -> void:

	if is_dead:
		return


	stomp_cooldown = 0.45

	stomp_count += 1


	# ==========================================
	# IMPEDIR ATAQUE
	# ==========================================

	is_attacking = false
	can_attack = false

	attack_cooldown_timer = 0.9


	# ==========================================
	# DESATIVAR HITBOX
	# ==========================================

	hitbox.set_deferred(
		"monitoring",
		false
	)


	print(
		"URSO PISADO: ",
		stomp_count,
		"/",
		MAX_STOMPS
	)


	# ==========================================
	# REBATER PLAYER
	# ==========================================

	if player != null:

		if player is CharacterBody2D:

			var player_body: CharacterBody2D = (
				player as CharacterBody2D
			)

			player_body.velocity.y = -120.0


	# ==========================================
	# TERCEIRO PISÃO
	# ==========================================

	if stomp_count >= MAX_STOMPS:

		matar_urso()

		return


	# ==========================================
	# REAÇÃO AO DANO
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


	var recoil_x: float = -direction * 5.0


	damage_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(
			recoil_x,
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
	# SEGUNDO PISÃO
	# ==========================================

	if stomp_count == 2:

		entrar_ultima_vida()


	is_hurt = false


	# ==========================================
	# REATIVAR HITBOX
	# ==========================================

	hitbox.set_deferred(
		"monitoring",
		true
	)


	# ==========================================
	# WALKING
	# ==========================================

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("walking"):

			animated_sprite.play("walking")


# ==========================================
# ÚLTIMA VIDA
# ==========================================

func entrar_ultima_vida() -> void:

	if last_life:
		return


	last_life = true

	blink_time = 0.0

	animated_sprite.speed_scale = 1.25


	print("URSO ESTÁ NA ÚLTIMA VIDA!")


	# ==========================================
	# FLASH FORTE
	# ==========================================

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
# HITBOX
# ==========================================

func _on_hitbox_body_entered(body: Node2D) -> void:

	if is_dead:
		return


	if is_hurt:
		return


	if not body.is_in_group("player"):
		return


	# ==========================================
	# SE PLAYER ESTÁ ACIMA,
	# NÃO ATACA
	# ==========================================

	if body.global_position.y < global_position.y - 5.0:

		return


	if player == null:

		player = body


	var distancia: float = (
		global_position.distance_to(
			body.global_position
		)
	)


	if distancia <= ATTACK_TRIGGER_DISTANCE:

		entrar_attack()


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


	# ==========================================
	# SCORE
	# ==========================================

	Globals.score += 1000

	print("URSO DERROTADO!")
	print("+1000 SCORE")
	print("SCORE ATUAL: ", Globals.score)


	# ==========================================
	# PARAR
	# ==========================================

	velocity = Vector2.ZERO

	set_physics_process(false)


	# ==========================================
	# DESATIVAR TUDO
	# ==========================================

	collision.set_deferred(
		"disabled",
		true
	)

	hitbox.set_deferred(
		"monitoring",
		false
	)

	hitbox_collision.set_deferred(
		"disabled",
		true
	)

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
	# QUEDA PARA TRÁS
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
	# FICA NO CHÃO
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
