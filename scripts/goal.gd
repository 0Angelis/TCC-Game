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

var player_near_portal := false

var result_screen_open := false


# =========================================================
# TELA DE RESULTADO
# =========================================================

var result_layer: CanvasLayer = null

var result_overlay: Control = null

var result_panel: Panel = null

var result_title: Label = null

var result_player_label: Label = null

var result_coins_label: Label = null

var result_score_label: Label = null

var result_fragment_label: Label = null

var result_button: Button = null

var top_line: ColorRect = null

var bottom_line: ColorRect = null

var left_decor: Label = null

var right_decor: Label = null


# =========================================================
# FONTE DO HUD
# =========================================================

var game_font: Font = null

var game_theme: Theme = null


# =========================================================
# CORES RETRÔ
# =========================================================

const RETRO_PANEL := Color("#1B1030")

const RETRO_PURPLE := Color("#8E4DCE")

const RETRO_PURPLE_LIGHT := Color("#C88BFF")

const RETRO_MAGENTA := Color("#E35BFF")

const RETRO_WHITE := Color("#F7F1FF")

const RETRO_CYAN := Color("#7BE7FF")

const RETRO_GOLD := Color("#F5D56A")

const RETRO_BLACK := Color("#0A0610")


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS


	# =====================================================
	# PEGA A FONTE/THEME DA HUD
	# =====================================================

	_get_hud_font_and_theme()


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


	if fragment_label == null:

		fragment_label = _find_first_label(
			self
		)


	# =====================================================
	# PROCURA MENSAGEM
	# =====================================================

	portal_message_label = find_child(
		"PortalMessage",
		true,
		false
	) as Label


	# =====================================================
	# CRIA MENSAGEM
	# =====================================================

	if portal_message_label == null:

		portal_message_label = Label.new()

		portal_message_label.name = "PortalMessage"

		add_child(
			portal_message_label
		)


	# =====================================================
	# POSIÇÃO
	# =====================================================

	portal_message_label.position = Vector2(
		-120,
		-42
	)


	portal_message_label.size = Vector2(
		240,
		28
	)


	portal_message_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	portal_message_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	# =====================================================
	# PIXEL ART
	# =====================================================

	portal_message_label.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)


	portal_message_label.add_theme_font_size_override(
		"font_size",
		8
	)


	portal_message_label.add_theme_constant_override(
		"font_antialiasing",
		0
	)


	portal_message_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)


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
		1
	)


	portal_message_label.add_theme_color_override(
		"font_shadow_color",
		Color(
			0,
			0,
			0,
			0
		)
	)


	portal_message_label.add_theme_constant_override(
		"shadow_offset_x",
		0
	)


	portal_message_label.add_theme_constant_override(
		"shadow_offset_y",
		0
	)


	portal_message_label.clip_text = false

	portal_message_label.visible = false


	# =====================================================
	# MONITORAMENTO
	# =====================================================

	monitoring = true

	monitorable = true


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


	# =====================================================
	# CONTADOR
	# =====================================================

	_update_fragment_label()


# =========================================================
# PEGA FONTE DA HUD
# =========================================================

func _get_hud_font_and_theme() -> void:

	var current_scene := get_tree().current_scene


	if current_scene == null:

		return


	# =====================================================
	# PROCURA COINS_COUNTER
	# =====================================================

	var hud_label := current_scene.find_child(
		"coins_counter",
		true,
		false
	) as Label


	if hud_label == null:

		print(
			"AVISO: coins_counter não encontrado."
		)

		return


	# =====================================================
	# PEGA FONTE RESOLVIDA DA HUD
	# =====================================================

	game_font = hud_label.get_theme_font(
		"font"
	)


	# =====================================================
	# PEGA THEME RESOLVIDO
	# =====================================================

	game_theme = hud_label.get_theme()


	# =====================================================
	# DEBUG
	# =====================================================

	if game_font != null:

		print(
			"FONTE DA HUD ENCONTRADA!"
		)

	else:

		print(
			"AVISO: fonte da HUD não encontrada."
		)

	if game_theme != null:

		print(
			"THEME DA HUD ENCONTRADO!"
		)

	else:

		print(
			"AVISO: theme da HUD não encontrado."
		)


# =========================================================
# APLICA FONTE RETRÔ
# =========================================================

func _apply_game_font(
	control: Control
) -> void:

	if control == null:

		return


	# =====================================================
	# APLICA THEME
	# =====================================================

	if game_theme != null:

		control.theme = game_theme


	# =====================================================
	# APLICA FONTE DIRETAMENTE
	# =====================================================

	if game_font != null:

		control.add_theme_font_override(
			"font",
			game_font
		)


	# =====================================================
	# PIXEL ART
	# =====================================================

	control.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)


# =========================================================
# PROCURA LABEL
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

	if result_screen_open:

		return


	_update_fragment_label()


# =========================================================
# IDENTIFICA MUNDO
# =========================================================

func get_current_world() -> int:

	var current_scene := get_tree().current_scene


	if current_scene == null:

		return 0


	var path := (
		current_scene.scene_file_path.to_lower()
	)


	if path.contains(
		"world_00"
	):

		return 0


	if path.contains(
		"world_01"
	):

		return 1


	if path.contains(
		"world_02"
	):

		return 2


	if path.contains(
		"world_03"
	):

		return 3


	return 0


# =========================================================
# FRAGMENTOS NECESSÁRIOS
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
# FRAGMENTOS ATUAIS
# =========================================================

func get_fragment_count() -> int:

	match get_current_world():

		1:

			return Globals.raciocinio_fragments


		2:

			return Globals.atencao_fragments


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


	var required := (
		get_required_fragments()
	)


	if required <= 0:

		fragment_label.text = ""

		return


	var current := (
		get_fragment_count()
	)


	current = clamp(
		current,
		0,
		required
	)


	fragment_label.text = (
		str(current)
		+ "/"
		+ str(required)
	)


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


	portal_message_label.modulate = Color.WHITE

	portal_message_label.self_modulate = Color.WHITE


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

	if not body.is_in_group(
		"player"
	):

		return


	if result_screen_open:

		return


	player_near_portal = true


	if not can_change_scene:

		return


	var world := (
		get_current_world()
	)


	var required := (
		get_required_fragments()
	)


	var current := (
		get_fragment_count()
	)


	# =====================================================
	# WORLD 00
	# =====================================================

	if world == 0:

		_hide_portal_message()


	# =====================================================
	# OUTROS MUNDOS
	# =====================================================

	else:

		if current < required:

			var missing := (
				required - current
			)


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


		_show_portal_message(
			"PORTAL LIBERADO!"
		)


	# =====================================================
	# PRÓXIMA FASE
	# =====================================================

	if next_level == "":

		print(
			"ERRO: PRÓXIMA FASE NÃO DEFINIDA!"
		)

		return


	# =====================================================
	# BLOQUEIA DUPLA ENTRADA
	# =====================================================

	can_change_scene = false


	# =====================================================
	# RESULTADO
	# =====================================================

	_show_result_screen()


# =========================================================
# MOSTRA TELA DE RESULTADO
# =========================================================

func _show_result_screen() -> void:

	if result_screen_open:

		return


	result_screen_open = true


	# =====================================================
	# PAUSA
	# =====================================================

	get_tree().paused = true


	# =====================================================
	# CANVAS LAYER
	# =====================================================

	result_layer = CanvasLayer.new()

	result_layer.name = (
		"RetroLevelResult"
	)

	result_layer.layer = 200

	result_layer.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	get_tree().root.add_child(
		result_layer
	)


	# =====================================================
	# OVERLAY
	# =====================================================

	result_overlay = Control.new()

	result_overlay.name = (
		"ResultOverlay"
	)

	result_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	result_overlay.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	result_overlay.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	result_layer.add_child(
		result_overlay
	)


	# =====================================================
	# ESCURECIMENTO
	# =====================================================

	var dark := ColorRect.new()

	dark.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	dark.color = Color(
		0.035,
		0.015,
		0.07,
		0.64
	)

	dark.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	result_overlay.add_child(
		dark
	)


	# =====================================================
	# PAINEL
	# =====================================================

	result_panel = Panel.new()

	result_panel.name = (
		"RetroPanel"
	)


	result_panel.anchor_left = 0.5

	result_panel.anchor_top = 0.5

	result_panel.anchor_right = 0.5

	result_panel.anchor_bottom = 0.5


	result_panel.offset_left = -330

	result_panel.offset_top = -190

	result_panel.offset_right = 330

	result_panel.offset_bottom = 190


	result_panel.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	result_panel.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)


	# =====================================================
	# THEME DA HUD
	# =====================================================

	_apply_game_font(
		result_panel
	)


	# =====================================================
	# ESTILO
	# =====================================================

	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = (
		RETRO_PANEL
	)

	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3

	panel_style.border_color = (
		RETRO_PURPLE
	)

	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12

	panel_style.shadow_color = Color(
		0.35,
		0.05,
		0.55,
		0.65
	)

	panel_style.shadow_size = 12

	panel_style.shadow_offset = Vector2(
		0,
		4
	)


	result_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)


	result_overlay.add_child(
		result_panel
	)


	# =====================================================
	# LINHA SUPERIOR
	# =====================================================

	top_line = ColorRect.new()

	top_line.position = Vector2(
		28,
		18
	)

	top_line.size = Vector2(
		604,
		2
	)

	top_line.color = (
		RETRO_MAGENTA
	)

	top_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	result_panel.add_child(
		top_line
	)


	# =====================================================
	# LINHA INFERIOR
	# =====================================================

	bottom_line = ColorRect.new()

	bottom_line.position = Vector2(
		28,
		315
	)

	bottom_line.size = Vector2(
		604,
		2
	)

	bottom_line.color = (
		RETRO_PURPLE
	)

	bottom_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	result_panel.add_child(
		bottom_line
	)


	# =====================================================
	# DECORAÇÃO ESQUERDA
	# =====================================================

	left_decor = Label.new()

	left_decor.text = (
		"◆  ◆  ◆"
	)

	left_decor.position = Vector2(
		35,
		40
	)

	left_decor.size = Vector2(
		110,
		25
	)

	left_decor.add_theme_font_size_override(
		"font_size",
		11
	)

	left_decor.add_theme_color_override(
		"font_color",
		RETRO_PURPLE_LIGHT
	)

	left_decor.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	left_decor.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_game_font(
		left_decor
	)


	result_panel.add_child(
		left_decor
	)


	# =====================================================
	# DECORAÇÃO DIREITA
	# =====================================================

	right_decor = Label.new()

	right_decor.text = (
		"◆  ◆  ◆"
	)

	right_decor.position = Vector2(
		520,
		40
	)

	right_decor.size = Vector2(
		100,
		25
	)

	right_decor.add_theme_font_size_override(
		"font_size",
		11
	)

	right_decor.add_theme_color_override(
		"font_color",
		RETRO_PURPLE_LIGHT
	)

	right_decor.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	right_decor.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_game_font(
		right_decor
	)


	result_panel.add_child(
		right_decor
	)


	# =====================================================
	# TÍTULO
	# =====================================================

	result_title = Label.new()

	result_title.text = (
		"✦  FASE CONCLUÍDA!  ✦"
	)

	result_title.position = Vector2(
		80,
		55
	)

	result_title.size = Vector2(
		500,
		55
	)

	result_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	result_title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	result_title.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	result_title.add_theme_font_size_override(
		"font_size",
		30
	)

	result_title.add_theme_color_override(
		"font_color",
		RETRO_WHITE
	)

	result_title.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	result_title.add_theme_constant_override(
		"outline_size",
		5
	)


	_apply_game_font(
		result_title
	)


	result_panel.add_child(
		result_title
	)


	# =====================================================
	# PLAYER
	# =====================================================

	result_player_label = Label.new()

	result_player_label.text = (
		"PLAYER 1"
	)

	result_player_label.position = Vector2(
		80,
		100
	)

	result_player_label.size = Vector2(
		500,
		28
	)

	result_player_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	result_player_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	result_player_label.add_theme_font_size_override(
		"font_size",
		14
	)

	result_player_label.add_theme_color_override(
		"font_color",
		RETRO_CYAN
	)

	result_player_label.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	result_player_label.add_theme_constant_override(
		"outline_size",
		3
	)

	result_player_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_game_font(
		result_player_label
	)


	result_panel.add_child(
		result_player_label
	)


	# =====================================================
	# MOEDAS
	# =====================================================

	result_coins_label = Label.new()

	result_coins_label.text = (
		"MOEDAS      %03d"
		% Globals.coins
	)

	result_coins_label.position = Vector2(
		80,
		145
	)

	result_coins_label.size = Vector2(
		500,
		42
	)

	result_coins_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	result_coins_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	result_coins_label.add_theme_font_size_override(
		"font_size",
		23
	)

	result_coins_label.add_theme_color_override(
		"font_color",
		RETRO_GOLD
	)

	result_coins_label.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	result_coins_label.add_theme_constant_override(
		"outline_size",
		4
	)

	result_coins_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_game_font(
		result_coins_label
	)


	result_panel.add_child(
		result_coins_label
	)


	# =====================================================
	# SCORE
	# =====================================================

	result_score_label = Label.new()

	result_score_label.text = (
		"SCORE       %06d"
		% Globals.score
	)

	result_score_label.position = Vector2(
		80,
		190
	)

	result_score_label.size = Vector2(
		500,
		42
	)

	result_score_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	result_score_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	result_score_label.add_theme_font_size_override(
		"font_size",
		23
	)

	result_score_label.add_theme_color_override(
		"font_color",
		RETRO_WHITE
	)

	result_score_label.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	result_score_label.add_theme_constant_override(
		"outline_size",
		4
	)

	result_score_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_apply_game_font(
		result_score_label
	)


	result_panel.add_child(
		result_score_label
	)


	# =====================================================
	# FRAGMENTO
	# =====================================================

	if get_current_world() != 0:

		result_fragment_label = Label.new()

		result_fragment_label.text = (
			get_fragment_name().to_upper()
			+ "      "
			+ str(get_fragment_count())
			+ "/"
			+ str(get_required_fragments())
		)

		result_fragment_label.position = Vector2(
			80,
			235
		)

		result_fragment_label.size = Vector2(
			500,
			34
		)

		result_fragment_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		result_fragment_label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		result_fragment_label.add_theme_font_size_override(
			"font_size",
			15
		)

		result_fragment_label.add_theme_color_override(
			"font_color",
			RETRO_PURPLE_LIGHT
		)

		result_fragment_label.add_theme_color_override(
			"font_outline_color",
			RETRO_BLACK
		)

		result_fragment_label.add_theme_constant_override(
			"outline_size",
			3
		)

		result_fragment_label.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)


		_apply_game_font(
			result_fragment_label
		)


		result_panel.add_child(
			result_fragment_label
		)


	# =====================================================
	# BOTÃO
	# =====================================================

	result_button = Button.new()

	result_button.text = (
		"↵   CONTINUAR"
	)

	result_button.position = Vector2(
		175,
		280
	)

	result_button.size = Vector2(
		310,
		48
	)

	result_button.custom_minimum_size = Vector2(
		310,
		48
	)

	result_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	# =====================================================
	# NÃO DEIXA O SPACE ATIVAR O BOTÃO
	# =====================================================
	result_button.focus_mode = (
		Control.FOCUS_NONE
	)

	result_button.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	result_button.add_theme_font_size_override(
		"font_size",
		17
	)

	result_button.add_theme_color_override(
		"font_color",
		RETRO_WHITE
	)

	result_button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	result_button.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)

	result_button.add_theme_color_override(
		"font_focus_color",
		Color.WHITE
	)

	result_button.add_theme_color_override(
		"font_outline_color",
		RETRO_BLACK
	)

	result_button.add_theme_constant_override(
		"outline_size",
		2
	)


	_apply_game_font(
		result_button
	)


	_style_result_button(
		result_button
	)


	result_button.pressed.connect(
		_close_result_screen
	)


	result_panel.add_child(
		result_button
	)


	# =====================================================
	# FOCO
	# =====================================================

	result_button.grab_focus()


	# =====================================================
	# ANIMAÇÃO
	# =====================================================

	result_panel.modulate = Color(
		1,
		1,
		1,
		0
	)

	result_panel.scale = Vector2(
		0.96,
		0.96
	)


	var tween := create_tween()

	tween.set_parallel(true)


	tween.tween_property(
		result_panel,
		"modulate",
		Color.WHITE,
		0.18
	)


	tween.tween_property(
		result_panel,
		"scale",
		Vector2(
			1.0,
			1.0
		),
		0.20
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


# =========================================================
# ESTILO BOTÃO
# =========================================================

func _style_result_button(
	button: Button
) -> void:

	var normal := StyleBoxFlat.new()


	normal.bg_color = Color(
		"#33204D"
	)

	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2

	normal.border_color = (
		RETRO_PURPLE_LIGHT
	)

	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_left = 5
	normal.corner_radius_bottom_right = 5

	normal.shadow_color = Color(
		0.40,
		0.08,
		0.65,
		0.65
	)

	normal.shadow_size = 5

	normal.shadow_offset = Vector2(
		0,
		3
	)


	var hover := normal.duplicate()

	hover.bg_color = Color(
		"#4D2D70"
	)

	hover.border_color = (
		RETRO_MAGENTA
	)

	hover.shadow_color = Color(
		0.70,
		0.15,
		0.85,
		0.75
	)

	hover.shadow_size = 7


	var pressed := normal.duplicate()

	pressed.bg_color = Color(
		"#241334"
	)

	pressed.border_color = (
		RETRO_PURPLE
	)

	pressed.shadow_size = 2

	pressed.shadow_offset = Vector2(
		0,
		1
	)


	var focus := normal.duplicate()

	focus.bg_color = Color(
		"#45275F"
	)

	focus.border_color = (
		RETRO_CYAN
	)

	focus.shadow_color = Color(
		0.25,
		0.80,
		1.0,
		0.45
	)

	focus.shadow_size = 6


	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"focus",
		focus
	)


# =========================================================
# ENTER
# =========================================================

func _input(
	event: InputEvent
) -> void:

	# =====================================================
	# SÓ FUNCIONA NA TELA DE RESULTADO
	# =====================================================

	if not result_screen_open:

		return


	# =====================================================
	# SPACE NÃO FAZ NADA
	# =====================================================

	if event is InputEventKey:

		if not event.pressed:

			return


		if event.echo:

			return


		if event.keycode == KEY_SPACE:

			var viewport_space := get_viewport()

			if viewport_space != null:

				viewport_space.set_input_as_handled()

			return


		# =================================================
		# ENTER NORMAL OU ENTER DO TECLADO NUMÉRICO
		# =================================================

		if (
			event.keycode == KEY_ENTER
			or event.keycode == KEY_KP_ENTER
		):

			# =============================================
			# TELEPORTA / TROCA DE FASE IMEDIATAMENTE
			# =============================================

			_close_result_screen()


			get_viewport().set_input_as_handled()


# =========================================================
# FECHA RESULTADO
# =========================================================

func _close_result_screen() -> void:

	if not result_screen_open:

		return


	result_screen_open = false


	# =====================================================
	# REMOVE TELA
	# =====================================================

	if result_layer != null:

		result_layer.queue_free()

		result_layer = null


	result_overlay = null

	result_panel = null


	# =====================================================
	# DESPAUSA
	# =====================================================

	get_tree().paused = false


	# =====================================================
	# SALVA O TOTAL DE MOEDAS PARA O PRÓXIMO MAPA
	# =====================================================

	# O total fica acumulado entre os mapas.
	# Esse valor será usado pelo RESTART do PAUSE
	# para voltar ao saldo que existia antes do mapa atual.

	Globals.coins_before_level = Globals.coins

	# =====================================================
	# RESET SCORE / DADOS DA FASE
	# =====================================================

	Globals.score = 0

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


	player_near_portal = false


	_hide_portal_message()
