extends Node

# =========================================================
# MÚSICAS DO WORLD 04
# =========================================================

const MUSICA_MUNDO := preload(
	"res://sounds/mundos/mundo04_1.wav"
)

const MUSICA_BOSS := preload(
	"res://sounds/mundos/mundo04_2.wav"
)


# =========================================================
# VOLUME
# =========================================================

@export_range(-40.0, 5.0, 0.5)
var volume_mundo_db: float = -20.0

@export_range(-40.0, 5.0, 0.5)
var volume_boss_db: float = -15.0


# =========================================================
# PLAYERS DE ÁUDIO
# =========================================================

var audio_mundo: AudioStreamPlayer = null
var audio_boss: AudioStreamPlayer = null


# =========================================================
# CONTROLE
# =========================================================

var boss_music_active: bool = false

var boss_controller: Node = null

var search_timer: float = 0.0

const SEARCH_INTERVAL: float = 0.25


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS


	# =====================================================
	# MÚSICA NORMAL
	# =====================================================

	audio_mundo = AudioStreamPlayer.new()

	audio_mundo.name = "AudioMundo04"

	audio_mundo.stream = MUSICA_MUNDO

	audio_mundo.volume_db = volume_mundo_db

	audio_mundo.bus = "Master"

	audio_mundo.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(audio_mundo)


	if not audio_mundo.finished.is_connected(
		_on_mundo_finished
	):

		audio_mundo.finished.connect(
			_on_mundo_finished
	)


	# =====================================================
	# MÚSICA DO BOSS
	# =====================================================

	audio_boss = AudioStreamPlayer.new()

	audio_boss.name = "AudioBoss04"

	audio_boss.stream = MUSICA_BOSS

	audio_boss.volume_db = volume_boss_db

	audio_boss.bus = "Master"

	audio_boss.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(audio_boss)


	if not audio_boss.finished.is_connected(
		_on_boss_finished
	):

		audio_boss.finished.connect(
			_on_boss_finished
	)


	# =====================================================
	# GARANTE QUE NÃO EXISTE OUTRA MÚSICA 1 TOCANDO
	# =====================================================

	_stop_other_world_music_players()


	# =====================================================
	# COMEÇA COM A MÚSICA NORMAL
	# =====================================================

	boss_music_active = false

	audio_boss.stop()

	audio_mundo.play()


	# =====================================================
	# PROCURA O CONTROLADOR DO BOSS
	# =====================================================

	_find_boss_controller()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	# Se ainda não encontrou o boss,
	# continua procurando.
	if boss_controller == null:

		search_timer -= delta

		if search_timer <= 0.0:

			search_timer = SEARCH_INTERVAL

			_find_boss_controller()


	# Verifica o estado do boss.
	if boss_controller != null:

		_check_boss_state()


# =========================================================
# PROCURA O CONTROLADOR DO BOSS
# =========================================================

func _find_boss_controller() -> void:

	var current_scene := get_tree().current_scene

	if current_scene == null:
		return


	boss_controller = _find_boss_node(
		current_scene
	)


	if boss_controller != null:

		print(
			"MÚSICA WORLD 04: boss encontrado em ",
			boss_controller.get_path()
		)


# =========================================================
# PROCURA RECURSIVA PELO BOSS.GD
# =========================================================

func _find_boss_node(node: Node) -> Node:

	if node == self:
		return null


	if (
		node.has_method("_start_chase")
		and
		node.has_signal("boss_health_changed")
	):

		return node


	for child in node.get_children():

		var found := _find_boss_node(
			child
		)

		if found != null:

			return found


	return null


# =========================================================
# PROCURA E PARA OUTRAS MÚSICAS DO WORLD 04
# =========================================================
#
# Isso resolve o problema de existir um AudioStreamPlayer
# antigo na cena tocando mundo04_1.wav ao mesmo tempo.
#
# =========================================================

func _stop_other_world_music_players() -> void:

	var current_scene := get_tree().current_scene

	if current_scene == null:
		return


	_stop_world_music_recursive(
		current_scene
	)


func _stop_world_music_recursive(node: Node) -> void:

	if node is AudioStreamPlayer:

		var player := node as AudioStreamPlayer

		# Ignora o nosso próprio player.
		if player != audio_mundo and player != audio_boss:

			if player.stream != null:

				var stream_path := (
					player.stream.resource_path
				)

				if stream_path == (
					"res://sounds/mundos/mundo04_1.wav"
				):

					if player.playing:

						print(
							"MÚSICA WORLD 04: parando player duplicado: ",
							player.get_path()
						)

						player.stop()


	for child in node.get_children():

		_stop_world_music_recursive(
			child
		)


# =========================================================
# VERIFICA ESTADO DO BOSS
# =========================================================

func _check_boss_state() -> void:

	if not is_instance_valid(
		boss_controller
	):

		boss_controller = null

		return


	# =====================================================
	# ESTADO
	# =====================================================

	var state_variant: Variant = (
		boss_controller.get("state")
	)

	if state_variant == null:
		return


	var state_value: int = int(
		state_variant
	)


	# =====================================================
	# CHASE = BATALHA COMEÇOU
	# =====================================================

	if (
		state_value == 2
		and
		not boss_music_active
	):

		iniciar_batalha_boss()

		return


	# =====================================================
	# VICTORY_DIALOGUE / DEAD = BOSS DERROTADO
	# =====================================================

	if (
		(
			state_value == 6
			or
			state_value == 7
		)
		and
		boss_music_active
	):

		finalizar_batalha_boss()

		return


	# =====================================================
	# SEGURANÇA PELA VIDA
	# =====================================================

	var health_variant: Variant = (
		boss_controller.get("current_health")
	)

	if health_variant != null:

		var current_health := int(
			health_variant
		)

		if (
			current_health <= 0
			and
			boss_music_active
		):

			finalizar_batalha_boss()


# =========================================================
# LOOP DA MÚSICA NORMAL
# =========================================================

func _on_mundo_finished() -> void:

	if audio_mundo == null:
		return


	if not boss_music_active:

		audio_mundo.play()


# =========================================================
# LOOP DA MÚSICA DO BOSS
# =========================================================

func _on_boss_finished() -> void:

	if audio_boss == null:
		return


	if boss_music_active:

		audio_boss.play()


# =========================================================
# COMEÇA A BATALHA
# =========================================================

func iniciar_batalha_boss() -> void:

	if boss_music_active:
		return


	boss_music_active = true


	print(
		"MÚSICA WORLD 04: INICIANDO BATALHA DO BOSS"
	)


	# =====================================================
	# PARA TODAS AS OUTRAS MÚSICAS 1
	# =====================================================

	_stop_other_world_music_players()


	# =====================================================
	# PARA A NOSSA MÚSICA NORMAL
	# =====================================================

	if audio_mundo != null:

		audio_mundo.stop()


	# =====================================================
	# COMEÇA A MÚSICA DO BOSS
	# =====================================================

	if audio_boss != null:

		audio_boss.stop()

		audio_boss.play()


# =========================================================
# BOSS DERROTADO
# =========================================================

func finalizar_batalha_boss() -> void:

	if not boss_music_active:
		return


	boss_music_active = false


	print(
		"MÚSICA WORLD 04: BOSS DERROTADO"
	)


	# =====================================================
	# PARA A MÚSICA DO BOSS
	# =====================================================

	if audio_boss != null:

		audio_boss.stop()


	# =====================================================
	# GARANTE QUE NÃO EXISTE OUTRA MÚSICA 1 TOCANDO
	# =====================================================

	_stop_other_world_music_players()


	# =====================================================
	# VOLTA PARA A MÚSICA NORMAL
	# =====================================================

	if audio_mundo != null:

		audio_mundo.stop()

		audio_mundo.play()
