extends CharacterBody2D

@export var speed = 100
@export var sprint_speed = 180
@export var stamina_max = 100.0
@export var stamina_drain = 20.0   # per second while sprinting
@export var stamina_regen = 10.0   # per second while not sprinting

var fear_meter
var flicker_active = false
var is_dialogue_open = false
var stamina = 100.0
var is_sprinting = false

# inventory
var evidence_count: int = 0
var battery_count: int = 0

# ── READY ─────────────────────────────────────────────────
func _ready():
	await get_tree().process_frame
	fear_meter = get_tree().get_first_node_in_group("fear_meter")
	$PointLight2D.enabled = false

# ── PHYSICS ───────────────────────────────────────────────
func _physics_process(delta):
	if is_dialogue_open:
		velocity = Vector2.ZERO
		move_and_slide()
		$AnimatedSprite2D.play("Idle")
		return

	if fear_meter and fear_meter.value >= 100:
		var battery_bar = get_tree().get_first_node_in_group("battery")
		if $PointLight2D.enabled:
			$PointLight2D.enabled = false
			if battery_bar:
				battery_bar.turn_off()
		_on_fear_full()
		return

	# stamina logic
	_handle_stamina(delta)

	var input_dir = Input.get_vector("left", "right", "up", "down")

	# sprint only if holding shift and has stamina
	if Input.is_action_pressed("sprint") and stamina > 0 and input_dir != Vector2.ZERO:
		is_sprinting = true
		velocity = input_dir * sprint_speed
	else:
		is_sprinting = false
		velocity = input_dir * speed

	move_and_slide()

	if input_dir.x != 0:
		$AnimatedSprite2D.flip_h = input_dir.x < 0

	_animation(input_dir)

# ── STAMINA ───────────────────────────────────────────────
func _handle_stamina(delta):
	if is_sprinting and stamina > 0:
		stamina -= stamina_drain * delta
		stamina = max(0, stamina)
	else:
		stamina += stamina_regen * delta
		stamina = min(stamina_max, stamina)

	# debug print — remove later when stamina bar is added
	# print("Stamina: ", stamina)

# ── ANIMATION ─────────────────────────────────────────────
func _animation(dir):
	if dir != Vector2.ZERO:
		$AnimatedSprite2D.play("Walking")
	else:
		$AnimatedSprite2D.play("Idle")

# ── INPUT ─────────────────────────────────────────────────
func _input(event):
	if event.is_action_pressed("flashlight"):
		var battery_bar = get_tree().get_first_node_in_group("battery")
		if not battery_bar:
			return
		if not $PointLight2D.enabled and battery_bar.battery <= 0:
			return
		if flicker_active:
			return
		$PointLight2D.enabled = !$PointLight2D.enabled
		if $PointLight2D.enabled:
			battery_bar.turn_on()
		else:
			battery_bar.turn_off()

	if event.is_action_pressed("interact"):
		var interactable = _get_interactable()
		if interactable == null:
			show_message("Nothing here.")
		elif interactable.is_in_group("battery"):
			_pickup_battery(interactable)
		elif interactable.is_in_group("evidence"):
			_pickup_evidence(interactable)
		else:
			show_message("Nothing here.")

# ── PICKUP HANDLERS ───────────────────────────────────────
func _pickup_battery(item):
	var battery_bar = get_tree().get_first_node_in_group("battery")
	if battery_bar:
		battery_bar.add_battery(20.0)
	battery_count += 1
	print("Battery picked up! Total: ", battery_count)
	show_message("Found a battery!")
	item.pickup()

func _pickup_evidence(item):
	evidence_count += 1
	print("Evidence picked up! Total: ", evidence_count)
	_increase_difficulty()
	show_message("Found evidence! (" + str(evidence_count) + ")")
	item.pickup()

# ── DIFFICULTY ────────────────────────────────────────────
func _increase_difficulty():
	var enemy = get_tree().get_first_node_in_group("enemy")
	if enemy:
		enemy.chase_speed += 5
		enemy.detection_radius += 10
		print("Enemy stronger! Speed: ", enemy.chase_speed, " Detection: ", enemy.detection_radius)

# ── INTERACTABLE DETECTION ────────────────────────────────
func _get_interactable():
	for area in $InteractionArea.get_overlapping_areas():
		if area.is_in_group("battery") or area.is_in_group("evidence"):
			return area
	return null

# ── DIALOGUE ──────────────────────────────────────────────
func show_message(text):
	is_dialogue_open = true
	$CanvasLayer/TextBox/NinePatchRect.start_dialogue(text)

# ── FEAR FULL ─────────────────────────────────────────────
func _on_fear_full():
	set_physics_process(false)
	set_process_input(false)
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

# ── NEARBY ITEMS ──────────────────────────────────────────
func add_to_nearby_items(item):
	pass

func remove_from_nearby_items(item):
	pass
