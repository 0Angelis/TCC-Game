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

	if area_sign.get_overlapping_bodies().size() <= 0:
		return


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
