extends Area2D


# =========================================================
# CENA DO STROOP
# =========================================================

const STROOP_SCENE = preload(
	"res://stroop_challenge.tscn"
)


# =========================================================
# CONFIGURAÇÃO
# =========================================================

# Pequena pausa antes de o Stroop aparecer.
const STROOP_APPEAR_DELAY := 0.5


# Tempo que a tela permanece totalmente fechada
# antes de o mapa voltar a aparecer.
const MAP_REVEAL_DELAY := 0.8


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
	# PROCURA A TRANSIÇÃO
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
			"ERRO: nó 'transition' não encontrado!"
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


# =========================================================
# CRIA "E - INTERAGIR"
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
# ABRE STROOP
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
			"TRANSIÇÃO DE ENTRADA..."
		)

		await _cover_screen()


	# =====================================================
	# PEQUENA PAUSA
	# =====================================================

	await get_tree().create_timer(
		STROOP_APPEAR_DELAY
	).timeout


	# =====================================================
	# CRIA CANVAS
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

	stroop_instance.process_mode = Node.PROCESS_MODE_ALWAYS


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

		await _reveal_screen()


	transition_busy = false


	print(
		"STROOP ABERTO!"
	)


# =========================================================
# COBRIR TELA
# =========================================================

func _cover_screen():

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

func _reveal_screen():

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

func _on_stroop_completed():

	if transition_busy:

		return


	transition_busy = true


	print(
		"STROOP CONCLUÍDO!"
	)


	# =====================================================
	# COBRE TELA
	# =====================================================

	if transition != null:

		print(
			"TRANSIÇÃO DE SAÍDA..."
		)

		await _cover_screen()


	# =====================================================
	# REMOVE STROOP
	# =====================================================

	if challenge_canvas != null:

		challenge_canvas.queue_free()

		challenge_canvas = null


	stroop_instance = null


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
	# ESPERA ANTES DE MOSTRAR O MAPA
	# =====================================================

	print(
		"AGUARDANDO ANTES DE REVELAR O MAPA..."
	)

	await get_tree().create_timer(
		MAP_REVEAL_DELAY
	).timeout


	# =====================================================
	# REVELA MAPA
	# =====================================================

	if transition != null:

		print(
			"REVELANDO MAPA..."
		)

		await _reveal_screen()


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
