class_name BallTrails
extends Node2D
## A short fading trail behind every ball in flight, from the positions it was drawn at in the
## last few frames. Buffers grow only when a new ball appears.

const LENGTH: int = 6
const RADIUS: float = 2.5
const COLOUR: Color = Color("#bfe9ff")

var _points: PackedVector2Array = PackedVector2Array()
var _counts: PackedInt32Array = PackedInt32Array()


## Records where ball [param index] is drawn this frame; [param flying] false clears its trail.
func track(index: int, at: Vector2, flying: bool) -> void:
	if _counts.size() <= index:
		_counts.resize(index + 1)
		_points.resize((index + 1) * LENGTH)
	if not flying:
		_counts[index] = 0
		return
	var base: int = index * LENGTH
	for slot: int in range(LENGTH - 1, 0, -1):
		_points[base + slot] = _points[base + slot - 1]
	_points[base] = at
	_counts[index] = mini(_counts[index] + 1, LENGTH)


func clear() -> void:
	_counts.fill(0)
	queue_redraw()


func _draw() -> void:
	for index: int in _counts.size():
		var base: int = index * LENGTH
		for slot: int in range(1, _counts[index]):
			var fade: float = 1.0 - float(slot) / LENGTH
			var colour: Color = COLOUR
			colour.a = 0.5 * fade
			draw_circle(_points[base + slot], RADIUS * fade, colour)
