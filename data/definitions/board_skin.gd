class_name BoardSkin
extends Resource
## Art and colours used to draw a board, so placeholder art can be replaced without code changes.

@export var ball_texture: Texture2D
@export var bucket_texture: Texture2D
@export var launcher_texture: Texture2D
@export var background_color: Color = Color("#1b1d2b")
@export var board_color: Color = Color("#2a3147")
@export var panel_color: Color = Color("#22263a")
@export var guide_color: Color = Color("#f4e9c9b0")
## Ring drawn around lit pegs.
@export var lit_color: Color = Color("#fff6d8")
## Zones such as webs: a translucent fill and the strands drawn over it.
@export var zone_color: Color = Color("#c9d1d922")
@export var zone_line_color: Color = Color("#c9d1d980")
