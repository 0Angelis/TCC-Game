extends Control


# =========================================================
# SINAL
# =========================================================
# Avisará o StroopTrigger quando o desafio terminar.
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
# COMBINAÇÕES STROOP
# =========================================================

var stroop_combinations: Array[Dictionary] = []

var current_combination_index := -1


# =========================================================
# VARIÁVEIS
# =========================================================

var current_word := ""
var current_color := ""

var last_word := ""
var last_color := ""

var correct_answers := 0

var challenge_active := false
var can_answer := false


# =========================================================
# READY
# =========================================================

func _ready():

	# =====================================================
	# GARANTE RENDERIZAÇÃO NORMAL
	# =====================================================

	modulate = Color.WHITE
	self_modulate = Color.WHITE


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
	# VERIFICAÇÃO
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
	# FUNDO
	# =====================================================

	if background != null:

		background.color = Color("#101827")

		background.modulate = Color.WHITE
		background.self_modulate = Color.WHITE


	# =====================================================
	# TEXTOS INICIAIS
	# =====================================================

	instruction_label.text = "ESCOLHA A COR DA PALAVRA"

	word_label.text = ""

	progress_label.text = "0 / %d" % TOTAL_ACERTOS

	result_label.text = ""


	# =====================================================
	# CORES DOS TEXTOS
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

	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


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

	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


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

	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


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

	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


	# =====================================================
	# BOTÕES
	# =====================================================

	red_button.text = "VERMELHO"

	blue_button.text = "AZUL"

	green_button.text = "VERDE"


	_style_button(
		red_button,
		Color("#D94242")
	)

	_style_button(
		blue_button,
		Color("#397FD1")
	)

	_style_button(
		green_button,
		Color("#3FA85B")
	)


	# =====================================================
	# CONECTA BOTÕES
	# =====================================================

	red_button.pressed.connect(
		func():
			_answer("vermelho")
	)

	blue_button.pressed.connect(
		func():
			_answer("azul")
	)

	green_button.pressed.connect(
		func():
			_answer("verde")
	)


	# =====================================================
	# MONTA AS COMBINAÇÕES
	# =====================================================

	_build_combinations()


	# =====================================================
	# INICIA
	# =====================================================

	start_challenge()


# =========================================================
# MONTA TODAS AS COMBINAÇÕES POSSÍVEIS
# =========================================================

func _build_combinations():

	stroop_combinations.clear()


	for word in color_names:

		for color in color_names:

			# =============================================
			# PALAVRA E COR NÃO PODEM SER IGUAIS
			# =============================================

			if word == color:
				continue


			stroop_combinations.append({
				"word": word,
				"color": color
			})


	# =====================================================
	# EMBARALHA
	# =====================================================

	stroop_combinations.shuffle()

	current_combination_index = -1


	print(
		"COMBINAÇÕES STROOP DISPONÍVEIS: ",
		stroop_combinations.size()
	)


# =========================================================
# PEGA A PRÓXIMA COMBINAÇÃO
# =========================================================

func _get_next_combination() -> Dictionary:

	current_combination_index += 1


	# =====================================================
	# TERMINOU O CICLO
	# =====================================================

	if current_combination_index >= stroop_combinations.size():

		stroop_combinations.shuffle()

		current_combination_index = 0


		# ==============================================
		# EVITA REPETIR A ÚLTIMA COMBINAÇÃO
		# ==============================================

		var first_combination: Dictionary = stroop_combinations[0]


		if (
			first_combination["word"] == last_word
			and first_combination["color"] == last_color
		):

			if stroop_combinations.size() > 1:

				var swap_index := randi_range(
					1,
					stroop_combinations.size() - 1
				)


				var temp = stroop_combinations[0]

				stroop_combinations[0] = stroop_combinations[swap_index]

				stroop_combinations[swap_index] = temp


	# =====================================================
	# RETORNA
	# =====================================================

	return stroop_combinations[current_combination_index]


# =========================================================
# ESTILO DOS BOTÕES
# =========================================================

func _style_button(
	button: Button,
	color: Color
):

	button.custom_minimum_size = Vector2(
		190,
		70
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
		Color.WHITE
	)


	button.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	button.add_theme_constant_override(
		"outline_size",
		2
	)


	# =====================================================
	# NORMAL
	# =====================================================

	var normal := StyleBoxFlat.new()

	normal.bg_color = color


	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3


	normal.border_color = color.darkened(
		0.35
	)


	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10


	# =====================================================
	# HOVER
	# =====================================================

	var hover := normal.duplicate()

	hover.bg_color = color.lightened(
		0.15
	)


	# =====================================================
	# PRESSED
	# =====================================================

	var pressed := normal.duplicate()

	pressed.bg_color = color.darkened(
		0.15
	)


	# =====================================================
	# DISABLED
	# =====================================================

	var disabled := normal.duplicate()

	disabled.bg_color = Color("#444444")

	disabled.border_color = Color("#222222")


	# =====================================================
	# APLICA ESTILOS
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
		"disabled",
		disabled
	)


# =========================================================
# INICIAR DESAFIO
# =========================================================

func start_challenge():

	correct_answers = 0

	challenge_active = true

	can_answer = false


	progress_label.text = "0 / %d" % TOTAL_ACERTOS

	result_label.text = ""


	_enable_buttons(true)


	# =====================================================
	# NOVO CICLO
	# =====================================================

	_build_combinations()


	# =====================================================
	# PRIMEIRA RODADA
	# =====================================================

	_new_round()


# =========================================================
# NOVA RODADA
# =========================================================

func _new_round():

	if not challenge_active:

		return


	can_answer = false


	# =====================================================
	# PEGA COMBINAÇÃO
	# =====================================================

	var combination := _get_next_combination()


	current_word = combination["word"]

	current_color = combination["color"]


	# =====================================================
	# GUARDA ÚLTIMA
	# =====================================================

	last_word = current_word

	last_color = current_color


	# =====================================================
	# MOSTRA PALAVRA
	# =====================================================

	word_label.text = current_word.to_upper()


	# =====================================================
	# DEFINE COR
	# =====================================================

	word_label.add_theme_color_override(
		"font_color",
		colors[current_color]
	)


	# =====================================================
	# PEQUENO DELAY
	# =====================================================

	await get_tree().create_timer(
		0.35
	).timeout


	if not challenge_active:

		return


	can_answer = true


# =========================================================
# RESPOSTA
# =========================================================

func _answer(selected_color: String):

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


		progress_label.text = "%d / %d" % [
			correct_answers,
			TOTAL_ACERTOS
		]


		result_label.text = "CORRETO!"


		result_label.add_theme_color_override(
			"font_color",
			Color("#55D477")
		)


		print(
			"ACERTO: ",
			correct_answers,
			"/",
			TOTAL_ACERTOS,
			" | ",
			current_word,
			" em ",
			current_color
		)


		# =================================================
		# COMPLETOU 10
		# =================================================

		if correct_answers >= TOTAL_ACERTOS:

			_complete_challenge()

			return


	# =====================================================
	# ERRO
	# =====================================================

	else:

		correct_answers = 0


		progress_label.text = "0 / %d" % TOTAL_ACERTOS


		result_label.text = "ERRO! ATENÇÃO!"


		result_label.add_theme_color_override(
			"font_color",
			Color("#FF5C5C")
		)


		print(
			"ERRO! CORRETA ERA: ",
			current_color
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

func _complete_challenge():

	# =====================================================
	# DESATIVA O DESAFIO
	# =====================================================

	challenge_active = false

	can_answer = false


	_enable_buttons(false)


	# =====================================================
	# MOSTRA RESULTADO
	# =====================================================

	progress_label.text = "10 / 10"

	result_label.text = "DESAFIO CONCLUÍDO!"


	result_label.add_theme_color_override(
		"font_color",
		PURPLE_COLOR
	)


	print("================================")
	print("STROOP CONCLUÍDO!")
	print("10 ACERTOS!")
	print("FRAGMENTO DESBLOQUEADO!")
	print("================================")


	# =====================================================
	# AVISA O STROOP TRIGGER
	# =====================================================
	# Esse é o ponto que estava faltando.
	# O trigger recebe esse sinal, fecha a tela
	# e libera o movimento do player.
	# =====================================================

	challenge_completed.emit()


# =========================================================
# BOTÕES
# =========================================================

func _enable_buttons(enabled: bool):

	red_button.disabled = not enabled

	blue_button.disabled = not enabled

	green_button.disabled = not enabled
