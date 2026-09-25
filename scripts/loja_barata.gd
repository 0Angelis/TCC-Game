extends Area2D

# =========================================================
# LOJA DA BARATA - 7 SAIAS DE FILÓ
# =========================================================
# Baseada na estrutura da loja de skins enviada.
#
# IDEIA DO MEME:
# - A barata anuncia "7 SAIAS DE FILÓ".
# - O jogador entra, conversa e abre a loja.
# - Compra pagando moedas.
# - NÃO ganha item nenhum.
# - Depois da compra a barata revela que era mentira.
#
# O preço fica fácil de alterar em PRECO_SAIAS_FILO.

# =========================================================
# CONFIGURAÇÃO
# =========================================================

const OFFSET_DIALOGO: Vector2 = Vector2(0.0, 95.0)
const OFFSET_AVISO: Vector2 = Vector2(-45.0, -42.0)

const DISTANCIA_MAXIMA_INTERACAO: float = 100.0

# PREÇO DA PEGADINHA
const PRECO_SAIAS_FILO: int = 10

# Tempo entre a falsa confirmação e a revelação da mentira.
const TEMPO_REVELACAO: float = 0.8

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
# INTERFACE
# =========================================================

var canvas: CanvasLayer = null
var tela: Control = null
var painel: Panel = null

var titulo: Label = null
var subtitulo: Label = null
var icone_item: Label = null
var nome_item: Label = null
var preco: Label = null
var moedas: Label = null
var estado_item: Label = null
var resultado: Label = null

var voltar: Button = null
var comprar: Button = null

# =========================================================
# MEME
# =========================================================

var comprou_saias_filo: bool = false
var selecao: int = -1

# =========================================================
# FONTE
# =========================================================

var fonte_retro = preload(
	"res://assets/Fontes/Pixeloid_Font_1_0/OpenType (.otf)/PixeloidSans-Bold.otf"
)

# =========================================================
# READY
# =========================================================

func _ready() -> void:

	monitoring = true
	monitorable = true

	# -----------------------------------------------------
	# PLAYER
	# -----------------------------------------------------

	player = get_node_or_null("../player") as Node2D

	# -----------------------------------------------------
	# SINAIS
	# -----------------------------------------------------

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	# -----------------------------------------------------
	# AVISO
	# -----------------------------------------------------

	criar_aviso()

	print("========================================")
	print("LOJA DA BARATA INICIADA")
	print("7 SAIAS DE FILÓ")
	print("PREÇO: ", PRECO_SAIAS_FILO)
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

# =========================================================
# PLAYER SAIU
# =========================================================

func _on_body_exited(body: Node2D) -> void:

	if body != player:
		return

	jogador_na_area = false

	if aviso != null:
		aviso.hide()

	if estado == EstadoLoja.CONVERSA:
		bloqueado = false

	esperando_soltar_e = false

# =========================================================
# PROCESS
# =========================================================

func _process(_delta: float) -> void:

	# -----------------------------------------------------
	# SEGURANÇA DE DISTÂNCIA
	# -----------------------------------------------------

	if jogador_na_area and not jogador_esta_perto_da_loja():
		jogador_na_area = false
		esperando_soltar_e = false

		if aviso != null:
			aviso.hide()

	# -----------------------------------------------------
	# ESPERAR SOLTAR E
	# -----------------------------------------------------

	if esperando_soltar_e:

		if not Input.is_action_pressed("interact"):
			esperando_soltar_e = false

			if jogador_na_area:
				abrir_menu()
			else:
				estado = EstadoLoja.ESPERANDO

		return

	# -----------------------------------------------------
	# DIÁLOGO
	# -----------------------------------------------------

	if DialogManager.is_message_active:

		if aviso != null:
			aviso.hide()

		return

	# -----------------------------------------------------
	# MENU
	# -----------------------------------------------------

	if estado == EstadoLoja.MENU:
		atualizar_dados()
		return

	# -----------------------------------------------------
	# PLAYER FORA
	# -----------------------------------------------------

	if not jogador_na_area:

		if aviso != null:
			aviso.hide()

		return

	# -----------------------------------------------------
	# ESTADO NORMAL
	# -----------------------------------------------------

	if estado == EstadoLoja.ESPERANDO:

		if aviso != null:
			aviso.show()

# =========================================================
# INPUT
# =========================================================

func _input(event: InputEvent) -> void:

	# -----------------------------------------------------
	# MENU
	# -----------------------------------------------------

	if estado == EstadoLoja.MENU:
		processar_menu(event)
		return

	# -----------------------------------------------------
	# PLAYER PRECISA ESTAR NA ÁREA
	# -----------------------------------------------------

	if not jogador_na_area:
		return

	# -----------------------------------------------------
	# DIÁLOGO
	# -----------------------------------------------------

	if DialogManager.is_message_active:
		return

	if esperando_soltar_e:
		return

	# -----------------------------------------------------
	# ABRIR CONVERSA
	# -----------------------------------------------------

	if estado == EstadoLoja.ESPERANDO:

		if event.is_action_pressed("interact"):

			if not jogador_esta_perto_da_loja():
				return

			get_viewport().set_input_as_handled()

			abrir_conversa()

# =========================================================
# CHECAR DISTÂNCIA
# =========================================================

func jogador_esta_perto_da_loja() -> bool:

	if player == null:
		return false

	if not is_instance_valid(player):
		return false

	var centro_loja: Vector2 = global_position

	var collision := (
		get_node_or_null("CollisionShape2D")
		as CollisionShape2D
	)

	if collision != null:
		centro_loja = collision.global_position

	var distancia: float = (
		player.global_position.distance_to(centro_loja)
	)

	return distancia <= DISTANCIA_MAXIMA_INTERACAO

# =========================================================
# CONVERSA DA BARATA
# =========================================================

func abrir_conversa() -> void:

	if bloqueado:
		return

	if DialogManager.is_message_active:
		return

	bloqueado = true
	estado = EstadoLoja.CONVERSA

	aviso.hide()

	var falas: Array[String] = [
		"psiu... chega ai.",
		"tenho uma oferta que voce nunca viu antes.",
		"AS 7 SAIAS DE FILÓ!",
		"isso mesmo! 7 saias! uma mais estilosa que a outra.",
		"so hoje por %d moedas!" % PRECO_SAIAS_FILO,
		"confia aqui na barata..."
	]

	var posicao: Vector2 = (
		$CollisionShape2D.global_position
		+ OFFSET_DIALOGO
	)

	DialogManager.start_message(
		posicao,
		falas,
		self
	)

	while DialogManager.is_message_active:
		await get_tree().process_frame

	if not is_inside_tree():
		return

	while Input.is_action_pressed("interact"):
		await get_tree().process_frame

	if not is_inside_tree():
		return

	if not jogador_esta_perto_da_loja():
		bloqueado = false
		esperando_soltar_e = false
		estado = EstadoLoja.ESPERANDO
		return

	abrir_menu()

# =========================================================
# AVISO
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

	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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

	aviso.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE

	aviso.hide()

	add_child(aviso)

# =========================================================
# ABRIR MENU
# =========================================================

func abrir_menu() -> void:

	if tela == null:
		criar_menu()

	bloqueado = false
	estado = EstadoLoja.MENU
	selecao = -1

	bloquear_player_para_loja()

	resultado.hide()

	atualizar_menu()

	tela.show()

	aviso.hide()

	painel.pivot_offset = painel.size / 2.0
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

	# -----------------------------------------------------
	# CANVAS
	# -----------------------------------------------------

	canvas = CanvasLayer.new()
	canvas.name = "LojaBarataCanvas"
	canvas.layer = 200
	canvas.process_mode = Node.PROCESS_MODE_PAUSABLE

	var cena_atual := get_tree().current_scene

	if cena_atual != null:
		cena_atual.add_child(canvas)
	else:
		get_tree().root.add_child(canvas)

	# -----------------------------------------------------
	# TELA
	# -----------------------------------------------------

	tela = Control.new()
	tela.name = "TelaLojaBarata"

	tela.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	tela.process_mode = Node.PROCESS_MODE_PAUSABLE
	tela.mouse_filter = Control.MOUSE_FILTER_STOP

	canvas.add_child(tela)

	# -----------------------------------------------------
	# FUNDO
	# -----------------------------------------------------

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

	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tela.add_child(escurecer)

	# -----------------------------------------------------
	# PAINEL
	# -----------------------------------------------------

	painel = Panel.new()

	painel.anchor_left = 0.5
	painel.anchor_top = 0.5
	painel.anchor_right = 0.5
	painel.anchor_bottom = 0.5

	painel.offset_left = -300.0
	painel.offset_top = -205.0
	painel.offset_right = 300.0
	painel.offset_bottom = 205.0

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

	# -----------------------------------------------------
	# LINHA TOPO
	# -----------------------------------------------------

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

	# -----------------------------------------------------
	# TITULO
	# -----------------------------------------------------

	titulo = criar_label(
		"LOJA DA BARATA",
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

	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(titulo)

	# -----------------------------------------------------
	# SUBTITULO
	# -----------------------------------------------------

	subtitulo = criar_label(
		"A BARATA DIZ QUE TEM",
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

	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(subtitulo)

	# -----------------------------------------------------
	# ICONE / NOME CURTO
	# -----------------------------------------------------

	icone_item = criar_label(
		"7 SAIAS DE FILÓ",
		15,
		Color("#F0A0FF")
	)

	icone_item.position = Vector2(
		0.0,
		88.0
	)

	icone_item.size = Vector2(
		600.0,
		38.0
	)

	icone_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(icone_item)

	# -----------------------------------------------------
	# NOME
	# -----------------------------------------------------

	nome_item = criar_label(
		"",
		11,
		Color("#7BE7FF")
	)

	nome_item.position = Vector2(
		0.0,
		138.0
	)

	nome_item.size = Vector2(
		600.0,
		22.0
	)

	nome_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(nome_item)

	# -----------------------------------------------------
	# PREÇO
	# -----------------------------------------------------

	preco = criar_label(
		"",
		10,
		Color("#F5D56A")
	)

	preco.position = Vector2(
		0.0,
		165.0
	)

	preco.size = Vector2(
		600.0,
		22.0
	)

	preco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(preco)

	# -----------------------------------------------------
	# MOEDAS
	# -----------------------------------------------------

	moedas = criar_label(
		"",
		10,
		Color("#A9D9FF")
	)

	moedas.position = Vector2(
		0.0,
		191.0
	)

	moedas.size = Vector2(
		600.0,
		22.0
	)

	moedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(moedas)

	# -----------------------------------------------------
	# ESTADO
	# -----------------------------------------------------

	estado_item = criar_label(
		"",
		8,
		Color.WHITE
	)

	estado_item.position = Vector2(
		0.0,
		217.0
	)

	estado_item.size = Vector2(
		600.0,
		22.0
	)

	estado_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(estado_item)

	# -----------------------------------------------------
	# RESULTADO
	# -----------------------------------------------------

	resultado = criar_label(
		"",
		12,
		Color.WHITE
	)

	resultado.position = Vector2(
		0.0,
		238.0
	)

	resultado.size = Vector2(
		600.0,
		55.0
	)

	resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resultado.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	resultado.hide()

	painel.add_child(resultado)

	# -----------------------------------------------------
	# VOLTAR
	# -----------------------------------------------------

	voltar = criar_botao(
		"VOLTAR",
		Vector2(45.0, 300.0),
		Vector2(230.0, 44.0)
	)

	voltar.pressed.connect(_clicar_voltar)
	voltar.mouse_entered.connect(_mouse_entrou_voltar)
	voltar.mouse_exited.connect(_mouse_saiu_botao)

	painel.add_child(voltar)

	# -----------------------------------------------------
	# COMPRAR
	# -----------------------------------------------------

	comprar = criar_botao(
		"COMPRAR",
		Vector2(325.0, 300.0),
		Vector2(230.0, 44.0)
	)

	comprar.pressed.connect(_clicar_comprar)
	comprar.mouse_entered.connect(_mouse_entrou_comprar)
	comprar.mouse_exited.connect(_mouse_saiu_botao)

	painel.add_child(comprar)

	# -----------------------------------------------------
	# ESCONDER
	# -----------------------------------------------------

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

	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return label

# =========================================================
# CRIAR BOTÃO
# =========================================================

func criar_botao(
	texto: String,
	posicao: Vector2,
	tamanho: Vector2
) -> Button:

	var botao := Button.new()

	botao.text = texto
	botao.position = posicao
	botao.size = tamanho

	botao.focus_mode = Control.FOCUS_NONE
	botao.mouse_filter = Control.MOUSE_FILTER_STOP
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	botao.add_theme_font_override(
		"font",
		fonte_retro
	)

	botao.add_theme_font_size_override(
		"font_size",
		9
	)

	var normal := StyleBoxFlat.new()

	normal.bg_color = Color("#39234C")
	normal.border_color = Color("#8C5BB2")
	normal.set_border_width_all(2)

	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6

	var hover := StyleBoxFlat.new()

	hover.bg_color = Color("#472D63")
	hover.border_color = Color("#D58CFF")
	hover.set_border_width_all(2)

	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6

	var pressed := StyleBoxFlat.new()

	pressed.bg_color = Color("#5A3B78")
	pressed.border_color = Color("#D58CFF")
	pressed.set_border_width_all(2)

	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_left = 6
	pressed.corner_radius_bottom_right = 6

	botao.add_theme_stylebox_override(
		"normal",
		normal
	)

	botao.add_theme_stylebox_override(
		"hover",
		hover
	)

	botao.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	botao.add_theme_color_override(
		"font_color",
		Color("#FFF0C7")
	)

	botao.add_theme_color_override(
		"font_hover_color",
		Color("#D9A7FF")
	)

	botao.add_theme_color_override(
		"font_pressed_color",
		Color("#D9A7FF")
	)

	return botao

# =========================================================
# ATUALIZAR DADOS
# =========================================================

func atualizar_dados() -> void:

	if moedas == null:
		return

	moedas.text = "MOEDAS: %d" % Globals.coins

# =========================================================
# ATUALIZAR MENU
# =========================================================

func atualizar_menu() -> void:

	if nome_item == null:
		return

	nome_item.text = "OFERTA DO DIA"
	preco.text = "%d MOEDAS" % PRECO_SAIAS_FILO
	moedas.text = "MOEDAS: %d" % Globals.coins

	if comprou_saias_filo:

		estado_item.text = "COMPRADO"

		estado_item.add_theme_color_override(
			"font_color",
			Color("#FF7185")
		)

		comprar.text = "JÁ COMPREI"

		comprar.disabled = true

	else:

		estado_item.text = "OFERTA ÚNICA"

		estado_item.add_theme_color_override(
			"font_color",
			Color("#7CFFB2")
		)

		comprar.text = "COMPRAR"

		comprar.disabled = false

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
		remover_destaque_botao(comprar)
		destacar_botao(voltar)

		get_viewport().set_input_as_handled()
		return

	# -----------------------------------------------------
	# DIREITA = COMPRAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_right"):

		selecao = 1
		remover_destaque_botao(voltar)
		destacar_botao(comprar)

		get_viewport().set_input_as_handled()
		return

	# -----------------------------------------------------
	# CIMA = COMPRAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_up"):

		selecao = 1
		remover_destaque_botao(voltar)
		destacar_botao(comprar)

		get_viewport().set_input_as_handled()
		return

	# -----------------------------------------------------
	# BAIXO = VOLTAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_down"):

		selecao = 0
		remover_destaque_botao(comprar)
		destacar_botao(voltar)

		get_viewport().set_input_as_handled()
		return

	# -----------------------------------------------------
	# E = CONFIRMAR
	# -----------------------------------------------------

	if event.is_action_pressed("interact"):

		if selecao == -1:
			return

		get_viewport().set_input_as_handled()
		confirmar_opcao()
		return

	# -----------------------------------------------------
	# ENTER = CONFIRMAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_accept"):

		if selecao == -1:
			return

		get_viewport().set_input_as_handled()
		confirmar_opcao()
		return

	# -----------------------------------------------------
	# ESC = FECHAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_cancel"):

		get_viewport().set_input_as_handled()
		fechar_menu()
		return


# =========================================================
# COMPRAR
# =========================================================

func confirmar_opcao() -> void:

	if bloqueado:
		return

	if selecao == 0:
		fechar_menu()
		return

	if selecao == 1:
		comprar_ou_equipar()
		return


func comprar_ou_equipar() -> void:

	if bloqueado:
		return

	if comprou_saias_filo:

		mostrar_resultado(
			"VOCE JA COMPROU AS SAIAS KKK",
			Color("#FF7185")
		)

		return

	# -----------------------------------------------------
	# SEM MOEDAS
	# -----------------------------------------------------

	if Globals.coins < PRECO_SAIAS_FILO:

		var faltam: int = (
			PRECO_SAIAS_FILO - Globals.coins
		)

		mostrar_resultado(
			"FALTAM %d MOEDAS!" % faltam,
			Color("#FF7185")
		)

		return

	# -----------------------------------------------------
	# COMPRA DA PEGADINHA
	# -----------------------------------------------------

	bloqueado = true

	# O jogador REALMENTE perde as moedas.
	Globals.coins -= PRECO_SAIAS_FILO

	# Marca que comprou para não permitir pagar de novo.
	comprou_saias_filo = true

	atualizar_menu()
	atualizar_dados()

	# Primeiro vem a falsa confirmação.
	mostrar_resultado(
		"COMPRA REALIZADA! 7 SAIAS DE FILÓ!",
		Color("#7CFFB2")
	)

	await get_tree().create_timer(
		1.5
	).timeout

	if not is_inside_tree():
		return

	# -----------------------------------------------------
	# REVELAÇÃO DA MENTIRA
	# -----------------------------------------------------

	mostrar_resultado(
		"ERA MENTIRA DA BARATA KKKKK!",
		Color("#FF7185")
	)

	await get_tree().create_timer(
		1.7
	).timeout

	if not is_inside_tree():
		return

	mostrar_resultado(
		"VOCE PAGOU E NAO RECEBEU NADA!",
		Color("#FF7185")
	)

	await get_tree().create_timer(
		1.6
	).timeout

	if not is_inside_tree():
		return

	resultado.hide()

	bloqueado = false

# =========================================================
# RESULTADO
# =========================================================

func mostrar_resultado(
	texto: String,
	cor: Color
) -> void:

	resultado.text = texto

	resultado.add_theme_color_override(
		"font_color",
		cor
	)

	resultado.show()

# =========================================================
# BOTÃO VOLTAR
# =========================================================

func _clicar_voltar() -> void:

	if estado != EstadoLoja.MENU:
		return

	fechar_menu()

# =========================================================
# BOTÃO COMPRAR
# =========================================================

func _clicar_comprar() -> void:

	if estado != EstadoLoja.MENU:
		return

	comprar_ou_equipar()

# =========================================================
# MOUSE - ENTRAR NO BOTÃO VOLTAR
# =========================================================

func _mouse_entrou_voltar() -> void:

	if voltar == null or comprar == null:
		return

	selecao = -1
	remover_destaque_botao(comprar)
	destacar_botao(voltar)

# =========================================================
# MOUSE - ENTRAR NO BOTÃO COMPRAR
# =========================================================

func _mouse_entrou_comprar() -> void:

	if voltar == null or comprar == null:
		return

	selecao = -1
	remover_destaque_botao(voltar)
	destacar_botao(comprar)

# =========================================================
# MOUSE - SAIR
# =========================================================

func _mouse_saiu_botao() -> void:

	var mouse_pos := get_viewport().get_mouse_position()

	var sobre_voltar := (
		voltar != null
		and voltar.get_global_rect().has_point(mouse_pos)
	)

	var sobre_comprar := (
		comprar != null
		and comprar.get_global_rect().has_point(mouse_pos)
	)

	if not sobre_voltar and not sobre_comprar:

		selecao = -1

		if voltar != null:
			remover_destaque_botao(voltar)

		if comprar != null:
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
# BLOQUEAR PLAYER
# =========================================================

func bloquear_player_para_loja() -> void:

	if player == null:
		return

	if not is_instance_valid(player):
		return

	if player_bloqueado_loja:
		return

	player_bloqueado_loja = true

	player_physics_was_enabled = (
		player.is_physics_processing()
	)

	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	if player.has_method("set"):

		player.set(
			"can_move",
			false
		)

		player.set(
			"velocity",
			Vector2.ZERO
		)

	var sprite := (
		player.get_node_or_null("Anim")
		as AnimatedSprite2D
	)

	if sprite != null:
		sprite.stop()

# =========================================================
# DESBLOQUEAR PLAYER
# =========================================================

func desbloquear_player_da_loja() -> void:

	if player == null:
		return

	if not is_instance_valid(player):
		return

	if not player_bloqueado_loja:
		return

	player_bloqueado_loja = false

	if player.has_method("set"):

		player.set(
			"can_move",
			true
		)

		player.set(
			"velocity",
			Vector2.ZERO
		)

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
	bloqueado = false

	if jogador_na_area:

		aviso.text = "[E] FALAR"
		aviso.show()

	else:

		aviso.hide()

	# A barata faz a zoeira depois que o jogador sai da loja.
	await get_tree().create_timer(0.15).timeout

	if not is_inside_tree():
		return

	var falas_zoeira: Array[String] = [
		"EI, TONTÃO! KKKKK!",
		"CAIU NO GOLPE DA BARATA! AS 7 SAIAS NEM EXISTEM!"
	]

	DialogManager.start_message(
		global_position + OFFSET_DIALOGO,
		falas_zoeira,
		self
	)
