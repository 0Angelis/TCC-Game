extends Control


# =========================================================
# SINAIS
# =========================================================

signal challenge_completed
signal challenge_failed


# =========================================================
# CONFIGURAÇÕES
# =========================================================

const TOTAL_ROUNDS: int = 5

const INITIAL_TIME: float = 15.0

const MAX_TIME: float = 20.0


# =========================================================
# TEMPO
# =========================================================

const CORRECT_TIME_BONUS: float = 1.0

const ERROR_TIME_PENALTY: float = 4.0


# =========================================================
# VELOCIDADE DA SEQUÊNCIA
# =========================================================

const START_DELAY: float = 1.20

const BETWEEN_COLORS: float = 0.32

const FLASH_TIME: float = 0.24

const AFTER_FLASH_DELAY: float = 0.16

const NEXT_ROUND_DELAY: float = 0.80

const ERROR_DELAY: float = 1.00


# =========================================================
# SCORE
# =========================================================

const VICTORY_SCORE: int = 1500


# =========================================================
# GENIUS
# =========================================================

const WHEEL_RADIUS: float = 180.0

const WHEEL_INNER_RADIUS: float = 70.0

const WHEEL_GAP: float = 0.065


# =========================================================
# PAINÉIS
# =========================================================

const PANEL_COLOR: Color = Color("#171226")

const PANEL_BORDER: Color = Color("#68438F")


# =========================================================
# TEXTO
# =========================================================

const WHITE: Color = Color("#F4EFF9")

const PURPLE: Color = Color("#9259C2")

const PURPLE_LIGHT: Color = Color("#B977DF")


# =========================================================
# CORES
# =========================================================

const RED: Color = Color("#D84A4A")
const RED_LIGHT: Color = Color("#FF7774")

const BLUE: Color = Color("#3F78C4")
const BLUE_LIGHT: Color = Color("#76ADFA")

const GREEN: Color = Color("#4FA35E")
const GREEN_LIGHT: Color = Color("#79D485")

const YELLOW: Color = Color("#D5B53D")
const YELLOW_LIGHT: Color = Color("#F2D86B")


# =========================================================
# FEEDBACK
# =========================================================

const SUCCESS: Color = Color("#55C96B")

const ERROR: Color = Color("#E85B70")


# =========================================================
# TELA FINAL
# =========================================================

const RETRO_PANEL_COLOR: Color = Color("#1B1030")

const RETRO_PURPLE: Color = Color("#8E4DCE")

const RETRO_PURPLE_LIGHT: Color = Color("#C88BFF")

const RETRO_MAGENTA: Color = Color("#E35BFF")

const RETRO_CYAN: Color = Color("#7BE7FF")

const RETRO_GOLD: Color = Color("#F5D56A")

const RETRO_WHITE: Color = Color("#F7F1FF")

const RETRO_BLACK: Color = Color("#0A0610")


# =========================================================
# REFERÊNCIAS
# =========================================================

var background: CanvasItem = null

var old_ui: Control = null

var tutorial: Control = null

var tutorial_image: TextureRect = null

var tutorial_button: Button = null


var tutorial_finished: bool = false

var tutorial_dim_overlay: ColorRect = null

# Mantido apenas por compatibilidade; o jogo NÃO é escondido durante o tutorial.
var game_visual_nodes: Array[CanvasItem] = []


# =========================================================
# SEQUÊNCIA
# =========================================================

var sequence: Array[int] = []

var player_index: int = 0


# =========================================================
# RODADA
# =========================================================

var current_round: int = 0


# =========================================================
# ERROS
# =========================================================

var total_errors: int = 0


# =========================================================
# ESTADOS
# =========================================================

var showing_sequence: bool = false

var player_turn: bool = false

var game_finished: bool = false

var game_started: bool = false


# =========================================================
# TIMER
# =========================================================

var time_left: float = 0.0

var timer_running: bool = false


# =========================================================
# STATUS
# =========================================================

var status_text: String = "PREPARE-SE"

var status_color: Color = WHITE


# =========================================================
# FLASH
# =========================================================

var flashing_button: int = -1

var flash_progress: float = 0.0


# =========================================================
# HOVER
# =========================================================

var hovered_button: int = -1


# =========================================================
# TELA FINAL
# =========================================================

var result_screen_active: bool = false

var result_is_success: bool = false

var final_layer: CanvasLayer = null

var final_overlay: Control = null

var final_panel: Panel = null

var final_button: Button = null

# =========================================================
# FONTE RETRÔ SOMENTE DAS TELAS FINAIS
# =========================================================

var final_retro_font: Font = null
var final_retro_theme: Theme = null


# =========================================================
# RETRO
# =========================================================

var retro_effect_busy: bool = false


# =========================================================
# FONTE RETRÔ DAS TELAS FINAIS
# =========================================================

func _get_final_retro_font() -> void:

	final_retro_font = null
	final_retro_theme = null

	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return

	# Reaproveita a mesma fonte retrô usada pelo HUD do jogo.
	var hud_label: Label = current_scene.find_child(
		"coins_counter",
		true,
		false
	) as Label

	if hud_label == null:
		return

	final_retro_font = hud_label.get_theme_font("font")
	final_retro_theme = hud_label.get_theme()


func _apply_final_retro_font(control: Control) -> void:

	if control == null:
		return

	if final_retro_theme != null:
		control.theme = final_retro_theme

	if final_retro_font != null:
		control.add_theme_font_override(
			"font",
			final_retro_font
		)

	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	mouse_filter = Control.MOUSE_FILTER_STOP

	set_process(true)

	set_process_input(true)


	# =====================================================
	# TELA INTEIRA
	# =====================================================

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	# =====================================================
	# BACKGROUND
	# =====================================================

	background = find_child(
		"BG 1",
		true,
		false
	) as CanvasItem


	if background == null:

		background = find_child(
			"BG",
			true,
			false
		) as CanvasItem


	if background != null:

		# O BG continua visível. Ele será apenas escurecido
		# por uma camada por cima enquanto o tutorial estiver aberto.
		background.visible = true

		background.z_index = -20


	# =====================================================
	# UI ANTIGA
	# =====================================================

	old_ui = find_child(
		"CenterContainer",
		true,
		false
	) as Control


	if old_ui != null:

		old_ui.visible = false


	# =====================================================
	# TUTORIAL
	# =====================================================

	tutorial = get_node_or_null("tutorial") as Control

	if tutorial == null:

		push_error("MemoryGame: nó 'tutorial' não foi encontrado.")

	else:

		tutorial.visible = true
		tutorial.z_index = 1000
		tutorial.mouse_filter = Control.MOUSE_FILTER_STOP
		tutorial.process_mode = Node.PROCESS_MODE_ALWAYS


		# -----------------------------------------------------
		# IMAGEM DO TUTORIAL
		# -----------------------------------------------------
		tutorial_image = tutorial.get_node_or_null("tutorial_MEMO") as TextureRect

		if tutorial_image == null:

			push_error("MemoryGame: nó 'tutorial/tutorial_MEMO' não foi encontrado.")

		else:

			# NÃO alteramos posição, tamanho, âncoras ou stretch da imagem.
			# O layout centralizado feito no editor é preservado.
			tutorial_image.visible = true
			tutorial_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tutorial_image.z_index = 1

		# -----------------------------------------------------
		# BOTÃO COMEÇAR
		# -----------------------------------------------------
		tutorial_button = tutorial.get_node_or_null("Button") as Button

		if tutorial_button == null:

			push_error("MemoryGame: nó 'tutorial/Button' não foi encontrado.")

		else:

			# Coloca o botão na parte de baixo da tela,
			# centralizado e fora da imagem.
			tutorial_button.anchor_left = 0.5
			tutorial_button.anchor_right = 0.5
			tutorial_button.anchor_top = 1.0
			tutorial_button.anchor_bottom = 1.0

			tutorial_button.offset_left = -160
			tutorial_button.offset_right = 160
			tutorial_button.offset_top = 5
			tutorial_button.offset_bottom = 69

			tutorial_button.text = "COMEÇAR"
			tutorial_button.visible = true
			tutorial_button.z_index = 10
			tutorial_button.focus_mode = Control.FOCUS_NONE
			tutorial_button.mouse_filter = Control.MOUSE_FILTER_STOP
			tutorial_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			tutorial_button.add_theme_font_size_override("font_size", 20)
			tutorial_button.add_theme_color_override("font_color", WHITE)
			tutorial_button.add_theme_color_override("font_hover_color", WHITE)
			tutorial_button.add_theme_color_override("font_pressed_color", WHITE)
			tutorial_button.add_theme_color_override("font_focus_color", WHITE)
			style_tutorial_button(tutorial_button)

			if not tutorial_button.pressed.is_connected(_on_tutorial_continue):

				tutorial_button.pressed.connect(_on_tutorial_continue)


	# =====================================================
	# ESCURECE O JOGO ATRÁS DO TUTORIAL
	# =====================================================
	_create_tutorial_dim_overlay()


	# =====================================================
	# RESET
	# =====================================================

	current_round = 0

	sequence.clear()

	player_index = 0

	total_errors = 0

	showing_sequence = false

	player_turn = false

	game_finished = false

	game_started = false

	timer_running = false

	time_left = INITIAL_TIME

	status_text = "PREPARE-SE"

	status_color = WHITE

	result_screen_active = false

	retro_effect_busy = false

	flashing_button = -1

	hovered_button = -1


	# =====================================================
	# COMEÇA
	# =====================================================

	tutorial_finished = false



# =========================================================
# ESCURECE O JOGO ATRÁS DO TUTORIAL
# =========================================================

func _create_tutorial_dim_overlay() -> void:

	if tutorial_dim_overlay != null and is_instance_valid(tutorial_dim_overlay):

		tutorial_dim_overlay.visible = true
		return

	tutorial_dim_overlay = ColorRect.new()
	tutorial_dim_overlay.name = "TutorialDimOverlay"
	tutorial_dim_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	tutorial_dim_overlay.color = Color(0.0, 0.0, 0.0, 0.58)
	tutorial_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_dim_overlay.z_index = 900
	tutorial_dim_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(tutorial_dim_overlay)
	move_child(tutorial_dim_overlay, get_child_count() - 1)

	if tutorial != null:

		tutorial.z_index = 1000
		move_child(tutorial, get_child_count() - 1)


# Mantido por compatibilidade com versões anteriores do script.
# O jogo NÃO é escondido durante o tutorial; apenas escurecido.
func _hide_game_visuals_for_tutorial() -> void:

	_create_tutorial_dim_overlay()


func _show_game_visuals_after_tutorial() -> void:

	if tutorial_dim_overlay != null and is_instance_valid(tutorial_dim_overlay):

		tutorial_dim_overlay.hide()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	# =====================================================
	# TIMER
	# =====================================================

	if timer_running and player_turn:

		time_left -= delta


		if time_left <= 0.0:

			time_left = 0.0

			timer_running = false

			time_finished()


	# =====================================================
	# FLASH
	# =====================================================

	if flashing_button != -1:

		flash_progress -= delta


		if flash_progress <= 0.0:

			flashing_button = -1

			flash_progress = 0.0


	# =====================================================
	# HOVER
	# =====================================================

	if (
		player_turn
		and not showing_sequence
		and not result_screen_active
		and not game_finished
	):

		var local_mouse: Vector2 = (
			get_local_mouse_position()
		)


		var new_hover: int = (
			get_button_at_position(
				local_mouse
			)
		)


		hovered_button = new_hover

	else:

		hovered_button = -1


	queue_redraw()


# =========================================================
# INPUT
# =========================================================

func _input(event: InputEvent) -> void:

	# =====================================================
	# TUTORIAL ABERTO:
	# somente ENTER/ENTER DO TECLADO NUMÉRICO inicia.
	# 1-4 e mouse não afetam o mini-game enquanto a tela
	# de tutorial estiver aberta.
	# O clique do botão continua funcionando normalmente.
	# =====================================================
	if not tutorial_finished:

		if event is InputEventKey:

			var tutorial_key: InputEventKey = event as InputEventKey

			if tutorial_key.pressed and not tutorial_key.echo:

				if (
					tutorial_key.keycode == KEY_ENTER
					or tutorial_key.keycode == KEY_KP_ENTER
				):

					_on_tutorial_continue()
					get_viewport().set_input_as_handled()

		return

	# =====================================================
	# TELA FINAL
	# =====================================================

	if result_screen_active:

		if event is InputEventKey:

			var key_event: InputEventKey = (
				event as InputEventKey
			)


			if not key_event.pressed:

				return


			if key_event.echo:

				return


			if (
				key_event.keycode == KEY_ENTER
				or key_event.keycode == KEY_KP_ENTER
			):

				if final_button != null:

					final_button.pressed.emit()


				get_viewport().set_input_as_handled()

				return


		return


	# =====================================================
	# TECLADO
	# =====================================================

	if event is InputEventKey:

		var key_event: InputEventKey = (
			event as InputEventKey
		)


		if not key_event.pressed:

			return


		if key_event.echo:

			return


		match key_event.keycode:

			KEY_1:

				player_selected_color(0)

				get_viewport().set_input_as_handled()


			KEY_2:

				player_selected_color(1)

				get_viewport().set_input_as_handled()


			KEY_3:

				player_selected_color(2)

				get_viewport().set_input_as_handled()


			KEY_4:

				player_selected_color(3)

				get_viewport().set_input_as_handled()


	# =====================================================
	# MOUSE
	# =====================================================

	if event is InputEventMouseButton:

		var mouse_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)


		if (
			mouse_event.button_index
			== MOUSE_BUTTON_LEFT
			and mouse_event.pressed
		):

			if not player_turn:

				return


			if showing_sequence:

				return


			if game_finished:

				return


			var local_mouse: Vector2 = (
				get_local_mouse_position()
			)


			var color_index: int = (
				get_button_at_position(
					local_mouse
				)
			)


			if color_index != -1:

				player_selected_color(
					color_index
				)


				get_viewport().set_input_as_handled()


# =========================================================
# CONTINUAR TUTORIAL
# =========================================================
# CONTINUAR TUTORIAL
# =========================================================

func _on_tutorial_continue() -> void:

	if tutorial_finished:

		return


	tutorial_finished = true

	if tutorial_button != null:

		tutorial_button.disabled = true

	# =====================================================
	# ESCONDE TUTORIAL
	# =====================================================

	if tutorial != null:

		tutorial.visible = false

	# Agora que clicou em COMEÇAR, remove apenas o escurecimento.
	# O BG e a interface do mini-game continuam normalmente visíveis.
	_show_game_visuals_after_tutorial()

	if background != null:

		background.visible = true

	queue_redraw()


	# =====================================================
	# PEQUENA PAUSA
	# =====================================================

	await get_tree().create_timer(
		0.20
	).timeout


	# =====================================================
	# COMEÇA O DESAFIO
	# =====================================================

	await get_tree().create_timer(
		START_DELAY
	).timeout


	start_game()


# =========================================================
# ESTILO DO BOTÃO DO TUTORIAL
# =========================================================

func style_tutorial_button(button: Button) -> void:

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color("#201632")
	normal_style.border_color = Color("#9259C2")
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8

	var hover_style: StyleBoxFlat = StyleBoxFlat.new()
	hover_style.bg_color = Color("#2E1E47")
	hover_style.border_color = Color("#C88BFF")
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8

	var pressed_style: StyleBoxFlat = StyleBoxFlat.new()
	pressed_style.bg_color = Color("#170F24")
	pressed_style.border_color = Color("#9259C2")
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)


# =========================================================
# COMEÇA
# =========================================================

func start_game() -> void:

	# =====================================================
	# NÃO COMEÇA ANTES DO TUTORIAL
	# =====================================================

	if not tutorial_finished:

		return


	result_screen_active = false

	current_round = 0

	sequence.clear()

	player_index = 0

	total_errors = 0

	game_finished = false

	game_started = true

	showing_sequence = false

	player_turn = false

	timer_running = false

	time_left = INITIAL_TIME

	status_text = "OBSERVE A SEQUÊNCIA"

	status_color = WHITE

	hovered_button = -1

	flashing_button = -1


	next_round()


# =========================================================
# PRÓXIMA RODADA
# =========================================================

func next_round() -> void:

	if game_finished:

		return


	# =====================================================
	# NÃO DEIXA PASSAR DE 5/5
	# =====================================================

	if current_round >= TOTAL_ROUNDS:

		win_game()

		return


	# =====================================================
	# NOVA RODADA
	# =====================================================

	current_round += 1


	showing_sequence = true

	player_turn = false

	timer_running = false

	player_index = 0

	hovered_button = -1

	flashing_button = -1


	status_text = "OBSERVE A SEQUÊNCIA"

	status_color = WHITE


	# =====================================================
	# ADICIONA COR
	# =====================================================

	sequence.append(
		randi_range(
			0,
			3
		)
	)


	queue_redraw()


	# =====================================================
	# ESPERA
	# =====================================================

	await get_tree().create_timer(
		1.0
	).timeout


	# =====================================================
	# SEQUÊNCIA
	# =====================================================

	await play_sequence()


	# =====================================================
	# VEZ DO JOGADOR
	# =====================================================

	showing_sequence = false

	player_turn = true

	timer_running = true

	player_index = 0

	hovered_button = -1

	time_left = min(
		time_left,
		MAX_TIME
	)


	status_text = "SUA VEZ! REPITA A SEQUÊNCIA"

	status_color = PURPLE_LIGHT


	queue_redraw()


# =========================================================
# PLAY SEQUENCE
# =========================================================

func play_sequence() -> void:

	hovered_button = -1


	for color_index: int in sequence:

		if game_finished:

			return


		await get_tree().create_timer(
			BETWEEN_COLORS
		).timeout


		await flash_color(
			color_index
		)


		await get_tree().create_timer(
			AFTER_FLASH_DELAY
		).timeout


		hovered_button = -1

		queue_redraw()


# =========================================================
# FLASH
# =========================================================

func flash_color(
	color_index: int
) -> void:

	hovered_button = -1

	flashing_button = color_index

	flash_progress = FLASH_TIME

	queue_redraw()


	await get_tree().create_timer(
		FLASH_TIME
	).timeout


	flashing_button = -1

	flash_progress = 0.0

	hovered_button = -1

	queue_redraw()


# =========================================================
# JOGADOR CLICOU
# =========================================================

func player_selected_color(
	color_index: int
) -> void:

	if not player_turn:

		return


	if showing_sequence:

		return


	if game_finished:

		return


	if result_screen_active:

		return


	if player_index >= sequence.size():

		return


	# =====================================================
	# FEEDBACK
	# =====================================================

	hovered_button = -1

	flashing_button = color_index

	flash_progress = 0.16

	queue_redraw()


	# =====================================================
	# ACERTOU
	# =====================================================

	if color_index == sequence[player_index]:

		player_index += 1


		status_text = "CORRETO!"

		status_color = SUCCESS


		queue_redraw()


		# =================================================
		# TERMINOU A RODADA
		# =================================================

		if player_index >= sequence.size():

			player_turn = false

			timer_running = false

			hovered_button = -1


			# ---------------------------------------------
			# SÓ GANHA TEMPO AQUI
			# ---------------------------------------------

			time_left += CORRECT_TIME_BONUS


			if time_left > MAX_TIME:

				time_left = MAX_TIME


			status_text = "RODADA COMPLETA!  +1s"

			status_color = SUCCESS


			queue_redraw()


			await get_tree().create_timer(
				NEXT_ROUND_DELAY
			).timeout


			next_round()


		return


	# =====================================================
	# ERROU
	# =====================================================

	player_turn = false

	timer_running = false

	hovered_button = -1

	total_errors += 1


	# =====================================================
	# PENALIDADE
	# =====================================================

	time_left -= ERROR_TIME_PENALTY


	if time_left < 0.0:

		time_left = 0.0


	status_text = "ERRO!  -4s"

	status_color = ERROR


	queue_redraw()


	# =====================================================
	# SEM TEMPO
	# =====================================================

	if time_left <= 0.0:

		await get_tree().create_timer(
			0.5
		).timeout


		time_finished()

		return


	# =====================================================
	# REPETE
	# =====================================================

	await get_tree().create_timer(
		ERROR_DELAY
	).timeout


	player_index = 0

	status_text = "OBSERVE NOVAMENTE"

	status_color = WHITE


	queue_redraw()


	await get_tree().create_timer(
		0.6
	).timeout


	showing_sequence = true

	hovered_button = -1


	await play_sequence()


	# =====================================================
	# VOLTA PARA JOGADOR
	# =====================================================

	showing_sequence = false

	player_turn = true

	timer_running = true

	player_index = 0

	hovered_button = -1


	time_left = min(
		time_left,
		MAX_TIME
	)


	status_text = "SUA VEZ! REPITA A SEQUÊNCIA"

	status_color = PURPLE_LIGHT


	queue_redraw()


# =========================================================
# TEMPO ESGOTADO
# =========================================================

func time_finished() -> void:

	if result_screen_active:

		return


	player_turn = false

	showing_sequence = false

	timer_running = false

	game_finished = true

	hovered_button = -1

	flashing_button = -1


	status_text = "TEMPO ESGOTADO!"

	status_color = ERROR


	queue_redraw()


	await get_tree().create_timer(
		0.5
	).timeout


	show_final_screen(
		false
	)


	# =====================================================
	# AVISA O TRIGGER
	# =====================================================

	challenge_failed.emit()


# =========================================================
# VITÓRIA
# =========================================================

func win_game() -> void:

	if game_finished:

		return


	game_finished = true

	player_turn = false

	showing_sequence = false

	timer_running = false

	hovered_button = -1

	flashing_button = -1


	# =====================================================
	# +1500 SCORE
	# =====================================================

	Globals.score += VICTORY_SCORE


	status_text = "MEMÓRIA RECUPERADA!"

	status_color = SUCCESS


	queue_redraw()


	await get_tree().create_timer(
		0.7
	).timeout


	show_final_screen(
		true
	)


	# =====================================================
	# AVISA QUE GANHOU
	# =====================================================

	await get_tree().create_timer(
		0.10
	).timeout


	challenge_completed.emit()


# =========================================================
# DETECÇÃO DOS SETORES
# =========================================================
#
#              [ 1 ]
#             VERMELHO
#
# [ 2 ] AZUL          VERDE [ 3 ]
#
#             AMARELO
#               [ 4 ]
#
# =========================================================

func get_button_at_position(
	position: Vector2
) -> int:

	var center: Vector2 = (
		size / 2.0
	)


	var direction: Vector2 = (
		position - center
	)


	var distance: float = (
		direction.length()
	)


	if distance > WHEEL_RADIUS:

		return -1


	if distance < WHEEL_INNER_RADIUS:

		return -1


	var x: float = direction.x

	var y: float = direction.y


	if abs(y) >= abs(x):

		if y < 0.0:

			return 0


		return 3


	if x < 0.0:

		return 1


	return 2


# =========================================================
# DRAW
# =========================================================

func _draw() -> void:

	# =====================================================
	# DURANTE O TUTORIAL, O MINI-GAME FICA TOTALMENTE
	# ESCONDIDO. SÓ A TELA DE COMO JOGAR APARECE.
	# =====================================================
	if not tutorial_finished:

		return

	var center: Vector2 = (
		size / 2.0
	)


	draw_top_hud()

	draw_memory_wheel(
		center
	)

	draw_status_panel()


# =========================================================
# HUD TOPO
# =========================================================

func draw_top_hud() -> void:

	var width: float = size.x


	# =====================================================
	# RODADA
	# =====================================================

	var round_rect: Rect2 = Rect2(
		32,
		28,
		215,
		104
	)


	draw_panel(
		round_rect
	)


	draw_text_center(
		"RODADA",
		Vector2(
			139.5,
			61
		),
		18,
		PURPLE_LIGHT
	)


	draw_text_center(
		str(current_round)
		+ " / "
		+ str(TOTAL_ROUNDS),
		Vector2(
			139.5,
			108
		),
		30,
		WHITE
	)


	# =====================================================
	# TÍTULO
	# =====================================================

	var title_rect: Rect2 = Rect2(
		350,
		22,
		width - 700,
		108
	)


	draw_panel(
		title_rect
	)


	draw_text_center(
		"DESAFIO DA MEMÓRIA",
		Vector2(
			width / 2.0,
			62
		),
		27,
		WHITE
	)


	draw_text_center(
		status_text,
		Vector2(
			width / 2.0,
			101
		),
		16,
		status_color
	)


	# =====================================================
	# TIMER - MESMO ESTILO DO OUTRO DESAFIO
	# ÍCONE À ESQUERDA + NÚMERO À DIREITA
	# =====================================================

	var timer_width: float = 145.0
	var timer_height: float = 62.0

	var timer_rect: Rect2 = Rect2(
		width - timer_width - 28,
		28,
		timer_width,
		timer_height
	)


	draw_panel(
		timer_rect
	)


	# =====================================================
	# RELÓGIO
	# =====================================================

	var clock_center: Vector2 = Vector2(
		timer_rect.position.x + 26,
		timer_rect.position.y + 31
	)


	var clock_color: Color = PURPLE

	if time_left <= 10.0 and player_turn:
		clock_color = PURPLE_LIGHT

	if time_left <= 5.0 and player_turn:
		clock_color = ERROR


	# Corpo do relógio
	draw_circle(
		clock_center,
		13.0,
		Color("#171226")
	)

	draw_circle(
		clock_center,
		11.0,
		clock_color
	)

	draw_circle(
		clock_center,
		8.0,
		Color("#171226")
	)


	# Ponteiros
	draw_line(
		clock_center,
		clock_center + Vector2(0, -6.0),
		clock_color,
		2.0,
		true
	)

	draw_line(
		clock_center,
		clock_center + Vector2(5.0, 2.0),
		clock_color,
		2.0,
		true
	)

	draw_circle(
		clock_center,
		2.0,
		clock_color
	)


	# =====================================================
	# TEMPO
	# =====================================================

	var seconds: int = int(
		ceil(
			max(
				time_left,
				0.0
			)
		)
	)


	var time_string: String

	if seconds < 10:
		time_string = "00:0" + str(seconds)
	else:
		time_string = "00:" + str(seconds)


	draw_text_center(
		time_string,
		Vector2(
			timer_rect.position.x + 96,
			timer_rect.position.y + 39
		),
		30,
		clock_color
	)


# =========================================================
# GENIUS
# =========================================================

func draw_memory_wheel(
	center: Vector2
) -> void:

	# =====================================================
	# SOMBRA
	# =====================================================

	draw_circle(
		center + Vector2(
			0,
			8
		),
		WHEEL_RADIUS + 22,
		Color(
			0,
			0,
			0,
			0.38
		)
	)


	# =====================================================
	# ANÉIS
	# =====================================================

	draw_circle(
		center,
		WHEEL_RADIUS + 20,
		Color("#06070C")
	)


	draw_circle(
		center,
		WHEEL_RADIUS + 13,
		Color("#22263A")
	)


	draw_circle(
		center,
		WHEEL_RADIUS + 5,
		Color("#080A13")
	)


	# =====================================================
	# SETORES
	# =====================================================

	for index: int in range(4):

		draw_memory_segment(
			center,
			index
		)


	# =====================================================
	# CENTRO
	# =====================================================

	draw_circle(
		center,
		WHEEL_INNER_RADIUS + 14,
		Color("#05060C")
	)


	draw_circle(
		center,
		WHEEL_INNER_RADIUS + 7,
		Color("#252A42")
	)


	draw_circle(
		center,
		WHEEL_INNER_RADIUS,
		Color("#111527")
	)


	draw_fragment(
		center + Vector2(
			0,
			-25
		)
	)


	draw_text_center(
		"MEMÓRIA",
		center + Vector2(
			0,
			8
		),
		18,
		WHITE
	)


	draw_text_center(
		"SUA VEZ",
		center + Vector2(
			0,
			36
		),
		11,
		PURPLE_LIGHT
	)


# =========================================================
# SETOR
# =========================================================

func draw_memory_segment(
	center: Vector2,
	index: int
) -> void:

	var base_color: Color

	var light_color: Color


	match index:

		0:

			base_color = RED
			light_color = RED_LIGHT


		1:

			base_color = BLUE
			light_color = BLUE_LIGHT


		2:

			base_color = GREEN
			light_color = GREEN_LIGHT


		3:

			base_color = YELLOW
			light_color = YELLOW_LIGHT


		_:

			return


	var center_angle: float


	match index:

		0:

			center_angle = -PI / 2.0


		1:

			center_angle = PI


		2:

			center_angle = 0.0


		3:

			center_angle = PI / 2.0


		_:

			return


	var start_angle: float = (
		center_angle
		- PI / 4.0
		+ WHEEL_GAP
	)


	var end_angle: float = (
		center_angle
		+ PI / 4.0
		- WHEEL_GAP
	)


	var active: bool = (
		flashing_button == index
	)


	var hover: bool = (
		hovered_button == index
	)


	var color: Color = base_color


	if active:

		color = light_color

	elif hover:

		color = base_color.lightened(
			0.08
		)


	var offset: Vector2 = Vector2.ZERO


	if hover:

		offset = Vector2(
			cos(center_angle),
			sin(center_angle)
		) * 3.0


	# =====================================================
	# BORDA
	# =====================================================

	var border_points: PackedVector2Array = (
		create_sector_points(
			center + offset,
			WHEEL_INNER_RADIUS + 2,
			WHEEL_RADIUS - 2,
			start_angle,
			end_angle,
			24
		)
	)


	draw_colored_polygon(
		border_points,
		Color("#020309")
	)


	# =====================================================
	# COR
	# =====================================================

	var points: PackedVector2Array = (
		create_sector_points(
			center + offset,
			WHEEL_INNER_RADIUS + 9,
			WHEEL_RADIUS - 12,
			start_angle,
			end_angle,
			24
		)
	)


	draw_colored_polygon(
		points,
		color
	)


	# =====================================================
	# HIGHLIGHT
	# =====================================================

	var highlight_points: PackedVector2Array = (
		create_sector_points(
			center + offset,
			WHEEL_RADIUS - 42,
			WHEEL_RADIUS - 19,
			start_angle + 0.07,
			end_angle - 0.12,
			14
		)
	)


	draw_colored_polygon(
		highlight_points,
		Color(
			1,
			1,
			1,
			0.08
		)
	)


	# =====================================================
	# NÚMERO
	# =====================================================

	var number_position: Vector2 = (
		center
		+ Vector2(
			cos(center_angle),
			sin(center_angle)
		)
		* (
			(
				WHEEL_RADIUS
				+ WHEEL_INNER_RADIUS
			)
			/ 2.0
		)
	)


	draw_number_tag(
		number_position,
		index + 1
	)


	# =====================================================
	# GLOW
	# =====================================================

	if active:

		var glow_center: Vector2 = (
			center
			+ Vector2(
				cos(center_angle),
				sin(center_angle)
			)
			* 125.0
		)


		draw_circle(
			glow_center,
			34.0,
			Color(
				1,
				1,
				1,
				0.16
			)
		)


# =========================================================
# NÚMERO
# =========================================================

func draw_number_tag(
	center: Vector2,
	number: int
) -> void:

	draw_text_center(
		"[ %d ]" % number,
		center + Vector2(
			0,
			6
		),
		15,
		WHITE
	)


# =========================================================
# STATUS
# =========================================================

func draw_status_panel() -> void:

	var width: float = size.x

	var height: float = size.y

	var panel_width: float = 300.0

	var panel_height: float = 132.0


	var rect: Rect2 = Rect2(
		width - panel_width - 32,
		height - panel_height - 32,
		panel_width,
		panel_height
	)


	draw_panel(
		rect
	)


	draw_text_center(
		"STATUS",
		Vector2(
			rect.position.x
			+ rect.size.x / 2.0,
			rect.position.y + 29
		),
		18,
		PURPLE_LIGHT
	)


	draw_text_center(
		"RODADA ATUAL",
		Vector2(
			rect.position.x
			+ rect.size.x / 2.0,
			rect.position.y + 60
		),
		14,
		WHITE
	)


	var spacing: float = 40.0

	var total_width: float = (
		(TOTAL_ROUNDS - 1)
		* spacing
	)


	var start_x: float = (
		rect.position.x
		+ rect.size.x / 2.0
		- total_width / 2.0
	)


	for i: int in range(
		TOTAL_ROUNDS
	):

		var completed: bool = (
			i < current_round - 1
		)


		var current: bool = (
			i == current_round - 1
		)


		var dot_color: Color = Color(
			"#302A3D"
		)


		if completed:

			dot_color = PURPLE


		elif current:

			dot_color = PURPLE_LIGHT


		draw_circle(
			Vector2(
				start_x
				+ i * spacing,
				rect.position.y + 103
			),
			9,
			dot_color
		)


		if completed:

			draw_circle(
				Vector2(
					start_x
					+ i * spacing,
					rect.position.y + 103
				),
				3,
				Color(
					"#E4BBFF"
				)
			)


# =========================================================
# POLÍGONO
# =========================================================

func create_sector_points(
	center: Vector2,
	inner_radius: float,
	outer_radius: float,
	start_angle: float,
	end_angle: float,
	steps: int
) -> PackedVector2Array:

	var points: PackedVector2Array = (
		PackedVector2Array()
	)


	for i: int in range(
		steps + 1
	):

		var t: float = (
			float(i)
			/ float(steps)
		)


		var angle: float = lerp(
			start_angle,
			end_angle,
			t
		)


		points.append(
			center
			+ Vector2(
				cos(angle),
				sin(angle)
			)
			* outer_radius
		)


	for i: int in range(
		steps,
		-1,
		-1
	):

		var t: float = (
			float(i)
			/ float(steps)
		)


		var angle: float = lerp(
			start_angle,
			end_angle,
			t
		)


		points.append(
			center
			+ Vector2(
				cos(angle),
				sin(angle)
			)
			* inner_radius
		)


	return points


# =========================================================
# FRAGMENTO
# =========================================================

func draw_fragment(
	center: Vector2
) -> void:

	var points: PackedVector2Array = (
		PackedVector2Array()
	)


	points.append(
		center + Vector2(
			0,
			-14
		)
	)


	points.append(
		center + Vector2(
			8,
			-2
		)
	)


	points.append(
		center + Vector2(
			4,
			10
		)
	)


	points.append(
		center + Vector2(
			-4,
			10
		)
	)


	points.append(
		center + Vector2(
			-8,
			-2
		)
	)


	draw_colored_polygon(
		points,
		PURPLE
	)


	draw_line(
		center + Vector2(
			0,
			-10
		),
		center + Vector2(
			4,
			-4
		),
		Color(
			0.92,
			0.78,
			1.0,
			0.85
		),
		2.0
	)


# =========================================================
# PAINEL
# =========================================================

func draw_panel(
	rect: Rect2
) -> void:

	# =====================================================
	# PAINEL LIMPO
	# Mesmo estilo visual do timer do Stroop:
	# borda roxa + sombra pequena e suave.
	# Remove a sombra preta deslocada que estava criando
	# aquela faixa grossa em volta das caixas.
	# =====================================================

	var style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	style.bg_color = PANEL_COLOR

	style.border_color = PANEL_BORDER

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	style.shadow_color = Color(
		0,
		0,
		0,
		0.40
	)

	style.shadow_size = 6

	style.shadow_offset = Vector2(
		0,
		3
	)

	draw_style_box(
		style,
		rect
	)


# =========================================================
# TEXTO
# =========================================================

func draw_text_center(
	text_value: String,
	position: Vector2,
	font_size: int,
	color: Color
) -> void:

	var font: Font = ThemeDB.fallback_font


	var text_width: float = (
		font.get_string_size(
			text_value,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		).x
	)


	draw_string(
		font,
		Vector2(
			position.x
			- text_width / 2.0,
			position.y
		),
		text_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)


# =========================================================
# TELA FINAL
# =========================================================

func show_final_screen(
	success: bool
) -> void:

	if result_screen_active:

		return

	# A fonte retrô é aplicada SOMENTE à tela final.
	_get_final_retro_font()


	result_screen_active = true

	result_is_success = success

	player_turn = false

	showing_sequence = false

	timer_running = false

	flashing_button = -1

	hovered_button = -1


	# =====================================================
	# PAUSA DO JOGO
	# =====================================================

	get_tree().paused = true


	# =====================================================
	# CANVAS
	# =====================================================

	final_layer = CanvasLayer.new()

	final_layer.name = (
		"MemoryFinalLayer"
	)

	final_layer.layer = 300

	final_layer.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	get_tree().root.add_child(
		final_layer
	)


	# =====================================================
	# OVERLAY
	# =====================================================

	final_overlay = Control.new()

	final_overlay.name = (
		"MemoryFinalOverlay"
	)

	final_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	final_overlay.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	final_overlay.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	final_layer.add_child(
		final_overlay
	)


	# =====================================================
	# FUNDO
	# =====================================================

	var dark_background: ColorRect = (
		ColorRect.new()
	)


	dark_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	dark_background.color = Color(
		0.035,
		0.015,
		0.07,
		0.68
	)


	dark_background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	final_overlay.add_child(
		dark_background
	)


	# =====================================================
	# PAINEL
	# =====================================================

	final_panel = Panel.new()

	final_panel.name = (
		"MemoryFinalPanel"
	)

	final_panel.anchor_left = 0.5

	final_panel.anchor_top = 0.5

	final_panel.anchor_right = 0.5

	final_panel.anchor_bottom = 0.5

	final_panel.offset_left = -330

	final_panel.offset_top = -190

	final_panel.offset_right = 330

	final_panel.offset_bottom = 190

	final_panel.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	final_panel.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	var panel_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)


	panel_style.bg_color = (
		RETRO_PANEL_COLOR
	)

	panel_style.border_width_left = 3

	panel_style.border_width_top = 3

	panel_style.border_width_right = 3

	panel_style.border_width_bottom = 3

	panel_style.border_color = (
		RETRO_PURPLE
	)

	panel_style.corner_radius_top_left = 12

	panel_style.corner_radius_top_right = 12

	panel_style.corner_radius_bottom_left = 12

	panel_style.corner_radius_bottom_right = 12

	panel_style.shadow_color = Color(
		0.35,
		0.05,
		0.55,
		0.70
	)

	panel_style.shadow_size = 12

	panel_style.shadow_offset = Vector2(
		0,
		5
	)


	final_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)


	final_overlay.add_child(
		final_panel
	)


	# =====================================================
	# LINHA
	# =====================================================

	var top_line: ColorRect = ColorRect.new()

	top_line.position = Vector2(
		28,
		18
	)

	top_line.size = Vector2(
		604,
		2
	)

	top_line.color = RETRO_MAGENTA

	top_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	final_panel.add_child(
		top_line
	)


	# =====================================================
	# DECOR
	# =====================================================

	var left_decor: Label = Label.new()

	left_decor.text = (
		"◆  ◆  ◆"
	)

	left_decor.position = Vector2(
		35,
		42
	)

	left_decor.size = Vector2(
		110,
		24
	)

	left_decor.add_theme_font_size_override(
		"font_size",
		11
	)

	left_decor.add_theme_color_override(
		"font_color",
		RETRO_PURPLE_LIGHT
	)

	left_decor.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_final_retro_font(
		left_decor
	)

	final_panel.add_child(
		left_decor
	)


	var right_decor: Label = Label.new()

	right_decor.text = (
		"◆  ◆  ◆"
	)

	right_decor.position = Vector2(
		520,
		42
	)

	right_decor.size = Vector2(
		110,
		24
	)

	right_decor.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	right_decor.add_theme_font_size_override(
		"font_size",
		11
	)

	right_decor.add_theme_color_override(
		"font_color",
		RETRO_PURPLE_LIGHT
	)

	right_decor.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_final_retro_font(
		right_decor
	)

	final_panel.add_child(
		right_decor
	)


	# =====================================================
	# TÍTULO
	# =====================================================

	var title_label: Label = Label.new()


	if success:

		title_label.text = (
			"✦  DESAFIO 1 CONCLUÍDO!  ✦"
		)

	else:

		title_label.text = (
			"✦  TEMPO ESGOTADO!  ✦"
		)


	title_label.position = Vector2(
		20,
		62
	)

	title_label.size = Vector2(
		620,
		52
	)

	title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	title_label.add_theme_font_size_override(
		"font_size",
		28
	)

	title_label.add_theme_color_override(
		"font_color",
		RETRO_WHITE
	)

	title_label.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	title_label.add_theme_constant_override(
		"outline_size",
		5
	)

	title_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_final_retro_font(
		title_label
	)

	final_panel.add_child(
		title_label
	)


	# =====================================================
	# SUBTÍTULO
	# =====================================================

	var stage_label: Label = Label.new()

	stage_label.text = (
		"DESAFIO DE MEMÓRIA  •  5 RODADAS"
	)

	stage_label.position = Vector2(
		40,
		108
	)

	stage_label.size = Vector2(
		580,
		30
	)

	stage_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	stage_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	stage_label.add_theme_font_size_override(
		"font_size",
		13
	)

	stage_label.add_theme_color_override(
		"font_color",
		RETRO_CYAN
	)

	stage_label.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	stage_label.add_theme_constant_override(
		"outline_size",
		2
	)

	stage_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_final_retro_font(
		stage_label
	)

	final_panel.add_child(
		stage_label
	)


	# =====================================================
	# ERROS
	# Fica acima do SCORE na vitória.
	# Na derrota continua aparecendo normalmente.
	# =====================================================

	var error_label: Label = Label.new()

	error_label.text = (
		"ERROS COMETIDOS      "
		+ str(total_errors)
	)

	error_label.position = Vector2(
		40,
		145
	)

	error_label.size = Vector2(
		580,
		70
	)

	error_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	error_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	error_label.add_theme_font_size_override(
		"font_size",
		22
	)

	error_label.add_theme_color_override(
		"font_color",
		RETRO_WHITE
	)

	error_label.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	error_label.add_theme_constant_override(
		"outline_size",
		3
	)

	error_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	_apply_final_retro_font(
		error_label
	)

	final_panel.add_child(
		error_label
	)


	# =====================================================
	# SCORE
	# Só aparece na vitória.
	# Na derrota NÃO mostra +0 / SCORE.
	# =====================================================

	if success:

		var score_label: Label = Label.new()

		score_label.text = (
			"+1500 SCORE"
		)

		score_label.position = Vector2(
			40,
			205
		)

		score_label.size = Vector2(
			580,
			42
		)

		score_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		score_label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		score_label.add_theme_font_size_override(
			"font_size",
			20
		)

		score_label.add_theme_color_override(
			"font_color",
			RETRO_GOLD
		)

		score_label.add_theme_color_override(
			"font_outline_color",
			RETRO_BLACK
		)

		score_label.add_theme_constant_override(
			"outline_size",
			3
		)

		score_label.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		_apply_final_retro_font(
			score_label
		)

		final_panel.add_child(
			score_label
		)


	# =====================================================
	# MENSAGEM
	# =====================================================

	var message_label: Label = Label.new()


	if success:

		message_label.text = (
			"✦  FRAGMENTO DE MEMÓRIA RECUPERADO  ✦"
		)

	else:

		message_label.text = (
			"VOCÊ PERDEU!"
		)


	message_label.position = Vector2(
		40,
		250
	)

	message_label.size = Vector2(
		580,
		36
	)

	message_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	message_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	message_label.add_theme_font_size_override(
		"font_size",
		16
	)

	message_label.add_theme_color_override(
		"font_color",
		RETRO_GOLD if success else RETRO_MAGENTA
	)

	message_label.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	message_label.add_theme_constant_override(
		"outline_size",
		2
	)

	message_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	_apply_final_retro_font(
		message_label
	)

	final_panel.add_child(
		message_label
	)


	# =====================================================
	# LINHA INFERIOR
	# =====================================================

	var bottom_line: ColorRect = ColorRect.new()

	bottom_line.position = Vector2(
		28,
		276
	)

	bottom_line.size = Vector2(
		604,
		2
	)

	bottom_line.color = RETRO_PURPLE

	bottom_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	final_panel.add_child(
		bottom_line
	)


	# =====================================================
	# BOTÃO
	# =====================================================

	final_button = Button.new()

	final_button.name = (
		"MemoryFinalButton"
	)


	if success:

		final_button.text = (
			"↵   CONTINUAR"
		)

	else:

		final_button.text = (
			"↻   TENTAR NOVAMENTE"
		)


	final_button.position = Vector2(
		175,
		300
	)

	final_button.size = Vector2(
		310,
		48
	)

	final_button.custom_minimum_size = Vector2(
		310,
		48
	)

	final_button.focus_mode = (
		Control.FOCUS_NONE
	)

	final_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	final_button.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	final_button.add_theme_font_size_override(
		"font_size",
		17
	)

	final_button.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	final_button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	final_button.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)

	final_button.add_theme_color_override(
		"font_focus_color",
		Color.WHITE
	)


	_apply_final_retro_font(
		final_button
	)

	style_final_button(
		final_button
	)


	final_button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)


	if success:

		final_button.pressed.connect(
			continue_after_success
		)

	else:

		final_button.pressed.connect(
			restart_after_timeout
		)


	_apply_final_retro_font(
		final_button
	)

	final_panel.add_child(
		final_button
	)


	# =====================================================
	# ANIMAÇÃO
	# =====================================================

	final_panel.modulate = Color(
		1,
		1,
		1,
		0
	)

	final_panel.scale = Vector2(
		0.94,
		0.94
	)


	var tween: Tween = create_tween()

	tween.set_parallel(true)


	tween.tween_property(
		final_panel,
		"modulate",
		Color.WHITE,
		0.20
	)


	tween.tween_property(
		final_panel,
		"scale",
		Vector2(
			1.0,
			1.0
		),
		0.25
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


# =========================================================
# ESTILO BOTÃO
# =========================================================

func style_final_button(
	button: Button
) -> void:

	var normal_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	normal_style.bg_color = Color(
		"#39434B"
	)

	normal_style.border_color = (
		RETRO_PURPLE
	)

	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2

	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8


	var hover_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	hover_style.bg_color = Color(
		"#4B5861"
	)

	hover_style.border_color = (
		RETRO_PURPLE_LIGHT
	)

	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2

	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8


	var pressed_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	pressed_style.bg_color = Color(
		"#293137"
	)

	pressed_style.border_color = (
		RETRO_PURPLE
	)

	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2

	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8


	button.add_theme_stylebox_override(
		"normal",
		normal_style
	)

	button.add_theme_stylebox_override(
		"hover",
		hover_style
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed_style
	)

	button.add_theme_stylebox_override(
		"focus",
		hover_style
	)


# =========================================================
# CONTINUAR
# =========================================================

func continue_after_success() -> void:

	if not result_screen_active:

		return


	challenge_completed.emit()

	close_result_screen()


# =========================================================
# REINICIAR
# =========================================================

func restart_after_timeout() -> void:

	if not result_screen_active:

		return


	close_result_screen()


	await get_tree().create_timer(
		0.2
	).timeout


	current_round = 0

	sequence.clear()

	player_index = 0

	total_errors = 0

	game_finished = false

	game_started = false

	showing_sequence = false

	player_turn = false

	timer_running = false

	time_left = INITIAL_TIME

	status_text = "PREPARE-SE"

	status_color = WHITE

	hovered_button = -1

	flashing_button = -1


	queue_redraw()


	await get_tree().create_timer(
		START_DELAY
	).timeout


	start_game()


# =========================================================
# FECHA TELA FINAL
# =========================================================

func close_result_screen() -> void:

	result_screen_active = false


	get_tree().paused = false


	if is_instance_valid(
		final_layer
	):

		final_layer.queue_free()


	final_layer = null

	final_overlay = null

	final_panel = null

	final_button = null


	queue_redraw()


# =========================================================
# REINICIAR PÚBLICO
# =========================================================

func restart_game() -> void:

	if result_screen_active:

		return


	current_round = 0

	sequence.clear()

	player_index = 0

	total_errors = 0

	showing_sequence = false

	player_turn = false

	game_finished = false

	game_started = false

	timer_running = false

	time_left = INITIAL_TIME

	status_text = "PREPARE-SE"

	status_color = WHITE

	flashing_button = -1

	hovered_button = -1


	queue_redraw()


	await get_tree().create_timer(
		START_DELAY
	).timeout


	start_game()
