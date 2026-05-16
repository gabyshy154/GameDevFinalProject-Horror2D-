extends ProgressBar

func _ready():
	max_value = 100
	value = 100

func update_stamina(stamina_value: float):
	value = stamina_value
