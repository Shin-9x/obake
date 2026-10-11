class_name SlowMotion
extends RefCounted
## The fever of the last red lantern, in the spirit of the classic peg games. When a single red
## lantern is left unlit and a ball in flight comes near it, the view slows right down and closes
## in, the slower the nearer the ball. After a near miss it lingers a moment, so the player sees
## how close the ball came. When the lantern is lit the view all but stops on it, and the Matsuri
## begins there. Only the view changes; the simulation runs as always.

enum Stage { IDLE, APPROACH, LINGER, STRUCK }

## Distance, in milli-pixels, from which the view slows down, and at which it is slowest.
const REACH: int = 80_000
const CLOSE: int = 25_000
const FAR_SPEED: float = 0.35
const NEAR_SPEED: float = 0.1
## How far a ball must move back from its closest point, in milli-pixels, to count as leaving.
const LEAVING: float = 6_000.0
## Longest slow approach, in seconds, for a ball that keeps bouncing about near the lantern.
const APPROACH_SECONDS: float = 4.0
## Seconds the view stays slow and close after a near miss, and its speed meanwhile.
const LINGER_SECONDS: float = 0.7
const LINGER_SPEED: float = 0.35
## Seconds the view all but stops when the last red lantern is lit, and its speed meanwhile.
const STRUCK_SECONDS: float = 0.9
const STRUCK_SPEED: float = 0.04
## How far the view closes in.
const ZOOM: float = 2.2
const PX: float = 1000.0

var stage: Stage = Stage.IDLE
## Playback speed of the view.
var speed: float = 1.0
## Where the view closes in, in board pixels, while not idle.
var focus: Vector2 = Vector2.ZERO

var _left: float = 0.0
var _closest: float = INF
var _approaching: float = 0.0
## After a near miss the view waits for the balls to leave before it slows down again.
var _spent: bool = false


## The only red lantern left when it is still unlit; otherwise -1.
static func last_red(game: BoardGame) -> int:
	var last: int = -1
	for peg: int in game.roles.size():
		if game.roles[peg] != BoardGame.Role.RED or game.simulation.pegs[peg].removed:
			continue
		if last >= 0:
			return -1
		last = peg
	if last < 0 or game.simulation.pegs[last].lit:
		return -1
	return last


## Distance in milli-pixels from [param peg] to the nearest ball in flight; infinite without one.
static func nearest_ball(game: BoardGame, peg: int) -> float:
	var red: SimPeg = game.simulation.pegs[peg]
	var nearest: float = INF
	for ball: SimBall in game.simulation.balls:
		if ball.active:
			nearest = minf(nearest, Vector2(ball.x - red.x, ball.y - red.y).length())
	return nearest


func reset() -> void:
	stage = Stage.IDLE
	speed = 1.0
	_left = 0.0
	_closest = INF
	_approaching = 0.0
	_spent = false


## Follows [param game] for a frame that lasted [param delta] seconds of real time.
func update(game: BoardGame, delta: float) -> void:
	if stage == Stage.STRUCK or stage == Stage.LINGER:
		_left -= delta
		if _left > 0.0:
			return
		_rest()
	var red: int = last_red(game) if game.simulation.is_shot_active() else -1
	var distance: float = nearest_ball(game, red) if red >= 0 else INF
	if distance > REACH:
		_spent = false
		_closest = INF
		_approaching = 0.0
		_rest()
		return
	if _spent:
		return
	_approaching += delta
	if distance > _closest + LEAVING or _approaching > APPROACH_SECONDS:
		_spent = true
		_closest = INF
		_approaching = 0.0
		stage = Stage.LINGER
		speed = LINGER_SPEED
		_left = LINGER_SECONDS
		return
	_closest = minf(_closest, distance)
	var peg: SimPeg = game.simulation.pegs[red]
	focus = Vector2(peg.x, peg.y) / PX
	stage = Stage.APPROACH
	speed = lerpf(FAR_SPEED, NEAR_SPEED, clampf((REACH - distance) / (REACH - CLOSE), 0.0, 1.0))


## The last red lantern has just been lit at [param at], in board pixels.
func strike(at: Vector2) -> void:
	focus = at
	stage = Stage.STRUCK
	speed = STRUCK_SPEED
	_left = STRUCK_SECONDS
	_spent = true
	_closest = INF
	_approaching = 0.0


func _rest() -> void:
	stage = Stage.IDLE
	speed = 1.0
