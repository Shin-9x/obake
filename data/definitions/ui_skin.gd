class_name UiSkin
extends Resource
## Art of the menus and overlays, so placeholder art can be replaced without code changes.

## Obo, the chōchin-obake, who celebrates unlocks.
@export var mascot: Texture2D
## Obo's faces on the board, in [enum MascotMood.Mood] order: idle, happy, worried, sad, excited.
@export var mascot_moods: Array[Texture2D] = []
