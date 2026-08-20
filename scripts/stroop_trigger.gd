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

# Pequena pausa antes do Stroop aparecer.
const STROOP_APPEAR_DELAY := 0.5

# Tempo que a tela fica fechada antes do mapa voltar.
const MAP_REVEAL_DELAY := 0.8

# Tempo da revelação do Stroop.
const STROOP_REVEAL_TIME := 0.75

# Tempo da revelação do mapa.
const MAP_REVEAL_TIME := 0.75

# Pequena pausa durante as trocas.
const TRANSITION_PAUSE := 0.15

# Tempo para o pinguim olhar para trás.
const WARNING_DELAY := 0.4

# Quanto tempo o pinguim dança depois de voltar.
const VICTORY_DANCE_TIME := 1.5


# =========================================================
# CAMADAS
# =========================================================

const STROOP_LAYER := 200
const HUD_LAYER := 300
const TRANSITION_LAYER := 1000


# =========================================================
# CONTROLE
# =========================================================

var player_inside := false
var challenge_open := false
var challenge_completed := false
var transition_busy := false

# Impede ganhar o mesmo fragmento duas vezes.
var fragment_awarded := false


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
var original_transition_layer := 0


# =========================================================
# HUD
# =========================================================

var hud = null
var original_hud_layer := 0

var hud_mouse_filters: Dictionary = {}


# =========================================================
# READY
# =========================================================

func _ready():

	monitoring = true
	monitorable = true


	# =====================================================
	# CENA ATUAL
	# =====================================================

	var current_scene = get_tree().current_scene


	# =====================================================
	# PROCURA TRANSIÇÃO
	# =====================================================

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

		if transition is CanvasLayer:

			original_transition_layer = transition.layer


	# =====================================================
	# PROCURA HUD
	# =====================================================

	if current_scene != null:

		hud = current_scene.find_child(
			"HUD",
			true,
			false
		)


	if hud == null:

		print(
			"ERRO: HUD NÃO ENCONTRADA!"
		)

	else:

		print(
			"HUD ENCONTRADA!"
		)

		if hud is CanvasLayer:

			original_hud_layer = hud.layer


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
	# OLHA PARA TRÁS
	# =====================================================

	if player.has_method("play_warning"):

		print(
			"PLAYER OLHANDO PARA TRÁS..."
		)

		player.play_warning()


	# =====================================================
	# ESPERA
	# =====================================================

	await get_tree().create_timer(
		WARNING_DELAY
	).timeout


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
# COLOCA TRANSIÇÃO NA FRENTE
# =========================================================

func _put_transition_in_front():

	if transition == null:
		return


	if transition is CanvasLayer:

		transition.layer = TRANSITION_LAYER


# =========================================================
# RESTAURA TRANSIÇÃO
# =========================================================

func _restore_transition_layer():

	if transition == null:
		return


	if transition is CanvasLayer:

		transition.layer = original_transition_layer


# =========================================================
# COLOCA HUD NA FRENTE
# =========================================================

func _put_hud_in_front():

	if hud == null:
		return


	if hud is CanvasLayer:

		hud.layer = HUD_LAYER


# =========================================================
# RESTAURA HUD
# =========================================================

func _restore_hud_layer():

	if hud == null:
		return


	if hud is CanvasLayer:

		hud.layer = original_hud_layer


# =========================================================
# DESATIVA CLIQUES DA HUD
# =========================================================

func _disable_hud_mouse():

	if hud == null:
		return


	hud_mouse_filters.clear()


	var controls = _get_hud_controls(hud)


	for control in controls:

		if control == null:
			continue


		hud_mouse_filters[control] = control.mouse_filter

		control.mouse_filter = Control.MOUSE_FILTER_IGNORE


	print(
		"CLIQUES DA HUD DESATIVADOS!"
	)


# =========================================================
# RESTAURA CLIQUES DA HUD
# =========================================================

func _restore_hud_mouse():

	if hud_mouse_filters.is_empty():
		return


	for control in hud_mouse_filters:

		if is_instance_valid(control):

			control.mouse_filter = hud_mouse_filters[control]


	hud_mouse_filters.clear()


	print(
		"CLIQUES DA HUD RESTAURADOS!"
	)


# =========================================================
# PEGA TODOS OS CONTROLS DA HUD
# =========================================================

func _get_hud_controls(node: Node) -> Array:

	var result: Array = []


	if node is Control:

		result.append(node)


	for child in node.get_children():

		result.append_array(
			_get_hud_controls(child)
		)


	return result


# =========================================================
# ABRE STROOP
# =========================================================

func _open_stroop_with_transition():

	if challenge_open:
		return


	challenge_open = true
	transition_busy = true


	# =====================================================
	# HUD
	# =====================================================

	_put_hud_in_front()

	_disable_hud_mouse()


	# =====================================================
	# TRANSIÇÃO
	# =====================================================

	_put_transition_in_front()


	# =====================================================
	# COBRE A TELA
	# =====================================================

	if transition != null:

		print(
			"TRANSIÇÃO DE ENTRADA..."
		)

		await _cover_screen()


	# =====================================================
	# PAUSA
	# =====================================================

	await get_tree().create_timer(
		TRANSITION_PAUSE
	).timeout


	# =====================================================
	# ESPERA ANTES DO STROOP
	# =====================================================

	await get_tree().create_timer(
		STROOP_APPEAR_DELAY
	).timeout


	# =====================================================
	# CANVAS
	# =====================================================

	challenge_canvas = CanvasLayer.new()

	challenge_canvas.layer = STROOP_LAYER

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
	# HUD
	# =====================================================

	_put_hud_in_front()

	_disable_hud_mouse()


	# =====================================================
	# SINAL
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
	# TRANSIÇÃO ACIMA DE TUDO
	# =====================================================

	_put_transition_in_front()


	# =====================================================
	# REVELA STROOP
	# =====================================================

	if transition != null:

		print(
			"REVELANDO STROOP..."
		)

		await _reveal_screen(
			STROOP_REVEAL_TIME
		)


	# =====================================================
	# RESTAURA TRANSIÇÃO
	# =====================================================

	_restore_transition_layer()


	_put_hud_in_front()


	transition_busy = false


	print(
		"STROOP ABERTO!"
	)


# =========================================================
# COBRIR TELA
# =========================================================

func _cover_screen():

	if transition == null:
		return


	var tween = transition.create_tween()


	tween.tween_property(
		transition.color_rect,
		"threshold",
		1.0,
		0.55
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


	await tween.finished


# =========================================================
# REVELAR TELA
# =========================================================

func _reveal_screen(duration: float):

	if transition == null:
		return


	var tween = transition.create_tween()


	tween.tween_property(
		transition.color_rect,
		"threshold",
		0.0,
		duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


	await tween.finished


# =========================================================
# GANHA FRAGMENTO
# =========================================================

func _give_attention_fragment():

	if fragment_awarded:
		return


	fragment_awarded = true


	Globals.atencao_fragments += 1


	print(
		"================================"
	)

	print(
		"FRAGMENTO DE ATENÇÃO GANHO!"
	)

	print(
		"TOTAL DE ATENÇÃO: ",
		Globals.atencao_fragments
	)

	print(
		"================================"
	)


# =========================================================
# ANIMAÇÃO DE VITÓRIA
# =========================================================

func _play_completion_animation():

	if player == null:
		return


	if player.has_method("play_victory"):

		print(
			"PLAYER: ANIMAÇÃO DE VITÓRIA!"
		)

		player.play_victory()

	else:

		print(
			"ERRO: player não possui play_victory()!"
		)


# =========================================================
# PARA A VITÓRIA E DEVOLVE O MOVIMENTO
# =========================================================

func _finish_victory_animation():

	if player == null:
		return


	# Cancela o estado de comemoração.
	if player.get("celebrating") != null:

		player.set(
			"celebrating",
			false
		)


	# Devolve movimento.
	if player.get("can_move") != null:

		player.set(
			"can_move",
			true
		)


	player.velocity = Vector2.ZERO


	print(
		"ANIMAÇÃO DE VITÓRIA FINALIZADA!"
	)


# =========================================================
# STROOP TERMINOU
# =========================================================

func _on_stroop_completed():

	if transition_busy:
		return


	transition_busy = true


	print(
		"================================"
	)

	print(
		"STROOP CONCLUÍDO!"
	)

	print(
		"================================"
	)


	# =====================================================
	# FRAGMENTO
	# =====================================================

	_give_attention_fragment()


	# =====================================================
	# HUD
	# =====================================================

	_put_hud_in_front()


	# =====================================================
	# TRANSIÇÃO
	# =====================================================

	_put_transition_in_front()


	# =====================================================
	# FECHA A TELA
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
	# ESPERA UM FRAME
	# =====================================================

	await get_tree().process_frame


	# =====================================================
	# ESTADO
	# =====================================================

	challenge_open = false
	challenge_completed = true


	# =====================================================
	# PEGA PLAYER
	# =====================================================

	if player == null:

		player = get_tree().get_first_node_in_group(
			"player"
		)


	# =====================================================
	# MANTÉM PLAYER PARADO
	# =====================================================

	if player != null:

		player.velocity = Vector2.ZERO

		if player.get("can_move") != null:

			player.set(
				"can_move",
				false
			)


	# =====================================================
	# ESPERA
	# =====================================================

	print(
		"AGUARDANDO ANTES DO RETORNO..."
	)


	await get_tree().create_timer(
		MAP_REVEAL_DELAY
	).timeout


	# =====================================================
	# TRANSIÇÃO NA FRENTE
	# =====================================================

	_put_transition_in_front()


	# =====================================================
	# REVELA O MAPA PRIMEIRO
	# =====================================================

	if transition != null:

		print(
			"REVELANDO MAPA..."
		)

		await _reveal_screen(
			MAP_REVEAL_TIME
		)


	# =====================================================
	# AGORA O PLAYER ESTÁ VISÍVEL
	# =====================================================

	_play_completion_animation()


	# =====================================================
	# DANÇA
	# =====================================================

	print(
		"PLAYER VAI DANÇAR POR ",
		VICTORY_DANCE_TIME,
		" SEGUNDOS!"
	)


	await get_tree().create_timer(
		VICTORY_DANCE_TIME
	).timeout


	# =====================================================
	# PARA DANÇA E DEVOLVE CONTROLE
	# =====================================================

	_finish_victory_animation()


	# =====================================================
	# RESTAURA CAMADAS
	# =====================================================

	_restore_transition_layer()

	_restore_hud_layer()

	_restore_hud_mouse()


	# =====================================================
	# FINAL
	# =====================================================

	transition_busy = false


	print(
		"================================"
	)

	print(
		"MAPA REVELADO!"
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


	_restore_transition_layer()

	_restore_hud_layer()

	_restore_hud_mouse()

	stroop_instance = null
