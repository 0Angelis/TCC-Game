extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

const SPEED: float = 120.0
const JUMP_FORCE: float = -300.0


# ==========================================
# KNOCKBACK DOS INIMIGOS
# ==========================================

const ENEMY_KNOCKBACK_X: float = 180.0
const ENEMY_KNOCKBACK_Y: float = -150.0

const SPIKE_KNOCKBACK_Y: float = -35.0


# ==========================================
# KNOCKBACK
# ==========================================

var knockback_active: bool = false

const KNOCKBACK_CONTROL_TIME: float = 0.12

var knockback_control_timer: float = 0.0


# ==========================================
# DANO
# ==========================================

const HURT_ANIMATION_TIME: float = 0.12
const INVINCIBILITY_TIME: float = 0.4


# ==========================================
# COOLDOWN DE INIMIGO
# ==========================================

var enemy_damage_cooldown: float = 0.0


# ==========================================
# ESTADOS
# ==========================================

var taking_damage: bool = false
var can_take_damage: bool = true
var can_move: bool = true
var is_dead: bool = false


# ==========================================
# WARNING
# ==========================================

var showing_warning: bool = false


# ==========================================
# VITÓRIA / DANÇA
# ==========================================

var celebrating: bool = false


# ==========================================
# NÓS
# ==========================================

@onready var animation: AnimatedSprite2D = $Anim
@onready var remote_transform: RemoteTransform2D = $remote
@onready var level = get_tree().current_scene.get_node("level")


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	add_to_group("player")

	Globals.player_life = 5

	is_dead = false
	taking_damage = false
	can_take_damage = true
	can_move = true

	showing_warning = false
	celebrating = false

	knockback_active = false
	knockback_control_timer = 0.0

	enemy_damage_cooldown = 0.0

	print("PLAYER INICIADO")
	print("VIDAS: ", Globals.player_life)


# ==========================================
# INPUT
# ==========================================

func _unhandled_input(event: InputEvent) -> void:

	if is_dead:
		return


	# ==========================================
	# B = DANÇA
	# ==========================================

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_B
	):

		play_dance()

		get_viewport().set_input_as_handled()

		return


	# ==========================================
	# CANCELAR DANÇA
	# ==========================================

	if celebrating:

		if (
			event is InputEventKey
			and event.pressed
			and not event.echo
		):

			if (
				event.keycode == KEY_A
				or event.keycode == KEY_D
				or event.keycode == KEY_LEFT
				or event.keycode == KEY_RIGHT
				or event.keycode == KEY_W
				or event.keycode == KEY_UP
				or event.keycode == KEY_DOWN
				or event.keycode == KEY_S
				or event.keycode == KEY_SPACE
			):

				celebrating = false
				can_move = true

				print("DANÇA CANCELADA")


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
	# COOLDOWN
	# ==========================================

	if enemy_damage_cooldown > 0.0:

		enemy_damage_cooldown -= delta


	# ==========================================
	# TIMER KNOCKBACK
	# ==========================================

	if knockback_control_timer > 0.0:

		knockback_control_timer -= delta

	else:

		knockback_active = false


	# ==========================================
	# AGACHAR
	# ==========================================

	var moving_down: bool = (
		Input.is_key_pressed(KEY_DOWN)
		or Input.is_key_pressed(KEY_S)
	)


	# ==========================================
	# DIREÇÃO
	# ==========================================

	var direction: int = 0


	if not moving_down:

		if (
			Input.is_key_pressed(KEY_A)
			or Input.is_key_pressed(KEY_LEFT)
		):

			direction = -1

		elif (
			Input.is_key_pressed(KEY_D)
			or Input.is_key_pressed(KEY_RIGHT)
		):

			direction = 1


	# ==========================================
	# PULO
	# ==========================================

	if (
		(
			Input.is_key_pressed(KEY_W)
			or Input.is_key_pressed(KEY_SPACE)
			or Input.is_key_pressed(KEY_UP)
		)
		and is_on_floor()
		and can_move
		and not taking_damage
		and not knockback_active
		and not moving_down
	):

		velocity.y = JUMP_FORCE


	# ==========================================
	# MOVIMENTO
	# ==========================================

	if not knockback_active:

		if moving_down:

			velocity.x = 0.0

		elif direction != 0 and can_move:

			velocity.x = direction * SPEED

			animation.flip_h = direction < 0

		elif can_move:

			velocity.x = move_toward(
				velocity.x,
				0.0,
				SPEED
			)


	# ==========================================
	# KNOCKBACK
	# ==========================================

	if knockback_active:

		# Mantém o impulso horizontal,
		# mas deixa ele diminuir naturalmente.

		velocity.x = move_toward(
			velocity.x,
			0.0,
			120.0 * delta
		)


	# ==========================================
	# ANIMAÇÕES
	# ==========================================

	if taking_damage:

		if animation.animation != "hurt":

			animation.play("hurt")

	elif celebrating:

		if animation.animation != "vitoria":

			animation.play("vitoria")

	elif showing_warning:

		if animation.animation != "warning":

			animation.play("warning")

	elif moving_down and is_on_floor():

		if animation.animation != "arrastar":

			animation.play("arrastar")

	elif not is_on_floor() and velocity.y > 0.0:

		if animation.animation != "falling":

			animation.play("falling")

	elif not is_on_floor():

		if animation.animation != "jump":

			animation.play("jump")

	elif direction != 0:

		if animation.animation != "run":

			animation.play("run")

	else:

		if animation.animation != "idle":

			animation.play("idle")


	# ==========================================
	# ÚLTIMA VIDA
	# ==========================================

	if (
		Globals.player_life == 1
		and not taking_damage
	):

		var blink: float = abs(
			sin(
				Time.get_ticks_msec() * 0.005
			)
		)


		animation.modulate = Color(
			1.0,
			blink,
			blink,
			1.0
		)

	elif not taking_damage:

		animation.modulate = Color(
			1.0,
			1.0,
			1.0,
			1.0
		)


	# ==========================================
	# MOVIMENTO FÍSICO
	# ==========================================

	move_and_slide()


	# ==========================================
	# AQUI ESTÁ A CORREÇÃO
	# ==========================================
	#
	# O PLAYER verifica as colisões que ELE
	# acabou de fazer.
	#
	# Isso detecta o collision azul do urso.
	#

	verificar_colisao_com_inimigo()


	# ==========================================
	# ESPINHOS
	# ==========================================

	check_damage_tile()


# ==========================================
# VERIFICAR COLISÃO COM INIMIGO
# ==========================================

func verificar_colisao_com_inimigo() -> void:

	if is_dead:
		return


	if not can_take_damage:
		return


	if enemy_damage_cooldown > 0.0:
		return


	# ==========================================
	# PEGAR TODAS AS COLISÕES DO PLAYER
	# ==========================================

	var collision_count: int = (
		get_slide_collision_count()
	)


	if collision_count <= 0:
		return


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


		# ==========================================
		# PRECISA SER INIMIGO
		# ==========================================

		if not other_body.is_in_group("enemies"):

			continue


		# ==========================================
		# INIMIGO MORTO?
		# ==========================================

		var enemy_dead = (
			other_body.get("is_dead")
		)


		if enemy_dead == true:

			continue


		# ==========================================
		# NORMAL DA COLISÃO
		# ==========================================

		var normal: Vector2 = (
			slide_collision.get_normal()
		)


		# ==========================================
		# PLAYER ESTÁ EM CIMA
		# ==========================================
		#
		# Normal apontando para cima significa
		# que o player bateu por cima.
		#
		# NÃO toma dano.
		#

		if normal.y < -0.5:

			continue


		# ==========================================
		# PRECISA SER COLISÃO LATERAL
		# ==========================================

		if abs(normal.x) < 0.5:

			continue


		# ==========================================
		# DANO
		# ==========================================

		print("==============================")
		print("PLAYER BATEU NO CORPO DO INIMIGO!")
		print(
			"Inimigo: ",
			other_body.name
		)
		print(
			"Normal: ",
			normal
		)
		print("==============================")


		var knockback_direction: float = 1.0


		if (
			global_position.x
			< other_body.global_position.x
		):

			knockback_direction = -1.0


		receber_dano_inimigo(
			Vector2(
				knockback_direction
				* ENEMY_KNOCKBACK_X,
				ENEMY_KNOCKBACK_Y
			)
		)


		enemy_damage_cooldown = 0.7


		return


# ==========================================
# HURTBOX
# ==========================================

func _on_hurtbox_body_entered(
	body: Node2D
) -> void:

	# Não usamos Hurtbox para inimigos.
	return


# ==========================================
# ESPINHOS
# ==========================================

func check_damage_tile() -> void:

	if is_dead:
		return


	if not can_take_damage:
		return


	if level == null:

		return


	var feet_position: Vector2 = (
		global_position
		+ Vector2(
			0.0,
			12.0
		)
	)


	var positions: Array[Vector2] = [
		feet_position,
		feet_position + Vector2(-8.0, 0.0),
		feet_position + Vector2(8.0, 0.0),
		feet_position + Vector2(0.0, 8.0),
		feet_position + Vector2(0.0, 16.0)
	]


	for layer_index in range(
		level.get_layers_count()
	):

		for world_position in positions:

			var local_position: Vector2 = (
				level.to_local(
					world_position
				)
			)


			var tile_position: Vector2i = (
				level.local_to_map(
					local_position
				)
			)


			var tile_data = (
				level.get_cell_tile_data(
					layer_index,
					tile_position
				)
			)


			if tile_data == null:

				continue


			var damage = (
				tile_data.get_custom_data(
					"damage"
				)
			)


			if damage == true:

				print(
					"ESPINHO DETECTADO!"
				)


				take_damage(
					Vector2(
						0.0,
						SPIKE_KNOCKBACK_Y
					)
				)


				return


# ==========================================
# RECEBER DANO
# ==========================================

func take_damage(
	knockback_force: Vector2 = Vector2.ZERO
) -> void:

	if is_dead:
		return


	if not can_take_damage:
		return


	# ==========================================
	# BLOQUEIA NOVO DANO
	# ==========================================

	can_take_damage = false

	taking_damage = true

	showing_warning = false
	celebrating = false


	# ==========================================
	# PERDE VIDA
	# ==========================================

	if Globals.player_life > 0:

		Globals.player_life -= 1

	else:

		die()

		return


	print(
		"VIDA: ",
		Globals.player_life
	)


	# ==========================================
	# MORTE
	# ==========================================

	if Globals.player_life <= 0:

		die()

		return


	# ==========================================
	# HURT
	# ==========================================

	animation.play("hurt")


	animation.modulate = Color(
		1.0,
		0.55,
		0.55,
		1.0
	)


	# ==========================================
	# KNOCKBACK
	# ==========================================

	if knockback_force != Vector2.ZERO:

		velocity = knockback_force

		knockback_active = true

		knockback_control_timer = (
			KNOCKBACK_CONTROL_TIME
		)


	# ==========================================
	# HURT CURTO
	# ==========================================

	await get_tree().create_timer(
		HURT_ANIMATION_TIME
	).timeout


	if is_dead:
		return


	taking_damage = false


	animation.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0
	)


	# ==========================================
	# INVENCIBILIDADE
	# ==========================================

	await get_tree().create_timer(
		INVINCIBILITY_TIME
	).timeout


	if is_dead:
		return


	can_take_damage = true


# ==========================================
# DANO DE INIMIGO
# ==========================================

func receber_dano_inimigo(
	knockback: Vector2 = Vector2.ZERO
) -> void:

	print("==============================")
	print("DANO DO INIMIGO RECEBIDO!")
	print(
		"VIDA ANTES: ",
		Globals.player_life
	)
	print("==============================")


	take_damage(knockback)


	print("==============================")
	print(
		"VIDA DEPOIS: ",
		Globals.player_life
	)
	print("==============================")


# ==========================================
# WARNING
# ==========================================

func play_warning() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	if celebrating:
		return


	showing_warning = true

	animation.play("warning")


	print(
		"WARNING DO PLAYER!"
	)


# ==========================================
# PARA WARNING
# ==========================================

func stop_warning() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	if celebrating:
		return


	showing_warning = false


# ==========================================
# VITÓRIA
# ==========================================

func play_victory() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	showing_warning = false

	celebrating = true

	can_move = false

	velocity.x = 0.0

	animation.stop()

	animation.play("vitoria")


	print(
		"================================"
	)

	print(
		"ANIMAÇÃO DE VITÓRIA!"
	)

	print(
		"================================"
	)


# ==========================================
# DANÇA
# ==========================================

func play_dance() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	showing_warning = false

	celebrating = true

	can_move = false

	velocity.x = 0.0

	animation.stop()

	animation.play("vitoria")


	print(
		"================================"
	)

	print(
		"DANÇA ATIVADA PELA TECLA B!"
	)

	print(
		"================================"
	)


# ==========================================
# MORTE
# ==========================================

func die() -> void:

	if is_dead:
		return


	is_dead = true

	can_move = false
	can_take_damage = false
	taking_damage = true

	showing_warning = false
	celebrating = false

	velocity = Vector2.ZERO

	knockback_active = false
	knockback_control_timer = 0.0


	# ==========================================
	# FECHAR WARNING
	# ==========================================

	if DialogManager.is_message_active:

		DialogManager.close_message()


	# ==========================================
	# SALVAR CENA
	# ==========================================

	get_tree().set_meta(
		"restart_scene",
		get_tree().current_scene.scene_file_path
	)


	# ==========================================
	# RESET
	# ==========================================

	Globals.coins = 0
	Globals.score = 0

	Globals.coins_before_level = 0

	Globals.level_coins = 0
	Globals.level_score = 0

	Globals.raciocinio_fragments = 0
	Globals.atencao_fragments = 0
	Globals.memoria_fragments = 0


	print(
		"=============================="
	)

	print(
		"JOGADOR MORREU"
	)

	print(
		"=============================="
	)


	# ==========================================
	# SUMIR
	# ==========================================

	animation.visible = false

	set_physics_process(false)


	# ==========================================
	# GAME OVER
	# ==========================================

	get_tree().change_scene_to_file(
		"res://scenes/game_over.tscn"
	)


# ==========================================
# CÂMERA
# ==========================================

func follow_camera(
	camera: Camera2D
) -> void:

	var camera_path: NodePath = (
		camera.get_path()
	)


	remote_transform.remote_path = (
		camera_path
	)
