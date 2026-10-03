@tool
class_name GridPattern
extends LayoutPattern
## A grid centred on the node. Staggered grids shift every other row by half a column and drop
## its last peg, so the pattern stays symmetric.

@export_range(1, 32) var columns: int = 8:
	set(value):
		columns = value
		notify_changed()
@export_range(1, 32) var rows: int = 4:
	set(value):
		rows = value
		notify_changed()
@export var spacing: Vector2 = Vector2(40, 30):
	set(value):
		spacing = value
		notify_changed()
@export var staggered: bool = true:
	set(value):
		staggered = value
		notify_changed()


func local_points() -> Array[Vector3i]:
	var points: Array[Vector3i] = []
	var step_x: int = roundi(spacing.x * PX)
	var step_y: int = roundi(spacing.y * PX)
	for row: int in rows:
		var shifted: bool = staggered and row % 2 == 1
		var in_row: int = columns - 1 if shifted else columns
		for column: int in in_row:
			# Twice the offset from the centre, so half steps stay exact.
			var doubled: int = 2 * column - (in_row - 1)
			var x: int = doubled * step_x / 2
			var y: int = (2 * row - (rows - 1)) * step_y / 2
			points.append(Vector3i(x, y, 0))
	return points
