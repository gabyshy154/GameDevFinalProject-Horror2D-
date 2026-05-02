extends ProgressBar

@onready var damage_bar = $DamageBar
@onready var timer = $Timer
@export var ambient_increase = 1.0
@export var ambient_interval = 6.0
var fear = 0.0 : set = _set_fear
var target_fear = 0.0
var fill_speed = 15.0

# ambient drip variables
var ambient_drip_active = false
var ambient_drip_total = 0.0
var ambient_drip_remaining = 0.0
var ambient_drip_speed = 2.0  # how fast the ambient fear drips in per second

func _ready():
	min_value = 0
	max_value = 100
	value = 0
	damage_bar.min_value = 0
	damage_bar.max_value = 100
	damage_bar.value = 0
	timer.wait_time = ambient_interval
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _process(delta):
	# smooth visual fill toward target
	if value < target_fear:
		value = move_toward(value, target_fear, fill_speed * delta)

	# drip ambient fear in slowly over time instead of instant jump
	if ambient_drip_remaining > 0:
		var drip = ambient_drip_speed * delta
		drip = min(drip, ambient_drip_remaining)
		ambient_drip_remaining -= drip
		fear = min(max_value, fear + drip)
		target_fear = fear
		# update damage bar
		var tween = create_tween()
		tween.tween_property(damage_bar, "value", fear, 0.3)

func _set_fear(new_fear):
	fear = min(max_value, new_fear)
	target_fear = fear
	await get_tree().create_timer(0.4).timeout
	var tween = create_tween()
	tween.tween_property(damage_bar, "value", fear, 0.3)

func add_fear(amount):
	fear += amount

func _on_timer_timeout():
	# instead of instantly adding, drip it in slowly
	ambient_drip_remaining += ambient_increase
