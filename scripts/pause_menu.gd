extends CanvasLayer


# ==========================================
# BOTÕES
# ==========================================

@onready var resume_btn = $menu_houder/resume_btn
@onready var restart_btn = $menu_houder/restart_btn
@onready var menu_btn = $menu_houder/menu_btn


# ==========================================
# READY
# ==========================================

func _ready():

	# Continua funcionando enquanto o jogo está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false


	# ==========================================
	# DESATIVA MOUSE NOS BOTÕES
	# ==========================================

	resume_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	restart_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# ==========================================
	# FOCO PELO TECLADO
	# ==========================================

	resume_btn.focus_mode = Control.FOCUS_ALL
	restart_btn.focus_mode = Control.FOCUS_ALL
	menu_btn.focus_mode = Control.FOCUS_ALL


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

		return


	# ==========================================
	# SÓ PROCESSA NAVEGAÇÃO SE ESTIVER PAUSADO
	# ==========================================

	if not get_tree().paused:
		return


	if event is InputEventKey and event.pressed:


		# ==========================================
		# CIMA
		# ==========================================

		if event.keycode == KEY_W or event.keycode == KEY_UP:

			if resume_btn.has_focus():

				menu_btn.grab_focus()

			elif restart_btn.has_focus():

				resume_btn.grab_focus()

			elif menu_btn.has_focus():

				restart_btn.grab_focus()

			else:

				resume_btn.grab_focus()


		# ==========================================
		# BAIXO
		# ==========================================

		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:

			if resume_btn.has_focus():

				restart_btn.grab_focus()

			elif restart_btn.has_focus():

				menu_btn.grab_focus()

			elif menu_btn.has_focus():

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

			elif menu_btn.has_focus():

				go_to_menu()


# ==========================================
# ABRIR PAUSE
# ==========================================

func pause_game():

	print("JOGO PAUSADO")

	visible = true

	get_tree().paused = true

	resume_btn.grab_focus()


# ==========================================
# CONTINUAR
# ==========================================

func resume_game():

	print("JOGO CONTINUANDO")

	get_tree().paused = false

	visible = false


# ==========================================
# RESTART
# ==========================================

func restart_game():

	print("==============================")
	print("REINICIANDO FASE")
	print("==============================")


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
	print("FRAGMENTOS: ", Globals.raciocinio_fragments)


	# ==========================================
	# DESPAUSA
	# ==========================================

	get_tree().paused = false

	visible = false


	# ==========================================
	# RECARREGA A FASE
	# ==========================================

	get_tree().reload_current_scene()


# ==========================================
# VOLTAR PARA O MENU
# ==========================================

func go_to_menu():

	print("==============================")
	print("VOLTANDO PARA O MENU")
	print("==============================")


	get_tree().paused = false

	visible = false


	get_tree().change_scene_to_file(
		"res://scenes/title_screen.tscn"
	)
