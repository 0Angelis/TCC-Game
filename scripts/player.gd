extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

const SPEED: float = 120.0
const JUMP_FORCE: float = -300.0


# ==========================================
# KNOCKBACK
# ==========================================

const ENEMY_KNOCKBACK_X: float = 85.0
const ENEMY_KNOCKBACK_Y: float = -55.0

const SPIKE_KNOCKBACK_Y: float = -35.0

const KNOCKBACK_TIME: float = 0.08

var knockback_vector: Vector2 = Vector2.ZERO
var knockback_active: bool = false


# ==========================================
# TEMPOS DE DANO
# ==========================================

const HURT_ANIMATION_TIME: float = 0.12
const INVINCIBILITY_TIME: float = 0.4


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

	knockback_vector = Vector2.ZERO
	knockback_active = false

	print("PLAYER INICIADO")
	print("Vidas: ", Globals.player_life)
	print("TileMap encontrado: ", level)


# ==========================================
# INPUT
# ==========================================

func _unhandled_input(event: InputEvent) -> void:

	if is_dead:
		return


	# ==========================================
	# TECLA B = DANÇA
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
	# CANCELAR DANÇA COM MOVIMENTO
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
		and not moving_down
		and not taking_damage
		and not knockback_active
	):

		velocity.y = JUMP_FORCE


	# ==========================================
	# MOVIMENTO NORMAL
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

		velocity.x = move_toward(
			velocity.x,
			0.0,
			900.0 * delta
		)


	# ==========================================
	# WARNING
	# ==========================================

	if showing_warning:

		if (
			Input.is_key_pressed(KEY_A)
			or Input.is_key_pressed(KEY_D)
			or Input.is_key_pressed(KEY_LEFT)
			or Input.is_key_pressed(KEY_RIGHT)
			or Input.is_key_pressed(KEY_W)
			or Input.is_key_pressed(KEY_UP)
			or Input.is_key_pressed(KEY_DOWN)
			or Input.is_key_pressed(KEY_S)
			or Input.is_key_pressed(KEY_SPACE)
		):

			showing_warning = false


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

	elif not is_on_floor() and velocity.y > 0:

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

	if Globals.player_life == 1 and not taking_damage:

		var blink: float = abs(
			sin(Time.get_ticks_msec() * 0.005)
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
	# MOVIMENTO
	# ==========================================

	move_and_slide()


	# ==========================================
	# ESPINHOS
	# ==========================================

	check_damage_tile()


# ==========================================
# DANO DOS INIMIGOS
# ==========================================

func _on_hurtbox_body_entered(body: Node2D) -> void:

	if is_dead:
		return


	if not body.is_in_group("enemies"):
		return


	# ==========================================
	# PLAYER ESTÁ ACIMA DO INIMIGO
	# ==========================================

	if (
		body.global_position.y > global_position.y
		and velocity.y >= 0.0
	):

		return


	# ==========================================
	# DIREÇÃO DO KNOCKBACK
	# ==========================================

	var knockback_direction: Vector2 = (
		global_position - body.global_position
	).normalized()


	take_damage(
		Vector2(
			knockback_direction.x * ENEMY_KNOCKBACK_X,
			ENEMY_KNOCKBACK_Y
		)
	)


# ==========================================
# ESPINHOS
# ==========================================

func check_damage_tile() -> void:

	if is_dead:
		return


	if not can_take_damage:
		return


	if level == null:

		print("ERRO: TileMap 'level' não encontrado!")

		return


	var feet_position: Vector2 = (
		global_position + Vector2(0, 12)
	)


	var positions: Array[Vector2] = [
		feet_position,
		feet_position + Vector2(-8, 0),
		feet_position + Vector2(8, 0),
		feet_position + Vector2(0, 8),
		feet_position + Vector2(0, 16)
	]


	for layer_index in range(
		level.get_layers_count()
	):

		for world_position in positions:

			var local_position: Vector2 = level.to_local(
				world_position
			)


			var tile_position: Vector2i = level.local_to_map(
				local_position
			)


			var tile_data = level.get_cell_tile_data(
				layer_index,
				tile_position
			)


			if tile_data == null:
				continue


			var damage = tile_data.get_custom_data(
				"damage"
			)


			if damage == true:

				print("ESPINHO DETECTADO!")


				take_damage(
					Vector2(
						0.0,
						SPIKE_KNOCKBACK_Y
					)
				)


				return


# ==========================================
# RECEBE DANO
# ==========================================

func take_damage(
	knockback_force: Vector2 = Vector2.ZERO
) -> void:

	if is_dead:
		return


	if not can_take_damage:
		return


	# ==========================================
	# BLOQUEAR NOVO DANO
	# ==========================================

	can_take_damage = false
	can_move = false
	taking_damage = true

	showing_warning = false
	celebrating = false


	# ==========================================
	# PERDE VIDA
	# ==========================================

	if Globals.player_life > 0:

		Globals.player_life -= 1

		print(
			"VIDA: ",
			Globals.player_life
		)

	else:

		die()

		return


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


		# ==========================================
		# KNOCKBACK CURTO
		# ==========================================

		await get_tree().create_timer(
			KNOCKBACK_TIME
		).timeout


		if is_dead:
			return


		knockback_active = false


		# Reduz o impulso restante
		velocity.x *= 0.15
		velocity.y *= 0.15


	# ==========================================
	# ANIMAÇÃO DE HURT CURTA
	# ==========================================

	await get_tree().create_timer(
		HURT_ANIMATION_TIME
	).timeout


	if is_dead:
		return


	# ==========================================
	# VOLTA AO NORMAL RAPIDAMENTE
	# ==========================================

	taking_damage = false
	can_move = true


	animation.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0
	)


	# ==========================================
	# INVENCIBILIDADE CONTINUA
	# ==========================================
	#
	# O player pode se mover normalmente,
	# mas ainda não pode tomar outro dano.
	#

	await get_tree().create_timer(
		INVINCIBILITY_TIME - HURT_ANIMATION_TIME
	).timeout


	if is_dead:
		return


	can_take_damage = true


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

	print("WARNING DO PLAYER!")


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


	print("================================")
	print("ANIMAÇÃO DE VITÓRIA!")
	print("================================")


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


	print("================================")
	print("DANÇA ATIVADA PELA TECLA B!")
	print("================================")


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
	knockback_vector = Vector2.ZERO
	knockback_active = false


	# ==========================================
	# FECHA WARNING
	# ==========================================

	if DialogManager.is_message_active:

		DialogManager.close_message()


	# ==========================================
	# GUARDA CENA
	# ==========================================

	get_tree().set_meta(
		"restart_scene",
		get_tree().current_scene.scene_file_path
	)


	print(
		"PRÓXIMA CENA DE RESTART: ",
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


	# ==========================================
	# RESET FRAGMENTOS
	# ==========================================

	Globals.raciocinio_fragments = 0
	Globals.atencao_fragments = 0
	Globals.memoria_fragments = 0


	print("==============================")
	print("JOGADOR MORREU")
	print("==============================")


	# ==========================================
	# SOME
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

func follow_camera(camera: Camera2D) -> void:

	var camera_path: NodePath = camera.get_path()

	remote_transform.remote_path = camera_path
