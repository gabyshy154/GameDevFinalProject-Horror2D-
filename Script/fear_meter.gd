extends ProgressBar

@onready var timer = $Timer
@export var ambient_increase = 0.5
@export var ambient_interval = 5.0
var fear = 0.0 : set = _set_fear
var target_fear = 0.0
var fill_speed = 15.0
var is_being_chased = false
var paused = false  # controlled by safe zone

func _ready():
	min_value = 0
	max_value = 100
	value = 0
	timer.wait_time = ambient_interval
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _process(delta):
	if value != target_fear:
		value = move_toward(value, target_fear, fill_speed * delta)

func _set_fear(new_fear):
	fear = min(max_value, new_fear)
	target_fear = fear

func add_fear(amount):
	# dont add fear when paused inside safe zone
	if paused:
		return
	fear = min(max_value, fear + amount)
	target_fear = fear

func set_chasing(chasing: bool):
	is_being_chased = chasing

func _on_timer_timeout():
	# dont tick ambient fear when paused
	if paused:
		return
	add_fear(ambient_increase)
