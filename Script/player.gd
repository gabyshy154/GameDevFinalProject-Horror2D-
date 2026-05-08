extends CharacterBody2D

@export var speed = 200
var fear_meter
var flicker_active = false

func _ready():
	await get_tree().process_frame
	fear_meter = get_tree().get_first_node_in_group("fear_meter")
	$PointLight2D.enabled = false

func _physics_process(_delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()

	if input_dir.x != 0:
		$AnimatedSprite2D.flip_h = input_dir.x < 0
	_animation(input_dir)

	if fear_meter and fear_meter.value >= 100:
		var battery_bar = get_tree().get_first_node_in_group("battery")
		if battery_bar and battery_bar.is_on and not flicker_active:
			_start_flicker()
	else:
		if flicker_active:
			flicker_active = false
			$PointLight2D.enabled = true

func _animation(dir):
	if dir != Vector2.ZERO:
		$AnimatedSprite2D.play("Walking")
	else:
		$AnimatedSprite2D.play("Idle")

func _input(event):
	if event.is_action_pressed("flashlight"):
		var battery_bar = get_tree().get_first_node_in_group("battery")

		if not battery_bar:
			return

		if not $PointLight2D.enabled and battery_bar.battery <= 0:
			return

		# block toggle while flickering
		if flicker_active:
			return

		$PointLight2D.enabled = !$PointLight2D.enabled

		if $PointLight2D.enabled:
			battery_bar.turn_on()
		else:
			battery_bar.turn_off()

func _start_flicker():
	if flicker_active:
		return
	flicker_active = true
	_do_flicker()

func _do_flicker():
	if not flicker_active:
		return

	if fear_meter and fear_meter.value < 100:
		flicker_active = false
		$PointLight2D.enabled = true
		return

	$PointLight2D.enabled = false
	await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
	if not flicker_active or fear_meter.value < 100:
		flicker_active = false
		$PointLight2D.enabled = true
		return

	$PointLight2D.enabled = true
	await get_tree().create_timer(randf_range(0.05, 0.3)).timeout
	if not flicker_active or fear_meter.value < 100:
		flicker_active = false
		$PointLight2D.enabled = true
		return

	$PointLight2D.enabled = false
	await get_tree().create_timer(randf_range(0.1, 0.25)).timeout
	if not flicker_active or fear_meter.value < 100:
		flicker_active = false
		$PointLight2D.enabled = true
		return

	$PointLight2D.enabled = true
	await get_tree().create_timer(randf_range(0.3, 0.8)).timeout
	if not flicker_active or fear_meter.value < 100:
		flicker_active = false
		$PointLight2D.enabled = true
		return

	_do_flicker()
