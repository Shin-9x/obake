class_name EventOutcome
## What a chosen option did, for the event screen to tell.

var text_key: String = ""
## Item the player received, if any.
var item: ItemDefinition


func _init(key: String = "", received: ItemDefinition = null) -> void:
	text_key = key
	item = received
