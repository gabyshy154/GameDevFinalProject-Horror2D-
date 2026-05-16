extends CharacterBody2D

enum State { WAIT, FOLLOW }
var state = State.WAIT

var player: Node2D = null
@export var follow_distance = 40.0    # ideal distance to keep from player
@export var min_distance = 25.0       # minimum distance before stopping
@export var walk_speed = 95.0
@export var run_speed = 175.0

var is_found = false

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta):
	if state == State.WAIT or player == null:
		$AnimatedSprite2D.play("Idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_follow_player()

func _follow_player():
	var dist = global_position.distance_to(player.global_position)

	# too close — push away slightly to avoid overlap
	if dist < min_distance:
		var push_away = (global_position - player.global_position).normalized()
		velocity = push_away * walk_speed
		move_and_slide()
		$AnimatedSprite2D.play("Idle")
		return

	# close enough — stop and idle
	if dist <= follow_distance:
		$AnimatedSprite2D.play("Idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# follow player and match their speed
	var direction = (player.global_position - global_position).normalized()

	if player.is_sprinting:
		velocity = direction * run_speed
		$AnimatedSprite2D.play("Run")
	else:
		velocity = direction * walk_speed
		$AnimatedSprite2D.play("Walking")

	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

func interact():
	if is_found:
		return
	is_found = true
	state = State.FOLLOW
