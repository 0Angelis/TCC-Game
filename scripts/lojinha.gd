extends Area2D


# =========================================================
# CONFIGURAÇÃO
# =========================================================

const PRECO_VIDA: int = 10

# Distância máxima para interagir com a loja.
const DISTANCIA_MAXIMA: float = 100.0

# Caixa do diálogo mais baixa
const OFFSET_DIALOGO: Vector2 = Vector2(0.0, 90.0)

# Aviso pequeno acima da barraca
const OFFSET_AVISO: Vector2 = Vector2(-45.0, -58.0)


# =========================================================
# ESTADOS
# =========================================================

enum EstadoLoja {
	ESPERANDO,
	CONVERSA,
	MENU
}


var estado: EstadoLoja = EstadoLoja.ESPERANDO


# =========================================================
# PLAYER
# =========================================================

var player: Node2D = null
var jogador_na_area: bool = false


# =========================================================
# CONTROLE
# =========================================================

var bloqueado: bool = false
var esperando_soltar_e: bool = false
var player_bloqueado_loja: bool = false
var player_physics_was_enabled: bool = true


# =========================================================
# AVISO
# =========================================================

var aviso: Label = null


# =========================================================
# INTERFACE DA LOJA
# =========================================================

var canvas: CanvasLayer = null
var tela: Control = null
var painel: Panel = null

var titulo: Label = null
var subtitulo: Label = null
var icone_vida: TextureRect = null
var nome_item: Label = null
var preco: Label = null
var moedas: Label = null
var vidas: Label = null
var resultado: Label = null

var voltar: Button = null
var comprar: Button = null

# =========================================================
# SELEÇÃO
#
# 0 = VOLTAR
# 1 = COMPRAR
#
# Nenhum botão começa selecionado.
# =========================================================

var selecao: int = -1


# =========================================================
# FONTE
# =========================================================

var fonte_retro = preload(
	"res://assets/Fontes/Pixeloid_Font_1_0/OpenType (.otf)/PixeloidSans-Bold.otf"
)


# =========================================================
# ÍCONE
# =========================================================

var textura_vida = preload(
	"res://assets/Mini FX, Items & UI/Common Pick-ups/Health_Kit (16 x 16).png"
)


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# =====================================================
	# AREA2D
	# =====================================================

	monitoring = true
	monitorable = true


	# =====================================================
	# PLAYER
	# =====================================================

	player = get_node_or_null("../player") as Node2D


	# =====================================================
	# SINAIS
	# =====================================================

	if not body_entered.is_connected(_on_body_entered):

		body_entered.connect(_on_body_entered)


	if not body_exited.is_connected(_on_body_exited):

		body_exited.connect(_on_body_exited)


	# =====================================================
	# AVISO
	# =====================================================

	criar_aviso()


	print("========================================")
	print("LOJA INICIADA")
	print("NODE: ", name)
	print("PLAYER: ", player)
	print("========================================")


# =========================================================
# PLAYER ENTROU
# =========================================================

func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):

		return


	player = body

	jogador_na_area = true


	if estado == EstadoLoja.ESPERANDO:

		aviso.text = "[E] FALAR"

		aviso.show()


	print("========================================")
	print("LOJA: PLAYER ENTROU")
	print("PLAYER: ", body.name)
	print("========================================")


# =========================================================
# PLAYER SAIU
# =========================================================

func _on_body_exited(body: Node2D) -> void:

	if body != player:

		return


	jogador_na_area = false

	aviso.hide()


	print("LOJA: PLAYER SAIU")


# =========================================================
# VERIFICAR DISTÂNCIA DO PLAYER
# =========================================================

func jogador_esta_perto() -> bool:
	if player == null or not is_instance_valid(player):
		return false

	var ponto_loja: Vector2 = global_position

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		ponto_loja = collision.global_position

	return player.global_position.distance_to(ponto_loja) <= DISTANCIA_MAXIMA


# =========================================================
# PROCESS
# =========================================================

func _process(_delta: float) -> void:

	# =====================================================
	# ESPERAR SOLTAR E
	# =====================================================

	if esperando_soltar_e:

		if not Input.is_action_pressed("interact"):

			esperando_soltar_e = false


			if jogador_na_area:

				abrir_menu()


			else:

				estado = EstadoLoja.ESPERANDO


		return


	# =====================================================
	# DURANTE DIÁLOGO
	# =====================================================

	if DialogManager.is_message_active:

		aviso.hide()

		return


	# =====================================================
	# MENU ABERTO
	# =====================================================

	if estado == EstadoLoja.MENU:

		atualizar_dados()

		return


	# =====================================================
	# PLAYER FORA
	# =====================================================

	if not jogador_na_area:

		aviso.hide()

		return


	# =====================================================
	# ESTADO NORMAL
	# =====================================================

	if estado == EstadoLoja.ESPERANDO:

		aviso.show()


# =========================================================
# INPUT
# =========================================================

func _input(event: InputEvent) -> void:

	# =====================================================
	# MENU
	# O menu continua recebendo input mesmo depois da conversa.
	# =====================================================
	if estado == EstadoLoja.MENU:
		processar_menu(event)
		return


	# =====================================================
	# PLAYER PRECISA ESTAR DENTRO PARA ABRIR CONVERSA
	# =====================================================
	if not jogador_na_area:
		return

	if not jogador_esta_perto():
		aviso.hide()
		return


	# =====================================================
	# DIÁLOGO
	# =====================================================

	if DialogManager.is_message_active:

		return


	# =====================================================
	# AGUARDANDO SOLTAR E
	# =====================================================

	if esperando_soltar_e:

		return


	# =====================================================
	# ABRIR CONVERSA
	# =====================================================

	if estado == EstadoLoja.ESPERANDO:

		if event.is_action_pressed("interact"):

			get_viewport().set_input_as_handled()

			abrir_conversa()


# =========================================================
# CONVERSA
# =========================================================

func abrir_conversa() -> void:

	if not jogador_esta_perto():
		return

	if bloqueado:
		return


	if DialogManager.is_message_active:
		return


	bloqueado = true
	estado = EstadoLoja.CONVERSA
	aviso.hide()


	# =====================================================
	# FALAS
	# =====================================================

	var falas: Array[String] = [
		"Bem-vindo!",
		"Essa e a Loja da Vida.",
		"Aqui voce pode comprar uma vida extra por 10 moedas."
	]


	# =====================================================
	# POSIÇÃO
	# =====================================================

	var posicao: Vector2 = (
		$CollisionShape2D.global_position
		+ OFFSET_DIALOGO
	)


	# =====================================================
	# ABRIR DIALOG MANAGER
	# =====================================================

	DialogManager.start_message(
		posicao,
		falas,
		self
	)

	print("LOJA: CONVERSA ABERTA")


	# =====================================================
	# ESPERAR A ÚLTIMA FALA SER FECHADA
	# =====================================================

	while DialogManager.is_message_active:
		await get_tree().process_frame

	if not is_inside_tree():
		return


	# =====================================================
	# ESPERAR O JOGADOR SOLTAR E
	#
	# Evita que o mesmo E usado para fechar a conversa
	# seja interpretado como uma compra imediatamente.
	# =====================================================

	while Input.is_action_pressed("interact"):
		await get_tree().process_frame


	# =====================================================
	# ABRIR MENU AUTOMATICAMENTE
	# =====================================================

	if jogador_esta_perto():
		abrir_menu()
	else:
		estado = EstadoLoja.ESPERANDO
		bloqueado = false
		aviso.hide()


# =========================================================
# CRIAR AVISO
# =========================================================

func criar_aviso() -> void:

	aviso = Label.new()

	aviso.text = "[E] FALAR"


	aviso.position = (
		$CollisionShape2D.position
		+ OFFSET_AVISO
	)


	aviso.size = Vector2(
		90.0,
		18.0
	)


	aviso.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	aviso.add_theme_font_override(
		"font",
		fonte_retro
	)


	aviso.add_theme_font_size_override(
		"font_size",
		6
	)


	aviso.add_theme_color_override(
		"font_color",
		Color("#FFF0C7")
	)


	aviso.add_theme_color_override(
		"font_outline_color",
		Color("#21172A")
	)


	aviso.add_theme_constant_override(
		"outline_size",
		2
	)


	aviso.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)


	aviso.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	aviso.hide()


	add_child(aviso)


# =========================================================
# ABRIR MENU
# =========================================================

func abrir_menu() -> void:

	if tela == null:

		criar_menu()


	# Depois da conversa, o menu abre automaticamente.
	estado = EstadoLoja.MENU

	# Congela o pinguim completamente enquanto a tela da loja
	# estiver aberta: sem movimento e sem animação.
	bloquear_player_para_loja()

	selecao = -1

	if voltar != null:
		remover_destaque_botao(voltar)
	if comprar != null:
		remover_destaque_botao(comprar)

	bloqueado = false

	resultado.hide()

	atualizar_menu()

	tela.show()

	aviso.hide()


	print("========================================")
	print("LOJA: MENU ABERTO")
	print("========================================")


	# =====================================================
	# ANIMAÇÃO
	# =====================================================

	painel.pivot_offset = (
		painel.size / 2.0
	)


	painel.scale = Vector2(
		0.94,
		0.94
	)


	var tween := create_tween()


	tween.tween_property(
		painel,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


# =========================================================
# CRIAR MENU
# =========================================================

func criar_menu() -> void:

	# =====================================================
	# CANVAS
	# =====================================================

	canvas = CanvasLayer.new()

	canvas.name = "LojaCanvas"

	canvas.layer = 200

	canvas.process_mode = (
		Node.PROCESS_MODE_PAUSABLE
	)

	# O Canvas da loja fica dentro da cena atual.
	# Assim, quando o jogador reiniciar a fase ou voltar ao menu,
	# a cena antiga é destruída junto com a tela da loja.
	var cena_atual := get_tree().current_scene

	if cena_atual != null:
		cena_atual.add_child(canvas)
	else:
		get_tree().root.add_child(canvas)


	# =====================================================
	# TELA
	# =====================================================

	tela = Control.new()

	tela.name = "TelaLoja"

	tela.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	tela.process_mode = (
		Node.PROCESS_MODE_PAUSABLE
	)

	tela.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	canvas.add_child(tela)


	# =====================================================
	# FUNDO
	# =====================================================

	var escurecer := ColorRect.new()

	escurecer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	escurecer.color = Color(
		0.02,
		0.015,
		0.04,
		0.65
	)

	escurecer.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	tela.add_child(escurecer)


	# =====================================================
	# PAINEL
	# =====================================================

	painel = Panel.new()

	painel.anchor_left = 0.5
	painel.anchor_top = 0.5
	painel.anchor_right = 0.5
	painel.anchor_bottom = 0.5

	painel.offset_left = -300.0
	painel.offset_top = -190.0
	painel.offset_right = 300.0
	painel.offset_bottom = 190.0


	# =====================================================
	# ESTILO
	# =====================================================

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = Color("#17111F")

	estilo.border_color = Color("#955ECC")

	estilo.set_border_width_all(3)

	estilo.corner_radius_top_left = 10
	estilo.corner_radius_top_right = 10
	estilo.corner_radius_bottom_left = 10
	estilo.corner_radius_bottom_right = 10

	estilo.shadow_color = Color(
		0.30,
		0.04,
		0.45,
		0.75
	)

	estilo.shadow_size = 12

	estilo.shadow_offset = Vector2(
		0.0,
		5.0
	)


	painel.add_theme_stylebox_override(
		"panel",
		estilo
	)


	tela.add_child(painel)


	# =====================================================
	# LINHA TOPO
	# =====================================================

	var linha := ColorRect.new()

	linha.position = Vector2(
		28.0,
		18.0
	)

	linha.size = Vector2(
		544.0,
		2.0
	)

	linha.color = Color("#DF63FF")

	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE

	painel.add_child(linha)


	# =====================================================
	# TÍTULO
	# =====================================================

	titulo = criar_label(
		"LOJA DA VIDA",
		17,
		Color("#F5D56A")
	)

	titulo.position = Vector2(
		0.0,
		28.0
	)

	titulo.size = Vector2(
		600.0,
		30.0
	)

	titulo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	painel.add_child(titulo)


	# =====================================================
	# SUBTÍTULO
	# =====================================================

	subtitulo = criar_label(
		"UMA VIDA EXTRA PARA SUA AVENTURA",
		9,
		Color("#C18ADB")
	)

	subtitulo.position = Vector2(
		0.0,
		56.0
	)

	subtitulo.size = Vector2(
		600.0,
		20.0
	)

	subtitulo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	painel.add_child(subtitulo)


	# =====================================================
	# ÍCONE
	# =====================================================

	icone_vida = TextureRect.new()

	icone_vida.texture = textura_vida

	icone_vida.position = Vector2(
		260.0,
		90.0
	)

	icone_vida.size = Vector2(
		80.0,
		80.0
	)

	icone_vida.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	icone_vida.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	icone_vida.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	icone_vida.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	painel.add_child(icone_vida)


	# =====================================================
	# ITEM
	# =====================================================

	nome_item = criar_label(
		"VIDA EXTRA",
		11,
		Color("#7BE7FF")
	)

	nome_item.position = Vector2(
		0.0,
		174.0
	)

	nome_item.size = Vector2(
		600.0,
		22.0
	)

	nome_item.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	painel.add_child(nome_item)


	# =====================================================
	# PREÇO
	# =====================================================

	preco = criar_label(
		"10 MOEDAS",
		10,
		Color("#F5D56A")
	)

	preco.position = Vector2(
		0.0,
		202.0
	)

	preco.size = Vector2(
		600.0,
		22.0
	)

	preco.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	painel.add_child(preco)


	# =====================================================
	# MOEDAS
	# =====================================================

	moedas = criar_label(
		"",
		10,
		Color("#A9D9FF")
	)

	moedas.position = Vector2(
		0.0,
		228.0
	)

	moedas.size = Vector2(
		600.0,
		22.0
	)

	moedas.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	painel.add_child(moedas)


	# =====================================================
	# VIDAS
	# =====================================================

	vidas = criar_label(
		"",
		10,
		Color("#FFBBCB")
	)

	vidas.position = Vector2(
		0.0,
		254.0
	)

	vidas.size = Vector2(
		600.0,
		22.0
	)

	vidas.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	painel.add_child(vidas)


	# =====================================================
	# RESULTADO
	# =====================================================

	resultado = criar_label(
		"",
		8,
		Color.WHITE
	)

	resultado.position = Vector2(
		0.0,
		278.0
	)

	resultado.size = Vector2(
		600.0,
		22.0
	)

	resultado.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	resultado.hide()

	painel.add_child(resultado)


	# =====================================================
	# VOLTAR
	# PRIMEIRO BOTÃO
	# =====================================================

	voltar = Button.new()
	voltar.text = "VOLTAR"
	voltar.position = Vector2(45.0, 300.0)
	voltar.size = Vector2(230.0, 44.0)
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	voltar.add_theme_font_override("font", fonte_retro)
	voltar.add_theme_font_size_override("font_size", 10)

	var voltar_normal := StyleBoxFlat.new()
	voltar_normal.bg_color = Color("#39234C")
	voltar_normal.border_color = Color("#8C5BB2")
	voltar_normal.set_border_width_all(2)
	voltar_normal.corner_radius_top_left = 6
	voltar_normal.corner_radius_top_right = 6
	voltar_normal.corner_radius_bottom_left = 6
	voltar_normal.corner_radius_bottom_right = 6

	var voltar_hover := StyleBoxFlat.new()
	voltar_hover.bg_color = Color("#472D63")
	voltar_hover.border_color = Color("#D58CFF")
	voltar_hover.set_border_width_all(2)
	voltar_hover.corner_radius_top_left = 6
	voltar_hover.corner_radius_top_right = 6
	voltar_hover.corner_radius_bottom_left = 6
	voltar_hover.corner_radius_bottom_right = 6

	var voltar_pressed := StyleBoxFlat.new()
	voltar_pressed.bg_color = Color("#5A3B78")
	voltar_pressed.border_color = Color("#D58CFF")
	voltar_pressed.set_border_width_all(2)
	voltar_pressed.corner_radius_top_left = 6
	voltar_pressed.corner_radius_top_right = 6
	voltar_pressed.corner_radius_bottom_left = 6
	voltar_pressed.corner_radius_bottom_right = 6

	voltar.add_theme_stylebox_override("normal", voltar_normal)
	voltar.add_theme_stylebox_override("hover", voltar_hover)
	voltar.add_theme_stylebox_override("pressed", voltar_pressed)
	voltar.add_theme_color_override("font_color", Color("#FFF0C7"))
	voltar.add_theme_color_override("font_hover_color", Color("#D9A7FF"))
	voltar.add_theme_color_override("font_pressed_color", Color("#D9A7FF"))

	voltar.pressed.connect(_clicar_voltar)
	voltar.mouse_entered.connect(_mouse_entrou_voltar)
	voltar.mouse_exited.connect(_mouse_saiu_botao)
	painel.add_child(voltar)


	# =====================================================
	# COMPRAR VIDA
	# SEGUNDO BOTÃO
	# =====================================================

	comprar = Button.new()
	comprar.text = "COMPRAR VIDA"
	comprar.position = Vector2(325.0, 300.0)
	comprar.size = Vector2(230.0, 44.0)
	comprar.focus_mode = Control.FOCUS_NONE
	comprar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	comprar.add_theme_font_override("font", fonte_retro)
	comprar.add_theme_font_size_override("font_size", 10)

	var comprar_normal := StyleBoxFlat.new()
	comprar_normal.bg_color = Color("#39234C")
	comprar_normal.border_color = Color("#8C5BB2")
	comprar_normal.set_border_width_all(2)
	comprar_normal.corner_radius_top_left = 6
	comprar_normal.corner_radius_top_right = 6
	comprar_normal.corner_radius_bottom_left = 6
	comprar_normal.corner_radius_bottom_right = 6

	var comprar_hover := StyleBoxFlat.new()
	comprar_hover.bg_color = Color("#472D63")
	comprar_hover.border_color = Color("#D58CFF")
	comprar_hover.set_border_width_all(2)
	comprar_hover.corner_radius_top_left = 6
	comprar_hover.corner_radius_top_right = 6
	comprar_hover.corner_radius_bottom_left = 6
	comprar_hover.corner_radius_bottom_right = 6

	var comprar_pressed := StyleBoxFlat.new()
	comprar_pressed.bg_color = Color("#5A3B78")
	comprar_pressed.border_color = Color("#D58CFF")
	comprar_pressed.set_border_width_all(2)
	comprar_pressed.corner_radius_top_left = 6
	comprar_pressed.corner_radius_top_right = 6
	comprar_pressed.corner_radius_bottom_left = 6
	comprar_pressed.corner_radius_bottom_right = 6

	comprar.add_theme_stylebox_override("normal", comprar_normal)
	comprar.add_theme_stylebox_override("hover", comprar_hover)
	comprar.add_theme_stylebox_override("pressed", comprar_pressed)
	comprar.add_theme_color_override("font_color", Color("#FFF0C7"))
	comprar.add_theme_color_override("font_hover_color", Color("#D9A7FF"))
	comprar.add_theme_color_override("font_pressed_color", Color("#D9A7FF"))

	comprar.pressed.connect(_clicar_comprar)
	comprar.mouse_entered.connect(_mouse_entrou_comprar)
	comprar.mouse_exited.connect(_mouse_saiu_botao)
	painel.add_child(comprar)


	# =====================================================
	# ESCONDER
	# =====================================================

	tela.hide()


# =========================================================
# CRIAR LABEL
# =========================================================

func criar_label(
	texto: String,
	tamanho: int,
	cor: Color
) -> Label:

	var label := Label.new()

	label.text = texto

	label.add_theme_font_override(
		"font",
		fonte_retro
	)

	label.add_theme_font_size_override(
		"font_size",
		tamanho
	)

	label.add_theme_color_override(
		"font_color",
		cor
	)

	label.add_theme_color_override(
		"font_outline_color",
		Color("#09060D")
	)

	label.add_theme_constant_override(
		"outline_size",
		2
	)

	label.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	return label


# =========================================================
# ATUALIZAR DADOS
# =========================================================

func atualizar_dados() -> void:

	if moedas == null:

		return


	moedas.text = "MOEDAS: %d" % Globals.coins

	vidas.text = "VIDAS ATUAIS: %d" % Globals.player_life


# =========================================================
# ATUALIZAR MENU
# =========================================================

func atualizar_menu() -> void:

	atualizar_dados()

	if voltar == null or comprar == null:
		return

	# Nenhum botão selecionado.
	if selecao == -1:

		voltar.add_theme_color_override(
			"font_color",
			Color("#FFF0C7")
		)

		comprar.add_theme_color_override(
			"font_color",
			Color("#FFF0C7")
		)

		return

	# Seleção pelo teclado: roxo.
	if selecao == 0:

		voltar.add_theme_color_override(
			"font_color",
			Color("#D9B5FF")
		)

		comprar.add_theme_color_override(
			"font_color",
			Color("#FFF0C7")
		)

	else:

		voltar.add_theme_color_override(
			"font_color",
			Color("#FFF0C7")
		)

		comprar.add_theme_color_override(
			"font_color",
			Color("#D9B5FF")
		)


# =========================================================
# MOUSE
# =========================================================

func _mouse_entrou_voltar() -> void:
	if voltar == null or comprar == null:
		return

	selecao = -1
	remover_destaque_botao(comprar)
	destacar_botao(voltar)


func _mouse_entrou_comprar() -> void:
	if voltar == null or comprar == null:
		return

	selecao = -1
	remover_destaque_botao(voltar)
	destacar_botao(comprar)


func _mouse_saiu_botao() -> void:
	if voltar == null or comprar == null:
		return

	# Só tira a seleção do mouse quando ele não estiver sobre
	# nenhum dos dois botões.
	var mouse_pos := get_viewport().get_mouse_position()
	var sobre_voltar := voltar.get_global_rect().has_point(mouse_pos)
	var sobre_comprar := comprar.get_global_rect().has_point(mouse_pos)

	if not sobre_voltar and not sobre_comprar:
		selecao = -1
		remover_destaque_botao(voltar)
		remover_destaque_botao(comprar)


# =========================================================
# DESTAQUE DOS BOTÕES
# =========================================================

func destacar_botao(botao: Button) -> void:
	if botao == null:
		return

	botao.add_theme_color_override(
		"font_color",
		Color("#D9A7FF")
	)

	var tween := create_tween()
	tween.tween_property(
		botao,
		"scale",
		Vector2(1.04, 1.04),
		0.10
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


func remover_destaque_botao(botao: Button) -> void:
	if botao == null:
		return

	botao.add_theme_color_override(
		"font_color",
		Color("#FFF0C7")
	)

	var tween := create_tween()
	tween.tween_property(
		botao,
		"scale",
		Vector2.ONE,
		0.10
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


# =========================================================
# PROCESSAR MENU
# =========================================================

func processar_menu(event: InputEvent) -> void:

	if bloqueado:

		return


	# -----------------------------------------------------
	# ESQUERDA = VOLTAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_left"):

		selecao = 0
		atualizar_menu()
		remover_destaque_botao(comprar)
		destacar_botao(voltar)
		get_viewport().set_input_as_handled()
		return


	# -----------------------------------------------------
	# DIREITA = COMPRAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_right"):

		selecao = 1
		atualizar_menu()
		remover_destaque_botao(voltar)
		destacar_botao(comprar)
		get_viewport().set_input_as_handled()
		return


	# -----------------------------------------------------
	# CIMA / BAIXO
	# Também funcionam.
	# -----------------------------------------------------

	if event.is_action_pressed("ui_up"):

		selecao = 1
		atualizar_menu()
		remover_destaque_botao(voltar)
		destacar_botao(comprar)
		get_viewport().set_input_as_handled()
		return


	if event.is_action_pressed("ui_down"):

		selecao = 0
		atualizar_menu()
		remover_destaque_botao(comprar)
		destacar_botao(voltar)
		get_viewport().set_input_as_handled()
		return


	# -----------------------------------------------------
	# E
	# -----------------------------------------------------

	if event.is_action_pressed("interact"):

		if selecao == -1:
			return

		get_viewport().set_input_as_handled()

		confirmar_opcao()

		return


	# -----------------------------------------------------
	# ENTER
	# -----------------------------------------------------

	if event.is_action_pressed("ui_accept"):

		if selecao == -1:
			return

		get_viewport().set_input_as_handled()

		confirmar_opcao()

		return


	# -----------------------------------------------------
	# ESC
	# A pausa do jogo fica por cima da loja.
	# A loja não fecha aqui.
	# -----------------------------------------------------

	if event.is_action_pressed("ui_cancel"):

		return


# =========================================================
# CONFIRMAR
# =========================================================

func confirmar_opcao() -> void:

	if bloqueado:

		return


	# -----------------------------------------------------
	# VOLTAR
	# -----------------------------------------------------

	if selecao == 0:

		fechar_menu()

		return


	# -----------------------------------------------------
	# COMPRAR
	# -----------------------------------------------------

	if selecao == 1:

		comprar_vida()


# =========================================================
# COMPRAR VIDA
# =========================================================

func comprar_vida() -> void:

	if bloqueado:

		return


	bloqueado = true


	# =====================================================
	# TEM DINHEIRO
	# =====================================================

	if Globals.coins >= PRECO_VIDA:

		Globals.coins -= PRECO_VIDA

		Globals.player_life += 1


		print("LOJA: VIDA COMPRADA")


		resultado.text = "COMPRA REALIZADA!   +1 VIDA"

		resultado.add_theme_color_override(
			"font_color",
			Color("#7CFFB2")
		)

		resultado.show()


		atualizar_dados()


		# -------------------------------------------------
		# Animação
		# -------------------------------------------------

		icone_vida.scale = Vector2(
			1.20,
			1.20
		)


		var tween := create_tween()

		tween.tween_property(
			icone_vida,
			"scale",
			Vector2.ONE,
			0.20
		).set_trans(
			Tween.TRANS_BACK
		).set_ease(
			Tween.EASE_OUT
		)


		await get_tree().create_timer(
			0.8
		).timeout


		if not is_inside_tree():

			return


		resultado.hide()


	# =====================================================
	# SEM DINHEIRO
	# =====================================================

	else:

		var faltam: int = (
			PRECO_VIDA - Globals.coins
		)


		resultado.text = "FALTAM %d MOEDAS" % faltam

		resultado.add_theme_color_override(
			"font_color",
			Color("#FF7185")
		)

		resultado.show()


		await get_tree().create_timer(
			1.1
		).timeout


		if not is_inside_tree():

			return


		resultado.hide()


	# =====================================================
	# LIBERAR
	# =====================================================

	bloqueado = false

	atualizar_menu()


# =========================================================
# CLIQUE NOS BOTÕES
# =========================================================

func _clicar_voltar() -> void:

	if estado != EstadoLoja.MENU:
		return

	selecao = 0
	atualizar_menu()
	confirmar_opcao()


func _clicar_comprar() -> void:

	if estado != EstadoLoja.MENU:
		return

	selecao = 1
	atualizar_menu()
	confirmar_opcao()


# =========================================================
# BLOQUEAR PLAYER DURANTE A LOJA
# =========================================================

func bloquear_player_para_loja() -> void:
	if player == null:
		return

	if not is_instance_valid(player):
		return

	if player_bloqueado_loja:
		return

	player_bloqueado_loja = true

	# Guarda o estado antes de congelar.
	player_physics_was_enabled = player.is_physics_processing()

	# Para completamente movimento, pulo e animação de caminhada.
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	if player.has_method("set"):
		player.set("can_move", false)
		player.set("velocity", Vector2.ZERO)

	var sprite := player.get_node_or_null("Anim") as AnimatedSprite2D
	if sprite != null:
		sprite.stop()


func desbloquear_player_da_loja() -> void:
	if player == null:
		return

	if not is_instance_valid(player):
		return

	if not player_bloqueado_loja:
		return

	player_bloqueado_loja = false

	if player.has_method("set"):
		player.set("can_move", true)
		player.set("velocity", Vector2.ZERO)

	if player_physics_was_enabled:
		player.set_physics_process(true)


# =========================================================
# FECHAR MENU
# =========================================================

func fechar_menu() -> void:

	if bloqueado:

		return


	if tela != null:

		tela.hide()

	desbloquear_player_da_loja()

	estado = EstadoLoja.ESPERANDO

	selecao = -1

	bloqueado = false


	if jogador_na_area:

		aviso.text = "[E] FALAR"

		aviso.show()

	else:

		aviso.hide()


	print("LOJA: MENU FECHADO")
