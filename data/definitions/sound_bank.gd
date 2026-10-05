class_name SoundBank
extends Resource
## The game's sound effects by cue name and its music, so placeholder audio can be replaced
## without code changes.

@export var cues: Dictionary[StringName, AudioStream] = {}
## Loop for the title, menus and the map.
@export var menu_music: AudioStream
## Loop for boards.
@export var board_music: AudioStream
