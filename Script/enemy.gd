extends CharacterBody2D

@export var patrol_speed = 50
@export var chase_speed = 70
@export var detection_radius = 50.0
@export var lose_sight_radius = 300.0

# Fear settings
@export var fear_increase_when_near = 0.2
@export var fear_increase_when_chasing = 0.05
@export var near_radius = 80.0

enum State { PATROL, CHASE, SEARCH }
var state = State.PATROL

var player: Node2D = null
var patrol_points: Array = []
var patrol_index: int = 0
var search_timer: float = 0.0
var search_duration: float = 3.0
var fear_bar: Node = null

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	fear_bar = get_tree().get_first_node_in_group("fear_meter")

	patrol_points = [
		global_position + Vector2(-100, 0),
		global_position + Vector2(100, 0)
	]

func _physics_process(delta):
	match state:
		State.PATROL:
			_do_patrol()
			_check_for_player()
		State.CHASE:
			_do_chase()
			_check_lost_player()
		State.SEARCH:
			_do_search(delta)

	_handle_fear(delta)

# ── PATROL ──────────────────────────────────────────────
func _do_patrol():
	if patrol_points.is_empty():
		return

	var target = patrol_points[patrol_index]
	var direction = (target - global_position).normalized()
	velocity = direction * patrol_speed
	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

	$AnimatedSprite2D.play("Walking")

	if global_position.distance_to(target) < 8.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()

# ── CHASE ────────────────────────────────────────────────
func _do_chase():
	if player == null:
		state = State.PATROL
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

	$AnimatedSprite2D.play("Walking")

# ── SEARCH ───────────────────────────────────────────────
func _do_search(delta):
	velocity = Vector2.ZERO
	move_and_slide()
	$AnimatedSprite2D.play("Idle")

	search_timer += delta
	if search_timer >= search_duration:
		search_timer = 0.0
		state = State.PATROL

# ── DETECTION ────────────────────────────────────────────
func _check_for_player():
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= detection_radius:
		state = State.CHASE

func _check_lost_player():
	if player == null:
		state = State.SEARCH
		return
	var dist = global_position.distance_to(player.global_position)
	if dist > lose_sight_radius:
		state = State.SEARCH

# ── FEAR ─────────────────────────────────────────────────
func _handle_fear(delta):
	if fear_bar == null or player == null:
		return

	#var dist = global_position.distance_to(player.global_position)

	if state == State.CHASE:
		fear_bar.add_fear(fear_increase_when_chasing * delta * 60)

	#if dist <= near_radius:
		#fear_bar.add_fear(fear_increase_when_near * delta * 60)
