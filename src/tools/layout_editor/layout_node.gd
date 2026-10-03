@tool
class_name LayoutNode
extends Node2D
## Base for layout editor nodes. Reads the editor transform as exact integers, so the same
## source scene always exports the same layout.
##
## A pose is a Vector3i: x and y in milli-pixels, z the angle in centidegrees. Scale is ignored.

const PX: float = 1000.0
const BALANCE: BalanceConfig = preload("res://data/balance.tres")


## This node's pose relative to the [LayoutDocument] it belongs to.
func document_pose() -> Vector3i:
	var pose: Vector3i = local_pose()
	var parent: Node = get_parent()
	while parent is LayoutNode:
		pose = compose((parent as LayoutNode).local_pose(), pose)
		parent = parent.get_parent()
	return pose


func local_pose() -> Vector3i:
	return Vector3i(
		roundi(position.x * PX), roundi(position.y * PX), roundi(rotation_degrees * 100.0)
	)


## [param inner] expressed in the frame that [param outer] is expressed in.
static func compose(outer: Vector3i, inner: Vector3i) -> Vector3i:
	var cosine: int = Trig.cos_cd(outer.z)
	var sine: int = Trig.sin_cd(outer.z)
	return Vector3i(
		outer.x + FixedMath.div_round(inner.x * cosine - inner.y * sine, FixedMath.UNIT),
		outer.y + FixedMath.div_round(inner.x * sine + inner.y * cosine, FixedMath.UNIT),
		outer.z + inner.z
	)


## Asks the owning document to refresh its warnings after an edit.
func notify_changed() -> void:
	queue_redraw()
	var node: Node = self
	while node != null:
		if node is LayoutDocument:
			(node as LayoutDocument).mark_dirty()
			return
		node = node.get_parent()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		notify_changed()


func _enter_tree() -> void:
	set_notify_transform(Engine.is_editor_hint())


## Draws one peg in the node's local space, as the game would show its outline.
func draw_peg(
	at: Vector2, shape: PegMarker.Shape, size: Vector2, angle: float, colour: Color
) -> void:
	if shape == PegMarker.Shape.ROUND:
		draw_circle(at, BALANCE.peg_radius / PX, colour)
		return
	draw_set_transform(at, angle)
	draw_rect(Rect2(-size / 2.0, size), colour)
	draw_set_transform(Vector2.ZERO)
