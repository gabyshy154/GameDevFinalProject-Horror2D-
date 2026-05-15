extends Node

var respawn_position: Vector2 = Vector2.ZERO
var current_scene: String = ""
var has_save: bool = false

func save():
	# store current scene and position
	current_scene = get_tree().current_scene.scene_file_path
	has_save = true

func respawn():
	if not has_save:
		get_tree().reload_current_scene()
		return
	# reload the scene and move player to saved position
	get_tree().change_scene_to_file(current_scene)
