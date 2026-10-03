class_name BoardSimulation
## Deterministic simulation of one board at a fixed 120 Hz: balls, pegs and walls.
##
## Advance it with [method step] and read what happened from [member events]. Balls never collide
## with each other. Presentation reads this state and must never write it.

const TICKS_PER_SECOND: int = 120

const _UNIT: int = FixedMath.UNIT
const _PERMILLE: int = FixedMath.PERMILLE
const _HASH_MODULUS: int = 2_147_483_647
const _HASH_MULTIPLIER: int = 1_000_003

var tick: int = 0
var events: SimEventQueue = SimEventQueue.new()
var balls: Array[SimBall] = []
var pegs: Array[SimPeg] = []
var walls: Array[SimWall] = []

var _config: BalanceConfig
var _grid: SpatialGrid
var _contact: Contact = Contact.new()
var _gravity_step: int = 0
var _shot_active: bool = false


func _init(config: BalanceConfig) -> void:
	_config = config
	_grid = SpatialGrid.new(config.board_width, config.board_height)
	_gravity_step = FixedMath.div_round(config.gravity, TICKS_PER_SECOND)
	var width: int = config.board_width
	var height: int = config.board_height
	add_wall(0, height, 0, 0)
	add_wall(width, 0, width, height)
	add_wall(0, 0, width, 0)


func add_round_peg(x: int, y: int) -> int:
	return _add_peg(SimPeg.create_round(x, y, _config.peg_radius))


func add_rect_peg(x: int, y: int, half_width: int, half_height: int, angle_cd: int) -> int:
	return _add_peg(SimPeg.create_rect(x, y, half_width, half_height, angle_cd))


## Adds a one-sided wall; see [SimWall] for which side is playable.
func add_wall(ax: int, ay: int, bx: int, by: int) -> int:
	walls.append(SimWall.new(ax, ay, bx, by))
	return walls.size() - 1


func is_shot_active() -> bool:
	return _shot_active


## Launches a ball from the launcher. Returns false while a shot is still in progress.
func launch(input: ShotInput) -> bool:
	if _shot_active:
		return false
	var aim: int = clampi(input.aim, -_config.aim_limit, _config.aim_limit)
	var speed: int = _config.launch_speed
	spawn_ball(
		_config.launcher_x,
		_config.launcher_y,
		FixedMath.div_round(speed * Trig.sin_cd(aim), _UNIT),
		FixedMath.div_round(speed * Trig.cos_cd(aim), _UNIT)
	)
	_shot_active = true
	return true


## Puts a ball in flight, reusing a lost one when possible. Ball effects such as Splitter add
## balls this way during a shot.
func spawn_ball(x: int, y: int, vx: int, vy: int) -> void:
	var ball: SimBall = null
	for candidate: SimBall in balls:
		if not candidate.active:
			ball = candidate
			break
	if ball == null:
		ball = SimBall.new()
		balls.append(ball)
	ball.x = x
	ball.y = y
	ball.vx = vx
	ball.vy = vy
	ball.radius = _config.ball_radius
	ball.active = true


func step() -> void:
	if not _shot_active:
		return
	tick += 1
	var any_active: bool = false
	for index: int in balls.size():
		var ball: SimBall = balls[index]
		if not ball.active:
			continue
		_integrate(ball)
		_collide_with_walls(index, ball)
		_collide_with_pegs(index, ball)
		if ball.y - ball.radius > _config.board_height:
			ball.active = false
			events.push(SimEvent.Kind.BALL_LOST, tick, index, -1, ball.x, ball.y)
		else:
			any_active = true
	if not any_active:
		_resolve_shot()


## Order-sensitive hash of the full simulation state, for golden tests and desync checks.
func state_hash() -> int:
	var result: int = _mix(0, tick)
	for ball: SimBall in balls:
		result = _mix(result, 1 if ball.active else 0)
		result = _mix(result, ball.x)
		result = _mix(result, ball.y)
		result = _mix(result, ball.vx)
		result = _mix(result, ball.vy)
	for peg: SimPeg in pegs:
		result = _mix(result, (1 if peg.lit else 0) + (2 if peg.removed else 0))
	return result


func _add_peg(peg: SimPeg) -> int:
	var index: int = pegs.size()
	pegs.append(peg)
	_grid.insert(index, peg.min_x, peg.min_y, peg.max_x, peg.max_y)
	return index


## Semi-implicit Euler: gravity, speed cap, then position.
func _integrate(ball: SimBall) -> void:
	ball.vy += _gravity_step
	var max_speed: int = _config.max_speed
	var speed_squared: int = ball.vx * ball.vx + ball.vy * ball.vy
	if speed_squared > max_speed * max_speed:
		var speed: int = FixedMath.isqrt(speed_squared)
		ball.vx = FixedMath.div_round(ball.vx * max_speed, speed)
		ball.vy = FixedMath.div_round(ball.vy * max_speed, speed)
	ball.x += FixedMath.div_round(ball.vx, TICKS_PER_SECOND)
	ball.y += FixedMath.div_round(ball.vy, TICKS_PER_SECOND)


func _collide_with_walls(ball_index: int, ball: SimBall) -> void:
	for wall_index: int in walls.size():
		if not Collision.circle_vs_wall(ball.x, ball.y, ball.radius, walls[wall_index], _contact):
			continue
		if _resolve_contact(ball, _config.wall_restitution):
			events.push(SimEvent.Kind.WALL_BOUNCE, tick, ball_index, wall_index, ball.x, ball.y)


func _collide_with_pegs(ball_index: int, ball: SimBall) -> void:
	var radius: int = ball.radius
	_grid.query(ball.x - radius, ball.y - radius, ball.x + radius, ball.y + radius)
	for result: int in _grid.result_count:
		var peg_index: int = _grid.results[result]
		var peg: SimPeg = pegs[peg_index]
		var touching: bool = false
		if peg.shape == SimPeg.Shape.ROUND:
			touching = Collision.circle_vs_circle(
				ball.x, ball.y, radius, peg.x, peg.y, peg.radius, _contact
			)
		else:
			touching = Collision.circle_vs_box(ball.x, ball.y, radius, peg, _contact)
		if not touching:
			continue
		var impact: bool = _resolve_contact(ball, _config.peg_restitution)
		# Any touch lights a peg; after that only real impacts are reported.
		if impact or not peg.lit:
			peg.lit = true
			events.push(SimEvent.Kind.PEG_HIT, tick, ball_index, peg_index, ball.x, ball.y)


## Pushes the ball out along the contact normal and reflects the approaching velocity.
## Returns true when the ball was moving into the obstacle.
func _resolve_contact(ball: SimBall, restitution: int) -> bool:
	var contact: Contact = _contact
	ball.x += FixedMath.div_round(contact.nx * contact.depth, _UNIT)
	ball.y += FixedMath.div_round(contact.ny * contact.depth, _UNIT)
	var approach: int = FixedMath.div_round(ball.vx * contact.nx + ball.vy * contact.ny, _UNIT)
	if approach >= 0:
		return false
	var impulse: int = FixedMath.div_round(approach * (_PERMILLE + restitution), _PERMILLE)
	ball.vx -= FixedMath.div_round(impulse * contact.nx, _UNIT)
	ball.vy -= FixedMath.div_round(impulse * contact.ny, _UNIT)
	return true


func _resolve_shot() -> void:
	for peg_index: int in pegs.size():
		var peg: SimPeg = pegs[peg_index]
		if peg.lit and not peg.removed:
			peg.removed = true
			_grid.remove(peg_index)
	_shot_active = false
	events.push(SimEvent.Kind.SHOT_RESOLVED, tick, -1, -1, 0, 0)


static func _mix(current: int, value: int) -> int:
	return (current * _HASH_MULTIPLIER + posmod(value, _HASH_MODULUS)) % _HASH_MODULUS
