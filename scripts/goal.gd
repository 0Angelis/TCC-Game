extends Area2D


@onready var transition = $"../transition"


# ==========================================
# CONFIGURAÇÕES
# ==========================================

@export_file("*.tscn") var next_level: String = ""


# ==========================================
# CONTROLE
# ==========================================

var can_change_scene: bool = true


# ==========================================
# VERIFICA SE É O TUTORIAL
# ==========================================

func is_tutorial() -> bool:

	var current_scene := get_tree().current_scene

	if current_scene == null:
		return false

	return current_scene.scene_file_path.ends_with("world_00.tscn")


# ==========================================
# PLAYER ENTROU NO GOAL
# ==========================================

func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):
		return


	if not can_change_scene:
		return


	# ==========================================
	# VERIFICA SE É O TUTORIAL
	# ==========================================

	var tutorial := is_tutorial()


	# ==========================================
	# FASES NORMAIS EXIGEM 5 FRAGMENTOS
	# ==========================================

	if not tutorial:

		if Globals.raciocinio_fragments < 5:

			print("==============================")
			print("FASE BLOQUEADA!")
			print(
				"FRAGMENTOS: ",
				Globals.raciocinio_fragments,
				"/5"
			)
			print("Pegue todos os fragmentos!")
			print("==============================")

			return


	# ==========================================
	# VERIFICA PRÓXIMA FASE
	# ==========================================

	if next_level == "":

		print("==============================")
		print("ERRO: PRÓXIMA FASE NÃO DEFINIDA!")
		print("==============================")

		return


	# ==========================================
	# IMPEDE DUPLA ATIVAÇÃO
	# ==========================================

	can_change_scene = false


	# ==========================================
	# MENSAGEM
	# ==========================================

	print("==============================")

	if tutorial:

		print("TUTORIAL CONCLUÍDO!")

	else:

		print("TODOS OS 5 FRAGMENTOS COLETADOS!")


	print("PASSANDO DE FASE!")
	print("PRÓXIMA FASE: ", next_level)

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

	Globals.raciocinio_fragments = 0


	print("SCORE RESETADO: ", Globals.score)
	print("MOEDAS RESETADAS: ", Globals.coins)
	print(
		"FRAGMENTOS RESETADOS: ",
		Globals.raciocinio_fragments
	)


	# ==========================================
	# MUDA DE FASE
	# ==========================================

	transition.change_scene(next_level)
