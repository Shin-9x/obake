class_name SimWall
## A one-sided wall segment from a to b, in milli-pixels.
##
## The playable side is on the right when walking from a to b as seen on screen (y down).
## Being one-sided, the wall still pushes a ball back when a fast step carries its centre past
## the line.

var ax: int = 0
var ay: int = 0
var bx: int = 0
var by: int = 0
## Unit normal pointing to the playable side, scaled by [constant FixedMath.UNIT].
var nx: int = 0
var ny: int = 0
var length_squared: int = 0


func _init(from_x: int, from_y: int, to_x: int, to_y: int) -> void:
	ax = from_x
	ay = from_y
	bx = to_x
	by = to_y
	var dx: int = to_x - from_x
	var dy: int = to_y - from_y
	length_squared = dx * dx + dy * dy
	var length: int = FixedMath.isqrt(length_squared)
	nx = FixedMath.div_round(-dy * FixedMath.UNIT, length)
	ny = FixedMath.div_round(dx * FixedMath.UNIT, length)
