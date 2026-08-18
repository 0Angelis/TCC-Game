extends MarginContainer

@onready var text_label = $label_margin/text_label
@onready var counter_label = $counter_label
@onready var letter_timer_display = $letter_timer_display

const MAX_WIDTH = 256

var text = ""
var letter_index = 0

var letter_display_timer := 0.07
var space_display_timer := 0.05
var punctuation_display_timer := 0.2

signal text_display_finished


func _ready():

	counter_label.top_level = true

	counter_label.add_theme_font_size_override(
		"font_size",
		8
	)

	counter_label.custom_minimum_size = Vector2(0, 0)
	counter_label.size = Vector2(40, 14)


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
		8
	)

	# ==========================================
	# TEXTO
	# ==========================================

	text_label.text = text

	await resized

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

	await get_tree().process_frame

	# ==========================================
	# POSIÇÃO DO CONTADOR
	# ==========================================

	counter_label.global_position = Vector2(
		global_position.x + size.x - 17,
		global_position.y - 1
	)

	# ==========================================
	# FINALIZA
	# ==========================================

	text_display_finished.emit()


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


func _on_letter_timer_display_timeout():

	display_letter()
