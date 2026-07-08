extends Node

const DIALOG = preload("res://prefabs/dialog_box.tscn")

var dialog_box

var lines = []
var line = 0

var is_message_active = false
var can_next = false

func start_message(position:Vector2,new_lines:Array[String]):

	if is_message_active:
		return

	lines = new_lines
	line = 0

	is_message_active = true

	show_dialog(position)

func show_dialog(position):

	dialog_box = DIALOG.instantiate()

	get_tree().current_scene.add_child(dialog_box)

	dialog_box.global_position = position + Vector2(-120,-90)

	dialog_box.finished.connect(_finished)

	dialog_box.display_text(lines[line])

func _finished():

	can_next = true

func _unhandled_input(event):

	if !is_message_active:
		return

	if event.is_action_pressed("advance_message") and can_next:

		dialog_box.queue_free()

		can_next = false

		line += 1

		if line >= lines.size():

			is_message_active = false
			dialog_box = null
			return

		show_dialog(dialog_box.global_position)
