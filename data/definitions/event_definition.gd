class_name EventDefinition
extends Resource
## A yokai event met on the map: its texts, art and the run-logic script that gives it choices.

@export var id: StringName = &""
@export var title_key: String = ""
@export var text_key: String = ""
@export var art: Texture2D
## Script extending RunEvent.
@export var event_script: Script
## Named numbers the event uses, such as a price.
@export var params: Dictionary[StringName, int] = {}
