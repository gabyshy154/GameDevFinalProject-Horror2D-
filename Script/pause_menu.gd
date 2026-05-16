extends CanvasLayer

func _ready():
	# hide pause menu at start
	visible = false
	# pause menu should not be affected by game pause
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()

func _pause():
	get_tree().paused = true
	visible = true

func _resume():
	get_tree().paused = false
	visible = false

func _on_resume_button_pressed():
	_resume()

func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().quit()
