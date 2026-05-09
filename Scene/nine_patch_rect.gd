extends NinePatchRect

@export var typing_speed = 0.05
var full_text = ""
var displayed_text = ""
var char_index = 0

func start_dialogue(text):
	full_text = text
	displayed_text = ""
	char_index = 0
	$MarginContainer/Label.text = ""
	get_parent().visible = true
	$TypingTimer.start()

func _on_typing_timer_timeout():
	if char_index < full_text.length():
		displayed_text += full_text[char_index]
		$MarginContainer/Label.text = displayed_text
		char_index += 1
	else:
		$TypingTimer.stop()
		$Timer.start()

func _on_timer_timeout():
	get_parent().visible = false
	get_tree().get_first_node_in_group("Player").is_dialogue_open = false
