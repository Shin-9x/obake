@tool
class_name ArcPattern
extends LayoutPattern
## Pegs evenly spaced along an arc around the node. Angles follow the screen: 0 points right,
## 90 points down. Rectangles lie along the arc.

@export var radius: float = 80.0:
	set(value):
		radius = value
		notify_changed()
@export var from_degrees: float = 200.0:
	set(value):
		from_degrees = value
		notify_changed()
@export var to_degrees: float = 340.0:
	set(value):
		to_degrees = value
		notify_changed()
@export_range(1, 64) var count: int = 7:
	set(value):
		count = value
		notify_changed()


func local_points() -> Array[Vector3i]:
	var points: Array[Vector3i] = []
	var from: int = roundi(from_degrees * 100.0)
	var to: int = roundi(to_degrees * 100.0)
	for index: int in count:
		var angle: int = spread(from, to, index, count)
		var at: Vector2i = polar(roundi(radius * PX), angle)
		points.append(Vector3i(at.x, at.y, angle + Trig.QUARTER_TURN))
	return points
