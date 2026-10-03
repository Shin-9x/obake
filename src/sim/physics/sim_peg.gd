@tool
class_name SimPeg
## A peg on the board: a circle or a rotated rectangle. Distances in milli-pixels.
##
## Static pegs never move. Pegs of a [MovingGroup] are moved every tick from their base pose,
## which is where they sit when the group's phase is zero.

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
## Bounce in permille, overriding the ball and the board; -1 keeps them.
var restitution: int = -1
## Goes dark at the end of a shot instead of being removed.
var persistent: bool = false
## Pulls balls that have an attraction.
var attractor: bool = false

## Index of the moving group this peg belongs to, or -1 for a static peg.
var group: int = -1
var base_x: int = 0
var base_y: int = 0
var base_angle: int = 0
var base_cos: int = FixedMath.UNIT
var base_sin: int = 0
## Velocity of a moving peg over the last tick, in milli-pixels per second.
var vx: int = 0
var vy: int = 0

## Largest distance from the centre to any point of the peg.
var extent: int = 0

## Bounds of a static peg, used by the broad phase.
var min_x: int = 0
var min_y: int = 0
var max_x: int = 0
var max_y: int = 0


static func create_round(center_x: int, center_y: int, peg_radius: int) -> SimPeg:
	var peg: SimPeg = SimPeg.new()
	peg.shape = Shape.ROUND
	peg.radius = peg_radius
	peg.extent = peg_radius
	peg._set_base(center_x, center_y, 0)
	peg._set_bounds(peg_radius, peg_radius)
	return peg


## Rectangle centred on ([param center_x], [param center_y]) and rotated clockwise on screen by
## [param angle] centidegrees.
static func create_rect(
	center_x: int, center_y: int, half_w: int, half_h: int, angle: int
) -> SimPeg:
	var peg: SimPeg = SimPeg.new()
	peg.shape = Shape.RECT
	peg.half_width = half_w
	peg.half_height = half_h
	peg.extent = FixedMath.isqrt(half_w * half_w + half_h * half_h) + 1
	peg._set_base(center_x, center_y, angle)
	var abs_cos: int = absi(peg.cos_angle)
	var abs_sin: int = absi(peg.sin_angle)
	var unit: int = FixedMath.UNIT
	# Rounded up so the bounds always contain the rotated rectangle.
	var extent_x: int = (abs_cos * half_w + abs_sin * half_h + unit - 1) / unit
	var extent_y: int = (abs_sin * half_w + abs_cos * half_h + unit - 1) / unit
	peg._set_bounds(extent_x, extent_y)
	return peg


func _set_base(center_x: int, center_y: int, angle: int) -> void:
	x = center_x
	y = center_y
	base_x = center_x
	base_y = center_y
	angle_cd = angle
	base_angle = angle
	cos_angle = Trig.cos_cd(angle)
	sin_angle = Trig.sin_cd(angle)
	base_cos = cos_angle
	base_sin = sin_angle


func _set_bounds(extent_x: int, extent_y: int) -> void:
	min_x = x - extent_x
	min_y = y - extent_y
	max_x = x + extent_x
	max_y = y + extent_y
