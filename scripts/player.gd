extends CharacterBody2D

const SPEED = 150.0
const JUMP_FORCE = -300.0

# =========================
# CONFIGURAÇÃO DO KNOCKBACK
# =========================

# Quanto menor, menos o personagem é empurrado
const ENEMY_KNOCKBACK_X = 100.0
const ENEMY_KNOCKBACK_Y = -40.0

const SPIKE_KNOCKBACK_Y = -35.0

# Limite máximo para evitar knockback exagerado
const MAX_KNOCKBACK_X = 110.0
const MAX_KNOCKBACK_Y = 50.0

var knockback_vector := Vector2.ZERO

var taking_damage := false
var can_take_damage := true
var can_move := true

@onready var animation = $Anim as AnimatedSprite2D
@onready var remote_transform = $remote as RemoteTransform2D
@onready var level = get_tree().current_scene.get_node("level")


func _ready():
	add_to_group("player")
	Globals.player_life = 3

	print("PLAYER INICIADO")
	print("TileMap encontrado: ", level)


func _physics_process(delta: float) -> void:

	# =========================
	# GRAVIDADE
	# =========================

	if not is_on_floor():
		velocity += get_gravity() * delta


	# =========================
	# KNOCKBACK
	# =========================

	velocity += knockback_vector


	# =========================
	# PULO
	# =========================

	if (
		Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_SPACE)
		or Input.is_key_pressed(KEY_UP)
	) and is_on_floor() and can_move:

		velocity.y = JUMP_FORCE


	# =========================
	# MOVIMENTO
	# =========================

	var direction = 0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction = -1

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction = 1


	# =========================
	# ANDAR
	# =========================

	if direction != 0 and can_move:

		velocity.x = direction * SPEED

		animation.flip_h = direction < 0

	elif can_move:

		velocity.x = move_toward(
			velocity.x,
			0,
			SPEED
		)


	# =========================
	# ANIMAÇÕES
	# =========================

	if not is_on_floor():

		animation.play("jump")

	elif direction != 0:

		animation.play("run")

	else:

		animation.play("idle")


	# =========================
	# ÚLTIMA VIDA PISCANDO
	# =========================

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


	move_and_slide()


	# =========================
	# VERIFICA ESPINHOS
	# =========================

	check_damage_tile()


func _on_hurtbox_body_entered(body: Node2D) -> void:

	# =========================
	# DANO DOS INIMIGOS
	# =========================

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


func check_damage_tile() -> void:

	# Se está invencível, não verifica
	if not can_take_damage:
		return

	if level == null:
		print("ERRO: TileMap 'level' não encontrado!")
		return


	# =========================
	# POSIÇÃO DOS PÉS
	# =========================

	var feet_position = global_position + Vector2(0, 12)


	# Vários pontos ao redor dos pés
	var positions = [
		feet_position,
		feet_position + Vector2(-8, 0),
		feet_position + Vector2(8, 0),
		feet_position + Vector2(0, 8),
		feet_position + Vector2(0, 16)
	]


	# =========================
	# VERIFICA TODAS AS CAMADAS
	# =========================

	for layer_index in range(level.get_layers_count()):

		for world_position in positions:

			var local_position = level.to_local(world_position)

			var tile_position = level.local_to_map(local_position)

			var tile_data = level.get_cell_tile_data(
				layer_index,
				tile_position
			)

			if tile_data == null:
				continue

			var damage = tile_data.get_custom_data("damage")

			if damage == true:

				print("================================")
				print("ESPINHO DETECTADO!")
				print("Camada: ", layer_index)
				print("Tile: ", tile_position)
				print("Damage: ", damage)
				print("================================")


				# =========================
				# KNOCKBACK PEQUENO DOS ESPINHOS
				# =========================

				take_damage(
					Vector2(
						0,
						SPIKE_KNOCKBACK_Y
					)
				)

				return


func take_damage(
	knockback_force := Vector2.ZERO,
	duration := 0.25
):

	# =========================
	# EVITA VÁRIOS DANOS SEGUIDOS
	# =========================

	if not can_take_damage:
		return

	can_take_damage = false
	can_move = false
	taking_damage = true


	# =========================
	# PERDE UMA VIDA
	# =========================

	if Globals.player_life > 0:

		Globals.player_life -= 1

		print("VIDA: ", Globals.player_life)

	else:

		die()
		return


	# =========================
	# MORREU
	# =========================

	if Globals.player_life <= 0:

		die()
		return


	# =========================
	# FICA VERMELHO
	# =========================

	animation.modulate = Color(
		1,
		0,
		0,
		1
	)


	# =========================
	# KNOCKBACK
	# =========================

	if knockback_force != Vector2.ZERO:

		# Limita o knockback máximo
		knockback_force.x = clamp(
			knockback_force.x,
			-MAX_KNOCKBACK_X,
			MAX_KNOCKBACK_X
		)

		knockback_force.y = clamp(
			knockback_force.y,
			-MAX_KNOCKBACK_Y,
			MAX_KNOCKBACK_Y
		)

		knockback_vector = knockback_force


		# Suaviza o knockback até chegar a zero
		var knockback_tween := get_tree().create_tween()

		knockback_tween.tween_property(
			self,
			"knockback_vector",
			Vector2.ZERO,
			duration
		)


	# =========================
	# PEQUENO STUN
	# =========================

	await get_tree().create_timer(0.08).timeout

	can_move = true


	# =========================
	# INVENCIBILIDADE
	# =========================

	await get_tree().create_timer(0.4).timeout

	can_take_damage = true
	taking_damage = false


	# =========================
	# VOLTA AO NORMAL
	# =========================

	animation.modulate = Color(
		1,
		1,
		1,
		1
	)


func die():

	can_move = false
	can_take_damage = false
	taking_damage = true

	velocity = Vector2.ZERO


	# =========================
	# RESETA OS DADOS DA PARTIDA
	# =========================

	Globals.coins = 0
	Globals.score = 0
	Globals.level_coins = 0
	Globals.level_score = 0


	animation.play("hurt")


	# Espera só 0.3 segundos antes de reiniciar
	await get_tree().create_timer(0.3).timeout

	get_tree().reload_current_scene()


func follow_camera(camera):

	var camera_path = camera.get_path()

	remote_transform.remote_path = camera_path
