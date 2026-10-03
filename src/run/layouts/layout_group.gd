@tool
class_name LayoutGroup
## Pegs of a layout that move together; see [MovingGroup] for the motions.

var motion: MovingGroup.Motion = MovingGroup.Motion.ROTATE
## Centre of rotation, in milli-pixels.
var pivot_x: int = 0
var pivot_y: int = 0
## Largest offset while oscillating, in milli-pixels.
var travel_x: int = 0
var travel_y: int = 0
## Ticks for one full turn or one full back-and-forth.
var period: int = 0
var clockwise: bool = true
## Member pegs, at their positions when the group's phase is zero.
var pegs: Array[LayoutPeg] = []
