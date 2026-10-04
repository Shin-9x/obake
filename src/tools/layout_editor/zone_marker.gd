@tool
class_name ZoneMarker
extends LayoutNode
## A circular zone, such as one of Jorogumo's webs. What it does is up to the boss rule.

const COLOUR: Color = Color("#c9d1d955")
const EDGE_COLOUR: Color = Color("#c9d1d9")

## In pixels.
@export var radius: float = 30.0:
	set(value):
		radius = value
		notify_changed()


func to_layout_zone() -> LayoutZone:
	var pose: Vector3i = document_pose()
	return LayoutZone.new(pose.x, pose.y, roundi(radius * PX))


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, COLOUR)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, EDGE_COLOUR, 1.0)
