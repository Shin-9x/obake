class_name UiSkin
extends Resource
## Art of the menus and overlays, so placeholder art can be replaced without code changes.

## Obo, the chōchin-obake, who celebrates unlocks.
@export var mascot: Texture2D
## Obo's faces on the board, in [enum MascotMood.Mood] order: idle, happy, worried, sad, excited.
@export var mascot_moods: Array[Texture2D] = []
## Icon of the pause button.
@export var pause_icon: Texture2D
## Tile laid over the background of every screen and around the board.
@export var background_pattern: Texture2D
