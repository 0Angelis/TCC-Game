extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

var direction := -1

const SPEED := 30.0


# ==========================================
# ESTADO
# ==========================================

var is_dead := false


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

	direction = -1

	animated_sprite.flip_h = false

	ray_cast.enabled = true

	_update_ray_cast()

	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation("walkin"):

			animated_sprite.play("walkin")

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

	if not is_on_floor():

		velocity += get_gravity() * delta

	_update_ray_cast()

	if is_on_floor():

		if not ray_cast.is_colliding():

			virar()

	velocity.x = direction * SPEED

	move_and_slide()

	for i in get_slide_collision_count():

		var slide_collision := get_slide_collision(i)

		var normal := slide_collision.get_normal()

		if abs(normal.x) > 0.5:

			virar()

			break

	if not is_dead:

		if animated_sprite.sprite_frames != null:

			if animated_sprite.sprite_frames.has_animation("walkin"):

				if animated_sprite.animation != "walkin":

					animated_sprite.play("walkin")


# ==========================================
# RAYCAST
# ==========================================

func _update_ray_cast() -> void:

	if ray_cast == null:
		return

	ray_cast.target_position = Vector2(
		direction * 18.0,
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

	if is_dead:
		return

	if not body.is_in_group("player"):
		return

	if body.global_position.y >= global_position.y:
		return

	matar_minhoca()

	body.velocity.y = -120.0


# ==========================================
# MORTE
# ==========================================

func matar_minhoca() -> void:

	if is_dead:
		return

	is_dead = true


	# ==========================================
	# +50 SCORE
	# ==========================================

	Globals.score += 50


	print("MINHOCA DERROTADA!")
	print("+50 SCORE")
	print("SCORE ATUAL: ", Globals.score)


	velocity = Vector2.ZERO

	set_physics_process(false)

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

	animated_sprite.visible = true

	animated_sprite.play("hurt")

	var original_position := animated_sprite.position

	animated_sprite.rotation_degrees = 0.0

	var jump_tween := create_tween()

	jump_tween.set_parallel(true)

	jump_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(0, -5),
		0.18
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

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

	await get_tree().create_timer(0.04).timeout

	var fall_tween := create_tween()

	fall_tween.set_parallel(true)

	fall_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(0, 14),
		0.20
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	fall_tween.tween_property(
		animated_sprite,
		"rotation_degrees",
		180.0,
		0.20
	)

	await fall_tween.finished

	var fade_tween := create_tween()

	fade_tween.set_parallel(true)

	fade_tween.tween_property(
		animated_sprite,
		"position",
		original_position + Vector2(0, 18),
		0.12
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

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

	queue_free()


# ==========================================
# MORTE DIRETA
# ==========================================

func die() -> void:

	matar_minhoca()
