extends CharacterBody2D


# ============================================================
# BOSS FINAL - GUARDIAO COGNITIVO
# ============================================================

signal boss_attack_started
signal boss_hit_player
signal boss_health_changed(current: int, maximum: int)
signal boss_defeated


# ============================================================
# SPRITE
# ============================================================

const SPRITE_FACES_RIGHT: bool = false


# ============================================================
# MOVIMENTO
# ============================================================

const WALK_SPEED: float = 40.0
const CHASE_SPEED: float = 72.0
const RAGE_SPEED: float = 104.0

const ACCELERATION: float = 260.0
const RAGE_ACCELERATION: float = 360.0
const DECELERATION: float = 320.0

const DETECTION_DISTANCE: float = 900.0
const STOP_DISTANCE: float = 30.0


# ============================================================
# SURTO
# ============================================================

const RAGE_INTERVAL: float = 10.0
const RAGE_DURATION: float = 3.0

var rage_timer: float = RAGE_INTERVAL
var rage_time_left: float = 0.0
var enraged: bool = false


# ============================================================
# DASH
# ============================================================

const ATTACK_TRIGGER_DISTANCE: float = 62.0
const ATTACK_START_DISTANCE: float = 68.0

const ATTACK_VERTICAL_DISTANCE: float = 38.0

const ATTACK_PREPARE_TIME: float = 0.22
const ATTACK_DASH_TIME: float = 0.30
const ATTACK_DASH_SPEED: float = 172.0

const ATTACK_RECOVERY_TIME: float = 0.32
const ATTACK_COOLDOWN: float = 1.60

# Delay antes do boss voltar a andar/atacar.
# Usado ao iniciar a batalha e depois de cada desafio.
const BATTLE_START_DELAY: float = 0.8


# ============================================================
# CONTATO DO DASH
# ============================================================

const DASH_CONTACT_HORIZONTAL: float = 27.0
const DASH_CONTACT_VERTICAL: float = 28.0


var attack_cooldown: float = 0.0
var attack_prepare_timer: float = 0.30
var attack_dash_timer: float = 0.50
var attack_recovery_timer: float = 0.0

var is_attacking: bool = false
var attack_hit_done: bool = false
var attack_direction: int = 1

# Delay curto antes de voltar a agir.
var battle_start_delay_timer: float = 0.0
var battle_start_delay_active: bool = false
var damage_enabled_before_battle_delay: bool = false


# ============================================================
# DANO
# ============================================================

const DAMAGE_COOLDOWN: float = 0.70

const KNOCKBACK_X: float = 115.0
const KNOCKBACK_Y: float = -50.0

var damage_cooldown: float = 0.0


# ============================================================
# PULO
# ============================================================

const JUMP_FORCE: float = -330.0
const JUMP_HORIZONTAL_SPEED: float = 100.0

var jump_cooldown: float = 0.0
const JUMP_COOLDOWN: float = 0.55

const PLAYER_ABOVE_HEIGHT: float = 42.0
const PLAYER_ABOVE_DISTANCE: float = 420.0


# ============================================================
# DETECCAO DE OBSTACULO
# ============================================================

const OBSTACLE_DISTANCE: float = 70.0

const OBSTACLE_LOW_Y: float = -4.0
const OBSTACLE_MIDDLE_Y: float = -16.0
const OBSTACLE_HIGH_Y: float = -28.0
const OBSTACLE_VERY_HIGH_Y: float = -40.0


# ============================================================
# PISAO / CABECA
# ============================================================

@export var stomp_damage: int = 20

const STOMP_COOLDOWN: float = 0.75
const STOMP_HORIZONTAL_DISTANCE: float = 27.0

const STOMP_HEAD_Y: float = 34.0

var stomp_cooldown: float = 0.0

var previous_player_y: float = 0.0
var previous_player_y_valid: bool = false


# ============================================================
# VIRADA
# ============================================================

const TURN_COOLDOWN: float = 0.10

var turn_cooldown: float = 0.0
var direction: int = -1


# ============================================================
# VIDA
# ============================================================

@export var max_health: int = 100

var current_health: int = 100


# ============================================================
# ESTADOS
# ============================================================

var is_dead: bool = false
var is_hurt: bool = false
var healing_feedback: bool = false

var can_move: bool = true
var battle_controlled: bool = false

# Quando o boss precisa ser congelado enquanto ainda está no ar,
# ele termina a queda antes de ficar parado.
var waiting_for_landing_lock: bool = false

var attack_enabled: bool = false
var damage_enabled: bool = false
var stomp_enabled: bool = false


# ============================================================
# HURT
# ============================================================

const HURT_DURATION: float = 0.18

var hurt_time_left: float = 0.0


# ============================================================
# FLASH
# ============================================================

const FLASH_DURATION: float = 0.08

var flash_time_left: float = 0.0


# ============================================================
# PLAYER
# ============================================================

var player: CharacterBody2D = null


# ============================================================
# NODES
# ============================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var collision: CollisionShape2D = $collision

@onready var ray_cast: RayCast2D = $RayCast2D

@onready var hitbox_area: Area2D = $Area2D

@onready var hitbox: CollisionShape2D = $Area2D/hitbox


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	add_to_group("enemies")
	add_to_group("boss")

	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED

	up_direction = Vector2.UP

	floor_snap_length = 6.0

	current_health = max_health

	direction = -1

	_reset_all_timers()
	_reset_attack_state()

	_set_facing(direction)

	_find_player()


	# ========================================================
	# RAYCAST
	# ========================================================

	if ray_cast != null:

		ray_cast.enabled = true

		_update_ray_cast()


	# ========================================================
	# HITBOX
	# ========================================================

	if hitbox_area != null:

		hitbox_area.monitoring = true
		hitbox_area.monitorable = true


	if hitbox != null:

		hitbox.disabled = false


	# ========================================================
	# SIGNAL
	# ========================================================

	if (
		hitbox_area != null
		and
		not hitbox_area.body_entered.is_connected(
			_on_hitbox_body_entered
		)
	):

		hitbox_area.body_entered.connect(
			_on_hitbox_body_entered
		)


	_play_animation("olhando")


	print("================================")
	print("GUARDIAO COGNITIVO")
	print("BOSS PRONTO")
	print("VIDA: ", current_health, "/", max_health)
	print("================================")


# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta: float) -> void:

	if is_dead:

		return


	_update_timers(delta)

	_update_rage(delta)

	_update_flash(delta)


	# ========================================================
	# GRAVIDADE
	# ========================================================

	if not is_on_floor():

		velocity += get_gravity() * delta

	elif velocity.y > 0.0:

		velocity.y = 0.0


	# ========================================================
	# TERMINAR QUEDA ANTES DE CONGELAR
	# ========================================================

	if waiting_for_landing_lock:

		# O boss precisa continuar com a física ATIVA
		# mesmo estando com can_move = false.
		# Assim a gravidade continua funcionando e ele
		# não fica preso no ar quando o desafio aparece.
		can_move = false

		velocity.x = 0.0

		if not is_on_floor():
			velocity += get_gravity() * delta

		move_and_slide()

		if is_on_floor():

			waiting_for_landing_lock = false
			can_move = false
			velocity = Vector2.ZERO

			_reset_attack_state()

			_play_animation("olhando")

		else:

			_update_air_animation()

		return


	# ========================================================
	# DELAY ANTES DE VOLTAR A ANDAR/ATACAR
	# ========================================================

	if battle_start_delay_active:

		battle_start_delay_timer -= delta

		can_move = false
		velocity.x = 0.0

		# Durante o delay o boss continua sujeito à gravidade.
		move_and_slide()

		if is_on_floor():

			velocity.x = 0.0
			velocity.y = 0.0
			_play_animation("olhando")


		if battle_start_delay_timer <= 0.0:

			battle_start_delay_timer = 0.0
			battle_start_delay_active = false
			can_move = true

			# Só devolve o dano quando o delay acabou.
			damage_enabled = damage_enabled_before_battle_delay

			_find_player()

		return


	# ========================================================
	# PLAYER
	# ========================================================

	if not is_instance_valid(player):

		_find_player()


	# ========================================================
	# PISAO
	# ========================================================

	if is_instance_valid(player):

		_check_stomp()


	# ========================================================
	# HURT
	# ========================================================

	if is_hurt:

		_process_hurt(delta)

		return


	# ========================================================
	# FREEZE
	# ========================================================

	if not can_move:

		_process_frozen()

		return


	# ========================================================
	# PREPARANDO DASH
	# ========================================================

	if attack_prepare_timer > 0.0:

		_process_attack_prepare(delta)

		return


	# ========================================================
	# DASH
	# ========================================================

	if is_attacking:

		_process_attack_dash(delta)

		return


	# ========================================================
	# RECUPERACAO
	# ========================================================

	if attack_recovery_timer > 0.0:

		_process_attack_recovery(delta)

		return


	# ========================================================
	# SEM PLAYER
	# ========================================================

	if not is_instance_valid(player):

		_process_idle(delta)

		return


	# ========================================================
	# NO AR
	# ========================================================

	if not is_on_floor():

		_process_air_follow(delta)

		return


	# ========================================================
	# PERSEGUIR
	# ========================================================

	_process_follow_player(delta)


# ============================================================
# TIMERS
# ============================================================

func _update_timers(delta: float) -> void:

	if attack_cooldown > 0.0:

		attack_cooldown -= delta


	if damage_cooldown > 0.0:

		damage_cooldown -= delta


	if jump_cooldown > 0.0:

		jump_cooldown -= delta


	if turn_cooldown > 0.0:

		turn_cooldown -= delta


	if stomp_cooldown > 0.0:

		stomp_cooldown -= delta


	if hurt_time_left > 0.0:

		hurt_time_left -= delta


# ============================================================
# SURTO
# ============================================================

func _update_rage(delta: float) -> void:

	if enraged:

		rage_time_left -= delta


		if rage_time_left <= 0.0:

			enraged = false

			rage_time_left = 0.0

			rage_timer = RAGE_INTERVAL


		return


	rage_timer -= delta


	if rage_timer <= 0.0:

		enraged = true

		rage_time_left = RAGE_DURATION

		rage_timer = RAGE_INTERVAL

		print("BOSS: SURTO!")


# ============================================================
# FLASH
# ============================================================

func _update_flash(delta: float) -> void:

	if animated_sprite == null:

		return


	if flash_time_left > 0.0:

		if healing_feedback:

			animated_sprite.modulate = Color(
				0.65,
				1.0,
				0.65,
				1.0
			)

		else:

			animated_sprite.modulate = Color(
				1.0,
				0.65,
				0.65,
				1.0
			)


		flash_time_left -= delta


	else:

		if not is_hurt:

			animated_sprite.modulate = Color.WHITE


# ============================================================
# PLAYER
# ============================================================

func _find_player() -> void:

	if not is_inside_tree():

		return


	var players: Array[Node] = (
		get_tree().get_nodes_in_group("player")
	)


	for candidate: Node in players:

		if candidate is CharacterBody2D:

			player = candidate as CharacterBody2D

			if not previous_player_y_valid:

				previous_player_y = player.global_position.y

				previous_player_y_valid = true

			return


	player = null


# ============================================================
# PERSEGUICAO
# ============================================================

func _process_follow_player(
	delta: float
) -> void:

	if not is_instance_valid(player):

		return


	var difference_x: float = (
		player.global_position.x
		-
		global_position.x
	)


	var difference_y: float = (
		player.global_position.y
		-
		global_position.y
	)


	var distance_x: float = abs(
		difference_x
	)


	var distance_y: float = abs(
		difference_y
	)


	# ========================================================
	# DIRECAO
	# ========================================================

	var target_direction: int = 1


	if difference_x < 0.0:

		target_direction = -1


	if (
		target_direction != direction
		and
		turn_cooldown <= 0.0
	):

		direction = target_direction

		_set_facing(direction)

		turn_cooldown = TURN_COOLDOWN

		_update_ray_cast()


	# ========================================================
	# ATAQUE
	# ========================================================

	if (
		attack_enabled
		and
		attack_cooldown <= 0.0
		and
		not is_attacking
		and
		attack_prepare_timer <= 0.0
		and
		distance_x <= ATTACK_TRIGGER_DISTANCE
		and
		distance_y <= ATTACK_VERTICAL_DISTANCE
	):

		_start_attack()

		return


	# ========================================================
	# PULO: PAREDE / OBSTACULO
	# ========================================================

	if (
		is_on_floor()
		and
		jump_cooldown <= 0.0
		and
		(
			is_on_wall()
			or
			_is_obstacle_ahead()
		)
	):

		_start_jump()

		return


	# ========================================================
	# PULO PARA ALCANCAR O PLAYER
	# ========================================================

	var player_above: bool = (
		player.global_position.y
		<
		global_position.y - PLAYER_ABOVE_HEIGHT
	)


	var player_far: bool = (
		distance_x > 110.0
	)


	var height_difference: bool = (
		distance_y > 55.0
	)


	if (
		is_on_floor()
		and
		jump_cooldown <= 0.0
		and
		distance_x <= PLAYER_ABOVE_DISTANCE
		and
		(
			player_above
			or
			(
				player_far
				and
				height_difference
			)
		)
	):

		_start_jump()

		return


	# ========================================================
	# MUITO PERTO
	# ========================================================

	if distance_x <= STOP_DISTANCE:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			DECELERATION * delta
		)

		_face_player()

		_play_animation("olhando")

		move_and_slide()

		return


	# ========================================================
	# VELOCIDADE
	# ========================================================

	var speed: float = (
		RAGE_SPEED
		if enraged
		else CHASE_SPEED
	)


	var acceleration: float = (
		RAGE_ACCELERATION
		if enraged
		else ACCELERATION
	)


	velocity.x = move_toward(
		velocity.x,
		direction * speed,
		acceleration * delta
	)


	move_and_slide()


	# ========================================================
	# SE BATEU NA PAREDE
	# ========================================================

	if (
		is_on_wall()
		and
		is_on_floor()
		and
		jump_cooldown <= 0.0
	):

		_start_jump()

		return


	_update_ground_animation()


# ============================================================
# DETECTAR OBSTACULO
# ============================================================

func _is_obstacle_ahead() -> bool:

	if not is_inside_tree():

		return false


	var space_state: PhysicsDirectSpaceState2D = (
		get_world_2d().direct_space_state
	)


	var heights: Array[float] = [
		OBSTACLE_LOW_Y,
		OBSTACLE_MIDDLE_Y,
		OBSTACLE_HIGH_Y,
		OBSTACLE_VERY_HIGH_Y
	]


	for height: float in heights:

		var start: Vector2 = Vector2(
			global_position.x
			+
			float(direction) * 5.0,
			global_position.y
			+
			height
		)


		var finish: Vector2 = Vector2(
			global_position.x
			+
			float(direction)
			*
			OBSTACLE_DISTANCE,
			global_position.y
			+
			height
		)


		var query: PhysicsRayQueryParameters2D = (
			PhysicsRayQueryParameters2D.create(
				start,
				finish
			)
		)


		# Enxerga qualquer collision layer.
		query.collision_mask = 0xFFFFFFFF

		query.collide_with_bodies = true

		query.collide_with_areas = false


		var excluded: Array[RID] = [
			get_rid()
		]


		if is_instance_valid(player):

			excluded.append(
				player.get_rid()
			)


		query.exclude = excluded


		var result: Dictionary = (
			space_state.intersect_ray(query)
		)


		if result.is_empty():

			continue


		var collider: Object = (
			result.get("collider")
		)


		if collider == null:

			continue


		if collider == player:

			continue


		return true


	return false


# ============================================================
# PULO
# ============================================================

func _start_jump() -> void:

	if not is_on_floor():

		return


	if jump_cooldown > 0.0:

		return


	if is_hurt:

		return


	if is_attacking:

		return


	jump_cooldown = JUMP_COOLDOWN


	var jump_direction: float = (
		float(direction)
	)


	# Se o player existir, pula em direção a ele.
	# Se não existir, pula na direção atual.
	if is_instance_valid(player):

		if player.global_position.x < global_position.x:

			jump_direction = -1.0

		elif player.global_position.x > global_position.x:

			jump_direction = 1.0


	_set_facing(
		int(jump_direction)
	)


	# ========================================================
	# IMPULSO VERTICAL
	# ========================================================

	velocity.y = JUMP_FORCE


	# ========================================================
	# IMPULSO HORIZONTAL
	# ========================================================

	var horizontal_speed: float = (
		JUMP_HORIZONTAL_SPEED
	)


	if enraged:

		horizontal_speed = 180.0


	velocity.x = (
		jump_direction
		*
		horizontal_speed
	)


	_play_animation("pular")


	print(
		"BOSS: PULO! velocity=",
		velocity
	)


	# ========================================================
	# IMPORTANTE
	#
	# O movimento é aplicado IMEDIATAMENTE.
	# ========================================================

	move_and_slide()


# ============================================================
# MOVIMENTO NO AR
# ============================================================

func _process_air_follow(
	delta: float
) -> void:

	if not is_instance_valid(player):

		move_and_slide()

		_update_air_animation()

		return


	var difference_x: float = (
		player.global_position.x
		-
		global_position.x
	)


	var air_direction: float = 0.0


	if difference_x > 8.0:

		air_direction = 1.0

	elif difference_x < -8.0:

		air_direction = -1.0


	if air_direction != 0.0:

		var air_speed: float = (
			RAGE_SPEED
			if enraged
			else JUMP_HORIZONTAL_SPEED
		)


		velocity.x = move_toward(
			velocity.x,
			air_direction * air_speed,
			ACCELERATION * delta
		)


		_set_facing(
			int(air_direction)
		)


	move_and_slide()


	_update_air_animation()


# ============================================================
# IDLE
# ============================================================

func _process_idle(
	delta: float
) -> void:

	velocity.x = move_toward(
		velocity.x,
		0.0,
		DECELERATION * delta
	)


	move_and_slide()


	_play_animation("olhando")


# ============================================================
# FREEZE
# ============================================================

func _process_frozen() -> void:

	velocity = Vector2.ZERO

	_reset_attack_state()

	_play_animation("olhando")


# ============================================================
# INICIAR ATAQUE
# ============================================================

func _start_attack() -> void:

	if not attack_enabled:

		return


	if attack_cooldown > 0.0:

		return


	if is_attacking:

		return


	if not is_instance_valid(player):

		return


	_face_player()


	attack_direction = direction


	attack_prepare_timer = (
		ATTACK_PREPARE_TIME
	)


	attack_hit_done = false


	velocity.x = 0.0


	_play_animation("ataque")


# ============================================================
# PREPARACAO DO DASH
# ============================================================

func _process_attack_prepare(
	delta: float
) -> void:

	if not is_instance_valid(player):

		attack_prepare_timer = 0.0

		return


	var distance_x: float = abs(
		player.global_position.x
		-
		global_position.x
	)


	var distance_y: float = abs(
		player.global_position.y
		-
		global_position.y
	)


	if (
		distance_x
		>
		ATTACK_START_DISTANCE + 20.0
		or
		distance_y
		>
		ATTACK_VERTICAL_DISTANCE + 12.0
	):

		attack_prepare_timer = 0.0

		_play_animation("walking")

		return


	_face_player()


	velocity.x = 0.0


	attack_prepare_timer -= delta


	move_and_slide()


	if attack_prepare_timer <= 0.0:

		_begin_dash()


# ============================================================
# INICIAR DASH
# ============================================================

func _begin_dash() -> void:

	if not is_instance_valid(player):

		attack_prepare_timer = 0.0

		return


	var distance_x: float = abs(
		player.global_position.x
		-
		global_position.x
	)


	var distance_y: float = abs(
		player.global_position.y
		-
		global_position.y
	)


	if (
		distance_x
		>
		ATTACK_START_DISTANCE
		or
		distance_y
		>
		ATTACK_VERTICAL_DISTANCE + 5.0
	):

		attack_prepare_timer = 0.0

		return


	attack_prepare_timer = 0.0

	attack_dash_timer = (
		ATTACK_DASH_TIME
	)

	attack_cooldown = (
		ATTACK_COOLDOWN
	)

	attack_hit_done = false

	is_attacking = true


	velocity.x = (
		float(attack_direction)
		*
		ATTACK_DASH_SPEED
	)


	boss_attack_started.emit()


	print("BOSS: DASH!")


# ============================================================
# EXECUTAR DASH
# ============================================================

func _process_attack_dash(
	delta: float
) -> void:

	velocity.x = (
		float(attack_direction)
		*
		ATTACK_DASH_SPEED
	)


	move_and_slide()


	if (
		not attack_hit_done
		and
		_dash_touched_player()
	):

		_apply_dash_damage()


	attack_dash_timer -= delta


	if attack_dash_timer <= 0.0:

		is_attacking = false

		attack_dash_timer = 0.0

		attack_hit_done = false

		attack_recovery_timer = (
			ATTACK_RECOVERY_TIME
		)

		velocity.x = 0.0


# ============================================================
# CONTATO REAL DO DASH
# ============================================================

func _dash_touched_player() -> bool:

	if not is_instance_valid(player):

		return false


	var horizontal_distance: float = abs(
		player.global_position.x
		-
		global_position.x
	)


	var vertical_distance: float = abs(
		player.global_position.y
		-
		global_position.y
	)


	if (
		horizontal_distance
		>
		DASH_CONTACT_HORIZONTAL
	):

		return false


	if (
		vertical_distance
		>
		DASH_CONTACT_VERTICAL
	):

		return false


	var relative_x: float = (
		player.global_position.x
		-
		global_position.x
	)


	if attack_direction > 0:

		if relative_x < -3.0:

			return false

	else:

		if relative_x > 3.0:

			return false


	return true


# ============================================================
# DANO DO DASH
# ============================================================

func _apply_dash_damage() -> void:

	if not damage_enabled:

		return


	if is_dead:

		return


	if damage_cooldown > 0.0:

		return


	if not is_instance_valid(player):

		return


	if not player.has_method("take_damage"):

		return


	player.take_damage(
		Vector2(
			float(attack_direction)
			*
			KNOCKBACK_X,
			KNOCKBACK_Y
		)
	)


	boss_hit_player.emit()

	damage_cooldown = (
		DAMAGE_COOLDOWN
	)


	attack_hit_done = true


	print("BOSS: DASH ACERTOU!")


# ============================================================
# PISAO
# ============================================================

func _check_stomp() -> void:

	if not stomp_enabled:

		_update_previous_player_y()

		return


	if stomp_cooldown > 0.0:

		_update_previous_player_y()

		return


	if not is_instance_valid(player):

		_update_previous_player_y()

		return


	var current_y: float = (
		player.global_position.y
	)


	if not previous_player_y_valid:

		previous_player_y = current_y

		previous_player_y_valid = true

		return


	var player_velocity_y: float = (
		player.velocity.y
	)


	if player_velocity_y <= 15.0:

		previous_player_y = current_y

		return


	var horizontal_distance: float = abs(
		player.global_position.x
		-
		global_position.x
	)


	if (
		horizontal_distance
		>
		STOMP_HORIZONTAL_DISTANCE
	):

		previous_player_y = current_y

		return


	var head_y: float = (
		global_position.y
		-
		STOMP_HEAD_Y
	)


	var was_above: bool = (
		previous_player_y
		<
		head_y
	)


	var reached_head: bool = (
		current_y
		>=
		head_y
	)


	if not was_above or not reached_head:

		previous_player_y = current_y

		return


	if current_y > global_position.y + 5.0:

		previous_player_y = current_y

		return


	_apply_stomp_damage()


	previous_player_y = current_y


# ============================================================
# SALVAR Y DO PLAYER
# ============================================================

func _update_previous_player_y() -> void:

	if not is_instance_valid(player):

		return


	previous_player_y = (
		player.global_position.y
	)

	previous_player_y_valid = true


# ============================================================
# APLICAR PISAO
# ============================================================

func _apply_stomp_damage() -> void:

	if not is_instance_valid(player):

		return


	if not damage_enabled:

		return


	if not stomp_enabled:

		return


	if stomp_cooldown > 0.0:

		return


	stomp_cooldown = (
		STOMP_COOLDOWN
	)


	take_boss_damage(
		stomp_damage
	)


	player.velocity.y = -260.0


	print(
		"BOSS: PISAO RECEBIDO!"
	)


# ============================================================
# DANO POR CONTATO
# ============================================================

func _apply_contact_damage() -> void:

	if not damage_enabled:

		return


	if is_dead:

		return


	if damage_cooldown > 0.0:

		return


	if not is_instance_valid(player):

		return


	if not player.has_method("take_damage"):

		return


	# Dano imediato ao encostar no boss.
	# Não depende da animação de ataque.
	player.take_damage(
		Vector2(
			float(direction)
			*
			KNOCKBACK_X,
			KNOCKBACK_Y
		)
	)


	boss_hit_player.emit()

	damage_cooldown = DAMAGE_COOLDOWN


	print("BOSS: DANO POR CONTATO!")


# ============================================================
# HITBOX CALLBACK
# ============================================================

func _on_hitbox_body_entered(
	body: Node2D
) -> void:

	if is_dead:

		return


	if not damage_enabled:

		return


	if not is_instance_valid(player):

		return


	# Só o player pode receber dano aqui.
	if body != player:

		return


	# Encostou no boss = dano imediato.
	_apply_contact_damage()


# ============================================================
# RECUPERACAO
# ============================================================

func _process_attack_recovery(
	delta: float
) -> void:

	velocity.x = move_toward(
		velocity.x,
		0.0,
		DECELERATION * delta
	)


	attack_recovery_timer -= delta


	move_and_slide()


	if attack_recovery_timer <= 0.0:

		attack_recovery_timer = 0.0

		_play_animation(
			"walking"
		)


# ============================================================
# HURT
# ============================================================

func _start_hurt() -> void:

	if is_dead:

		return


	healing_feedback = false
	is_hurt = true

	hurt_time_left = (
		HURT_DURATION
	)


	_reset_attack_state()


	velocity.x = 0.0


	_play_animation(
		"hurt"
	)


	flash_time_left = (
		FLASH_DURATION
	)


func _process_hurt(
	delta: float
) -> void:

	velocity.x = move_toward(
		velocity.x,
		0.0,
		DECELERATION * delta
	)


	move_and_slide()


	if hurt_time_left <= 0.0:

		is_hurt = false
		healing_feedback = false

		flash_time_left = 0.0

		if animated_sprite != null:

			animated_sprite.modulate = Color.WHITE


		_update_ground_animation()


# ============================================================
# ANIMACAO
# ============================================================

func _update_ground_animation() -> void:

	if is_dead:

		return


	if is_hurt:

		return


	if is_attacking:

		return


	if not is_on_floor():

		_play_animation(
			"pular"
		)

		return


	if abs(velocity.x) > 4.0:

		_play_animation(
			"walking"
		)

	else:

		_play_animation(
			"olhando"
		)


func _update_air_animation() -> void:

	if is_dead:

		return


	if is_hurt:

		return


	if is_attacking:

		return


	if not is_on_floor():

		_play_animation(
			"pular"
		)


func _play_animation(
	animation_name: String
) -> void:

	if animated_sprite == null:

		return


	if animated_sprite.sprite_frames == null:

		return


	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):

		return


	if animated_sprite.animation == animation_name:

		if not animated_sprite.is_playing():

			animated_sprite.play(
				animation_name
			)

		return


	animated_sprite.play(
		animation_name
	)


# ============================================================
# FACING
# ============================================================

func _set_facing(
	new_direction: int
) -> void:

	direction = (
		-1
		if new_direction < 0
		else 1
	)


	if animated_sprite == null:

		return


	if SPRITE_FACES_RIGHT:

		animated_sprite.flip_h = (
			direction < 0
		)

	else:

		animated_sprite.flip_h = (
			direction > 0
		)


func _face_player() -> void:

	if not is_instance_valid(player):

		return


	if (
		player.global_position.x
		<
		global_position.x
	):

		_set_facing(
			-1
		)

	else:

		_set_facing(
			1
		)


	_update_ray_cast()


func _update_ray_cast() -> void:

	if ray_cast == null:

		return


	ray_cast.target_position = Vector2(
		float(direction) * 24.0,
		18.0
	)


	ray_cast.force_raycast_update()


# ============================================================
# CONTROLE DA BATALHA
# ============================================================

func set_attack_enabled(
	enabled: bool
) -> void:

	attack_enabled = enabled


	if not enabled:

		_reset_attack_state()


func set_damage_enabled(
	enabled: bool
) -> void:

	damage_enabled = enabled


	if hitbox_area != null:

		hitbox_area.monitoring = true

		hitbox_area.monitorable = true


func set_stomp_enabled(
	enabled: bool
) -> void:

	stomp_enabled = enabled


# ============================================================
# FREEZE
# ============================================================

func freeze_boss() -> void:

	waiting_for_landing_lock = false

	battle_start_delay_active = false
	battle_start_delay_timer = 0.0

	can_move = false

	velocity = Vector2.ZERO

	_reset_attack_state()

	_play_animation(
		"olhando"
	)


func freeze_boss_after_landing() -> void:

	if is_dead:
		return

	_reset_attack_state()

	# Garante que a física continue ativa enquanto
	# o boss termina uma queda.
	set_physics_process(true)

	# Se já está no chão, congela imediatamente.
	if is_on_floor():

		waiting_for_landing_lock = false

		can_move = false

		velocity = Vector2.ZERO

		_play_animation(
			"olhando"
		)

		return

	# Se está no ar, deixa a gravidade terminar
	# a queda antes de congelar.
	waiting_for_landing_lock = true

	can_move = false

	velocity.x = 0.0

	_play_animation(
		"pular"
	)


func unfreeze_boss() -> void:

	if is_dead:

		return


	waiting_for_landing_lock = false

	# ========================================================
	# DELAY DE 0.8s AO INICIAR/RETOMAR A BATALHA
	# ========================================================
	# O boss fica parado por um instante antes de voltar
	# a perseguir/atacar. Durante esse tempo ele também
	# não consegue causar dano por contato.

	battle_start_delay_timer = BATTLE_START_DELAY
	battle_start_delay_active = true

	damage_enabled_before_battle_delay = damage_enabled
	damage_enabled = false

	can_move = false
	velocity.x = 0.0

	_reset_attack_state()

	battle_controlled = false

	call_deferred(
		"_find_player"
	)


func continuar_boss() -> void:

	unfreeze_boss()


func parar_boss() -> void:

	freeze_boss()


func ativar_controle_da_batalha() -> void:

	waiting_for_landing_lock = false

	battle_controlled = true

	can_move = true

	_find_player()


func liberar_controle_da_batalha() -> void:

	if is_dead:

		return


	waiting_for_landing_lock = false

	battle_controlled = false

	can_move = true

	_find_player()


# ============================================================
# VIDA
# ============================================================

func take_boss_damage(
	amount: int = 1
) -> void:

	if is_dead:

		return


	if amount <= 0:

		return


	current_health = max(
		current_health - amount,
		0
	)


	boss_health_changed.emit(
		current_health,
		max_health
	)


	print(
		"BOSS TOMOU DANO: ",
		amount,
		" | VIDA: ",
		current_health,
		"/",
		max_health
	)


	if current_health <= 0:

		_defeat()

		return


	_start_hurt()


func heal_boss(
	amount: int = 20
) -> void:

	if is_dead:

		return

	if amount <= 0:

		return


	current_health = min(
		current_health + amount,
		max_health
	)

	boss_health_changed.emit(
		current_health,
		max_health
	)

	print(
		"BOSS RECUPEROU VIDA: ",
		amount,
		" | VIDA: ",
		current_health,
		"/",
		max_health
	)

	# Mesmo stun do dano, mas com feedback verde.
	healing_feedback = true
	is_hurt = true
	hurt_time_left = HURT_DURATION
	flash_time_left = FLASH_DURATION
	_reset_attack_state()
	velocity.x = 0.0
	_play_animation(
		"hurt"
	)


func hurt() -> void:

	take_boss_damage(
		1
	)


func set_boss_health(
	value: int
) -> void:

	if is_dead:

		return


	current_health = clamp(
		value,
		0,
		max_health
	)


	boss_health_changed.emit(
		current_health,
		max_health
	)


	if current_health <= 0:

		_defeat()


func reset_boss_health() -> void:

	if is_dead:

		return


	current_health = max_health


	boss_health_changed.emit(
		current_health,
		max_health
	)


func get_current_health() -> int:

	return current_health


func get_max_health() -> int:

	return max_health


func get_health_percent() -> float:

	if max_health <= 0:

		return 0.0


	return (
		float(current_health)
		/
		float(max_health)
	)


func reset_visual() -> void:

	if animated_sprite == null:

		return


	animated_sprite.modulate = Color.WHITE


	_play_animation(
		"olhando"
	)


# ============================================================
# RESET ATAQUE
# ============================================================

func _reset_attack_state() -> void:

	is_attacking = false

	attack_hit_done = false

	attack_prepare_timer = 0.0

	attack_dash_timer = 0.0

	attack_recovery_timer = 0.0


func _reset_all_timers() -> void:

	rage_timer = RAGE_INTERVAL

	rage_time_left = 0.0

	enraged = false

	attack_cooldown = 0.0

	battle_start_delay_timer = 0.0
	battle_start_delay_active = false
	damage_enabled_before_battle_delay = false

	attack_prepare_timer = 0.0

	attack_dash_timer = 0.0

	attack_recovery_timer = 0.0

	damage_cooldown = 0.0

	jump_cooldown = 0.0

	turn_cooldown = 0.0

	stomp_cooldown = 0.0

	hurt_time_left = 0.0

	flash_time_left = 0.0


# ============================================================
# MORTE
# ============================================================

func _defeat() -> void:

	if is_dead:

		return


	is_dead = true

	can_move = false

	attack_enabled = false

	damage_enabled = false

	stomp_enabled = false

	waiting_for_landing_lock = false

	velocity = Vector2.ZERO

	_reset_attack_state()


	# Desativa colisão, mas MANTÉM O BOSS VISÍVEL.
	# Ele só vai desaparecer depois que o diálogo
	# de derrota terminar completamente.
	if collision != null:

		collision.set_deferred(
			"disabled",
			true
		)


	if hitbox_area != null:

		hitbox_area.set_deferred(
			"monitoring",
			false
		)


	# Mantém a animação de dano/morte na tela
	# enquanto o jogador lê a mensagem.
	_play_animation(
		"hurt"
	)


	# Avisa imediatamente o controlador da batalha.
	# O boss continua visível até _finish_victory().
	boss_defeated.emit()
