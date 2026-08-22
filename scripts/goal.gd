extends Area2D


# =========================================================
# TRANSIÇÃO
# =========================================================

var transition = null


# =========================================================
# PRÓXIMA FASE
# =========================================================

@export_file("*.tscn")
var next_level: String = ""


# =========================================================
# LABEL DO CONTADOR
# =========================================================

var fragment_label: Label = null


# =========================================================
# LABEL DA MENSAGEM DO PORTAL
# =========================================================

var portal_message_label: Label = null


# =========================================================
# CONTROLE
# =========================================================

var can_change_scene := true


# =========================================================
# PLAYER PERTO DO PORTAL
# =========================================================

var player_near_portal := false


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# =====================================================
	# PROCURA TRANSIÇÃO
	# =====================================================

	var current_scene := get_tree().current_scene

	if current_scene != null:

		transition = current_scene.find_child(
			"transition",
			true,
			false
		)


	# =====================================================
	# PROCURA LABEL DO CONTADOR
	# =====================================================

	fragment_label = find_child(
		"Label",
		true,
		false
	) as Label


	# =====================================================
	# CASO NÃO ACHE "Label"
	# PROCURA QUALQUER LABEL
	# =====================================================

	if fragment_label == null:

		fragment_label = _find_first_label(
			self
		)


	# =====================================================
	# PROCURA LABEL DA MENSAGEM
	# =====================================================

	portal_message_label = find_child(
		"PortalMessage",
		true,
		false
	) as Label


	# =====================================================
	# CRIA LABEL AUTOMATICAMENTE
	# =====================================================

	if portal_message_label == null:

		portal_message_label = Label.new()

		portal_message_label.name = "PortalMessage"

		add_child(
			portal_message_label
		)


	# =====================================================
	# POSIÇÃO DA MENSAGEM
	# =====================================================

	portal_message_label.position = Vector2(
		-105,
		-38
	)

	portal_message_label.size = Vector2(
		210,
		22
	)


	# =====================================================
	# ALINHAMENTO
	# =====================================================

	portal_message_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	portal_message_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	# =====================================================
	# FILTRO PIXEL ART
	# =====================================================

	portal_message_label.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)


	# =====================================================
	# TAMANHO DA FONTE
	# =====================================================

	portal_message_label.add_theme_font_size_override(
		"font_size",
		6
	)


	# =====================================================
	# ANTIALIASING
	# =====================================================

	portal_message_label.add_theme_constant_override(
		"font_antialiasing",
		0
	)


	# =====================================================
	# COR
	# =====================================================

	portal_message_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			1.0,
			1.0,
			1.0
		)
	)


	# =====================================================
	# CONTORNO
	# =====================================================

	portal_message_label.add_theme_color_override(
		"font_outline_color",
		Color(
			0.02,
			0.03,
			0.05,
			1.0
		)
	)

	portal_message_label.add_theme_constant_override(
		"outline_size",
		2
	)


	# =====================================================
	# SOMBRA
	# =====================================================

	portal_message_label.add_theme_color_override(
		"font_shadow_color",
		Color(
			0.0,
			0.0,
			0.0,
			0.45
		)
	)

	portal_message_label.add_theme_constant_override(
		"shadow_offset_x",
		1
	)

	portal_message_label.add_theme_constant_override(
		"shadow_offset_y",
		1
	)


	# =====================================================
	# ESCONDE INICIALMENTE
	# =====================================================

	portal_message_label.visible = false


	# =====================================================
	# MONITORAMENTO
	# =====================================================

	monitoring = true

	monitorable = true


	# =====================================================
	# CONECTA ENTRADA DO PLAYER
	# =====================================================

	if not body_entered.is_connected(
		_on_body_entered
	):

		body_entered.connect(
			_on_body_entered
		)


	# =====================================================
	# CONECTA SAÍDA DO PLAYER
	# =====================================================

	if not body_exited.is_connected(
		_on_body_exited
	):

		body_exited.connect(
			_on_body_exited
		)


	# =====================================================
	# ATUALIZA CONTADOR
	# =====================================================

	_update_fragment_label()


# =========================================================
# PROCURA PRIMEIRO LABEL
# =========================================================

func _find_first_label(
	node: Node
) -> Label:

	for child in node.get_children():

		if child is Label:

			return child as Label


		var found := _find_first_label(
			child
		)


		if found != null:

			return found


	return null


# =========================================================
# PROCESS
# =========================================================

func _process(_delta: float) -> void:

	_update_fragment_label()


# =========================================================
# IDENTIFICA MUNDO ATUAL
# =========================================================

func get_current_world() -> int:

	var current_scene := get_tree().current_scene


	if current_scene == null:

		return 0


	var path := current_scene.scene_file_path


	# =====================================================
	# WORLD 00
	# =====================================================

	if path.to_lower().contains(
		"world_00"
	):

		return 0


	# =====================================================
	# WORLD 01
	# =====================================================

	if path.to_lower().contains(
		"world_01"
	):

		return 1


	# =====================================================
	# WORLD 02
	# =====================================================

	if path.to_lower().contains(
		"world_02"
	):

		return 2


	# =====================================================
	# WORLD 03
	# =====================================================

	if path.to_lower().contains(
		"world_03"
	):

		return 3


	# =====================================================
	# SEGURANÇA
	# =====================================================

	return 0


# =========================================================
# QUANTIDADE NECESSÁRIA
# =========================================================

func get_required_fragments() -> int:

	match get_current_world():

		0:
			return 0

		1:
			return 5

		2:
			return 3

		3:
			return 5


	return 0


# =========================================================
# PEGA FRAGMENTOS
# =========================================================

func get_fragment_count() -> int:

	match get_current_world():

		# =================================================
		# WORLD 01
		# RACIOCÍNIO
		# =================================================

		1:
			return Globals.raciocinio_fragments


		# =================================================
		# WORLD 02
		# ATENÇÃO
		# =================================================

		2:
			return Globals.atencao_fragments


		# =================================================
		# WORLD 03
		# MEMÓRIA
		# =================================================

		3:
			return Globals.memoria_fragments


	return 0


# =========================================================
# NOME DO FRAGMENTO
# =========================================================

func get_fragment_name() -> String:

	match get_current_world():

		1:
			return "Raciocínio"

		2:
			return "Atenção"

		3:
			return "Memória"


	return "Fragmentos"


# =========================================================
# ATUALIZA CONTADOR
# =========================================================

func _update_fragment_label() -> void:

	if fragment_label == null:

		return


	var required := get_required_fragments()


	# =====================================================
	# WORLD 00
	# =====================================================

	if required <= 0:

		fragment_label.text = ""

		return


	var current := get_fragment_count()


	current = clamp(
		current,
		0,
		required
	)


	# =====================================================
	# MOSTRA CONTADOR
	# =====================================================

	fragment_label.text = (
		str(current)
		+ "/"
		+ str(required)
	)


	# =====================================================
	# VISUAL
	# =====================================================

	fragment_label.visible = true

	fragment_label.modulate = Color.WHITE

	fragment_label.self_modulate = Color.WHITE


	fragment_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	fragment_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	fragment_label.add_theme_constant_override(
		"outline_size",
		2
	)


# =========================================================
# MOSTRA MENSAGEM
# =========================================================

func _show_portal_message(
	text: String
) -> void:

	if portal_message_label == null:

		return


	portal_message_label.text = text

	portal_message_label.visible = true


# =========================================================
# ESCONDE MENSAGEM
# =========================================================

func _hide_portal_message() -> void:

	if portal_message_label == null:

		return


	portal_message_label.text = ""

	portal_message_label.visible = false


# =========================================================
# PLAYER ENTROU
# =========================================================

func _on_body_entered(
	body: Node2D
) -> void:

	# =====================================================
	# SOMENTE PLAYER
	# =====================================================

	if not body.is_in_group(
		"player"
	):

		return


	# =====================================================
	# MARCA PLAYER PERTO
	# =====================================================

	player_near_portal = true


	# =====================================================
	# EVITA DUPLICAÇÃO
	# =====================================================

	if not can_change_scene:

		return


	# =====================================================
	# INFORMAÇÕES
	# =====================================================

	var world := get_current_world()

	var required := get_required_fragments()

	var current := get_fragment_count()


	# =====================================================
	# WORLD 00
	# =====================================================

	if world == 0:

		print(
			"=============================="
		)

		print(
			"MUNDO 00 CONCLUÍDO!"
		)

		print(
			"PORTAL LIBERADO!"
		)

		print(
			"=============================="
		)

		_hide_portal_message()


	# =====================================================
	# OUTROS MUNDOS
	# =====================================================

	else:

		# =================================================
		# PORTAL BLOQUEADO
		# =================================================

		if current < required:

			var missing := required - current


			print(
				"=============================="
			)

			print(
				"PORTAL BLOQUEADO!"
			)

			print(
				get_fragment_name(),
				": ",
				current,
				"/",
				required
			)

			print(
				"FALTAM: ",
				missing
			)

			print(
				"=============================="
			)


			# =============================================
			# MENSAGEM
			# =============================================

			if missing == 1:

				_show_portal_message(
					"Falta 1 fragmento de "
					+ get_fragment_name()
				)

			else:

				_show_portal_message(
					"Faltam "
					+ str(missing)
					+ " fragmentos de "
					+ get_fragment_name()
				)


			_update_fragment_label()

			return


		# =================================================
		# PORTAL LIBERADO
		# =================================================

		print(
			"=============================="
		)

		print(
			"PORTAL LIBERADO!"
		)

		print(
			get_fragment_name(),
			": ",
			current,
			"/",
			required
		)

		print(
			"=============================="
		)


		_show_portal_message(
			"Portal liberado!"
		)


	# =====================================================
	# VERIFICA PRÓXIMA FASE
	# =====================================================

	if next_level == "":

		print(
			"ERRO: PRÓXIMA FASE NÃO DEFINIDA!"
		)

		return


	# =====================================================
	# BLOQUEIA NOVAS ENTRADAS
	# =====================================================

	can_change_scene = false


	# =====================================================
	# RESET SCORE E MOEDAS
	# =====================================================

	Globals.score = 0

	Globals.coins = 0

	Globals.level_score = 0

	Globals.level_coins = 0


	# =====================================================
	# RESET FRAGMENTOS
	# =====================================================

	Globals.raciocinio_fragments = 0

	Globals.atencao_fragments = 0

	Globals.memoria_fragments = 0


	# =====================================================
	# TROCA DE FASE IMEDIATA
	# =====================================================

	if transition != null:

		if transition.has_method(
			"change_scene"
		):

			transition.change_scene(
				next_level
			)

			return


	# =====================================================
	# FALLBACK
	# =====================================================

	get_tree().change_scene_to_file(
		next_level
	)


# =========================================================
# PLAYER SAIU
# =========================================================

func _on_body_exited(
	body: Node2D
) -> void:

	# =====================================================
	# SOMENTE PLAYER
	# =====================================================

	if not body.is_in_group(
		"player"
	):

		return


	# =====================================================
	# PLAYER NÃO ESTÁ MAIS PERTO
	# =====================================================

	player_near_portal = false


	# =====================================================
	# ESCONDE MENSAGEM
	# =====================================================

	_hide_portal_message()
