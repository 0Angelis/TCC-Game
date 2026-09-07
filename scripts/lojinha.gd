extends Node2D


# =========================================================
# CONFIGURAÇÃO DA LOJA
# =========================================================

const PRECO_VIDA: int = 10
const DISTANCIA_INTERACAO: float = 120.0


# =========================================================
# ESTADOS
# =========================================================

enum EstadoLoja {
	AGUARDANDO,
	DIALOGO_INICIAL,
	PRONTA_PARA_COMPRAR,
	PROCESSANDO_COMPRA
}


var estado: EstadoLoja = EstadoLoja.AGUARDANDO

var player: Node2D = null
var aviso: Label = null

var bloqueado: bool = false
var tecla_e_anterior: bool = false


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	print("========================================")
	print("LOJINHA INICIANDO")
	print("POSIÇÃO: ", global_position)
	print("========================================")


	# -----------------------------------------------------
	# Pega diretamente o player da cena loja.tscn
	# -----------------------------------------------------

	player = get_node_or_null("../player") as Node2D


	if player != null:

		print("LOJINHA: PLAYER ENCONTRADO!")
		print("PLAYER: ", player.name)
		print("PLAYER POSIÇÃO: ", player.global_position)

	else:

		print("LOJINHA: ERRO!")
		print("Não encontrei ../player")


	# -----------------------------------------------------
	# Criar aviso
	# -----------------------------------------------------

	criar_aviso()


# =========================================================
# PROCESS
# =========================================================

func _process(_delta: float) -> void:

	# -----------------------------------------------------
	# Tenta encontrar o player novamente
	# -----------------------------------------------------

	if player == null:

		player = get_node_or_null("../player") as Node2D

		if player == null:
			return


	# -----------------------------------------------------
	# Distância
	# -----------------------------------------------------

	var distancia: float = global_position.distance_to(
		player.global_position
	)

	var perto: bool = distancia <= DISTANCIA_INTERACAO


	# -----------------------------------------------------
	# DEBUG
	# -----------------------------------------------------

	if perto and estado == EstadoLoja.AGUARDANDO:

		aviso.show()

	else:

		if estado != EstadoLoja.PROCESSANDO_COMPRA:
			aviso.hide()


	# -----------------------------------------------------
	# Verificar E
	# -----------------------------------------------------

	var e_pressionado: bool = Input.is_key_pressed(KEY_E)

	var acabou_de_pressionar: bool = (
		e_pressionado
		and not tecla_e_anterior
	)

	tecla_e_anterior = e_pressionado


	# -----------------------------------------------------
	# Não fazer nada se estiver longe
	# -----------------------------------------------------

	if not perto:
		return


	# -----------------------------------------------------
	# Não interferir enquanto o DialogManager estiver ativo
	# -----------------------------------------------------

	if DialogManager.is_message_active:
		return


	# -----------------------------------------------------
	# Primeiro E = conversa
	# -----------------------------------------------------

	if (
		acabou_de_pressionar
		and estado == EstadoLoja.AGUARDANDO
		and not bloqueado
	):

		print("========================================")
		print("LOJINHA: E DETECTADO")
		print("LOJINHA: ABRINDO DIÁLOGO")
		print("DISTÂNCIA: ", distancia)
		print("========================================")

		abrir_dialogo_inicial()

		return


	# -----------------------------------------------------
	# Segundo E = compra
	# -----------------------------------------------------

	if (
		acabou_de_pressionar
		and estado == EstadoLoja.PRONTA_PARA_COMPRAR
		and not bloqueado
	):

		print("LOJINHA: E PARA COMPRAR")

		comprar_vida()

		return


# =========================================================
# CRIAR AVISO
# =========================================================

func criar_aviso() -> void:

	aviso = Label.new()


	# -----------------------------------------------------
	# Texto
	# -----------------------------------------------------

	aviso.text = "[E] FALAR"


	# -----------------------------------------------------
	# Posição acima da loja
	# -----------------------------------------------------

	aviso.position = Vector2(
		-45.0,
		-115.0
	)


	# -----------------------------------------------------
	# Fonte
	# -----------------------------------------------------

	var fonte = load(
		"res://assets/Fontes/Pixeloid_Font_1_0/OpenType (.otf)/PixeloidSans-Bold.otf"
	)


	if fonte != null:

		aviso.add_theme_font_override(
			"font",
			fonte
		)


	# -----------------------------------------------------
	# Tamanho
	# -----------------------------------------------------

	aviso.add_theme_font_size_override(
		"font_size",
		8
	)


	# -----------------------------------------------------
	# Cor
	# -----------------------------------------------------

	aviso.add_theme_color_override(
		"font_color",
		Color("#7046A3")
	)


	# -----------------------------------------------------
	# Pixel art
	# -----------------------------------------------------

	aviso.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


	# -----------------------------------------------------
	# Mouse
	# -----------------------------------------------------

	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# -----------------------------------------------------
	# Começa escondido
	# -----------------------------------------------------

	aviso.hide()


	add_child(aviso)


# =========================================================
# ABRIR DIÁLOGO
# =========================================================

func abrir_dialogo_inicial() -> void:

	if bloqueado:
		return

	if DialogManager.is_message_active:
		return


	bloqueado = true
	estado = EstadoLoja.DIALOGO_INICIAL

	aviso.hide()


	var falas: Array[String] = [
		"Olá, aventureiro!",
		"Bem-vindo a este novo mundo.",
		"Está precisando de uma vida extra?",
		"Eu posso vender uma vida para você.",
		"Cada vida custa 10 moedas.",
		"Quando terminar, pressione E novamente para comprar."
	]


	DialogManager.start_message(
		global_position + Vector2(0.0, -70.0),
		falas,
		self
	)


	print("LOJINHA: DIÁLOGO ABERTO")


	# -----------------------------------------------------
	# Espera o diálogo terminar
	# -----------------------------------------------------

	await esperar_dialogo()


	if not is_inside_tree():
		return


	estado = EstadoLoja.PRONTA_PARA_COMPRAR

	bloqueado = false

	aviso.text = "[E] COMPRAR VIDA - 10 MOEDAS"

	aviso.show()


	print("LOJINHA: PRONTA PARA COMPRA")


# =========================================================
# ESPERAR DIÁLOGO
# =========================================================

func esperar_dialogo() -> void:

	while DialogManager.is_message_active:

		await get_tree().process_frame


# =========================================================
# COMPRAR VIDA
# =========================================================

func comprar_vida() -> void:

	if bloqueado:
		return

	if DialogManager.is_message_active:
		return


	bloqueado = true
	estado = EstadoLoja.PROCESSANDO_COMPRA

	aviso.hide()


	print("========================================")
	print("LOJINHA: TENTANDO COMPRAR")
	print("MOEDAS ATUAIS: ", Globals.coins)
	print("VIDAS ATUAIS: ", Globals.player_life)
	print("========================================")


	# =====================================================
	# TEM MOEDAS
	# =====================================================

	if Globals.coins >= PRECO_VIDA:

		# -------------------------------------------------
		# Retira moedas
		# -------------------------------------------------

		Globals.coins -= PRECO_VIDA


		# -------------------------------------------------
		# Adiciona vida
		# -------------------------------------------------

		Globals.player_life += 1


		print("LOJINHA: COMPRA REALIZADA!")
		print("VIDAS: ", Globals.player_life)
		print("MOEDAS: ", Globals.coins)


		var falas_sucesso: Array[String] = [
			"Pronto!",
			"Você acabou de comprar uma vida extra.",
			"+1 vida!",
			"Agora você tem %d vidas." % Globals.player_life,
			"Restaram %d moedas." % Globals.coins
		]


		DialogManager.start_message(
			global_position + Vector2(0.0, -70.0),
			falas_sucesso,
			self
		)


		await esperar_dialogo()


	# =====================================================
	# SEM MOEDAS SUFICIENTES
	# =====================================================

	else:

		var faltam: int = PRECO_VIDA - Globals.coins


		print("LOJINHA: MOEDAS INSUFICIENTES")
		print("MOEDAS: ", Globals.coins)
		print("FALTAM: ", faltam)


		var falas_erro: Array[String] = [
			"Ops! Você não tem moedas suficientes.",
			"Uma vida custa 10 moedas.",
			"Você tem apenas %d moedas." % Globals.coins,
			"Faltam %d moedas." % faltam,
			"Volte quando conseguir mais!"
		]


		DialogManager.start_message(
			global_position + Vector2(0.0, -70.0),
			falas_erro,
			self
		)


		await esperar_dialogo()


	# =====================================================
	# VOLTAR PARA A LOJA
	# =====================================================

	if not is_inside_tree():
		return


	estado = EstadoLoja.PRONTA_PARA_COMPRAR

	bloqueado = false

	aviso.text = "[E] COMPRAR VIDA - 10 MOEDAS"

	aviso.show()
