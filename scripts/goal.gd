extends Area2D


@onready var transition = $"../transition"

@export var next_level: String = ""


func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):
		return


	# ==========================================
	# VERIFICA SE PEGOU TODOS OS FRAGMENTOS
	# ==========================================

	if Globals.raciocinio_fragments < 4:

		print("==============================")
		print("FASE BLOQUEADA!")
		print(
			"FRAGMENTOS: ",
			Globals.raciocinio_fragments,
			"/4"
		)
		print("Pegue todos os fragmentos!")
		print("==============================")


		# Não passa de fase
		return


	# ==========================================
	# VERIFICA SE EXISTE PRÓXIMA FASE
	# ==========================================

	if next_level == "":
		return


	# ==========================================
	# TODOS OS FRAGMENTOS FORAM COLETADOS
	# ==========================================

	print("==============================")
	print("TODOS OS FRAGMENTOS COLETADOS!")
	print("PASSANDO DE FASE!")
	print("==============================")


	# ==========================================
	# RESET SCORE E MOEDAS
	# ==========================================

	Globals.score = 0
	Globals.coins = 0

	Globals.level_score = 0
	Globals.level_coins = 0


	# ==========================================
	# RESET DOS FRAGMENTOS
	# ==========================================
	#
	# A próxima fase terá seus próprios 4
	# fragmentos.
	#

	Globals.raciocinio_fragments = 0


	print("SCORE RESETADO: ", Globals.score)
	print("MOEDAS RESETADAS: ", Globals.coins)
	print("FRAGMENTOS RESETADOS: ", Globals.raciocinio_fragments)


	# ==========================================
	# MUDA PARA A PRÓXIMA FASE
	# ==========================================

	transition.change_scene(next_level)
