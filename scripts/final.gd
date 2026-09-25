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

var score_screen_open: bool = false

var final_total_score: int = 0

var final_total_play_time: float = 0.0


# ============================================================
# NODES
# ============================================================

var collision_shape: CollisionShape2D = null

var prompt_layer: CanvasLayer = null

var prompt_label: Label = null

var score_layer: CanvasLayer = null

var score_overlay: ColorRect = null

var score_panel: Panel = null

var score_title: Label = null

var score_value: Label = null

var score_hint: Button = null


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
# INPUT - E / ENTER NA TELA DE SCORE
# ============================================================

func _input(event: InputEvent) -> void:

	# ========================================================
	# TELA DE SCORE FINAL
	# ========================================================

	if score_screen_open:

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
			key_event.keycode == KEY_ENTER
			or
			key_event.keycode == KEY_KP_ENTER
			or
			key_event.keycode == KEY_E
			or
			key_event.physical_keycode == KEY_E
		):

			get_viewport().set_input_as_handled()

			_close_score_screen()

		return


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

	# Para o cronômetro antes de abrir a tela final.
	Globals.pause_game_timer()

	# Soma o score do ultimo mundo ao total ja acumulado.
	final_total_score = (
		Globals.total_score
		+
		Globals.score
	)

	Globals.total_score = final_total_score

	# Finaliza explicitamente o tempo da ultima fase.
	# Assim a pontuacao e o tempo seguem a mesma regra:
	# cada fase contribui uma unica vez para o total.
	Globals.finalize_current_level_time()
	final_total_play_time = Globals.total_play_time

	# A partida terminou aqui.
	Globals.stop_game_timer()

	print(
		"TEMPO TOTAL DA PARTIDA: ",
		Globals.format_game_time(final_total_play_time)
	)

	print(
		"================================"
	)

	print(
		"SCORE TOTAL DA PARTIDA: ",
		final_total_score
	)

	print(
		"ABRINDO TELA DE SCORE FINAL"
	)

	print(
		"================================"
	)

	_show_score_screen()

	await _wait_for_score_screen()

	if not is_inside_tree():
		return

	get_tree().paused = false

	get_tree().change_scene_to_file(
		CREDITS_SCENE
	)


# ============================================================
# ESPERA A TELA DE SCORE
# ============================================================

func _wait_for_score_screen() -> void:

	while score_screen_open and is_inside_tree():

		await get_tree().process_frame


# ============================================================
# TELA DE SCORE FINAL
# ============================================================

func _show_score_screen() -> void:

	if score_screen_open:
		return

	score_screen_open = true

	score_layer = CanvasLayer.new()
	score_layer.name = "FinalScoreLayer"
	score_layer.layer = 500
	score_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(score_layer)

	score_overlay = ColorRect.new()
	score_overlay.name = "FinalScoreOverlay"
	score_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	score_overlay.color = Color(
		0.02,
		0.01,
		0.05,
		0.88
	)
	score_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	score_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	score_layer.add_child(score_overlay)

	score_panel = Panel.new()
	score_panel.name = "FinalScorePanel"
	score_panel.anchor_left = 0.5
	score_panel.anchor_top = 0.5
	score_panel.anchor_right = 0.5
	score_panel.anchor_bottom = 0.5
	score_panel.offset_left = -290
	score_panel.offset_top = -225
	score_panel.offset_right = 290
	score_panel.offset_bottom = 225
	score_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#1B1030")
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color("#8E4DCE")
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0.20, 0.05, 0.30, 0.85)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 6)

	score_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	score_overlay.add_child(score_panel)

	var font_resource: Resource = load(
		"res://assets/Fontes/Pixeloid_Font_1_0/"
		+
		"OpenType (.otf)/PixeloidSans-Bold.otf"
	)

	# Titulo
	score_title = Label.new()
	score_title.name = "FinalScoreTitle"
	score_title.text = "PONTUAÇÃO FINAL"
	score_title.position = Vector2(30, 30)
	score_title.size = Vector2(520, 55)
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	score_title.add_theme_font_size_override("font_size", 26)
	score_title.add_theme_color_override("font_color", Color("#C88BFF"))
	score_title.add_theme_color_override("font_outline_color", Color.BLACK)
	score_title.add_theme_constant_override("outline_size", 5)
	if font_resource != null:
		score_title.add_theme_font_override("font", font_resource)
	score_panel.add_child(score_title)

	# Texto auxiliar
	var score_caption := Label.new()
	score_caption.name = "FinalScoreCaption"
	score_caption.text = "SEU SCORE TOTAL"
	score_caption.position = Vector2(30, 105)
	score_caption.size = Vector2(520, 35)
	score_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_caption.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	score_caption.add_theme_font_size_override("font_size", 15)
	score_caption.add_theme_color_override("font_color", Color("#F7F1FF"))
	score_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	score_caption.add_theme_constant_override("outline_size", 3)
	if font_resource != null:
		score_caption.add_theme_font_override("font", font_resource)
	score_panel.add_child(score_caption)

	# Valor
	score_value = Label.new()
	score_value.name = "FinalScoreValue"
	score_value.text = str(final_total_score)
	score_value.position = Vector2(30, 145)
	score_value.size = Vector2(520, 95)
	score_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_value.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	score_value.add_theme_font_size_override("font_size", 52)
	score_value.add_theme_color_override("font_color", Color("#F5D56A"))
	score_value.add_theme_color_override("font_outline_color", Color.BLACK)
	score_value.add_theme_constant_override("outline_size", 6)
	if font_resource != null:
		score_value.add_theme_font_override("font", font_resource)
	score_panel.add_child(score_value)

	# Tempo total
	var time_caption := Label.new()
	time_caption.name = "FinalTimeCaption"
	time_caption.text = "TEMPO TOTAL DE JOGO"
	time_caption.position = Vector2(30, 245)
	time_caption.size = Vector2(520, 32)
	time_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_caption.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	time_caption.add_theme_font_size_override("font_size", 12)
	time_caption.add_theme_color_override("font_color", Color("#F7F1FF"))
	time_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	time_caption.add_theme_constant_override("outline_size", 3)
	if font_resource != null:
		time_caption.add_theme_font_override("font", font_resource)
	score_panel.add_child(time_caption)

	var time_value := Label.new()
	time_value.name = "FinalTimeValue"
	time_value.text = Globals.format_game_time(final_total_play_time)
	time_value.position = Vector2(30, 278)
	time_value.size = Vector2(520, 55)
	time_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_value.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	time_value.add_theme_font_size_override("font_size", 24)
	time_value.add_theme_color_override("font_color", Color("#F5D56A"))
	time_value.add_theme_color_override("font_outline_color", Color.BLACK)
	time_value.add_theme_constant_override("outline_size", 4)
	if font_resource != null:
		time_value.add_theme_font_override("font", font_resource)
	score_panel.add_child(time_value)

	# Continuar
	# Agora e um Button de verdade para poder clicar com o mouse.
	score_hint = Button.new()
	score_hint.name = "FinalScoreHint"
	score_hint.text = "CONTINUAR"
	score_hint.position = Vector2(30, 350)
	score_hint.size = Vector2(520, 45)
	score_hint.alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_hint.focus_mode = Control.FOCUS_NONE
	score_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	score_hint.flat = true
	score_hint.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	score_hint.add_theme_font_size_override("font_size", 14)
	score_hint.add_theme_color_override("font_color", Color("#7BE7FF"))
	score_hint.add_theme_color_override("font_hover_color", Color("#A9F0FF"))
	score_hint.add_theme_color_override("font_pressed_color", Color("#7BE7FF"))
	score_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	score_hint.add_theme_constant_override("outline_size", 4)
	if font_resource != null:
		score_hint.add_theme_font_override("font", font_resource)
	score_hint.pressed.connect(_on_score_continue_pressed)
	score_panel.add_child(score_hint)


# ============================================================
# BOTAO CONTINUAR DA TELA FINAL
# ============================================================

func _on_score_continue_pressed() -> void:
	get_viewport().set_input_as_handled()
	_close_score_screen()


# ============================================================
# FECHA TELA DE SCORE
# ============================================================

func _close_score_screen() -> void:

	if not score_screen_open:
		return

	score_screen_open = false

	if score_layer != null:
		score_layer.queue_free()

	score_layer = null
	score_overlay = null
	score_panel = null
	score_title = null
	score_value = null
	score_hint = null


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
