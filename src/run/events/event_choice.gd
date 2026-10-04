class_name EventChoice
## One option of a yokai event, as the event screen shows it.

## What the option asks the player to pick before it applies.
enum Pick { NONE, BALL, OMAMORI }

## Text with %d placeholders filled from [member args].
var text_key: String = ""
var args: Array = []
var enabled: bool = true
var pick: Pick = Pick.NONE
## Bag or slot indices the player may pick from.
var options: PackedInt32Array = PackedInt32Array()


func _init(key: String = "", values: Array = [], open: bool = true) -> void:
	text_key = key
	args = values
	enabled = open
