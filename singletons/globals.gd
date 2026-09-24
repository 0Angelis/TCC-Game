extends Node


# ==========================================
# MOEDAS / SCORE / VIDAS
# ==========================================

var coins := 0
var score := 0

# Pontuação total acumulada dos mundos concluídos.
# Diferente de "score", este valor não é zerado ao trocar de mundo.
var total_score := 0

# ==========================================
# TEMPO DE JOGO
# ==========================================
# total_play_time = tempo das fases já concluídas.
# level_play_time = tempo somente da fase atual.
# O tempo só é contado quando o cronômetro está ativo.
var total_play_time: float = 0.0
var level_play_time: float = 0.0
var gameplay_timer_running: bool = false
var gameplay_timer_paused: bool = true

# Cena usada para detectar quando uma fase terminou e outra começou.
var tracked_scene_path: String = ""

var player_life := 5

# ==========================================
# VIDA NO INÍCIO DA FASE ATUAL
# ==========================================
# Usado pelo RESTART do pause.
# O restart volta para a quantidade de vidas que existia
# quando o jogador entrou na fase, sem contar as vidas perdidas nela.
var lives_before_level := 5

# Caminho da cena usada para criar o snapshot acima.
# Impede que o _ready() do player sobrescreva o snapshot
# quando a mesma fase for apenas recarregada pelo RESTART.
var life_snapshot_scene := ""

# ==========================================
# ÚLTIMO MUNDO ANTES DA LOJA
# ==========================================

# 1 = mundo 01 -> loja -> mundo 02
# 2 = mundo 02 -> loja -> mundo 03
# 3 = mundo 03 -> loja -> mundo 04 (boss final)
var last_world_before_shop := 0


# ==========================================
# MOEDAS ANTES DO MAPA ATUAL
# ==========================================

var coins_before_level := 0


# ==========================================
# DADOS DA FASE ATUAL
# ==========================================

var level_coins := 0
var level_score := 0


# ==========================================
# FRAGMENTOS
# ==========================================

var raciocinio_fragments := 0
var atencao_fragments := 0
var memoria_fragments := 0

# ==========================================
# TEMPO DE JOGO - PROCESSO GLOBAL
# ==========================================

func _ready() -> void:

	# O cronometro precisa continuar executando quando a
	# SceneTree estiver pausada. A propria flag abaixo decide
	# se o tempo realmente deve ser contado.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:

	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	var current_path := current_scene.scene_file_path.to_lower()

	# Menus/telas que NÃO fazem parte do tempo de jogo.
	var is_non_gameplay_scene := (
		current_path.ends_with("title_screen.tscn")
		or current_path.ends_with("credits.tscn")
		or current_path.ends_with("game_over.tscn")
	)

	# IMPORTANTE:
	# Se o jogador iniciar diretamente uma fase pelo editor
	# (por exemplo, World 05), não dependemos do title_screen.gd
	# para ligar o cronômetro. A primeira cena jogável já inicia
	# a contagem automaticamente.
	if not is_non_gameplay_scene and not gameplay_timer_running:
		gameplay_timer_running = true
		gameplay_timer_paused = false
		tracked_scene_path = current_path
		level_play_time = 0.0

	# Guarda qual cena está sendo cronometrada.
	if tracked_scene_path == "":
		tracked_scene_path = current_path

	# Quando a cena muda normalmente, a fase anterior terminou.
	# Soma somente o tempo efetivamente jogado naquela fase.
	elif current_path != tracked_scene_path:
		if gameplay_timer_running:
			total_play_time += level_play_time

			print(
				"TEMPO DA FASE ADICIONADO: ",
				format_game_time(level_play_time),
				" | TEMPO TOTAL: ",
				format_game_time(total_play_time)
			)

		level_play_time = 0.0
		tracked_scene_path = current_path

	# Menus/telas fora da partida não contam.
	if not gameplay_timer_running:
		return

	# Qualquer pause da SceneTree também não conta tempo.
	# Isso cobre pause normal e telas de resultado/desafio.
	if gameplay_timer_paused or get_tree().paused:
		return

	if is_non_gameplay_scene:
		return

	level_play_time += delta


# ==========================================
# FINALIZA A FASE ATUAL MANUALMENTE
# ==========================================

func finalize_current_level_time() -> void:
	if not gameplay_timer_running:
		return

	total_play_time += level_play_time

	print(
		"TEMPO DA FASE FINAL ADICIONADO: ",
		format_game_time(level_play_time),
		" | TEMPO TOTAL: ",
		format_game_time(total_play_time)
	)

	level_play_time = 0.0
	gameplay_timer_paused = true

	# Mantém a cena atual como referência para não adicionar
	# o último trecho novamente na troca para os créditos.
	var current_scene := get_tree().current_scene
	if current_scene != null:
		tracked_scene_path = current_scene.scene_file_path.to_lower()


# ==========================================
# COMEÇA NOVA PARTIDA
# ==========================================

func start_new_game_timer() -> void:
	total_play_time = 0.0
	level_play_time = 0.0
	gameplay_timer_running = true
	gameplay_timer_paused = false
	tracked_scene_path = ""


# ==========================================
# PAUSAR / RETOMAR CRONÔMETRO
# ==========================================

func pause_game_timer() -> void:
	gameplay_timer_paused = true


func resume_game_timer() -> void:
	if gameplay_timer_running:
		gameplay_timer_paused = false


# ==========================================
# RESET SOMENTE DA FASE ATUAL
# ==========================================

func reset_current_level_timer() -> void:
	# Zera somente o tempo da cena/fase atual.
	# O total das cenas ja concluidas permanece intacto.
	level_play_time = 0.0
	gameplay_timer_paused = true

	# Mantem a cena atual como referencia para impedir que o tempo
	# descartado seja somado ao total durante o RESTART.
	var current_scene := get_tree().current_scene
	if current_scene != null:
		tracked_scene_path = current_scene.scene_file_path.to_lower()


# ==========================================
# PARA A CONTAGEM AO SAIR DA PARTIDA
# ==========================================

func stop_game_timer() -> void:
	gameplay_timer_running = false
	gameplay_timer_paused = true


# ==========================================
# FORMATA TEMPO
# ==========================================

func format_game_time(seconds: float) -> String:
	var total_seconds := maxi(
		0,
		int(floor(seconds))
	)

	var hours := int(total_seconds / 3600)
	var minutes := int((total_seconds % 3600) / 60)
	var secs := int(total_seconds % 60)

	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, secs]

	return "%02d:%02d" % [minutes, secs]
