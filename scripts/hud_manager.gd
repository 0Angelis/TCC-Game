extends Control

@onready var coins_counter = $container/coins_container/coins_counter as Label
@onready var timer_counter = $container/tiemer_container/timer_counter as Label
@onready var score_counter = $container/score_container/score_counter as Label
@onready var life_counter = $container/life_container/life_counter as Label

var time_left := 180.0 # 3 minutos
var game_over := false

func _ready():
	coins_counter.text = "%03d" % Globals.coins
	score_counter.text = "%06d" % Globals.score
	life_counter.text = "%02d" % Globals.player_life


func _process(delta):

	# Atualiza HUD
	coins_counter.text = "%03d" % Globals.coins
	score_counter.text = "%06d" % Globals.score
	life_counter.text = "%02d" % Globals.player_life

	# Timer
	if !game_over:

		time_left -= delta

		if time_left <= 0:
			time_left = 0
			game_over = true

			print("Tempo esgotado!")

			var player = get_tree().get_first_node_in_group("player")

			if player:
				player.die()

	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60

	timer_counter.text = "%02d:%02d" % [minutes, seconds]
