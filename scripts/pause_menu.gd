extends CanvasLayer


@onready var resume_btn = $menu_houder/resume_btn
@onready var restart_btn = $menu_houder/restart_btn
@onready var quit_btn = $menu_houder/quit_btn
@onready var bg_overlay = $bg_overlay


func _ready():

	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS

	resume_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	quit_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	resume_btn.focus_mode = Control.FOCUS_ALL
	restart_btn.focus_mode = Control.FOCUS_ALL
	quit_btn.focus_mode = Control.FOCUS_ALL


	if not resume_btn.pressed.is_connected(_on_resume_btn_pressed):
		resume_btn.pressed.connect(_on_resume_btn_pressed)

	if not restart_btn.pressed.is_connected(_on_restart_btn_pressed):
		restart_btn.pressed.connect(_on_restart_btn_pressed)

	if not quit_btn.pressed.is_connected(_on_quit_btn_pressed):
		quit_btn.pressed.connect(_on_quit_btn_pressed)


func _input(event):

	if get_tree().paused:

		if event is InputEventKey:

			if event.pressed and event.keycode == KEY_SPACE:

				return


func _unhandled_input(event):

	if event.is_action_pressed("ui_cancel"):

		if get_tree().paused:

			resume_game()

		else:

			pause_game()

		return


	if get_tree().paused and event is InputEventKey and event.pressed:

		if event.keycode == KEY_W or event.keycode == KEY_UP:

			if resume_btn.has_focus():

				quit_btn.grab_focus()

			elif restart_btn.has_focus():

				resume_btn.grab_focus()

			elif quit_btn.has_focus():

				restart_btn.grab_focus()

			else:

				resume_btn.grab_focus()


		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:

			if resume_btn.has_focus():

				restart_btn.grab_focus()

			elif restart_btn.has_focus():

				quit_btn.grab_focus()

			elif quit_btn.has_focus():

				resume_btn.grab_focus()

			else:

				resume_btn.grab_focus()


		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:

			if resume_btn.has_focus():

				resume_game()

			elif restart_btn.has_focus():

				restart_game()

			elif quit_btn.has_focus():

				quit_game()


func pause_game():

	visible = true
	get_tree().paused = true

	resume_btn.grab_focus()


func resume_game():

	get_tree().paused = false
	visible = false


func restart_game():

	# ==========================================
	# RESET DOS DADOS DA PARTIDA
	# ==========================================

	Globals.coins = 0
	Globals.score = 0

	Globals.level_coins = 0
	Globals.level_score = 0

	# RESET DOS FRAGMENTOS
	Globals.raciocinio_fragments = 0


	print("==============================")
	print("RESTART DA FASE")
	print("MOEDAS RESETADAS: ", Globals.coins)
	print("SCORE RESETADO: ", Globals.score)
	print(
		"FRAGMENTOS RESETADOS: ",
		Globals.raciocinio_fragments
	)
	print("==============================")


	get_tree().paused = false
	visible = false

	get_tree().reload_current_scene()


func quit_game():

	get_tree().paused = false
	get_tree().quit()


func _on_resume_btn_pressed():

	resume_game()


func _on_restart_btn_pressed():

	restart_game()


func _on_quit_btn_pressed():

	quit_game()
