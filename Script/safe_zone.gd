extends Area2D

@export var fear_drain_speed = 5.0
@export var drain_interval = 0.5

var fear_bar: Node = null
var player_inside: bool = false
var player: Node = null
@onready var timer = $Timer

func _ready():
	fear_bar = get_tree().get_first_node_in_group("fear_meter")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.wait_time = drain_interval
	timer.stop()
	timer.timeout.connect(_on_timer_timeout)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		player_inside = true
		timer.start()

		# save respawn point when player enters
		SavePoint.respawn_position = global_position
		SavePoint.save()
		print("Game saved at safe zone: ", global_position)

		if fear_bar:
			fear_bar.paused = true

		var enemy = get_tree().get_first_node_in_group("enemy")
		if enemy:
			enemy.player_in_safezone = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player = null
		player_inside = false
		timer.stop()

		if fear_bar:
			fear_bar.paused = false

		var enemy = get_tree().get_first_node_in_group("enemy")
		if enemy:
			enemy.player_in_safezone = false

func _on_timer_timeout():
	if not player_inside or fear_bar == null:
		return
	if fear_bar.fear > 0:
		fear_bar.fear -= fear_drain_speed
		fear_bar.fear = max(0, fear_bar.fear)  # clamp so it never goes below 0
		fear_bar.target_fear = fear_bar.fear # update target so bar visually decreases
		fear_bar.value = fear_bar.target_fear # force visual bar to update
