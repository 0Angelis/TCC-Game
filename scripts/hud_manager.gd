extends Control


# ==========================================
# CONTADORES DO HUD
# ==========================================

@onready var coins_counter = $container/coins_container/coins_counter as Label
@onready var timer_counter = $container/tiemer_container/timer_counter as Label
@onready var score_counter = $container/score_container/score_counter as Label
@onready var life_counter = $container/life_container/life_counter as Label

@onready var raciocinio_counter = get_node_or_null(
	"container/raciocinio_container/raciocinio_counter"
) as Label


# ==========================================
# TIMER
# ==========================================

# 10 minutos
var time_left := 600.0

var game_over := false


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

	if raciocinio_counter != null:

		raciocinio_counter.text = "%d/5" % Globals.raciocinio_fragments


func _process(delta):

	# ==========================================
	# ATUALIZA MOEDAS
	# ==========================================

	coins_counter.text = "%03d" % Globals.coins


	# ==========================================
	# ATUALIZA SCORE
	# ==========================================

	score_counter.text = "%06d" % Globals.score


	# ==========================================
	# ATUALIZA VIDAS
	# ==========================================

	life_counter.text = "%02d" % Globals.player_life


	# ==========================================
	# ATUALIZA FRAGMENTOS
	# ==========================================

	if raciocinio_counter != null:

		raciocinio_counter.text = "%d/5" % Globals.raciocinio_fragments


	# ==========================================
	# TIMER
	# ==========================================

	if not game_over:

		time_left -= delta


		if time_left <= 0:

			time_left = 0
			game_over = true

			print("Tempo esgotado!")


			var player = get_tree().get_first_node_in_group("player")


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
