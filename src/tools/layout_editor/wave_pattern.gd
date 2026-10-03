@tool
class_name WavePattern
extends LayoutPattern
## Pegs along a horizontal sine wave centred on the node.

@export_range(2, 64) var count: int = 11:
	set(value):
		count = value
		notify_changed()
@export var width: float = 280.0:
	set(value):
		width = value
		notify_changed()
@export var amplitude: float = 16.0:
	set(value):
		amplitude = value
		notify_changed()
@export var cycles: float = 1.5:
	set(value):
		cycles = value
		notify_changed()
@export var phase_degrees: float = 0.0:
	set(value):
		phase_degrees = value
		notify_changed()


func local_points() -> Array[Vector3i]:
	var points: Array[Vector3i] = []
	var half: int = roundi(width * PX / 2.0)
	var wave: int = roundi(cycles * Trig.FULL_TURN)
	var phase: int = roundi(phase_degrees * 100.0)
	var height: int = roundi(amplitude * PX)
	for index: int in count:
		var x: int = spread(-half, half, index, count)
		var angle: int = phase + spread(0, wave, index, count)
		var y: int = FixedMath.div_round(height * Trig.sin_cd(angle), FixedMath.UNIT)
		points.append(Vector3i(x, y, 0))
	return points
