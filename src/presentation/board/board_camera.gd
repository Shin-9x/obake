class_name BoardCamera
extends RefCounted
## Moves the board's world node: shakes it, and closes in on a point for the slow motion. The
## shake follows fixed waves rather than random numbers, so it looks the same every time.

const ZOOM: float = 1.6
## Zoom gained or lost per second.
const ZOOM_RATE: float = 3.0
## Strength lost per second, in pixels.
const SHAKE_DECAY: float = 18.0
const MAX_SHAKE: float = 6.0

var world: Node2D
## Board size in pixels, to keep the view centred when zooming.
var size: Vector2 = Vector2(360, 360)

var _zoom: float = 1.0
var _target_zoom: float = 1.0
var _focus: Vector2 = Vector2.ZERO
var _shake: float = 0.0
var _time: float = 0.0


## Adds [param strength] pixels of shake, up to a ceiling.
func shake(strength: float) -> void:
	_shake = minf(MAX_SHAKE, _shake + strength)


## Closes in on [param point], in board pixels, or pulls back when [param on] is false.
func focus(point: Vector2, on: bool) -> void:
	if on:
		_focus = point
	_target_zoom = ZOOM if on else 1.0


func reset() -> void:
	_zoom = 1.0
	_target_zoom = 1.0
	_shake = 0.0
	_apply(Vector2.ZERO)


## True while the view is still moving, so the screen keeps updating it.
func busy() -> bool:
	return _shake > 0.0 or not is_equal_approx(_zoom, _target_zoom)


func update(delta: float) -> void:
	_time += delta
	_zoom = move_toward(_zoom, _target_zoom, ZOOM_RATE * delta)
	_shake = maxf(0.0, _shake - SHAKE_DECAY * delta)
	_apply(Vector2(sin(_time * 71.0), cos(_time * 53.0)) * _shake)


## The view centre slides from the board centre to the focus as the zoom grows, and the board
## always fills the view.
func _apply(offset: Vector2) -> void:
	if world == null:
		return
	world.scale = Vector2(_zoom, _zoom)
	var centre: Vector2 = size / 2.0
	var view: Vector2 = centre.lerp(_focus, (_zoom - 1.0) / (ZOOM - 1.0))
	var position: Vector2 = centre - view * _zoom
	world.position = position.clamp(size - size * _zoom, Vector2.ZERO) + offset
