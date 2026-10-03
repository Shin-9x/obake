class_name PegDefinition
extends ItemDefinition
## A kind of peg: what it scores the first time it is hit in a shot, how it bounces and how it
## looks. Base lanterns and purchasable pegs share it.
##
## Scoring is applied in field order: points, then mult added, then mult factor. Mult values are
## in permille: [member mult_add] 1000 adds +1 mult, [member mult_factor] 2000 doubles the mult.

@export var points: int = 0
@export var mult_add: int = 0
@export var mult_factor: int = 1000
@export var mon: int = 0
## Bounce in permille; 0 keeps the board's default.
@export var restitution: int = 0
## Never removed from the board: it goes dark at the end of each shot instead.
@export var persistent: bool = false

@export_group("Presentation")
## Fill colour for shapes that have no texture, such as rotated bars.
@export var color: Color = Color.WHITE
@export var texture: Texture2D
