@tool
class_name Contact
## Reusable result of a collision test.

## Unit normal pushing the ball out of the obstacle, scaled by [constant FixedMath.UNIT].
var nx: int = 0
var ny: int = 0
## Penetration depth in milli-pixels.
var depth: int = 0


func set_normal(normal_x: int, normal_y: int, penetration: int) -> void:
	nx = normal_x
	ny = normal_y
	depth = penetration
