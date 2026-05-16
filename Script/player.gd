extends CharacterBody2D

@export var speed = 100
@export var sprint_speed = 180
@export var stamina_max = 100.0
@export var stamina_drain = 20.0
@export var stamina_regen = 10.0
@export var stamina_recover_threshold = 30.0  # how much stamina needed to sprint again

var fear_meter
var flicker_active = false
var is_dialogue_open = false
var stamina = 100.0
var is_sprinting = false
var last_direction = Vector2.DOWN
var has_flashlight: bool = false
var soma_found: bool = false

# inventory
var evidence_count: int = 0
var battery_count: int = 0
var stamina_depleted = false

func _ready():
	await get_tree().process_frame
	fear_meter = get_tree().get_first_node_in_group("fear_meter")
	$PointLight2D.enabled = false

	if SavePoint.has_save:
		global_position = SavePoint.respawn_position
		# restore inventory from SavePoint
		has_flashlight = SavePoint.has_flashlight
		evidence_count = SavePoint.evidence_count
		battery_count = SavePoint.battery_count

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

	_update_light_intensity()
	_handle_stamina(delta)

	var input_dir = Input.get_vector("left", "right", "up", "down")

	if Input.is_action_pressed("sprint") and stamina > 0 and input_dir != Vector2.ZERO and not stamina_depleted:
		is_sprinting = true
		velocity = input_dir * sprint_speed
	else:
		is_sprinting = false
		velocity = input_dir * speed

	move_and_slide()

	if input_dir.x != 0:
		$AnimatedSprite2D.flip_h = input_dir.x < 0

	if input_dir != Vector2.ZERO:
		last_direction = input_dir.normalized()
		_update_interaction_area()

	_animation(input_dir)

func _update_interaction_area():
	var offset = Vector2.ZERO
	if last_direction.y > 0.5:
		offset = Vector2(-4, 20)
	elif last_direction.y < -0.5:
		offset = Vector2(-4, -45)
	elif last_direction.x > 0.5:
		offset = Vector2(22, -12)
	elif last_direction.x < -0.5:
		offset = Vector2(-32, -12)
	$InteractionArea/CollisionShape2D.position = offset

func _handle_stamina(delta):
	if is_sprinting and stamina > 0 and not stamina_depleted:
		stamina -= stamina_drain * delta
		stamina = max(0, stamina)
		if stamina <= 0:
			stamina_depleted = true
	else:
		stamina += stamina_regen * delta
		stamina = min(stamina_max, stamina)
		if stamina >= stamina_recover_threshold:
			stamina_depleted = false

	var stamina_bar = get_tree().get_first_node_in_group("stamina_bar")
	if stamina_bar:
		stamina_bar.update_stamina(stamina)

func _animation(dir):
	if not has_flashlight:
		if dir != Vector2.ZERO:
			if is_sprinting:
				$AnimatedSprite2D.play("Run")
			else:
				$AnimatedSprite2D.play("Walking")
		else:
			$AnimatedSprite2D.play("Idle")
	elif $PointLight2D.enabled:
		if dir != Vector2.ZERO:
			if is_sprinting:
				$AnimatedSprite2D.play("With_Flashlight_On_Run")
			else:
				$AnimatedSprite2D.play("With_Flashlight_On_Walking")
		else:
			$AnimatedSprite2D.play("With_Flashlight_On_Idle")
	else:
		if dir != Vector2.ZERO:
			if is_sprinting:
				$AnimatedSprite2D.play("With_Flashlight_Off_Run")
			else:
				$AnimatedSprite2D.play("With_Flashlight_Off_Walking")
		else:
			$AnimatedSprite2D.play("With_Flashlight_Off_Idle")

func _input(event):
	if is_dialogue_open:
		return

	if event.is_action_pressed("flashlight"):
		if not has_flashlight:
			return
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
			show_message("Nothing of use here.")
		elif interactable.is_in_group("soma") and not soma_found:
			soma_found = true
			interactable.interact()
			show_message("Soma! I finally found you! Are you okay?")
		elif interactable.is_in_group("soma") and soma_found:
			show_message("Stay close Soma, this place is dangerous.")
		elif interactable.is_in_group("flashlight_item"):
			_pickup_flashlight(interactable)
		elif interactable.is_in_group("battery"):
			_pickup_battery(interactable)
		elif interactable.is_in_group("evidence"):
			_pickup_evidence(interactable)
		else:
			show_message("What is this!")

func _pickup_flashlight(item):
	has_flashlight = true
	SavePoint.has_flashlight = true  # save to autoload immediately
	show_message("Found a flashlight!")
	print("Flashlight picked up!")
	item.pickup()

func _pickup_battery(item):
	var battery_bar = get_tree().get_first_node_in_group("battery")
	if battery_bar:
		battery_bar.add_battery(20.0)
	battery_count += 1
	SavePoint.battery_count = battery_count  # save to autoload immediately
	print("Battery picked up! Total: ", battery_count)
	show_message("Found a battery!")
	item.pickup()

func _pickup_evidence(item):
	evidence_count += 1
	SavePoint.evidence_count = evidence_count  # save to autoload immediately
	print("Evidence picked up! Total: ", evidence_count)
	_increase_difficulty()
	show_message("Found evidence! (" + str(evidence_count) + ")")
	item.pickup()

func _increase_difficulty():
	var enemy = get_tree().get_first_node_in_group("enemy")
	if enemy:
		enemy.chase_speed += 5
		enemy.detection_radius += 10
		print("Enemy stronger! Speed: ", enemy.chase_speed, " Detection: ", enemy.detection_radius)

func _get_interactable():
	for area in $InteractionArea.get_overlapping_areas():
		if area.is_in_group("battery") or area.is_in_group("evidence") or area.is_in_group("flashlight_item"):
			return area
	for body in $InteractionArea.get_overlapping_bodies():
		if body.is_in_group("soma"):
			return body
	return null

func show_message(text):
	is_dialogue_open = true
	$CanvasLayer/TextBox/NinePatchRect.start_dialogue(text)

func _on_fear_full():
	set_physics_process(false)
	set_process_input(false)
	await get_tree().create_timer(1.5).timeout
	SavePoint.respawn()

func _update_light_intensity():
	if not fear_meter or not $PointLight2D.enabled:
		return
	var fear_percent = fear_meter.value / 100.0
	if fear_percent <= 0.5:
		$PointLight2D.energy = 1.0
		return
	var dim_percent = (fear_percent - 0.5) / 0.5
	$PointLight2D.energy = lerp(1.0, 0.2, dim_percent)

func add_to_nearby_items(_item):
	pass

func remove_from_nearby_items(_item):
	pass
