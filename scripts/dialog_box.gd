extends MarginContainer


@onready var text_label = $label_margin/text_label
@onready var counter_label = $counter_label
@onready var letter_timer_display = $letter_timer_display


# ==========================================
# CONFIGURAÇÕES
# ==========================================

const MAX_WIDTH = 384

const TEXT_FONT_SIZE = 8

const COUNTER_FONT_SIZE = 4


# ==========================================
# VARIÁVEIS
# ==========================================

var text = ""
var letter_index = 0

var letter_display_timer := 0.07
var space_display_timer := 0.05
var punctuation_display_timer := 0.2


signal text_display_finished


# ==========================================
# READY
# ==========================================

func _ready():

	# ==========================================
	# CONFIGURAÇÃO DO TEXTO
	# ==========================================

	text_label.add_theme_font_size_override(
		"font_size",
		TEXT_FONT_SIZE
	)

	text_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


	# ==========================================
	# CONFIGURAÇÃO DO CONTADOR
	# ==========================================

	counter_label.top_level = true

	counter_label.z_index = 100

	counter_label.add_theme_font_size_override(
		"font_size",
		COUNTER_FONT_SIZE
	)

	counter_label.add_theme_color_override(
		"font_color",
		Color("#7046A3")
	)

	counter_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


# ==========================================
# MOSTRAR TEXTO
# ==========================================

func display_text(
	text_to_display: String,
	current_number := 1,
	total_number := 1
):

	letter_index = 0

	text = text_to_display


	# ==========================================
	# CONTADOR
	# ==========================================

	counter_label.text = "%d / %d" % [
		current_number,
		total_number
	]

	counter_label.add_theme_font_size_override(
		"font_size",
		COUNTER_FONT_SIZE
	)

	counter_label.reset_size()


	# ==========================================
	# TEXTO
	# ==========================================

	text_label.text = text

	await resized


	# ==========================================
	# TAMANHO DA CAIXA
	# ==========================================

	custom_minimum_size.x = min(
		size.x,
		MAX_WIDTH
	)


	if size.x > MAX_WIDTH:

		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD

		await resized
		await resized

		custom_minimum_size.y = size.y


	# ==========================================
	# POSIÇÃO DA CAIXA
	# ==========================================

	global_position.x -= size.x / 2

	global_position.y -= size.y + 24


	# ==========================================
	# ESPERA O LAYOUT
	# ==========================================

	await get_tree().process_frame

	await get_tree().process_frame


	# ==========================================
	# RETÂNGULO DA CAIXA
	# ==========================================

	var box_rect = get_global_rect()


	# ==========================================
	# POSIÇÃO DO CONTADOR
	# ==========================================

	counter_label.global_position = Vector2(
		box_rect.end.x - counter_label.size.x - 2,
		box_rect.position.y + 1
		
	)


	# ==========================================
	# FINALIZA
	# ==========================================

	text_display_finished.emit()


# ==========================================
# MOSTRA LETRAS
# ==========================================

func display_letter():

	text_label.text += text[letter_index]

	letter_index += 1


	if letter_index >= text.length():

		text_display_finished.emit()

		return


	match text[letter_index]:

		"!", "?", ",", ".":

			letter_timer_display.start(
				punctuation_display_timer
			)

		" ":

			letter_timer_display.start(
				space_display_timer
			)

		_:

			letter_timer_display.start(
				letter_display_timer
			)


# ==========================================
# TIMER DAS LETRAS
# ==========================================

func _on_letter_timer_display_timeout():

	display_letter()
