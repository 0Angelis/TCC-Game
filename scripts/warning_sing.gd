extends Node2D

@onready var alert_sign = $alert_sign
@onready var area_sign = $area_sign

@export var dialog_texts: Array[String]


func _ready():
	alert_sign.hide()


func _process(_delta):

	if area_sign.get_overlapping_bodies().size() > 0:
		alert_sign.show()
	else:
		alert_sign.hide()


func _input(event):

	if not event.is_action_pressed("interact"):
		return

	# Verifica se o jogador realmente está perto desta placa
	if area_sign.get_overlapping_bodies().size() <= 0:
		return


	# Se já existe uma mensagem de OUTRA placa,
	# esta placa assume o diálogo.
	if DialogManager.is_message_active:

		if DialogManager.current_source != self:

			alert_sign.hide()

			DialogManager.start_message(
				global_position,
				dialog_texts,
				self
			)

			get_viewport().set_input_as_handled()

		# Se for a mesma placa, não fazemos nada aqui.
		# O DialogManager vai receber o E e avançar o texto.

		return


	# Nenhuma mensagem aberta.
	# Abre normalmente esta placa.
	alert_sign.hide()

	DialogManager.start_message(
		global_position,
		dialog_texts,
		self
	)

	get_viewport().set_input_as_handled()
