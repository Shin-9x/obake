class_name HitSparks
extends Node2D
## Pooled bursts drawn in one pass: a ring and sparks where a lantern is hit, a puff where a lit
## lantern leaves the board, and confetti for a Matsuri. Nothing is allocated after start, and
## processing stops while nothing is showing.

enum Kind { HIT, PUFF, CONFETTI }

const POOL_SIZE: int = 96
const LIFETIMES: Array[float] = [0.25, 0.35, 1.6]
const SPARKS: int = 4
const RING_START: float = 3.0
const RING_GROWTH: float = 6.0
const SPARK_LENGTH: float = 3.0
const PUFF_RADIUS: float = 6.0
## Downward pull on confetti, in pixels per second squared.
const CONFETTI_GRAVITY: float = 220.0
const CONFETTI_SIZE: Vector2 = Vector2(2, 3)
const CONFETTI_COLOURS: Array[Color] = [
	Color("#ffd866"), Color("#ff8fa3"), Color("#6fc3ff"), Color("#9be37a"), Color("#f4e9c9")
]

var _kinds: PackedInt32Array = PackedInt32Array()
var _ages: PackedFloat32Array = PackedFloat32Array()
var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _colours: PackedColorArray = PackedColorArray()
var _next: int = 0
var _showing: int = 0


func _ready() -> void:
	_kinds.resize(POOL_SIZE)
	_ages.resize(POOL_SIZE)
	_ages.fill(-1.0)
	_positions.resize(POOL_SIZE)
	_velocities.resize(POOL_SIZE)
	_colours.resize(POOL_SIZE)
	set_process(false)


func hit(at: Vector2, colour: Color) -> void:
	_spawn(Kind.HIT, at, Vector2.ZERO, colour)


func puff(at: Vector2, colour: Color) -> void:
	_spawn(Kind.PUFF, at, Vector2.ZERO, colour)


## Throws [param count] bits of confetti upward from [param origin], fanned out evenly.
func confetti(origin: Vector2, count: int) -> void:
	for index: int in count:
		var angle: float = -PI * (0.15 + 0.7 * index / maxf(1.0, count - 1.0))
		var speed: float = 120.0 + 60.0 * (index % 3)
		var colour: Color = CONFETTI_COLOURS[index % CONFETTI_COLOURS.size()]
		_spawn(Kind.CONFETTI, origin, Vector2.from_angle(angle) * speed, colour)


func clear() -> void:
	_ages.fill(-1.0)
	_showing = 0
	set_process(false)
	queue_redraw()


func showing() -> int:
	return _showing


func _spawn(kind: Kind, at: Vector2, velocity: Vector2, colour: Color) -> void:
	if _ages[_next] < 0.0:
		_showing += 1
	_kinds[_next] = kind
	_ages[_next] = 0.0
	_positions[_next] = at
	_velocities[_next] = velocity
	_colours[_next] = colour
	_next = (_next + 1) % POOL_SIZE
	set_process(true)


func _process(delta: float) -> void:
	for index: int in POOL_SIZE:
		if _ages[index] < 0.0:
			continue
		_ages[index] += delta
		if _kinds[index] == Kind.CONFETTI:
			_velocities[index].y += CONFETTI_GRAVITY * delta
			_positions[index] += _velocities[index] * delta
		if _ages[index] >= LIFETIMES[_kinds[index]]:
			_ages[index] = -1.0
			_showing -= 1
	queue_redraw()
	if _showing <= 0:
		_showing = 0
		set_process(false)


func _draw() -> void:
	for index: int in POOL_SIZE:
		var age: float = _ages[index]
		if age < 0.0:
			continue
		var progress: float = age / LIFETIMES[_kinds[index]]
		var colour: Color = _colours[index]
		colour.a = 1.0 - progress
		var at: Vector2 = _positions[index]
		match _kinds[index]:
			Kind.HIT:
				var radius: float = RING_START + RING_GROWTH * progress
				draw_arc(at, radius, 0.0, TAU, 12, colour, 1.0)
				for spark: int in SPARKS:
					var direction: Vector2 = Vector2.from_angle(TAU * (spark + 0.5) / SPARKS)
					draw_line(
						at + direction * radius, at + direction * (radius + SPARK_LENGTH), colour
					)
			Kind.PUFF:
				colour.a *= 0.6
				draw_circle(at, PUFF_RADIUS * (0.5 + progress), colour)
			Kind.CONFETTI:
				draw_rect(Rect2(at, CONFETTI_SIZE), colour)
