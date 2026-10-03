@tool
class_name LayoutPeg
## One peg of a board layout. Distances in milli-pixels, angle in centidegrees.

var shape: SimPeg.Shape = SimPeg.Shape.ROUND
var x: int = 0
var y: int = 0
## Rectangles only.
var half_width: int = 0
var half_height: int = 0
var angle: int = 0


static func round_at(at_x: int, at_y: int) -> LayoutPeg:
	var peg: LayoutPeg = LayoutPeg.new()
	peg.x = at_x
	peg.y = at_y
	return peg


static func rect_at(at_x: int, at_y: int, half_w: int, half_h: int, angle_cd: int) -> LayoutPeg:
	var peg: LayoutPeg = round_at(at_x, at_y)
	peg.shape = SimPeg.Shape.RECT
	peg.half_width = half_w
	peg.half_height = half_h
	peg.angle = angle_cd
	return peg
