@tool
class_name SimBall
## A ball in flight. Position in milli-pixels, velocity in milli-pixels per second.
##
## The modifiers are set by the shot's ball effect and cleared whenever the ball is reused.

## Most pegs a ball can pass through in one shot.
const GHOST_CAPACITY: int = 8

var x: int = 0
var y: int = 0
var vx: int = 0
var vy: int = 0
var radius: int = 0
var active: bool = false
## Consecutive ticks spent below the stuck speed.
var slow_ticks: int = 0

## Bounce override for pegs and walls, in permille; -1 keeps the defaults.
var restitution: int = -1
## Pegs still to pass through, hitting them without bouncing.
var ghost_hits: int = 0
## Pegs already passed through this shot, ignored from then on; first [member ghost_count] valid.
var ghosted: PackedInt32Array = PackedInt32Array()
var ghost_count: int = 0
## Pull towards attractor pegs within this distance, in milli-pixels.
var attraction_radius: int = 0
## Acceleration of that pull, in milli-pixels per second squared.
var attraction_strength: int = 0
## Bounces left off the bottom of the board.
var floor_bounces: int = 0


func _init() -> void:
	ghosted.resize(GHOST_CAPACITY)


func clear_modifiers() -> void:
	restitution = -1
	ghost_hits = 0
	ghost_count = 0
	attraction_radius = 0
	attraction_strength = 0
	floor_bounces = 0


func has_ghosted(peg: int) -> bool:
	for index: int in ghost_count:
		if ghosted[index] == peg:
			return true
	return false
