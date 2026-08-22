extends Control


# ==========================================
# CONTADORES DO HUD
# ==========================================

@onready var coins_counter = (
	$container/coins_container/coins_counter
) as Label


@onready var timer_counter = (
	$container/tiemer_container/timer_counter
) as Label


@onready var score_counter = (
	$container/score_container/score_counter
) as Label


@onready var life_counter = (
	$container/life_container/life_counter
) as Label


@onready var fragment_counter = get_node_or_null(
	"container/raciocinio_container/raciocinio_counter"
) as Label


# ==========================================
# TIMER
# ==========================================

var time_left := 600.0

var game_over := false


# ==========================================
# PEGA QUANTIDADE DE FRAGMENTOS
# ==========================================

func get_current_fragment_count() -> int:

	var current_scene := get_tree().current_scene


	if current_scene == null:

		return 0


	var scene_path := (
		current_scene.scene_file_path
	)


	# ==========================================
	# WORLD 01
	# ==========================================

	if scene_path.ends_with(
		"world_01.tscn"
	):

		return Globals.raciocinio_fragments


	# ==========================================
	# WORLD 02
	# ==========================================

	if scene_path.ends_with(
		"world_02.tscn"
	):

		return Globals.atencao_fragments


	# ==========================================
	# WORLD 03
	# ==========================================

	if scene_path.ends_with(
		"world_03.tscn"
	):

		return Globals.memoria_fragments


	# ==========================================
	# NENHUM MUNDO
	# ==========================================

	return 0


# ==========================================
# PEGA LIMITE DE FRAGMENTOS DA FASE
# ==========================================

func get_required_fragment_count() -> int:

	var current_scene := get_tree().current_scene


	if current_scene == null:

		return 0


	var scene_path := (
		current_scene.scene_file_path
	)


	# ==========================================
	# WORLD 00
	# ==========================================

	if scene_path.ends_with(
		"world_00.tscn"
	):

		return 0


	# ==========================================
	# WORLD 01
	# ==========================================

	if scene_path.ends_with(
		"world_01.tscn"
	):

		return 5


	# ==========================================
	# WORLD 02
	# ==========================================

	if scene_path.ends_with(
		"world_02.tscn"
	):

		return 3


	# ==========================================
	# WORLD 03
	# ==========================================

	if scene_path.ends_with(
		"world_03.tscn"
	):

		return 5


	# ==========================================
	# PADRÃO
	# ==========================================

	return 0


# ==========================================
# ATUALIZA FRAGMENTOS
# ==========================================

func update_fragment_counter() -> void:

	if fragment_counter == null:

		return


	var current := (
		get_current_fragment_count()
	)


	var required := (
		get_required_fragment_count()
	)


	# ==========================================
	# WORLD 00
	# ==========================================

	if required <= 0:

		fragment_counter.text = ""

		return


	# ==========================================
	# SEGURANÇA
	# ==========================================

	current = clamp(
		current,
		0,
		required
	)


	# ==========================================
	# MOSTRA CONTADOR
	# ==========================================

	fragment_counter.text = (
		"%d/%d"
		% [
			current,
			required
		]
	)


# ==========================================
# READY
# ==========================================

func _ready():

	# ==========================================
	# MOEDAS
	# ==========================================

	coins_counter.text = (
		"%03d"
		% Globals.coins
	)


	# ==========================================
	# SCORE
	# ==========================================

	score_counter.text = (
		"%06d"
		% Globals.score
	)


	# ==========================================
	# VIDAS
	# ==========================================

	life_counter.text = (
		"%02d"
		% Globals.player_life
	)


	# ==========================================
	# FRAGMENTOS
	# ==========================================

	update_fragment_counter()


# ==========================================
# PROCESS
# ==========================================

func _process(delta):

	# ==========================================
	# MOEDAS
	# ==========================================

	coins_counter.text = (
		"%03d"
		% Globals.coins
	)


	# ==========================================
	# SCORE
	# ==========================================

	score_counter.text = (
		"%06d"
		% Globals.score
	)


	# ==========================================
	# VIDAS
	# ==========================================

	life_counter.text = (
		"%02d"
		% Globals.player_life
	)


	# ==========================================
	# FRAGMENTOS
	# ==========================================

	update_fragment_counter()


	# ==========================================
	# TIMER
	# ==========================================

	if not game_over:

		time_left -= delta


		if time_left <= 0:

			time_left = 0

			game_over = true

			print(
				"Tempo esgotado!"
			)


			var player = (
				get_tree().get_first_node_in_group(
					"player"
				)
			)


			if player:

				player.die()


	# ==========================================
	# MOSTRA TIMER
	# ==========================================

	var minutes = (
		int(time_left) / 60
	)


	var seconds = (
		int(time_left) % 60
	)


	timer_counter.text = (
		"%02d:%02d"
		% [
			minutes,
			seconds
		]
	)
