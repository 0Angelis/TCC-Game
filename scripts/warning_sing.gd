extends Node2D


# ==========================================
# NÓS
# ==========================================

@onready var alert_sign = $alert_sign
@onready var area_sign = $area_sign


# ==========================================
# DIÁLOGO
# ==========================================

@export var dialog_texts: Array[String]


# ==========================================
# READY
# ==========================================

func _ready():

	alert_sign.hide()


# ==========================================
# PROCESS
# ==========================================

func _process(_delta):

	if area_sign.get_overlapping_bodies().size() > 0:

		alert_sign.show()

	else:

		alert_sign.hide()


# ==========================================
# INPUT
# ==========================================

func _input(event):

	if not event.is_action_pressed("interact"):
		return


	if area_sign.get_overlapping_bodies().size() <= 0:
		return


	# ==========================================
	# PROCURA O PLAYER
	# ==========================================

	var player = null

	for body in area_sign.get_overlapping_bodies():

		if body.is_in_group("player"):

			player = body

			break


	# ==========================================
	# TOCA WARNING
	# ==========================================

	if player != null:

		if player.has_method("play_warning"):

			player.play_warning()


	# ==========================================
	# DIÁLOGO
	# ==========================================

	if DialogManager.is_message_active:

		if DialogManager.current_source != self:

			alert_sign.hide()

			DialogManager.start_message(
				global_position,
				dialog_texts,
				self
			)

			get_viewport().set_input_as_handled()

		return


	alert_sign.hide()

	DialogManager.start_message(
		global_position,
		dialog_texts,
		self
	)

	get_viewport().set_input_as_handled()
