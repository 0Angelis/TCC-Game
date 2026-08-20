extends Area2D


# ==========================================
# TIPO DO FRAGMENTO
# ==========================================

@export_enum("Raciocinio", "Atencao", "Memoria")
var tipo_fragmento := "Raciocinio"


# ==========================================
# FRAGMENTOS
# ==========================================

@onready var frag_atencao = $fragmentos/Frag_atencao
@onready var frag_memoria = $fragmentos/Frag_memoria
@onready var frag_raciocinio = $fragmentos/Frag_raciocinio


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	# ==========================================
	# ESCONDE TODOS
	# ==========================================

	frag_atencao.hide()
	frag_memoria.hide()
	frag_raciocinio.hide()


	# ==========================================
	# MOSTRA O CORRETO
	# ==========================================

	match tipo_fragmento:

		"Raciocinio":
			frag_raciocinio.show()

		"Atencao":
			frag_atencao.show()

		"Memoria":
			frag_memoria.show()


	# ==========================================
	# ATIVA COLISÃO
	# ==========================================

	monitoring = true
	monitorable = true


# ==========================================
# PROCESS
# ==========================================

func _process(_delta: float) -> void:

	pass


# ==========================================
# PLAYER PEGOU O FRAGMENTO
# ==========================================

func _on_body_entered(body: Node2D) -> void:

	# ==========================================
	# VERIFICA PLAYER
	# ==========================================

	if not body.is_in_group("player"):

		return


	# ==========================================
	# EVITA DUPLA COLETA
	# ==========================================

	if not monitoring:

		return


	monitoring = false


	# ==========================================
	# ADICIONA NO CONTADOR CORRETO
	# ==========================================

	match tipo_fragmento:

		"Raciocinio":

			Globals.raciocinio_fragments += 1

			print(
				"FRAGMENTO DE RACIOCÍNIO: ",
				Globals.raciocinio_fragments
			)


		"Atencao":

			Globals.atencao_fragments += 1

			print(
				"FRAGMENTO DE ATENÇÃO: ",
				Globals.atencao_fragments
			)


		"Memoria":

			Globals.memoria_fragments += 1

			print(
				"FRAGMENTO DE MEMÓRIA: ",
				Globals.memoria_fragments
			)


	# ==========================================
	# VITÓRIA DO PLAYER
	# ==========================================

	if body.has_method("play_victory"):

		body.play_victory()

	else:

		print(
			"ERRO: play_victory() não encontrado no Player"
		)


	# ==========================================
	# TOCA ANIMAÇÃO DE COLETA
	# ==========================================

	match tipo_fragmento:

		"Raciocinio":

			if frag_raciocinio.has_method("play"):

				frag_raciocinio.play("collect")


		"Atencao":

			if frag_atencao.has_method("play"):

				frag_atencao.play("collect")


		"Memoria":

			if frag_memoria.has_method("play"):

				frag_memoria.play("collect")


	# ==========================================
	# ESPERA
	# ==========================================

	await get_tree().create_timer(0.1).timeout


	# ==========================================
	# REMOVE FRAGMENTO
	# ==========================================

	queue_free()
