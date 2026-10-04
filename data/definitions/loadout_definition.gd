class_name LoadoutDefinition
extends Resource
## What the player brings to a board: the character, the bag, the omamori in slot order and the
## purchased pegs. The run keeps one as its inventory; a hand-made one drives board playtests.

## Null plays without a power or a passive.
@export var character: CharacterDefinition
@export var balls: Array[BallDefinition] = []
## Level of each ball, by index; missing entries are level 1.
@export var ball_levels: PackedInt32Array = PackedInt32Array()
@export var omamori: Array[OmamoriDefinition] = []
@export var purchased_pegs: Array[PegDefinition] = []


func level_of(index: int) -> int:
	return ball_levels[index] if index < ball_levels.size() else 1
