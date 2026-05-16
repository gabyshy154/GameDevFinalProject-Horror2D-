extends Area2D

@export var target_scene: String = "res://first_tunnel.tscn"
@export var spawn_position: Vector2 = Vector2(37, 352)

func _ready():
	body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		call_deferred("_do_transition", body)

func _do_transition(body: Node2D) -> void:
	SavePoint.save_inventory(body)
	SavePoint.respawn_position = spawn_position
	SavePoint.current_scene = target_scene
	SavePoint.has_save = true
	get_tree().change_scene_to_file(target_scene)
