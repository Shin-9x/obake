class_name PegDefinition
extends Resource
## A kind of peg: what it scores the first time it is hit in a shot, and how it looks.
##
## Scoring is applied in field order: points, then mult added, then mult factor. Mult values are
## in permille: [member mult_add] 1000 adds +1 mult, [member mult_factor] 2000 doubles the mult.

@export var id: StringName = &""
@export var name_key: String = ""
@export var points: int = 0
@export var mult_add: int = 0
@export var mult_factor: int = 1000

@export_group("Presentation")
## Fill colour for shapes that have no texture, such as rotated bars.
@export var color: Color = Color.WHITE
@export var texture: Texture2D
