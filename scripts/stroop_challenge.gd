extends Control


# =========================================================
# SINAL
# =========================================================

signal challenge_completed


# =========================================================
# REFERÊNCIAS
# =========================================================

@onready var instruction_label: Label = find_child(
	"InstructionLabel",
	true,
	false
) as Label

@onready var word_label: Label = find_child(
	"WordLabel",
	true,
	false
) as Label

@onready var red_button: Button = find_child(
	"RedButton",
	true,
	false
) as Button

@onready var blue_button: Button = find_child(
	"BlueButton",
	true,
	false
) as Button

@onready var green_button: Button = find_child(
	"GreenButton",
	true,
	false
) as Button

@onready var progress_label: Label = find_child(
	"ProgressLabel",
	true,
	false
) as Label

@onready var result_label: Label = find_child(
	"ResultLabel",
	true,
	false
) as Label

@onready var background: ColorRect = find_child(
	"Background",
	true,
	false
) as ColorRect

@onready var main_container: Control = find_child(
	"MainContainer",
	true,
	false
) as Control


# =========================================================
# TUTORIAL
# =========================================================

@onready var tutorial: Control = find_child(
	"tutorial",
	true,
	false
) as Control

@onready var tutorial_stroop: TextureRect = find_child(
	"tutorial_stroop",
	true,
	false
) as TextureRect

@onready var tutorial_button: Button = find_child(
	"Button",
	true,
	false
) as Button


# =========================================================
# CONFIGURAÇÃO
# =========================================================

const TOTAL_ACERTOS := 10

const PURPLE_COLOR := Color("#7046A3")


var colors := {
	"vermelho": Color("#E84B4B"),
	"azul": Color("#4D8FE8"),
	"verde": Color("#55B86A")
}


var color_names := [
	"vermelho",
	"azul",
	"verde"
]


# =========================================================
# CORES DA TELA FINAL
# =========================================================

const FINAL_TITLE_COLOR := Color("#F4F7FA")
const FINAL_TEXT_COLOR := Color("#DCE8F2")
const FINAL_INFO_COLOR := Color("#82CFFF")
const FINAL_ERROR_COLOR := Color("#FF7070")


# =========================================================
# COMBINAÇÕES
# =========================================================

var stroop_combinations: Array[Dictionary] = []

var current_combination_index: int = -1


# =========================================================
# VARIÁVEIS
# =========================================================

var current_word: String = ""
var current_color: String = ""

var last_word: String = ""
var last_color: String = ""

var correct_answers: int = 0
var error_count: int = 0

var challenge_active: bool = false
var can_answer: bool = false

var tutorial_active: bool = true
var result_screen_active: bool = false


# =========================================================
# LABEL DO ENTER DO TUTORIAL
# =========================================================

var enter_label: Label = null


# =========================================================
# LABEL DO ENTER FINAL
# =========================================================

var final_enter_label: Label = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	modulate = Color.WHITE
	self_modulate = Color.WHITE


	# =====================================================
	# RENDERIZAÇÃO
	# =====================================================

	if main_container != null:
		main_container.modulate = Color.WHITE
		main_container.self_modulate = Color.WHITE


	if instruction_label != null:
		instruction_label.modulate = Color.WHITE
		instruction_label.self_modulate = Color.WHITE


	if word_label != null:
		word_label.modulate = Color.WHITE
		word_label.self_modulate = Color.WHITE


	if progress_label != null:
		progress_label.modulate = Color.WHITE
		progress_label.self_modulate = Color.WHITE


	if result_label != null:
		result_label.modulate = Color.WHITE
		result_label.self_modulate = Color.WHITE


	if red_button != null:
		red_button.modulate = Color.WHITE
		red_button.self_modulate = Color.WHITE


	if blue_button != null:
		blue_button.modulate = Color.WHITE
		blue_button.self_modulate = Color.WHITE


	if green_button != null:
		green_button.modulate = Color.WHITE
		green_button.self_modulate = Color.WHITE


	# =====================================================
	# VERIFICA ELEMENTOS
	# =====================================================

	if instruction_label == null:
		print("ERRO: InstructionLabel não encontrado!")
		return

	if word_label == null:
		print("ERRO: WordLabel não encontrado!")
		return

	if red_button == null:
		print("ERRO: RedButton não encontrado!")
		return

	if blue_button == null:
		print("ERRO: BlueButton não encontrado!")
		return

	if green_button == null:
		print("ERRO: GreenButton não encontrado!")
		return

	if progress_label == null:
		print("ERRO: ProgressLabel não encontrado!")
		return

	if result_label == null:
		print("ERRO: ResultLabel não encontrado!")
		return


	# =====================================================
	# VERIFICA TUTORIAL
	# =====================================================

	if tutorial == null:
		print("ERRO: nó 'tutorial' não encontrado!")

	if tutorial_stroop == null:
		print("ERRO: nó 'tutorial_stroop' não encontrado!")

	if tutorial_button == null:
		print("ERRO: botão do tutorial não encontrado!")


	# =====================================================
	# FUNDO
	# =====================================================

	if background != null:
		background.color = Color("#101827")
		background.modulate = Color.WHITE
		background.self_modulate = Color.WHITE


	# =====================================================
	# TEXTOS
	# =====================================================

	instruction_label.text = (
		"ESCOLHA A COR DA PALAVRA"
	)

	word_label.text = ""

	progress_label.text = (
		"0 / %d"
		% TOTAL_ACERTOS
	)

	result_label.text = ""


	# =====================================================
	# INSTRUÇÃO
	# =====================================================

	instruction_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	instruction_label.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)

	instruction_label.add_theme_constant_override(
		"shadow_offset_x",
		2
	)

	instruction_label.add_theme_constant_override(
		"shadow_offset_y",
		2
	)

	instruction_label.add_theme_font_size_override(
		"font_size",
		28
	)

	instruction_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	# =====================================================
	# PALAVRA
	# =====================================================

	word_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	word_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	word_label.add_theme_constant_override(
		"outline_size",
		8
	)

	word_label.add_theme_font_size_override(
		"font_size",
		72
	)

	word_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	# =====================================================
	# PROGRESSO
	# =====================================================

	progress_label.add_theme_color_override(
		"font_color",
		PURPLE_COLOR
	)

	progress_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	progress_label.add_theme_constant_override(
		"outline_size",
		6
	)

	progress_label.add_theme_font_size_override(
		"font_size",
		28
	)

	progress_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	# =====================================================
	# RESULTADO
	# =====================================================

	result_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	result_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	result_label.add_theme_constant_override(
		"outline_size",
		5
	)

	result_label.add_theme_font_size_override(
		"font_size",
		24
	)

	result_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	# =====================================================
	# BOTÕES DO STROOP
	# =====================================================

	red_button.text = "[ 1 ]  VERMELHO"
	blue_button.text = "[ 2 ]  AZUL"
	green_button.text = "[ 3 ]  VERDE"


	_style_button(
		red_button,
		colors["vermelho"]
	)

	_style_button(
		blue_button,
		colors["azul"]
	)

	_style_button(
		green_button,
		colors["verde"]
	)


	# =====================================================
	# CONECTA BOTÕES
	# =====================================================

	if not red_button.pressed.is_connected(
		_on_red_button_pressed
	):
		red_button.pressed.connect(
			_on_red_button_pressed
		)


	if not blue_button.pressed.is_connected(
		_on_blue_button_pressed
	):
		blue_button.pressed.connect(
			_on_blue_button_pressed
		)


	if not green_button.pressed.is_connected(
		_on_green_button_pressed
	):
		green_button.pressed.connect(
			_on_green_button_pressed
	)


	# =====================================================
	# TUTORIAL
	# =====================================================

	_setup_tutorial()


	# =====================================================
	# COMBINAÇÕES
	# =====================================================

	_build_combinations()


	challenge_active = false
	can_answer = false
	result_screen_active = false


	print(
		"TUTORIAL DO STROOP ABERTO!"
	)


# =========================================================
# CONFIGURA TUTORIAL
# =========================================================

func _setup_tutorial() -> void:

	if tutorial == null:
		return


	tutorial.show()
	tutorial_active = true
	tutorial.z_index = 1000

	tutorial.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# =====================================================
	# IMAGEM
	# =====================================================

	if tutorial_stroop != null:

		tutorial_stroop.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		tutorial_stroop.z_index = 0


	# =====================================================
	# BOTÃO
	# =====================================================

	if tutorial_button != null:

		tutorial_button.text = "VAMOS LÁ"

		tutorial_button.mouse_filter = (
			Control.MOUSE_FILTER_STOP
		)

		tutorial_button.focus_mode = (
			Control.FOCUS_ALL
		)

		tutorial_button.disabled = false
		tutorial_button.z_index = 50


		_style_tutorial_button(
			tutorial_button
		)


		if not tutorial_button.pressed.is_connected(
			_on_tutorial_button_pressed
		):

			tutorial_button.pressed.connect(
				_on_tutorial_button_pressed
			)


		_create_enter_label()

		tutorial_button.grab_focus()


# =========================================================
# CRIA LABEL DO ENTER
# =========================================================

func _create_enter_label() -> void:

	if tutorial_button == null:
		return


	enter_label = Label.new()

	enter_label.text = "(ENTER)"

	enter_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	enter_label.add_theme_font_size_override(
		"font_size",
		9
	)

	enter_label.add_theme_color_override(
		"font_color",
		Color("#E6D8F5")
	)

	enter_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	enter_label.add_theme_constant_override(
		"outline_size",
		2
	)


	enter_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	enter_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	enter_label.size = Vector2(
		180,
		14
	)

	enter_label.position = Vector2(
		40,
		40
	)

	enter_label.z_index = 10


	tutorial_button.add_child(
		enter_label
	)


# =========================================================
# INPUT DO MOUSE
# =========================================================

func _input(event: InputEvent) -> void:

	if tutorial_active:

		if tutorial_button == null:
			return


		var mouse_event := (
			event as InputEventMouseButton
		)


		if mouse_event == null:
			return


		if mouse_event.button_index != (
			MOUSE_BUTTON_LEFT
		):
			return


		if not mouse_event.pressed:
			return


		var mouse_position: Vector2 = (
			mouse_event.position
		)


		var button_rect: Rect2 = (
			tutorial_button.get_global_rect()
		)


		if button_rect.has_point(
			mouse_position
		):

			print(
				"CLIQUE DETECTADO NO VAMOS LÁ!"
			)

			_on_tutorial_button_pressed()

			get_viewport().set_input_as_handled()


		return


	# =====================================================
	# TELA FINAL
	# =====================================================

	if result_screen_active:

		if event.is_action_pressed(
			"ui_accept"
		):

			_close_result_screen()

			get_viewport().set_input_as_handled()

		return


# =========================================================
# BOTÃO VAMOS LÁ
# =========================================================

func _on_tutorial_button_pressed() -> void:

	if not tutorial_active:
		return


	print(
		"================================"
	)

	print(
		"VAMOS LÁ CLICADO!"
	)

	print(
		"INICIANDO STROOP..."
	)

	print(
		"================================"
	)


	tutorial_active = false


	if tutorial != null:
		tutorial.hide()


	start_challenge()


# =========================================================
# ESTILO DO BOTÃO VAMOS LÁ
# =========================================================

func _style_tutorial_button(
	button: Button
) -> void:

	button.custom_minimum_size = Vector2(
		260,
		62
	)


	button.add_theme_font_size_override(
		"font_size",
		22
	)


	button.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_focus_color",
		Color.WHITE
	)


	button.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	button.add_theme_constant_override(
		"outline_size",
		3
	)


	# =====================================================
	# NORMAL
	# =====================================================

	var normal := StyleBoxFlat.new()

	normal.bg_color = Color("#7B3FC6")

	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2

	normal.border_color = Color.BLACK

	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8


	normal.shadow_color = Color(
		0,
		0,
		0,
		0.4
	)

	normal.shadow_size = 4

	normal.shadow_offset = Vector2(
		0,
		3
	)


	# =====================================================
	# HOVER
	# =====================================================

	var hover := normal.duplicate()

	hover.bg_color = Color("#A75AEA")

	hover.border_color = Color.BLACK

	hover.shadow_color = Color(
		0,
		0,
		0,
		0.65
	)

	hover.shadow_size = 9

	hover.shadow_offset = Vector2(
		0,
		3
	)


	# =====================================================
	# PRESSIONADO
	# =====================================================

	var pressed := normal.duplicate()

	pressed.bg_color = Color("#5E299A")

	pressed.border_color = Color.BLACK

	pressed.shadow_color = Color(
		0,
		0,
		0,
		0.3
	)

	pressed.shadow_size = 1

	pressed.shadow_offset = Vector2(
		0,
		1
	)


	# =====================================================
	# FOCUS
	# =====================================================

	var focus := normal.duplicate()

	focus.bg_color = Color("#8A48D8")

	focus.border_color = Color.BLACK

	focus.shadow_color = Color(
		0,
		0,
		0,
		0.55
	)

	focus.shadow_size = 8

	focus.shadow_offset = Vector2(
		0,
		3
	)


	# =====================================================
	# APLICA
	# =====================================================

	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"focus",
		focus
	)


	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)


# =========================================================
# BOTÕES DO STROOP
# =========================================================

func _on_red_button_pressed() -> void:
	_answer("vermelho")


func _on_blue_button_pressed() -> void:
	_answer("azul")


func _on_green_button_pressed() -> void:
	_answer("verde")


# =========================================================
# INPUT DO TECLADO
# =========================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	# =====================================================
	# TUTORIAL
	# =====================================================

	if tutorial_active:

		if event.is_action_pressed(
			"ui_accept"
		):

			_on_tutorial_button_pressed()

			get_viewport().set_input_as_handled()

		return


	# =====================================================
	# TELA FINAL
	# =====================================================

	if result_screen_active:
		return


	# =====================================================
	# DESAFIO
	# =====================================================

	if not challenge_active:
		return

	if not can_answer:
		return

	if not event.is_pressed():
		return

	if event.is_echo():
		return


	# =====================================================
	# 1 / 2 / 3
	# =====================================================

	if event is InputEventKey:

		match event.keycode:

			KEY_1:

				_answer("vermelho")

				get_viewport().set_input_as_handled()


			KEY_2:

				_answer("azul")

				get_viewport().set_input_as_handled()


			KEY_3:

				_answer("verde")

				get_viewport().set_input_as_handled()


# =========================================================
# COMBINAÇÕES
# =========================================================

func _build_combinations() -> void:

	stroop_combinations.clear()


	for word in color_names:

		for color in color_names:

			if word == color:
				continue


			stroop_combinations.append({
				"word": word,
				"color": color
			})


	stroop_combinations.shuffle()

	current_combination_index = -1


# =========================================================
# PRÓXIMA COMBINAÇÃO
# =========================================================

func _get_next_combination() -> Dictionary:

	current_combination_index += 1


	if current_combination_index >= (
		stroop_combinations.size()
	):

		stroop_combinations.shuffle()

		current_combination_index = 0


		var first_combination: Dictionary = (
			stroop_combinations[0]
		)


		if (
			first_combination["word"] == last_word
			and first_combination["color"] == last_color
		):

			if stroop_combinations.size() > 1:

				var swap_index: int = randi_range(
					1,
					stroop_combinations.size() - 1
				)


				var temp = stroop_combinations[0]

				stroop_combinations[0] = (
					stroop_combinations[
						swap_index
					]
				)

				stroop_combinations[swap_index] = temp


	return stroop_combinations[
		current_combination_index
	]


# =========================================================
# ESTILO DOS BOTÕES 1 / 2 / 3
# =========================================================

func _style_button(
	button: Button,
	color: Color
) -> void:

	button.custom_minimum_size = Vector2(
		220,
		72
	)


	button.add_theme_font_size_override(
		"font_size",
		20
	)


	button.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_focus_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_disabled_color",
		Color("#777777")
	)


	button.add_theme_color_override(
		"font_outline_color",
		Color("#17131F")
	)

	button.add_theme_constant_override(
		"outline_size",
		2
	)


	# =====================================================
	# NORMAL
	# =====================================================

	var normal := StyleBoxFlat.new()

	normal.bg_color = color.darkened(
		0.12
	)

	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2

	normal.border_color = Color(
		"#30283A"
	)

	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8


	normal.shadow_color = Color(
		0,
		0,
		0,
		0.28
	)

	normal.shadow_size = 3

	normal.shadow_offset = Vector2(
		0,
		3
	)


	# =====================================================
	# HOVER
	# =====================================================

	var hover := normal.duplicate()

	hover.bg_color = color.lightened(
		0.10
	)

	hover.border_color = PURPLE_COLOR

	hover.shadow_color = PURPLE_COLOR
	hover.shadow_color.a = 0.35

	hover.shadow_size = 5

	hover.shadow_offset = Vector2(
		0,
		2
	)


	# =====================================================
	# PRESSIONADO
	# =====================================================

	var pressed := normal.duplicate()

	pressed.bg_color = color.darkened(
		0.28
	)

	pressed.border_color = Color(
		"#241E2C"
	)

	pressed.shadow_size = 1

	pressed.shadow_offset = Vector2(
		0,
		1
	)


	# =====================================================
	# FOCUS
	# =====================================================

	var focus := normal.duplicate()

	focus.bg_color = color.lightened(
		0.06
	)

	focus.border_color = Color(
		"#A477D6"
	)

	focus.shadow_color = PURPLE_COLOR
	focus.shadow_color.a = 0.45

	focus.shadow_size = 5

	focus.shadow_offset = Vector2(
		0,
		2
	)


	# =====================================================
	# DESABILITADO
	# =====================================================

	var disabled := normal.duplicate()

	disabled.bg_color = Color(
		"#38343F"
	)

	disabled.border_color = Color(
		"#26222C"
	)

	disabled.shadow_color = Color(
		0,
		0,
		0,
		0.15
	)

	disabled.shadow_size = 2


	# =====================================================
	# APLICA
	# =====================================================

	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"focus",
		focus
	)

	button.add_theme_stylebox_override(
		"disabled",
		disabled
	)


	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)


# =========================================================
# INICIAR DESAFIO
# =========================================================

func start_challenge() -> void:

	correct_answers = 0
	error_count = 0

	result_screen_active = false
	challenge_active = true
	can_answer = false


	progress_label.text = (
		"0 / %d"
		% TOTAL_ACERTOS
	)

	result_label.text = ""


	red_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	blue_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	green_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	_build_combinations()

	_new_round()


# =========================================================
# NOVA RODADA
# =========================================================

func _new_round() -> void:

	if not challenge_active:
		return


	can_answer = false


	var combination: Dictionary = (
		_get_next_combination()
	)


	current_word = combination["word"]
	current_color = combination["color"]


	last_word = current_word
	last_color = current_color


	word_label.text = (
		current_word.to_upper()
	)


	word_label.add_theme_color_override(
		"font_color",
		colors[current_color]
	)


	await get_tree().create_timer(
		0.35
	).timeout


	if not challenge_active:
		return


	can_answer = true


# =========================================================
# RESPOSTA
# =========================================================

func _answer(
	selected_color: String
) -> void:

	if tutorial_active:
		return

	if result_screen_active:
		return

	if not challenge_active:
		return

	if not can_answer:
		return


	can_answer = false


	# =====================================================
	# ACERTO
	# =====================================================

	if selected_color == current_color:

		correct_answers += 1


		progress_label.text = (
			"%d / %d"
			% [
				correct_answers,
				TOTAL_ACERTOS
			]
		)


		result_label.text = "CORRETO!"


		result_label.add_theme_color_override(
			"font_color",
			Color("#55D477")
		)


		print(
			"ACERTO: ",
			correct_answers,
			"/",
			TOTAL_ACERTOS
		)


		if correct_answers >= TOTAL_ACERTOS:

			_complete_challenge()

			return


	# =====================================================
	# ERRO
	# =====================================================

	else:

		error_count += 1

		print(
			"ERRO #",
			error_count
		)


		correct_answers = 0


		progress_label.text = (
			"0 / %d"
			% TOTAL_ACERTOS
		)


		result_label.text = (
			"ERRO! ATENÇÃO!"
		)


		result_label.add_theme_color_override(
			"font_color",
			Color("#FF5C5C")
		)


	# =====================================================
	# ESPERA
	# =====================================================

	await get_tree().create_timer(
		0.75
	).timeout


	if not challenge_active:
		return


	result_label.text = ""

	_new_round()


# =========================================================
# DESAFIO CONCLUÍDO
# =========================================================

func _complete_challenge() -> void:

	challenge_active = false
	can_answer = false
	result_screen_active = true


	# =====================================================
	# NÃO DESABILITA OS BOTÕES
	# =====================================================

	red_button.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	blue_button.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	green_button.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# =====================================================
	# REMOVE PALAVRA
	# =====================================================

	word_label.text = ""


	# =====================================================
	# PROGRESSO
	# =====================================================

	progress_label.text = (
		"10 / %d"
		% TOTAL_ACERTOS
	)


	# =====================================================
	# RESULTADO FINAL
	# =====================================================

	result_label.text = (
		"DESAFIO CONCLUÍDO!\n\n"
		+ "ERROS: "
		+ str(error_count)
		+ "\n\n"
		+ ""
	)


	# =====================================================
	# COR DO RESULTADO
	# =====================================================

	result_label.add_theme_color_override(
		"font_color",
		FINAL_TITLE_COLOR
	)

	result_label.add_theme_color_override(
		"font_outline_color",
		Color("#081018")
	)

	result_label.add_theme_constant_override(
		"outline_size",
		6
	)


	# =====================================================
	# FONTE DA TELA FINAL
	# =====================================================

	result_label.add_theme_font_size_override(
		"font_size",
		19
	)


	# =====================================================
	# ENTER FINAL
	# =====================================================

	_create_final_enter_label()


	print(
		"================================"
	)

	print(
		"STROOP CONCLUÍDO!"
	)

	print(
		"ERROS: ",
		error_count
	)

	print(
		"AGUARDANDO ENTER..."
	)

	print(
		"================================"
	)


	grab_focus()


# =========================================================
# ENTER DA TELA FINAL
# =========================================================

func _create_final_enter_label() -> void:

	if final_enter_label != null:

		final_enter_label.queue_free()
		final_enter_label = null


	final_enter_label = Label.new()

	final_enter_label.text = "↵ ENTER"

	final_enter_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	final_enter_label.add_theme_font_size_override(
		"font_size",
		13
	)


	final_enter_label.add_theme_color_override(
		"font_color",
		FINAL_INFO_COLOR
	)

	final_enter_label.add_theme_color_override(
		"font_outline_color",
		Color("#081018")
	)

	final_enter_label.add_theme_constant_override(
		"outline_size",
		3
	)


	final_enter_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	final_enter_label.set_anchors_preset(
		Control.PRESET_CENTER_BOTTOM
	)


	final_enter_label.position = Vector2(
		-100,
		-45
	)


	final_enter_label.size = Vector2(
		200,
		25
	)


	final_enter_label.z_index = 20


	add_child(
		final_enter_label
	)


# =========================================================
# FECHA TELA FINAL
# =========================================================

func _close_result_screen() -> void:

	if not result_screen_active:
		return


	print(
		"ENTER PRESSIONADO."
	)

	print(
		"VOLTANDO AO MAPA..."
	)


	result_screen_active = false


	if final_enter_label != null:

		final_enter_label.queue_free()
		final_enter_label = null


	challenge_completed.emit()


# =========================================================
# FUNÇÃO MANTIDA
# =========================================================

func _enable_buttons(
	enabled: bool
) -> void:

	red_button.disabled = false
	blue_button.disabled = false
	green_button.disabled = false
