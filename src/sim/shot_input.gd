class_name ShotInput
## The player's input for one shot. A run replay is the ordered list of its shot inputs.

## Aim in centidegrees from straight down; positive values aim to the right.
var aim: int = 0
## Bucket phase, in ticks, at the moment of the shot: the bucket keeps moving while the player
## aims, so it is part of the input.
var bucket_phase: int = 0


func _init(aim_cd: int = 0, phase: int = 0) -> void:
	aim = aim_cd
	bucket_phase = phase
