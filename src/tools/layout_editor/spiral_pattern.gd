@tool
class_name SpiralPattern
extends LayoutPattern
## Pegs along a spiral that widens from an inner to an outer radius over a number of turns.

@export var inner_radius: float = 20.0:
	set(value):
		inner_radius = value
		notify_changed()
@export var outer_radius: float = 100.0:
	set(value):
		outer_radius = value
		notify_changed()
@export var turns: float = 1.5:
	set(value):
		turns = value
		notify_changed()
@export var start_degrees: float = 0.0:
	set(value):
		start_degrees = value
		notify_changed()
@export_range(2, 64) var count: int = 20:
	set(value):
		count = value
		notify_changed()


func local_points() -> Array[Vector3i]:
	var points: Array[Vector3i] = []
	var start: int = roundi(start_degrees * 100.0)
	var sweep: int = roundi(turns * Trig.FULL_TURN)
	var inner: int = roundi(inner_radius * PX)
	var outer: int = roundi(outer_radius * PX)
	for index: int in count:
		var angle: int = start + spread(0, sweep, index, count)
		var at: Vector2i = polar(spread(inner, outer, index, count), angle)
		points.append(Vector3i(at.x, at.y, angle + Trig.QUARTER_TURN))
	return points
