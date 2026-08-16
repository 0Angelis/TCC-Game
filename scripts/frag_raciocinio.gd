extends Area2D

var coletado := false


func _ready():

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D):

	# Verifica se é o player
	if not body.is_in_group("player"):
		return

	# Evita coletar duas vezes
	if coletado:
		return

	coletado = true

	# Guarda que o fragmento foi coletado
	Globals.raciocinio_fragments += 1

	print("FRAGMENTO DE RACIOCÍNIO COLETADO!")
	print("Fragmentos: ", Globals.raciocinio_fragments)

	# Remove o fragmento da fase
	queue_free()
