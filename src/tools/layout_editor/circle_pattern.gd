@tool
class_name CirclePattern
extends LayoutPattern
## Pegs evenly spaced around a full circle centred on the node.

@export var radius: float = 40.0:
	set(value):
		radius = value
		notify_changed()
@export var start_degrees: float = 0.0:
	set(value):
		start_degrees = value
		notify_changed()
@export_range(1, 64) var count: int = 8:
	set(value):
		count = value
		notify_changed()


func local_points() -> Array[Vector3i]:
	var points: Array[Vector3i] = []
	var start: int = roundi(start_degrees * 100.0)
	for index: int in count:
		var angle: int = start + Trig.FULL_TURN * index / count
		var at: Vector2i = polar(roundi(radius * PX), angle)
		points.append(Vector3i(at.x, at.y, angle + Trig.QUARTER_TURN))
	return points
