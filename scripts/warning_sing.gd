extends Node2D

@onready var texture = $texture
@onready var area = $area_sign

const LINES:Array[String] = [
	"Olá aventureiro!",
	"Bem-vindo ao jogo.",
	"Use A e D para andar.",
	"Use Espaço para pular.",
	"Boa sorte!"
]

func _process(_delta):

	if area.get_overlapping_bodies().size() > 0:
		texture.show()
	else:
		texture.hide()

func _unhandled_input(event):

	if area.get_overlapping_bodies().size() == 0:
		return

	if event.is_action_pressed("interact") and !DialogManager.is_message_active:

		DialogManager.start_message(global_position,LINES)
