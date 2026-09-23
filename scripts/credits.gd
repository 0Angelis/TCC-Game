extends Control


# ============================================================
# CREDITOS FINAIS
# ============================================================
#
# CREDITOS:
# - Sobem continuamente.
# - ESC precisa ser SEGURADO.
# - Enquanto ESC esta segurado, aparece uma barra carregando.
# - Ao completar a barra, os creditos pulam e voltam ao menu.
#
# ============================================================


# ============================================================
# CONFIGURACAO
# ============================================================

const RETURN_MENU_SCENE: String = (
	"res://scenes/title_screen.tscn"
)

const FONT_PATH: String = (
	"res://assets/Fontes/Pixeloid_Font_1_0/"
	+
	"OpenType (.otf)/PixeloidSans-Bold.otf"
)

# Mais lento que antes.
const CREDITS_SPEED: float = 40.0

const SKIP_HOLD_TIME: float = 1.25

const END_WAIT_TIME: float = 1.5


# ============================================================
# CORES
# ============================================================

const BG_COLOR: Color = (
	Color("#08050D")
)

const TEXT_COLOR: Color = (
	Color("#F8F5FF")
)

const PURPLE: Color = (
	Color("#A85CFF")
)

const PURPLE_LIGHT: Color = (
	Color("#D6A8FF")
)

const DARK_BAR: Color = (
	Color("#241632")
)


# ============================================================
# NODES
# ============================================================

var clip_area: Control = null

var credits_content: Control = null

var skip_hint: Label = null

var skip_bar_background: ColorRect = null

var skip_bar_fill: ColorRect = null


# ============================================================
# ESTADO
# ============================================================

var scroll_finished: bool = false

var returning_to_menu: bool = false

var end_timer: float = 0.0

var esc_held: bool = false

var esc_hold_time: float = 0.0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_build_background()

	_build_credits()

	_build_skip_ui()

	await get_tree().process_frame

	var viewport_size := (
		get_viewport_rect().size
	)

	# ========================================================
	# COMECA BEM ABAIXO DA TELA
	# ========================================================
	#
	# O texto nao aparece no meio.
	# Ele entra pela parte de baixo.
	#
	credits_content.position = Vector2(
		0,
		viewport_size.y + 20.0
	)


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	if returning_to_menu:
		return


	if not event is InputEventKey:
		return


	var key_event := (
		event as InputEventKey
	)


	if (
		key_event.keycode == KEY_ESCAPE
		or
		key_event.physical_keycode == KEY_ESCAPE
	):

		if key_event.pressed:

			# Comecou a segurar ESC.
			esc_held = true

		else:

			# Soltou ESC antes de completar.
			esc_held = false

			esc_hold_time = 0.0

			_update_skip_bar()

		get_viewport().set_input_as_handled()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	if returning_to_menu:
		return


	_process_skip(delta)


	if scroll_finished:

		end_timer -= delta

		if end_timer <= 0.0:

			_return_to_menu()

		return


	# --------------------------------------------------------
	# SOBE OS CREDITOS
	# --------------------------------------------------------

	if credits_content != null:

		credits_content.position.y -= (
			CREDITS_SPEED * delta
		)


	# --------------------------------------------------------
	# VERIFICA FINAL
	# --------------------------------------------------------

	if credits_content == null:
		return

	var bottom_of_content: float = (
		credits_content.position.y
		+
		credits_content.size.y
	)


	if bottom_of_content <= 0.0:

		scroll_finished = true

		end_timer = (
			END_WAIT_TIME
		)


# ============================================================
# SEGURAR ESC
# ============================================================

func _process_skip(
	delta: float
) -> void:

	if not esc_held:

		return


	esc_hold_time += delta

	esc_hold_time = min(
		esc_hold_time,
		SKIP_HOLD_TIME
	)


	_update_skip_bar()


	if (
		esc_hold_time
		>=
		SKIP_HOLD_TIME
	):

		esc_held = false

		esc_hold_time = 0.0

		_update_skip_bar()

		_return_to_menu()


# ============================================================
# BARRA DE CARREGAMENTO
# ============================================================

func _update_skip_bar() -> void:

	if skip_hint == null:
		return

	if skip_bar_fill == null:
		return


	var progress: float = 0.0

	if SKIP_HOLD_TIME > 0.0:

		progress = (
			esc_hold_time
			/
			SKIP_HOLD_TIME
		)

	progress = clamp(
		progress,
		0.0,
		1.0
	)


	skip_hint.text = (
		"[ ESC ] PULAR"
	)


	# Barra menor.
	skip_bar_fill.size.x = (
		100.0 * progress
	)


	if progress > 0.0:

		skip_hint.modulate = Color(
			1.0,
			1.0,
			1.0,
			1.0
		)

	else:

		skip_hint.modulate = Color(
			0.85,
			0.80,
			0.90,
			1.0
		)


# ============================================================
# FUNDO
# ============================================================

func _build_background() -> void:

	var background := ColorRect.new()

	background.name = (
		"CreditsBackground"
	)

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.color = (
		BG_COLOR
	)

	background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		background
	)

	move_child(
		background,
		0
	)


	# Linha superior.
	var top_line := ColorRect.new()

	top_line.position = Vector2(
		0,
		0
	)

	top_line.size = Vector2(
		get_viewport_rect().size.x,
		4
	)

	top_line.color = PURPLE

	top_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		top_line
	)


	# Linha inferior.
	var bottom_line := ColorRect.new()

	bottom_line.position = Vector2(
		0,
		get_viewport_rect().size.y - 4
	)

	bottom_line.size = Vector2(
		get_viewport_rect().size.x,
		4
	)

	bottom_line.color = PURPLE

	bottom_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		bottom_line
	)


# ============================================================
# CREDITOS
# ============================================================

func _build_credits() -> void:

	clip_area = Control.new()

	clip_area.name = (
		"CreditsClipArea"
	)

	clip_area.position = Vector2(
		0,
		4
	)

	clip_area.size = Vector2(
		get_viewport_rect().size.x,
		get_viewport_rect().size.y - 8
	)

	clip_area.clip_contents = true

	clip_area.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		clip_area
	)


	# --------------------------------------------------------
	# CONTROLE SIMPLES.
	# NAO e Container.
	# Assim a posicao pode subir livremente.
	# --------------------------------------------------------

	credits_content = Control.new()

	credits_content.name = (
		"CreditsContent"
	)

	credits_content.position = Vector2(
		0,
		800
	)

	credits_content.size = Vector2(
		get_viewport_rect().size.x,
		1500
	)

	credits_content.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	clip_area.add_child(
		credits_content
	)


	# ========================================================
	# CREDITOS
	# ========================================================

	# Comeca mais perto da parte inferior.
	# Assim o primeiro titulo entra pela parte de baixo
	# sem aparecer no meio da tela.
	var y: float = 60.0

	y = _add_title(
		"MEMÓRIA ZERO",
		y
	)

	y += 35.0

	y = _add_text(
		"um jogo desenvolvido como Trabalho de Conclusão de Curso",
		y
	)

	y += 50.0

	y = _add_section(
		"DESENVOLVIMENTO",
		y
	)

	y += 10.0

	y = _add_text(
		"Felipe Nascimento De Angelis",
		y
	)

	y = _add_text(
		"Engenharia de Software - UEM",
		y
	)

	y += 40.0

	y = _add_section(
		"TECNOLOGIAS",
		y
	)

	y += 10.0

	y = _add_text(
		"Godot Engine",
		y
	)

	y = _add_text(
		"GDScript",
		y
	)

	y = _add_text(
		"Pixel Art",
		y
	)

	y += 40.0

	y = _add_section(
		"CONCEITO",
		y
	)

	y += 10.0

	y = _add_text(
		"Raciocínio • Atenção • Memória",
		y
	)

	y += 40.0

	y = _add_section(
		"AGRADECIMENTOS",
		y
	)

	y += 10.0

	y = _add_text(
		"Obrigado por jogar!",
		y
	)

	y = _add_text(
		"Espero que tenha gostado da jornada.",
		y
	)

	y += 70.0

	y = _add_title(
		"FIM",
		y
	)

	y += 20.0

	y = _add_text(
		"Finalmente... de volta para casa.",
		y
	)

	# Espaco depois do texto para garantir
	# que o fim demore um pouco para sair.
	y += 400.0

	credits_content.size.y = max(
		y,
		1500.0
	)


# ============================================================
# CRIAR LABEL
# ============================================================

func _make_label(
	text_value: String,
	font_size: int,
	color: Color
) -> Label:

	var label := Label.new()

	label.text = (
		text_value
	)

	label.position = Vector2(
		40.0,
		0.0
	)

	label.size = Vector2(
		get_viewport_rect().size.x - 80.0,
		48.0
	)

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	label.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		color
	)

	label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	label.add_theme_constant_override(
		"outline_size",
		3
	)

	var font_resource: Resource = (
		load(
			FONT_PATH
		)
	)

	if font_resource != null:

		label.add_theme_font_override(
			"font",
			font_resource
		)

	credits_content.add_child(
		label
	)

	return label


# ============================================================
# ADICIONAR TITULO / SECAO / TEXTO
# ============================================================

func _add_title(
	text_value: String,
	y: float
) -> float:

	var label := _make_label(
		text_value,
		34,
		PURPLE_LIGHT
	)

	label.position.y = y

	return y + label.size.y


func _add_section(
	text_value: String,
	y: float
) -> float:

	var label := _make_label(
		text_value,
		22,
		PURPLE
	)

	label.position.y = y

	return y + label.size.y


func _add_text(
	text_value: String,
	y: float
) -> float:

	var label := _make_label(
		text_value,
		17,
		TEXT_COLOR
	)

	label.position.y = y

	return y + label.size.y


# ============================================================
# UI DO SKIP
# ============================================================

func _build_skip_ui() -> void:

	skip_hint = Label.new()

	skip_hint.name = (
		"SkipHint"
	)

	skip_hint.text = (
		"[ SEGURE ESC ] PULAR"
	)

	skip_hint.position = Vector2(
		get_viewport_rect().size.x - 275.0,
		get_viewport_rect().size.y - 88.0
	)

	skip_hint.size = Vector2(
		240,
		28
	)

	skip_hint.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	skip_hint.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	skip_hint.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	skip_hint.z_index = 100

	skip_hint.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	skip_hint.add_theme_font_size_override(
		"font_size",
		11
	)

	skip_hint.add_theme_color_override(
		"font_color",
		TEXT_COLOR
	)

	skip_hint.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)

	skip_hint.add_theme_constant_override(
		"outline_size",
		3
	)

	var font_resource: Resource = (
		load(
			FONT_PATH
		)
	)

	if font_resource != null:

		skip_hint.add_theme_font_override(
			"font",
			font_resource
		)

	add_child(
		skip_hint
	)


	# --------------------------------------------------------
	# FUNDO DA BARRA
	# --------------------------------------------------------

	skip_bar_background = ColorRect.new()

	skip_bar_background.name = (
		"SkipBarBackground"
	)

	# Centralizada embaixo do texto.
	skip_bar_background.position = Vector2(
		get_viewport_rect().size.x - 133.0,
		get_viewport_rect().size.y - 55.0
	)

	# Metade do tamanho anterior.
	skip_bar_background.size = Vector2(
		100,
		6
	)

	skip_bar_background.color = (
		DARK_BAR
	)

	skip_bar_background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	skip_bar_background.z_index = 100

	add_child(
		skip_bar_background
	)


	# --------------------------------------------------------
	# PREENCHIMENTO DA BARRA
	# --------------------------------------------------------

	skip_bar_fill = ColorRect.new()

	skip_bar_fill.name = (
		"SkipBarFill"
	)

	skip_bar_fill.position = (
		skip_bar_background.position
	)

	skip_bar_fill.size = Vector2(
		0,
		6
	)

	skip_bar_fill.color = (
		PURPLE
	)

	skip_bar_fill.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	skip_bar_fill.z_index = 101

	add_child(
		skip_bar_fill
	)


	_update_skip_bar()


# ============================================================
# VOLTAR PARA O MENU
# ============================================================

func _return_to_menu() -> void:

	if returning_to_menu:
		return

	returning_to_menu = true

	esc_held = false

	esc_hold_time = 0.0

	if skip_hint != null:
		skip_hint.hide()

	if skip_bar_background != null:
		skip_bar_background.hide()

	if skip_bar_fill != null:
		skip_bar_fill.hide()

	get_tree().paused = false

	print(
		"CREDITOS: VOLTANDO PARA O MENU"
	)

	await get_tree().process_frame

	get_tree().change_scene_to_file(
		RETURN_MENU_SCENE
	)
