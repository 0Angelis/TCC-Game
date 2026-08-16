extends Area2D

@onready var transition = $"../transition"

@export var next_level: String = ""


func _on_body_entered(body: Node2D) -> void:

	if body.is_in_group("player") and next_level != "":

		# ==========================================
		# NÃO RESETAR SCORE NEM MOEDAS
		# ==========================================
		# Os valores continuam salvos no Globals
		# ao mudar de fase.
		
		print("PASSANDO DE FASE")
		print("MOEDAS: ", Globals.coins)
		print("SCORE: ", Globals.score)

		transition.change_scene(next_level)

	else:

		print("Cena carregada")
