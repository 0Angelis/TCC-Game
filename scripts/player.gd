extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

const SPEED = 150.0
const JUMP_FORCE = -300.0


# ==========================================
# KNOCKBACK
# ==========================================

const ENEMY_KNOCKBACK_X = 120.0
const ENEMY_KNOCKBACK_Y = -45.0
const SPIKE_KNOCKBACK_Y = -35.0

var knockback_vector := Vector2.ZERO


# ==========================================
# ESTADOS
# ==========================================

var taking_damage := false
var can_take_damage := true
var can_move := true
var is_dead := false

# Warning da placa
var showing_warning := false

# Vitória ao pegar fragmento
var celebrating := false


# ==========================================
# NÓS
# ==========================================

@onready var animation = $Anim as AnimatedSprite2D
@onready var remote_transform = $remote as RemoteTransform2D
@onready var level = get_tree().current_scene.get_node("level")


# ==========================================
# READY
# ==========================================

func _ready():

	add_to_group("player")

	# 5 vidas
	Globals.player_life = 5

	is_dead = false
	taking_damage = false
	can_take_damage = true
	can_move = true
	showing_warning = false
	celebrating = false

	print("PLAYER INICIADO")
	print("Vidas: ", Globals.player_life)
	print("TileMap encontrado: ", level)


# ==========================================
# INPUT
# ==========================================

func _unhandled_input(event):

	if is_dead:
		return

	# Se estiver dançando, uma NOVA tecla
	# de movimento cancela a dança.
	if celebrating:

		if event is InputEventKey and event.pressed and not event.echo:

			if (
				event.keycode == KEY_A
				or event.keycode == KEY_D
				or event.keycode == KEY_LEFT
				or event.keycode == KEY_RIGHT
				or event.keycode == KEY_W
				or event.keycode == KEY_UP
				or event.keycode == KEY_DOWN
				or event.keycode == KEY_SPACE
			):

				celebrating = false

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
	# KNOCKBACK
	# ==========================================

	velocity += knockback_vector


	# ==========================================
	# SETA PARA BAIXO
	# ==========================================

	var moving_down := Input.is_key_pressed(KEY_DOWN)


	# ==========================================
	# DIREÇÃO HORIZONTAL
	# ==========================================

	var direction := 0

	if not moving_down:

		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):

			direction = -1

		elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):

			direction = 1


	# ==========================================
	# PULO
	# ==========================================

	if (
		Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_SPACE)
		or Input.is_key_pressed(KEY_UP)
	) and is_on_floor() and can_move and not moving_down:

		velocity.y = JUMP_FORCE


	# ==========================================
	# MOVIMENTO HORIZONTAL
	# ==========================================

	if moving_down:

		# ↓ = não anda
		velocity.x = 0

	elif direction != 0 and can_move:

		velocity.x = direction * SPEED

		animation.flip_h = direction < 0

	elif can_move:

		velocity.x = move_toward(
			velocity.x,
			0,
			SPEED
		)


	# ==========================================
	# CANCELA WARNING AO MOVIMENTAR
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
			or Input.is_key_pressed(KEY_SPACE)
		):

			showing_warning = false


	# ==========================================
	# ANIMAÇÕES
	# ==========================================

	# ------------------------------------------
	# 1. HURT
	# ------------------------------------------

	if taking_damage:

		if animation.animation != "hurt":

			animation.play("hurt")


	# ------------------------------------------
	# 2. VITÓRIA
	# ------------------------------------------

	elif celebrating:

		if animation.animation != "vitoria":

			animation.play("vitoria")


	# ------------------------------------------
	# 3. WARNING
	# ------------------------------------------

	elif showing_warning:

		if animation.animation != "warning":

			animation.play("warning")


	# ------------------------------------------
	# 4. ARRASTAR
	# ------------------------------------------

	elif moving_down and is_on_floor():

		if animation.animation != "arrastar":

			animation.play("arrastar")


	# ------------------------------------------
	# 5. FALLING
	# ------------------------------------------

	elif not is_on_floor() and velocity.y > 0:

		if animation.animation != "falling":

			animation.play("falling")


	# ------------------------------------------
	# 6. JUMP
	# ------------------------------------------

	elif not is_on_floor():

		if animation.animation != "jump":

			animation.play("jump")


	# ------------------------------------------
	# 7. RUN
	# ------------------------------------------

	elif direction != 0:

		if animation.animation != "run":

			animation.play("run")


	# ------------------------------------------
	# 8. IDLE
	# ------------------------------------------

	else:

		if animation.animation != "idle":

			animation.play("idle")


	# ==========================================
	# ÚLTIMA VIDA PISCANDO
	# ==========================================

	if Globals.player_life == 1 and not taking_damage:

		var blink = abs(
			sin(Time.get_ticks_msec() * 0.005)
		)

		animation.modulate = Color(
			1,
			blink,
			blink,
			1
		)

	elif not taking_damage:

		animation.modulate = Color(
			1,
			1,
			1,
			1
		)


	# ==========================================
	# MOVIMENTO
	# ==========================================

	move_and_slide()


	# ==========================================
	# VERIFICA ESPINHOS
	# ==========================================

	check_damage_tile()


# ==========================================
# DANO DOS INIMIGOS
# ==========================================

func _on_hurtbox_body_entered(body: Node2D) -> void:

	if is_dead:
		return

	if body.is_in_group("enemies"):

		var direction = (
			global_position - body.global_position
		).normalized()

		take_damage(
			Vector2(
				direction.x * ENEMY_KNOCKBACK_X,
				ENEMY_KNOCKBACK_Y
			)
		)


# ==========================================
# VERIFICA ESPINHOS
# ==========================================

func check_damage_tile() -> void:

	if is_dead:
		return

	if not can_take_damage:
		return


	if level == null:

		print("ERRO: TileMap 'level' não encontrado!")

		return


	var feet_position = global_position + Vector2(0, 12)


	var positions = [

		feet_position,
		feet_position + Vector2(-8, 0),
		feet_position + Vector2(8, 0),
		feet_position + Vector2(0, 8),
		feet_position + Vector2(0, 16)

	]


	for layer_index in range(level.get_layers_count()):

		for world_position in positions:

			var local_position = level.to_local(
				world_position
			)

			var tile_position = level.local_to_map(
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

				print("================================")
				print("ESPINHO DETECTADO!")
				print("Camada: ", layer_index)
				print("Tile: ", tile_position)
				print("Damage: ", damage)
				print("================================")


				take_damage(
					Vector2(
						0,
						SPIKE_KNOCKBACK_Y
					)
				)

				return


# ==========================================
# RECEBE DANO
# ==========================================

func take_damage(
	knockback_force := Vector2.ZERO,
	duration := 0.20
):

	if is_dead:
		return

	if not can_take_damage:
		return


	can_take_damage = false
	can_move = false
	taking_damage = true

	showing_warning = false
	celebrating = false


	# ==========================================
	# PERDE UMA VIDA
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


	# ==========================================
	# VERMELHO SUAVE
	# ==========================================

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

		knockback_vector = knockback_force

		var knockback_tween := get_tree().create_tween()

		knockback_tween.tween_property(
			self,
			"knockback_vector",
			Vector2.ZERO,
			duration
		)


	# ==========================================
	# PEQUENO STUN
	# ==========================================

	await get_tree().create_timer(0.08).timeout

	if is_dead:
		return

	can_move = true


	# ==========================================
	# INVENCIBILIDADE
	# ==========================================

	await get_tree().create_timer(0.4).timeout

	if is_dead:
		return

	can_take_damage = true
	taking_damage = false


	# ==========================================
	# VOLTA AO NORMAL
	# ==========================================

	animation.modulate = Color(
		1,
		1,
		1,
		1
	)


# ==========================================
# WARNING
# ==========================================

func play_warning():

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

func stop_warning():

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

func play_victory():

	if is_dead:
		return

	if taking_damage:
		return


	showing_warning = false

	celebrating = true

	# NÃO trava o player
	can_move = true

	# NÃO zera velocity
	# Assim ele continua caindo normalmente.

	animation.stop()
	animation.play("vitoria")

	print("================================")
	print("FRAGMENTO PEGADO!")
	print("ANIMAÇÃO DE VITÓRIA!")
	print("================================")


# ==========================================
# MORTE
# ==========================================

func die():

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

	Globals.level_coins = 0
	Globals.level_score = 0

	Globals.raciocinio_fragments = 0


	print("==============================")
	print("JOGADOR MORREU")
	print("MOEDAS RESETADAS: ", Globals.coins)
	print("SCORE RESETADO: ", Globals.score)
	print(
		"FRAGMENTOS RESETADOS: ",
		Globals.raciocinio_fragments
	)
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

func follow_camera(camera):

	var camera_path = camera.get_path()

	remote_transform.remote_path = camera_path
