extends CanvasLayer

@onready var resume_btn = $menu_houder/resume_btn
@onready var quit_btn = $menu_houder/quit_btn


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Garante que os botões funcionem durante o pause
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Garante que os sinais estejam conectados
	if not resume_btn.pressed.is_connected(_on_resume_btn_pressed):
		resume_btn.pressed.connect(_on_resume_btn_pressed)
	
	if not quit_btn.pressed.is_connected(_on_quit_btn_pressed):
		quit_btn.pressed.connect(_on_quit_btn_pressed)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()


func pause_game():
	visible = true
	get_tree().paused = true


func resume_game():
	get_tree().paused = false
	visible = false


func _on_resume_btn_pressed():
	resume_game()


func _on_quit_btn_pressed():
	get_tree().paused = false
	get_tree().quit()
