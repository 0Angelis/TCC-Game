extends Area2D


# ==========================================
# CONTROLE DE COLETA
# ==========================================

var coletada := false


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:

	# ==========================================
	# VERIFICA SE É O PLAYER
	# ==========================================

	if body.name != "player":
		return


	# ==========================================
	# IMPEDIR COLETA DUPLA
	# ==========================================

	if coletada:
		return


	# ==========================================
	# MARCA COMO COLETADA IMEDIATAMENTE
	# ==========================================

	coletada = true

	# Desativa completamente a colisão da moeda
	monitoring = false
	monitorable = false


	# ==========================================
	# SOM DA MOEDA
	# ==========================================

	$coin_sfx.play()


	# ==========================================
	# MOEDA TOTAL
	# ==========================================

	Globals.coins += 1


	# ==========================================
	# MOEDA COLETADA NESTE MAPA
	# ==========================================

	Globals.level_coins += 1


	# ==========================================
	# ANIMAÇÃO DA MOEDA
	# ==========================================

	$anim.play("collect")


	# ==========================================
	# ESPERA O SOM TERMINAR
	# ==========================================

	await $coin_sfx.finished


	# ==========================================
	# REMOVE A MOEDA
	# ==========================================

	queue_free()
