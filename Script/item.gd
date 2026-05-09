extends Area2D

@export var item_name: String = "Item"
@export var item_type: String = "evidence"  # evidence or battery

func _ready():
	# automatically join the correct group based on item_type
	add_to_group(item_type)  

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
