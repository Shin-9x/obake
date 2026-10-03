@tool
class_name PegMarker
extends LayoutNode
## One hand-placed peg. A rectangle uses the node's rotation as its angle.

enum Shape { ROUND, RECT }

const COLOUR: Color = Color("#7fb2e6")

@export var shape: Shape = Shape.ROUND:
	set(value):
		shape = value
		notify_changed()
## Full size of a rectangle, in pixels.
@export var size: Vector2 = Vector2(24, 6):
	set(value):
		size = value
		notify_changed()


func to_layout_peg() -> LayoutPeg:
	var pose: Vector3i = document_pose()
	if shape == Shape.ROUND:
		return LayoutPeg.round_at(pose.x, pose.y)
	return LayoutPeg.rect_at(
		pose.x, pose.y, roundi(size.x * PX / 2.0), roundi(size.y * PX / 2.0), pose.z
	)


func _draw() -> void:
	draw_peg(Vector2.ZERO, shape, size, 0.0, COLOUR)
