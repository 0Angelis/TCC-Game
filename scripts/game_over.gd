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

	# Continua funcionando normalmente
	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# DESATIVA MOUSE
	# ==========================================

	restart_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# ==========================================
	# FOCO PELO TECLADO
	# ==========================================

	restart_btn.focus_mode = Control.FOCUS_ALL
	menu_btn.focus_mode = Control.FOCUS_ALL


	# Começa no Restart
	restart_btn.grab_focus()


# ==========================================
# INPUT DO TECLADO
# ==========================================

func _unhandled_input(event):


	if not (event is InputEventKey):
		return


	if not event.pressed:
		return


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
# RESTART
# ==========================================

func restart_game():

	print("==============================")
	print("REINICIANDO JOGO")
	print("==============================")


	# ==========================================
	# RESET DOS DADOS
	# ==========================================

	Globals.coins = 0
	Globals.score = 0

	Globals.level_coins = 0
	Globals.level_score = 0

	Globals.raciocinio_fragments = 0
	Globals.player_life = 5


	print("MOEDAS: ", Globals.coins)
	print("SCORE: ", Globals.score)
	print("FRAGMENTOS: ", Globals.raciocinio_fragments)
	print("VIDAS: ", Globals.player_life)


	# ==========================================
	# DESPAUSA
	# ==========================================

	get_tree().paused = false


	# ==========================================
	# VOLTA PARA A FASE 1
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


	get_tree().paused = false


	get_tree().change_scene_to_file(
		"res://scenes/title_screen.tscn"
	)
