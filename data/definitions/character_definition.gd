class_name CharacterDefinition
extends ItemDefinition
## A playable character. Its effect script holds both the power, triggered by green lanterns,
## and the passive; [member ItemDefinition.params] also carries run-level perks such as extra
## shop offers.

@export var portrait: Texture2D
@export var power_key: String = ""
@export var passive_key: String = ""
@export var starting_balls: Array[BallDefinition] = []
