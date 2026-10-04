@tool
class_name SimZone
## A circular area of the board, such as one of Jorogumo's webs. Distances in milli-pixels.

var x: int = 0
var y: int = 0
var radius: int = 0
## Share of its speed a ball loses every tick while its centre is inside, in permille; 0 leaves
## balls alone.
var drag: int = 0


func _init(at_x: int = 0, at_y: int = 0, zone_radius: int = 0) -> void:
	x = at_x
	y = at_y
	radius = zone_radius


func contains(point_x: int, point_y: int) -> bool:
	var dx: int = point_x - x
	var dy: int = point_y - y
	return dx * dx + dy * dy <= radius * radius
