extends Control


# ==========================================
# CONTADORES DO HUD
# ==========================================

@onready var coins_counter = $container/coins_container/coins_counter as Label

@onready var timer_counter = $container/tiemer_container/timer_counter as Label

@onready var score_counter = $container/score_container/score_counter as Label

@onready var life_counter = $container/life_container/life_counter as Label


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


	var scene_path := current_scene.scene_file_path


	# ==========================================
	# WORLD 01
	# ==========================================

	if scene_path.ends_with("world_01.tscn"):

		return Globals.raciocinio_fragments


	# ==========================================
	# WORLD 02
	# ==========================================

	if scene_path.ends_with("world_02.tscn"):

		return Globals.atencao_fragments


	# ==========================================
	# WORLD 03
	# ==========================================

	if scene_path.ends_with("world_03.tscn"):

		return Globals.memoria_fragments


	return 0


# ==========================================
# READY
# ==========================================

func _ready():

	# ==========================================
	# MOEDAS
	# ==========================================

	coins_counter.text = "%03d" % Globals.coins


	# ==========================================
	# SCORE
	# ==========================================

	score_counter.text = "%06d" % Globals.score


	# ==========================================
	# VIDAS
	# ==========================================

	life_counter.text = "%02d" % Globals.player_life


	# ==========================================
	# FRAGMENTOS
	# ==========================================

	if fragment_counter != null:

		fragment_counter.text = "%d/5" % get_current_fragment_count()


# ==========================================
# PROCESS
# ==========================================

func _process(delta):

	# ==========================================
	# MOEDAS
	# ==========================================

	coins_counter.text = "%03d" % Globals.coins


	# ==========================================
	# SCORE
	# ==========================================

	score_counter.text = "%06d" % Globals.score


	# ==========================================
	# VIDAS
	# ==========================================

	life_counter.text = "%02d" % Globals.player_life


	# ==========================================
	# FRAGMENTOS
	# ==========================================

	if fragment_counter != null:

		fragment_counter.text = "%d/5" % get_current_fragment_count()


	# ==========================================
	# TIMER
	# ==========================================

	if not game_over:

		time_left -= delta


		if time_left <= 0:

			time_left = 0

			game_over = true

			print("Tempo esgotado!")


			var player = get_tree().get_first_node_in_group(
				"player"
			)


			if player:

				player.die()


	# ==========================================
	# MOSTRA TIMER
	# ==========================================

	var minutes = int(time_left) / 60

	var seconds = int(time_left) % 60


	timer_counter.text = "%02d:%02d" % [
		minutes,
		seconds
	]
