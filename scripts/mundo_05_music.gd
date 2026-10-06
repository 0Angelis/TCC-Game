extends AudioStreamPlayer

const MUSICA := preload("res://sounds/mundos/mundo00.wav")

@export_range(-40.0, 5.0, 0.5)
var volume_musica_db: float = -20.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	stream = MUSICA
	volume_db = volume_musica_db
	bus = "Master"

	# garante que comece sozinho
	play()

	# garante o loop mesmo sem configurar pelo Import
	if not finished.is_connected(_on_finished):
		finished.connect(_on_finished)


func _on_finished() -> void:
	play()
