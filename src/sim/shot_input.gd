class_name ShotInput
## The player's input for one shot. A run replay is the ordered list of its shot inputs.

## Aim in centidegrees from straight down; positive values aim to the right.
var aim: int = 0


func _init(aim_cd: int = 0) -> void:
	aim = aim_cd
