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
# CANVAS DO STROOP
# =========================================================

var challenge_canvas: CanvasLayer = null
var stroop_instance: Control = null


# =========================================================
# TRANSIÇÃO
# =========================================================

var transition = null


# =========================================================
# READY
# =========================================================

func _ready():

	monitoring = true
	monitorable = true


	# =====================================================
	# PROCURA AUTOMATICAMENTE A TRANSIÇÃO
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
			"ERRO: nó 'transition' não encontrado no mundo 2!"
		)

	else:

		print(
			"TRANSIÇÃO ENCONTRADA!"
		)


	# =====================================================
	# CRIA AVISO
	# =====================================================

	_create_interaction_label()


	# =====================================================
	# SINAIS DA ÁREA
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
# CRIA AVISO "E - INTERAGIR"
# =========================================================

func _create_interaction_label():

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

	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	interaction_label.hide()

	add_child(
		interaction_label
	)


# =========================================================
# PLAYER ENTROU
# =========================================================

func _on_body_entered(body: Node2D):

	if not body.is_in_group("player"):

		return


	player_inside = true

	player = body


	if not challenge_open and not challenge_completed:

		interaction_label.show()


# =========================================================
# PLAYER SAIU
# =========================================================

func _on_body_exited(body: Node2D):

	if not body.is_in_group("player"):

		return


	player_inside = false

	# Mantém referência
	player = body

	interaction_label.hide()


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(event):

	if not player_inside:

		return


	if challenge_open:

		return


	if challenge_completed:

		return


	if transition_busy:

		return


	if not event.is_action_pressed("interact"):

		return


	# =====================================================
	# ESCONDE AVISO
	# =====================================================

	interaction_label.hide()


	# =====================================================
	# PLAYER
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

func _stop_player():

	if player == null:

		return


	if player.get("can_move") != null:

		player.set(
			"can_move",
			false
		)


	player.velocity = Vector2.ZERO


# =========================================================
# ABRE STROOP COM TRANSIÇÃO
# =========================================================

func _open_stroop_with_transition():

	if challenge_open:

		return


	challenge_open = true

	transition_busy = true


	# =====================================================
	# COBRE A TELA
	# =====================================================

	if transition != null:

		print(
			"INICIANDO TRANSIÇÃO DE ENTRADA..."
		)

		await transition.cover_screen()

	else:

		print(
			"AVISO: sem transition, abrindo Stroop normalmente."
		)


	# =====================================================
	# CRIA CANVAS
	# =====================================================

	challenge_canvas = CanvasLayer.new()

	challenge_canvas.layer = 200

	get_tree().root.add_child(
		challenge_canvas
	)


	# =====================================================
	# CRIA STROOP
	# =====================================================

	stroop_instance = STROOP_SCENE.instantiate()

	stroop_instance.process_mode = Node.PROCESS_MODE_ALWAYS


	# =====================================================
	# ADICIONA
	# =====================================================

	challenge_canvas.add_child(
		stroop_instance
	)


	# =====================================================
	# OCUPA A TELA INTEIRA
	# =====================================================

	stroop_instance.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	stroop_instance.position = Vector2.ZERO

	stroop_instance.size = get_viewport().get_visible_rect().size

	stroop_instance.mouse_filter = Control.MOUSE_FILTER_STOP


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
	# REVELA STROOP
	# =====================================================

	if transition != null:

		print(
			"REVELANDO STROOP..."
		)

		await transition.reveal_screen()


	transition_busy = false


	print(
		"STROOP ABERTO!"
	)


# =========================================================
# STROOP TERMINOU
# =========================================================

func _on_stroop_completed():

	if transition_busy:

		return


	transition_busy = true


	print(
		"STROOP CONCLUÍDO!"
	)


	# =====================================================
	# COBRE A TELA
	# =====================================================

	if transition != null:

		print(
			"INICIANDO TRANSIÇÃO DE SAÍDA..."
		)

		await transition.cover_screen()


	# =====================================================
	# REMOVE STROOP
	# =====================================================

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	stroop_instance = null


	# =====================================================
	# ESTADO
	# =====================================================

	challenge_open = false

	challenge_completed = true


	# =====================================================
	# DEVOLVE CONTROLE AO PLAYER
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
	# REVELA O MAPA
	# =====================================================

	if transition != null:

		print(
			"REVELANDO MAPA..."
		)

		await transition.reveal_screen()


	transition_busy = false


	print(
		"================================"
	)

	print(
		"PLAYER VOLTOU AO MAPA!"
	)

	print(
		"================================"
	)


# =========================================================
# LIMPEZA
# =========================================================

func _exit_tree():

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	stroop_instance = null
