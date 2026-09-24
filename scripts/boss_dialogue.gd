extends Node

signal intro_finished
signal victory_finished

const INTRO_LINES: Array[String] = [
	"GUARDIAO: Entao... voce finalmente chegou.",
	"GUARDIAO: Eu estava esperando por voce.",
	"PINGUIM: Onde estao minhas memorias?",
	"GUARDIAO: Voce ja recuperou grande parte delas durante sua jornada.",
	"PINGUIM: Raciocinio... atencao... memoria...",
	"PINGUIM: Eu passei por tudo isso para chegar ate aqui.",
	"GUARDIAO: Exatamente.",
	"GUARDIAO: Cada mundo devolveu uma parte do que voce perdeu.",
	"GUARDIAO: No primeiro, voce recuperou seu raciocinio.",
	"GUARDIAO: No segundo, sua atencao.",
	"GUARDIAO: E no terceiro... sua memoria.",
	"PINGUIM: Entao por que eu ainda nao consigo lembrar quem eu sou?",
	"GUARDIAO: Porque suas memorias voltaram... mas a verdade ainda permanece escondida.",
	"PINGUIM: E voce sabe quem eu sou?",
	"GUARDIAO: Sei.",
	"PINGUIM: Entao me conte.",
	"GUARDIAO: Nao posso.",
	"PINGUIM: Por que?",
	"GUARDIAO: Porque essa resposta esta dentro de voce.",
	"GUARDIAO: Eu sou apenas o ultimo obstaculo entre voce e suas lembrancas.",
	"PINGUIM: Entao e voce que esta me impedindo de lembrar?",
	"GUARDIAO: Nao estou impedindo.",
	"GUARDIAO: Estou testando se voce esta pronto.",
	"PINGUIM: Entao eu vou descobrir a verdade.",
	"GUARDIAO: Venha, Pinguim.",
	"GUARDIAO: Derrote-me... e talvez voce finalmente descubra quem realmente eh."
]

const VICTORY_LINES: Array[String] = [
	"GUARDIAO: Eu... fui derrotado.",
	"PINGUIM: Agora me diga... quem eu sou?",
	"GUARDIAO: Voce ja recuperou seu raciocinio.",
	"GUARDIAO: Recuperou sua atencao.",
	"GUARDIAO: Recuperou sua memoria.",
	"GUARDIAO: E agora recuperou a ultima parte que faltava.",
	"PINGUIM: Entao... eu finalmente me lembro.",
	"GUARDIAO: Sim.",
	"GUARDIAO: Nada mais esta escondido.",
	"PINGUIM: Eu me lembro de quem sou.",
	"PINGUIM: E agora... posso voltar para casa."
]

var boss: Node2D = null
var waiting: bool = false
var active_dialogue: String = ""

const DIALOGUE_OFFSET: Vector2 = Vector2(
	0.0,
	-8.0
)

var last_boss_dialogue_position: Vector2 = Vector2.ZERO
var has_last_boss_dialogue_position: bool = false


func setup(boss_node: Node2D) -> void:
	boss = boss_node


func start_intro() -> void:
	if waiting:
		return
	if not is_instance_valid(boss):
		return
	if DialogManager.is_message_active:
		return

	last_boss_dialogue_position = (
		boss.global_position
		+
		DIALOGUE_OFFSET
	)

	has_last_boss_dialogue_position = true

	active_dialogue = "intro"
	waiting = true

	DialogManager.start_message(
		last_boss_dialogue_position,
		INTRO_LINES,
		self
	)


func start_victory() -> void:
	if waiting:
		return

	if DialogManager.is_message_active:
		return

	if is_instance_valid(boss):
		last_boss_dialogue_position = (
			boss.global_position
			+
			DIALOGUE_OFFSET
		)

		has_last_boss_dialogue_position = true

	elif not has_last_boss_dialogue_position:
		return

	active_dialogue = "victory"
	waiting = true

	DialogManager.start_message(
		last_boss_dialogue_position,
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
