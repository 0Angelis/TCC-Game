extends CanvasLayer


# ==========================================
# CAMADA DO PAUSE
# ==========================================

const PAUSE_LAYER := 1000


# ==========================================
# BOTÕES
# ==========================================

@onready var resume_btn = $menu_houder/resume_btn
@onready var restart_btn = $menu_houder/restart_btn
@onready var quit_btn = $menu_houder/menu_btn
@onready var bg_overlay = $bg_overlay


# ==========================================
# SELEÇÃO MANUAL
# ==========================================

var selected_button: Button = null


# ==========================================
# MODO MOUSE
# ==========================================

var mouse_mode_active := false


# ==========================================
# CORES NORMAIS
# ==========================================

var normal_resume_color: Color = Color.WHITE
var normal_restart_color: Color = Color.WHITE
var normal_quit_color: Color = Color.WHITE


# ==========================================
# CORES DO HOVER
# ==========================================

var hover_resume_color: Color = Color("#7B3FC6")
var hover_restart_color: Color = Color("#7B3FC6")
var hover_quit_color: Color = Color("#7B3FC6")


# ==========================================
# READY
# ==========================================

func _ready():

	# ==========================================
	# FUNCIONA DURANTE O PAUSE
	# ==========================================

	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# CAMADA
	# ==========================================

	layer = PAUSE_LAYER


	# ==========================================
	# ESCONDIDO NO COMEÇO
	# ==========================================

	visible = false


	# ==========================================
	# OVERLAY
	# ==========================================

	bg_overlay.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# ==========================================
	# BOTÕES
	# ==========================================

	resume_btn.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	restart_btn.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	quit_btn.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	resume_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	restart_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	quit_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# ==========================================
	# FOCO AUTOMÁTICO DESATIVADO
	# ==========================================

	resume_btn.focus_mode = (
		Control.FOCUS_NONE
	)

	restart_btn.focus_mode = (
		Control.FOCUS_NONE
	)

	quit_btn.focus_mode = (
		Control.FOCUS_NONE
	)


	# ==========================================
	# CORES NORMAIS
	# ==========================================

	var detected_resume_normal: Color = (
		resume_btn.get_theme_color(
			"font_color"
		)
	)

	var detected_restart_normal: Color = (
		restart_btn.get_theme_color(
			"font_color"
		)
	)

	var detected_quit_normal: Color = (
		quit_btn.get_theme_color(
			"font_color"
		)
	)


	if detected_resume_normal.a > 0.0:

		normal_resume_color = (
			detected_resume_normal
		)


	if detected_restart_normal.a > 0.0:

		normal_restart_color = (
			detected_restart_normal
		)


	if detected_quit_normal.a > 0.0:

		normal_quit_color = (
			detected_quit_normal
		)


	# ==========================================
	# CORES HOVER
	# ==========================================

	var detected_resume_hover: Color = (
		resume_btn.get_theme_color(
			"font_hover_color"
		)
	)

	var detected_restart_hover: Color = (
		restart_btn.get_theme_color(
			"font_hover_color"
		)
	)

	var detected_quit_hover: Color = (
		quit_btn.get_theme_color(
			"font_hover_color"
		)
	)


	if detected_resume_hover.a > 0.0:

		hover_resume_color = (
			detected_resume_hover
		)

	else:

		hover_resume_color = Color(
			"#7B3FC6"
		)


	if detected_restart_hover.a > 0.0:

		hover_restart_color = (
			detected_restart_hover
		)

	else:

		hover_restart_color = Color(
			"#7B3FC6"
		)


	if detected_quit_hover.a > 0.0:

		hover_quit_color = (
			detected_quit_hover
		)

	else:

		hover_quit_color = Color(
			"#7B3FC6"
		)


	# ==========================================
	# SINAIS DOS BOTÕES
	# ==========================================

	if not resume_btn.pressed.is_connected(
		_on_resume_btn_pressed
	):

		resume_btn.pressed.connect(
			_on_resume_btn_pressed
	)


	if not restart_btn.pressed.is_connected(
		_on_restart_btn_pressed
	):

		restart_btn.pressed.connect(
			_on_restart_btn_pressed
	)


	if not quit_btn.pressed.is_connected(
		_on_quit_btn_pressed
	):

		quit_btn.pressed.connect(
			_on_quit_btn_pressed
	)


	# ==========================================
	# MOUSE ENTER
	# ==========================================

	if not resume_btn.mouse_entered.is_connected(
		_on_resume_mouse_entered
	):

		resume_btn.mouse_entered.connect(
			_on_resume_mouse_entered
	)


	if not restart_btn.mouse_entered.is_connected(
		_on_restart_mouse_entered
	):

		restart_btn.mouse_entered.connect(
			_on_restart_mouse_entered
	)


	if not quit_btn.mouse_entered.is_connected(
		_on_quit_mouse_entered
	):

		quit_btn.mouse_entered.connect(
			_on_quit_mouse_entered
	)


	# ==========================================
	# MOUSE EXIT
	# ==========================================

	if not resume_btn.mouse_exited.is_connected(
		_on_button_mouse_exited
	):

		resume_btn.mouse_exited.connect(
			_on_button_mouse_exited
	)


	if not restart_btn.mouse_exited.is_connected(
		_on_button_mouse_exited
	):

		restart_btn.mouse_exited.connect(
			_on_button_mouse_exited
	)


	if not quit_btn.mouse_exited.is_connected(
		_on_button_mouse_exited
	):

		quit_btn.mouse_exited.connect(
			_on_button_mouse_exited
	)


	# ==========================================
	# SELEÇÃO INICIAL
	# ==========================================

	selected_button = resume_btn


# ==========================================
# MARCA INPUT COMO TRATADO
# ==========================================

func _mark_input_handled() -> void:

	if not is_inside_tree():

		return


	var viewport := get_viewport()


	if viewport == null:

		return


	viewport.set_input_as_handled()


# ==========================================
# INPUT
# ==========================================

func _input(event):

	# ==========================================
	# SOMENTE TECLAS
	# ==========================================

	if not (
		event is InputEventKey
	):

		return


	if not event.pressed:

		return


	if event.echo:

		return


	# ==========================================
	# ESC
	# ==========================================

	if event.is_action_pressed(
		"ui_cancel"
	):

		# ======================================
		# SE O MENU DO PAUSE ESTÁ VISÍVEL
		# ESC FECHA O PAUSE
		# ======================================

		if visible:

			_mark_input_handled()

			resume_game()

			return


		# ======================================
		# SE O MENU NÃO ESTÁ VISÍVEL E O JOGO
		# ESTÁ PAUSADO POR OUTRA TELA
		#
		# NÃO FAZ NADA.
		#
		# Isso é importante para a tela final
		# do Stroop não ser afetada.
		# ======================================

		if get_tree().paused:

			return


		# ======================================
		# JOGO NORMAL
		# ESC ABRE O PAUSE
		# ======================================

		_mark_input_handled()

		pause_game()

		return


	# ==========================================
	# A PARTIR DAQUI:
	#
	# SOMENTE O MENU DE PAUSE PODE RECEBER
	# W / S / SETAS / ENTER / ESPAÇO
	# ==========================================

	if not visible:

		return


	# ==========================================
	# O JOGO PRECISA ESTAR PAUSADO
	# ==========================================

	if not get_tree().paused:

		return


	# ==========================================
	# BLOQUEIA RESPOSTAS 1-6 DO STROOP
	# ==========================================

	if (
		event.keycode == KEY_1
		or event.keycode == KEY_2
		or event.keycode == KEY_3
		or event.keycode == KEY_4
		or event.keycode == KEY_5
		or event.keycode == KEY_6
	):

		_mark_input_handled()

		return


	# ==========================================
	# SPACE NÃO CONFIRMA
	# ==========================================

	if event.keycode == KEY_SPACE:

		_mark_input_handled()

		return


	# ==========================================
	# CIMA
	# ==========================================

	if (
		event.keycode == KEY_UP
		or event.keycode == KEY_W
	):

		_mark_input_handled()

		mouse_mode_active = false


		if selected_button == resume_btn:

			selected_button = quit_btn

		elif selected_button == restart_btn:

			selected_button = resume_btn

		elif selected_button == quit_btn:

			selected_button = restart_btn

		else:

			selected_button = resume_btn


		_apply_keyboard_visual()

		return


	# ==========================================
	# BAIXO
	# ==========================================

	if (
		event.keycode == KEY_DOWN
		or event.keycode == KEY_S
	):

		_mark_input_handled()

		mouse_mode_active = false


		if selected_button == resume_btn:

			selected_button = restart_btn

		elif selected_button == restart_btn:

			selected_button = quit_btn

		elif selected_button == quit_btn:

			selected_button = resume_btn

		else:

			selected_button = resume_btn


		_apply_keyboard_visual()

		return


	# ==========================================
	# ENTER
	# ==========================================

	if (
		event.keycode == KEY_ENTER
		or event.keycode == KEY_KP_ENTER
	):

		_mark_input_handled()


		if selected_button == resume_btn:

			resume_game()

		elif selected_button == restart_btn:

			restart_game()

		elif selected_button == quit_btn:

			quit_game()


		return


# ==========================================
# VISUAL DO TECLADO
# ==========================================

func _apply_keyboard_visual():

	if mouse_mode_active:

		return


	_clear_all_keyboard_colors()


	if selected_button == resume_btn:

		resume_btn.add_theme_color_override(
			"font_color",
			hover_resume_color
		)


	elif selected_button == restart_btn:

		restart_btn.add_theme_color_override(
			"font_color",
			hover_restart_color
		)


	elif selected_button == quit_btn:

		quit_btn.add_theme_color_override(
			"font_color",
			hover_quit_color
		)


# ==========================================
# REMOVE COR DO TECLADO
# ==========================================

func _clear_all_keyboard_colors():

	resume_btn.add_theme_color_override(
		"font_color",
		normal_resume_color
	)

	restart_btn.add_theme_color_override(
		"font_color",
		normal_restart_color
	)

	quit_btn.add_theme_color_override(
		"font_color",
		normal_quit_color
	)


# ==========================================
# MOUSE - RESUME
# ==========================================

func _on_resume_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE - RESTART
# ==========================================

func _on_restart_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE - MENU
# ==========================================

func _on_quit_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE SAIU
# ==========================================

func _on_button_mouse_exited():

	mouse_mode_active = false

	_apply_keyboard_visual()


# ==========================================
# PAUSAR
# ==========================================

func pause_game():

	print(
		"=============================="
	)

	print(
		"JOGO PAUSADO"
	)

	print(
		"=============================="
	)


	mouse_mode_active = false


	visible = true


	layer = PAUSE_LAYER


	get_tree().paused = true


	# ==========================================
	# COMEÇA NO CONTINUAR
	# ==========================================

	selected_button = resume_btn


	_apply_keyboard_visual()


# ==========================================
# CONTINUAR
# ==========================================

func resume_game():

	print(
		"=============================="
	)

	print(
		"JOGO CONTINUOU"
	)

	print(
		"=============================="
	)


	get_tree().paused = false


	visible = false


# ==========================================
# FECHAR DIÁLOGO
# ==========================================

func close_dialog():

	if DialogManager.is_message_active:

		print(
			"FECHANDO DIÁLOGO ANTES DO RESTART"
		)

		DialogManager.close_message()


# ==========================================
# RESTART
# ==========================================

func restart_game():

	print(
		"=============================="
	)

	print(
		"RESTART PELO PAUSE"
	)

	print(
		"=============================="
	)


	close_dialog()


	get_tree().paused = false


	visible = false


	# ==========================================
	# RESET
	# ==========================================

	Globals.coins = 0
	Globals.score = 0

	Globals.level_coins = 0
	Globals.level_score = 0

	Globals.raciocinio_fragments = 0
	Globals.atencao_fragments = 0
	Globals.memoria_fragments = 0


	print(
		"MOEDAS: ",
		Globals.coins
	)

	print(
		"SCORE: ",
		Globals.score
	)

	print(
		"RACIOCÍNIO: ",
		Globals.raciocinio_fragments
	)

	print(
		"ATENÇÃO: ",
		Globals.atencao_fragments
	)

	print(
		"MEMÓRIA: ",
		Globals.memoria_fragments
	)


	await get_tree().process_frame


	get_tree().reload_current_scene()


# ==========================================
# MENU INICIAL
# ==========================================

func quit_game():

	print(
		"=============================="
	)

	print(
		"VOLTANDO PARA O MENU"
	)

	print(
		"=============================="
	)


	close_dialog()


	get_tree().paused = false


	visible = false


	await get_tree().process_frame


	get_tree().change_scene_to_file(
		"res://scenes/title_screen.tscn"
	)


# ==========================================
# BOTÃO RESUME
# ==========================================

func _on_resume_btn_pressed():

	selected_button = resume_btn

	mouse_mode_active = false

	_apply_keyboard_visual()

	resume_game()


# ==========================================
# BOTÃO RESTART
# ==========================================

func _on_restart_btn_pressed():

	selected_button = restart_btn

	mouse_mode_active = false

	_apply_keyboard_visual()

	restart_game()


# ==========================================
# BOTÃO MENU
# ==========================================

func _on_quit_btn_pressed():

	selected_button = quit_btn

	mouse_mode_active = false

	_apply_keyboard_visual()

	quit_game()
