extends CanvasLayer


@onready var color_rect = $color_rect


# =========================================================
# READY
# =========================================================

func _ready():

	show_new_scene()


# =========================================================
# TROCAR DE CENA
# =========================================================

func change_scene(path, delay = 0.3):

	var scene_transition = get_tree().create_tween()

	scene_transition.tween_property(
		color_rect,
		"threshold",
		1.0,
		0.5
	).set_delay(delay).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await scene_transition.finished

	assert(
		get_tree().change_scene_to_file(path) == OK
	)


# =========================================================
# FECHAR TRANSIÇÃO / REVELAR TELA
# =========================================================

func show_new_scene():

	var show_transition = get_tree().create_tween()

	show_transition.tween_property(
		color_rect,
		"threshold",
		0.0,
		0.5
	).from(1.0).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await show_transition.finished


# =========================================================
# COBRIR A TELA
# =========================================================
# Usado quando vamos abrir o Stroop.
# A tela vai sendo coberta pelo efeito.
# =========================================================

func cover_screen():

	var cover_transition = get_tree().create_tween()

	cover_transition.tween_property(
		color_rect,
		"threshold",
		1.0,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await cover_transition.finished


# =========================================================
# REVELAR A TELA
# =========================================================
# Usado depois que o Stroop abre ou fecha.
# =========================================================

func reveal_screen():

	var reveal_transition = get_tree().create_tween()

	reveal_transition.tween_property(
		color_rect,
		"threshold",
		0.0,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await reveal_transition.finished
