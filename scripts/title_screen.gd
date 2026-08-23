extends Control


# ==========================================
# BOTÕES
# ==========================================

@onready var start_btn = $VBoxContainer/start_btn
@onready var credits_btn = $VBoxContainer/credits_btn
@onready var quit_btn = $VBoxContainer/quit_btn


# ==========================================
# BOTÃO SELECIONADO PELO TECLADO
# ==========================================

var selected_button: Button = null


# ==========================================
# MOUSE ESTÁ SENDO USADO?
# ==========================================

var mouse_mode_active := false


# ==========================================
# CORES
# ==========================================

var normal_text_color: Color = Color.WHITE

var hover_text_color: Color = Color("#7B3FC6")


# ==========================================
# READY
# ==========================================

func _ready():

	process_mode = Node.PROCESS_MODE_ALWAYS


	# ==========================================
	# MOUSE
	# ==========================================

	start_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	credits_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	quit_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# ==========================================
	# FOCO PELO TECLADO
	# ==========================================

	start_btn.focus_mode = (
		Control.FOCUS_ALL
	)

	credits_btn.focus_mode = (
		Control.FOCUS_ALL
	)

	quit_btn.focus_mode = (
		Control.FOCUS_ALL
	)


	# ==========================================
	# REMOVE QUALQUER CAIXA DE FOCO
	# ==========================================

	start_btn.add_theme_stylebox_override(
		"focus",
		StyleBoxEmpty.new()
	)

	credits_btn.add_theme_stylebox_override(
		"focus",
		StyleBoxEmpty.new()
	)

	quit_btn.add_theme_stylebox_override(
		"focus",
		StyleBoxEmpty.new()
	)


	# ==========================================
	# PEGA A COR REAL DO HOVER
	# ==========================================

	var detected_hover: Color = (
		start_btn.get_theme_color(
			"font_hover_color"
		)
	)


	if detected_hover.a > 0.0:

		hover_text_color = detected_hover

	else:

		hover_text_color = Color(
			"#7B3FC6"
		)


	# ==========================================
	# PEGA A COR NORMAL
	# ==========================================

	var detected_normal: Color = (
		start_btn.get_theme_color(
			"font_color"
		)
	)


	if detected_normal.a > 0.0:

		normal_text_color = detected_normal

	else:

		normal_text_color = Color.WHITE


	# ==========================================
	# FOCO USA A MESMA COR DO HOVER
	# ==========================================

	start_btn.add_theme_color_override(
		"font_focus_color",
		hover_text_color
	)

	credits_btn.add_theme_color_override(
		"font_focus_color",
		hover_text_color
	)

	quit_btn.add_theme_color_override(
		"font_focus_color",
		hover_text_color
	)


	# ==========================================
	# CLIQUES
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
	# FOCO
	# ==========================================

	if not start_btn.focus_entered.is_connected(
		_on_start_focus
	):

		start_btn.focus_entered.connect(
			_on_start_focus
	)


	if not credits_btn.focus_entered.is_connected(
		_on_credits_focus
	):

		credits_btn.focus_entered.connect(
			_on_credits_focus
	)


	if not quit_btn.focus_entered.is_connected(
		_on_quit_focus
	):

		quit_btn.focus_entered.connect(
			_on_quit_focus
	)


	# ==========================================
	# MOUSE ENTER
	# ==========================================

	if not start_btn.mouse_entered.is_connected(
		_on_start_mouse_entered
	):

		start_btn.mouse_entered.connect(
			_on_start_mouse_entered
	)


	if not credits_btn.mouse_entered.is_connected(
		_on_credits_mouse_entered
	):

		credits_btn.mouse_entered.connect(
			_on_credits_mouse_entered
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

	if not start_btn.mouse_exited.is_connected(
		_on_button_mouse_exited
	):

		start_btn.mouse_exited.connect(
			_on_button_mouse_exited
	)


	if not credits_btn.mouse_exited.is_connected(
		_on_button_mouse_exited
	):

		credits_btn.mouse_exited.connect(
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

	selected_button = start_btn

	start_btn.grab_focus()

	_apply_keyboard_visual()


# ==========================================
# MARCA INPUT COMO TRATADO COM SEGURANÇA
# ==========================================

func _mark_input_handled() -> void:

	# ==========================================
	# GARANTE QUE AINDA ESTÁ NA ÁRVORE
	# ==========================================

	if not is_inside_tree():

		return


	# ==========================================
	# PEGA VIEWPORT
	# ==========================================

	var viewport := get_viewport()


	if viewport == null:

		return


	# ==========================================
	# MARCA INPUT
	# ==========================================

	viewport.set_input_as_handled()


# ==========================================
# INPUT DO TECLADO
# ==========================================

func _unhandled_input(event):

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

		mouse_mode_active = false


		if selected_button == start_btn:

			selected_button = quit_btn

		elif selected_button == credits_btn:

			selected_button = start_btn

		elif selected_button == quit_btn:

			selected_button = credits_btn

		else:

			selected_button = start_btn


		selected_button.grab_focus()

		_apply_keyboard_visual()

		_mark_input_handled()

		return


	# ==========================================
	# BAIXO
	# ==========================================

	if (
		event.keycode == KEY_S
		or event.keycode == KEY_DOWN
	):

		mouse_mode_active = false


		if selected_button == start_btn:

			selected_button = credits_btn

		elif selected_button == credits_btn:

			selected_button = quit_btn

		elif selected_button == quit_btn:

			selected_button = start_btn

		else:

			selected_button = start_btn


		selected_button.grab_focus()

		_apply_keyboard_visual()

		_mark_input_handled()

		return


	# ==========================================
	# ENTER
	# ==========================================

	if (
		event.keycode == KEY_ENTER
		or event.keycode == KEY_KP_ENTER
	):

		# ==========================================
		# MARCA PRIMEIRO
		# ==========================================

		_mark_input_handled()


		# ==========================================
		# DEPOIS EXECUTA A AÇÃO
		# ==========================================

		if selected_button == start_btn:

			start_game()

		elif selected_button == credits_btn:

			open_credits()

		elif selected_button == quit_btn:

			quit_game()


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
	# SEM SELEÇÃO
	# ==========================================

	if selected_button == null:

		return


	# ==========================================
	# SELECIONADO FICA ROXO
	# ==========================================

	selected_button.add_theme_color_override(
		"font_color",
		hover_text_color
	)

	selected_button.add_theme_color_override(
		"font_focus_color",
		hover_text_color
	)


# ==========================================
# REMOVE COR DO TECLADO
# ==========================================

func _clear_all_keyboard_colors():

	start_btn.add_theme_color_override(
		"font_color",
		normal_text_color
	)

	start_btn.add_theme_color_override(
		"font_focus_color",
		normal_text_color
	)


	credits_btn.add_theme_color_override(
		"font_color",
		normal_text_color
	)

	credits_btn.add_theme_color_override(
		"font_focus_color",
		normal_text_color
	)


	quit_btn.add_theme_color_override(
		"font_color",
		normal_text_color
	)

	quit_btn.add_theme_color_override(
		"font_focus_color",
		normal_text_color
	)


# ==========================================
# MOUSE ENTROU - JOGAR
# ==========================================

func _on_start_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE ENTROU - CRÉDITOS
# ==========================================

func _on_credits_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE ENTROU - SAIR
# ==========================================

func _on_quit_mouse_entered():

	mouse_mode_active = true

	_clear_all_keyboard_colors()


# ==========================================
# MOUSE SAIU
# ==========================================

func _on_button_mouse_exited():

	# ==========================================
	# SEGURANÇA
	# ==========================================

	if not is_inside_tree():

		return


	var viewport := get_viewport()


	if viewport == null:

		return


	var mouse_pos: Vector2 = (
		viewport.get_mouse_position()
	)


	# ==========================================
	# AINDA ESTÁ EM ALGUM BOTÃO?
	# ==========================================

	if (
		start_btn.get_global_rect().has_point(
			mouse_pos
		)
		or
		credits_btn.get_global_rect().has_point(
			mouse_pos
		)
		or
		quit_btn.get_global_rect().has_point(
			mouse_pos
		)
	):

		return


	# ==========================================
	# MOUSE SAIU DO MENU
	# ==========================================

	mouse_mode_active = false

	_apply_keyboard_visual()


# ==========================================
# FOCO - JOGAR
# ==========================================

func _on_start_focus():

	selected_button = start_btn

	if not mouse_mode_active:

		_apply_keyboard_visual()


# ==========================================
# FOCO - CRÉDITOS
# ==========================================

func _on_credits_focus():

	selected_button = credits_btn

	if not mouse_mode_active:

		_apply_keyboard_visual()


# ==========================================
# FOCO - SAIR
# ==========================================

func _on_quit_focus():

	selected_button = quit_btn

	if not mouse_mode_active:

		_apply_keyboard_visual()


# ==========================================
# CLIQUE - JOGAR
# ==========================================

func _on_start_btn_pressed():

	# ==========================================
	# CLIQUE PASSA A SER A SELEÇÃO
	# ==========================================

	selected_button = start_btn

	mouse_mode_active = false

	_apply_keyboard_visual()


	# ==========================================
	# INICIA
	# ==========================================

	start_game()


# ==========================================
# CLIQUE - CRÉDITOS
# ==========================================

func _on_credits_btn_pressed():

	selected_button = credits_btn

	mouse_mode_active = false

	_apply_keyboard_visual()

	open_credits()


# ==========================================
# CLIQUE - SAIR
# ==========================================

func _on_quit_btn_pressed():

	selected_button = quit_btn

	mouse_mode_active = false

	_apply_keyboard_visual()

	quit_game()


# ==========================================
# JOGAR
# ==========================================

func start_game():

	print(
		"=============================="
	)

	print(
		"INICIANDO NOVO JOGO"
	)

	print(
		"=============================="
	)


	# ==========================================
	# RESET COMPLETO
	# ==========================================

	Globals.score = 0
	Globals.coins = 0

	Globals.level_score = 0
	Globals.level_coins = 0

	# Novo jogo começa sem moedas acumuladas.
	Globals.coins_before_level = 0

	Globals.raciocinio_fragments = 0
	Globals.atencao_fragments = 0
	Globals.memoria_fragments = 0


	print(
		"SCORE: ",
		Globals.score
	)

	print(
		"MOEDAS: ",
		Globals.coins
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
	# COMEÇA PELO TUTORIAL
	# ==========================================

	get_tree().change_scene_to_file(
		"res://levels/world_00.tscn"
	)


# ==========================================
# CRÉDITOS
# ==========================================

func open_credits():

	print(
		"=============================="
	)

	print(
		"ABRINDO CRÉDITOS"
	)

	print(
		"=============================="
	)


	print(
		"Tela de créditos ainda será criada."
	)


# ==========================================
# SAIR
# ==========================================

func quit_game():

	print(
		"=============================="
	)

	print(
		"FECHANDO JOGO"
	)

	print(
		"=============================="
	)


	get_tree().quit()
