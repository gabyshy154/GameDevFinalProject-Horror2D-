extends ProgressBar

@onready var timer = $Timer
@onready var damage_bar = $DamageBar

@export var increase_amount = 5.0
@export var increase_interval = 5.0

var fear = 0.0 : set = _set_fear

func _ready():
	min_value = 0
	max_value = 100
	value = 0
	damage_bar.min_value = 0
	damage_bar.max_value = 100
	damage_bar.value = 0
	timer.wait_time = increase_interval
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _set_fear(new_fear):
	fear = min(max_value, new_fear)
	value = fear

	# damage bar smoothly catches up after a delay
	await get_tree().create_timer(0.4).timeout
	var tween = create_tween()
	tween.tween_property(damage_bar, "value", fear, 0.3)

func add_fear(amount):
	fear += amount

func _on_timer_timeout():
	fear += increase_amount
