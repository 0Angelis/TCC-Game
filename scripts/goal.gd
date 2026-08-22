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
# CONTROLE
# =========================================================

var can_change_scene := true


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
	# PROCURA O LABEL
	# =====================================================

	fragment_label = find_child(
		"Label",
		true,
		false
	) as Label


	# =====================================================
	# CASO NÃO ACHE "Label",
	# PROCURA QUALQUER LABEL DESCENDENTE
	# =====================================================

	if fragment_label == null:

		fragment_label = _find_first_label(
			self
		)


	# =====================================================
	# MONITORAMENTO
	# =====================================================

	monitoring = true

	monitorable = true


	# =====================================================
	# CONECTA PLAYER
	# =====================================================

	if not body_entered.is_connected(
		_on_body_entered
	):

		body_entered.connect(
			_on_body_entered
		)


	# =====================================================
	# ATUALIZA TEXTO
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


	var path := (
		current_scene.scene_file_path
	)


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
# PEGA FRAGMENTOS DA FASE
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
			return "RACIOCÍNIO"

		2:
			return "ATENÇÃO"

		3:
			return "MEMÓRIA"


	return "FRAGMENTOS"


# =========================================================
# ATUALIZA LABEL DO PORTAL
# =========================================================

func _update_fragment_label() -> void:

	if fragment_label == null:

		return


	# =====================================================
	# QUANTIDADE NECESSÁRIA
	# =====================================================

	var required := (
		get_required_fragments()
	)


	# =====================================================
	# WORLD 00
	# =====================================================
	# Não precisa mostrar contador.

	if required <= 0:

		fragment_label.text = ""

		return


	# =====================================================
	# QUANTIDADE ATUAL
	# =====================================================

	var current := (
		get_fragment_count()
	)


	# =====================================================
	# LIMITA
	# =====================================================

	current = clamp(
		current,
		0,
		required
	)


	# =====================================================
	# MOSTRA
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
		3
	)


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
	# EVITA DUPLICAÇÃO
	# =====================================================

	if not can_change_scene:

		return


	# =====================================================
	# MUNDO ATUAL
	# =====================================================

	var world := get_current_world()


	# =====================================================
	# NECESSÁRIOS
	# =====================================================

	var required := (
		get_required_fragments()
	)


	# =====================================================
	# ATUAIS
	# =====================================================

	var current := (
		get_fragment_count()
	)


	# =====================================================
	# MUNDO 00
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


	# =====================================================
	# OUTROS MUNDOS
	# =====================================================

	else:

		# =================================================
		# BLOQUEADO
		# =================================================

		if current < required:

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
				required - current
			)

			print(
				"=============================="
			)

			_update_fragment_label()

			return


		# =================================================
		# LIBERADO
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
	# TROCA DE FASE
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
