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

	# ==========================================
	# PROCESSAMENTO
	# ==========================================

	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# CONFIGURAÇÃO DOS BOTÕES
	# ==========================================

	start_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	credits_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS


	start_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	quit_btn.mouse_filter = Control.MOUSE_FILTER_STOP


	start_btn.focus_mode = Control.FOCUS_ALL
	credits_btn.focus_mode = Control.FOCUS_ALL
	quit_btn.focus_mode = Control.FOCUS_ALL


	# ==========================================
	# CONECTA OS BOTÕES
	# ==========================================

	if not start_btn.pressed.is_connected(
		_on_start_btn_pressed
	):

		start_btn.pressed.connect(
			_on_start_btn_pressed
		)


	if not credits_btn.pressed.is_connected(
		_on_credits_btn_pressed
	):

		credits_btn.pressed.connect(
			_on_credits_btn_pressed
		)


	if not quit_btn.pressed.is_connected(
		_on_quit_btn_pressed
	):

		quit_btn.pressed.connect(
			_on_quit_btn_pressed
		)


	# ==========================================
	# FOCO INICIAL
	# ==========================================

	start_btn.grab_focus()


# ==========================================
# CONTROLE DO TECLADO
# ==========================================

func _unhandled_input(event):

	if event is InputEventKey and event.pressed:

		# ==========================================
		# CIMA
		# ==========================================

		if event.keycode == KEY_W or event.keycode == KEY_UP:

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

		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:

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


	# POR ENQUANTO
	# apenas mostra no console.
	# Depois criamos a tela de créditos.

	print("Tela de créditos ainda será criada.")


# ==========================================
# SAIR
# ==========================================

func quit_game():

	print("==============================")
	print("SAINDO DO JOGO")
	print("==============================")


	get_tree().quit()


# ==========================================
# BOTÃO JOGAR
# ==========================================

func _on_start_btn_pressed():

	start_game()


# ==========================================
# BOTÃO CRÉDITOS
# ==========================================

func _on_credits_btn_pressed():

	open_credits()


# ==========================================
# BOTÃO SAIR
# ==========================================

func _on_quit_btn_pressed():

	quit_game()
