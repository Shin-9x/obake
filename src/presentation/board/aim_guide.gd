class_name AimGuide
extends Node2D
## Dotted trajectory from the launcher to the first impact, predicted by the simulation itself.

## One dot every few ticks of predicted flight.
const SAMPLE_TICKS: int = 4
const PX: float = 1000.0

var color: Color = Color.WHITE

var _points: PackedInt32Array = PackedInt32Array()
var _count: int = 0


func _ready() -> void:
	_points.resize(2 * (BoardSimulation.PREDICTION_TICKS / SAMPLE_TICKS + 2))


func show_path(simulation: BoardSimulation, aim: int) -> void:
	_count = simulation.predict_path(aim, SAMPLE_TICKS, _points)
	visible = true
	queue_redraw()


func _draw() -> void:
	for index: int in range(1, _count):
		var point: Vector2 = Vector2(_points[2 * index], _points[2 * index + 1]) / PX
		draw_rect(Rect2(point.round(), Vector2.ONE), color)
	if _count > 1:
		var last: Vector2 = Vector2(_points[2 * _count - 2], _points[2 * _count - 1]) / PX
		draw_arc(last.round(), 3.0, 0.0, TAU, 12, color, 1.0)
