extends Control


# ==========================================
# BOTÕES
# ==========================================

@onready var restart_btn = $VBoxContainer/Restart_Btn
@onready var menu_btn = $VBoxContainer/menu_Btn


# ==========================================
# READY
# ==========================================

func _ready():

	# Permite que o Game Over funcione
	# mesmo se o jogo estiver pausado
	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# CONFIGURAÇÃO DOS BOTÕES
	# ==========================================

	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS

	restart_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	restart_btn.focus_mode = Control.FOCUS_ALL
	menu_btn.focus_mode = Control.FOCUS_ALL


	# ==========================================
	# CONECTA RESTART
	# ==========================================

	if not restart_btn.pressed.is_connected(
		_on_restart_btn_pressed
	):

		restart_btn.pressed.connect(
			_on_restart_btn_pressed
		)


	# ==========================================
	# CONECTA MENU
	# ==========================================

	if not menu_btn.pressed.is_connected(
		_on_menu_btn_pressed
	):

		menu_btn.pressed.connect(
			_on_menu_btn_pressed
		)


	# ==========================================
	# FOCO INICIAL
	# ==========================================

	restart_btn.grab_focus()


# ==========================================
# INPUT DO TECLADO
# ==========================================

func _unhandled_input(event):

	if event is InputEventKey and event.pressed:

		# ==========================================
		# CIMA
		# ==========================================

		if (
			event.keycode == KEY_W
			or event.keycode == KEY_UP
		):

			if restart_btn.has_focus():

				menu_btn.grab_focus()

			elif menu_btn.has_focus():

				restart_btn.grab_focus()

			else:

				restart_btn.grab_focus()


		# ==========================================
		# BAIXO
		# ==========================================

		elif (
			event.keycode == KEY_S
			or event.keycode == KEY_DOWN
		):

			if restart_btn.has_focus():

				menu_btn.grab_focus()

			elif menu_btn.has_focus():

				restart_btn.grab_focus()

			else:

				restart_btn.grab_focus()


		# ==========================================
		# ENTER
		# ==========================================

		elif (
			event.keycode == KEY_ENTER
			or event.keycode == KEY_KP_ENTER
		):

			if restart_btn.has_focus():

				restart_game()

			elif menu_btn.has_focus():

				go_to_menu()


# ==========================================
# FECHA DIÁLOGO
# ==========================================

func close_dialog():

	if DialogManager.is_message_active:

		print("FECHANDO DIÁLOGO ANTES DO RESTART")

		DialogManager.close_message()


# ==========================================
# RESTART DO JOGO
# ==========================================

func restart_game():

	print("==============================")
	print("REINICIANDO JOGO")
	print("==============================")


	# ==========================================
	# FECHA QUALQUER WARNING / DIÁLOGO
	# ==========================================

	close_dialog()


	# ==========================================
	# GARANTE QUE NÃO ESTÁ PAUSADO
	# ==========================================

	get_tree().paused = false


	# ==========================================
	# RESET DOS DADOS
	# ==========================================

	Globals.coins = 0
	Globals.score = 0

	Globals.level_coins = 0
	Globals.level_score = 0

	Globals.raciocinio_fragments = 0


	print("MOEDAS: ", Globals.coins)
	print("SCORE: ", Globals.score)
	print(
		"FRAGMENTOS: ",
		Globals.raciocinio_fragments
	)


	# ==========================================
	# GARANTE QUE A CAIXA SUMIU
	# ==========================================

	await get_tree().process_frame


	# ==========================================
	# VOLTA PARA A PRIMEIRA FASE
	# ==========================================

	get_tree().change_scene_to_file(
		"res://levels/world_01.tscn"
	)


# ==========================================
# VOLTAR PARA O MENU
# ==========================================

func go_to_menu():

	print("==============================")
	print("VOLTANDO PARA O MENU")
	print("==============================")


	# ==========================================
	# FECHA QUALQUER WARNING / DIÁLOGO
	# ==========================================

	close_dialog()


	# ==========================================
	# GARANTE QUE NÃO ESTÁ PAUSADO
	# ==========================================

	get_tree().paused = false


	# ==========================================
	# ESPERA A CAIXA FECHAR
	# ==========================================

	await get_tree().process_frame


	# ==========================================
	# VOLTA PARA A TELA INICIAL
	# ==========================================

	get_tree().change_scene_to_file(
		"res://scenes/title_screen.tscn"
	)


# ==========================================
# BOTÃO RESTART
# ==========================================

func _on_restart_btn_pressed():

	restart_game()


# ==========================================
# BOTÃO MENU
# ==========================================

func _on_menu_btn_pressed():

	go_to_menu()
