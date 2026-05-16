extends CharacterBody2D

@export var patrol_speed = 50
@export var chase_speed = 120
@export var lose_sight_radius = 300.0

# Radius settings
@export var patrol_radius = 150.0
@export var chase_radius = 250.0

# Fear settings
@export var fear_increase_when_chasing = 0.3

enum State { PATROL, CHASE, SEARCH, RETURN, ATTACK }
var state = State.PATROL

var player: Node2D = null
var patrol_points: Array = []
var patrol_index: int = 0
var search_timer: float = 0.0
var search_duration: float = 3.0
var fear_bar: Node = null
var home_position: Vector2
var player_in_safezone: bool = false
var has_attacked: bool = false

# patrol wait
var wait_timer: float = 0.0
var wait_duration: float = 0.0
var is_waiting: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	fear_bar = get_tree().get_first_node_in_group("fear_meter")
	home_position = global_position
	_generate_patrol_points()
	var area = $DetectionArea
	area.body_entered.connect(_on_detection_area_body_entered)
	area.body_exited.connect(_on_detection_area_body_exited)

func _generate_patrol_points():
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
		State.RETURN:
			_do_return()
		State.ATTACK:
			# stick to player during attack
			if player != null:
				global_position = player.global_position + Vector2(10, 0)
				# keep facing player
				var direction = player.global_position - global_position
				$AnimatedSprite2D.flip_h = direction.x < 0

	_handle_fear(delta)

# ── PATROL ──────────────────────────────────────────────
func _do_patrol(delta):
	if patrol_points.is_empty():
		return

	if is_waiting:
		wait_timer += delta
		velocity = Vector2.ZERO
		move_and_slide()
		$AnimatedSprite2D.play("Walking")
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
		is_waiting = true
		wait_duration = randf_range(0.5, 2.0)

# ── CHASE ────────────────────────────────────────────────
func _do_chase():
	if player == null:
		state = State.PATROL
		return

	if player_in_safezone:
		state = State.RETURN
		$Audio_Chase.stop()
		return

	if not $Audio_Chase.playing:
		$Audio_Chase.play()

	# if fear is full get close then trigger attack
	if fear_bar and fear_bar.fear >= 100 and not has_attacked:
		var dist = global_position.distance_to(player.global_position)
		if dist < 20.0:
			_do_attack()
			return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

	$AnimatedSprite2D.play("Run")

# ── ATTACK ───────────────────────────────────────────────
func _do_attack():
	if has_attacked:
		return
	has_attacked = true
	state = State.ATTACK
	$Audio_Chase.stop()
	$Audio_Captured.play()

	# face the player direction
	if player != null:
		var direction = player.global_position - global_position
		$AnimatedSprite2D.flip_h = direction.x < 0

	$AnimatedSprite2D.play("Attack")

	# freeze player immediately
	if player != null:
		player.set_physics_process(false)
		player.set_process_input(false)
		player.get_node("AnimatedSprite2D").play("Idle")

	# use timer instead of waiting for animation
	await get_tree().create_timer(2.0).timeout
	_kill_player()

func _kill_player():
	if player == null:
		return
	state = State.RETURN
	player.on_attacked()

# remove _stick_to_player and _follow_and_wait entirely

# ── SEARCH ───────────────────────────────────────────────
func _do_search(delta):
	velocity = Vector2.ZERO
	move_and_slide()
	$AnimatedSprite2D.play("Walking")

	search_timer += delta
	if search_timer >= search_duration:
		search_timer = 0.0
		_generate_patrol_points()
		state = State.RETURN

# ── RETURN HOME ──────────────────────────────────────────
func _do_return():
	$Audio_Chase.stop()
	var direction = (home_position - global_position).normalized()
	velocity = direction * patrol_speed
	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

	$AnimatedSprite2D.play("Walking")

	if global_position.distance_to(home_position) < 10.0:
		_generate_patrol_points()
		state = State.PATROL

# ── DETECTION via Area2D ─────────────────────────────────
func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		if not player_in_safezone:
			state = State.CHASE
			$Audio_Spotted.play()

func _on_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		state = State.SEARCH
		$Audio_Chase.stop()

func _check_lost_player():
	if player == null:
		state = State.SEARCH
		return
	var dist_from_home = global_position.distance_to(home_position)
	if dist_from_home > chase_radius:
		state = State.RETURN

# ── FEAR ─────────────────────────────────────────────────
func _handle_fear(delta):
	if fear_bar == null or player == null:
		return
	if state == State.CHASE and not player_in_safezone:
		fear_bar.set_chasing(true)
		fear_bar.add_fear(fear_increase_when_chasing * delta * 60)
	else:
		fear_bar.set_chasing(false)
