extends Area2D


# =========================================================
# CENA DO STROOP
# =========================================================

const STROOP_SCENE = preload(
	"res://stroop_challenge.tscn"
)


# =========================================================
# CONTROLE
# =========================================================

var player_inside := false
var challenge_open := false
var challenge_completed := false
var transition_busy := false


# =========================================================
# PLAYER
# =========================================================

var player = null


# =========================================================
# INTERAÇÃO
# =========================================================

var interaction_label: Label = null


# =========================================================
# CANVAS
# =========================================================

var challenge_canvas: CanvasLayer = null
var stroop_instance: Control = null


# =========================================================
# TRANSIÇÃO
# =========================================================

var transition = null


# =========================================================
# DIFICULDADE
# =========================================================

var difficulty := 1


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# =====================================================
	# DEFINE DIFICULDADE PELO NOME
	# =====================================================

	if name == "StroopTrigger":

		difficulty = 1

	elif name == "StroopTrigger2":

		difficulty = 2

	elif name == "StroopTrigger3":

		difficulty = 3

	else:

		difficulty = 1


	# =====================================================
	# ÁREA
	# =====================================================

	monitoring = true
	monitorable = true


	# =====================================================
	# PROCURA TRANSIÇÃO
	# =====================================================

	var current_scene = get_tree().current_scene


	if current_scene != null:

		transition = current_scene.find_child(
			"transition",
			true,
			false
		)


	if transition == null:

		print(
			"AVISO: nó 'transition' não encontrado!"
		)


	# =====================================================
	# INICIA PROGRESSÃO
	# =====================================================

	if not current_scene.has_meta(
		"stroop_progress"
	):

		current_scene.set_meta(
			"stroop_progress",
			1
		)


	# =====================================================
	# CRIA AVISO
	# =====================================================

	_create_interaction_label()


	# =====================================================
	# CONECTA ÁREA
	# =====================================================

	if not body_entered.is_connected(
		_on_body_entered
	):

		body_entered.connect(
			_on_body_entered
		)


	if not body_exited.is_connected(
		_on_body_exited
	):

		body_exited.connect(
			_on_body_exited
		)


	print(
		"================================"
	)

	print(
		"STROOP TRIGGER INICIADO"
	)

	print(
		"NOME: ",
		name
	)

	print(
		"DIFICULDADE: ",
		difficulty
	)

	print(
		"PRÓXIMO LIBERADO: ",
		_get_unlocked_level()
	)

	print(
		"================================"
	)


# =========================================================
# RETORNA QUAL STROOP ESTÁ LIBERADO
# =========================================================

func _get_unlocked_level() -> int:

	var current_scene = get_tree().current_scene


	if current_scene == null:

		return 1


	if not current_scene.has_meta(
		"stroop_progress"
	):

		current_scene.set_meta(
			"stroop_progress",
			1
		)


	return int(
		current_scene.get_meta(
			"stroop_progress"
		)
	)


# =========================================================
# VERIFICA SE ESTE TRIGGER ESTÁ LIBERADO
# =========================================================

func _is_unlocked() -> bool:

	return difficulty == _get_unlocked_level()


# =========================================================
# CRIA AVISO
# =========================================================

func _create_interaction_label() -> void:

	interaction_label = Label.new()

	interaction_label.text = "E - interagir"

	interaction_label.position = Vector2(
		-65,
		-55
	)

	interaction_label.add_theme_font_size_override(
		"font_size",
		14
	)

	interaction_label.add_theme_color_override(
		"font_color",
		Color("#7046A3")
	)

	interaction_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	interaction_label.add_theme_constant_override(
		"outline_size",
		4
	)

	interaction_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	interaction_label.hide()

	add_child(
		interaction_label
	)


# =========================================================
# PLAYER ENTROU
# =========================================================

func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):

		return


	player_inside = true

	player = body


	# =====================================================
	# SÓ MOSTRA SE FOR O DESAFIO DA VEZ
	# =====================================================

	if _is_unlocked():

		if not challenge_open:

			if not challenge_completed:

				interaction_label.show()

	else:

		interaction_label.hide()


	print(
		"PLAYER ENTROU EM: ",
		name
	)

	print(
		"LIBERADO: ",
		_is_unlocked()
	)


# =========================================================
# PLAYER SAIU
# =========================================================

func _on_body_exited(body: Node2D) -> void:

	if not body.is_in_group("player"):

		return


	player_inside = false

	player = null

	interaction_label.hide()


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	if not player_inside:

		return


	if challenge_open:

		return


	if challenge_completed:

		return


	if transition_busy:

		return


	# =====================================================
	# TRAVA DE ORDEM
	# =====================================================

	if not _is_unlocked():

		return


	# =====================================================
	# USA E / INTERACT
	# =====================================================

	if not event.is_action_pressed(
		"interact"
	):

		return


	# =====================================================
	# ESCONDE AVISO
	# =====================================================

	interaction_label.hide()


	# =====================================================
	# PEGA PLAYER
	# =====================================================

	if player == null:

		player = get_tree().get_first_node_in_group(
			"player"
		)


	if player == null:

		print(
			"ERRO: PLAYER NÃO ENCONTRADO!"
		)

		return


	# =====================================================
	# PARA PLAYER
	# =====================================================

	_stop_player()


	# =====================================================
	# ABRE STROOP
	# =====================================================

	_open_stroop_with_transition()


	get_viewport().set_input_as_handled()


# =========================================================
# PARA PLAYER
# =========================================================

func _stop_player() -> void:

	if player == null:

		return


	if player.get("can_move") != null:

		player.set(
			"can_move",
			false
		)


	player.velocity = Vector2.ZERO


# =========================================================
# ABRE STROOP
# =========================================================

func _open_stroop_with_transition() -> void:

	if challenge_open:

		return


	# =====================================================
	# SEGURANÇA DA ORDEM
	# =====================================================

	if not _is_unlocked():

		return


	challenge_open = true

	transition_busy = true


	print(
		"================================"
	)

	print(
		"ABRINDO ",
		name
	)

	print(
		"DIFICULDADE: ",
		difficulty
	)

	print(
		"================================"
	)


	# =====================================================
	# COBRE A TELA
	# =====================================================

	if transition != null:

		await _cover_screen()


	# =====================================================
	# PAUSA
	# =====================================================

	await get_tree().create_timer(
		0.25
	).timeout


	# =====================================================
	# CANVAS
	# =====================================================

	challenge_canvas = CanvasLayer.new()

	challenge_canvas.layer = 200

	get_tree().root.add_child(
		challenge_canvas
	)


	# =====================================================
	# INSTANCIA STROOP
	# =====================================================

	stroop_instance = STROOP_SCENE.instantiate()


	# =====================================================
	# PASSA DIFICULDADE
	# =====================================================

	stroop_instance.set(
		"difficulty",
		difficulty
	)


	print(
		"DIFICULDADE NO STROOP: ",
		stroop_instance.get(
			"difficulty"
		)
	)


	# =====================================================
	# PROCESSAMENTO
	# =====================================================

	stroop_instance.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	# =====================================================
	# ADICIONA
	# =====================================================

	challenge_canvas.add_child(
		stroop_instance
	)


	# =====================================================
	# TELA INTEIRA
	# =====================================================

	stroop_instance.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	stroop_instance.position = Vector2.ZERO

	stroop_instance.size = (
		get_viewport().get_visible_rect().size
	)

	stroop_instance.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# =====================================================
	# CONECTA FINAL
	# =====================================================

	if stroop_instance.has_signal(
		"challenge_completed"
	):

		if not stroop_instance.challenge_completed.is_connected(
			_on_stroop_completed
		):

			stroop_instance.challenge_completed.connect(
				_on_stroop_completed
			)

	else:

		print(
			"ERRO: Stroop não possui challenge_completed!"
		)


	# =====================================================
	# REVELA
	# =====================================================

	if transition != null:

		await _reveal_screen()


	transition_busy = false


	print(
		"STROOP ABERTO!"
	)


# =========================================================
# COBRIR TELA
# =========================================================

func _cover_screen() -> void:

	if transition == null:

		return


	var tween = transition.create_tween()


	tween.tween_property(
		transition.color_rect,
		"threshold",
		1.0,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


	await tween.finished


# =========================================================
# REVELAR TELA
# =========================================================

func _reveal_screen() -> void:

	if transition == null:

		return


	var tween = transition.create_tween()


	tween.tween_property(
		transition.color_rect,
		"threshold",
		0.0,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


	await tween.finished


# =========================================================
# STROOP TERMINOU
# =========================================================

func _on_stroop_completed() -> void:

	if transition_busy:

		return


	transition_busy = true


	print(
		"================================"
	)

	print(
		"STROOP ",
		difficulty,
		" CONCLUÍDO!"
	)

	print(
		"================================"
	)


	# =====================================================
	# COBRE TELA
	# =====================================================

	if transition != null:

		await _cover_screen()


	# =====================================================
	# REMOVE STROOP
	# =====================================================

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	stroop_instance = null


	# =====================================================
	# AVANÇA A ORDEM
	# =====================================================

	var current_scene = get_tree().current_scene


	if current_scene != null:

		current_scene.set_meta(
			"stroop_progress",
			difficulty + 1
		)


	# =====================================================
	# ATUALIZA ESTADO
	# =====================================================

	challenge_open = false

	challenge_completed = true


	# =====================================================
	# DEVOLVE MOVIMENTO
	# =====================================================

	if player == null:

		player = get_tree().get_first_node_in_group(
			"player"
		)


	if player != null:

		if player.get("can_move") != null:

			player.set(
				"can_move",
				true
			)

		player.velocity = Vector2.ZERO


	# =====================================================
	# REVELA MAPA
	# =====================================================

	if transition != null:

		await _reveal_screen()


	transition_busy = false


	print(
		"PRÓXIMO STROOP LIBERADO: ",
		difficulty + 1
	)


# =========================================================
# LIMPEZA
# =========================================================

func _exit_tree() -> void:

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	stroop_instance = null
