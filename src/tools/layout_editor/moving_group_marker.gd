@tool
class_name MovingGroupMarker
extends LayoutNode
## Pegs placed under this node move together on the board clock. Rotation turns them around
## this node's position; oscillation slides them back and forth by [member travel].

const COLOUR: Color = Color("#e3b341")

@export var motion: MovingGroup.Motion = MovingGroup.Motion.ROTATE:
	set(value):
		motion = value
		notify_changed()
## Seconds for one full turn or one full back-and-forth.
@export var period_seconds: float = 6.0:
	set(value):
		period_seconds = value
		notify_changed()
@export var clockwise: bool = true:
	set(value):
		clockwise = value
		notify_changed()
## Largest offset while oscillating, in pixels.
@export var travel: Vector2 = Vector2(40, 0):
	set(value):
		travel = value
		notify_changed()


func build_group() -> LayoutGroup:
	var pose: Vector3i = document_pose()
	var group: LayoutGroup = LayoutGroup.new()
	group.motion = motion
	group.period = maxi(1, roundi(period_seconds * BoardSimulation.TICKS_PER_SECOND))
	group.clockwise = clockwise
	if motion == MovingGroup.Motion.ROTATE:
		group.pivot_x = pose.x
		group.pivot_y = pose.y
	else:
		var turned: Vector3i = compose(
			Vector3i(0, 0, pose.z), Vector3i(roundi(travel.x * PX), roundi(travel.y * PX), 0)
		)
		group.travel_x = turned.x
		group.travel_y = turned.y
	for child: Node in get_children():
		LayoutDocument.collect_pegs(child, group.pegs)
	return group


func _draw() -> void:
	draw_line(Vector2(-4, 0), Vector2(4, 0), COLOUR)
	draw_line(Vector2(0, -4), Vector2(0, 4), COLOUR)
	if motion == MovingGroup.Motion.OSCILLATE:
		draw_line(-travel, travel, COLOUR, 1.0)
	else:
		draw_arc(Vector2.ZERO, 8.0, 0.0, PI * 1.5, 12, COLOUR, 1.0)
