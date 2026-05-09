extends CharacterBody2D
@export var speed = 200
var fear_meter
var flicker_active = false
var is_dialogue_open = false

func _ready():
	await get_tree().process_frame
	fear_meter = get_tree().get_first_node_in_group("fear_meter")
	$PointLight2D.enabled = false

func _physics_process(_delta):
	if is_dialogue_open:
		velocity = Vector2.ZERO
		move_and_slide()
		$AnimatedSprite2D.play("Idle")
		return
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()
	if input_dir.x != 0:
		$AnimatedSprite2D.flip_h = input_dir.x < 0
	_animation(input_dir)

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
			show_message("Nothing to use here.")
		elif interactable.is_in_group("battery"):
			show_message("Got the battery!")
		elif interactable.is_in_group("evidence"):
			show_message("Found evidence!")
		else:
			show_message("Nothing to use here.")

func _get_interactable():
	for body in $InteractionArea.get_overlapping_bodies():
		if body.is_in_group("battery") or body.is_in_group("evidence"):
			return body
	return null

func show_message(text):
	is_dialogue_open = true
	$CanvasLayer/TextBox/NinePatchRect.start_dialogue(text)
