#extends ProgressBar
#
#@export var drain_amount = 1
#@export var drain_interval = 2.5
#@export var flicker_threshold = 20.0
#
#@onready var timer = $Timer
#
#var battery = 100.0 : set = _set_battery
#var is_on = false
#var light_node = null
#
#func _ready():
	#min_value = 0
	#max_value = 100
	#value = 100
	#timer.wait_time = drain_interval
	#timer.stop()
	#timer.timeout.connect(_on_timer_timeout)
	#await get_tree().process_frame
	#light_node = get_tree().get_first_node_in_group("flashlight")
#
#func _set_battery(new_val):
	#battery = clamp(new_val, 0, max_value)
	#value = battery
	#if battery <= 0:
		#turn_off()
#
#func turn_on():
	#if battery > 0:
		#is_on = true
		#timer.start()
#
#func turn_off():
	#is_on = false
	#timer.stop()
	#if light_node:
		#light_node.enabled = false
#
#func add_battery(percent: float):
	#var restore_amount = max_value * (percent / 100.0)
	#battery = min(max_value, battery + restore_amount)
	#print("Battery restored by ", percent, "% | Current battery: ", battery)
#
#func _on_timer_timeout():
	#battery -= drain_amount
	#if battery <= flicker_threshold and is_on:
		#if randf() < 0.2:
			#_flicker()
#
#func _flicker():
	#if not light_node:
		#return
	#light_node.enabled = false
	#await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
	#if is_on and battery > 0:
		#light_node.enabled = true
	#await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
	#if is_on and battery > 0:
		#light_node.enabled = false
	#await get_tree().create_timer(randf_range(0.05, 0.1)).timeout
	#if is_on and battery > 0:
		#light_node.enabled = true
extends ProgressBar

@export var drain_amount := 1.0
@export var drain_interval := 2.5
@export var flicker_threshold := 20.0

@onready var timer := $Timer

# Audio
@onready var sfx_toggle := $Audio_OnOff
@onready var sfx_low := $Audio_LowBattery
@onready var sfx_die := $Audio_Die

var battery := 100.0 : set = _set_battery
var is_on := false
var light_node = null

var low_battery_played := false


func _ready():
	min_value = 0
	max_value = 100
	value = battery

	timer.wait_time = drain_interval
	timer.stop()
	timer.timeout.connect(_on_timer_timeout)

	await get_tree().process_frame
	light_node = get_tree().get_first_node_in_group("flashlight")


# ---------------------------
# BATTERY SETTER
# ---------------------------
func _set_battery(new_val):
	battery = clamp(new_val, 0, max_value)
	value = battery

	if battery <= 0:
		if sfx_die and not sfx_die.playing:
			sfx_die.play()
		turn_off()


# ---------------------------
# FLASHLIGHT CONTROL
# ---------------------------
func turn_on():
	if battery > 0:
		is_on = true
		timer.start()

		if sfx_toggle:
			play_sfx(sfx_toggle)


func turn_off():
	is_on = false
	timer.stop()

	if light_node:
		light_node.enabled = false

	if sfx_toggle:
		play_sfx(sfx_toggle)


# ---------------------------
# BATTERY RECHARGE
# ---------------------------
func add_battery(percent: float):
	var restore_amount = max_value * (percent / 100.0)
	battery = min(max_value, battery + restore_amount)

	print("Battery restored by ", percent, "% | Current battery: ", battery)

	if battery > flicker_threshold:
		low_battery_played = false


# ---------------------------
# TIMER DRAIN LOGIC
# ---------------------------
func _on_timer_timeout():
	if not is_on:
		return

	battery -= drain_amount

	# Low battery warning sound
	if battery <= flicker_threshold and battery > 0:
		if not low_battery_played:
			if sfx_low:
				play_sfx(sfx_low)
			low_battery_played = true

		# Flicker chance
		if randf() < 0.2:
			_flicker()


# ---------------------------
# FLICKER EFFECT
# ---------------------------
func _flicker():
	if not light_node:
		return

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


# ---------------------------
# SAFE SFX HELPER
# ---------------------------
func play_sfx(audio):
	audio.pitch_scale = randf_range(0.95, 1.05)
	audio.play()
