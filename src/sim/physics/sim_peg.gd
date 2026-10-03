class_name SimPeg
## A peg on the board: a circle or a rotated rectangle. Distances in milli-pixels.

enum Shape { ROUND, RECT }

var shape: Shape = Shape.ROUND
var x: int = 0
var y: int = 0
var radius: int = 0
var half_width: int = 0
var half_height: int = 0
var angle_cd: int = 0
var cos_angle: int = FixedMath.UNIT
var sin_angle: int = 0
## Hit during the current shot.
var lit: bool = false
## Cleared from the board at the end of a shot.
var removed: bool = false

var min_x: int = 0
var min_y: int = 0
var max_x: int = 0
var max_y: int = 0


static func create_round(center_x: int, center_y: int, peg_radius: int) -> SimPeg:
	var peg: SimPeg = SimPeg.new()
	peg.shape = Shape.ROUND
	peg.x = center_x
	peg.y = center_y
	peg.radius = peg_radius
	peg._set_bounds(peg_radius, peg_radius)
	return peg


## Rectangle centred on ([param center_x], [param center_y]) and rotated clockwise on screen by
## [param angle] centidegrees.
static func create_rect(
	center_x: int, center_y: int, half_w: int, half_h: int, angle: int
) -> SimPeg:
	var peg: SimPeg = SimPeg.new()
	peg.shape = Shape.RECT
	peg.x = center_x
	peg.y = center_y
	peg.half_width = half_w
	peg.half_height = half_h
	peg.angle_cd = angle
	peg.cos_angle = Trig.cos_cd(angle)
	peg.sin_angle = Trig.sin_cd(angle)
	var abs_cos: int = absi(peg.cos_angle)
	var abs_sin: int = absi(peg.sin_angle)
	var unit: int = FixedMath.UNIT
	# Rounded up so the bounds always contain the rotated rectangle.
	var extent_x: int = (abs_cos * half_w + abs_sin * half_h + unit - 1) / unit
	var extent_y: int = (abs_sin * half_w + abs_cos * half_h + unit - 1) / unit
	peg._set_bounds(extent_x, extent_y)
	return peg


func _set_bounds(extent_x: int, extent_y: int) -> void:
	min_x = x - extent_x
	min_y = y - extent_y
	max_x = x + extent_x
	max_y = y + extent_y
