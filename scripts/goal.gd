extends Area2D


@onready var transition = $"../transition"


# ==========================================
# PRÓXIMA FASE
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

	return current_scene.scene_file_path.ends_with(
		"world_00.tscn"
	)


# ==========================================
# PEGA O TIPO DE FRAGMENTO DA FASE
# ==========================================

func get_fragment_count() -> int:

	var current_scene := get_tree().current_scene

	if current_scene == null:

		return 0


	var scene_path := current_scene.scene_file_path


	# ==========================================
	# MUNDO 1 → RACIOCÍNIO
	# ==========================================

	if scene_path.ends_with("world_01.tscn"):

		return Globals.raciocinio_fragments


	# ==========================================
	# MUNDO 2 → ATENÇÃO
	# ==========================================

	if scene_path.ends_with("world_02.tscn"):

		return Globals.atencao_fragments


	# ==========================================
	# MUNDO 3 → MEMÓRIA
	# ==========================================

	if scene_path.ends_with("world_03.tscn"):

		return Globals.memoria_fragments


	return 0


# ==========================================
# NOME DO TIPO
# ==========================================

func get_fragment_name() -> String:

	var current_scene := get_tree().current_scene

	if current_scene == null:

		return "Fragmentos"


	var scene_path := current_scene.scene_file_path


	if scene_path.ends_with("world_01.tscn"):

		return "Raciocínio"


	if scene_path.ends_with("world_02.tscn"):

		return "Atenção"


	if scene_path.ends_with("world_03.tscn"):

		return "Memória"


	return "Fragmentos"


# ==========================================
# PLAYER ENTROU NO PORTAL
# ==========================================

func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):

		return


	if not can_change_scene:

		return


	# ==========================================
	# TUTORIAL
	# ==========================================

	var tutorial := is_tutorial()


	# ==========================================
	# PEGA QUANTIDADE
	# ==========================================

	var fragments := get_fragment_count()


	# ==========================================
	# FASES NORMAIS EXIGEM 5
	# ==========================================

	if not tutorial:

		if fragments < 5:

			print("==============================")
			print("FASE BLOQUEADA!")
			print(
				"FRAGMENTOS DE ",
				get_fragment_name(),
				": ",
				fragments,
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

		print(
			"TODOS OS 5 FRAGMENTOS DE ",
			get_fragment_name(),
			" COLETADOS!"
		)


	print("PASSANDO DE FASE!")
	print("PRÓXIMA FASE: ", next_level)

	print("==============================")


	# ==========================================
	# RESET SCORE / MOEDAS
	# ==========================================

	Globals.score = 0
	Globals.coins = 0

	Globals.level_score = 0
	Globals.level_coins = 0


	# ==========================================
	# RESET DOS FRAGMENTOS
	# ==========================================

	Globals.raciocinio_fragments = 0
	Globals.atencao_fragments = 0
	Globals.memoria_fragments = 0


	print(
		"RACIOCÍNIO RESETADO: ",
		Globals.raciocinio_fragments
	)

	print(
		"ATENÇÃO RESETADA: ",
		Globals.atencao_fragments
	)

	print(
		"MEMÓRIA RESETADA: ",
		Globals.memoria_fragments
	)


	# ==========================================
	# MUDA DE FASE
	# ==========================================

	transition.change_scene(next_level)
