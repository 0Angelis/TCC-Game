extends Node

# ============================================================
# BOSS CHALLENGE MANAGER
# ============================================================
# REGRAS:
#
# ACERTO:
# -> desafio termina
# -> boss recebe dano
# -> volta para a luta
#
# ERRO:
# -> NÃO fecha o desafio
# -> perde 5 segundos
# -> continua no mesmo desafio
#
# TEMPO:
# -> 18 segundos
#
# ============================================================


signal challenge_finished(
	correct: bool,
	challenge_type: String
)


# ============================================================
# CONFIGURAÇÃO
# ============================================================

const FONT_PATH: String = (
	"res://assets/Fontes/Pixeloid_Font_1_0/"
	+ "OpenType (.otf)/PixeloidSans-Bold.otf"
)

const WRONG_PENALTY: float = 5.0

const CHALLENGE_TIME: float = 18.0

const SOM_CLICK_BUTTON: AudioStream = preload("res://sounds/click_button.wav")

@export_range(-40.0, 20.0, 0.5)
var volume_click_button_db: float = 20.0


# ============================================================
# CORES
# ============================================================

const PURPLE: Color = Color("#8E4EDB")
const PURPLE_LIGHT: Color = Color("#C39BFF")

const PANEL: Color = Color("#120D1B")
const PANEL_2: Color = Color("#1B1327")

const WHITE: Color = Color("#F8F5FF")
const MUTED: Color = Color("#BDB5C9")

const GREEN: Color = Color("#78E08F")
const RED: Color = Color("#FF6B7A")
const GOLD: Color = Color("#FFD166")

const BLUE: Color = Color("#55A8FF")


# ============================================================
# UI
# ============================================================

var canvas: CanvasLayer = null
var root: Control = null

var dim: ColorRect = null
var card: Panel = null

var title_label: Label = null
var instruction_label: Label = null

var challenge_body: VBoxContainer = null

var timer_label: Label = null
var feedback_label: Label = null

var start_prompt: Panel = null
var start_prompt_label: Label = null

var audio_click_button: AudioStreamPlayer = null


# ============================================================
# ESTADO
# ============================================================

var current_type: String = ""
var current_round: int = 0

var state: String = "idle"

var challenge_time_left: float = 0.0
var challenge_limit: float = CHALLENGE_TIME

var input_locked: bool = false

var external_start_prompt: bool = false

# O destaque do teclado so aparece depois que uma SETA e usada.
# O mouse limpa o destaque imediatamente.
var keyboard_navigation_enabled: bool = false
var keyboard_selected_index: int = -1


# ============================================================
# BOTÕES
# ============================================================

var active_buttons: Array[Button] = []

var memory_buttons: Array[Button] = []


# ============================================================
# RESPOSTAS
# ============================================================

var logic_answer: int = 0

var attention_answer: String = ""
var attention_word: String = ""
var last_attention_answer: String = ""

# Cores usadas nos desafios de atenção.
# Cada desafio sempre mostra apenas UMA alternativa de cada cor.
const ATTENTION_COLORS: Array[String] = [
	"VERMELHO",
	"AZUL",
	"VERDE",
	"AMARELO",
	"ROXO",
	"LARANJA"
]

const ATTENTION_COLOR_VALUES: Dictionary = {
	"VERMELHO": Color("#F04B58"),
	"AZUL": Color("#55A8FF"),
	"VERDE": Color("#78E08F"),
	"AMARELO": Color("#FFD166"),
	"ROXO": Color("#B47CFF"),
	"LARANJA": Color("#FF9F43")
}

var memory_sequence: Array[String] = []

var memory_position: int = 0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	_setup_click_sound()

	_build_ui()

	hide_all()


# ============================================================
# SOM DE CLIQUE
# ============================================================

func _setup_click_sound() -> void:

	audio_click_button = AudioStreamPlayer.new()
	audio_click_button.name = "AudioClickButton"
	audio_click_button.stream = SOM_CLICK_BUTTON
	audio_click_button.volume_db = volume_click_button_db
	audio_click_button.bus = "Master"
	audio_click_button.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(audio_click_button)


func _play_click_sound() -> void:

	if audio_click_button == null:
		return

	audio_click_button.volume_db = volume_click_button_db
	audio_click_button.play()


# ============================================================
# PROCESS
# ============================================================

func _process(
	delta: float
) -> void:

	if state != "active":
		return

	if input_locked:
		return

	challenge_time_left -= delta

	if timer_label != null:

		timer_label.text = (
			"%02d"
			% max(
				0,
				int(
					ceil(
						challenge_time_left
					)
				)
			)
		)

	if challenge_time_left <= 0.0:

		_timeout_finish()


# ============================================================
# INPUT
# ============================================================

func _input(
	event: InputEvent
) -> void:

	if input_locked:
		return

	if state == "ready":
		if event is InputEventKey:
			var start_key: InputEventKey = event as InputEventKey
			if not start_key.pressed or start_key.echo:
				return
			if start_key.keycode == KEY_ENTER or start_key.keycode == KEY_KP_ENTER:
				_play_click_sound()
				start_current_challenge()
				get_viewport().set_input_as_handled()
				return
		return

	if state != "active":
		return

	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_LEFT or key_event.keycode == KEY_UP:
		_move_keyboard_focus(-1)
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_RIGHT or key_event.keycode == KEY_DOWN:
		_move_keyboard_focus(1)
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_1 or key_event.keycode == KEY_KP_1:
		_press_index(0)
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_2 or key_event.keycode == KEY_KP_2:
		_press_index(1)
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_3 or key_event.keycode == KEY_KP_3:
		_press_index(2)
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_4 or key_event.keycode == KEY_KP_4:
		_press_index(3)
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		if keyboard_navigation_enabled:
			_play_click_sound()
			_press_focused_button()
			get_viewport().set_input_as_handled()
		return


func _move_keyboard_focus(
	direction_step: int
) -> void:

	if active_buttons.is_empty():
		return

	keyboard_navigation_enabled = true

	if keyboard_selected_index < 0 or keyboard_selected_index >= active_buttons.size():
		if direction_step > 0:
			keyboard_selected_index = 0
		else:
			keyboard_selected_index = active_buttons.size() - 1
		_apply_keyboard_selection()
		return

	var next_index: int = keyboard_selected_index + direction_step
	var attempts: int = active_buttons.size()

	while attempts > 0:
		if next_index < 0:
			next_index = active_buttons.size() - 1
		elif next_index >= active_buttons.size():
			next_index = 0

		var next_button: Button = active_buttons[next_index]
		if is_instance_valid(next_button) and not next_button.disabled:
			keyboard_selected_index = next_index
			_apply_keyboard_selection()
			return

		next_index += direction_step
		attempts -= 1


func _apply_keyboard_selection() -> void:

	for i in range(active_buttons.size()):
		var button: Button = active_buttons[i]
		if not is_instance_valid(button):
			continue
		_set_button_keyboard_selected(button, i == keyboard_selected_index and keyboard_navigation_enabled)


func _set_button_keyboard_selected(
	button: Button,
	selected: bool
) -> void:

	if not is_instance_valid(button):
		return

	button.focus_mode = Control.FOCUS_NONE
	button.release_focus()

	if selected:
		var selected_style: StyleBoxFlat = _button_style(Color("#3A2450"), PURPLE_LIGHT)
		button.add_theme_stylebox_override("normal", selected_style)
		button.add_theme_stylebox_override("hover", selected_style)
		button.add_theme_stylebox_override("pressed", selected_style)
	else:
		button.add_theme_stylebox_override("normal", _button_style(Color("#241832"), Color("#54336F")))
		button.add_theme_stylebox_override("hover", _button_style(Color("#37214E"), PURPLE_LIGHT))
		button.add_theme_stylebox_override("pressed", _button_style(Color("#5C3281"), PURPLE_LIGHT))


func _press_focused_button() -> void:

	if not keyboard_navigation_enabled:
		return

	if keyboard_selected_index < 0 or keyboard_selected_index >= active_buttons.size():
		return

	var button: Button = active_buttons[keyboard_selected_index]
	if not is_instance_valid(button) or button.disabled:
		return

	_animate_button_press(button)
	button.emit_signal("pressed")


# ============================================================
# API
# ============================================================

func is_ready_to_start() -> bool:

	return state == "ready"


func set_external_start_prompt(
	enabled: bool
) -> void:

	external_start_prompt = enabled

	if (
		external_start_prompt
		and
		start_prompt != null
	):

		start_prompt.hide()


func prepare_challenge(
	challenge_type: String,
	round_number: int
) -> void:

	current_type = challenge_type

	current_round = round_number

	state = "ready"

	input_locked = false

	_create_start_prompt()

	_set_start_text(
		"[ ENTER ]  INICIAR DESAFIO %d"
		% (
			current_round + 1
		)
	)

	if external_start_prompt:

		start_prompt.hide()

	else:

		start_prompt.show()


func hide_ready_prompt() -> void:

	if start_prompt != null:

		start_prompt.hide()


# ============================================================
# INICIAR
# ============================================================

func start_current_challenge() -> void:

	if state != "ready":
		return

	state = "active"

	input_locked = true

	challenge_time_left = (
		challenge_limit
	)

	if start_prompt != null:

		start_prompt.hide()

	dim.show()

	card.show()

	_clear_body()

	title_label.text = (
		"DESAFIO %d"
		% (
			current_round + 1
		)
	)


	match current_type:

		"sequence_double":

			_build_sequence_double()


		"quick_math":

			_build_quick_math()


		"attention_red":

			_build_attention_red()


		"attention_blue":

			_build_attention_blue()


		"memory_numbers":

			_build_memory_numbers()


		"memory_words":

			_build_memory_words()


		"order_numbers":

			_build_order_numbers()


		_:

			_build_sequence_double()


	_update_timer_text()


# ============================================================
# FECHAR
# ============================================================

func close_challenge() -> void:

	state = "idle"

	input_locked = true

	hide_all()


# ============================================================
# UI
# ============================================================

func _build_ui() -> void:

	canvas = CanvasLayer.new()

	canvas.layer = 130

	add_child(
		canvas
	)


	# ========================================================
	# ROOT
	# ========================================================

	root = Control.new()

	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	canvas.add_child(
		root
	)


	# ========================================================
	# FUNDO
	# ========================================================

	dim = ColorRect.new()

	dim.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	dim.color = Color(
		0.02,
		0.01,
		0.04,
		0.78
	)

	dim.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	root.add_child(
		dim
	)


	# ========================================================
	# CARD
	# ========================================================

	card = Panel.new()

	card.position = Vector2(
		180,
		115
	)

	card.size = Vector2(
		920,
		490
	)

	card.add_theme_stylebox_override(
		"panel",
		_panel_style(
			PANEL,
			Color("#55307C"),
			3,
			12
		)
	)

	root.add_child(
		card
	)


	# ========================================================
	# TITULO
	# ========================================================

	title_label = _label(
		"DESAFIO",
		30,
		PURPLE_LIGHT
	)

	title_label.position = Vector2(
		35,
		26
	)

	title_label.size = Vector2(
		620,
		50
	)

	card.add_child(
		title_label
	)


	# ========================================================
	# TIMER
	# ========================================================

	timer_label = _label(
		"18",
		22,
		PURPLE_LIGHT
	)

	timer_label.position = Vector2(
		790,
		30
	)

	timer_label.size = Vector2(
		90,
		40
	)

	timer_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	card.add_child(
		timer_label
	)


	# ========================================================
	# INSTRUÇÃO
	# ========================================================

	instruction_label = _label(
		"",
		17,
		WHITE
	)

	instruction_label.position = Vector2(
		35,
		82
	)

	instruction_label.size = Vector2(
		850,
		54
	)

	instruction_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	card.add_child(
		instruction_label
	)


	# ========================================================
	# BODY
	# ========================================================

	challenge_body = VBoxContainer.new()

	challenge_body.position = Vector2(
		35,
		150
	)

	challenge_body.size = Vector2(
		850,
		290
	)

	challenge_body.add_theme_constant_override(
		"separation",
		14
	)

	card.add_child(
		challenge_body
	)


	# ========================================================
	# FEEDBACK
	# ========================================================

	feedback_label = _label(
		"",
		20,
		WHITE
	)

	feedback_label.position = Vector2(
		35,
		435
	)

	feedback_label.size = Vector2(
		850,
		35
	)

	feedback_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	card.add_child(
		feedback_label
	)


# ============================================================
# COMANDOS PEQUENOS NOS BOTOES
# ============================================================

func _apply_keyboard_hints_and_focus() -> void:

	keyboard_navigation_enabled = false
	keyboard_selected_index = -1

	for i in range(active_buttons.size()):
		var button: Button = active_buttons[i]
		if not is_instance_valid(button):
			continue
		button.focus_mode = Control.FOCUS_NONE
		button.release_focus()
		_add_key_hint(button, i + 1)

	_apply_keyboard_selection()


func _add_key_hint(
	button: Button,
	key_number: int
) -> void:

	var key_hint: Label = Label.new()
	key_hint.text = "[%d]" % key_number
	key_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_hint.position = Vector2(5, 3)
	key_hint.size = Vector2(20, 12)
	key_hint.add_theme_font_size_override("font_size", 7)
	key_hint.add_theme_color_override("font_color", Color(MUTED.r, MUTED.g, MUTED.b, 0.35))
	key_hint.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.30))
	key_hint.add_theme_constant_override("outline_size", 1)
	_apply_font(key_hint)
	button.add_child(key_hint)


func _clear_keyboard_selection() -> void:

	keyboard_navigation_enabled = false
	keyboard_selected_index = -1
	_apply_keyboard_selection()


func _on_answer_button_gui_input(
	event: InputEvent,
	button: Button
) -> void:

	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		_play_click_sound()
		_clear_keyboard_selection()
		_animate_button_press(button)


func _animate_button_press(
	button: Button
) -> void:

	if not is_instance_valid(button):
		return

	button.pivot_offset = button.size * 0.5

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.055, 1.055), 0.06)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.08)


# ============================================================
# PROMPT ENTER
# ============================================================

func _create_start_prompt() -> void:

	if start_prompt != null:
		return

	start_prompt = Panel.new()

	# Mantem o mesmo painel visual, mas agora ele tambem
	# funciona como um botao por clique do mouse.
	start_prompt.mouse_filter = Control.MOUSE_FILTER_STOP
	start_prompt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if not start_prompt.gui_input.is_connected(
		_on_start_prompt_gui_input
	):

		start_prompt.gui_input.connect(
			_on_start_prompt_gui_input
		)

	start_prompt.position = Vector2(
		430,
		630
	)

	start_prompt.size = Vector2(
		420,
		58
	)

	start_prompt.add_theme_stylebox_override(
		"panel",
		_panel_style(
			PANEL_2,
			PURPLE_LIGHT,
			2,
			9
		)
	)

	canvas.add_child(
		start_prompt
	)

	start_prompt_label = _label(
		"[ ENTER ]  INICIAR DESAFIO",
		14,
		WHITE
	)

	start_prompt_label.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	start_prompt_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	start_prompt_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	start_prompt.add_child(
		start_prompt_label
	)


func _on_start_prompt_gui_input(
	event: InputEvent
) -> void:

	if state != "ready":
		return

	if input_locked:
		return

	if event is not InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if (
		mouse_event.button_index
		== MOUSE_BUTTON_LEFT
		and
		mouse_event.pressed
	):

		_play_click_sound()

		start_current_challenge()

		get_viewport().set_input_as_handled()


func _set_start_text(
	text_value: String
) -> void:

	_create_start_prompt()

	start_prompt_label.text = (
		text_value
	)


# ============================================================
# LIMPAR
# ============================================================

func hide_all() -> void:

	if dim != null:

		dim.hide()

	if card != null:

		card.hide()

	if start_prompt != null:

		start_prompt.hide()


func _clear_body() -> void:

	for child: Node in (
		challenge_body.get_children()
	):

		child.queue_free()

	active_buttons.clear()

	keyboard_navigation_enabled = false
	keyboard_selected_index = -1

	memory_buttons.clear()

	if feedback_label != null:

		feedback_label.text = ""

		feedback_label.add_theme_color_override(
			"font_color",
			WHITE
		)


# ============================================================
# LABEL
# ============================================================

func _label(
	text_value: String,
	size: int,
	color: Color
) -> Label:

	var label: Label = Label.new()

	label.text = text_value

	label.add_theme_font_size_override(
		"font_size",
		size
	)

	label.add_theme_color_override(
		"font_color",
		color
	)

	label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	label.add_theme_constant_override(
		"outline_size",
		3
	)

	label.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	_apply_font(
		label
	)

	return label


func _apply_font(
	control: Control
) -> void:

	var font_resource: Resource = (
		load(
			FONT_PATH
		)
	)

	if font_resource != null:

		control.add_theme_font_override(
			"font",
			font_resource
		)


# ============================================================
# BOTÃO
# ============================================================

func _make_button(
	text_value: String,
	font_size: int = 24
) -> Button:

	var button: Button = Button.new()

	button.text = text_value

	button.focus_mode = (
		Control.FOCUS_NONE
	)

	if not button.gui_input.is_connected(_on_answer_button_gui_input):
		button.gui_input.connect(_on_answer_button_gui_input.bind(button))

	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	button.add_theme_font_size_override(
		"font_size",
		font_size
	)

	_apply_font(
		button
	)

	button.add_theme_color_override(
		"font_color",
		WHITE
	)

	button.add_theme_color_override(
		"font_hover_color",
		WHITE
	)

	button.add_theme_color_override(
		"font_pressed_color",
		WHITE
	)

	button.add_theme_color_override(
		"font_focus_color",
		WHITE
	)

	button.add_theme_stylebox_override(
		"normal",
		_button_style(
			Color("#241832"),
			Color("#54336F")
		)
	)

	button.add_theme_stylebox_override(
		"hover",
		_button_style(
			Color("#37214E"),
			PURPLE_LIGHT
		)
	)

	button.add_theme_stylebox_override(
		"pressed",
		_button_style(
			Color("#5C3281"),
			PURPLE_LIGHT
		)
	)

	button.add_theme_stylebox_override(
		"focus",
		_button_style(
			Color("#3A2450"),
			PURPLE_LIGHT
		)
	)

	button.custom_minimum_size = Vector2(
		190,
		72
	)

	return button


# ============================================================
# ESTILOS
# ============================================================

func _panel_style(
	background: Color,
	border: Color,
	border_width: int,
	radius: int
) -> StyleBoxFlat:

	var style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	style.bg_color = background

	style.border_color = border

	style.set_border_width_all(
		border_width
	)

	style.set_corner_radius_all(
		radius
	)

	return style


func _button_style(
	background: Color,
	border: Color
) -> StyleBoxFlat:

	var style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	style.bg_color = background

	style.border_color = border

	style.set_border_width_all(
		2
	)

	style.set_corner_radius_all(
		8
	)

	return style


func _update_timer_text() -> void:

	if timer_label != null:

		timer_label.text = (
			"%02d"
			% int(
				ceil(
					challenge_time_left
				)
			)
		)


# ============================================================
# ERRO
# ============================================================

func _wrong_answer() -> void:

	if state != "active":
		return

	input_locked = true

	challenge_time_left -= (
		WRONG_PENALTY
	)

	challenge_time_left = max(
		challenge_time_left,
		0.0
	)

	feedback_label.text = (
		"ERRO! -5 SEGUNDOS"
	)

	feedback_label.add_theme_color_override(
		"font_color",
		RED
	)

	_update_timer_text()

	await get_tree().create_timer(
		0.35
	).timeout

	if state != "active":
		return

	feedback_label.text = ""

	if challenge_time_left <= 0.0:

		_timeout_finish()

		return

	# Continua no mesmo desafio.
	input_locked = false


# ============================================================
# RESPOSTA
# ============================================================

func _submit_answer(
	correct: bool
) -> void:

	if state != "active":
		return

	if not correct:

		_wrong_answer()

		return

	input_locked = true

	feedback_label.text = (
		"CORRETO!"
	)

	feedback_label.add_theme_color_override(
		"font_color",
		GREEN
	)

	await get_tree().create_timer(
		0.8
	).timeout

	if state != "active":
		return

	state = "idle"

	input_locked = true

	hide_all()

	challenge_finished.emit(
		true,
		current_type
	)


# ============================================================
# TEMPO ESGOTADO
# ============================================================

func _timeout_finish() -> void:

	if state != "active":
		return

	input_locked = true

	feedback_label.text = (
		"SEU TEMPO ACABOU"
	)

	feedback_label.add_theme_color_override(
		"font_color",
		RED
	)

	await get_tree().create_timer(
		0.8
	).timeout

	if state != "active":
		return

	state = "idle"

	hide_all()

	challenge_finished.emit(
		false,
		current_type
	)


# ============================================================
# DESAFIO - SEQUENCIA
# ============================================================

func _build_sequence_double() -> void:

	instruction_label.text = (
		"Qual numero completa a sequencia?"
	)

	var patterns: Array[Dictionary] = [

		{
			"values": [2, 4, 8, 16],
			"answer": 32
		},

		{
			"values": [3, 6, 12, 24],
			"answer": 48
		},

		{
			"values": [1, 2, 4, 8],
			"answer": 16
		}
	]

	patterns.shuffle()

	var item: Dictionary = (
		patterns[0]
	)

	logic_answer = int(
		item["answer"]
	)

	var sequence_label: Label = _label(
		"%d    %d    %d    %d    ?" % [
			int(item["values"][0]),
			int(item["values"][1]),
			int(item["values"][2]),
			int(item["values"][3])
		],
		38,
		PURPLE_LIGHT
	)

	sequence_label.custom_minimum_size = Vector2(
		850,
		110
	)

	sequence_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	sequence_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	challenge_body.add_child(
		sequence_label
	)

	_create_integer_answer_row(
		logic_answer
	)

	input_locked = false


# ============================================================
# DESAFIO - CONTA
# ============================================================

func _build_quick_math() -> void:

	instruction_label.text = (
		"Resolva rapidamente."
	)

	var equations: Array[Dictionary] = [

		{
			"text": "7 + 5 - 3 = ?",
			"answer": 9
		},

		{
			"text": "8 + 6 - 4 = ?",
			"answer": 10
		},

		{
			"text": "9 - 3 + 7 = ?",
			"answer": 13
		}
	]

	equations.shuffle()

	var item: Dictionary = (
		equations[0]
	)

	logic_answer = int(
		item["answer"]
	)

	var equation: Label = _label(
		str(
			item["text"]
		),
		42,
		PURPLE_LIGHT
	)

	equation.custom_minimum_size = Vector2(
		850,
		110
	)

	equation.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	equation.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	challenge_body.add_child(
		equation
	)

	_create_integer_answer_row(
		logic_answer
	)

	input_locked = false


# ============================================================
# ALTERNATIVAS DE NÚMEROS
# ============================================================

func _create_integer_answer_row(
	answer: int
) -> void:

	var row: HBoxContainer = (
		HBoxContainer.new()
	)

	row.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	row.add_theme_constant_override(
		"separation",
		12
	)

	challenge_body.add_child(
		row
	)

	# --------------------------------------------------------
	# Cria alternativas próximas da resposta.
	# --------------------------------------------------------

	var options: Array[int] = [
		answer
	]

	var offsets: Array[int] = [
		-2,
		2,
		-4,
		4,
		-3,
		3,
		-5,
		5
	]

	offsets.shuffle()

	for offset: int in offsets:

		var value: int = (
			answer + offset
		)

		if (
			value > 0
			and
			not options.has(value)
		):

			options.append(
				value
			)

		if options.size() >= 4:
			break

	options.shuffle()

	active_buttons.clear()

	for value: int in options:

		var button: Button = (
			_make_button(
				str(value),
				26
			)
		)

		button.pressed.connect(
			_on_logic_answer.bind(
				value
			)
		)

		row.add_child(
			button
		)

		active_buttons.append(
			button
		)


	_apply_keyboard_hints_and_focus()


func _on_logic_answer(
	value: int
) -> void:

	if input_locked:
		return

	input_locked = true

	_submit_answer(
		value == logic_answer
	)


# ============================================================
# STROOP VERMELHO
# ============================================================

func _build_attention_red() -> void:

	_build_attention_stroop()


# ============================================================
# STROOP AZUL
# ============================================================

func _build_attention_blue() -> void:

	_build_attention_stroop()


# ============================================================
# STROOP DINAMICO
# ============================================================

func _build_attention_stroop() -> void:

	# A cor escrita sempre pertence a ATTENTION_COLORS.
	# A cor da tinta tambem pertence a mesma lista.
	# Assim, tanto a palavra quanto a resposta sempre
	# existem nas alternativas do desafio.
	var colors: Array[String] = ATTENTION_COLORS.duplicate()
	colors.shuffle()

	attention_answer = colors[0]

	# Evita repetir a mesma resposta da rodada anterior.
	if (
		last_attention_answer != ""
		and
		attention_answer == last_attention_answer
		and
		colors.size() > 1
	):
		attention_answer = colors[1]

	last_attention_answer = attention_answer

	# A palavra sera diferente da cor da tinta,
	# mantendo o efeito Stroop.
	var words: Array[String] = ATTENTION_COLORS.duplicate()
	words.erase(attention_answer)
	words.shuffle()

	var word: String = words[0]

	# Guarda a palavra para coloca-la obrigatoriamente
	# entre as alternativas.
	attention_word = word

	var instructions: Array[String] = [
		"ATENCAO: clique na COR da tinta, nao na palavra!",
		"NAO LEIA! observe apenas a cor do texto.",
		"QUAL E A COR? ignore o significado da palavra!"
	]

	instructions.shuffle()
	instruction_label.text = instructions[0]

	var word_label: Label = _label(
		word,
		58,
		ATTENTION_COLOR_VALUES[attention_answer]
	)

	word_label.custom_minimum_size = Vector2(
		850,
		135
	)

	word_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	word_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	word_label.add_theme_constant_override(
		"outline_size",
		5
	)

	challenge_body.add_child(
		word_label
	)

	_create_attention_buttons()

	input_locked = false


func _create_attention_buttons() -> void:

	var answer_pool: Array[String] = (
		ATTENTION_COLORS.duplicate()
	)

	# A cor da tinta e a palavra escrita sao obrigatorias.
	# Portanto, a palavra nunca ficara fora das alternativas.
	var names: Array[String] = [
		attention_answer,
		attention_word
	]

	# A palavra ja e diferente da tinta, mas esta protecao
	# evita qualquer duplicacao caso a regra seja alterada futuramente.
	if attention_answer == attention_word:
		names = [attention_answer]

	answer_pool.shuffle()

	# Completa ate quatro alternativas sem repetir nenhuma.
	for color_name: String in answer_pool:

		if names.has(color_name):
			continue

		names.append(color_name)

		if names.size() >= 4:
			break

	names.shuffle()

	var row: HBoxContainer = (
		HBoxContainer.new()
	)

	row.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	row.add_theme_constant_override(
		"separation",
		12
	)

	challenge_body.add_child(
		row
	)

	active_buttons.clear()

	for name: String in names:

		var button: Button = (
			_make_button(
				name,
				16
			)
		)

		# Cada botao continua mostrando sua propria cor.
		button.add_theme_color_override(
			"font_color",
			ATTENTION_COLOR_VALUES[name]
		)

		button.add_theme_color_override(
			"font_hover_color",
			Color.WHITE
		)

		button.add_theme_color_override(
			"font_pressed_color",
			Color.WHITE
		)

		button.pressed.connect(
			_on_attention_answer.bind(
				name
			)
		)

		row.add_child(
			button
		)

		active_buttons.append(
			button
		)


	_apply_keyboard_hints_and_focus()


func _on_attention_answer(
	value: String
) -> void:

	if input_locked:
		return

	input_locked = true

	_submit_answer(
		value == attention_answer
	)


# ============================================================
# MEMÓRIA DE NÚMEROS
# ============================================================

func _build_memory_numbers() -> void:

	instruction_label.text = (
		"Memorize a sequencia."
	)

	memory_sequence.clear()

	memory_position = 0

	var sequences: Array[Array] = [

		["3", "8", "1", "6"],

		["7", "2", "9", "4"],

		["5", "1", "8", "3"],

		["4", "9", "2", "7"]
	]

	var sequence: Array = (
		sequences[
			randi()
			%
			sequences.size()
		]
	)

	for value: Variant in sequence:

		memory_sequence.append(
			str(value)
		)

	var sequence_label: Label = _label(
		"   ".join(
			memory_sequence
		),
		44,
		GOLD
	)

	sequence_label.custom_minimum_size = Vector2(
		850,
		110
	)

	sequence_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	sequence_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	challenge_body.add_child(
		sequence_label
	)

	input_locked = true

	await get_tree().create_timer(
		2.2
	).timeout

	if state != "active":
		return

	sequence_label.text = (
		"?   ?   ?   ?"
	)

	_build_memory_number_buttons()

	input_locked = false


func _build_memory_number_buttons() -> void:

	var row: HBoxContainer = (
		HBoxContainer.new()
	)

	row.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	row.add_theme_constant_override(
		"separation",
		12
	)

	challenge_body.add_child(
		row
	)

	var options: Array[String] = (
		memory_sequence.duplicate()
	)

	var extras: Array[String] = [
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9"
	]

	extras.shuffle()

	for value: String in extras:

		if (
			not options.has(value)
			and
			options.size() < 4
		):

			options.append(value)

	options.shuffle()

	memory_buttons.clear()

	for number: String in options:

		var button: Button = (
			_make_button(
				number,
				28
			)
		)

		button.pressed.connect(
			_on_memory_number.bind(
				number,
				button
			)
		)

		row.add_child(
			button
		)

		memory_buttons.append(
			button
		)


	active_buttons.clear()
	for memory_button: Button in memory_buttons:
		active_buttons.append(memory_button)
	_apply_keyboard_hints_and_focus()


func _on_memory_number(
	number: String,
	button: Button
) -> void:

	if input_locked:
		return

	if (
		memory_position
		>=
		memory_sequence.size()
	):

		return

	# --------------------------------------------------------
	# ERRO
	# --------------------------------------------------------

	if (
		number
		!=
		memory_sequence[
			memory_position
		]
	):

		button.modulate = RED

		memory_position = 0

		_reset_memory_buttons()

		_wrong_answer()

		return

	# --------------------------------------------------------
	# ACERTO
	# --------------------------------------------------------

	button.modulate = GREEN

	button.disabled = true

	memory_position += 1

	if (
		memory_position
		>=
		memory_sequence.size()
	):

		input_locked = true

		_submit_answer(
			true
		)


func _reset_memory_buttons() -> void:

	for button: Button in memory_buttons:

		if not is_instance_valid(
			button
		):

			continue

		button.disabled = false

		button.modulate = Color.WHITE


# ============================================================
# MEMÓRIA DE PALAVRAS
# ============================================================

func _build_memory_words() -> void:

	instruction_label.text = (
		"Memorize a ordem das palavras."
	)

	memory_sequence.clear()

	memory_position = 0

	var sequences: Array[Array] = [

		[
			"SOL",
			"LUA",
			"MAR",
			"CEU"
		],

		[
			"CASA",
			"ARVORE",
			"RIO",
			"FLOR"
		],

		[
			"GATO",
			"PEIXE",
			"PASSARO",
			"LEAO"
		],

		[
			"VERAO",
			"OUTONO",
			"INVERNO",
			"PRIMAVERA"
		]
	]

	var sequence: Array = (
		sequences[
			randi()
			%
			sequences.size()
		]
	)

	for value: Variant in sequence:

		memory_sequence.append(
			str(value)
		)

	var sequence_label: Label = _label(
		"  ".join(
			memory_sequence
		),
		30,
		PURPLE_LIGHT
	)

	sequence_label.custom_minimum_size = Vector2(
		850,
		110
	)

	sequence_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	sequence_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	challenge_body.add_child(
		sequence_label
	)

	input_locked = true

	await get_tree().create_timer(
		2.4
	).timeout

	if state != "active":
		return

	sequence_label.text = (
		"?    ?    ?    ?"
	)

	_build_memory_word_buttons()

	input_locked = false


func _build_memory_word_buttons() -> void:

	var row: HBoxContainer = (
		HBoxContainer.new()
	)

	row.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	row.add_theme_constant_override(
		"separation",
		10
	)

	challenge_body.add_child(
		row
	)

	var options: Array[String] = (
		memory_sequence.duplicate()
	)

	options.shuffle()

	memory_buttons.clear()

	for word: String in options:

		var button: Button = (
			_make_button(
				word,
				16
			)
		)

		button.pressed.connect(
			_on_memory_word.bind(
				word,
				button
			)
		)

		row.add_child(
			button
		)

		memory_buttons.append(
			button
		)


	active_buttons.clear()
	for memory_button: Button in memory_buttons:
		active_buttons.append(memory_button)
	_apply_keyboard_hints_and_focus()


func _on_memory_word(
	word: String,
	button: Button
) -> void:

	if input_locked:
		return

	if (
		memory_position
		>=
		memory_sequence.size()
	):

		return

	# --------------------------------------------------------
	# ERRO
	# --------------------------------------------------------

	if (
		word
		!=
		memory_sequence[
			memory_position
		]
	):

		button.modulate = RED

		memory_position = 0

		_reset_memory_buttons()

		_wrong_answer()

		return

	# --------------------------------------------------------
	# ACERTO
	# --------------------------------------------------------

	button.modulate = GREEN

	button.disabled = true

	memory_position += 1

	if (
		memory_position
		>=
		memory_sequence.size()
	):

		input_locked = true

		_submit_answer(
			true
		)


# ============================================================
# ORDEM CRESCENTE
# ============================================================

func _build_order_numbers() -> void:

	instruction_label.text = (
		"Qual sequencia esta em ordem crescente?"
	)

	var options: Array[String] = [
		"2 - 5 - 8 - 11",
		"7 - 4 - 9 - 12",
		"3 - 6 - 5 - 10",
		"9 - 8 - 12 - 14"
	]

	var indices: Array[int] = [
		0,
		1,
		2,
		3
	]

	indices.shuffle()

	var row: VBoxContainer = (
		VBoxContainer.new()
	)

	row.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	row.add_theme_constant_override(
		"separation",
		10
	)

	challenge_body.add_child(
		row
	)

	active_buttons.clear()

	for index: int in indices:

		var button: Button = (
			_make_button(
				options[index],
				21
			)
		)

		button.custom_minimum_size = Vector2(
			600,
			52
		)

		button.pressed.connect(
			_on_order_answer.bind(
				index
			)
		)

		row.add_child(
			button
		)

		active_buttons.append(
			button
		)

	input_locked = false


	_apply_keyboard_hints_and_focus()


func _on_order_answer(
	selected_index: int
) -> void:

	if input_locked:
		return

	input_locked = true

	var correct: bool = (
		selected_index == 0
	)

	_submit_answer(
		correct
	)


# ============================================================
# TECLAS 1-4
# ============================================================

func _press_index(
	index: int
) -> void:

	if (
		index < 0
		or
		index >= active_buttons.size()
	):
		return

	var button: Button = active_buttons[index]

	if not is_instance_valid(button):
		return

	if button.disabled:
		return

	# Atalho numerico: animacao apenas no botao apertado.
	# Nao deixa selecao permanente.
	_play_click_sound()
	_animate_button_press(button)

	button.emit_signal("pressed")
