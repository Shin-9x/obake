@tool
class_name ShotInput
## The player's input for one shot. A run replay is the ordered list of its shot inputs.

## Aim in centidegrees from straight down; positive values aim to the right.
var aim: int = 0
## Board clock at the moment of the shot. The bucket and the moving groups keep going while the
## player aims, so where they are is part of the input.
var board_clock: int = 0


func _init(aim_cd: int = 0, clock: int = 0) -> void:
	aim = aim_cd
	board_clock = clock
