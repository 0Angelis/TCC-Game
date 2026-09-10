extends CharacterBody2D


# ==========================================
# MOVIMENTO
# ==========================================

const SPEED: float = 120.0
const JUMP_FORCE: float = -300.0


# ==========================================
# KNOCKBACK DOS INIMIGOS
# ==========================================

const ENEMY_KNOCKBACK_X: float = 250.0
const ENEMY_KNOCKBACK_Y: float = -150.0


# ==========================================
# KNOCKBACK DOS ESPINHOS
# ==========================================

# ESPINHO JOGA SOMENTE PARA CIMA
const SPIKE_KNOCKBACK_X: float = 0.0
const SPIKE_KNOCKBACK_Y: float = -330.0


# ==========================================
# KNOCKBACK
# ==========================================

var knockback_active: bool = false

const KNOCKBACK_TIME: float = 0.22

var knockback_timer: float = 0.0


# ==========================================
# DANO
# ==========================================

const HURT_ANIMATION_TIME: float = 0.12
const INVINCIBILITY_TIME: float = 0.4


# ==========================================
# COOLDOWN DE INIMIGO
# ==========================================

var enemy_damage_cooldown: float = 0.0


# ==========================================
# ESTADOS
# ==========================================

var taking_damage: bool = false
var can_take_damage: bool = true
var can_move: bool = true
var is_dead: bool = false


# ==========================================
# ESTADO DOS ESPINHOS
# ==========================================

var spike_contact_active: bool = false


# ==========================================
# WARNING
# ==========================================

var showing_warning: bool = false


# ==========================================
# VITÓRIA / DANÇA
# ==========================================

var celebrating: bool = false


# ==========================================
# NÓS
# ==========================================

@onready var animation: AnimatedSprite2D = $Anim
@onready var remote_transform: RemoteTransform2D = $remote
@onready var level = get_tree().current_scene.get_node("level")

# ==========================================
# SKIN
# ==========================================

# A skin fica somente na memoria durante a execucao do jogo.
# Isso permite passar de fase sem perder a skin, mas ao fechar
# o jogo tudo volta ao estado inicial.
const SKIN_META_SESSAO: String = "skins_session_state"

var skin_equipada: String = "original"


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	add_to_group("player")

	is_dead = false
	taking_damage = false
	can_take_damage = true
	can_move = true

	showing_warning = false
	celebrating = false

	knockback_active = false
	knockback_timer = 0.0

	enemy_damage_cooldown = 0.0

	spike_contact_active = false

	# ==========================================
	# SALVA AS VIDAS DO INÍCIO DA FASE
	# ==========================================
	# Cria um novo snapshot somente quando entramos em
	# outra cena. No RESTART da mesma fase, o snapshot
	# continua sendo o valor original.
	var current_scene := get_tree().current_scene

	if current_scene != null:

		var current_path := current_scene.scene_file_path.to_lower()

		if Globals.life_snapshot_scene != current_path:

			Globals.lives_before_level = Globals.player_life
			Globals.life_snapshot_scene = current_path

			print("SNAPSHOT DE VIDAS: ", Globals.lives_before_level)

	# ==========================================
	# SKIN DA SESSAO / BASELINE DA FASE
	# ==========================================
	carregar_skin_da_sessao()
	preparar_baseline_da_fase()

	call_deferred("atualizar_cor_skin")

	print("PLAYER INICIADO")
	print("VIDAS: ", Globals.player_life)
	print("SKIN: ", skin_equipada)


# ==========================================
# INPUT
# ==========================================

func _unhandled_input(event: InputEvent) -> void:

	if is_dead:
		return


	# ==========================================
	# V = TROCAR SKIN
	# ==========================================
	# Só funciona quando existe mais de uma skin
	# realmente desbloqueada/comprada na sessão.
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_V
	):

		trocar_skin_com_v()

		get_viewport().set_input_as_handled()

		return


	# ==========================================
	# B = DANÇA
	# ==========================================

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_B
	):

		play_dance()

		get_viewport().set_input_as_handled()

		return


	# ==========================================
	# CANCELAR DANÇA
	# ==========================================

	if celebrating:

		if (
			event is InputEventKey
			and event.pressed
			and not event.echo
		):

			if (
				event.keycode == KEY_A
				or event.keycode == KEY_D
				or event.keycode == KEY_LEFT
				or event.keycode == KEY_RIGHT
				or event.keycode == KEY_W
				or event.keycode == KEY_UP
				or event.keycode == KEY_DOWN
				or event.keycode == KEY_S
				or event.keycode == KEY_SPACE
			):

				celebrating = false
				can_move = true

				print("DANÇA CANCELADA")


# ==========================================
# FÍSICA
# ==========================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	# ==========================================
	# GRAVIDADE
	# ==========================================

	if not is_on_floor():

		velocity += get_gravity() * delta


	# ==========================================
	# COOLDOWN DE INIMIGO
	# ==========================================

	if enemy_damage_cooldown > 0.0:

		enemy_damage_cooldown -= delta


	# ==========================================
	# KNOCKBACK
	# ==========================================

	if knockback_active:

		knockback_timer -= delta

		if knockback_timer <= 0.0:

			knockback_active = false

		else:

			velocity.x = move_toward(
				velocity.x,
				0.0,
				180.0 * delta
			)


	# ==========================================
	# AGACHAR
	# ==========================================

	var moving_down: bool = (
		Input.is_key_pressed(KEY_DOWN)
		or Input.is_key_pressed(KEY_S)
	)


	# ==========================================
	# DIREÇÃO
	# ==========================================

	var direction: int = 0


	if not moving_down:

		if (
			Input.is_key_pressed(KEY_A)
			or Input.is_key_pressed(KEY_LEFT)
		):

			direction = -1

		elif (
			Input.is_key_pressed(KEY_D)
			or Input.is_key_pressed(KEY_RIGHT)
		):

			direction = 1


	# ==========================================
	# PULO
	# ==========================================

	if (
		not knockback_active
		and (
			Input.is_key_pressed(KEY_W)
			or Input.is_key_pressed(KEY_SPACE)
			or Input.is_key_pressed(KEY_UP)
		)
		and is_on_floor()
		and can_move
		and not taking_damage
		and not moving_down
	):

		velocity.y = JUMP_FORCE


	# ==========================================
	# MOVIMENTO NORMAL
	# ==========================================

	if not knockback_active:

		if moving_down:

			velocity.x = 0.0

		elif direction != 0 and can_move:

			velocity.x = direction * SPEED

			animation.flip_h = direction < 0

		elif can_move:

			velocity.x = move_toward(
				velocity.x,
				0.0,
				SPEED
			)


	# ==========================================
	# WARNING
	# ==========================================

	if showing_warning:

		if (
			Input.is_key_pressed(KEY_A)
			or Input.is_key_pressed(KEY_D)
			or Input.is_key_pressed(KEY_LEFT)
			or Input.is_key_pressed(KEY_RIGHT)
			or Input.is_key_pressed(KEY_W)
			or Input.is_key_pressed(KEY_UP)
			or Input.is_key_pressed(KEY_DOWN)
			or Input.is_key_pressed(KEY_S)
			or Input.is_key_pressed(KEY_SPACE)
		):

			showing_warning = false


	# ==========================================
	# ANIMAÇÕES
	# ==========================================

	if taking_damage:

		if animation.animation != "hurt":

			animation.play("hurt")

	elif celebrating:

		if animation.animation != "vitoria":

			animation.play("vitoria")

	elif showing_warning:

		if animation.animation != "warning":

			animation.play("warning")

	elif moving_down and is_on_floor():

		if animation.animation != "arrastar":

			animation.play("arrastar")

	elif not is_on_floor() and velocity.y > 0.0:

		if animation.animation != "falling":

			animation.play("falling")

	elif not is_on_floor():

		if animation.animation != "jump":

			animation.play("jump")

	elif direction != 0:

		if animation.animation != "run":

			animation.play("run")

	else:

		if animation.animation != "idle":

			animation.play("idle")


	# ==========================================
	# COR / SKIN
	# ==========================================
	#
	# Dano continua usando vermelho.
	# Fora do dano, a skin equipada é aplicada
	# diretamente como MODULATE no sprite.
	#
	# ==========================================

	atualizar_cor_skin()


	# ==========================================
	# MOVIMENTO FÍSICO
	# ==========================================

	move_and_slide()


	# ==========================================
	# COLISÃO COM INIMIGO
	# ==========================================

	verificar_colisao_com_inimigo()


	# ==========================================
	# ESPINHOS
	# ==========================================

	check_damage_tile()


# ==========================================
# VERIFICAR COLISÃO COM INIMIGO
# ==========================================

func verificar_colisao_com_inimigo() -> void:

	if is_dead:
		return


	if not can_take_damage:
		return


	if enemy_damage_cooldown > 0.0:
		return


	var collision_count: int = (
		get_slide_collision_count()
	)


	if collision_count <= 0:
		return


	for i in collision_count:

		var slide_collision: KinematicCollision2D = (
			get_slide_collision(i)
		)


		var collider: Object = (
			slide_collision.get_collider()
		)


		if collider == null:
			continue


		if not collider is Node2D:
			continue


		var other_body: Node2D = (
			collider as Node2D
		)


		if not other_body.is_in_group("enemies"):

			continue


		var enemy_dead = (
			other_body.get("is_dead")
		)


		if enemy_dead == true:

			continue


		var normal: Vector2 = (
			slide_collision.get_normal()
		)


		# ==========================================
		# PLAYER ESTÁ EM CIMA
		# ==========================================

		if normal.y < -0.5:

			continue


		# ==========================================
		# PRECISA SER LATERAL
		# ==========================================

		if abs(normal.x) < 0.5:

			continue


		print("==============================")
		print("PLAYER BATEU NO CORPO DO INIMIGO!")
		print(
			"Inimigo: ",
			other_body.name
		)
		print("==============================")


		var knockback_direction: float = 1.0


		if (
			global_position.x
			< other_body.global_position.x
		):

			knockback_direction = -1.0


		receber_dano_inimigo(
			Vector2(
				knockback_direction
				* ENEMY_KNOCKBACK_X,
				ENEMY_KNOCKBACK_Y
			)
		)


		enemy_damage_cooldown = 0.7


		return


# ==========================================
# HURTBOX
# ==========================================

func _on_hurtbox_body_entered(
	body: Node2D
) -> void:

	return


# ==========================================
# ESPINHOS
# ==========================================

func check_damage_tile() -> void:

	if is_dead:
		return


	if level == null:
		return


	# ==========================================
	# POSIÇÃO DOS PÉS
	# ==========================================

	var feet_position: Vector2 = (
		global_position
		+ Vector2(
			0.0,
			12.0
		)
	)


	# ==========================================
	# DETECÇÃO DOS ESPINHOS
	# ==========================================

	var positions: Array[Vector2] = [
		feet_position,
		feet_position + Vector2(-5.0, 0.0),
		feet_position + Vector2(5.0, 0.0)
	]


	var on_spike: bool = false


	# ==========================================
	# PROCURA O ESPINHO
	# ==========================================

	for layer_index in range(
		level.get_layers_count()
	):

		for world_position in positions:

			var local_position: Vector2 = (
				level.to_local(
					world_position
				)
			)


			var tile_position: Vector2i = (
				level.local_to_map(
					local_position
				)
			)


			var tile_data = (
				level.get_cell_tile_data(
					layer_index,
					tile_position
				)
			)


			if tile_data == null:
				continue


			var damage = (
				tile_data.get_custom_data(
					"damage"
				)
			)


			if damage == true:

				on_spike = true

				break


		if on_spike:
			break


	# ==========================================
	# SAIU DOS ESPINHOS
	# ==========================================

	if not on_spike:

		if spike_contact_active:

			print("SAIU DOS ESPINHOS!")

		spike_contact_active = false

		return


	# ==========================================
	# ESTÁ NOS ESPINHOS
	# ==========================================

	if not spike_contact_active:

		spike_contact_active = true

		print("ENTROU NO ESPINHO!")


		# ==========================================
		# PRIMEIRO DANO
		# ==========================================

		if can_take_damage:

			# ESPINHO JOGA SOMENTE PARA CIMA

			take_damage(
				Vector2(
					0.0,
					SPIKE_KNOCKBACK_Y
				)
			)


	# ==========================================
	# KNOCKBACK CONTÍNUO
	# ==========================================

	# Enquanto estiver no espinho,
	# continua sendo jogado para cima.

	velocity.x = 0.0
	velocity.y = SPIKE_KNOCKBACK_Y

	knockback_active = true
	knockback_timer = KNOCKBACK_TIME


# ==========================================
# RECEBER DANO
# ==========================================

func take_damage(
	knockback_force: Vector2 = Vector2.ZERO
) -> void:

	if is_dead:
		return


	if not can_take_damage:
		return


	# ==========================================
	# BLOQUEIA NOVO DANO
	# ==========================================

	can_take_damage = false
	taking_damage = true

	showing_warning = false
	celebrating = false


	# ==========================================
	# PERDE VIDA
	# ==========================================

	if Globals.player_life > 0:

		Globals.player_life -= 1

	else:

		die()

		return


	print(
		"VIDA: ",
		Globals.player_life
	)


	# ==========================================
	# MORTE
	# ==========================================

	if Globals.player_life <= 0:

		die()

		return


	# ==========================================
	# HURT
	# ==========================================

	animation.play("hurt")

	animation.modulate = Color(
		1.0,
		0.55,
		0.55,
		1.0
	)


	# ==========================================
	# KNOCKBACK
	# ==========================================

	if knockback_force != Vector2.ZERO:

		velocity.x = knockback_force.x
		velocity.y = knockback_force.y

		knockback_active = true
		knockback_timer = KNOCKBACK_TIME


	# ==========================================
	# HURT CURTO
	# ==========================================

	await get_tree().create_timer(
		HURT_ANIMATION_TIME
	).timeout


	if is_dead:
		return


	taking_damage = false


	# A cor da skin volta automaticamente no próximo frame.
	atualizar_cor_skin()


	# ==========================================
	# INVENCIBILIDADE
	# ==========================================

	await get_tree().create_timer(
		INVINCIBILITY_TIME
	).timeout


	if is_dead:
		return


	can_take_damage = true


# ==========================================
# DANO DE INIMIGO
# ==========================================

func receber_dano_inimigo(
	knockback: Vector2 = Vector2.ZERO
) -> void:

	print("==============================")
	print("DANO DO INIMIGO RECEBIDO!")
	print(
		"VIDA ANTES: ",
		Globals.player_life
	)
	print("==============================")


	take_damage(
		knockback
	)


	print("==============================")
	print(
		"VIDA DEPOIS: ",
		Globals.player_life
	)
	print("==============================")


# ==========================================
# WARNING
# ==========================================

func play_warning() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	if celebrating:
		return


	showing_warning = true

	velocity.x = 0.0


	# ==========================================
	# MANTÉM A DIREÇÃO ATUAL
	# ==========================================
	#
	# NÃO usamos:
	#
	# animation.flip_h = !animation.flip_h
	#
	# porque isso faria o pinguim inverter
	# o lado toda vez que o warning fosse ativado.
	#
	# O pinguim simplesmente mantém o lado
	# para o qual já estava olhando.

	animation.stop()

	animation.play("warning")


	print(
		"WARNING DO PLAYER!"
	)


# ==========================================
# PARA WARNING
# ==========================================

func stop_warning() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	if celebrating:
		return


	showing_warning = false


	# ==========================================
	# VOLTA PARA ANIMAÇÃO NORMAL
	# ==========================================

	if not is_on_floor():

		if velocity.y > 0.0:

			animation.play("falling")

		else:

			animation.play("jump")


	else:

		if abs(velocity.x) > 1.0:

			animation.play("run")

		else:

			animation.play("idle")


	print(
		"WARNING ENCERRADO!"
	)


# ==========================================
# WARNING CANCELADO POR MOVIMENTO
# ==========================================

func cancelar_warning_por_movimento() -> void:

	if not showing_warning:
		return


	showing_warning = false


# ==========================================
# VITÓRIA
# ==========================================

func play_victory() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	showing_warning = false

	celebrating = true

	can_move = false

	velocity.x = 0.0

	animation.stop()

	animation.play("vitoria")


	print(
		"================================"
	)

	print(
		"ANIMAÇÃO DE VITÓRIA!"
	)

	print(
		"================================"
	)


# ==========================================
# DANÇA
# ==========================================

func play_dance() -> void:

	if is_dead:
		return


	if taking_damage:
		return


	showing_warning = false

	celebrating = true

	can_move = false

	velocity.x = 0.0

	animation.stop()

	animation.play("vitoria")


	print(
		"================================"
	)

	print(
		"DANÇA ATIVADA PELA TECLA B!"
	)

	print(
		"================================"
	)


# ==========================================
# MORTE
# ==========================================

func die() -> void:

	if is_dead:
		return


	is_dead = true

	can_move = false
	can_take_damage = false
	taking_damage = true

	showing_warning = false
	celebrating = false

	velocity = Vector2.ZERO

	knockback_active = false
	knockback_timer = 0.0

	spike_contact_active = false


	# ==========================================
	# FECHAR WARNING
	# ==========================================

	if DialogManager.is_message_active:

		DialogManager.close_message()


	# ==========================================
	# SALVAR CENA
	# ==========================================

	get_tree().set_meta(
		"restart_scene",
		get_tree().current_scene.scene_file_path
	)


	# ==========================================
	# RESET
	# ==========================================

	Globals.coins = 0
	Globals.score = 0

	Globals.coins_before_level = 0

	Globals.level_coins = 0
	Globals.level_score = 0

	Globals.raciocinio_fragments = 0
	Globals.atencao_fragments = 0
	Globals.memoria_fragments = 0


	print(
		"=============================="
	)

	print(
		"JOGADOR MORREU"
	)

	print(
		"=============================="
	)


	# ==========================================
	# SUMIR
	# ==========================================

	animation.visible = false

	set_physics_process(false)


	# ==========================================
	# GAME OVER
	# ==========================================

	get_tree().change_scene_to_file(
		"res://scenes/game_over.tscn"
	)


# ==========================================
# SISTEMA DE SKINS
# ==========================================
#
# Skins normais usam MODULATE.
# Bronze, Prata e Ouro usam um shader metálico criado por código,
# então não precisam de PNG novo.
#
# ==========================================

var skin_metal_shader: Shader = null
var skin_metal_material: ShaderMaterial = null


func carregar_skin() -> void:
	carregar_skin_da_sessao()


func carregar_skin_da_sessao() -> void:
	skin_equipada = "original"

	var raiz := get_tree().root

	if not raiz.has_meta(SKIN_META_SESSAO):
		return

	var dados = raiz.get_meta(SKIN_META_SESSAO)

	if typeof(dados) != TYPE_DICTIONARY:
		return

	if not dados.has("skin_equipada"):
		return

	var id: String = str(dados["skin_equipada"])

	if id in [
		"original",
		"bronze",
		"prata",
		"ouro",
		"azul",
		"vermelho",
		"amarelo",
		"rgb"
	]:
		skin_equipada = id


func estado_skin_atual() -> Dictionary:
	var raiz := get_tree().root

	if raiz.has_meta(SKIN_META_SESSAO):
		var dados = raiz.get_meta(SKIN_META_SESSAO)

		if typeof(dados) == TYPE_DICTIONARY:
			var estado: Dictionary = {
				"skins_desbloqueadas": ["original"],
				"skin_equipada": "original"
			}

			if dados.has("skins_desbloqueadas") 			and typeof(dados["skins_desbloqueadas"]) == TYPE_ARRAY:
				estado["skins_desbloqueadas"] = dados["skins_desbloqueadas"].duplicate()

			if dados.has("skin_equipada"):
				estado["skin_equipada"] = str(dados["skin_equipada"])

			return estado

	return {
		"skins_desbloqueadas": ["original"],
		"skin_equipada": "original"
	}


func chave_fase_atual() -> String:
	var cena = get_tree().current_scene

	if cena == null:
		return ""

	return cena.scene_file_path


func preparar_baseline_da_fase() -> void:
	var raiz := get_tree().root
	var chave_atual: String = chave_fase_atual()

	if chave_atual.is_empty():
		return

	# =====================================================
	# RESTART
	# =====================================================
	# O restart.gd ja restaurou a sessao antes de trocar a cena.
	# Nao criamos outro snapshot aqui.
	if raiz.has_meta("skins_restart_pending") 	and bool(raiz.get_meta("skins_restart_pending", false)):
		raiz.set_meta(
			"skins_last_scene_path",
			chave_atual
		)

		print("SKINS: entrada por RESTART, snapshot preservado.")
		return

	# =====================================================
	# NOVA ENTRADA NORMAL
	# =====================================================
	# Compara com a cena anterior, e nao apenas com um dicionario
	# permanente por nome.
	#
	# Isso permite:
	# MUNDO -> LOJA -> MUNDO -> LOJA
	# Mesmo sendo a mesma lojas.tscn, cada retorno normal a loja
	# recebe um novo snapshot.
	var cena_anterior: String = str(
		raiz.get_meta("skins_last_scene_path", "")
	)

	if cena_anterior == chave_atual:
		return

	# Primeira entrada ou entrada normal vindo de outra cena.
	var estado_inicial: Dictionary = estado_skin_atual()

	raiz.set_meta(
		"skins_before_level",
		estado_inicial.duplicate(true)
	)

	raiz.set_meta(
		"skins_last_scene_path",
		chave_atual
	)

	print("========================================")
	print("NOVO SNAPSHOT DE SKINS")
	print("CENA: ", chave_atual)
	print("ESTADO: ", estado_inicial)
	print("========================================")


func obter_cor_skin() -> Color:

	match skin_equipada:

		"bronze":
			return Color("#B87333")

		"prata":
			return Color.WHITE

		"ouro":
			return Color.WHITE

		"azul":
			return Color("#2196FF")

		"vermelho":
			return Color("#F44336")

		"amarelo":
			return Color("#FFE000")

		"rgb":
			var tempo: float = Time.get_ticks_msec() * 0.001
			var hue: float = fmod(tempo * 0.35, 1.0)

			return Color.from_hsv(
				hue,
				0.85,
				1.0
			)

		_:
			return Color.WHITE


func criar_shader_metalico() -> void:

	if skin_metal_shader != null:
		return

	skin_metal_shader = Shader.new()

	skin_metal_shader.code = """
shader_type canvas_item;

uniform vec4 metal_dark : source_color;
uniform vec4 metal_mid : source_color;
uniform vec4 metal_light : source_color;
uniform float shine_strength : hint_range(0.0, 2.0) = 0.75;
uniform float shine_speed : hint_range(0.0, 3.0) = 0.65;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a <= 0.01) {
		discard;
	}

	// Pega a luminosidade original do sprite para preservar
	// sombras e detalhes do pinguim.
	float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	// Cria três níveis de metal: sombra, meio e reflexo.
	float middle = smoothstep(0.10, 0.55, luminance);
	float bright = smoothstep(0.50, 0.90, luminance);

	vec3 metal_color = mix(metal_dark.rgb, metal_mid.rgb, middle);
	metal_color = mix(metal_color, metal_light.rgb, bright);

	// Reflexo metálico passando pelo personagem.
	float sweep = fract(TIME * shine_speed);
	float distance_to_shine = abs(UV.x - sweep);
	float shine = 1.0 - smoothstep(0.0, 0.16, distance_to_shine);
	shine *= shine_strength;

	metal_color += metal_light.rgb * shine * 0.55;
	metal_color = clamp(metal_color, vec3(0.0), vec3(1.0));

	COLOR = vec4(metal_color, tex.a);
}
"""

	skin_metal_material = ShaderMaterial.new()
	skin_metal_material.shader = skin_metal_shader


func aplicar_metal_bronze() -> void:

	if skin_metal_material == null:
		criar_shader_metalico()

	if skin_metal_material == null:
		return

	# Bronze com aparência de metal/cobre, bem diferente do amarelo.
	skin_metal_material.set_shader_parameter(
		"metal_dark",
		Color("#4A2410")
	)

	skin_metal_material.set_shader_parameter(
		"metal_mid",
		Color("#A95F2A")
	)

	skin_metal_material.set_shader_parameter(
		"metal_light",
		Color("#E9A35A")
	)

	skin_metal_material.set_shader_parameter(
		"shine_strength",
		0.78
	)

	skin_metal_material.set_shader_parameter(
		"shine_speed",
		0.52
	)

	animation.material = skin_metal_material


func aplicar_metal_prata() -> void:

	if skin_metal_material == null:
		criar_shader_metalico()

	if skin_metal_material == null:
		return

	skin_metal_material.set_shader_parameter(
		"metal_dark",
		Color("#666A70")
	)

	skin_metal_material.set_shader_parameter(
		"metal_mid",
		Color("#BFC4CA")
	)

	skin_metal_material.set_shader_parameter(
		"metal_light",
		Color("#F7F9FC")
	)

	skin_metal_material.set_shader_parameter(
		"shine_strength",
		0.85
	)

	skin_metal_material.set_shader_parameter(
		"shine_speed",
		0.55
	)

	animation.material = skin_metal_material


func aplicar_metal_ouro() -> void:

	if skin_metal_material == null:
		criar_shader_metalico()

	if skin_metal_material == null:
		return

	skin_metal_material.set_shader_parameter(
		"metal_dark",
		Color("#6B3F05")
	)

	skin_metal_material.set_shader_parameter(
		"metal_mid",
		Color("#D99516")
	)

	skin_metal_material.set_shader_parameter(
		"metal_light",
		Color("#FFF0A0")
	)

	skin_metal_material.set_shader_parameter(
		"shine_strength",
		0.95
	)

	skin_metal_material.set_shader_parameter(
		"shine_speed",
		0.48
	)

	animation.material = skin_metal_material


func remover_shader_metalico() -> void:

	if animation == null:
		return

	animation.material = null


func atualizar_cor_skin() -> void:

	if animation == null:
		return

	# ------------------------------------------
	# BRONZE, PRATA E OURO = MATERIAL METÁLICO
	# ------------------------------------------

	if skin_equipada == "bronze":
		aplicar_metal_bronze()
	elif skin_equipada == "prata":
		aplicar_metal_prata()
	elif skin_equipada == "ouro":
		aplicar_metal_ouro()
	else:
		remover_shader_metalico()

	# ------------------------------------------
	# QUANDO ESTÁ TOMANDO DANO
	# ------------------------------------------

	if taking_damage:
		animation.modulate = Color(
			1.0,
			0.55,
			0.55,
			1.0
		)
		return

	# ------------------------------------------
	# SKINS METÁLICAS
	# ------------------------------------------
	# O shader cuida da cor. Aqui só controlamos o
	# brilho quando o personagem está na última vida.
	# ------------------------------------------

	if skin_equipada == "bronze" or skin_equipada == "prata" or skin_equipada == "ouro":

		var intensidade_metal: float = 1.0

		if Globals.player_life == 1:

			var blink_metal: float = abs(
				sin(
					Time.get_ticks_msec() * 0.005
				)
			)

			intensidade_metal = lerp(
				0.35,
				1.0,
				blink_metal
			)

		animation.modulate = Color(
			intensidade_metal,
			intensidade_metal,
			intensidade_metal,
			1.0
		)

		return

	# ------------------------------------------
	# SKINS NORMAIS
	# ------------------------------------------

	var cor_skin: Color = obter_cor_skin()

	if Globals.player_life == 1:

		var blink: float = abs(
			sin(
				Time.get_ticks_msec() * 0.005
			)
		)

		var intensidade: float = lerp(
			0.35,
			1.0,
			blink
		)

		cor_skin *= intensidade

	animation.modulate = cor_skin


func definir_skin_visual(skin_id: String) -> void:

	if skin_id.is_empty():
		skin_id = "original"

	if not skin_id in [
		"original",
		"bronze",
		"prata",
		"ouro",
		"azul",
		"vermelho",
		"amarelo",
		"rgb"
	]:
		skin_id = "original"

	skin_equipada = skin_id

	# Mantem a skin equipada durante toda a sessao.
	var raiz := get_tree().root

	var dados: Dictionary = {
		"skins_desbloqueadas": ["original"],
		"skin_equipada": skin_equipada
	}

	if raiz.has_meta(SKIN_META_SESSAO):
		var anterior = raiz.get_meta(SKIN_META_SESSAO)

		if typeof(anterior) == TYPE_DICTIONARY:
			if anterior.has("skins_desbloqueadas") 			and typeof(anterior["skins_desbloqueadas"]) == TYPE_ARRAY:
				dados["skins_desbloqueadas"] = anterior["skins_desbloqueadas"].duplicate()

	raiz.set_meta(SKIN_META_SESSAO, dados)

	atualizar_cor_skin()

# ==========================================
# TROCAR SKIN PELA TECLA V
# ==========================================
func trocar_skin_com_v() -> void:
	if is_dead:
		return

	if celebrating or taking_damage:
		return

	var raiz := get_tree().root

	if not raiz.has_meta(SKIN_META_SESSAO):
		return

	var dados = raiz.get_meta(SKIN_META_SESSAO)

	if typeof(dados) != TYPE_DICTIONARY:
		return

	if not dados.has("skins_desbloqueadas"):
		return

	var lista = dados["skins_desbloqueadas"]

	if typeof(lista) != TYPE_ARRAY:
		return

	# Mantém somente IDs válidos e realmente desbloqueados.
	var skins_validas: Array[String] = []

	for item in lista:
		var id := str(item)

		if id in [
			"original",
			"bronze",
			"prata",
			"ouro",
			"azul",
			"vermelho",
			"amarelo",
			"rgb"
		] and not skins_validas.has(id):
			skins_validas.append(id)

	# Só troca se houver mais de uma skin disponível.
	if skins_validas.size() <= 1:
		return

	var indice_atual := skins_validas.find(skin_equipada)

	if indice_atual < 0:
		indice_atual = 0

	var proximo_indice := (indice_atual + 1) % skins_validas.size()
	var proxima_skin := skins_validas[proximo_indice]

	# Atualiza a skin equipada sem alterar o inventário.
	skin_equipada = proxima_skin
	dados["skins_desbloqueadas"] = skins_validas.duplicate()
	dados["skin_equipada"] = skin_equipada

	raiz.set_meta(SKIN_META_SESSAO, dados)

	atualizar_cor_skin()

	print("SKIN TROCADA PELA TECLA V: ", skin_equipada)



# ==========================================
# CÂMERA
# ==========================================

func follow_camera(
	camera: Camera2D
) -> void:

	var camera_path: NodePath = (
		camera.get_path()
	)


	remote_transform.remote_path = (
		camera_path
	)
