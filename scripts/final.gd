extends Area2D


# ============================================================
# FINAL DO JOGO
# ============================================================
#
# Perto da porta:
#     [ E ] ENTRAR EM CASA
#
# O prompt e criado em um CanvasLayer para ficar SEMPRE
# visivel por cima do cenario/camera.
#
# A deteccao do player usa distancia, entao nao depende
# somente do Collision Layer/Mask do Area2D.
#
# ============================================================


# ============================================================
# CONFIGURACAO
# ============================================================

const CREDITS_SCENE: String = (
	"res://scenes/credits.tscn"
)

const PROMPT_TEXT: String = (
	"[ E ] ENTRAR EM CASA"
)

# Aumentado para a mensagem aparecer de forma confiavel
# quando o player estiver chegando perto da porta.
const PROMPT_DISTANCE: float = 20.0


# ============================================================
# ESTADO
# ============================================================

var player: CharacterBody2D = null

var player_near: bool = false

var entering_house: bool = false


# ============================================================
# NODES
# ============================================================

var collision_shape: CollisionShape2D = null

var prompt_layer: CanvasLayer = null

var prompt_label: Label = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	monitoring = true

	monitorable = true

	collision_shape = (
		get_node_or_null(
			"CollisionShape2D"
		)
		as CollisionShape2D
	)

	if not body_entered.is_connected(
		_on_body_entered
	):

		body_entered.connect(
			_on_body_entered
		)

	if not body_exited.is_connected(
		_on_body_exited
	):

		body_exited.connect(
			_on_body_exited
		)

	_create_prompt()

	_hide_prompt()

	_find_player()


# ============================================================
# PROCESS
# ============================================================

func _process(_delta: float) -> void:

	if entering_house:
		return

	_find_player_if_needed()

	if not is_instance_valid(player):

		_hide_prompt()

		return


	var target_position: Vector2 = (
		global_position
	)

	if collision_shape != null:

		target_position = (
			collision_shape.global_position
		)


	var distance: float = (
		player.global_position.distance_to(
			target_position
		)
	)


	if distance <= PROMPT_DISTANCE:

		player_near = true

		_show_prompt()

	else:

		player_near = false

		_hide_prompt()


	_update_prompt_position(
		target_position
	)


# ============================================================
# INPUT - E
# ============================================================

func _input(event: InputEvent) -> void:

	if entering_house:
		return

	if not player_near:
		return

	if not event is InputEventKey:
		return

	var key_event := (
		event as InputEventKey
	)

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	if (
		key_event.keycode == KEY_E
		or
		key_event.physical_keycode == KEY_E
	):

		get_viewport().set_input_as_handled()

		_enter_home()


# ============================================================
# BODY ENTERED
# ============================================================

func _on_body_entered(
	body: Node2D
) -> void:

	if entering_house:
		return

	if not body.is_in_group(
		"player"
	):

		return

	player = (
		body as CharacterBody2D
	)

	player_near = true

	_show_prompt()


# ============================================================
# BODY EXITED
# ============================================================

func _on_body_exited(
	body: Node2D
) -> void:

	if player == null:
		return

	if body != player:
		return

	# Nao escondemos definitivamente aqui.
	# O _process() continua controlando a distancia.
	_find_player_if_needed()


# ============================================================
# PROCURA PLAYER
# ============================================================

func _find_player() -> void:

	var found: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if found is CharacterBody2D:

		player = (
			found as CharacterBody2D
		)

		return


	var scene := (
		get_tree().current_scene
	)

	if scene != null:

		var direct_player: Node = (
			scene.get_node_or_null(
				"player"
			)
		)

		if direct_player is CharacterBody2D:

			player = (
				direct_player
				as CharacterBody2D
			)


func _find_player_if_needed() -> void:

	if is_instance_valid(player):
		return

	_find_player()


# ============================================================
# ENTRAR EM CASA
# ============================================================

func _enter_home() -> void:

	if entering_house:
		return

	if not player_near:
		return

	if not is_instance_valid(player):
		return

	entering_house = true

	_hide_prompt()

	monitoring = false

	_freeze_player()

	print(
		"================================"
	)

	print(
		"FINAL: ENTRANDO EM CASA"
	)

	print(
		"ABRINDO CREDITOS"
	)

	print(
		"================================"
	)

	await get_tree().create_timer(
		0.20
	).timeout

	if not is_inside_tree():
		return

	get_tree().paused = false

	get_tree().change_scene_to_file(
		CREDITS_SCENE
	)


# ============================================================
# CONGELAR PLAYER
# ============================================================

func _freeze_player() -> void:

	if not is_instance_valid(player):
		return

	player.velocity = Vector2.ZERO

	if "can_move" in player:

		player.set(
			"can_move",
			false
		)


	if player.has_method(
		"restaurar_animacao_normal"
	):

		player.call(
			"restaurar_animacao_normal"
		)


	var animated: Node = (
		player.get_node_or_null(
			"Anim"
		)
	)

	if animated == null:

		animated = (
			player.get_node_or_null(
				"AnimatedSprite2D"
			)
		)


	if animated is AnimatedSprite2D:

		var sprite := (
			animated as AnimatedSprite2D
		)

		if sprite.sprite_frames != null:

			if sprite.sprite_frames.has_animation(
				"idle"
			):

				sprite.play(
					"idle"
				)

			elif sprite.sprite_frames.has_animation(
				"olhando"
			):

				sprite.play(
					"olhando"
				)


# ============================================================
# PROMPT
# ============================================================

func _create_prompt() -> void:

	if prompt_layer != null:
		return

	prompt_layer = CanvasLayer.new()

	prompt_layer.name = (
		"FinalPromptLayer"
	)

	prompt_layer.layer = 200

	prompt_layer.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	add_child(
		prompt_layer
	)


	prompt_label = Label.new()

	prompt_label.name = (
		"FinalPrompt"
	)

	prompt_label.text = (
		PROMPT_TEXT
	)

	prompt_label.size = Vector2(
		380,
		40
	)

	prompt_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	prompt_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	prompt_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	prompt_label.z_index = 200

	prompt_label.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)


	prompt_label.add_theme_font_size_override(
		"font_size",
		14
	)

	prompt_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	prompt_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	prompt_label.add_theme_constant_override(
		"outline_size",
		4
	)


	var font_resource: Resource = load(
		"res://assets/Fontes/Pixeloid_Font_1_0/"
		+
		"OpenType (.otf)/PixeloidSans-Bold.otf"
	)

	if font_resource != null:

		prompt_label.add_theme_font_override(
			"font",
			font_resource
		)


	prompt_layer.add_child(
		prompt_label
	)


# ============================================================
# POSICIONAR PROMPT NA TELA
# ============================================================

func _update_prompt_position(
	target_position: Vector2
) -> void:

	if prompt_label == null:
		return

	if prompt_layer == null:
		return

	var viewport := get_viewport()

	if viewport == null:
		return


	# Converte a posicao do mundo para a tela.
	var screen_position: Vector2 = (
		viewport
		.get_canvas_transform()
		*
		target_position
	)


	prompt_label.position = Vector2(
		screen_position.x
		-
		prompt_label.size.x * 0.5,

		screen_position.y
		-
		prompt_label.size.y
		-
		20.0
	)


# ============================================================
# SHOW / HIDE
# ============================================================

func _show_prompt() -> void:

	if prompt_label == null:
		return

	prompt_label.visible = true


func _hide_prompt() -> void:

	if prompt_label == null:
		return

	prompt_label.visible = false
