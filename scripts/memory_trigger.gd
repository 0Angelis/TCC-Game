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
# SOM DO FRAGMENTO
# =========================================================
# O som está dentro do memory_game.tscn.
# Aqui guardamos o Stream para tocar depois da transição.

var fragmento_stream: AudioStream = null


# =========================================================
# QUAL DOS 3 DESAFIOS É ESTE?
# =========================================================

func _get_challenge_number() -> int:

	match name:

		"MemoryTrigger":
			return 1

		"MemoryTrigger2":
			return 2

		"MemoryTrigger3":
			return 3

	return 1


# =========================================================
# PEGA PROGRESSO DA MEMÓRIA
# =========================================================

func _get_memory_progress() -> int:

	var world: Node = get_tree().current_scene

	if world == null:

		return 0

	if not world.has_meta("memory_progress"):

		return 0

	return int(
		world.get_meta(
			"memory_progress"
		)
	)


# =========================================================
# VERIFICA SE O DESAFIO ESTÁ LIBERADO
# =========================================================

func _is_unlocked() -> bool:

	var challenge_number: int = (
		_get_challenge_number()
	)

	if challenge_number == 1:

		return true

	return _get_memory_progress() >= (
		challenge_number - 1
	)


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


		if transition != null:

			transition.process_mode = (
				Node.PROCESS_MODE_ALWAYS
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
		and _is_unlocked()
	):

		interaction_label.show()

	else:

		interaction_label.hide()


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


	if not _is_unlocked():

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


	if not _is_unlocked():

		return


	challenge_open = true

	transition_busy = true


	# =====================================================
	# COBRE A TELA
	# =====================================================

	if transition != null:

		await _cover_screen()


	# =====================================================
	# PEQUENA ESPERA
	# =====================================================

	await get_tree().create_timer(
		0.25
	).timeout


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
	# INSTANCIA MEMORY
	# =====================================================

	memory_instance = (
		MEMORY_SCENE.instantiate()
	)


	memory_instance.set(
		"challenge_type",
		_get_challenge_number()
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
	# CONECTA FINAL
	# =====================================================

	if memory_instance.has_signal(
		"challenge_completed"
	):

		if not memory_instance.challenge_completed.is_connected(
			_on_memory_completed
		):

			memory_instance.challenge_completed.connect(
				_on_memory_completed
			)


	# =====================================================
	# REVELA MEMORY
	# =====================================================

	if transition != null:

		await _reveal_screen()


	transition_busy = false


# =========================================================
# PEGA O SOM DO MEMORY GAME
# =========================================================
# O AudioStreamPlayer está dentro de memory_game.tscn
# com o nome "fragmento_collect_sfx".

func _save_fragment_sound() -> void:

	fragmento_stream = null


	if memory_instance == null:

		print(
			"ERRO: memory_instance não existe."
		)

		return


	var sound_node: Node = (
		memory_instance.get_node_or_null(
			"fragmento_collect_sfx"
		)
	)


	if sound_node == null:

		print(
			"ERRO: fragmento_collect_sfx não encontrado no memory_game.tscn."
		)

		return


	if sound_node is AudioStreamPlayer:

		var audio_player: AudioStreamPlayer = (
			sound_node as AudioStreamPlayer
		)


		if audio_player.stream != null:

			fragmento_stream = audio_player.stream

			print(
				"SOM DO FRAGMENTO ENCONTRADO!"
			)

		else:

			print(
				"ERRO: fragmento_collect_sfx está sem Stream."
			)

	else:

		print(
			"ERRO: fragmento_collect_sfx não é AudioStreamPlayer."
		)


# =========================================================
# TOCA O SOM DO FRAGMENTO
# =========================================================
# Cria um AudioStreamPlayer independente no mundo.
# Assim ele não é destruído quando o Memory Game é removido.

func _play_fragment_sound() -> void:

	if fragmento_stream == null:

		print(
			"ERRO: nenhum som de fragmento foi salvo."
		)

		return


	var world: Node = get_tree().current_scene


	if world == null:

		print(
			"ERRO: mundo atual não encontrado."
		)

		return


	var sound_player: AudioStreamPlayer = (
		AudioStreamPlayer.new()
	)


	sound_player.name = (
		"FragmentoCollectSound"
	)

	sound_player.stream = fragmento_stream

	sound_player.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	sound_player.bus = "Master"

	sound_player.volume_db = -7.0


	world.add_child(
		sound_player
	)


	sound_player.play()


	print(
		"SOM DO FRAGMENTO TOCANDO APÓS A TRANSIÇÃO!"
	)


	sound_player.finished.connect(
		sound_player.queue_free
	)


# =========================================================
# DESAFIO CONCLUÍDO
# =========================================================

func _on_memory_completed() -> void:

	if transition_busy:

		return


	transition_busy = true

	interaction_label.hide()


	# =====================================================
	# PEGA O SOM ANTES DE DESTRUIR O MEMORY GAME
	# =====================================================

	_save_fragment_sound()


	# =====================================================
	# COBRE A TELA
	# =====================================================

	if transition != null:

		await _cover_screen()


	# =====================================================
	# MARCA PROGRESSO + FRAGMENTO DE MEMÓRIA
	# =====================================================

	var challenge_number: int = (
		_get_challenge_number()
	)

	var world: Node = get_tree().current_scene


	if world != null:

		# =================================================
		# GUARDA QUAL DESAFIO FOI CONCLUÍDO
		# =================================================

		world.set_meta(
			"memory_progress",
			max(
				_get_memory_progress(),
				challenge_number
			)
		)


		# =================================================
		# CADA DESAFIO LIBERA 1 FRAGMENTO
		# =================================================

		var novos_fragmentos: int = clamp(
			challenge_number,
			0,
			3
		)


		Globals.memoria_fragments = max(
			Globals.memoria_fragments,
			novos_fragmentos
		)


	# =====================================================
	# REMOVE MEMORY GAME
	# =====================================================

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	memory_instance = null


	# =====================================================
	# ESTADO DO DESAFIO
	# =====================================================

	challenge_open = false

	challenge_completed = true


	# =====================================================
	# DEVOLVE MOVIMENTO
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
	# REVELA WORLD 03
	# =====================================================

	if transition != null:

		await _reveal_screen()


	# =====================================================
	# ESPERA UM FRAME
	# =====================================================

	await get_tree().process_frame


	# =====================================================
	# TOCA O SOM DEPOIS DA TRANSIÇÃO
	# =====================================================

	_play_fragment_sound()


	# =====================================================
	# FINALIZA
	# =====================================================

	transition_busy = false


# =========================================================
# DERROTA
# =========================================================

func _on_memory_failed() -> void:

	# Mantido somente para compatibilidade.
	# A tela de derrota/retry é controlada pelo Memory Game.

	return


# =========================================================
# EFEITO RETRÔ - FECHAR
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
# LIMPEZA
# =========================================================

func _exit_tree() -> void:

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	memory_instance = null
