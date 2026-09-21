extends Area2D

# ============================================================
# BOSS.GD — CONTROLADOR DA BATALHA FINAL
# ============================================================
# ESTE NÓ (BOSS) É APENAS O GATILHO DA PORTA.
# O inimigo real já existe no World-04 como:
#     boss inimigo (CharacterBody2D)
#
# O boss.gd:
# - usa o CollisionShape2D como ponto de spawn;
# - controla a lore;
# - conta ataques reais do boss;
# - faz 3 -> 5 -> 10 -> 10 ataques;
# - deixa o Player livre quando o boss cansa;
# - mostra o [E] acima da cabeça do boss;
# - abre o desafio somente quando o Player chega perto;
# - impede dano do boss antes do primeiro desafio.
# ============================================================

signal boss_health_changed(current_health: int, maximum_health: int)

const MAX_HEALTH: int = 120
const DAMAGE_PER_SUCCESS: int = 15
const EXHAUSTED_TIME: float = 10.0
const CHALLENGE_INTERACTION_DISTANCE: float = 78.0

const ATTACK_REQUIREMENTS: Array[int] = [3, 5, 10, 10]
const CHALLENGE_ORDER: Array[String] = ["logic", "attention", "memory", "mixed"]

const FONT_PATH: String = "res://assets/Fontes/Pixeloid_Font_1_0/OpenType (.otf)/PixeloidSans-Bold.otf"
const PURPLE: Color = Color("#8E4EDB")
const PURPLE_LIGHT: Color = Color("#C39BFF")
const PANEL: Color = Color("#120D1B")
const WHITE: Color = Color("#F8F5FF")
const MUTED: Color = Color("#BDB5C9")
const GREEN: Color = Color("#78E08F")
const RED: Color = Color("#FF6B7A")

enum BossState {
	WAITING,
	DIALOGUE,
	CHASE,
	EXHAUSTED,
	CHALLENGE,
	VICTORY
}

var state: BossState = BossState.WAITING

var player: Node2D = null
var player_inside: bool = false

var boss_visual: CharacterBody2D = null
var boss_sprite: AnimatedSprite2D = null

var dialogue_controller: Node = null
var challenge_manager: Node = null

var current_health: int = MAX_HEALTH
var challenge_index: int = 0
var attack_count: int = 0
var exhausted_time_left: float = 0.0

var fight_started: bool = false
var waiting_for_challenge: bool = false

var boss_prompt: Panel = null
var boss_prompt_text: Label = null
var boss_prompt_timer: Label = null

var hud_canvas: CanvasLayer = null
var hud_panel: Panel = null
var hud_phase: Label = null
var hud_bar: ProgressBar = null
var hud_value: Label = null


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 1

	_find_player()
	_create_or_get_controllers()
	_spawn_existing_boss()
	_create_boss_prompt()
	_create_hud()
	_connect_signals()

	_set_boss_damage_enabled(false)
	_set_boss_prompt_visible(false)
	_set_hud_visible(false)
	_update_health_ui()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	print("BOSS.GD pronto.")


func _process(delta: float) -> void:
	_find_player_if_needed()

	match state:
		BossState.WAITING:
			_process_waiting()

		BossState.DIALOGUE:
			pass

		BossState.CHASE:
			_process_chase()

		BossState.EXHAUSTED:
			_process_exhausted(delta)

		BossState.CHALLENGE:
			pass

		BossState.VICTORY:
			pass


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if DialogManager.is_message_active:
		return

	# Entrada do boss.
	if state == BossState.WAITING and player_inside and not fight_started:
		get_viewport().set_input_as_handled()
		_start_intro()
		return

	# Início do desafio.
	if state == BossState.EXHAUSTED and waiting_for_challenge:
		if _player_is_close_to_boss():
			get_viewport().set_input_as_handled()
			_start_current_challenge()


# ============================================================
# SPAWN
# ============================================================

func _spawn_existing_boss() -> void:
	var existing: Node = get_parent().get_node_or_null("boss inimigo")

	if existing == null:
		var candidates: Array[Node] = get_tree().get_nodes_in_group("boss")
		for candidate: Node in candidates:
			if candidate is CharacterBody2D:
				existing = candidate
				break

	if existing == null or not existing is CharacterBody2D:
		push_error("BOSS: não encontrei o 'boss inimigo' no World-04.")
		return

	var shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		push_error("BOSS: CollisionShape2D não encontrado.")
		return

	boss_visual = existing as CharacterBody2D

	# PONTO EXATO: centro do CollisionShape2D.
	boss_visual.global_position = shape.global_position

	boss_visual.visible = true
	boss_visual.z_index = 20
	boss_visual.set_physics_process(true)

	boss_sprite = boss_visual.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if boss_sprite != null:
		boss_sprite.visible = true
		boss_sprite.modulate = Color.WHITE
		if boss_sprite.sprite_frames.has_animation("olhando"):
			boss_sprite.play("olhando")

	if boss_visual.has_method("set_boss_health"):
		boss_visual.call("set_boss_health", MAX_HEALTH)

	if boss_visual.has_method("set_damage_enabled"):
		boss_visual.call("set_damage_enabled", false)

	if boss_visual.has_method("freeze_boss"):
		boss_visual.call("freeze_boss")

	# Conta ataques reais emitidos pelo boss.
	if boss_visual.has_signal("boss_attack_started"):
		if not boss_visual.is_connected(
			"boss_attack_started",
			Callable(self, "_on_boss_attack_started")
		):
			boss_visual.connect(
				"boss_attack_started",
				Callable(self, "_on_boss_attack_started")
			)

	if boss_visual.has_signal("boss_health_changed"):
		if not boss_visual.is_connected(
			"boss_health_changed",
			Callable(self, "_on_boss_health_changed")
		):
			boss_visual.connect(
				"boss_health_changed",
				Callable(self, "_on_boss_health_changed")
			)

	if boss_visual.has_signal("boss_defeated"):
		if not boss_visual.is_connected(
			"boss_defeated",
			Callable(self, "_on_boss_defeated")
		):
			boss_visual.connect(
				"boss_defeated",
				Callable(self, "_on_boss_defeated")
			)

	print("BOSS spawn:", boss_visual.global_position)


func _get_collision_global_position() -> Vector2:
	var shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		return shape.global_position
	return global_position


# ============================================================
# CONTROLLERS
# ============================================================

func _create_or_get_controllers() -> void:
	dialogue_controller = get_node_or_null("BossDialogue")
	if dialogue_controller == null:
		dialogue_controller = Node.new()
		dialogue_controller.name = "BossDialogue"
		dialogue_controller.set_script(load("res://scripts/boss_dialogue.gd"))
		add_child(dialogue_controller)

	challenge_manager = get_node_or_null("BossChallengeManager")
	if challenge_manager == null:
		challenge_manager = Node.new()
		challenge_manager.name = "BossChallengeManager"
		challenge_manager.set_script(load("res://scripts/boss_challenge_manager.gd"))
		add_child(challenge_manager)

	if dialogue_controller.has_method("setup"):
		dialogue_controller.call("setup", boss_visual)


func _connect_signals() -> void:
	if dialogue_controller != null:
		if not dialogue_controller.is_connected(
			"intro_finished",
			Callable(self, "_on_intro_finished")
		):
			dialogue_controller.connect(
				"intro_finished",
				Callable(self, "_on_intro_finished")
			)

		if not dialogue_controller.is_connected(
			"victory_finished",
			Callable(self, "_on_victory_finished")
		):
			dialogue_controller.connect(
				"victory_finished",
				Callable(self, "_on_victory_finished")
			)

	if challenge_manager != null:
		if not challenge_manager.is_connected(
			"challenge_finished",
			Callable(self, "_on_challenge_finished")
		):
			challenge_manager.connect(
				"challenge_finished",
				Callable(self, "_on_challenge_finished")
			)


# ============================================================
# ENTRADA + LORE
# ============================================================

func _process_waiting() -> void:
	# Nada é criado aqui. O aviso da porta já pode ser feito por
	# este próprio Area2D, sem mexer nos outros mapas.
	pass


func _start_intro() -> void:
	if fight_started or state != BossState.WAITING:
		return

	fight_started = true
	player_inside = false
	state = BossState.DIALOGUE

	_set_hud_visible(false)
	_set_boss_prompt_visible(false)
	_set_boss_damage_enabled(false)

	if is_instance_valid(boss_visual):
		if boss_visual.has_method("freeze_boss"):
			boss_visual.call("freeze_boss")

	if dialogue_controller != null and dialogue_controller.has_method("start_intro"):
		dialogue_controller.call("start_intro")
	else:
		_on_intro_finished()


func _on_intro_finished() -> void:
	_set_hud_visible(true)
	_start_chase()


# ============================================================
# PERSEGUIÇÃO / ATAQUES
# ============================================================

func _start_chase() -> void:
	if state == BossState.VICTORY:
		return

	state = BossState.CHASE
	attack_count = 0

	var index: int = min(
		challenge_index,
		ATTACK_REQUIREMENTS.size() - 1
	)

	_set_boss_damage_enabled(challenge_index > 0)
	_set_boss_prompt_visible(false)

	if is_instance_valid(boss_visual):
		if boss_visual.has_method("unfreeze_boss"):
			boss_visual.call("unfreeze_boss")

	_update_phase_ui()


func _process_chase() -> void:
	# Toda a perseguição, ataque, pulo e animação
	# fica exclusivamente no bossinimigo.gd.
	pass


func _on_boss_attack_started() -> void:
	if state != BossState.CHASE:
		return

	attack_count += 1
	_update_phase_ui()

	var index: int = min(
		challenge_index,
		ATTACK_REQUIREMENTS.size() - 1
	)

	var required: int = ATTACK_REQUIREMENTS[index]

	if attack_count >= required:
		_start_exhausted()


func _start_exhausted() -> void:
	if state != BossState.CHASE:
		return

	state = BossState.EXHAUSTED
	waiting_for_challenge = true
	exhausted_time_left = EXHAUSTED_TIME

	# Player fica livre. Só o boss para.
	_set_boss_damage_enabled(false)

	if is_instance_valid(boss_visual):
		if boss_visual.has_method("freeze_boss"):
			boss_visual.call("freeze_boss")

	_update_exhausted_prompt()


func _process_exhausted(delta: float) -> void:
	if state != BossState.EXHAUSTED:
		return

	exhausted_time_left -= delta
	_update_exhausted_prompt()

	# O Player continua com can_move = true.
	if not is_instance_valid(player):
		_find_player_if_needed()

	# Se chegar perto e apertar E, o unhandled_input inicia.
	if exhausted_time_left <= 0.0:
		waiting_for_challenge = false
		_set_boss_prompt_visible(false)
		_start_chase()


# ============================================================
# DESAFIOS
# ============================================================

func _start_current_challenge() -> void:
	if state != BossState.EXHAUSTED:
		return

	if not _player_is_close_to_boss():
		return

	if challenge_manager == null:
		return

	waiting_for_challenge = false
	state = BossState.CHALLENGE

	_set_boss_prompt_visible(false)
	_set_boss_damage_enabled(false)

	if is_instance_valid(boss_visual):
		if boss_visual.has_method("freeze_boss"):
			boss_visual.call("freeze_boss")

	var type: String = CHALLENGE_ORDER[
		min(challenge_index, CHALLENGE_ORDER.size() - 1)
	]

	if challenge_manager.has_method("prepare_challenge"):
		challenge_manager.call(
			"prepare_challenge",
			type,
			challenge_index
		)

	if challenge_manager.has_method("start_current_challenge"):
		challenge_manager.call("start_current_challenge")


func _on_challenge_finished(
	correct: bool,
	_challenge_type: String
) -> void:
	if state != BossState.CHALLENGE:
		return

	if correct:
		if is_instance_valid(boss_visual):
			if boss_visual.has_method("take_boss_damage"):
				boss_visual.call(
					"take_boss_damage",
					DAMAGE_PER_SUCCESS
				)

		_update_health_from_boss()

		if current_health <= 0:
			_on_boss_defeated()
			return

		challenge_index += 1
		_unlock_player()
		_start_chase()
		return

	# Errou: não perde vida, mas volta para a perseguição.
	_unlock_player()
	_start_chase()


# ============================================================
# VIDA / MORTE
# ============================================================

func _on_boss_health_changed(
	current: int,
	_maximum: int
) -> void:
	current_health = current
	_update_health_ui()


func _update_health_from_boss() -> void:
	if not is_instance_valid(boss_visual):
		return

	if boss_visual.has_method("get_current_health"):
		current_health = int(
			boss_visual.call("get_current_health")
		)
	else:
		current_health = max(
			0,
			current_health - DAMAGE_PER_SUCCESS
		)

	_update_health_ui()


func _on_boss_defeated() -> void:
	if state == BossState.VICTORY:
		return

	state = BossState.VICTORY
	waiting_for_challenge = false

	_set_boss_damage_enabled(false)
	_set_boss_prompt_visible(false)

	if is_instance_valid(boss_visual):
		if boss_visual.has_method("freeze_boss"):
			boss_visual.call("freeze_boss")

	if dialogue_controller != null and dialogue_controller.has_method(
		"start_victory"
	):
		dialogue_controller.call("start_victory")
	else:
		_finish_victory()


func _on_victory_finished() -> void:
	_finish_victory()


func _finish_victory() -> void:
	if is_instance_valid(boss_visual):
		if boss_visual.has_method("queue_free"):
			boss_visual.call_deferred("queue_free")
		else:
			boss_visual.queue_free()

	_set_hud_visible(false)


# ============================================================
# PLAYER
# ============================================================

func _find_player() -> void:
	var found: Node = get_tree().get_first_node_in_group("player")
	if found is Node2D:
		player = found as Node2D


func _find_player_if_needed() -> void:
	if is_instance_valid(player):
		return
	_find_player()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_inside = true

		# Prompt da porta é separado dos prompts do boss.
		# Aqui só mantemos a entrada normal.


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_inside = false


func _unlock_player() -> void:
	if not is_instance_valid(player):
		_find_player_if_needed()

	if not is_instance_valid(player):
		return

	if player.get("can_move") != null:
		player.set("can_move", true)


func _player_is_close_to_boss() -> bool:
	if not is_instance_valid(player):
		return false

	if not is_instance_valid(boss_visual):
		return false

	return (
		player.global_position.distance_to(
			boss_visual.global_position
		) <= CHALLENGE_INTERACTION_DISTANCE
	)


# ============================================================
# DANO DO BOSS
# ============================================================

func _set_boss_damage_enabled(enabled: bool) -> void:
	if not is_instance_valid(boss_visual):
		return

	if boss_visual.has_method("set_damage_enabled"):
		boss_visual.call("set_damage_enabled", enabled)


# ============================================================
# PROMPT ACIMA DA CABEÇA
# ============================================================

func _create_boss_prompt() -> void:
	if not is_instance_valid(boss_visual):
		return

	boss_prompt = Panel.new()
	boss_prompt.name = "BossChallengePrompt"
	boss_prompt.position = Vector2(-135.0, -118.0)
	boss_prompt.size = Vector2(270.0, 56.0)
	boss_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_prompt.z_index = 1000

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = PURPLE
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	boss_prompt.add_theme_stylebox_override(
		"panel",
		style
	)

	boss_prompt_text = _make_label(
		"[ E ] INICIAR DESAFIO",
		12,
		WHITE
	)
	boss_prompt_text.position = Vector2(6.0, 4.0)
	boss_prompt_text.size = Vector2(258.0, 27.0)
	boss_prompt_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_prompt_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_prompt.add_child(boss_prompt_text)

	boss_prompt_timer = _make_label(
		"10 s",
		10,
		MUTED
	)
	boss_prompt_timer.position = Vector2(6.0, 31.0)
	boss_prompt_timer.size = Vector2(258.0, 18.0)
	boss_prompt_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_prompt_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_prompt.add_child(boss_prompt_timer)

	boss_visual.add_child(boss_prompt)
	boss_prompt.hide()


func _update_exhausted_prompt() -> void:
	if boss_prompt == null:
		return

	var challenge_number: int = challenge_index + 1
	var close: bool = _player_is_close_to_boss()

	if challenge_number >= CHALLENGE_ORDER.size():
		if close:
			boss_prompt_text.text = "[ E ] DESAFIO FINAL"
		else:
			boss_prompt_text.text = "DESAFIO FINAL"
	else:
		if close:
			boss_prompt_text.text = (
				"[ E ] INICIAR DESAFIO %d" % challenge_number
			)
		else:
			boss_prompt_text.text = "GUARDIAO EXAUSTO"

	boss_prompt_timer.text = (
		"%.0f s" % max(0.0, ceil(exhausted_time_left))
	)

	boss_prompt.show()


func _set_boss_prompt_visible(
	visible_value: bool
) -> void:
	if boss_prompt != null:
		boss_prompt.visible = visible_value


# ============================================================
# HUD
# ============================================================

func _create_hud() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.layer = 100
	add_child(hud_canvas)

	hud_panel = Panel.new()
	hud_panel.position = Vector2(70, 30)
	hud_panel.size = Vector2(1160, 95)
	hud_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			PANEL,
			PURPLE,
			2,
			9
		)
	)
	hud_canvas.add_child(hud_panel)

	var name_label: Label = _make_label(
		"GUARDIAO COGNITIVO",
		18,
		WHITE
	)
	name_label.position = Vector2(22, 12)
	name_label.size = Vector2(300, 28)
	hud_panel.add_child(name_label)

	hud_phase = _make_label(
		"ATAQUES 0 / 3",
		12,
		MUTED
	)
	hud_phase.position = Vector2(22, 44)
	hud_phase.size = Vector2(280, 24)
	hud_panel.add_child(hud_phase)

	hud_bar = ProgressBar.new()
	hud_bar.position = Vector2(320, 26)
	hud_bar.size = Vector2(650, 32)
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
			5
		)
	)
	hud_bar.add_theme_stylebox_override(
		"fill",
		_make_panel_style(
			PURPLE,
			PURPLE_LIGHT,
			0,
			5
		)
	)
	hud_panel.add_child(hud_bar)

	hud_value = _make_label(
		"120 / 120",
		13,
		PURPLE_LIGHT
	)
	hud_value.position = Vector2(990, 28)
	hud_value.size = Vector2(145, 28)
	hud_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_panel.add_child(hud_value)


func _update_health_ui() -> void:
	if hud_bar != null:
		hud_bar.value = current_health

	if hud_value != null:
		hud_value.text = "%d / %d" % [
			current_health,
			MAX_HEALTH
		]

	_update_phase_ui()
	boss_health_changed.emit(
		current_health,
		MAX_HEALTH
	)


func _update_phase_ui() -> void:
	if hud_phase == null:
		return

	if state == BossState.EXHAUSTED:
		hud_phase.text = "GUARDIAO EXAUSTO"
		return

	var index: int = min(
		challenge_index,
		ATTACK_REQUIREMENTS.size() - 1
	)

	hud_phase.text = "ATAQUES %d / %d" % [
		attack_count,
		ATTACK_REQUIREMENTS[index]
	]


func _set_hud_visible(
	visible_value: bool
) -> void:
	if hud_panel != null:
		hud_panel.visible = visible_value


# ============================================================
# HELPERS
# ============================================================

func _make_panel_style(
	background: Color,
	border: Color,
	width: int,
	radius: int
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style


func _make_label(
	text_value: String,
	size: int,
	color: Color
) -> Label:
	var label: Label = Label.new()
	label.text = text_value
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
		3
	)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_font(label)
	return label


func _apply_font(control: Control) -> void:
	var resource: Resource = load(FONT_PATH)
	if resource != null:
		control.add_theme_font_override(
			"font",
			resource
		)
