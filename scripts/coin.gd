extends Area2D


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:

	if body.name == "player":

		monitoring = false

		# ==========================================
		# MOEDA TOTAL
		# ==========================================

		Globals.coins += 1

		# ==========================================
		# MOEDA COLETADA NESTE MAPA
		# ==========================================

		Globals.level_coins += 1

		$anim.play("collect")

		await get_tree().create_timer(0.1).timeout

		queue_free()
