extends AudioStreamPlayer

const MUSICA := preload("res://sounds/mundos/loja.wav")

@export_range(-40.0, 5.0, 0.5)
var volume_musica_db: float = -3.0


func _ready() -> void:
	stream = MUSICA
	volume_db = volume_musica_db
	bus = "Master"

	# Começa automaticamente.
	play()

	# Reinicia quando a música terminar.
	if not finished.is_connected(_on_musica_finished):
		finished.connect(_on_musica_finished)


func _on_musica_finished() -> void:
	play()
