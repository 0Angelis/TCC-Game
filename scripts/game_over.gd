extends Control


# ==========================================
# BOTÕES
# ==========================================

@onready var restart_btn = $VBoxContainer/Restart_Btn
@onready var menu_btn = $VBoxContainer/menu_Btn


# ==========================================
# BOTÃO SELECIONADO PELO TECLADO
# ==========================================

var selected_button: Button = null


# ==========================================
# MODO MOUSE
# ==========================================

var mouse_mode_active := false


# ==========================================
# CORES NORMAIS
# ==========================================

var normal_restart_color: Color = Color.WHITE
var normal_menu_color: Color = Color.WHITE


# ==========================================
# CORES DO HOVER
# ==========================================

var hover_restart_color: Color = Color("#7B3FC6")
var hover_menu_color: Color = Color("#7B3FC6")


# ==========================================
# READY
# ==========================================

func _ready():

	# ==========================================
	# PERMITE GAME OVER FUNCIONAR PAUSADO
	# ==========================================

	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# BOTÕES SEM FOCO VISUAL AUTOMÁTICO
	# ==========================================

	restart_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.focus_mode = Control.FOCUS_NONE


	# ==========================================
	# MOUSE
	# ==========================================

	restart_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	menu_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# ==========================================
	# PROCESS MODE DOS BOTÕES
	# ==========================================

	restart_btn.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	menu_btn.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	# ==========================================
	# PEGA COR NORMAL
	# ==========================================

	var detected_restart_normal: Color = (
		restart_btn.get_theme_color(
			"font_color"
		)
	)

	var detected_menu_normal: Color = (
		menu_btn.get_theme_color(
			"font_color"
		)
	)


	if detected_restart_normal.a > 0.0:

		normal_restart_color = (
			detected_restart_normal
		)

	else:

		normal_restart_color = Color.WHITE


	if detected_menu_normal.a > 0.0:

		normal_menu_color = (
			detected_menu_normal
		)

	else:

		normal_menu_color = Color.WHITE


	# ==========================================
	# PEGA COR REAL DO HOVER
	# ==========================================

	var detected_restart_hover: Color = (
		restart_btn.get_theme_color(
			"font_hover_color"
		)
	)

	var detected_menu_hover: Color = (
		menu_btn.get_theme_color(
			"font_hover_color"
		)
	)


	if detected_restart_hover.a > 0.0:

		hover_restart_color = (
			detected_restart_hover
		)

	else:

		hover_restart_color = Color(
			"#7B3FC6"
		)


	if detected_menu_hover.a > 0.0:

		hover_menu_color = (
			detected_menu_hover
		)

	else:

		hover_menu_color = Color(
			"#7B3FC6"
		)


	# ==========================================
	# CLIQUE RESTART
	# ==========================================

	if not restart_btn.pressed.is_connected(
		_on_restart_btn_pressed
	):

		restart_btn.pressed.connect(
			_on_restart_btn_pressed
		)


	# ==========================================
	# CLIQUE MENU
	# ==========================================

	if not menu_btn.pressed.is_connected(
		_on_menu_btn_pressed
	):

		menu_btn.pressed.connect(
			_on_menu_btn_pressed
		)


	# ==========================================
	# MOUSE ENTER - RESTART
	# ==========================================

	if not restart_btn.mouse_entered.is_connected(
		_on_restart_mouse_entered
	):

		restart_btn.mouse_entered.connect(
			_on_restart_mouse_entered
		)


	# ==========================================
	# MOUSE ENTER - MENU
	# ==========================================

	if not menu_btn.mouse_entered.is_connected(
		_on_menu_mouse_entered
	):

		menu_btn.mouse_entered.connect(
			_on_menu_mouse_entered
		)


	# ==========================================
	# MOUSE EXIT
	# ==========================================

	if not restart_btn.mouse_exited.is_connected(
		_on_button_mouse_exited
	):

		restart_btn.mouse_exited.connect(
			_on_button_mouse_exited
		)


	if not menu_btn.mouse_exited.is_connected(
		_on_button_mouse_exited
	):

		menu_btn.mouse_exited.connect(
			_on_button_mouse_exited
		)


	# ==========================================
	# SELEÇÃO INICIAL
	# ==========================================

	selected_button = restart_btn


	_apply_keyboard_visual()


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
# INPUT DO TECLADO
# ==========================================

func _input(event):

	# ==========================================
	# PRECISA SER TECLA
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
	# CIMA
	# ==========================================

	if (
		event.keycode == KEY_W
		or event.keycode == KEY_UP
	):

		_mark_input_handled()


		# ======================================
		# MUDA PARA O OUTRO BOTÃO
		# ======================================

		if selected_button == restart_btn:

			selected_button = menu_btn

		elif selected_button == menu_btn:

			selected_button = restart_btn

		else:

			selected_button = restart_btn


		# ======================================
		# TECLADO VOLTA A TER PRIORIDADE
		# ======================================

		mouse_mode_active = false


		_apply_keyboard_visual()

		return


	# ==========================================
	# BAIXO
	# ==========================================

	if (
		event.keycode == KEY_S
		or event.keycode == KEY_DOWN
	):

		_mark_input_handled()


		# ======================================
		# MUDA PARA O OUTRO BOTÃO
		# ======================================

		if selected_button == restart_btn:

			selected_button = menu_btn

		elif selected_button == menu_btn:

			selected_button = restart_btn

		else:

			selected_button = restart_btn


		# ======================================
		# TECLADO VOLTA A TER PRIORIDADE
		# ======================================

		mouse_mode_active = false


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


		if selected_button == restart_btn:

			restart_game()

		elif selected_button == menu_btn:

			go_to_menu()

		return


# ==========================================
# APLICA COR DO TECLADO
# ==========================================

func _apply_keyboard_visual():

	# ==========================================
	# MOUSE ESTÁ ATIVO
	# ==========================================

	if mouse_mode_active:

		return


	# ==========================================
	# TODOS VOLTAM AO NORMAL
	# ==========================================

	_clear_all_keyboard_colors()


	# ==========================================
	# RESTART
	# ==========================================

	if selected_button == restart_btn:

		restart_btn.add_theme_color_override(
			"font_color",
			hover_restart_color
		)


	# ==========================================
	# MENU
	# ==========================================

	elif selected_button == menu_btn:

		menu_btn.add_theme_color_override(
			"font_color",
			hover_menu_color
		)


# ==========================================
# REMOVE COR DO TECLADO
# ==========================================

func _clear_all_keyboard_colors():

	restart_btn.add_theme_color_override(
		"font_color",
		normal_restart_color
	)

	menu_btn.add_theme_color_override(
		"font_color",
		normal_menu_color
	)


# ==========================================
# MOUSE ENTROU - RESTART
# ==========================================

func _on_restart_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE ENTROU - MENU
# ==========================================

func _on_menu_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE SAIU
# ==========================================

func _on_button_mouse_exited():

	if not is_inside_tree():

		return


	# ==========================================
	# VOLTA PARA O TECLADO
	# ==========================================

	mouse_mode_active = false

	_apply_keyboard_visual()


# ==========================================
# FECHA DIÁLOGO
# ==========================================

func close_dialog():

	if DialogManager.is_message_active:

		print(
			"FECHANDO DIÁLOGO ANTES DO RESTART"
		)

		DialogManager.close_message()


# ==========================================
# RESTART DO JOGO
# ==========================================

func restart_game():

	print(
		"=============================="
	)

	print(
		"REINICIANDO FASE"
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


	# ==========================================
	# PEGA FASE SALVA
	# ==========================================

	var restart_scene := ""


	if get_tree().has_meta(
		"restart_scene"
	):

		restart_scene = (
			get_tree().get_meta(
				"restart_scene"
			)
		)


		print(
			"FASE SALVA PARA RESTART: ",
			restart_scene
		)


	else:

		restart_scene = (
			"res://levels/world_00.tscn"
		)


		print(
			"NENHUMA FASE SALVA."
		)

		print(
			"USANDO WORLD_00."
		)


	# ==========================================
	# RESET DOS DADOS
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


	# ==========================================
	# ESPERA FRAME
	# ==========================================

	await get_tree().process_frame


	# ==========================================
	# REINICIA A FASE
	# ==========================================

	get_tree().change_scene_to_file(
		restart_scene
	)


# ==========================================
# VOLTAR PARA O MENU
# ==========================================

func go_to_menu():

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


	# ==========================================
	# ESPERA FRAME
	# ==========================================

	await get_tree().process_frame


	# ==========================================
	# MENU
	# ==========================================

	get_tree().change_scene_to_file(
		"res://scenes/title_screen.tscn"
	)


# ==========================================
# CLIQUE RESTART
# ==========================================

func _on_restart_btn_pressed():

	selected_button = restart_btn

	mouse_mode_active = false

	_apply_keyboard_visual()

	restart_game()


# ==========================================
# CLIQUE MENU
# ==========================================

func _on_menu_btn_pressed():

	selected_button = menu_btn

	mouse_mode_active = false

	_apply_keyboard_visual()

	go_to_menu()
