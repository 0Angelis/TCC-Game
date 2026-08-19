extends Area2D


func _ready() -> void:

	pass


func _process(_delta: float) -> void:

	pass


func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):

		return


	if not monitoring:

		return


	monitoring = false


	# ==========================================
	# ADICIONA 1 FRAGMENTO
	# ==========================================

	Globals.raciocinio_fragments += 1

	print(
		"FRAGMENTO DE RACIOCÍNIO: ",
		Globals.raciocinio_fragments
	)


	# ==========================================
	# VITÓRIA DO PLAYER
	# ==========================================

	if body.has_method("play_victory"):

		body.play_victory()

	else:

		print("ERRO: play_victory() não encontrado no Player")


	# ==========================================
	# ANIMAÇÃO DO FRAGMENTO
	# ==========================================

	if has_node("anim"):

		$anim.play("collect")


	# ==========================================
	# REMOVE O FRAGMENTO
	# ==========================================

	await get_tree().create_timer(0.1).timeout

	queue_free()
