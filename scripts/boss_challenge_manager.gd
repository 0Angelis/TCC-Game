extends Node

## Gerencia os desafios da batalha final.
## Nao usa as cenas dos desafios originais para nao alterar o comportamento deles.
## Os desafios abaixo foram feitos especificamente para a luta do boss.

signal challenge_finished(correct: bool, challenge_type: String)

const FONT_PATH: String = "res://assets/Fontes/Pixeloid_Font_1_0/OpenType (.otf)/PixeloidSans-Bold.otf"

const PURPLE: Color = Color("#8E4EDB")
const PURPLE_LIGHT: Color = Color("#C39BFF")
const PANEL: Color = Color("#120D1B")
const PANEL_2: Color = Color("#1B1327")
const WHITE: Color = Color("#F8F5FF")
const MUTED: Color = Color("#BDB5C9")
const GREEN: Color = Color("#78E08F")
const RED: Color = Color("#FF6B7A")
const GOLD: Color = Color("#FFD166")

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

var current_type: String = ""
var current_round: int = 0
var state: String = "idle"
var challenge_time_left: float = 0.0
var challenge_limit: float = 18.0
var input_locked: bool = false
var external_start_prompt: bool = false

var active_buttons: Array[Button] = []

var logic_answer: int = 0

var attention_answer: String = ""

var memory_sequence: Array[String] = []
var memory_position: int = 0
var memory_buttons: Array[Button] = []

var mixed_stage: int = 0
var mixed_memory_sequence: Array[String] = []
var mixed_attention_answer: String = ""
var mixed_logic_answer: int = 0

func _ready() -> void:
	_build_ui()
	hide_all()

func _process(delta: float) -> void:
	if state != "active":
		return

	if input_locked:
		return

	challenge_time_left -= delta
	if timer_label != null:
		timer_label.text = "%02d" % max(0, int(ceil(challenge_time_left)))

	if challenge_time_left <= 0.0:
		_finish(false)

func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# E inicia o desafio quando ele esta pronto.
	if state == "ready" and key_event.keycode == KEY_E:
		start_current_challenge()
		get_viewport().set_input_as_handled()
		return

	if state != "active":
		return

	if key_event.keycode == KEY_1:
		_press_index(0)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_2:
		_press_index(1)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_3:
		_press_index(2)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_4:
		_press_index(3)
		get_viewport().set_input_as_handled()

func is_ready_to_start() -> bool:
	return state == "ready"

func set_external_start_prompt(enabled: bool) -> void:
	external_start_prompt = enabled
	if external_start_prompt and start_prompt != null:
		start_prompt.hide()

func prepare_challenge(challenge_type: String, round_number: int) -> void:
	current_type = challenge_type
	current_round = round_number
	state = "ready"
	input_locked = false

	_create_start_prompt()
	if external_start_prompt:
		start_prompt.hide()
	else:
		start_prompt.show()
		start_prompt.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(start_prompt, "modulate:a", 1.0, 0.25)

func hide_ready_prompt() -> void:
	if start_prompt != null:
		start_prompt.hide()


func start_current_challenge() -> void:
	if state != "ready":
		return

	state = "active"
	input_locked = true
	challenge_time_left = challenge_limit

	if start_prompt != null:
		start_prompt.hide()

	dim.show()
	card.show()
	_clear_body()

	match current_type:
		"logic":
			_build_logic_challenge()
		"attention":
			_build_attention_challenge()
		"memory":
			_build_memory_challenge()
		"mixed":
			_build_mixed_challenge()
		_:
			_build_logic_challenge()

	_update_timer_text()

func close_challenge() -> void:
	state = "idle"
	input_locked = true
	hide_all()

# ============================================================
# UI BASE
# ============================================================

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 130
	add_child(canvas)

	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.04, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	card = Panel.new()
	card.position = Vector2(180, 115)
	card.size = Vector2(920, 490)
	card.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("#55307C"), 3, 12))
	root.add_child(card)

	title_label = _label("DESAFIO", 30, PURPLE_LIGHT)
	title_label.position = Vector2(35, 26)
	title_label.size = Vector2(620, 50)
	card.add_child(title_label)

	timer_label = _label("18", 22, PURPLE_LIGHT)
	timer_label.position = Vector2(790, 30)
	timer_label.size = Vector2(90, 40)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(timer_label)

	instruction_label = _label("", 17, WHITE)
	instruction_label.position = Vector2(35, 82)
	instruction_label.size = Vector2(850, 54)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(instruction_label)

	challenge_body = VBoxContainer.new()
	challenge_body.position = Vector2(35, 150)
	challenge_body.size = Vector2(850, 290)
	challenge_body.add_theme_constant_override("separation", 14)
	card.add_child(challenge_body)

	feedback_label = _label("", 20, WHITE)
	feedback_label.position = Vector2(35, 435)
	feedback_label.size = Vector2(850, 35)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(feedback_label)

func _create_start_prompt() -> void:
	if start_prompt != null:
		return

	start_prompt = Panel.new()
	start_prompt.position = Vector2(430, 635)
	start_prompt.size = Vector2(420, 64)
	start_prompt.add_theme_stylebox_override("panel", _panel_style(PANEL_2, Color("#8E4EDB"), 2, 9))
	canvas.add_child(start_prompt)

	start_prompt_label = _label("", 18, WHITE)
	start_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_prompt.add_child(start_prompt_label)

func _set_start_text(text_value: String) -> void:
	_create_start_prompt()
	start_prompt_label.text = text_value

func hide_all() -> void:
	if dim != null:
		dim.hide()
	if card != null:
		card.hide()
	if start_prompt != null:
		start_prompt.hide()

func _clear_body() -> void:
	for child: Node in challenge_body.get_children():
		child.queue_free()
	active_buttons.clear()
	memory_buttons.clear()

func _label(text_value: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_font(label)
	return label

func _apply_font(control: Control) -> void:
	var font_resource: Resource = load(FONT_PATH)
	if font_resource != null:
		control.add_theme_font_override("font", font_resource)

func _panel_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

func _make_button(text_value: String, font_size: int = 24) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	_apply_font(button)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_color_override("font_hover_color", WHITE)
	button.add_theme_color_override("font_pressed_color", WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color("#241832"), Color("#54336F")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#37214E"), PURPLE_LIGHT))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#5C3281"), PURPLE_LIGHT))
	button.custom_minimum_size = Vector2(190, 72)
	return button

func _update_timer_text() -> void:
	if timer_label != null:
		timer_label.text = "%02d" % int(ceil(challenge_time_left))

# ============================================================
# RACIOCINIO
# ============================================================

func _build_logic_challenge() -> void:
	title_label.text = "RACIOCINIO"
	instruction_label.text = "Qual numero completa a sequencia? Escolha a resposta correta."

	var patterns: Array[Dictionary] = [
		{"values": [2, 4, 8, 16], "answer": 32},
		{"values": [5, 8, 11, 14], "answer": 17},
		{"values": [21, 18, 15, 12], "answer": 9},
		{"values": [3, 6, 12, 24], "answer": 48},
		{"values": [4, 7, 10, 13], "answer": 16},
		{"values": [30, 25, 20, 15], "answer": 10}
	]

	var item: Dictionary = patterns[current_round % patterns.size()]
	logic_answer = int(item["answer"])

	var sequence_label: Label = _label(
		"%d    %d    %d    %d    ?" % [
			int(item["values"][0]),
			int(item["values"][1]),
			int(item["values"][2]),
			int(item["values"][3])
		],
		36,
		PURPLE_LIGHT
	)
	sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sequence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sequence_label.custom_minimum_size = Vector2(850, 100)
	challenge_body.add_child(sequence_label)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	challenge_body.add_child(row)

	var options: Array[int] = _make_integer_options(logic_answer, current_round)
	for i: int in range(options.size()):
		var button: Button = _make_button(str(options[i]), 26)
		button.pressed.connect(_on_logic_answer.bind(options[i]))
		row.add_child(button)
		active_buttons.append(button)

	input_locked = false

func _make_integer_options(answer: int, seed_value: int) -> Array[int]:
	var values: Array[int] = [answer]
	var candidates: Array[int] = [answer - 6, answer + 3, answer + 7, answer - 2, answer + 5, answer + 9]
	var offset: int = seed_value % candidates.size()

	for i: int in range(candidates.size()):
		var value: int = candidates[(i + offset) % candidates.size()]
		if value > 0 and value != answer and not values.has(value):
			values.append(value)
		if values.size() == 4:
			break

	while values.size() < 4:
		values.append(answer + values.size() + 2)

	values.shuffle()
	return values

func _on_logic_answer(value: int) -> void:
	if input_locked:
		return
	input_locked = true
	_finish(value == logic_answer)

# ============================================================
# ATENCAO / STROOP
# ============================================================

func _build_attention_challenge() -> void:
	title_label.text = "ATENCAO"
	instruction_label.text = "Ignore o significado da palavra. Clique na COR do texto."

	var names: Array[String] = ["VERMELHO", "AZUL", "VERDE", "AMARELO"]
	var colors: Array[Color] = [Color("#F04B58"), Color("#55A8FF"), Color("#62D88C"), Color("#F5D66D")]

	var color_index: int = current_round % 4
	var word_index: int = (color_index + 1 + (current_round % 3)) % 4
	attention_answer = names[color_index]

	var word: Label = _label(names[word_index], 50, colors[color_index])
	word.custom_minimum_size = Vector2(850, 110)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	challenge_body.add_child(word)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	challenge_body.add_child(row)

	for i: int in range(names.size()):
		var button: Button = _make_button(names[i], 18)
		button.pressed.connect(_on_attention_answer.bind(names[i]))
		row.add_child(button)
		active_buttons.append(button)

	input_locked = false

func _on_attention_answer(value: String) -> void:
	if input_locked:
		return
	input_locked = true
	_finish(value == attention_answer)

# ============================================================
# MEMORIA
# ============================================================

func _build_memory_challenge() -> void:
	title_label.text = "MEMORIA"
	instruction_label.text = "Observe a sequencia. Depois repita exatamente na mesma ordem."

	var symbols: Array[String] = ["▲", "●", "◆", "★", "✦", "✚"]
	memory_sequence.clear()
	memory_position = 0

	var length: int = 4 if current_round < 6 else 5
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5000 + current_round * 97

	for i: int in range(length):
		memory_sequence.append(symbols[rng.randi_range(0, symbols.size() - 1)])

	var sequence_label: Label = _label(
		"  ".join(memory_sequence),
		48,
		PURPLE_LIGHT
	)
	sequence_label.name = "MemorySequence"
	sequence_label.custom_minimum_size = Vector2(850, 105)
	sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sequence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	challenge_body.add_child(sequence_label)

	await get_tree().create_timer(3.0).timeout
	if state != "active":
		return

	sequence_label.text = "?   ?   ?   ?" if length == 4 else "?   ?   ?   ?   ?"
	_build_memory_buttons(symbols)
	input_locked = false

func _build_memory_buttons(symbols: Array[String]) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	challenge_body.add_child(row)

	var pool: Array[String] = symbols.duplicate()
	pool.shuffle()

	for i: int in range(4):
		var symbol: String = pool[i]
		var button: Button = _make_button(symbol, 34)
		button.pressed.connect(_on_memory_symbol.bind(symbol, button))
		row.add_child(button)
		memory_buttons.append(button)

func _on_memory_symbol(symbol: String, button: Button) -> void:
	if input_locked:
		return

	if memory_position >= memory_sequence.size():
		return

	if symbol != memory_sequence[memory_position]:
		input_locked = true
		button.modulate = Color("#FF6B7A")
		_finish(false)
		return

	button.modulate = Color("#78E08F")
	button.disabled = true
	memory_position += 1

	if memory_position >= memory_sequence.size():
		input_locked = true
		_finish(true)

# ============================================================
# DESAFIO FINAL MISTO
# ============================================================

func _build_mixed_challenge() -> void:
	title_label.text = "DESAFIO FINAL"
	instruction_label.text = "As tres habilidades serao exigidas. Complete todas as etapas."
	mixed_stage = 0
	_build_mixed_memory_stage()

func _build_mixed_memory_stage() -> void:
	_clear_body()
	mixed_stage = 0
	mixed_memory_sequence = ["2", "7", "4"]

	var text: Label = _label("MEMORIZE", 24, PURPLE_LIGHT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_body.add_child(text)

	var sequence: Label = _label("   ".join(mixed_memory_sequence), 46, GOLD)
	sequence.custom_minimum_size = Vector2(850, 120)
	sequence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sequence.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	challenge_body.add_child(sequence)

	await get_tree().create_timer(2.8).timeout
	if state != "active":
		return

	_clear_body()
	instruction_label.text = "MEMORIA: qual sequencia voce acabou de ver?"

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	challenge_body.add_child(row)

	var options: Array[String] = ["2   7   4", "7   2   4", "2   4   7", "4   7   2"]
	for i: int in range(options.size()):
		var button: Button = _make_button(options[i], 20)
		button.pressed.connect(_on_mixed_memory.bind(options[i]))
		row.add_child(button)
		active_buttons.append(button)

	input_locked = false

func _on_mixed_memory(value: String) -> void:
	if input_locked:
		return
	if value != "2   7   4":
		input_locked = true
		_finish(false)
		return

	input_locked = true
	_build_mixed_attention_stage()

func _build_mixed_attention_stage() -> void:
	_clear_body()
	mixed_stage = 1
	instruction_label.text = "ATENCAO: clique na COR do texto, nao na palavra."

	var word: Label = _label("VERDE", 50, Color("#FF4E62"))
	word.custom_minimum_size = Vector2(850, 120)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	challenge_body.add_child(word)
	mixed_attention_answer = "VERMELHO"

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	challenge_body.add_child(row)

	for color_name: String in ["VERMELHO", "AZUL", "VERDE", "AMARELO"]:
		var button: Button = _make_button(color_name, 17)
		button.pressed.connect(_on_mixed_attention.bind(color_name))
		row.add_child(button)
		active_buttons.append(button)

	input_locked = false

func _on_mixed_attention(value: String) -> void:
	if input_locked:
		return
	if value != mixed_attention_answer:
		input_locked = true
		_finish(false)
		return

	input_locked = true
	_build_mixed_logic_stage()

func _build_mixed_logic_stage() -> void:
	_clear_body()
	mixed_stage = 2
	mixed_logic_answer = 6
	instruction_label.text = "RACIOCINIO: use a memoria para resolver: primeiro numero + ultimo numero."

	var equation: Label = _label("2 + 4 = ?", 48, PURPLE_LIGHT)
	equation.custom_minimum_size = Vector2(850, 120)
	equation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	challenge_body.add_child(equation)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	challenge_body.add_child(row)

	for value: int in [4, 5, 6, 8]:
		var button: Button = _make_button(str(value), 28)
		button.pressed.connect(_on_mixed_logic.bind(value))
		row.add_child(button)
		active_buttons.append(button)

	input_locked = false

func _on_mixed_logic(value: int) -> void:
	if input_locked:
		return
	input_locked = true
	_finish(value == mixed_logic_answer)

# ============================================================
# AUXILIAR PARA TECLAS 1-4
# ============================================================

func _press_index(index: int) -> void:
	if index < 0 or index >= active_buttons.size():
		return
	if not is_instance_valid(active_buttons[index]):
		return
	active_buttons[index].emit_signal("pressed")

# ============================================================
# FINALIZACAO
# ============================================================

func _finish(correct: bool) -> void:
	if state != "active":
		return

	input_locked = true

	if correct:
		feedback_label.text = "CORRETO"
		feedback_label.add_theme_color_override("font_color", GREEN)
	else:
		feedback_label.text = "NAO FOI DESTA VEZ"
		feedback_label.add_theme_color_override("font_color", RED)

	await get_tree().create_timer(1.25).timeout
	if state != "active":
		return

	state = "idle"
	input_locked = true
	hide_all()
	challenge_finished.emit(correct, current_type)
