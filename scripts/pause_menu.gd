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
# READY
# ==========================================

func _ready():

	# ==========================================
	# CONTINUA FUNCIONANDO DURANTE O PAUSE
	# ==========================================

	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# CAMADA ACIMA DO STROOP
	# ==========================================

	layer = PAUSE_LAYER


	# ==========================================
	# COMEÇA ESCONDIDO
	# ==========================================

	visible = false


	# ==========================================
	# OVERLAY
	# ==========================================

	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# ==========================================
	# BOTÕES
	# ==========================================

	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS

	resume_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	quit_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	resume_btn.focus_mode = Control.FOCUS_ALL
	restart_btn.focus_mode = Control.FOCUS_ALL
	quit_btn.focus_mode = Control.FOCUS_ALL


	# ==========================================
	# SINAIS
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
# INPUT
# ==========================================

func _unhandled_input(event):

	# ==========================================
	# ESC
	# ==========================================

	if event.is_action_pressed("ui_cancel"):

		if get_tree().paused:

			resume_game()

		else:

			pause_game()

		get_viewport().set_input_as_handled()

		return


	# ==========================================
	# CONTROLES DO MENU
	# ==========================================

	if get_tree().paused and event is InputEventKey and event.pressed:

		# ==========================================
		# CIMA
		# ==========================================

		if (
			event.keycode == KEY_W
			or event.keycode == KEY_UP
		):

			if resume_btn.has_focus():

				quit_btn.grab_focus()

			elif restart_btn.has_focus():

				resume_btn.grab_focus()

			elif quit_btn.has_focus():

				restart_btn.grab_focus()

			else:

				resume_btn.grab_focus()


		# ==========================================
		# BAIXO
		# ==========================================

		elif (
			event.keycode == KEY_S
			or event.keycode == KEY_DOWN
		):

			if resume_btn.has_focus():

				restart_btn.grab_focus()

			elif restart_btn.has_focus():

				quit_btn.grab_focus()

			elif quit_btn.has_focus():

				resume_btn.grab_focus()

			else:

				resume_btn.grab_focus()


		# ==========================================
		# ENTER
		# ==========================================

		elif (
			event.keycode == KEY_ENTER
			or event.keycode == KEY_KP_ENTER
		):

			if resume_btn.has_focus():

				resume_game()

			elif restart_btn.has_focus():

				restart_game()

			elif quit_btn.has_focus():

				quit_game()


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


	# ==========================================
	# PRIMEIRO MOSTRA O MENU
	# ==========================================

	visible = true


	# ==========================================
	# GARANTE QUE ESTÁ NA FRENTE DO STROOP
	# ==========================================

	layer = PAUSE_LAYER


	# ==========================================
	# DEPOIS PAUSA O JOGO
	# ==========================================

	get_tree().paused = true


	# ==========================================
	# FOCO
	# ==========================================

	resume_btn.grab_focus()


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


	# ==========================================
	# DESPAUSA
	# ==========================================

	get_tree().paused = false


	# ==========================================
	# ESCONDE MENU
	# ==========================================

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


	# ==========================================
	# FECHA WARNING / DIÁLOGO
	# ==========================================

	close_dialog()


	# ==========================================
	# DESPAUSA
	# ==========================================

	get_tree().paused = false

	visible = false


	# ==========================================
	# RESET DOS DADOS
	# ==========================================

	Globals.coins = 0
	Globals.score = 0

	Globals.level_coins = 0
	Globals.level_score = 0

	Globals.raciocinio_fragments = 0


	print(
		"MOEDAS: ",
		Globals.coins
	)

	print(
		"SCORE: ",
		Globals.score
	)

	print(
		"FRAGMENTOS: ",
		Globals.raciocinio_fragments
	)


	# ==========================================
	# ESPERA UM FRAME
	# ==========================================

	await get_tree().process_frame


	# ==========================================
	# RECARREGA CENA
	# ==========================================

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


	# ==========================================
	# FECHA WARNING / DIÁLOGO
	# ==========================================

	close_dialog()


	# ==========================================
	# DESPAUSA
	# ==========================================

	get_tree().paused = false

	visible = false


	# ==========================================
	# ESPERA UM FRAME
	# ==========================================

	await get_tree().process_frame


	# ==========================================
	# TELA INICIAL
	# ==========================================

	get_tree().change_scene_to_file(
		"res://scenes/title_screen.tscn"
	)


# ==========================================
# BOTÃO RESUME
# ==========================================

func _on_resume_btn_pressed():

	resume_game()


# ==========================================
# BOTÃO RESTART
# ==========================================

func _on_restart_btn_pressed():

	restart_game()


# ==========================================
# BOTÃO MENU
# ==========================================

func _on_quit_btn_pressed():

	quit_game()
