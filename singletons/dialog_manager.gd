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

		return


	# ==========================================
	# ABRE NOVA MENSAGEM
	# ==========================================

	message_lines = lines
	dialog_box_position = position
	current_line = 0
	current_source = source

	show_text()

	is_message_active = true


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


func _on_all_text_displayed():

	can_advance_message = true


# ==========================================
# FECHAR DIÁLOGO FORÇADAMENTE
# ==========================================

func close_message():

	# Fecha a caixa visual
	if dialog_box != null:

		dialog_box.queue_free()
		dialog_box = null


	# Limpa todos os dados
	message_lines.clear()

	current_line = 0

	dialog_box_position = Vector2.ZERO

	is_message_active = false
	can_advance_message = false

	current_source = null


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

			return


		# ==========================================
		# MOSTRA PRÓXIMO
		# ==========================================

		show_text()
