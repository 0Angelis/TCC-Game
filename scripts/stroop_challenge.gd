extends Control


# =========================================================
# SINAL
# =========================================================

signal challenge_completed


# =========================================================
# DIFICULDADE
# =========================================================
# 1 = 3 cores
# 2 = 4 cores
# 3 = 6 cores

@export var difficulty: int = 1


# =========================================================
# CONFIGURAÇÕES
# =========================================================

const TOTAL_ACERTOS := 10

const INITIAL_TIME := 20.0

const MAX_TIME := 30.0


# =========================================================
# CORES PRINCIPAIS
# =========================================================

const PURPLE_COLOR := Color("#7046A3")

const SUCCESS_COLOR := Color("#3FAE5A")

const ERROR_COLOR := Color("#FF4D67")


# =========================================================
# CORES DO TIMER
# =========================================================

const TIMER_PURPLE := Color("#9B59D0")

const TIMER_PURPLE_LIGHT := Color("#B97BE8")

const TIMER_PURPLE_DARK := Color("#7046A3")


# =========================================================
# CORES DA TELA FINAL
# =========================================================

const FINAL_WHITE := Color("#F4F7FA")

const FINAL_TEXT := Color("#DCE4E9")


# =========================================================
# BOTÃO FINAL
# =========================================================

const FINAL_BUTTON := Color("#39434B")

const FINAL_BUTTON_HOVER := Color("#4B5861")

const FINAL_BUTTON_PRESSED := Color("#293137")


# =========================================================
# CORES DO STROOP
# =========================================================

var colors := {
	"vermelho": Color("#E84B4B"),
	"azul": Color("#4D8FE8"),
	"verde": Color("#55B86A"),
	"amarelo": Color("#E8C84B"),
	"roxo": Color("#9B59D0"),
	"laranja": Color("#E88A3D")
}


# =========================================================
# ORDEM DAS CORES
# =========================================================

var color_names := [
	"vermelho",
	"azul",
	"verde",
	"amarelo",
	"roxo",
	"laranja"
]


# =========================================================
# REFERÊNCIAS DA CENA
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


# =========================================================
# FUNDOS DO STROOP
# =========================================================
# BG = fundo normal
# BG2 = fundo escuro usado somente no desafio 2

@onready var normal_background: CanvasItem = find_child(
	"BG",
	true,
	false
) as CanvasItem


@onready var dark_background: CanvasItem = find_child(
	"BG2",
	true,
	false
) as CanvasItem


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
# BOTÕES
# =========================================================

var color_buttons: Dictionary = {}

var extra_buttons: Array[Button] = []


# =========================================================
# COMBINAÇÕES
# =========================================================

var stroop_combinations: Array[Dictionary] = []

var current_combination_index := -1


# =========================================================
# RODADA
# =========================================================

var current_word := ""

var current_color := ""

var last_word := ""

var last_color := ""


# =========================================================
# CONTADORES
# =========================================================

var correct_answers := 0

var error_count := 0


# =========================================================
# ESTADOS
# =========================================================

var challenge_active := false

var can_answer := false

var tutorial_active := false

var result_screen_active := false

var time_up_message := false


# =========================================================
# TIMER
# =========================================================

var initial_time := INITIAL_TIME

var time_left := INITIAL_TIME

var timer_running := false


# =========================================================
# HUD TIMER
# =========================================================

var timer_panel: Panel = null

var timer_label: Label = null

var timer_icon_label: Label = null

var timer_pulse_tween: Tween = null


# =========================================================
# ENTER TUTORIAL
# =========================================================

var enter_label: Label = null


# =========================================================
# TELA DE PREPARAÇÃO - DESAFIOS 2 E 3
# =========================================================

var pre_start_active := false

var pre_start_overlay: ColorRect = null

var pre_start_panel: Panel = null

var pre_start_title_label: Label = null

var pre_start_subtitle_label: Label = null

var pre_start_hint_label: Label = null

var pre_start_button: Button = null

var pre_start_tween: Tween = null


# =========================================================
# TRANSIÇÃO DE ENTRADA DA FASE
# =========================================================

var scene_fade: ColorRect = null

var scene_fade_tween: Tween = null


# =========================================================
# TELA FINAL
# =========================================================

var final_title_label: Label = null

var final_info_label: Label = null

var final_error_label: Label = null

var final_enter_button: Button = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	difficulty = clamp(
		difficulty,
		1,
		3
	)


	# =====================================================
	# TEMPO
	# =====================================================

	initial_time = INITIAL_TIME

	time_left = INITIAL_TIME


	# =====================================================
	# ESTADOS
	# =====================================================

	challenge_active = false

	can_answer = false

	tutorial_active = false

	pre_start_active = false

	result_screen_active = false

	time_up_message = false

	timer_running = false


	# =====================================================
	# FORÇA TEXTOS VISÍVEIS
	# =====================================================

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


	# =====================================================
	# APARÊNCIA GERAL
	# =====================================================

	modulate = Color.WHITE

	self_modulate = Color.WHITE


	if main_container != null:

		main_container.modulate = Color.WHITE

		main_container.self_modulate = Color.WHITE


	# =====================================================
	# VERIFICA ELEMENTOS
	# =====================================================

	if instruction_label == null:

		push_error(
			"InstructionLabel não encontrado!"
		)

		return


	if word_label == null:

		push_error(
			"WordLabel não encontrado!"
		)

		return


	if red_button == null:

		push_error(
			"RedButton não encontrado!"
		)

		return


	if blue_button == null:

		push_error(
			"BlueButton não encontrado!"
		)

		return


	if green_button == null:

		push_error(
			"GreenButton não encontrado!"
		)

		return


	if progress_label == null:

		push_error(
			"ProgressLabel não encontrado!"
		)

		return


	if result_label == null:

		push_error(
			"ResultLabel não encontrado!"
		)

		return


	# =====================================================
	# FUNDO
	# =====================================================

	if background != null:

		background.color = Color(
			"#101827"
		)

		background.modulate = Color.WHITE

		background.self_modulate = Color.WHITE


	# =====================================================
	# FUNDO DO DESAFIO
	# =====================================================
	# Desafio 2 usa BG2.
	# Desafios 1 e 3 usam BG normal.

	if normal_background != null:

		normal_background.visible = (
			difficulty != 2
		)


	if dark_background != null:

		dark_background.visible = (
			difficulty == 2
		)


	# =====================================================
	# INSTRUÇÃO
	# =====================================================

	instruction_label.text = (
		"ESCOLHA A COR DA PALAVRA"
	)

	instruction_label.visible = true

	instruction_label.modulate = Color.WHITE

	instruction_label.self_modulate = Color.WHITE

	instruction_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	instruction_label.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)

	instruction_label.add_theme_color_override(
		"font_outline_color",
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

	instruction_label.add_theme_constant_override(
		"outline_size",
		3
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

	word_label.text = ""

	word_label.visible = true

	word_label.modulate = Color.WHITE

	word_label.self_modulate = Color.WHITE

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

	progress_label.text = (
		"0 / %d"
		% TOTAL_ACERTOS
	)

	progress_label.visible = true

	progress_label.modulate = Color.WHITE

	progress_label.self_modulate = Color.WHITE

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
	# RESULTADO DURANTE O DESAFIO
	# =====================================================

	result_label.text = ""

	result_label.visible = true

	result_label.modulate = Color.WHITE

	result_label.self_modulate = Color.WHITE

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
	# BOTÕES
	# =====================================================

	_setup_color_buttons()


	# =====================================================
	# TIMER
	# =====================================================

	_create_timer_ui()


	# =====================================================
	# TRANSIÇÃO DE ENTRADA
	# =====================================================

	_setup_scene_fade_in()


	# =====================================================
	# TUTORIAL
	# =====================================================
	# SOMENTE DESAFIO 1.

	if difficulty == 1:

		var tutorial_seen := get_tree().has_meta(
			"stroop_tutorial_seen"
		)


		if tutorial_seen:

			tutorial_active = false

			if tutorial != null:

				tutorial.hide()

			start_challenge()

		else:

			_setup_tutorial()


	else:

		tutorial_active = false

		if tutorial != null:

			tutorial.hide()

		if enter_label != null:

			enter_label.queue_free()

			enter_label = null

		_setup_pre_start_screen()


	# =====================================================
	# COMBINAÇÕES
	# =====================================================

	_build_combinations()


# =========================================================
# PROCESS
# =========================================================

func _process(
	delta: float
) -> void:

	if not challenge_active:

		return


	if not timer_running:

		return


	if result_screen_active:

		return


	time_left -= delta


	if time_left <= 0.0:

		time_left = 0.0

		_update_timer_ui()

		_time_finished()

		return


	_update_timer_ui()


# =========================================================
# QUANTIDADE DE CORES
# =========================================================

func get_active_color_count() -> int:

	match difficulty:

		1:
			return 3

		2:
			return 4

		3:
			return 6


	return 3


# =========================================================
# CORES ATIVAS
# =========================================================

func get_active_colors() -> Array:

	return color_names.slice(
		0,
		get_active_color_count()
	)


# =========================================================
# LIMITE DE COMBINAÇÕES
# =========================================================

func get_combination_limit() -> int:

	match difficulty:

		1:
			return 6

		2:
			return 10

		3:
			return 14


	return 6


# =========================================================
# CRIA TIMER
# =========================================================

func _create_timer_ui() -> void:

	timer_panel = Panel.new()

	timer_panel.name = "TimerPanel"

	timer_panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	timer_panel.custom_minimum_size = Vector2(
		145,
		62
	)

	timer_panel.size = Vector2(
		145,
		62
	)

	timer_panel.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	timer_panel.position = Vector2(
		-165,
		28
	)


	# =====================================================
	# FUNDO DO TIMER
	# =====================================================

	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = Color(
		"#211A2B"
	)

	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2

	panel_style.border_color = TIMER_PURPLE

	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12

	panel_style.shadow_color = Color(
		0,
		0,
		0,
		0.40
	)

	panel_style.shadow_size = 6

	panel_style.shadow_offset = Vector2(
		0,
		3
	)


	timer_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)


	# =====================================================
	# ÍCONE
	# =====================================================

	timer_icon_label = Label.new()

	timer_icon_label.text = "⏱"

	timer_icon_label.position = Vector2(
		12,
		15
	)

	timer_icon_label.size = Vector2(
		35,
		30
	)

	timer_icon_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	timer_icon_label.add_theme_font_size_override(
		"font_size",
		24
	)

	timer_icon_label.add_theme_color_override(
		"font_color",
		TIMER_PURPLE
	)

	timer_icon_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	timer_icon_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	timer_panel.add_child(
		timer_icon_label
	)


	# =====================================================
	# NÚMERO
	# =====================================================

	timer_label = Label.new()

	timer_label.text = "20"

	timer_label.position = Vector2(
		50,
		8
	)

	timer_label.size = Vector2(
		82,
		45
	)

	timer_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	timer_label.add_theme_font_size_override(
		"font_size",
		32
	)

	timer_label.add_theme_color_override(
		"font_color",
		TIMER_PURPLE
	)

	timer_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	timer_label.add_theme_constant_override(
		"outline_size",
		4
	)

	timer_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	timer_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	timer_panel.add_child(
		timer_label
	)


	add_child(
		timer_panel
	)


	_update_timer_ui()


# =========================================================
# ATUALIZA TIMER
# =========================================================

func _update_timer_ui() -> void:

	if timer_label == null:

		return


	var seconds := int(
		ceil(time_left)
	)


	timer_label.text = str(
		seconds
	)


	var timer_color := TIMER_PURPLE


	if time_left <= 10.0:

		timer_color = TIMER_PURPLE_LIGHT


	if time_left <= 5.0:

		timer_color = TIMER_PURPLE_DARK


	timer_label.add_theme_color_override(
		"font_color",
		timer_color
	)


	if timer_icon_label != null:

		timer_icon_label.add_theme_color_override(
			"font_color",
			timer_color
		)


	if time_left <= 5.0 and time_left > 0.0:

		_start_timer_pulse()

	else:

		_stop_timer_pulse()


# =========================================================
# PULSO DO TIMER
# =========================================================

func _start_timer_pulse() -> void:

	if timer_panel == null:

		return


	if timer_pulse_tween != null:

		if timer_pulse_tween.is_running():

			return


	timer_pulse_tween = create_tween()

	timer_pulse_tween.set_loops()


	timer_pulse_tween.tween_property(
		timer_panel,
		"scale",
		Vector2(
			1.05,
			1.05
		),
		0.18
	).set_trans(
		Tween.TRANS_SINE
	)


	timer_pulse_tween.tween_property(
		timer_panel,
		"scale",
		Vector2(
			1.0,
			1.0
		),
		0.18
	).set_trans(
		Tween.TRANS_SINE
	)


# =========================================================
# PARA PULSO
# =========================================================

func _stop_timer_pulse() -> void:

	if timer_pulse_tween != null:

		timer_pulse_tween.kill()

		timer_pulse_tween = null


	if timer_panel != null:

		timer_panel.scale = Vector2(
			1.0,
			1.0
		)


# =========================================================
# +2 SEGUNDOS
# =========================================================

func add_time() -> void:

	time_left += 2.0


	if time_left > MAX_TIME:

		time_left = MAX_TIME


	_update_timer_ui()


# =========================================================
# -5 SEGUNDOS
# =========================================================

func remove_time() -> void:

	time_left -= 5.0


	if time_left < 0.0:

		time_left = 0.0


	_update_timer_ui()


# =========================================================
# TEMPO ESGOTADO
# =========================================================

func _time_finished() -> void:

	if not challenge_active:

		return


	challenge_active = false

	can_answer = false

	timer_running = false

	time_up_message = true

	result_screen_active = true


	_stop_timer_pulse()


	instruction_label.hide()

	word_label.hide()

	progress_label.hide()

	result_label.hide()


	for button in color_buttons.values():

		if is_instance_valid(
			button
		):

			button.hide()


	if timer_panel != null:

		timer_panel.hide()


	_show_final_screen(
		false
	)


# =========================================================
# TUTORIAL
# =========================================================

func _setup_tutorial() -> void:

	if difficulty != 1:

		if tutorial != null:

			tutorial.hide()


		tutorial_active = false


		start_challenge()


		return


	if tutorial == null:

		start_challenge()

		return


	tutorial.show()


	tutorial_active = true


	tutorial.z_index = 1000


	tutorial.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	if tutorial_stroop != null:

		tutorial_stroop.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)


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
# ENTER DO TUTORIAL
# =========================================================

func _create_enter_label() -> void:

	if tutorial_button == null:

		return


	if enter_label != null:

		enter_label.queue_free()


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
# BOTÃO TUTORIAL
# =========================================================

func _on_tutorial_button_pressed() -> void:

	if not tutorial_active:

		return


	get_tree().set_meta(
		"stroop_tutorial_seen",
		true
	)

	tutorial_active = false


	if tutorial != null:

		tutorial.hide()


	if enter_label != null:

		enter_label.queue_free()

		enter_label = null


	start_challenge()


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	# =====================================================
	# TELA DE PREPARAÇÃO
	# =====================================================

	if pre_start_active:

		if event.is_action_pressed(
			"ui_accept"
		):

			if pre_start_button != null:

				pre_start_button.grab_focus()

				pre_start_button.pressed.emit()


			get_viewport().set_input_as_handled()


		return


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

		if event.is_action_pressed(
			"ui_accept"
		):

			if final_enter_button != null:

				final_enter_button.grab_focus()

				final_enter_button.pressed.emit()


			get_viewport().set_input_as_handled()


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


	if event is InputEventKey:

		match event.keycode:

			KEY_1:

				_answer(
					"vermelho"
				)

				get_viewport().set_input_as_handled()


			KEY_2:

				_answer(
					"azul"
				)

				get_viewport().set_input_as_handled()


			KEY_3:

				_answer(
					"verde"
				)

				get_viewport().set_input_as_handled()


			KEY_4:

				if get_active_color_count() >= 4:

					_answer(
						"amarelo"
					)

					get_viewport().set_input_as_handled()


			KEY_5:

				if get_active_color_count() >= 5:

					_answer(
						"roxo"
					)

					get_viewport().set_input_as_handled()


			KEY_6:

				if get_active_color_count() >= 6:

					_answer(
						"laranja"
					)

					get_viewport().set_input_as_handled()


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


	if time_up_message:
		return


	if not challenge_active:
		return


	if not can_answer:
		return


	can_answer = false


	if selected_color == current_color:

		correct_answers += 1


		add_time()


		progress_label.text = (
			"%d / %d"
			% [
				correct_answers,
				TOTAL_ACERTOS
			]
		)


		result_label.text = (
			"+2s   CORRETO!"
		)


		result_label.add_theme_color_override(
			"font_color",
			SUCCESS_COLOR
		)


		result_label.modulate = Color.WHITE

		result_label.self_modulate = Color.WHITE

		result_label.visible = true


		if correct_answers >= TOTAL_ACERTOS:

			_complete_challenge()

			return


	else:

		error_count += 1


		remove_time()


		if time_left <= 0.0:

			_time_finished()

			return


		progress_label.text = (
			"%d / %d"
			% [
				correct_answers,
				TOTAL_ACERTOS
			]
		)


		result_label.text = (
			"-5s   ERRO!"
		)


		result_label.add_theme_color_override(
			"font_color",
			ERROR_COLOR
		)


		result_label.modulate = Color.WHITE

		result_label.self_modulate = Color.WHITE

		result_label.visible = true


	await get_tree().create_timer(
		0.75
	).timeout


	if not challenge_active:
		return


	if time_up_message:
		return


	result_label.text = ""

	result_label.visible = true


	_new_round()


# =========================================================
# CONFIGURA BOTÕES
# =========================================================

func _setup_color_buttons() -> void:

	color_buttons.clear()

	extra_buttons.clear()


	color_buttons["vermelho"] = red_button

	_setup_button(
		red_button,
		"vermelho",
		1
	)


	color_buttons["azul"] = blue_button

	_setup_button(
		blue_button,
		"azul",
		2
	)


	color_buttons["verde"] = green_button

	_setup_button(
		green_button,
		"verde",
		3
	)


	if get_active_color_count() >= 4:

		_create_extra_button(
			"amarelo",
			4
		)


	if get_active_color_count() >= 5:

		_create_extra_button(
			"roxo",
			5
		)


	if get_active_color_count() >= 6:

		_create_extra_button(
			"laranja",
			6
		)


	# =====================================================
	# DESAFIO 2
	# =====================================================

	if difficulty == 2:

		for button in color_buttons.values():

			if is_instance_valid(
				button
			):

				button.custom_minimum_size = Vector2(
					200,
					64
				)

				button.add_theme_font_size_override(
					"font_size",
					18
				)

				_force_white_text(
					button
				)


	# =====================================================
	# DESAFIO 3
	# =====================================================

	if difficulty == 3:

		for button in color_buttons.values():

			if is_instance_valid(
				button
			):

				button.custom_minimum_size = Vector2(
					155,
					56
				)

				button.add_theme_font_size_override(
					"font_size",
					16
				)

				_force_white_text(
					button
				)


# =========================================================
# CONFIGURA BOTÃO
# =========================================================

func _setup_button(
	button: Button,
	color_name: String,
	number: int
) -> void:

	button.text = (
		"[ %d ]  %s"
		% [
			number,
			color_name.to_upper()
		]
	)

	button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	button.focus_mode = (
		Control.FOCUS_ALL
	)


	_style_button(
		button,
		colors[color_name]
	)


	for connection in button.pressed.get_connections():

		var callable: Callable = (
			connection["callable"]
		)

		if callable.is_valid():

			button.pressed.disconnect(
				callable
			)


	button.pressed.connect(
		func():
			_answer(
				color_name
			)
	)


	_force_white_text(
		button
	)


# =========================================================
# BOTÃO EXTRA
# =========================================================

func _create_extra_button(
	color_name: String,
	number: int
) -> void:

	var button := Button.new()

	button.name = (
		color_name.capitalize()
		+ "Button"
	)

	button.text = (
		"[ %d ]  %s"
		% [
			number,
			color_name.to_upper()
		]
	)

	button.focus_mode = (
		Control.FOCUS_ALL
	)

	button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	_style_button(
		button,
		colors[color_name]
	)


	button.pressed.connect(
		func():
			_answer(
				color_name
			)
	)


	var parent := red_button.get_parent()


	if parent == null:

		push_error(
			"Parent dos botões não encontrado."
		)

		return


	parent.add_child(
		button
	)


	color_buttons[color_name] = button

	extra_buttons.append(
		button
	)


	_force_white_text(
		button
	)


# =========================================================
# FORÇA TEXTO BRANCO NOS BOTÕES
# =========================================================

func _force_white_text(
	button: Button
) -> void:

	if button == null:

		return


	button.modulate = Color.WHITE

	button.self_modulate = Color.WHITE


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
		"font_hover_pressed_color",
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


# =========================================================
# COMEÇA DESAFIO
# =========================================================

func start_challenge() -> void:

	_clear_final_screen()


	instruction_label.show()

	instruction_label.modulate = Color.WHITE

	instruction_label.self_modulate = Color.WHITE


	word_label.show()

	word_label.modulate = Color.WHITE

	word_label.self_modulate = Color.WHITE


	progress_label.show()

	progress_label.modulate = Color.WHITE

	progress_label.self_modulate = Color.WHITE


	result_label.show()

	result_label.modulate = Color.WHITE

	result_label.self_modulate = Color.WHITE


	for button in color_buttons.values():

		if is_instance_valid(
			button
		):

			button.show()

			button.mouse_filter = (
				Control.MOUSE_FILTER_STOP
			)


	correct_answers = 0

	error_count = 0

	challenge_active = true

	can_answer = false

	result_screen_active = false

	time_up_message = false


	time_left = INITIAL_TIME

	timer_running = true


	if timer_panel != null:

		timer_panel.show()

		timer_panel.modulate = Color.WHITE

		timer_panel.scale = Vector2(
			1.0,
			1.0
		)


	progress_label.text = (
		"0 / %d"
		% TOTAL_ACERTOS
	)

	result_label.text = ""

	result_label.visible = true


	instruction_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	instruction_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	word_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	progress_label.add_theme_color_override(
		"font_color",
		PURPLE_COLOR
	)

	progress_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	result_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)


	_update_timer_ui()

	_build_combinations()

	_new_round()


# =========================================================
# CONSTRÓI COMBINAÇÕES
# =========================================================

func _build_combinations() -> void:

	stroop_combinations.clear()


	var active_colors: Array = (
		get_active_colors()
	)


	for word in active_colors:

		for color in active_colors:

			if word == color:

				continue


			stroop_combinations.append({
				"word": word,
				"color": color
			})


	stroop_combinations.shuffle()


	var limit := get_combination_limit()


	if stroop_combinations.size() > limit:

		stroop_combinations = (
			stroop_combinations.slice(
				0,
				limit
			)
		)


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


		if stroop_combinations.size() > 1:

			var first_combination: Dictionary = (
				stroop_combinations[0]
			)


			if (
				first_combination["word"] == last_word
				and first_combination["color"] == last_color
			):

				var swap_index := randi_range(
					1,
					stroop_combinations.size() - 1
				)


				var temp: Dictionary = (
					stroop_combinations[0]
				)


				stroop_combinations[0] = (
					stroop_combinations[
						swap_index
					]
				)


				stroop_combinations[
					swap_index
				] = temp


	return stroop_combinations[
		current_combination_index
	]


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

	word_label.visible = true

	word_label.modulate = Color.WHITE

	word_label.self_modulate = Color.WHITE


	word_label.add_theme_color_override(
		"font_color",
		colors[current_color]
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


	await get_tree().create_timer(
		0.35
	).timeout


	if not challenge_active:

		return


	if time_up_message:

		return


	can_answer = true


# =========================================================
# FRAGMENTO DE ATENÇÃO
# =========================================================

func _award_attention_fragment() -> void:

	var fragment_key := (
		"stroop_fragment_awarded_"
		+ str(difficulty)
	)


	if get_tree().has_meta(
		fragment_key
	):

		return


	get_tree().set_meta(
		fragment_key,
		true
	)


	Globals.atencao_fragments += 1


	print(
		"================================"
	)

	print(
		"FRAGMENTO DE ATENÇÃO +1"
	)

	print(
		"DESAFIO: ",
		difficulty
	)

	print(
		"TOTAL: ",
		Globals.atencao_fragments
	)

	print(
		"================================"
	)


# =========================================================
# DESAFIO CONCLUÍDO
# =========================================================

func _complete_challenge() -> void:

	_award_attention_fragment()


	challenge_active = false

	can_answer = false

	timer_running = false

	result_screen_active = true

	time_up_message = false


	_stop_timer_pulse()


	instruction_label.hide()

	word_label.hide()

	progress_label.hide()

	result_label.hide()


	for button in color_buttons.values():

		if is_instance_valid(
			button
		):

			button.hide()


	if timer_panel != null:

		timer_panel.hide()


	_show_final_screen(
		true
	)


# =========================================================
# TELA FINAL
# =========================================================

func _show_final_screen(
	success: bool
) -> void:

	_clear_final_screen()


	final_title_label = Label.new()


	if success:

		final_title_label.text = (
			"✦  DESAFIO CONCLUÍDO!  ✦"
		)

	else:

		final_title_label.text = (
			"✦  TEMPO ESGOTADO!  ✦"
		)


	final_title_label.set_anchors_preset(
		Control.PRESET_CENTER_TOP
	)

	final_title_label.position = Vector2(
		-500,
		65
	)

	final_title_label.size = Vector2(
		1000,
		65
	)

	final_title_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	final_title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	final_title_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	final_title_label.add_theme_font_size_override(
		"font_size",
		38
	)

	final_title_label.add_theme_color_override(
		"font_color",
		FINAL_WHITE
	)

	final_title_label.add_theme_color_override(
		"font_outline_color",
		Color("#101820")
	)

	final_title_label.add_theme_constant_override(
		"outline_size",
		7
	)

	add_child(
		final_title_label
	)


	final_info_label = Label.new()


	if success:

		final_info_label.text = (
			"✦  FRAGMENTO DE ATENÇÃO  ✦\n"
			+ "+1"
		)

	else:

		final_info_label.text = (
			str(correct_answers)
			+ " / "
			+ str(TOTAL_ACERTOS)
			+ "\n"
			+ "ACERTOS"
		)


	final_info_label.set_anchors_preset(
		Control.PRESET_CENTER_TOP
	)

	final_info_label.position = Vector2(
		-430,
		150
	)

	final_info_label.size = Vector2(
		860,
		115
	)

	final_info_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	final_info_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	final_info_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	final_info_label.add_theme_font_size_override(
		"font_size",
		28
	)

	final_info_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	final_info_label.add_theme_color_override(
		"font_outline_color",
		Color("#101820")
	)

	final_info_label.add_theme_constant_override(
		"outline_size",
		5
	)

	add_child(
		final_info_label
	)


	final_error_label = Label.new()

	final_error_label.text = (
		"ERROS: "
		+ str(error_count)
	)

	final_error_label.set_anchors_preset(
		Control.PRESET_CENTER_TOP
	)

	final_error_label.position = Vector2(
		-300,
		285
	)

	final_error_label.size = Vector2(
		600,
		45
	)

	final_error_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	final_error_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	final_error_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	final_error_label.add_theme_font_size_override(
		"font_size",
		21
	)

	final_error_label.add_theme_color_override(
		"font_color",
		FINAL_TEXT
	)

	final_error_label.add_theme_color_override(
		"font_outline_color",
		Color("#101820")
	)

	final_error_label.add_theme_constant_override(
		"outline_size",
		4
	)

	add_child(
		final_error_label
	)


	final_enter_button = Button.new()

	final_enter_button.name = (
		"FinalEnterButton"
	)


	if success:

		final_enter_button.text = (
			"↵   CONTINUAR"
		)

	else:

		final_enter_button.text = (
			"↻   TENTAR NOVAMENTE"
		)


	final_enter_button.set_anchors_preset(
		Control.PRESET_CENTER_BOTTOM
	)

	final_enter_button.position = Vector2(
		-125,
		-80
	)

	final_enter_button.size = Vector2(
		250,
		48
	)

	final_enter_button.custom_minimum_size = Vector2(
		250,
		48
	)

	final_enter_button.focus_mode = (
		Control.FOCUS_ALL
	)

	final_enter_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	final_enter_button.add_theme_font_size_override(
		"font_size",
		18
	)

	final_enter_button.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	final_enter_button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	final_enter_button.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)

	final_enter_button.add_theme_color_override(
		"font_focus_color",
		Color.WHITE
	)

	final_enter_button.add_theme_color_override(
		"font_outline_color",
		Color("#111820")
	)

	final_enter_button.add_theme_constant_override(
		"outline_size",
		2
	)


	_style_final_button(
		final_enter_button
	)


	final_enter_button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)


	if success:

		final_enter_button.pressed.connect(
			_close_result_screen
		)

	else:

		final_enter_button.pressed.connect(
			_restart_after_timeout
		)


	add_child(
		final_enter_button
	)


	final_enter_button.grab_focus()


	final_title_label.modulate = Color(
		1,
		1,
		1,
		0
	)

	final_info_label.modulate = Color(
		1,
		1,
		1,
		0
	)

	final_error_label.modulate = Color(
		1,
		1,
		1,
		0
	)

	final_enter_button.modulate = Color(
		1,
		1,
		1,
		0
	)


	var tween := create_tween()

	tween.set_parallel(true)


	tween.tween_property(
		final_title_label,
		"modulate",
		Color.WHITE,
		0.20
	)

	tween.tween_property(
		final_info_label,
		"modulate",
		Color.WHITE,
		0.25
	)

	tween.tween_property(
		final_error_label,
		"modulate",
		Color.WHITE,
		0.30
	)

	tween.tween_property(
		final_enter_button,
		"modulate",
		Color.WHITE,
		0.40
	)


# =========================================================
# ESCONDE TEXTOS ANTIGOS DE ENTER
# =========================================================

func _hide_old_enter_hints() -> void:

	for node in find_children(
		"*",
		"Label",
		true,
		false
	):

		if not node is Label:

			continue


		var label := node as Label

		var text := label.text.to_upper()


		if text.contains("ENTER") and (
			text.contains("COMEÇ")
			or text.contains("COMEC")
			or text.contains("INICI")
			or text.contains("PARA COMEÇAR")
			or text.contains("PARA INICIAR")
		):

			label.visible = false


# =========================================================
# TRANSIÇÃO DE ENTRADA DA FASE
# =========================================================

func _setup_scene_fade_in() -> void:

	if scene_fade != null:

		return


	scene_fade = ColorRect.new()

	scene_fade.name = "SceneFadeIn"

	scene_fade.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)

	scene_fade.offset_left = 0
	scene_fade.offset_top = 0
	scene_fade.offset_right = 0
	scene_fade.offset_bottom = 0

	scene_fade.color = Color(
		0,
		0,
		0,
		1
	)

	scene_fade.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	scene_fade.z_index = 5000


	add_child(
		scene_fade
	)

	move_child(
		scene_fade,
		get_child_count() - 1
	)


	scene_fade_tween = create_tween()


	scene_fade_tween.tween_property(
		scene_fade,
		"modulate:a",
		0.0,
		0.65
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	scene_fade_tween.tween_callback(
		func():
			if is_instance_valid(
				scene_fade
			):

				scene_fade.queue_free()


			scene_fade = null

			scene_fade_tween = null
	)


# =========================================================
# TELA DE PREPARAÇÃO
# =========================================================

func _setup_pre_start_screen() -> void:

	pre_start_active = true

	_hide_old_enter_hints()


	instruction_label.hide()

	word_label.hide()

	progress_label.hide()

	result_label.hide()


	for button in color_buttons.values():

		if is_instance_valid(
			button
		):

			button.hide()


	if timer_panel != null:

		timer_panel.hide()


	# =====================================================
	# FUNDO ESCURO
	# =====================================================

	pre_start_overlay = ColorRect.new()

	pre_start_overlay.name = "PreStartOverlay"

	pre_start_overlay.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)

	pre_start_overlay.color = Color(
		0.02,
		0.03,
		0.07,
		0.78
	)

	pre_start_overlay.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	pre_start_overlay.z_index = 900

	add_child(
		pre_start_overlay
	)


	# =====================================================
	# PAINEL PRINCIPAL
	# =====================================================

	pre_start_panel = Panel.new()

	pre_start_panel.name = "PreStartPanel"

	pre_start_panel.set_anchors_preset(
		Control.PRESET_CENTER
	)

	pre_start_panel.position = Vector2(
		-335,
		-205
	)

	pre_start_panel.size = Vector2(
		670,
		410
	)

	pre_start_panel.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	pre_start_panel.z_index = 901


	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = Color(
		"#121827"
	)

	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3

	panel_style.border_color = Color(
		"#8D52D8"
	)

	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18

	panel_style.shadow_color = Color(
		0,
		0,
		0,
		0.55
	)

	panel_style.shadow_size = 14

	panel_style.shadow_offset = Vector2(
		0,
		7
	)


	pre_start_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	add_child(
		pre_start_panel
	)


	# =====================================================
	# LINHA SUPERIOR
	# =====================================================

	var accent := ColorRect.new()

	accent.color = Color(
		"#A477D6"
	)

	accent.position = Vector2(
		45,
		40
	)

	accent.size = Vector2(
		580,
		3
	)

	pre_start_panel.add_child(
		accent
	)


	# =====================================================
	# TÍTULO
	# =====================================================

	pre_start_title_label = Label.new()

	pre_start_title_label.text = "PREPARE-SE!"

	pre_start_title_label.position = Vector2(
		45,
		65
	)

	pre_start_title_label.size = Vector2(
		580,
		70
	)

	pre_start_title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	pre_start_title_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	pre_start_title_label.add_theme_font_size_override(
		"font_size",
		42
	)

	pre_start_title_label.add_theme_color_override(
		"font_color",
		Color(
			"#F4F7FA"
		)
	)

	pre_start_title_label.add_theme_color_override(
		"font_outline_color",
		Color(
			"#070B12"
		)
	)

	pre_start_title_label.add_theme_constant_override(
		"outline_size",
		6
	)

	pre_start_title_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	pre_start_panel.add_child(
		pre_start_title_label
	)


	# =====================================================
	# SUBTÍTULO
	# =====================================================

	pre_start_subtitle_label = Label.new()

	pre_start_subtitle_label.text = (
		"DESAFIO DE NÍVEL "
		+ str(difficulty)
	)

	pre_start_subtitle_label.position = Vector2(
		70,
		138
	)

	pre_start_subtitle_label.size = Vector2(
		530,
		40
	)

	pre_start_subtitle_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	pre_start_subtitle_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	pre_start_subtitle_label.add_theme_font_size_override(
		"font_size",
		24
	)

	pre_start_subtitle_label.add_theme_color_override(
		"font_color",
		Color(
			"#A477D6"
		)
	)

	pre_start_subtitle_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	pre_start_subtitle_label.add_theme_constant_override(
		"outline_size",
		3
	)

	pre_start_subtitle_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	pre_start_panel.add_child(
		pre_start_subtitle_label
	)


	# =====================================================
	# FRASE
	# =====================================================

	var message_label := Label.new()

	message_label.text = (
		"Atenção redobrada. O próximo desafio"
		+ " será ainda mais difícil."
	)

	message_label.position = Vector2(
		70,
		180
	)

	message_label.size = Vector2(
		530,
		48
	)

	message_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	message_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	message_label.add_theme_font_size_override(
		"font_size",
		16
	)

	message_label.add_theme_color_override(
		"font_color",
		Color(
			"#DCE4E9"
		)
	)

	message_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	pre_start_panel.add_child(
		message_label
	)


	# =====================================================
	# BOTÃO ENTER
	# =====================================================

	pre_start_button = Button.new()

	pre_start_button.name = "PreStartButton"

	pre_start_button.text = (
		"↵ COMEÇAR"
	)

	pre_start_button.position = Vector2(
		190,
		250
	)

	pre_start_button.size = Vector2(
		290,
		58
	)

	pre_start_button.custom_minimum_size = Vector2(
		290,
		58
	)

	pre_start_button.focus_mode = (
		Control.FOCUS_ALL
	)

	pre_start_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	pre_start_button.add_theme_font_size_override(
		"font_size",
		20
	)

	pre_start_button.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	pre_start_button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	pre_start_button.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)

	pre_start_button.add_theme_color_override(
		"font_focus_color",
		Color.WHITE
	)

	pre_start_button.add_theme_color_override(
		"font_outline_color",
		Color(
			"#111820"
		)
	)

	pre_start_button.add_theme_constant_override(
		"outline_size",
		2
	)


	_style_final_button(
		pre_start_button
	)


	pre_start_button.pressed.connect(
		_start_pre_start_screen
	)


	pre_start_panel.add_child(
		pre_start_button
	)


	# =====================================================
	# FOCO
	# =====================================================

	pre_start_button.grab_focus()


	# =====================================================
	# PISCAR BOTÃO
	# =====================================================

	pre_start_tween = create_tween()

	pre_start_tween.set_loops()


	pre_start_tween.tween_property(
		pre_start_button,
		"modulate:a",
		0.65,
		0.55
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


	pre_start_tween.tween_property(
		pre_start_button,
		"modulate:a",
		1.0,
		0.55
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


# =========================================================
# INICIA APÓS A TELA DE PREPARAÇÃO
# =========================================================

func _start_pre_start_screen() -> void:

	if not pre_start_active:

		return


	pre_start_active = false


	if pre_start_tween != null:

		pre_start_tween.kill()

		pre_start_tween = null


	_clear_pre_start_screen()


	start_challenge()


# =========================================================
# LIMPA TELA DE PREPARAÇÃO
# =========================================================

func _clear_pre_start_screen() -> void:

	if pre_start_tween != null:

		pre_start_tween.kill()

		pre_start_tween = null


	if pre_start_overlay != null:

		if is_instance_valid(
			pre_start_overlay
		):

			pre_start_overlay.queue_free()

		pre_start_overlay = null


	if pre_start_panel != null:

		if is_instance_valid(
			pre_start_panel
		):

			pre_start_panel.queue_free()

		pre_start_panel = null


	pre_start_title_label = null

	pre_start_subtitle_label = null

	pre_start_hint_label = null

	pre_start_button = null


# =========================================================
# ESTILO DO BOTÃO FINAL
# =========================================================

func _style_final_button(
	button: Button
) -> void:

	var normal := StyleBoxFlat.new()

	normal.bg_color = FINAL_BUTTON

	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2

	normal.border_color = Color(
		"#AEB8BE"
	)

	normal.corner_radius_top_left = 9
	normal.corner_radius_top_right = 9
	normal.corner_radius_bottom_left = 9
	normal.corner_radius_bottom_right = 9

	normal.shadow_color = Color(
		0,
		0,
		0,
		0.38
	)

	normal.shadow_size = 4

	normal.shadow_offset = Vector2(
		0,
		3
	)


	var hover := normal.duplicate()

	hover.bg_color = FINAL_BUTTON_HOVER

	hover.border_color = Color(
		"#E2E7EA"
	)

	hover.shadow_color = Color(
		0,
		0,
		0,
		0.55
	)

	hover.shadow_size = 7


	var pressed := normal.duplicate()

	pressed.bg_color = FINAL_BUTTON_PRESSED

	pressed.border_color = Color(
		"#929DA4"
	)

	pressed.shadow_size = 2

	pressed.shadow_offset = Vector2(
		0,
		1
	)


	var focus := normal.duplicate()

	focus.bg_color = FINAL_BUTTON_HOVER

	focus.border_color = Color.WHITE

	focus.shadow_size = 7


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


# =========================================================
# LIMPA TELA FINAL
# =========================================================

func _clear_final_screen() -> void:

	if final_title_label != null:

		if is_instance_valid(
			final_title_label
		):

			final_title_label.queue_free()

		final_title_label = null


	if final_info_label != null:

		if is_instance_valid(
			final_info_label
		):

			final_info_label.queue_free()

		final_info_label = null


	if final_error_label != null:

		if is_instance_valid(
			final_error_label
		):

			final_error_label.queue_free()

		final_error_label = null


	if final_enter_button != null:

		if is_instance_valid(
			final_enter_button
		):

			final_enter_button.queue_free()

		final_enter_button = null


# =========================================================
# FECHA RESULTADO
# =========================================================

func _close_result_screen() -> void:

	if not result_screen_active:

		return


	result_screen_active = false

	time_up_message = false


	_clear_final_screen()


	# =====================================================
	# ANIMAÇÃO DE VITÓRIA DO PLAYER
	# =====================================================

	var player := get_tree().get_first_node_in_group(
		"player"
	)


	if player != null:

		if player.has_method("play_victory"):

			player.play_victory()


	# =====================================================
	# AVISA AO MAPA QUE O DESAFIO TERMINOU
	# =====================================================

	challenge_completed.emit()


# =========================================================
# TENTA NOVAMENTE
# =========================================================

func _restart_after_timeout() -> void:

	if not result_screen_active:

		return


	result_screen_active = false

	time_up_message = false


	_clear_final_screen()


	start_challenge()


# =========================================================
# ESTILO TUTORIAL
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


	var normal := StyleBoxFlat.new()

	normal.bg_color = Color(
		"#7B3FC6"
	)

	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2

	normal.border_color = Color.BLACK

	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8


	var hover := normal.duplicate()

	hover.bg_color = Color(
		"#A75AEA"
	)


	var pressed := normal.duplicate()

	pressed.bg_color = Color(
		"#5E299A"
	)


	var focus := normal.duplicate()

	focus.bg_color = Color(
		"#8A48D8"
	)


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
# ESTILO DOS BOTÕES DE COR
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
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_outline_color",
		Color("#17131F")
	)

	button.add_theme_constant_override(
		"outline_size",
		2
	)


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


	var pressed := normal.duplicate()

	pressed.bg_color = color.darkened(
		0.28
	)

	pressed.shadow_size = 1

	pressed.shadow_offset = Vector2(
		0,
		1
	)


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


	_force_white_text(
		button
	)


# =========================================================
# COMPATIBILIDADE
# =========================================================

func _enable_buttons(
	enabled: bool
) -> void:

	for button in color_buttons.values():

		if is_instance_valid(
			button
		):

			if enabled:

				button.mouse_filter = (
					Control.MOUSE_FILTER_STOP
				)

			else:

				button.mouse_filter = (
					Control.MOUSE_FILTER_IGNORE
				)


			_force_white_text(
				button
			)
			
