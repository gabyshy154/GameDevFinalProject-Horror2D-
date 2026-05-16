extends Node

var respawn_position: Vector2 = Vector2.ZERO
var current_scene: String = ""
var has_save: bool = false

# inventory that persists across scenes
var has_flashlight: bool = false
var evidence_count: int = 0
var battery_count: int = 0

func save():
	current_scene = get_tree().current_scene.scene_file_path
	has_save = true

func save_inventory(player):
	has_flashlight = player.has_flashlight
	evidence_count = player.evidence_count
	battery_count = player.battery_count

func respawn():
	if not has_save:
		get_tree().reload_current_scene()
		return
	get_tree().change_scene_to_file(current_scene)
