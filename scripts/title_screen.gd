extends Control


# ==========================================
# BOTÕES
# ==========================================

@onready var start_btn = $VBoxContainer/start_btn
@onready var credits_btn = $VBoxContainer/credits_btn
@onready var quit_btn = $VBoxContainer/quit_btn


# ==========================================
# READY
# ==========================================

func _ready():

	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# DESATIVA MOUSE
	# ==========================================

	start_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quit_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# ==========================================
	# FOCO PELO TECLADO
	# ==========================================

	start_btn.focus_mode = Control.FOCUS_ALL
	credits_btn.focus_mode = Control.FOCUS_ALL
	quit_btn.focus_mode = Control.FOCUS_ALL


	# ==========================================
	# FOCO INICIAL
	# ==========================================

	start_btn.grab_focus()


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

		if start_btn.has_focus():

			quit_btn.grab_focus()

		elif credits_btn.has_focus():

			start_btn.grab_focus()

		elif quit_btn.has_focus():

			credits_btn.grab_focus()

		else:

			start_btn.grab_focus()


	# ==========================================
	# BAIXO
	# ==========================================

	elif (
		event.keycode == KEY_S
		or event.keycode == KEY_DOWN
	):

		if start_btn.has_focus():

			credits_btn.grab_focus()

		elif credits_btn.has_focus():

			quit_btn.grab_focus()

		elif quit_btn.has_focus():

			start_btn.grab_focus()

		else:

			start_btn.grab_focus()


	# ==========================================
	# ENTER
	# ==========================================

	elif (
		event.keycode == KEY_ENTER
		or event.keycode == KEY_KP_ENTER
	):

		if start_btn.has_focus():

			start_game()

		elif credits_btn.has_focus():

			open_credits()

		elif quit_btn.has_focus():

			quit_game()


# ==========================================
# JOGAR
# ==========================================

func start_game():

	print("==============================")
	print("INICIANDO JOGO")
	print("==============================")


	get_tree().change_scene_to_file(
		"res://levels/world_01.tscn"
	)


# ==========================================
# COMO JOGAR / CRÉDITOS
# ==========================================

func open_credits():

	print("==============================")
	print("ABRINDO CRÉDITOS")
	print("==============================")


	# Por enquanto não troca de cena.
	# Depois criamos a tela de créditos.
	print("Tela de créditos ainda será criada.")


# ==========================================
# SAIR
# ==========================================

func quit_game():

	print("==============================")
	print("FECHANDO JOGO")
	print("==============================")


	get_tree().quit()
