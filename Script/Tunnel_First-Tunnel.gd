extends Area2D

@export var target_scene: String = "res://first_tunnel.tscn"

func _ready():
	body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file(target_scene)
