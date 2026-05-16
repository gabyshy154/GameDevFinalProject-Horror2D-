extends Area2D

@export var target_scene: String = "res://Scene/Village.tscn"

func _ready():
	body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		SavePoint.save_inventory(body)
		SavePoint.respawn_position = body.global_position
		SavePoint.current_scene = target_scene
		SavePoint.has_save = true
		get_tree().call_deferred("change_scene_to_file", target_scene)
