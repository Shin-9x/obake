@tool
class_name LayoutZone
## A circular zone of a board layout, such as a web. Distances in milli-pixels.

var x: int = 0
var y: int = 0
var radius: int = 0


func _init(at_x: int = 0, at_y: int = 0, zone_radius: int = 0) -> void:
	x = at_x
	y = at_y
	radius = zone_radius
