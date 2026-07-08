extends Control

@onready var coins_counter: Label = $container/coins_container/coins_counter
@onready var timer_counter: Label = $container/timer_container/timer_counter
@onready var score_counter: Label = $container/score_container/score_counter
@onready var life_counter: Label = $container/life_container/life_counter
@onready var clock_timer: Timer = $clock_timer

@export_range(0, 5) var default_minutes := 1
@export_range(0, 59) var default_seconds := 0

var minutes := 0
var seconds := 0

func _ready():

	minutes = default_minutes
	seconds = default_seconds

	coins_counter.text = "%03d" % Globals.coins
	score_counter.text = "%06d" % Globals.score
	life_counter.text = "%02d" % Globals.player_life
	timer_counter.text = "%02d:%02d" % [minutes, seconds]

	clock_timer.start()


func _process(delta):

	coins_counter.text = "%03d" % Globals.coins
	score_counter.text = "%06d" % Globals.score
	life_counter.text = "%02d" % Globals.player_life


func _on_clock_timer_timeout() -> void:

	if seconds > 0:
		seconds -= 1

	elif minutes > 0:
		minutes -= 1
		seconds = 59

	else:
		clock_timer.stop()
		print("Tempo acabou!")

	timer_counter.text = "%02d:%02d" % [minutes, seconds]
