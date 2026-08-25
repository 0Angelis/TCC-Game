extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

var direction: int = -1

const SPEED: float = 30.0


# ==========================================
# CONTATO REAL
# ==========================================

# Bem menor para não dar dano de longe.
const CONTACT_DISTANCE_X: float = 18.0
const CONTACT_DISTANCE_Y: float = 18.0


# ==========================================
# PISÃO
# ==========================================

const STOMP_DISTANCE_X: float = 24.0
const STOMP_DISTANCE_Y: float = 18.0


# ==========================================
# DANO
# ==========================================

const DAMAGE_COOLDOWN: float = 0.7

const KNOCKBACK_X: float = 45.0
const KNOCKBACK_Y: float = -25.0

var damage_cooldown: float = 0.0
var stomp_cooldown: float = 0.0


# ==========================================
# ESTADO
# ==========================================

var is_dead: bool = false


# ==========================================
# PLAYER
# ==========================================

var player: Node2D = null


# ==========================================
# NÓS
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $collision
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var hitbox: Area2D = $Area2D


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
	# PLAYER
	# ==========================================

	encontrar_player()


	# ==========================================
	# HITBOX
	# ==========================================

	hitbox.monitoring = true
	hitbox.monitorable = true


	# ==========================================
	# ANIMAÇÃO
	# ==========================================

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("idle"):

			animated_sprite.play("idle")


# ==========================================
# FÍSICA
# ==========================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	# ==========================================
	# COOLDOWN
	# ==========================================

	if damage_cooldown > 0.0:

		damage_cooldown -= delta


	if stomp_cooldown > 0.0:

		stomp_cooldown -= delta


	# ==========================================
	# GRAVIDADE
	# ==========================================

	if not is_on_floor():

		velocity += get_gravity() * delta


	# ==========================================
	# PLAYER
	# ==========================================

	if player == null or not is_instance_valid(player):

		encontrar_player()


	# ==========================================
	# INTERAÇÃO
	# ==========================================

	if player != null:

		verificar_contato()


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
	# PAREDE
	# ==========================================

	for i in get_slide_collision_count():

		var slide_collision: KinematicCollision2D = (
			get_slide_collision(i)
		)

		var normal: Vector2 = (
			slide_collision.get_normal()
		)


		if abs(normal.x) > 0.5:

			virar()

			break


	# ==========================================
	# ANIMAÇÃO
	# ==========================================

	if not is_dead:

		if animated_sprite.sprite_frames != null:

			if animated_sprite.sprite_frames.has_animation("idle"):

				if animated_sprite.animation != "idle":

					animated_sprite.play("idle")


# ==========================================
# ENCONTRAR PLAYER
# ==========================================

func encontrar_player() -> void:

	var players: Array[Node] = (
		get_tree().get_nodes_in_group("player")
	)


	if players.size() > 0:

		player = players[0] as Node2D


# ==========================================
# VERIFICAR CONTATO
# ==========================================

func verificar_contato() -> void:

	if is_dead:
		return


	if player == null:
		return


	if not is_instance_valid(player):
		return


	# ==========================================
	# DISTÂNCIA
	# ==========================================

	var distancia_x: float = abs(
		player.global_position.x
		- global_position.x
	)


	var distancia_y: float = abs(
		player.global_position.y
		- global_position.y
	)


	# ==========================================
	# PLAYER ESTÁ ACIMA
	# ==========================================

	var player_acima: bool = (
		player.global_position.y
		< global_position.y
	)


	# ==========================================
	# PLAYER ESTÁ CAINDO
	# ==========================================

	var player_caindo: bool = false


	if player is CharacterBody2D:

		var player_body: CharacterBody2D = (
			player as CharacterBody2D
		)

		player_caindo = player_body.velocity.y > 0.0


	# ==========================================
	# PISÃO
	# ==========================================

	if (
		player_acima
		and player_caindo
		and distancia_x <= STOMP_DISTANCE_X
		and distancia_y <= STOMP_DISTANCE_Y
	):

		if stomp_cooldown <= 0.0:

			pisar_no_fantasma()

		return


	# ==========================================
	# CONTATO LATERAL
	# ==========================================

	if (
		not player_acima
		and distancia_x <= CONTACT_DISTANCE_X
		and distancia_y <= CONTACT_DISTANCE_Y
	):

		dar_dano()


# ==========================================
# PISÃO
# ==========================================

func pisar_no_fantasma() -> void:

	if is_dead:
		return


	stomp_cooldown = 0.5


	print("==============================")
	print("PLAYER PISOU NO FANTASMA!")
	print("FANTASMA DERROTADO!")
	print("==============================")


	# ==========================================
	# REBOTE
	# ==========================================

	if player is CharacterBody2D:

		var player_body: CharacterBody2D = (
			player as CharacterBody2D
		)

		player_body.velocity.y = -180.0


	matar_fantasma()


# ==========================================
# DAR DANO
# ==========================================

func dar_dano() -> void:

	if is_dead:
		return


	if player == null:
		return


	if not is_instance_valid(player):
		return


	if damage_cooldown > 0.0:
		return


	if not player.has_method(
		"receber_dano_inimigo"
	):

		print(
			"ERRO: Player não possui receber_dano_inimigo()"
		)

		return


	# ==========================================
	# DIREÇÃO
	# ==========================================

	var knockback_direction: float = 1.0


	if player.global_position.x < global_position.x:

		knockback_direction = -1.0


	print("==============================")
	print("FANTASMA ENCOSTOU!")
	print("DANO!")
	print("==============================")


	# ==========================================
	# DANO
	# ==========================================

	player.receber_dano_inimigo(
		Vector2(
			knockback_direction * KNOCKBACK_X,
			KNOCKBACK_Y
		)
	)


	damage_cooldown = DAMAGE_COOLDOWN


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

	# O sistema de dano usa a detecção
	# de distância acima.

	return


# ==========================================
# RECEBER DANO
# ==========================================

func hurt() -> void:

	take_damage()


func take_damage() -> void:

	if is_dead:
		return

	return


# ==========================================
# MORTE
# ==========================================

func matar_fantasma() -> void:

	if is_dead:
		return


	is_dead = true


	# ==========================================
	# SCORE
	# ==========================================

	Globals.score += 50


	print("FANTASMA DERROTADO!")
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


	# ==========================================
	# DESATIVAR RAYCAST
	# ==========================================

	ray_cast.enabled = false


	# ==========================================
	# MORTE
	# ==========================================

	animated_sprite.visible = true


	var start_rotation: float = (
		animated_sprite.rotation_degrees
	)


	var death_rotation: float = 90.0


	if direction > 0:

		death_rotation = -90.0


	var tween: Tween = create_tween()

	tween.set_parallel(true)


	tween.tween_property(
		animated_sprite,
		"rotation_degrees",
		start_rotation + death_rotation,
		0.45
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	tween.tween_property(
		animated_sprite,
		"position:y",
		animated_sprite.position.y + 18.0,
		0.45
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	tween.tween_property(
		animated_sprite,
		"scale",
		Vector2(
			0.92,
			0.92
		),
		0.45
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	tween.tween_property(
		animated_sprite,
		"modulate:a",
		0.0,
		0.45
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


	await tween.finished


	queue_free()


# ==========================================
# MORTE DIRETA
# ==========================================

func die() -> void:

	matar_fantasma()
