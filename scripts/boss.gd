extends Area2D
# ============================================================
# BOSS.GD - BATALHA FINAL
# ============================================================
signal boss_health_changed(
	current_health: int,
	maximum_health: int
)
# ============================================================
# CONFIGURAÇÃO
# ============================================================
const MAX_HEALTH: int = 100
const DAMAGE_PER_SUCCESS: int = 20
const TOTAL_CHALLENGES: int = 5
const BOSS_SCORE_REWARD: int = 5000
const BOSS_HEAL_ON_FAILURE: int = 20
const FATIGUE_TIME: float = 15.0
const EXHAUSTED_TIME: float = 30.0
const TALK_DISTANCE: float = 70.0
const CHALLENGE_DISTANCE: float = 70.0
# ============================================================
# PORTAL DO WORLD-04
# ============================================================
# O portal só libera o World-05 depois que a mensagem final
# da vitória do boss terminar.
const BOSS_DEFEATED_META: String = "world_04_boss_defeated"
# ============================================================
# POSIÇÃO DO HUD
# ============================================================
const HUD_POSITION: Vector2 = Vector2(
	12.0,
	12.0
)
# ============================================================
# DESAFIOS
# ============================================================
const LOGIC_CHALLENGE: String = (
	"sequence_double"
)
const FUN_CHALLENGE_POOL: Array[String] = [
	"attention_red",
	"attention_blue",
	"memory_numbers",
	"memory_words"
]
# ============================================================
# ORDEM DOS DESAFIOS
# ============================================================
var challenge_order: Array[String] = []
# ============================================================
# ESTADOS
# ============================================================
enum BossState {
	WAITING,
	DIALOGUE,
	CHASE,
	EXHAUSTED,
	CHALLENGE,
	VICTORY
}
var state: BossState = BossState.WAITING
# ============================================================
# PLAYER
# ============================================================
var player: Node2D = null
var player_was_frozen_for_dialogue: bool = false
var player_waiting_for_dialogue_landing: bool = false
# ============================================================
# BOSS
# ============================================================
var boss_visual: CharacterBody2D = null
var boss_sprite: AnimatedSprite2D = null
# ============================================================
# CONTROLLERS
# ============================================================
var dialogue_controller: Node = null
var challenge_manager: Node = null
# ============================================================
# BATALHA
# ============================================================
var current_health: int = MAX_HEALTH
var challenge_index: int = 0
var fatigue_time_left: float = 0.0
var exhausted_time_left: float = 0.0
var fight_started: bool = false
var waiting_for_challenge: bool = false
# ============================================================
# PROMPT
# ============================================================
var boss_prompt: Label = null
# ============================================================
# HUD
# ============================================================
var hud_canvas: CanvasLayer = null
var hud_panel: Panel = null
var hud_name: Label = null
var hud_phase: Label = null
var hud_fatigue_label: Label = null
var hud_fatigue_value: Label = null
var hud_bar: ProgressBar = null
var hud_value: Label = null
# ============================================================
# READY
# ============================================================
func _ready() -> void:
	# Ao entrar/reiniciar o World-04, o boss começa vivo novamente.
	# O portal ficará bloqueado até a vitória desta batalha.
	get_tree().set_meta(
		BOSS_DEFEATED_META,
		false
	)
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 1
	# ========================================================
	# MUITO IMPORTANTE:
	# O BOSS COMEÇA SEM PODER DAR DANO.
	# ========================================================
	_set_boss_attack_enabled(false)
	_set_boss_damage_enabled(false)
	_set_boss_stomp_enabled(false)
	# ========================================================
	# PREPARAÇÃO
	# ========================================================
	_build_challenge_order()
	_find_player()
	_spawn_existing_boss()
	_create_or_get_controllers()
	_create_boss_prompt()
	_create_hud()
	_connect_signals()
	if (
		challenge_manager != null
		and
		challenge_manager.has_method(
			"set_external_start_prompt"
		)
	):
		challenge_manager.call(
			"set_external_start_prompt",
			true
		)
	_set_boss_prompt_visible(false)
	_set_hud_visible(false)
	_update_health_ui()
	print(
		"================================"
	)
	print(
		"BOSS FINAL INICIADO"
	)
	print(
		"VIDA: ",
		MAX_HEALTH
	)
	print(
		"DESAFIOS: ",
		TOTAL_CHALLENGES
	)
	print(
		"ORDEM: ",
		challenge_order
	)
	print(
		"DANO DO BOSS: DESATIVADO"
	)
	print(
		"================================"
	)
# ============================================================
# PROCESS
# ============================================================
func _process(
	delta: float
) -> void:
	_find_player_if_needed()
	match state:
		BossState.WAITING:
			_process_waiting()
		BossState.DIALOGUE:
			_process_dialogue_landing()
		BossState.CHASE:
			_process_chase(delta)
		BossState.EXHAUSTED:
			_process_exhausted(delta)
		BossState.CHALLENGE:
			pass
		BossState.VICTORY:
			pass
# ============================================================
# INPUT
# ============================================================
func _unhandled_input(
	event: InputEvent
) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = (
		event as InputEventKey
	)
	if not key_event.pressed:
		return
	if key_event.echo:
		return
	var is_e: bool = (
		key_event.keycode == KEY_E
		or
		key_event.physical_keycode == KEY_E
	)
	if not is_e:
		return
	# ========================================================
	# FALAR
	# ========================================================
	if (
		state == BossState.WAITING
		and
		not fight_started
		and
		_is_player_close_to_boss(
			TALK_DISTANCE
		)
	):
		get_viewport().set_input_as_handled()
		_start_intro()
		return
	# ========================================================
	# DESAFIO
	# ========================================================
	if (
		state == BossState.EXHAUSTED
		and
		waiting_for_challenge
		and
		_is_player_close_to_boss(
			CHALLENGE_DISTANCE
		)
	):
		get_viewport().set_input_as_handled()
		_start_current_challenge()
		return
# ============================================================
# PLAYER
# ============================================================
func _find_player() -> void:
	var found: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)
	if found is Node2D:
		player = (
			found as Node2D
		)
		return
	var scene: Node = (
		get_tree().current_scene
	)
	if scene != null:
		var direct_player: Node = (
			scene.get_node_or_null(
				"player"
			)
		)
		if direct_player is Node2D:
			player = (
				direct_player as Node2D
			)
func _find_player_if_needed() -> void:
	if is_instance_valid(player):
		return
	_find_player()
func _is_player_close_to_boss(
	distance_limit: float
) -> bool:
	if not is_instance_valid(player):
		return false
	if not is_instance_valid(boss_visual):
		return false
	var distance: float = (
		player.global_position.distance_to(
			boss_visual.global_position
		)
	)
	return distance <= distance_limit
# ============================================================
# CONGELAR PINGUIM NO DIÁLOGO
# ============================================================
func _freeze_player_for_dialogue() -> void:
	if not is_instance_valid(player):
		return
	if player_was_frozen_for_dialogue:
		return
	player_was_frozen_for_dialogue = true
	# --------------------------------------------------------
	# SE O PINGUIM ESTIVER NO AR:
	# NÃO CORTA A QUEDA.
	# --------------------------------------------------------
	var player_body: CharacterBody2D = (
		player
		if player is CharacterBody2D
		else null
	)
	if (
		player_body != null
		and
		not player_body.is_on_floor()
	):
		player_waiting_for_dialogue_landing = true
		# Para somente o movimento horizontal.
		# A gravidade e a animação de queda continuam.
		player_body.velocity.x = 0.0
		if "can_move" in player:
			player.set(
				"can_move",
				false
			)
		return
	# --------------------------------------------------------
	# SE JÁ ESTÁ NO CHÃO:
	# congela imediatamente.
	# --------------------------------------------------------
	player_waiting_for_dialogue_landing = false
	if "velocity" in player:
		var current_velocity = (
			player.get(
				"velocity"
			)
		)
		if current_velocity is Vector2:
			player.set(
				"velocity",
				Vector2.ZERO
			)
	if "can_move" in player:
		player.set(
			"can_move",
			false
		)
	player.set_process(false)
	player.set_physics_process(false)
	if player.has_method(
		"finalizar_queda_dialogo"
	):
		player.call(
			"finalizar_queda_dialogo"
		)
	else:
		_stop_all_player_animations(
			player
		)
func _process_dialogue_landing() -> void:
	if not player_waiting_for_dialogue_landing:
		return
	if not is_instance_valid(player):
		player_waiting_for_dialogue_landing = false
		return
	var player_body: CharacterBody2D = (
		player
		if player is CharacterBody2D
		else null
	)
	if player_body == null:
		player_waiting_for_dialogue_landing = false
		return
	# Ainda está caindo.
	if not player_body.is_on_floor():
		player_body.velocity.x = 0.0
		return
	# --------------------------------------------------------
	# TERMINOU A QUEDA.
	# Agora sim congela completamente.
	# --------------------------------------------------------
	player_waiting_for_dialogue_landing = false
	player_body.velocity = Vector2.ZERO
	if "can_move" in player:
		player.set(
			"can_move",
			false
		)
	player.set_process(false)
	player.set_physics_process(false)
	if player.has_method(
		"finalizar_queda_dialogo"
	):
		player.call(
			"finalizar_queda_dialogo"
		)
	else:
		_stop_all_player_animations(
			player
		)
func _unfreeze_player_after_dialogue() -> void:
	if not is_instance_valid(player):
		return
	if not player_was_frozen_for_dialogue:
		return
	player.set_process(true)
	player.set_physics_process(true)
	if "can_move" in player:
		player.set(
			"can_move",
			true
		)
	if "velocity" in player:
		var current_velocity = (
			player.get(
				"velocity"
			)
		)
		if current_velocity is Vector2:
			player.set(
				"velocity",
				Vector2.ZERO
			)
	if player.has_method(
		"restaurar_animacao_normal"
	):
		player.call(
			"restaurar_animacao_normal"
		)
	player_was_frozen_for_dialogue = false
	player_waiting_for_dialogue_landing = false
func _stop_all_player_animations(
	node: Node
) -> void:
	if node == null:
		return
	if node is AnimatedSprite2D:
		var animated: AnimatedSprite2D = (
			node as AnimatedSprite2D
		)
		animated.stop()
	for child: Node in node.get_children():
		_stop_all_player_animations(
			child
		)
# ============================================================
# ORDEM DOS DESAFIOS
# ============================================================
func _build_challenge_order() -> void:
	challenge_order.clear()

	# Temos exatamente 5 desafios:
	# 1 de raciocinio + 2 de atencao (Stroop) + 2 de memoria.
	var fun_selected: Array[String] = (
		FUN_CHALLENGE_POOL.duplicate()
	)

	# Embaralha os 4 desafios sem repetir nenhum.
	fun_selected.shuffle()

	# Coloca o desafio de raciocinio em uma posicao aleatoria.
	var logic_position: int = (
		randi_range(
			0,
			TOTAL_CHALLENGES - 1
		)
	)

	var fun_index: int = 0

	for i: int in range(
		TOTAL_CHALLENGES
	):

		if i == logic_position:
			challenge_order.append(
				LOGIC_CHALLENGE
			)
		else:
			challenge_order.append(
				fun_selected[fun_index]
			)
			fun_index += 1

	print(
		"BOSS: ordem sorteada = ",
		challenge_order
	)

# ============================================================
# SPAWN
# ============================================================
func _spawn_existing_boss() -> void:
	var existing: Node = (
		get_parent().get_node_or_null(
			"boss inimigo"
		)
	)
	if existing == null:
		var candidates: Array[Node] = (
			get_tree().get_nodes_in_group(
				"boss"
			)
		)
		for candidate: Node in candidates:
			if candidate is CharacterBody2D:
				existing = candidate
				break
	if existing == null:
		var boss_scene: PackedScene = (
			load(
				"res://actors/boss.tscn"
			)
			as PackedScene
		)
		if boss_scene == null:
			push_error(
				"BOSS: não encontrei "
				+
				"res://actors/boss.tscn"
			)
			return
		existing = (
			boss_scene.instantiate()
		)
		if existing == null:
			return
		existing.name = (
			"boss inimigo"
		)
		get_parent().add_child(
			existing
		)
		if existing is Node2D:
			var existing_2d: Node2D = (
				existing as Node2D
			)
			existing_2d.global_position = (
				_get_spawn_position()
			)
	if not (
		existing is CharacterBody2D
	):
		push_error(
			"BOSS: boss precisa ser CharacterBody2D."
		)
		return
	boss_visual = (
		existing as CharacterBody2D
	)
	boss_visual.global_position = (
		_get_spawn_position()
	)
	boss_visual.visible = true
	boss_visual.z_index = 20
	boss_visual.set_physics_process(
		true
	)
	boss_sprite = (
		boss_visual.get_node_or_null(
			"AnimatedSprite2D"
		)
		as AnimatedSprite2D
	)
	if boss_sprite != null:
		boss_sprite.visible = true
		boss_sprite.modulate = Color.WHITE
	if boss_visual.has_method(
		"set_boss_health"
	):
		boss_visual.call(
			"set_boss_health",
			MAX_HEALTH
		)
	# ========================================================
	# GARANTE QUE O BOSS COMEÇA SEM DANO
	# ========================================================
	_set_boss_attack_enabled(false)
	_set_boss_damage_enabled(false)
	_set_boss_stomp_enabled(false)
	if boss_visual.has_method(
		"freeze_boss"
	):
		boss_visual.call(
			"freeze_boss"
		)
func _get_spawn_position() -> Vector2:
	var shape: CollisionShape2D = (
		get_node_or_null(
			"CollisionShape2D"
		)
		as CollisionShape2D
	)
	if shape != null:
		return shape.global_position
	return global_position
# ============================================================
# CONTROLLERS
# ============================================================
func _create_or_get_controllers() -> void:
	dialogue_controller = (
		get_node_or_null(
			"BossDialogue"
		)
	)
	if dialogue_controller == null:
		dialogue_controller = Node.new()
		dialogue_controller.name = (
			"BossDialogue"
		)
		var dialogue_script: Script = (
			load(
				"res://scripts/boss_dialogue.gd"
			)
			as Script
		)
		if dialogue_script != null:
			dialogue_controller.set_script(
				dialogue_script
			)
		add_child(
			dialogue_controller
		)
	challenge_manager = (
		get_node_or_null(
			"BossChallengeManager"
		)
	)
	if challenge_manager == null:
		challenge_manager = Node.new()
		challenge_manager.name = (
			"BossChallengeManager"
		)
		var challenge_script: Script = (
			load(
				"res://scripts/"
				+
				"boss_challenge_manager.gd"
			)
			as Script
		)
		if challenge_script != null:
			challenge_manager.set_script(
				challenge_script
			)
		add_child(
			challenge_manager
		)
	if (
		dialogue_controller != null
		and
		dialogue_controller.has_method(
			"setup"
		)
	):
		dialogue_controller.call(
			"setup",
			boss_visual
		)
# ============================================================
# SINAIS
# ============================================================
func _connect_signals() -> void:
	if dialogue_controller != null:
		if not dialogue_controller.is_connected(
			"intro_finished",
			Callable(
				self,
				"_on_intro_finished"
			)
		):
			dialogue_controller.connect(
				"intro_finished",
				Callable(
					self,
					"_on_intro_finished"
				)
			)
		if not dialogue_controller.is_connected(
			"victory_finished",
			Callable(
				self,
				"_on_victory_finished"
			)
		):
			dialogue_controller.connect(
				"victory_finished",
				Callable(
					self,
					"_on_victory_finished"
				)
			)
	if challenge_manager != null:
		if not challenge_manager.is_connected(
			"challenge_finished",
			Callable(
				self,
				"_on_challenge_finished"
			)
		):
			challenge_manager.connect(
				"challenge_finished",
				Callable(
					self,
					"_on_challenge_finished"
				)
			)
	if boss_visual != null:
		if boss_visual.has_signal(
			"boss_health_changed"
		):
			if not boss_visual.is_connected(
				"boss_health_changed",
				Callable(
					self,
					"_on_boss_health_changed"
				)
			):
				boss_visual.connect(
					"boss_health_changed",
					Callable(
						self,
						"_on_boss_health_changed"
					)
				)
		if boss_visual.has_signal(
			"boss_defeated"
		):
			if not boss_visual.is_connected(
				"boss_defeated",
				Callable(
					self,
					"_on_boss_defeated"
				)
			):
				boss_visual.connect(
					"boss_defeated",
					Callable(
						self,
						"_on_boss_defeated"
					)
				)
# ============================================================
# WAITING
# ============================================================
func _process_waiting() -> void:
	if fight_started:
		if boss_prompt != null:
			boss_prompt.hide()
		return
	if boss_prompt == null:
		_create_boss_prompt()
	if not _is_player_close_to_boss(
		TALK_DISTANCE
	):
		boss_prompt.hide()
		return
	boss_prompt.text = (
		"[ E ] FALAR COM O CHEFE"
	)
	boss_prompt.show()
	_update_boss_prompt_position()
# ============================================================
# COMEÇA DIÁLOGO
# ============================================================
func _start_intro() -> void:
	if fight_started:
		return
	if state != BossState.WAITING:
		return
	fight_started = true
	state = BossState.DIALOGUE
	_set_boss_prompt_visible(false)
	_set_hud_visible(false)
	# --------------------------------------------------------
	# PLAYER PARADO
	# --------------------------------------------------------
	_set_player_can_move(false)
	_freeze_player_for_dialogue()
	# --------------------------------------------------------
	# BOSS SEM DANO
	# --------------------------------------------------------
	_set_boss_attack_enabled(false)
	_set_boss_damage_enabled(false)
	_set_boss_stomp_enabled(false)
	if (
		is_instance_valid(boss_visual)
		and
		boss_visual.has_method(
			"freeze_boss"
		)
	):
		boss_visual.call(
			"freeze_boss"
		)
	if (
		dialogue_controller != null
		and
		dialogue_controller.has_method(
			"start_intro"
		)
	):
		dialogue_controller.call(
			"start_intro"
		)
	else:
		_on_intro_finished()
# ============================================================
# DIÁLOGO ACABOU
# ============================================================
func _on_intro_finished() -> void:
	_unfreeze_player_after_dialogue()
	_set_hud_visible(true)
	_set_player_can_move(true)
	_start_chase()
# ============================================================
# COMEÇA COMBATE
# ============================================================
func _start_chase() -> void:
	if state == BossState.VICTORY:
		return
	state = BossState.CHASE
	fatigue_time_left = (
		FATIGUE_TIME
	)
	_set_boss_attack_enabled(true)
	# ========================================================
	# AQUI O BOSS VOLTA A PODER DAR DANO
	# ========================================================
	_set_boss_damage_enabled(true)
	_set_boss_stomp_enabled(false)
	_set_boss_prompt_visible(false)
	if (
		is_instance_valid(boss_visual)
		and
		boss_visual.has_method(
			"unfreeze_boss"
		)
	):
		boss_visual.call(
			"unfreeze_boss"
		)
	_update_phase_ui()
# ============================================================
# PROCESSA COMBATE
# ============================================================
func _process_chase(
	delta: float
) -> void:
	if state != BossState.CHASE:
		return
	fatigue_time_left -= delta
	_update_phase_ui()
	if fatigue_time_left <= 0.0:
		fatigue_time_left = 0.0
		_start_exhausted()
# ============================================================
# BOSS CANSOU
# ============================================================
func _start_exhausted() -> void:
	if state != BossState.CHASE:
		return
	state = BossState.EXHAUSTED
	waiting_for_challenge = true
	exhausted_time_left = (
		EXHAUSTED_TIME
	)
	# ========================================================
	# DURANTE A ESPERA DO DESAFIO:
	# BOSS NÃO PODE DAR DANO
	# ========================================================
	_set_boss_attack_enabled(false)
	_set_boss_damage_enabled(false)
	_set_boss_stomp_enabled(false)
	if (
		is_instance_valid(boss_visual)
		and
		boss_visual.has_method(
			"freeze_boss_after_landing"
		)
	):
		boss_visual.call(
			"freeze_boss_after_landing"
		)
	_update_exhausted_prompt()
	_update_phase_ui()
# ============================================================
# PROCESSA CANSADO
# ============================================================
func _process_exhausted(
	delta: float
) -> void:
	if state != BossState.EXHAUSTED:
		return
	_update_exhausted_prompt()
	if _is_player_close_to_boss(
		CHALLENGE_DISTANCE
	):
		exhausted_time_left = max(
			exhausted_time_left,
			5.0
		)
	exhausted_time_left -= delta
	if exhausted_time_left <= 0.0:
		waiting_for_challenge = false
		_set_boss_prompt_visible(false)
		_start_chase()
# ============================================================
# INICIAR DESAFIO
# ============================================================
func _start_current_challenge() -> void:
	if state != BossState.EXHAUSTED:
		return
	if not _is_player_close_to_boss(
		CHALLENGE_DISTANCE
	):
		return
	if challenge_manager == null:
		return
	# Quando os 5 desafios da rodada terminarem,
	# sorteia uma nova rodada e continua a luta.
	if challenge_index >= TOTAL_CHALLENGES:
		_build_challenge_order()
		challenge_index = 0
	waiting_for_challenge = false
	state = BossState.CHALLENGE
	# ========================================================
	# DURANTE O DESAFIO:
	# BOSS NÃO CAUSA DANO
	# ========================================================
	_set_boss_prompt_visible(false)
	_set_boss_attack_enabled(false)
	_set_boss_damage_enabled(false)
	_set_boss_stomp_enabled(false)
	_set_player_can_move(false)
	if (
		is_instance_valid(boss_visual)
		and
		boss_visual.has_method(
			"freeze_boss_after_landing"
		)
	):
		boss_visual.call(
			"freeze_boss_after_landing"
		)
	var challenge_type: String = (
		challenge_order[
			challenge_index
		]
	)
	print(
		"BOSS: desafio ",
		challenge_index + 1,
		"/",
		TOTAL_CHALLENGES,
		" = ",
		challenge_type
	)
	if challenge_manager.has_method(
		"prepare_challenge"
	):
		challenge_manager.call(
			"prepare_challenge",
			challenge_type,
			challenge_index
		)
	if challenge_manager.has_method(
		"start_current_challenge"
	):
		challenge_manager.call(
			"start_current_challenge"
		)
# ============================================================
# FIM DO DESAFIO
# ============================================================
func _on_challenge_finished(
	correct: bool,
	_challenge_type: String
) -> void:
	if state != BossState.CHALLENGE:
		return

	if correct:
		# DESAFIO CERTO: o boss perde 20 de vida.
		if (
			is_instance_valid(boss_visual)
			and
			boss_visual.has_method(
				"take_boss_damage"
			)
		):
			boss_visual.call(
				"take_boss_damage",
				DAMAGE_PER_SUCCESS
			)

		_update_health_from_boss()

		# SOMENTE ACERTO avanca para o proximo desafio.
		# Se errar, o mesmo desafio continua sendo o desafio atual
		# ate o jogador acertar.
		challenge_index += 1

		# Se a vida chegou a zero, encerra a luta imediatamente.
		if current_health <= 0:
			_on_boss_defeated()
			return

	else:
		# DESAFIO ERRADO: o boss recupera 20 de vida.
		# A recuperação é limitada à vida máxima.
		if (
			is_instance_valid(boss_visual)
			and
			boss_visual.has_method(
				"heal_boss"
			)
		):
			boss_visual.call(
				"heal_boss",
				BOSS_HEAL_ON_FAILURE
			)

		_update_health_from_boss()

		# ERRO: volta exatamente 1 desafio, mas nunca abaixo do 1/5.
		# Ex.: 3/5 -> 2/5. No primeiro, continua 1/5.
		challenge_index = max(
			challenge_index - 1,
			0
		)

	_set_player_can_move(true)
	_start_chase()
# ============================================================
# VIDA
# ============================================================
func _on_boss_health_changed(
	current: int,
	_maximum: int
) -> void:
	current_health = current
	_update_health_ui()
func _update_health_from_boss() -> void:
	if not is_instance_valid(
		boss_visual
	):
		return
	if boss_visual.has_method(
		"get_current_health"
	):
		current_health = int(
			boss_visual.call(
				"get_current_health"
			)
		)
	_update_health_ui()
# ============================================================
# MORTE
# ============================================================
func _on_boss_defeated() -> void:
	if state == BossState.VICTORY:
		return

	# ========================================================
	# RECOMPENSA POR DERROTAR O BOSS
	# ========================================================
	# Os 5.000 pontos entram no score da fase atual.
	# O sistema de score total poderá somá-los junto com o
	# restante da fase quando ela for concluída.
	Globals.score += BOSS_SCORE_REWARD

	state = BossState.VICTORY
	waiting_for_challenge = false
	_set_boss_attack_enabled(false)
	_set_boss_damage_enabled(false)
	_set_boss_stomp_enabled(false)
	_set_boss_prompt_visible(false)
	# O player estava travado durante o desafio.
	# Ao derrotar o boss, ele precisa voltar a andar.
	_set_player_can_move(true)
	if is_instance_valid(player):
		if player.has_method(
			"restaurar_animacao_normal"
		):
			player.call(
				"restaurar_animacao_normal"
			)
	# NÃO congelamos o boss aqui.
	# Ele já está morto e mantendo a animação "hurt"
	# até o fim do diálogo.
	if (
		dialogue_controller != null
		and
		dialogue_controller.has_method(
			"start_victory"
		)
	):
		dialogue_controller.call(
			"start_victory"
		)
	else:
		_finish_victory()
func _on_victory_finished() -> void:
	_finish_victory()
func _finish_victory() -> void:
	# ========================================================
	# PORTAL DO WORLD-04 LIBERADO
	# ========================================================
	# Só chega aqui depois que TODAS as mensagens de vitória
	# foram lidas/fechadas.
	get_tree().set_meta(
		BOSS_DEFEATED_META,
		true
	)
	# Esta função só é chamada quando o BossDialogue
	# informa que todas as mensagens acabaram.
	_set_boss_prompt_visible(false)
	_set_hud_visible(false)
	_set_player_can_move(true)
	if is_instance_valid(player):
		if player.has_method(
			"restaurar_animacao_normal"
		):
			player.call(
				"restaurar_animacao_normal"
			)
	# O boss só some AGORA, depois que o último
	# texto de derrota foi lido/fechado.
	if is_instance_valid(
		boss_visual
	):
		boss_visual.call_deferred(
			"queue_free"
		)
# ============================================================
# PLAYER MOVIMENTO
# ============================================================
func _set_player_can_move(
	enabled: bool
) -> void:
	if not is_instance_valid(
		player
	):
		_find_player_if_needed()
	if not is_instance_valid(
		player
	):
		return
	if "can_move" in player:
		player.set(
			"can_move",
			enabled
		)
	if (
		not enabled
		and
		"velocity" in player
	):
		var current_velocity = (
			player.get(
				"velocity"
			)
		)
		if current_velocity is Vector2:
			# Quando o player estiver no ar,
			# não mata a velocidade vertical.
			# Assim ele termina a queda normalmente.
			if player is CharacterBody2D and not player.is_on_floor():
				player.set(
					"velocity",
					Vector2(0.0, current_velocity.y)
				)
			else:
				player.set(
					"velocity",
					Vector2.ZERO
				)
# ============================================================
# CONTROLE DO BOSS
# ============================================================
func _set_boss_attack_enabled(
	enabled: bool
) -> void:
	if not is_instance_valid(
		boss_visual
	):
		return
	if boss_visual.has_method(
		"set_attack_enabled"
	):
		boss_visual.call(
			"set_attack_enabled",
			enabled
		)
func _set_boss_damage_enabled(
	enabled: bool
) -> void:
	if not is_instance_valid(
		boss_visual
	):
		return
	if boss_visual.has_method(
		"set_damage_enabled"
	):
		boss_visual.call(
			"set_damage_enabled",
			enabled
		)
func _set_boss_stomp_enabled(
	enabled: bool
) -> void:
	if not is_instance_valid(
		boss_visual
	):
		return
	if boss_visual.has_method(
		"set_stomp_enabled"
	):
		boss_visual.call(
			"set_stomp_enabled",
			enabled
		)
# ============================================================
# PROMPT
# ============================================================
func _create_boss_prompt() -> void:
	if boss_prompt != null:
		return
	boss_prompt = Label.new()
	boss_prompt.name = (
		"BossPrompt"
	)
	boss_prompt.text = (
		"[ E ] FALAR COM O CHEFE"
	)
	boss_prompt.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	boss_prompt.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	boss_prompt.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	boss_prompt.size = Vector2(
		180,
		22
	)
	boss_prompt.position = Vector2(
		-90,
		-48
	)
	boss_prompt.add_theme_font_size_override(
		"font_size",
		6
	)
	boss_prompt.add_theme_color_override(
		"font_color",
		Color("#F8F5FF")
	)
	boss_prompt.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)
	boss_prompt.add_theme_constant_override(
		"outline_size",
		2
	)
	boss_prompt.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	_apply_font(
		boss_prompt
	)
	if is_instance_valid(
		boss_visual
	):
		boss_visual.add_child(
			boss_prompt
		)
	boss_prompt.hide()
func _update_boss_prompt_position() -> void:
	if boss_prompt == null:
		return
	boss_prompt.position = Vector2(
		-93,
		-32
	)
func _update_exhausted_prompt() -> void:
	if boss_prompt == null:
		_create_boss_prompt()
	if boss_prompt == null:
		return
	if state != BossState.EXHAUSTED:
		boss_prompt.hide()
		return
	if not waiting_for_challenge:
		boss_prompt.hide()
		return
	_update_boss_prompt_position()
	# ========================================================
	# LONGE DO CHEFE
	# ========================================================
	if not _is_player_close_to_boss(
		CHALLENGE_DISTANCE
	):
		boss_prompt.text = (
			"CHEGUE PERTO DO CHEFE"
		)
		boss_prompt.show()
		return
	# ========================================================
	# PERTO DO CHEFE
	# ========================================================
	boss_prompt.text = (
		"[ E ] INICIAR DESAFIO"
	)
	boss_prompt.show()
func _set_boss_prompt_visible(
	visible_value: bool
) -> void:
	if boss_prompt == null:
		return
	if visible_value:
		_update_boss_prompt_position()
		boss_prompt.show()
	else:
		boss_prompt.hide()
# ============================================================
# HUD
# ============================================================
func _create_hud() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.layer = 100
	add_child(
		hud_canvas
	)
	hud_panel = Panel.new()
	hud_panel.position = (
		HUD_POSITION
	)
	hud_panel.size = Vector2(
		440,
		100
	)
	hud_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			Color("#120D1B"),
			Color("#8E4EDB"),
			2,
			8
		)
	)
	hud_canvas.add_child(
		hud_panel
	)
	# ========================================================
	# NOME
	# ========================================================
	hud_name = _make_label(
		"GUARDIÃO COGNITIVO",
		14,
		Color("#F8F5FF")
	)
	hud_name.position = Vector2(
		12,
		8
	)
	hud_name.size = Vector2(
		230,
		22
	)
	hud_panel.add_child(
		hud_name
	)
	# ========================================================
	# BARRA
	# ========================================================
	hud_bar = ProgressBar.new()
	hud_bar.position = Vector2(
		12,
		38
	)
	hud_bar.size = Vector2(
		290,
		18
	)
	hud_bar.min_value = 0
	hud_bar.max_value = MAX_HEALTH
	hud_bar.value = MAX_HEALTH
	hud_bar.show_percentage = false
	hud_bar.add_theme_stylebox_override(
		"background",
		_make_panel_style(
			Color("#251B31"),
			Color("#3D2A51"),
			1,
			4
		)
	)
	hud_bar.add_theme_stylebox_override(
		"fill",
		_make_panel_style(
			Color("#8E4EDB"),
			Color("#C39BFF"),
			0,
			4
		)
	)
	hud_panel.add_child(
		hud_bar
	)
	# ========================================================
	# VIDA
	# ========================================================
	hud_value = _make_label(
		"100 / 100",
		11,
		Color("#C39BFF")
	)
	hud_value.position = Vector2(
		315,
		35
	)
	hud_value.size = Vector2(
		110,
		22
	)
	hud_value.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	hud_panel.add_child(
		hud_value
	)
	# ========================================================
	# DESAFIO
	# ========================================================
	hud_phase = _make_label(
		"DESAFIO 1/5",
		9,
		Color("#BDB5C9")
	)
	hud_phase.position = Vector2(
		12,
		68
	)
	hud_phase.size = Vector2(
		145,
		18
	)
	hud_panel.add_child(
		hud_phase
	)
	# ========================================================
	# CANSANDO
	# ========================================================
	hud_fatigue_label = _make_label(
		"CANSANDO:",
		9,
		Color("#BDB5C9")
	)
	hud_fatigue_label.position = Vector2(
		175,
		68
	)
	hud_fatigue_label.size = Vector2(
		80,
		18
	)
	hud_panel.add_child(
		hud_fatigue_label
	)
	# ========================================================
	# TEMPO
	# ========================================================
	hud_fatigue_value = _make_label(
		"15 s",
		9,
		Color("#C39BFF")
	)
	hud_fatigue_value.position = Vector2(
		250,
		68
	)
	hud_fatigue_value.size = Vector2(
		55,
		18
	)
	hud_fatigue_value.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)
	hud_panel.add_child(
		hud_fatigue_value
	)
# ============================================================
# VIDA HUD
# ============================================================
func _update_health_ui() -> void:
	if hud_bar != null:
		hud_bar.value = (
			current_health
		)
	if hud_value != null:
		hud_value.text = (
			"%d / %d"
			% [
				current_health,
				MAX_HEALTH
			]
		)
	_update_phase_ui()
	boss_health_changed.emit(
		current_health,
		MAX_HEALTH
	)
# ============================================================
# HUD FASE
# ============================================================
func _update_phase_ui() -> void:
	if hud_phase == null:
		return
	# O HUD nunca passa de 5/5.
	# O indice interno pode chegar a 5 antes da nova rodada ser
	# iniciada, mas o contador visual deve continuar valido.
	var number: int = (
		(challenge_index % TOTAL_CHALLENGES) + 1
	)
	if state == BossState.CHASE:
		hud_phase.text = (
			"DESAFIO %d/5"
			% number
		)
		if hud_fatigue_value != null:
			hud_fatigue_value.text = (
				"%d s"
				% int(
					ceil(
						fatigue_time_left
					)
				)
			)
		return
	if state == BossState.EXHAUSTED:
		hud_phase.text = (
			"INICIAR %d/5"
			% number
		)
		if hud_fatigue_value != null:
			hud_fatigue_value.text = (
				"AGORA"
			)
		return
	if state == BossState.CHALLENGE:
		hud_phase.text = (
			"DESAFIO %d/5"
			% number
		)
		if hud_fatigue_value != null:
			hud_fatigue_value.text = (
				"PAUSADO"
			)
		return
	if state == BossState.WAITING:
		hud_phase.text = (
			"AGUARDANDO"
		)
		if hud_fatigue_value != null:
			hud_fatigue_value.text = (
				"--"
			)
		return
	if state == BossState.DIALOGUE:
		hud_phase.text = (
			"GUARDIÃO"
		)
		if hud_fatigue_value != null:
			hud_fatigue_value.text = (
				"--"
			)
		return
	if state == BossState.VICTORY:
		hud_phase.text = (
			"VITÓRIA"
		)
		if hud_fatigue_value != null:
			hud_fatigue_value.text = (
				"OK"
			)
# ============================================================
# HUD VISÍVEL
# ============================================================
func _set_hud_visible(
	visible_value: bool
) -> void:
	if hud_panel != null:
		hud_panel.visible = (
			visible_value
		)
# ============================================================
# FONTE
# ============================================================
func _make_label(
	text_value: String,
	size: int,
	color: Color
) -> Label:
	var label: Label = Label.new()
	label.text = (
		text_value
	)
	label.add_theme_font_size_override(
		"font_size",
		size
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
		2
	)
	label.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	_apply_font(
		label
	)
	return label
func _apply_font(
	control: Control
) -> void:
	var resource: Resource = (
		load(
			"res://assets/Fontes/Pixeloid_Font_1_0/"
			+ "OpenType (.otf)/PixeloidSans-Bold.otf"
		)
	)
	if resource != null:
		control.add_theme_font_override(
			"font",
			resource
		)
# ============================================================
# ESTILO
# ============================================================
func _make_panel_style(
	background: Color,
	border: Color,
	width: int,
	radius: int
) -> StyleBoxFlat:
	var style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)
	style.bg_color = (
		background
	)
	style.border_color = (
		border
	)
	style.set_border_width_all(
		width
	)
	style.set_corner_radius_all(
		radius
	)
	return style
