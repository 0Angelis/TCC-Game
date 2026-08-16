extends Area2D


@onready var transition = $"../transition"

@export var next_level: String = ""


func _on_body_entered(body: Node2D) -> void:

	if body.is_in_group("player") and next_level != "":

		# ==========================================
		# RESET AO PASSAR DE FASE
		# ==========================================

		Globals.score = 0
		Globals.coins = 0

		Globals.level_score = 0
		Globals.level_coins = 0


		print("==============================")
		print("PASSANDO DE FASE")
		print("SCORE RESETADO: ", Globals.score)
		print("MOEDAS RESETADAS: ", Globals.coins)
		print("==============================")


		# ==========================================
		# MUDA PARA A PRÓXIMA FASE
		# ==========================================

		transition.change_scene(next_level)

	else:

		print("Cena carregada")
