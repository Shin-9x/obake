@tool
class_name MovingGroup
## Pegs that move together on the board clock: a ring turning around a pivot, such as a water
## wheel, or a set sliding back and forth along a fixed vector, such as bamboo stalks.
##
## Positions depend only on the clock, so every board motion is replayed from the shot input.

enum Motion { ROTATE, OSCILLATE }

var motion: Motion = Motion.ROTATE
## Centre of rotation, in milli-pixels.
var pivot_x: int = 0
var pivot_y: int = 0
## Largest offset from the base positions while oscillating, in milli-pixels.
var travel_x: int = 0
var travel_y: int = 0
## Ticks for one full turn or one full back-and-forth.
var period: int = 1
var clockwise: bool = true
## Added to the board clock so that groups need not move in step.
var phase_offset: int = 0
## Indices of the member pegs.
var pegs: PackedInt32Array = PackedInt32Array()

## Bounds of every position the member pegs can take, in milli-pixels.
var min_x: int = 0
var min_y: int = 0
var max_x: int = 0
var max_y: int = 0


## Angle of the group at [param clock], in centidegrees: the turn of a ring, or the phase of
## the oscillation.
func angle_at(clock: int) -> int:
	var angle: int = posmod(clock + phase_offset, period) * Trig.FULL_TURN / period
	if motion == Motion.ROTATE and not clockwise:
		return -angle
	return angle


## Grows the bounds to cover [param peg] wherever the motion takes it.
func cover(peg: SimPeg) -> void:
	var extent: int = peg.extent
	var left: int = 0
	var top: int = 0
	var right: int = 0
	var bottom: int = 0
	if motion == Motion.ROTATE:
		var distance: int = FixedMath.length(peg.base_x - pivot_x, peg.base_y - pivot_y) + 1
		left = pivot_x - distance - extent
		top = pivot_y - distance - extent
		right = pivot_x + distance + extent
		bottom = pivot_y + distance + extent
	else:
		left = peg.base_x - absi(travel_x) - extent
		top = peg.base_y - absi(travel_y) - extent
		right = peg.base_x + absi(travel_x) + extent
		bottom = peg.base_y + absi(travel_y) + extent
	if pegs.size() == 1:
		min_x = left
		min_y = top
		max_x = right
		max_y = bottom
		return
	min_x = mini(min_x, left)
	min_y = mini(min_y, top)
	max_x = maxi(max_x, right)
	max_y = maxi(max_y, bottom)


func overlaps(left: int, top: int, right: int, bottom: int) -> bool:
	return left <= max_x and right >= min_x and top <= max_y and bottom >= min_y
