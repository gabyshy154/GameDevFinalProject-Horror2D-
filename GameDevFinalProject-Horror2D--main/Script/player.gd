extends CharacterBody2D

@export var speed = 200

func _physics_process(_delta):
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
		$PointLight2D.enabled  = !$PointLight2D.enabled 
