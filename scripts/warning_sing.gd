extends Node2D

@onready var alert_sign = $alert_sign
@onready var area_sign = $area_sign

@export var dialog_texts : Array[String]

func _unhandled_input(event):

	if area_sign.get_overlapping_bodies().size() > 0:

		alert_sign.show()

		if event.is_action_pressed("interact") and !DialogManager.is_message_active:

			alert_sign.hide()
			DialogManager.start_message(global_position, dialog_texts)

	else:

		alert_sign.hide()
