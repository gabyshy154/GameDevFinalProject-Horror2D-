extends ProgressBar

@export var drain_amount = 1
@export var drain_interval = 2.5
@export var flicker_threshold = 20.0

@onready var timer = $Timer

var battery = 100.0 : set = _set_battery
var is_on = false
var light_node = null

func _ready():
	min_value = 0
	max_value = 100
	value = 100
	timer.wait_time = drain_interval
	timer.stop()
	timer.timeout.connect(_on_timer_timeout)
	await get_tree().process_frame
	light_node = get_tree().get_first_node_in_group("flashlight")

func _set_battery(new_val):
	battery = clamp(new_val, 0, max_value)
	value = battery
	if battery <= 0:
		turn_off()

func turn_on():
	if battery > 0:
		is_on = true
		timer.start()

func turn_off():
	is_on = false
	timer.stop()
	if light_node:
		light_node.enabled = false  # force light off

func _on_timer_timeout():
	battery -= drain_amount

	if battery <= flicker_threshold and is_on:
		# only flicker 20% of the time
		if randf() < 0.2:
			_flicker()

func _flicker():
	if not light_node:
		return
	# rapidly toggle light for flicker effect
	light_node.enabled = false
	await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
	if is_on and battery > 0:
		light_node.enabled = true
	await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
	if is_on and battery > 0:
		light_node.enabled = false
	await get_tree().create_timer(randf_range(0.05, 0.1)).timeout
	if is_on and battery > 0:
		light_node.enabled = true
