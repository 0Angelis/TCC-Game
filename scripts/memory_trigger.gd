extends Area2D


# =========================================================
# CENA DO DESAFIO
# =========================================================

const MEMORY_SCENE = preload(
	"res://scenes/memory_game.tscn"
)


# =========================================================
# WORLD 03
# =========================================================

const WORLD_03_SCENE: String = (
	"res://scenes/world_03.tscn"
)


# =========================================================
# ESTADOS
# =========================================================

var player_inside: bool = false

var challenge_open: bool = false

var challenge_completed: bool = false

var transition_busy: bool = false


# =========================================================
# PLAYER
# =========================================================

var player: Node = null


# =========================================================
# INTERAÇÃO
# =========================================================

var interaction_label: Label = null


# =========================================================
# MEMORY
# =========================================================

var challenge_canvas: CanvasLayer = null

var memory_instance: Control = null


# =========================================================
# TRANSIÇÃO
# =========================================================

var transition: Node = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	monitoring = true

	monitorable = true


	# =====================================================
	# PROCURA TRANSIÇÃO
	# =====================================================

	var current_scene: Node = (
		get_tree().current_scene
	)


	if current_scene != null:

		transition = current_scene.find_child(
			"transition",
			true,
			false
		)


	# =====================================================
	# INTERAÇÃO
	# =====================================================

	_create_interaction_label()


	# =====================================================
	# SINAIS
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


# =========================================================
# LABEL
# =========================================================

func _create_interaction_label() -> void:

	interaction_label = Label.new()

	interaction_label.text = (
		"E - interagir"
	)

	interaction_label.position = Vector2(
		-65,
		-55
	)

	interaction_label.size = Vector2(
		130,
		30
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

func _on_body_entered(
	body: Node2D
) -> void:

	if not body.is_in_group(
		"player"
	):

		return


	player_inside = true

	player = body


	if (
		not challenge_open
		and not challenge_completed
		and not transition_busy
	):

		interaction_label.show()


# =========================================================
# PLAYER SAIU
# =========================================================

func _on_body_exited(
	body: Node2D
) -> void:

	if not body.is_in_group(
		"player"
	):

		return


	player_inside = false

	player = null

	interaction_label.hide()


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	if not player_inside:

		return


	if challenge_open:

		return


	if challenge_completed:

		return


	if transition_busy:

		return


	if not event.is_action_pressed(
		"interact"
	):

		return


	interaction_label.hide()


	# =====================================================
	# PLAYER
	# =====================================================

	if player == null:

		player = (
			get_tree()
			.get_first_node_in_group(
				"player"
			)
		)


	if player == null:

		return


	# =====================================================
	# PARA PLAYER
	# =====================================================

	_stop_player()


	# =====================================================
	# ABRE DESAFIO
	#
	# IMPORTANTE:
	# NÃO USA EFEITO RETRÔ AQUI.
	# =====================================================

	_open_memory()


	get_viewport().set_input_as_handled()


# =========================================================
# PARA PLAYER
# =========================================================

func _stop_player() -> void:

	if player == null:

		return


	if player.get(
		"can_move"
	) != null:

		player.set(
			"can_move",
			false
		)


	if player.get(
		"velocity"
	) != null:

		player.velocity = Vector2.ZERO


# =========================================================
# ABRE MEMORY GAME
# =========================================================

func _open_memory() -> void:

	if challenge_open:

		return


	challenge_open = true

	transition_busy = true


	# =====================================================
	# CRIA CANVAS
	# =====================================================

	challenge_canvas = CanvasLayer.new()

	challenge_canvas.name = (
		"MemoryChallengeCanvas"
	)

	challenge_canvas.layer = 200

	challenge_canvas.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	get_tree().root.add_child(
		challenge_canvas
	)


	# =====================================================
	# INSTANCIA
	# =====================================================

	memory_instance = (
		MEMORY_SCENE.instantiate()
	)


	memory_instance.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	challenge_canvas.add_child(
		memory_instance
	)


	# =====================================================
	# TELA INTEIRA
	# =====================================================

	memory_instance.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	memory_instance.position = Vector2.ZERO

	memory_instance.size = (
		get_viewport()
		.get_visible_rect()
		.size
	)

	memory_instance.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# =====================================================
	# VITÓRIA
	# =====================================================

	if memory_instance.has_signal(
		"challenge_completed"
	):

		memory_instance.challenge_completed.connect(
			_on_memory_completed
		)


	# =====================================================
	# DERROTA
	# =====================================================

	if memory_instance.has_signal(
		"challenge_failed"
	):

		memory_instance.challenge_failed.connect(
			_on_memory_failed
		)


	transition_busy = false


# =========================================================
# DESAFIO CONCLUÍDO
# =========================================================

func _on_memory_completed() -> void:

	if transition_busy:

		return


	transition_busy = true

	interaction_label.hide()


	# =====================================================
	# ESPERA O JOGADOR CLICAR CONTINUAR
	# =====================================================
	#
	# O signal acontece quando ele aperta CONTINUAR.
	#
	# AGORA SIM entra o efeito retrô.
	#


	# =====================================================
	# EFEITO RETRÔ
	# =====================================================

	if transition != null:

		await _cover_screen()


	# =====================================================
	# REMOVE MEMORY
	# =====================================================

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	memory_instance = null


	# =====================================================
	# ESTADO
	# =====================================================

	challenge_open = false

	challenge_completed = true


	# =====================================================
	# PLAYER
	# =====================================================

	if player == null:

		player = (
			get_tree()
			.get_first_node_in_group(
				"player"
			)
		)


	if player != null:

		if player.get(
			"can_move"
		) != null:

			player.set(
				"can_move",
				true
			)


		if player.get(
			"velocity"
		) != null:

			player.velocity = Vector2.ZERO


	# =====================================================
	# WORLD 03
	# =====================================================

	var current_scene: Node = (
		get_tree().current_scene
	)


	if current_scene != null:

		if current_scene.scene_file_path == WORLD_03_SCENE:

			if transition != null:

				await _reveal_screen()


			transition_busy = false

			return


	# =====================================================
	# CASO PRECISE RECARREGAR
	# =====================================================

	await get_tree().change_scene_to_file(
		WORLD_03_SCENE
	)


# =========================================================
# DERROTA
# =========================================================

func _on_memory_failed() -> void:

	if transition_busy:

		return


	transition_busy = true


	# =====================================================
	# EFEITO RETRÔ
	# =====================================================

	if transition != null:

		await _cover_screen()


	# =====================================================
	# AQUI NÃO FECHAMOS O MEMORY.
	#
	# A TELA DE "VOCÊ PERDEU" CONTINUA ABERTA.
	# O efeito retrô acontece como encerramento visual.
	#
	# =====================================================

	if transition != null:

		await _reveal_screen()


	transition_busy = false


# =========================================================
# EFEITO RETRÔ - FECHAR
# =========================================================

func _cover_screen() -> void:

	if transition == null:

		return


	if not is_instance_valid(
		transition
	):

		return


	var color_rect = transition.get(
		"color_rect"
	)


	if color_rect == null:

		return


	var tween: Tween = (
		transition.create_tween()
	)


	tween.tween_property(
		color_rect,
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
# EFEITO RETRÔ - ABRIR
# =========================================================

func _reveal_screen() -> void:

	if transition == null:

		return


	if not is_instance_valid(
		transition
	):

		return


	var color_rect = transition.get(
		"color_rect"
	)


	if color_rect == null:

		return


	var tween: Tween = (
		transition.create_tween()
	)


	tween.tween_property(
		color_rect,
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
# LIMPEZA
# =========================================================

func _exit_tree() -> void:

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	memory_instance = null
