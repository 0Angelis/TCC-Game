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


func start_message(position: Vector2, lines: Array[String], source = null):

	# Se existe uma mensagem de outra placa,
	# fecha a anterior e abre a nova.
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


	# Abre uma nova mensagem normalmente
	message_lines = lines
	dialog_box_position = position
	current_line = 0
	current_source = source

	show_text()

	is_message_active = true


func show_text():

	# Segurança para não deixar duas caixas abertas
	if dialog_box != null:
		dialog_box.queue_free()

	# Cria a caixa de diálogo
	dialog_box = dialog_box_scene.instantiate()

	# Conecta o sinal de quando o texto terminou
	dialog_box.text_display_finished.connect(
		_on_all_text_displayed
	)

	# Adiciona a caixa na cena
	get_tree().root.add_child(dialog_box)

	# Posiciona a caixa
	dialog_box.global_position = dialog_box_position


	# ==========================================
	# CONTADOR
	# ==========================================

	dialog_box.display_text(
		message_lines[current_line],
		current_line + 1,
		message_lines.size()
	)


	can_advance_message = false


func _on_all_text_displayed():

	can_advance_message = true


func _unhandled_input(event):

	if event.is_action_pressed("advance_message") \
	and is_message_active \
	and can_advance_message:

		# Fecha o texto atual
		if dialog_box != null:
			dialog_box.queue_free()

		# Vai para o próximo texto
		current_line += 1


		# ==========================================
		# TERMINOU TODOS OS TEXTOS
		# ==========================================

		if current_line >= message_lines.size():

			is_message_active = false

			current_line = 0

			dialog_box = null

			current_source = null

			can_advance_message = false

			return


		# ==========================================
		# MOSTRA O PRÓXIMO TEXTO
		# ==========================================

		show_text()
