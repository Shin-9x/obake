class_name BlastRings
extends Node2D
## Pooled expanding rings for explosions. Drawing and processing stop when no ring is visible.

const POOL_SIZE: int = 8
## Seconds a ring takes to reach its radius and fade.
const LIFETIME: float = 0.3
const PX: float = 1000.0
const COLOUR: Color = Color("#ffb347")

var _centres: PackedVector2Array = PackedVector2Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
var _ages: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0


func _ready() -> void:
	_centres.resize(POOL_SIZE)
	_radii.resize(POOL_SIZE)
	_ages.resize(POOL_SIZE)
	_ages.fill(-1.0)
	set_process(false)


## Starts a ring at ([param x], [param y]) growing to [param radius], all in milli-pixels.
func burst(x: int, y: int, radius: int) -> void:
	_centres[_next] = Vector2(x, y) / PX
	_radii[_next] = radius / PX
	_ages[_next] = 0.0
	_next = (_next + 1) % POOL_SIZE
	set_process(true)


func clear() -> void:
	_ages.fill(-1.0)
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	var any_visible: bool = false
	for index: int in POOL_SIZE:
		if _ages[index] < 0.0:
			continue
		_ages[index] += delta
		if _ages[index] >= LIFETIME:
			_ages[index] = -1.0
		else:
			any_visible = true
	queue_redraw()
	if not any_visible:
		set_process(false)


func _draw() -> void:
	for index: int in POOL_SIZE:
		if _ages[index] < 0.0:
			continue
		var progress: float = _ages[index] / LIFETIME
		var colour: Color = COLOUR
		colour.a = 1.0 - progress
		draw_arc(_centres[index], _radii[index] * progress, 0.0, TAU, 24, colour, 1.0)
