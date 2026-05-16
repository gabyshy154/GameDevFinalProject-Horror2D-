extends Area2D

@export var item_name: String = "Item"
@export var item_type: String = "evidence"
@export var evidence_audio: String = ""  # audio name to play on pickup

func _ready():
	add_to_group(item_type)
	if item_type == "flashlight":
		add_to_group("flashlight_item")

func pickup():
	queue_free()
	
#For each instance just change in the Inspector:
#
#item_nameitem_typeOld LetterevidencePhotographevidenceBatterybatteryRusty Keykey
#
#So your workflow is:
#
#Drag your item scene into the level
#Click the instance
#In the Inspector change item_name and item_type
#Done — same scene, different behavior
#BOOMBOCLART
