@tool
class_name LayoutPattern
extends LayoutNode
## Base for pattern generators: a few parameters describe many pegs. The node's position and
## rotation move and turn the whole pattern. Bake replaces the pattern with editable markers.

const COLOUR: Color = Color("#9fd18b")

@export var shape: PegMarker.Shape = PegMarker.Shape.ROUND:
	set(value):
		shape = value
		notify_changed()
## Full size of each rectangle, in pixels.
@export var rect_size: Vector2 = Vector2(24, 6):
	set(value):
		rect_size = value
		notify_changed()
@export_tool_button("Bake into pegs", "Unlinked") var bake_button: Callable = bake


## The pattern's pegs relative to this node: x, y in milli-pixels and z the angle in
## centidegrees. Subclasses compute them with integer maths only.
func local_points() -> Array[Vector3i]:
	return []


func generate_pegs() -> Array[LayoutPeg]:
	var pose: Vector3i = document_pose()
	var pegs: Array[LayoutPeg] = []
	var half_width: int = roundi(rect_size.x * PX / 2.0)
	var half_height: int = roundi(rect_size.y * PX / 2.0)
	for point: Vector3i in local_points():
		var placed: Vector3i = compose(pose, point)
		if shape == PegMarker.Shape.ROUND:
			pegs.append(LayoutPeg.round_at(placed.x, placed.y))
		else:
			pegs.append(LayoutPeg.rect_at(placed.x, placed.y, half_width, half_height, placed.z))
	return pegs


## Replaces this pattern with one [PegMarker] per generated peg, for hand tuning.
func bake() -> void:
	var parent: Node = get_parent()
	var scene_root: Node = owner if owner != null else self
	var index: int = get_index()
	for point: Vector3i in local_points():
		var marker: PegMarker = PegMarker.new()
		marker.name = "%sPeg%d" % [name, index]
		marker.shape = shape
		marker.size = rect_size
		marker.transform = (
			transform * Transform2D(deg_to_rad(point.z / 100.0), Vector2(point.x, point.y) / PX)
		)
		parent.add_child(marker)
		marker.owner = scene_root
		index += 1
	queue_free()


func _draw() -> void:
	for point: Vector3i in local_points():
		var at: Vector2 = Vector2(point.x, point.y) / PX
		draw_peg(at, shape, rect_size, deg_to_rad(point.z / 100.0), COLOUR)


## Integer interpolation between [param from] and [param to] for step [param index] of
## [param count], endpoints included.
static func spread(from: int, to: int, index: int, count: int) -> int:
	if count <= 1:
		return from
	return from + (to - from) * index / (count - 1)


## Point at [param distance] milli-pixels along [param angle] centidegrees from the origin.
static func polar(distance: int, angle: int) -> Vector2i:
	return Vector2i(
		FixedMath.div_round(distance * Trig.cos_cd(angle), FixedMath.UNIT),
		FixedMath.div_round(distance * Trig.sin_cd(angle), FixedMath.UNIT)
	)
