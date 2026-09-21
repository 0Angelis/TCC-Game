extends Node

signal intro_finished
signal victory_finished

const INTRO_LINES: Array[String] = [
	"GUARDIAO: Entao... voce finalmente chegou.",
	"GUARDIAO: Eu estava esperando por voce.",
	"PLAYER: Onde estao minhas memorias?",
	"GUARDIAO: Voce chama de memoria aquilo que deixou para tras durante sua jornada.",
	"PLAYER: Foi voce quem tirou elas de mim?",
	"GUARDIAO: Eu apenas guardei o que voce ainda nao estava pronto para recuperar.",
	"GUARDIAO: Em cada mundo, voce aprendeu uma parte do caminho.",
	"GUARDIAO: Aprendeu a raciocinar. Aprendeu a prestar atencao. Aprendeu a lembrar.",
	"GUARDIAO: Mas aprender nao basta.",
	"PLAYER: Entao o que eu preciso fazer?",
	"GUARDIAO: Me derrotar.",
	"GUARDIAO: Mas voce nao vai vencer usando apenas forca.",
	"GUARDIAO: Eu vou cansar voce. Vou pressionar suas escolhas. Vou testar tudo o que aprendeu.",
	"GUARDIAO: Quando eu cair, suas memorias serao devolvidas.",
	"GUARDIAO: Ate la... sobreviva.",
	"GUARDIAO: Venha. Vamos descobrir se voce realmente se lembra de quem e."
]

const VICTORY_LINES: Array[String] = [
	"GUARDIAO: Eu... fui derrotado.",
	"GUARDIAO: Entao voce realmente aprendeu.",
	"PLAYER: Minhas memorias... agora.",
	"GUARDIAO: Elas nunca estiveram perdidas.",
	"GUARDIAO: Raciocinio. Atencao. Memoria.",
	"GUARDIAO: Tudo o que voce buscava estava sendo reconstruido dentro de voce.",
	"GUARDIAO: Agora e hora de lembrar."
]

var boss: Node2D = null
var waiting: bool = false
var active_dialogue: String = ""


func setup(boss_node: Node2D) -> void:
	boss = boss_node


func start_intro() -> void:
	if waiting:
		return
	if not is_instance_valid(boss):
		return
	if DialogManager.is_message_active:
		return

	active_dialogue = "intro"
	waiting = true

	DialogManager.start_message(
		boss.global_position + Vector2(0.0, -25.0),
		INTRO_LINES,
		self
	)


func start_victory() -> void:
	if waiting:
		return
	if not is_instance_valid(boss):
		return
	if DialogManager.is_message_active:
		return

	active_dialogue = "victory"
	waiting = true

	DialogManager.start_message(
		boss.global_position + Vector2(0.0, -25.0),
		VICTORY_LINES,
		self
	)


func _process(_delta: float) -> void:
	if not waiting:
		return
	if DialogManager.is_message_active:
		return

	waiting = false

	if active_dialogue == "intro":
		intro_finished.emit()
	elif active_dialogue == "victory":
		victory_finished.emit()

	active_dialogue = ""


func force_close() -> void:
	if waiting and DialogManager.is_message_active:
		if DialogManager.current_source == self:
			DialogManager.close_message()

	waiting = false
	active_dialogue = ""
