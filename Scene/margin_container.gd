extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var time =  $LetterDisplayTimer

const MAX_WIDTH = 256

var text = ""
var letter
