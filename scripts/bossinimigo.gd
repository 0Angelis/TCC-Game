extends CharacterBody2D

# ============================================================
# BOSS INIMIGO — FISICA E COMPORTAMENTO
# ============================================================
# Animações:
# - olhando
# - walking
# - ataque
# - hurt
# - pular
#
# O boss.gd controla a lógica da batalha.
# ESTE SCRIPT controla apenas:
# - gravidade
# - movimento
# - pulo
# - ataque
# - colisão
# - dano no Player
# - dano recebido
# - pisão
# ============================================================

signal boss_attack_started
signal boss_health_changed(current: int, maximum: int)
signal boss_defeated

const SPRITE_FACES_RIGHT: bool = false

const WALK_SPEED: float = 14.0
const CHASE_SPEED: float = 22.0
const ACCELERATION: float = 65.0
const DECELERATION: float = 100.0

const DETECTION_DISTANCE: float = 500.0

const ATTACK_TRIGGER_DISTANCE: float = 22.0
const ATTACK_HIT_DISTANCE: float = 26.0
const ATTACK_VERTICAL_DISTANCE: float = 25.0

const ATTACK_COOLDOWN: float = 1.60
const ATTACK_DURATION: float = 0.62

const DAMAGE_COOLDOWN: float = 0.70
const KNOCKBACK_X: float = 120.0
const KNOCKBACK_Y: float = -45.0

const JUMP_FORCE: float = -285.0
const JUMP_COOLDOWN: float = 1.10
const EDGE_JUMP_SPEED: float = 52.0
const PLAYER_HEIGHT_TO_JUMP: float = 48.0
const EDGE_FOLLOW_DISTANCE: float = 320.0

const TURN_COOLDOWN: float = 0.18

# Um pisão mata o boss.
@export var stomp_damage: int = 999999
@export var max_health: int = 120

var current_health: int = 120

var player: CharacterBody2D = null
var direction: int = -1

var can_move: bool = true
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false

var attack_enabled: bool = false
var damage_enabled: bool = false
var stomp_enabled: bool = false

var attack_cooldown: float = 0.0
var attack_timer: float = 0.0
var damage_cooldown: float = 0.0
var jump_cooldown: float = 0.0
var turn_cooldown: float = 0.0

var attack_hit_done: bool = false
var attack_locked_until_leave: bool = false
var stomp_invulnerability: float = 0.0

var player_was_above: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $collision
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var hitbox_area: Area2D = $Area2D
@onready var hitbox: CollisionShape2D = $Area2D/hitbox


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")

	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	up_direction = Vector2.UP
	floor_snap_length = 6.0

	current_health = max_health

	_find_player()

	direction = -1
	_set_facing(direction)

	ray_cast.enabled = true
	_update_ray_cast()

	hitbox_area.monitoring = true
	hitbox_area.monitorable = true

	if not hitbox_area.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox_area.body_entered.connect(_on_hitbox_body_entered)

	_play_animation("olhando")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_timers(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	_update_player_vertical_state()

	if is_hurt:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			DECELERATION * delta
		)
		move_and_slide()
		_check_stomp_overlap()
		_update_air_animation()
		return

	if not can_move:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			DECELERATION * delta
		)
		_play_animation("olhando")
		move_and_slide()
		_check_stomp_overlap()
		_update_air_animation()
		return

	if is_attacking:
		_process_attack(delta)
		_check_stomp_overlap()
		_update_air_animation()
		return

	if not is_instance_valid(player):
		_find_player()

	if not is_instance_valid(player):
		velocity.x = move_toward(
			velocity.x,
			0.0,
			DECELERATION * delta
		)
		_play_animation("olhando")
		move_and_slide()
		return

	_update_attack_lock()

	var distance_x: float = abs(
		player.global_position.x -
		global_position.x
	)

	var distance_y: float = abs(
		player.global_position.y -
		global_position.y
	)

	if (
		attack_enabled
		and
		distance_x <= ATTACK_TRIGGER_DISTANCE
		and
		distance_y <= ATTACK_VERTICAL_DISTANCE
		and
		attack_cooldown <= 0.0
		and
		not attack_locked_until_leave
	):
		_face_player()
		_start_attack()
		move_and_slide()
		return

	# Pulo se o Player está claramente acima.
	if (
		is_on_floor()
		and
		jump_cooldown <= 0.0
		and
		distance_y >= PLAYER_HEIGHT_TO_JUMP
		and
		distance_x <= EDGE_FOLLOW_DISTANCE
		and
		player.global_position.y < global_position.y
	):
		_jump_toward_player()
		move_and_slide()
		_update_air_animation()
		return

	_update_ray_cast()

	# Borda: tenta pular para continuar seguindo.
	if is_on_floor() and not ray_cast.is_colliding():
		if _can_follow_over_edge():
			_jump_from_edge_toward_player()
		else:
			_virar()

		move_and_slide()
		_update_air_animation()
		return

	_chase_player(delta)
	move_and_slide()

	_process_slide_collisions()
	_update_air_animation()

	if is_on_floor() and abs(velocity.x) > 0.1:
		_play_animation("walking")
	elif is_on_floor():
		_play_animation("olhando")


func _update_timers(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if damage_cooldown > 0.0:
		damage_cooldown -= delta

	if jump_cooldown > 0.0:
		jump_cooldown -= delta

	if turn_cooldown > 0.0:
		turn_cooldown -= delta

	if stomp_invulnerability > 0.0:
		stomp_invulnerability -= delta


func _find_player() -> void:
	var players: Array[Node] = (
		get_tree().get_nodes_in_group("player")
	)

	for candidate: Node in players:
		if candidate is CharacterBody2D:
			player = candidate as CharacterBody2D
			return

	player = null


func _update_player_vertical_state() -> void:
	if not is_instance_valid(player):
		player_was_above = false
		return

	player_was_above = (
		player.global_position.y <
		global_position.y - 5.0
	)


func _chase_player(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var difference: float = (
		player.global_position.x -
		global_position.x
	)

	var target_direction: int = direction

	if difference > 7.0:
		target_direction = 1
	elif difference < -7.0:
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

	velocity.x = move_toward(
		velocity.x,
		direction * CHASE_SPEED,
		ACCELERATION * delta
	)


func _start_attack() -> void:
	if not attack_enabled:
		return

	if is_attacking:
		return

	if attack_locked_until_leave:
		return

	if attack_cooldown > 0.0:
		return

	if not _player_is_in_front():
		return

	is_attacking = true
	attack_hit_done = false
	attack_timer = ATTACK_DURATION
	attack_cooldown = ATTACK_COOLDOWN

	velocity.x = 0.0
	_face_player()
	_play_animation("ataque")

	# IMPORTANTE:
	# o controlador da luta conta este sinal como um
	# ataque real do boss.
	boss_attack_started.emit()


func _process_attack(delta: float) -> void:
	velocity.x = 0.0

	if not attack_hit_done:
		if (
			attack_timer <=
			ATTACK_DURATION * 0.55
		):
			if _player_is_in_attack_hit_range():
				dar_dano_no_player(player)

			attack_hit_done = true

	attack_timer -= delta
	move_and_slide()
	_check_stomp_overlap()

	if attack_timer <= 0.0:
		is_attacking = false
		attack_locked_until_leave = true

		if not is_dead and not is_hurt:
			if is_on_floor():
				_play_animation("walking")
			else:
				_play_animation("pular")


func _player_is_in_attack_hit_range() -> bool:
	if not is_instance_valid(player):
		return false

	if not _player_is_in_front():
		return false

	var horizontal_distance: float = abs(
		player.global_position.x -
		global_position.x
	)

	var vertical_distance: float = abs(
		player.global_position.y -
		global_position.y
	)

	return (
		horizontal_distance <= ATTACK_HIT_DISTANCE
		and
		vertical_distance <= ATTACK_VERTICAL_DISTANCE
	)


func _player_is_in_front() -> bool:
	if not is_instance_valid(player):
		return false

	var difference: float = (
		player.global_position.x -
		global_position.x
	)

	if abs(difference) <= 1.0:
		return true

	if direction > 0:
		return difference > 0.0

	return difference < 0.0


func _update_attack_lock() -> void:
	if not attack_locked_until_leave:
		return

	if not is_instance_valid(player):
		attack_locked_until_leave = false
		return

	var horizontal_distance: float = abs(
		player.global_position.x -
		global_position.x
	)

	var vertical_distance: float = abs(
		player.global_position.y -
		global_position.y
	)

	if (
		horizontal_distance >
		ATTACK_TRIGGER_DISTANCE + 18.0
		or
		vertical_distance >
		ATTACK_VERTICAL_DISTANCE + 18.0
	):
		attack_locked_until_leave = false


func dar_dano_no_player(body: Node2D) -> void:
	if not damage_enabled:
		return

	if is_dead:
		return

	if damage_cooldown > 0.0:
		return

	if body == null or not is_instance_valid(body):
		return

	if not body.is_in_group("player"):
		return

	# Não causa dano por baixo/atrás.
	if body.global_position.y < global_position.y - 5.0:
		return

	if not _body_is_in_front(body):
		return

	if not body.has_method("take_damage"):
		return

	var knockback_direction: float = 1.0

	if body.global_position.x < global_position.x:
		knockback_direction = -1.0

	body.take_damage(
		Vector2(
			knockback_direction * KNOCKBACK_X,
			KNOCKBACK_Y
		)
	)

	damage_cooldown = DAMAGE_COOLDOWN


func _body_is_in_front(body: Node2D) -> bool:
	var difference: float = (
		body.global_position.x -
		global_position.x
	)

	if abs(difference) <= 1.0:
		return true

	if direction > 0:
		return difference > 0.0

	return difference < 0.0


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if not body.is_in_group("player"):
		return

	_check_single_stomp(body)

	if not damage_enabled:
		return

	if is_attacking:
		return

	if _is_player_above_boss(body):
		return

	dar_dano_no_player(body)


func _check_stomp_overlap() -> void:
	if is_dead:
		return

	if stomp_invulnerability > 0.0:
		return

	var bodies: Array[Node2D] = (
		hitbox_area.get_overlapping_bodies()
	)

	for body: Node2D in bodies:
		if body.is_in_group("player"):
			_check_single_stomp(body)
			return


func _check_single_stomp(body: Node2D) -> void:
	if not stomp_enabled:
		return

	if is_dead:
		return

	if stomp_invulnerability > 0.0:
		return

	if not body.is_in_group("player"):
		return

	if not _is_player_above_boss(body):
		return

	var horizontal_distance: float = abs(
		body.global_position.x -
		global_position.x
	)

	if horizontal_distance > 46.0:
		return

	var player_vertical_speed: float = 0.0

	if body.get("velocity") != null:
		var player_velocity: Vector2 = (
			body.get("velocity") as Vector2
		)
		player_vertical_speed = player_velocity.y

	# Jogador precisa estar descendo sobre o boss
	# ou muito próximo do topo.
	if player_vertical_speed > 140.0:
		return

	stomp_invulnerability = 0.65

	take_boss_damage(max_health)


func _is_player_above_boss(body: Node2D) -> bool:
	return (
		body.global_position.y <
		global_position.y - 8.0
	)


func take_boss_damage(amount: int = 1) -> void:
	if is_dead:
		return

	if amount <= 0:
		return

	current_health -= amount
	current_health = max(current_health, 0)

	boss_health_changed.emit(
		current_health,
		max_health
	)

	_play_hurt()

	if current_health <= 0:
		_defeat()


func hurt() -> void:
	take_boss_damage(1)


func _play_hurt() -> void:
	if is_dead or is_hurt:
		return

	is_hurt = true
	is_attacking = false
	attack_timer = 0.0
	velocity.x = 0.0

	_play_animation("hurt")

	animated_sprite.modulate = Color(
		1.0,
		0.55,
		0.55,
		1.0
	)

	await get_tree().create_timer(0.20).timeout

	if is_dead:
		return

	animated_sprite.modulate = Color.WHITE
	is_hurt = false

	if is_on_floor():
		_play_animation("olhando")
	else:
		_play_animation("pular")


func _defeat() -> void:
	if is_dead:
		return

	is_dead = true
	can_move = false
	damage_enabled = false
	is_hurt = false
	is_attacking = false

	velocity = Vector2.ZERO

	# Não existe animação death no seu boss.
	# Usamos hurt como reação e depois desaparecemos.
	_play_animation("hurt")

	await get_tree().create_timer(0.25).timeout

	# Fade simples.
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		animated_sprite,
		"modulate:a",
		0.0,
		0.35
	)
	tween.tween_property(
		animated_sprite,
		"scale",
		Vector2(0.82, 0.82),
		0.35
	)

	await tween.finished

	boss_defeated.emit()


func _jump_toward_player() -> void:
	if jump_cooldown > 0.0:
		return

	if not is_on_floor():
		return

	jump_cooldown = JUMP_COOLDOWN

	var target_direction: float = 1.0

	if is_instance_valid(player):
		if player.global_position.x < global_position.x:
			target_direction = -1.0

	_set_facing(int(target_direction))
	velocity.y = JUMP_FORCE
	velocity.x = target_direction * EDGE_JUMP_SPEED

	_play_animation("pular")


func _jump_from_edge_toward_player() -> void:
	_jump_toward_player()


func _can_follow_over_edge() -> bool:
	if not is_instance_valid(player):
		return false

	var horizontal_distance: float = abs(
		player.global_position.x -
		global_position.x
	)

	return horizontal_distance <= EDGE_FOLLOW_DISTANCE


func _process_slide_collisions() -> void:
	for i: int in range(get_slide_collision_count()):
		var collision_data: KinematicCollision2D = (
			get_slide_collision(i)
		)

		var collider: Object = (
			collision_data.get_collider()
		)

		var normal: Vector2 = (
			collision_data.get_normal()
		)

		if collider == null:
			continue

		if collider.is_in_group("enemies"):
			if collider != self:
				_virar()
			break

		if abs(normal.x) > 0.5:
			_virar()
			break


func _virar() -> void:
	if is_dead or is_hurt or is_attacking:
		return

	if turn_cooldown > 0.0:
		return

	turn_cooldown = TURN_COOLDOWN

	direction *= -1
	_set_facing(direction)
	_update_ray_cast()


func _face_player() -> void:
	if not is_instance_valid(player):
		return

	var difference: float = (
		player.global_position.x -
		global_position.x
	)

	if difference < 0.0:
		_set_facing(-1)
	else:
		_set_facing(1)

	_update_ray_cast()


func _set_facing(new_direction: int) -> void:
	direction = -1 if new_direction < 0 else 1

	if SPRITE_FACES_RIGHT:
		animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.flip_h = direction > 0


func _update_ray_cast() -> void:
	if ray_cast == null:
		return

	ray_cast.target_position = Vector2(
		float(direction) * 18.0,
		24.0
	)

	ray_cast.force_raycast_update()


func _update_air_animation() -> void:
	if is_dead or is_hurt or is_attacking:
		return

	if not is_on_floor():
		_play_animation("pular")


func _play_animation(name: String) -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation(name):
		return

	if animated_sprite.animation == name:
		if not animated_sprite.is_playing():
			animated_sprite.play(name)
		return

	animated_sprite.stop()
	animated_sprite.play(name)


# ============================================================
# CONTROLE DA BATALHA
# ============================================================

func set_attack_enabled(enabled: bool) -> void:
	attack_enabled = enabled

	if not enabled:
		is_attacking = false
		attack_timer = 0.0
		attack_hit_done = false


func set_damage_enabled(enabled: bool) -> void:
	damage_enabled = enabled

	# Não desliga a Area2D por completo, porque ela é usada
	# para o pisão do Player.
	hitbox_area.monitoring = true
	hitbox_area.monitorable = true


func set_stomp_enabled(enabled: bool) -> void:
	stomp_enabled = enabled


func freeze_boss() -> void:
	can_move = false
	velocity = Vector2.ZERO
	is_attacking = false
	attack_timer = 0.0
	_play_animation("olhando")


func unfreeze_boss() -> void:
	if is_dead:
		return

	can_move = true
	_find_player()


func continuar_boss() -> void:
	unfreeze_boss()


func parar_boss() -> void:
	freeze_boss()


func set_boss_health(value: int) -> void:
	current_health = clamp(
		value,
		0,
		max_health
	)

	boss_health_changed.emit(
		current_health,
		max_health
	)


func get_current_health() -> int:
	return current_health


func get_max_health() -> int:
	return max_health
