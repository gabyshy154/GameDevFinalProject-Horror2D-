extends CharacterBody2D

@export var patrol_speed = 50
@export var chase_speed = 50
@export var lose_sight_radius = 300.0

# Radius settings
@export var patrol_radius = 150.0
@export var chase_radius = 250.0

# Fear settings
@export var fear_increase_when_chasing = 0.03

enum State { PATROL, CHASE, SEARCH }
var state = State.PATROL

var player: Node2D = null
var patrol_points: Array = []
var patrol_index: int = 0
var search_timer: float = 0.0
var search_duration: float = 3.0
var fear_bar: Node = null
var home_position: Vector2

# patrol wait
var wait_timer: float = 0.0
var wait_duration: float = 0.0
var is_waiting: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	fear_bar = get_tree().get_first_node_in_group("fear_meter")
	home_position = global_position

	_generate_patrol_points()

	# connect Area2D signal for instant detection
	var area = $DetectionArea
	area.body_entered.connect(_on_detection_area_body_entered)
	area.body_exited.connect(_on_detection_area_body_exited)

func _generate_patrol_points():
	# generate random points within patrol radius instead of just left and right
	patrol_points.clear()
	var num_points = randi_range(3, 6)
	for i in num_points:
		var angle = (float(i) / num_points) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(patrol_radius * 0.4, patrol_radius)
		patrol_points.append(home_position + offset)
	patrol_index = 0

func _physics_process(delta):
	match state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase()
			_check_lost_player()
		State.SEARCH:
			_do_search(delta)

	_handle_fear(delta)

# ── PATROL ──────────────────────────────────────────────
func _do_patrol(delta):
	if patrol_points.is_empty():
		return

	# wait at patrol point for a moment before moving
	if is_waiting:
		wait_timer += delta
		velocity = Vector2.ZERO
		move_and_slide()
		$AnimatedSprite2D.play("Idle")
		if wait_timer >= wait_duration:
			is_waiting = false
			wait_timer = 0.0
			patrol_index = (patrol_index + 1) % patrol_points.size()
		return

	var target = patrol_points[patrol_index]
	var direction = (target - global_position).normalized()
	velocity = direction * patrol_speed
	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

	$AnimatedSprite2D.play("Walking")

	if global_position.distance_to(target) < 8.0:
		# pause at each point for a random duration
		is_waiting = true
		wait_duration = randf_range(0.5, 2.0)

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
		_generate_patrol_points()  # generate fresh patrol path after searching
		state = State.PATROL

# ── DETECTION via Area2D ─────────────────────────────────
func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		state = State.CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		state = State.SEARCH

func _check_lost_player():
	if player == null:
		state = State.SEARCH
		return

	var dist_from_home = global_position.distance_to(home_position)
	if dist_from_home > chase_radius:
		state = State.SEARCH

# ── FEAR ─────────────────────────────────────────────────
func _handle_fear(delta):
	if fear_bar == null or player == null:
		return

	if state == State.CHASE:
		fear_bar.add_fear(fear_increase_when_chasing * delta * 60)
