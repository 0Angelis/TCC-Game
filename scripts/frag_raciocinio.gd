extends Area2D


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:

	if body.name == "player":

		monitoring = false

		# Adiciona 1 fragmento
		Globals.raciocinio_fragments += 1

		print("FRAGMENTO DE RACIOCÍNIO: ", Globals.raciocinio_fragments)

		# Toca a animação de coleta
		$anim.play("collect")

		await get_tree().create_timer(0.1).timeout

		queue_free()
