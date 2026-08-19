extends Node


var dialog_box_scene = preload("res://prefabs/dialog_box.tscn")

var message_lines: Array[String] = []
var current_line := 0

var dialog_box
var dialog_box_position := Vector2.ZERO

var is_message_active := false
var can_advance_message := false

# Guarda qual placa abriu o diálogo
var current_source = null


# ==========================================
# AVISO DE COMANDO
# ==========================================

var command_canvas: CanvasLayer
var command_label: Label

var command_font = preload(
	"res://assets/Fontes/Pixeloid_Font_1_0/OpenType (.otf)/PixeloidSans-Bold.otf"
)


# ==========================================
# READY
# ==========================================

func _ready():

	# ==========================================
	# CANVAS FIXO NA TELA
	# ==========================================

	command_canvas = CanvasLayer.new()
	command_canvas.layer = 100

	get_tree().root.add_child(command_canvas)


	# ==========================================
	# LABEL DO COMANDO
	# ==========================================

	command_label = Label.new()

	command_label.position = Vector2(20, 15)

	command_label.text = ""

	# Fonte
	command_label.add_theme_font_override(
		"font",
		command_font
	)

	# Tamanho
	command_label.add_theme_font_size_override(
		"font_size",
		8
	)

	# Mesma cor roxa do contador 1 / 3
	command_label.add_theme_color_override(
		"font_color",
		Color("#7046A3")
	)

	# Pixel art
	command_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Não interfere no jogo
	command_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	command_canvas.add_child(command_label)


	# ==========================================
	# COMEÇA ESCONDIDO
	# ==========================================

	command_label.hide()


# ==========================================
# ATUALIZA TEXTO DO COMANDO
# ==========================================

func update_command():

	if command_label == null:
		return


	# ==========================================
	# SEM DIÁLOGO
	# ==========================================

	if not is_message_active:

		command_label.hide()

		return


	# ==========================================
	# ÚLTIMA PÁGINA
	# ==========================================

	if current_line >= message_lines.size() - 1:

		command_label.text = "E - fechar"

	else:

		command_label.text = "E - próximo"


	command_label.show()


# ==========================================
# INICIAR MENSAGEM
# ==========================================

func start_message(
	position: Vector2,
	lines: Array[String],
	source = null
):

	# ==========================================
	# SE NÃO EXISTE TEXTO, NÃO ABRE
	# ==========================================

	if lines.is_empty():
		return


	# ==========================================
	# TROCA DE PLACA
	# ==========================================

	if is_message_active and current_source != source:

		if dialog_box != null:
			dialog_box.queue_free()
			dialog_box = null

		message_lines = lines
		dialog_box_position = position
		current_line = 0
		current_source = source

		show_text()

		update_command()

		return


	# ==========================================
	# ABRE NOVA MENSAGEM
	# ==========================================

	message_lines = lines
	dialog_box_position = position
	current_line = 0
	current_source = source

	is_message_active = true

	show_text()

	update_command()


# ==========================================
# MOSTRAR TEXTO
# ==========================================

func show_text():

	# ==========================================
	# SEGURANÇA
	# ==========================================

	if message_lines.is_empty():
		return


	# ==========================================
	# FECHA CAIXA ANTERIOR
	# ==========================================

	if dialog_box != null:
		dialog_box.queue_free()
		dialog_box = null


	# ==========================================
	# CRIA NOVA CAIXA
	# ==========================================

	dialog_box = dialog_box_scene.instantiate()

	dialog_box.text_display_finished.connect(
		_on_all_text_displayed
	)

	get_tree().root.add_child(dialog_box)

	dialog_box.global_position = dialog_box_position


	# ==========================================
	# MOSTRA TEXTO + CONTADOR
	# ==========================================

	dialog_box.display_text(
		message_lines[current_line],
		current_line + 1,
		message_lines.size()
	)

	can_advance_message = false


	# ==========================================
	# ATUALIZA AVISO
	# ==========================================

	update_command()


# ==========================================
# TEXTO TERMINOU DE APARECER
# ==========================================

func _on_all_text_displayed():

	can_advance_message = true


# ==========================================
# FECHAR DIÁLOGO FORÇADAMENTE
# ==========================================

func close_message():

	# ==========================================
	# FECHA A CAIXA VISUAL
	# ==========================================

	if dialog_box != null:

		dialog_box.queue_free()
		dialog_box = null


	# ==========================================
	# LIMPA TODOS OS DADOS
	# ==========================================

	message_lines.clear()

	current_line = 0

	dialog_box_position = Vector2.ZERO

	is_message_active = false
	can_advance_message = false

	current_source = null


	# ==========================================
	# ESCONDE AVISO
	# ==========================================

	if command_label != null:

		command_label.hide()


	print("DIÁLOGO FECHADO")


# ==========================================
# AVANÇAR DIÁLOGO
# ==========================================

func _unhandled_input(event):

	if event.is_action_pressed("advance_message") \
	and is_message_active \
	and can_advance_message:

		# ==========================================
		# FECHA TEXTO ATUAL
		# ==========================================

		if dialog_box != null:

			dialog_box.queue_free()
			dialog_box = null


		# ==========================================
		# PRÓXIMO TEXTO
		# ==========================================

		current_line += 1


		# ==========================================
		# TERMINOU TODOS
		# ==========================================

		if current_line >= message_lines.size():

			is_message_active = false
			current_line = 0
			current_source = null
			can_advance_message = false


			# ==========================================
			# ESCONDE AVISO
			# ==========================================

			if command_label != null:

				command_label.hide()


			return


		# ==========================================
		# MOSTRA PRÓXIMO
		# ==========================================

		show_text()

		update_command()
