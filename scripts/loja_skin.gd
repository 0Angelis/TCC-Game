extends Area2D

# =========================================================
# FEIRINHA DO VALE - LOJA DE SKINS
# =========================================================

const OFFSET_DIALOGO: Vector2 = Vector2(0.0, 90.0)
const OFFSET_AVISO: Vector2 = Vector2(-45.0, -58.0)

# Distancia maxima para poder interagir com a lojinha.
# Isso impede que o E abra a loja mesmo quando o jogador esta longe.
const DISTANCIA_MAXIMA_INTERACAO: float = 100.0

# Arquivo usado para guardar skins compradas/equipadas.
# As compras existem somente enquanto o jogo esta aberto.
# Nada e salvo em arquivo.
#
# O estado da sessao atravessa as fases.
# O snapshot representa o que o jogador possuia no inicio da fase.
const META_SESSAO: String = "skins_session_state"
const META_SNAPSHOT: String = "skins_phase_snapshot"
const META_SCENE: String = "skins_phase_scene"

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
var icone_skin: Label = null
var nome_item: Label = null
var preco: Label = null
var moedas: Label = null
var estado_skin: Label = null
var resultado: Label = null

var voltar: Button = null
var comprar: Button = null
var esquerda: Button = null
var direita: Button = null

# =========================================================
# SELECAO
# =========================================================

var skin_atual_index: int = 0

# =========================================================
# FONTE
# =========================================================

var fonte_retro = preload(
	"res://assets/Fontes/Pixeloid_Font_1_0/OpenType (.otf)/PixeloidSans-Bold.otf"
)

# =========================================================
# SKINS
# =========================================================

var skins: Array[Dictionary] = [
	{
		"id": "original",
		"nome": "PINGUIM PADRAO",
		"preco": 0,
		"icone": "PADRAO",
		"cor": Color.WHITE
	},
	{
		"id": "azul",
		"nome": "PINGUIM AZUL",
		"preco": 10,
		"icone": "AZUL",
		"cor": Color("#2196FF")
	},
	{
		"id": "vermelho",
		"nome": "PINGUIM VERMELHO",
		"preco": 10,
		"icone": "VERMELHO",
		"cor": Color("#F44336")
	},
	{
		"id": "amarelo",
		"nome": "PINGUIM AMARELO",
		"preco": 10,
		"icone": "AMARELO",
		"cor": Color("#FFD600")
	},
	{
		"id": "bronze",
		"nome": "PINGUIM BRONZE",
		"preco": 20,
		"icone": "BRONZE",
		"cor": Color("#B87333")
	},
	{
		"id": "prata",
		"nome": "PINGUIM PRATA",
		"preco": 25,
		"icone": "PRATA",
		"cor": Color("#C8C8C8")
	},
	{
		"id": "ouro",
		"nome": "PINGUIM OURO",
		"preco": 30,
		"icone": "OURO",
		"cor": Color("#FFD21F")
	},
	{
		"id": "rgb",
		"nome": "PINGUIM RGB",
		"preco": 30,
		"icone": "RGB",
		"cor": Color.WHITE
	}
]

# =========================================================
# ESTADO DAS COMPRAS
# =========================================================

var skins_desbloqueadas: Array[String] = ["original"]
var skin_equipada: String = "original"

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

	# -----------------------------------------------------
	# SESSAO / RODADA
	# -----------------------------------------------------

	preparar_estado_da_rodada()
	carregar_estado_da_sessao()
	aplicar_skin_no_player()

	print("========================================")
	print("LOJA DE SKINS INICIADA")
	print("SKIN EQUIPADA: ", skin_equipada)
	print("SKINS DESBLOQUEADAS: ", skins_desbloqueadas)
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

	# Se o jogador saiu da proximidade durante a conversa,
	# ele nao podera entrar no menu depois de ficar longe.
	if estado == EstadoLoja.CONVERSA:
		bloqueado = false

	# Se ainda estava esperando o jogador soltar o E, cancela.
	esperando_soltar_e = false


# =========================================================
# PROCESS
# =========================================================

func _process(_delta: float) -> void:

	# -----------------------------------------------------
	# SEGURANCA DE DISTANCIA
	# -----------------------------------------------------
	# Alem da Area2D, conferimos a distancia real do jogador.
	# Assim, uma CollisionShape2D grande demais nao permite
	# abrir a loja de longe.
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
	# PLAYER PRECISA ESTAR NA AREA
	# -----------------------------------------------------

	if not jogador_na_area:
		return

	# -----------------------------------------------------
	# DIALOGO
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

			# Segunda verificacao no exato momento do E.
			if not jogador_esta_perto_da_loja():
				return

			get_viewport().set_input_as_handled()

			abrir_conversa()


# =========================================================
# CHECAR DISTANCIA
# =========================================================

func jogador_esta_perto_da_loja() -> bool:

	if player == null:
		return false

	if not is_instance_valid(player):
		return false

	var centro_loja: Vector2 = global_position

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		centro_loja = collision.global_position

	var distancia: float = player.global_position.distance_to(centro_loja)

	return distancia <= DISTANCIA_MAXIMA_INTERACAO


# =========================================================
# CONVERSA
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
		"Bem-vindo a Loja de Roupas!",
		"Aqui voce encontra visuais para o seu pinguim.",
		"Compre uma skin e equipe na hora!",
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

	# Se o jogador se afastou enquanto a conversa estava aberta,
	# nao abre o menu. Ele precisa voltar para perto da lojinha.
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

	# Libera o bloqueio usado durante a conversa.
	# Sem isso, nenhum botão da loja respondia.
	bloqueado = false

	estado = EstadoLoja.MENU

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
	canvas.name = "LojaSkinCanvas"
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
	tela.name = "TelaLojaSkin"

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
		"LOJA DE ROUPAS",
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
		"LOJA DE SKINS",
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

	icone_skin = criar_label(
		"BRONZE",
		18,
		Color("#B87333")
	)

	icone_skin.position = Vector2(
		0.0,
		84.0
	)

	icone_skin.size = Vector2(
		600.0,
		45.0
	)

	icone_skin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(icone_skin)

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
		145.0
	)

	nome_item.size = Vector2(
		600.0,
		22.0
	)

	nome_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(nome_item)

	# -----------------------------------------------------
	# PRECO
	# -----------------------------------------------------

	preco = criar_label(
		"",
		10,
		Color("#F5D56A")
	)

	preco.position = Vector2(
		0.0,
		172.0
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
		198.0
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

	estado_skin = criar_label(
		"",
		8,
		Color.WHITE
	)

	estado_skin.position = Vector2(
		0.0,
		224.0
	)

	estado_skin.size = Vector2(
		600.0,
		22.0
	)

	estado_skin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	painel.add_child(estado_skin)

	# -----------------------------------------------------
	# RESULTADO
	# -----------------------------------------------------

	resultado = criar_label(
		"",
		8,
		Color.WHITE
	)

	resultado.position = Vector2(
		0.0,
		251.0
	)

	resultado.size = Vector2(
		600.0,
		22.0
	)

	resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	resultado.hide()

	painel.add_child(resultado)

	# -----------------------------------------------------
	# BOTAO ESQUERDA
	# -----------------------------------------------------

	esquerda = criar_botao(
		"<",
		Vector2(45.0, 90.0),
		Vector2(65.0, 45.0)
	)

	esquerda.pressed.connect(_clicar_esquerda)
	esquerda.mouse_entered.connect(_mouse_entrou_esquerda)
	esquerda.mouse_exited.connect(_mouse_saiu_botao)

	painel.add_child(esquerda)

	# -----------------------------------------------------
	# BOTAO DIREITA
	# -----------------------------------------------------

	direita = criar_botao(
		">",
		Vector2(490.0, 90.0),
		Vector2(65.0, 45.0)
	)

	direita.pressed.connect(_clicar_direita)
	direita.mouse_entered.connect(_mouse_entrou_direita)
	direita.mouse_exited.connect(_mouse_saiu_botao)

	painel.add_child(direita)

	# -----------------------------------------------------
	# VOLTAR
	# -----------------------------------------------------

	voltar = criar_botao(
		"VOLTAR",
		Vector2(45.0, 310.0),
		Vector2(230.0, 44.0)
	)

	voltar.pressed.connect(_clicar_voltar)
	voltar.mouse_entered.connect(_mouse_entrou_voltar)
	voltar.mouse_exited.connect(_mouse_saiu_botao)

	painel.add_child(voltar)

	# -----------------------------------------------------
	# COMPRAR / EQUIPAR
	# -----------------------------------------------------

	comprar = criar_botao(
		"COMPRAR",
		Vector2(325.0, 310.0),
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
# CRIAR BOTAO
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

	if skins.is_empty():
		return

	var skin: Dictionary = skins[skin_atual_index]

	nome_item.text = str(skin["nome"])
	preco.text = "%d MOEDAS" % int(skin["preco"])
	moedas.text = "MOEDAS: %d" % Globals.coins

	var id: String = str(skin["id"])
	var cor: Color = skin["cor"]

	icone_skin.text = str(skin["icone"])
	icone_skin.add_theme_color_override(
		"font_color",
		cor
	)

	# -----------------------------------------------------
	# ESTADO
	# -----------------------------------------------------

	if skin_equipada == id:

		estado_skin.text = "EQUIPADO"
		estado_skin.add_theme_color_override(
			"font_color",
			Color("#7CFFB2")
		)

		comprar.text = "EQUIPADO"

	elif skin_desbloqueada(id):

		estado_skin.text = "DESBLOQUEADO"
		estado_skin.add_theme_color_override(
			"font_color",
			Color("#7BE7FF")
		)

		comprar.text = "EQUIPAR"

	else:

		estado_skin.text = "BLOQUEADO"
		estado_skin.add_theme_color_override(
			"font_color",
			Color("#FF7185")
		)

		comprar.text = "COMPRAR"

	# -----------------------------------------------------
	# NAVEGACAO
	# -----------------------------------------------------

	esquerda.disabled = false
	direita.disabled = false


# =========================================================
# PROCESSAR MENU
# =========================================================

func processar_menu(event: InputEvent) -> void:

	if bloqueado:
		return

	# -----------------------------------------------------
	# ESQUERDA / A = SKIN ANTERIOR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_left") \
	or (event is InputEventKey and event.pressed \
	and not event.echo and event.keycode == KEY_A):

		mudar_skin(-1)

		get_viewport().set_input_as_handled()

		return

	# -----------------------------------------------------
	# DIREITA / D = PROXIMA SKIN
	# -----------------------------------------------------

	if event.is_action_pressed("ui_right") \
	or (event is InputEventKey and event.pressed \
	and not event.echo and event.keycode == KEY_D):

		mudar_skin(1)

		get_viewport().set_input_as_handled()

		return

	# -----------------------------------------------------
	# ENTER = COMPRAR OU EQUIPAR
	# -----------------------------------------------------
	# E e ESPACO ficam desabilitados dentro da loja.
	# -----------------------------------------------------

	if event.is_action_pressed("ui_accept"):

		comprar_ou_equipar()

		get_viewport().set_input_as_handled()

		return

	# -----------------------------------------------------
	# ESC = VOLTAR / FECHAR
	# -----------------------------------------------------

	if event.is_action_pressed("ui_cancel"):

		fechar_menu()

		get_viewport().set_input_as_handled()

		return


# =========================================================
# MUDAR SKIN
# =========================================================

func mudar_skin(direcao: int) -> void:

	if skins.is_empty():
		return

	var novo_index: int = skin_atual_index + direcao

	# Navegação circular.
	if novo_index < 0:
		novo_index = skins.size() - 1

	elif novo_index >= skins.size():
		novo_index = 0

	if novo_index == skin_atual_index:
		return

	skin_atual_index = novo_index

	resultado.hide()

	atualizar_menu()

	icone_skin.scale = Vector2(
		1.15,
		1.15
	)

	var tween := create_tween()

	tween.tween_property(
		icone_skin,
		"scale",
		Vector2.ONE,
		0.12
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


# =========================================================
# COMPRAR / EQUIPAR
# =========================================================

func comprar_ou_equipar() -> void:

	if bloqueado:
		return

	var skin: Dictionary = skins[skin_atual_index]

	var id: String = str(skin["id"])
	var valor: int = int(skin["preco"])

	# -----------------------------------------------------
	# JÁ EQUIPADA
	# -----------------------------------------------------

	if skin_equipada == id:

		mostrar_resultado(
			"ESSA SKIN JA ESTA EQUIPADA!",
			Color("#7BE7FF")
		)

		return

	# -----------------------------------------------------
	# JÁ DESBLOQUEADA
	# -----------------------------------------------------

	if skin_desbloqueada(id):

		equipar_skin(id)

		mostrar_resultado(
			"SKIN EQUIPADA!",
			Color("#7CFFB2")
		)

		atualizar_menu()

		return

	# -----------------------------------------------------
	# SEM MOEDAS
	# -----------------------------------------------------

	if Globals.coins < valor:

		var faltam: int = valor - Globals.coins

		mostrar_resultado(
			"FALTAM %d MOEDAS!" % faltam,
			Color("#FF7185")
		)

		return

	# -----------------------------------------------------
	# COMPRA
	# -----------------------------------------------------

	bloqueado = true

	Globals.coins -= valor

	if not skins_desbloqueadas.has(id):
		skins_desbloqueadas.append(id)

	equipar_skin(id)
	atualizar_estado_da_sessao()

	atualizar_menu()
	atualizar_dados()

	mostrar_resultado(
		"COMPRA REALIZADA! SKIN EQUIPADA!",
		Color("#7CFFB2")
	)

	await get_tree().create_timer(
		0.9
	).timeout

	if not is_inside_tree():
		return

	resultado.hide()

	bloqueado = false


# =========================================================
# EQUIPAR
# =========================================================

func equipar_skin(id: String) -> void:

	if not skin_id_existe(id):
		return

	if id != "original" and not skins_desbloqueadas.has(id):
		return

	# A skin equipada existe durante toda a sessão do jogo,
	# inclusive quando a cena muda de fase.
	skin_equipada = id
	atualizar_estado_da_sessao()

	if player != null and is_instance_valid(player):
		if player.has_method("definir_skin_visual"):
			player.definir_skin_visual(skin_equipada)

	print(
		"========================================"
	)

	print(
		"SKIN EQUIPADA: ",
		skin_equipada
	)

	print(
		"========================================"
	)


# =========================================================
# APLICAR SKIN NO PLAYER
# =========================================================

func aplicar_skin_no_player() -> void:

	if player == null:
		return

	if not is_instance_valid(player):
		return

	if player.has_method("definir_skin_visual"):

		player.definir_skin_visual(
			skin_equipada
		)


# =========================================================
# SKIN DESBLOQUEADA?
# =========================================================

func skin_desbloqueada(id: String) -> bool:

	if id == "original":
		return true

	return skins_desbloqueadas.has(id)


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
# BOTAO VOLTAR
# =========================================================

func _clicar_voltar() -> void:

	if estado != EstadoLoja.MENU:
		return

	fechar_menu()


# =========================================================
# BOTAO COMPRAR
# =========================================================

func _clicar_comprar() -> void:

	if estado != EstadoLoja.MENU:
		return

	comprar_ou_equipar()


# =========================================================
# BOTAO ESQUERDA
# =========================================================

func _clicar_esquerda() -> void:

	if bloqueado:
		return

	mudar_skin(-1)


# =========================================================
# BOTAO DIREITA
# =========================================================

func _clicar_direita() -> void:

	if bloqueado:
		return

	mudar_skin(1)


# =========================================================
# MOUSE
# =========================================================

func _mouse_entrou_voltar() -> void:

	if voltar == null:
		return

	destacar_botao(voltar)


func _mouse_entrou_comprar() -> void:

	if comprar == null:
		return

	destacar_botao(comprar)


func _mouse_entrou_esquerda() -> void:

	if esquerda == null:
		return

	destacar_botao(esquerda)


func _mouse_entrou_direita() -> void:

	if direita == null:
		return

	destacar_botao(direita)


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

	var sobre_esquerda := (
		esquerda != null
		and esquerda.get_global_rect().has_point(mouse_pos)
	)

	var sobre_direita := (
		direita != null
		and direita.get_global_rect().has_point(mouse_pos)
	)

	if not sobre_voltar \
	and not sobre_comprar \
	and not sobre_esquerda \
	and not sobre_direita:

		if voltar != null:
			remover_destaque_botao(voltar)

		if comprar != null:
			remover_destaque_botao(comprar)

		if esquerda != null:
			remover_destaque_botao(esquerda)

		if direita != null:
			remover_destaque_botao(direita)


# =========================================================
# DESTAQUE DOS BOTOES
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
# SESSAO / RODADA
# =========================================================

func criar_estado_inicial_sessao() -> Dictionary:
	return {
		"skins_desbloqueadas": ["original"],
		"skin_equipada": "original"
	}


func raiz_do_jogo() -> Node:
	return get_tree().root


func preparar_estado_da_rodada() -> void:
	var raiz := raiz_do_jogo()
	var cena_atual: String = ""

	var cena = get_tree().current_scene
	if cena != null:
		cena_atual = cena.scene_file_path

	# PRIMEIRO INICIO DO JOGO
	if not raiz.has_meta(META_SESSAO):
		var inicial := criar_estado_inicial_sessao()
		raiz.set_meta(META_SESSAO, inicial)
		raiz.set_meta(META_SNAPSHOT, inicial.duplicate(true))
		raiz.set_meta(META_SCENE, cena_atual)
		return

	# PRIMEIRA VEZ que este sistema encontra uma cena.
	if not raiz.has_meta(META_SCENE):
		raiz.set_meta(META_SCENE, cena_atual)
		raiz.set_meta(
		META_SNAPSHOT,
		duplicar_estado_sessao()
	)
	return

	var ultima_cena: String = str(
		raiz.get_meta(META_SCENE, "")
	)

	# Mudanca normal de fase:
	# a compra ja realizada continua para a proxima fase e
	# torna-se o novo estado de inicio dessa fase.
	if ultima_cena != cena_atual:
		raiz.set_meta(META_SCENE, cena_atual)
		raiz.set_meta(
		META_SNAPSHOT,
		duplicar_estado_sessao()
		)


func duplicar_estado_sessao() -> Dictionary:
	var raiz := raiz_do_jogo()

	if not raiz.has_meta(META_SESSAO):
		return criar_estado_inicial_sessao()

	var dados = raiz.get_meta(META_SESSAO)

	if typeof(dados) != TYPE_DICTIONARY:
		return criar_estado_inicial_sessao()

	var lista: Array[String] = ["original"]

	if dados.has("skins_desbloqueadas"):
		var lista_original = dados["skins_desbloqueadas"]

		if typeof(lista_original) == TYPE_ARRAY:
			for item in lista_original:
				var id: String = str(item)

				if skin_id_existe(id) and not lista.has(id):
					lista.append(id)

	var equipada: String = "original"

	if dados.has("skin_equipada"):
		var tentativa: String = str(dados["skin_equipada"])

		if skin_id_existe(tentativa) 		and (tentativa == "original" or lista.has(tentativa)):
			equipada = tentativa

	return {
		"skins_desbloqueadas": lista,
		"skin_equipada": equipada
	}


func carregar_estado_da_sessao() -> void:
	var dados := duplicar_estado_sessao()

	skins_desbloqueadas.clear()

	var lista = dados["skins_desbloqueadas"]

	for item in lista:
		var id: String = str(item)

		if not skins_desbloqueadas.has(id):
			skins_desbloqueadas.append(id)

	skin_equipada = str(dados["skin_equipada"])

	if skin_equipada not in skins_desbloqueadas:
		skin_equipada = "original"


func atualizar_estado_da_sessao() -> void:
	var dados: Dictionary = {
		"skins_desbloqueadas": skins_desbloqueadas.duplicate(),
		"skin_equipada": skin_equipada
	}

	# Estado global da execucao do jogo.
	# Nao desaparece ao trocar de mundo/fase.
	raiz_do_jogo().set_meta(META_SESSAO, dados)


func resetar_compras_da_rodada() -> void:
	var raiz := raiz_do_jogo()

	if not raiz.has_meta(META_SNAPSHOT):
		return

	var snapshot = raiz.get_meta(META_SNAPSHOT)

	if typeof(snapshot) != TYPE_DICTIONARY:
		return

	# Restart: volta somente ao estado do inicio da fase.
	raiz.set_meta(
		META_SESSAO,
		snapshot.duplicate(true)
	)

# =========================================================
# CHECAR ID
# =========================================================

func skin_id_existe(id: String) -> bool:

	if id == "original":
		return true

	for skin in skins:

		if str(skin["id"]) == id:
			return true

	return false


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
