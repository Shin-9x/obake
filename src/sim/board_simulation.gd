@tool
class_name BoardSimulation
## Deterministic simulation of one board at a fixed 120 Hz: balls, pegs, walls and the bucket.
##
## Advance it with [method step] during a shot and [method idle_step] between shots, and read what
## happened from [member events]. Balls never collide with each other. Presentation reads this
## state and must never write it.
##
## Everything that moves on its own (the bucket and the moving groups) follows [member clock].
## A shot sets the clock from its input, so time spent aiming never affects a replay.

const TICKS_PER_SECOND: int = 120
## Longest flight the aim guide predicts.
const PREDICTION_TICKS: int = 4 * TICKS_PER_SECOND

const _UNIT: int = FixedMath.UNIT
const _PERMILLE: int = FixedMath.PERMILLE
const _HASH_MODULUS: int = 2_147_483_647
const _HASH_MULTIPLIER: int = 1_000_003

## Ticks simulated in shots; event timestamps use it.
var tick: int = 0
## Board time that drives the bucket and the moving groups.
var clock: int = 0
var events: SimEventQueue = SimEventQueue.new()
var balls: Array[SimBall] = []
var pegs: Array[SimPeg] = []
var walls: Array[SimWall] = []
var groups: Array[MovingGroup] = []
var zones: Array[SimZone] = []
var bucket: Bucket
## Index of the ball fired by the last [method launch].
var launched_ball: int = -1

var _config: BalanceConfig
var _grid: SpatialGrid
var _contact: Contact = Contact.new()
var _ghost: SimBall = SimBall.new()
var _gravity_step: int = 0
var _stuck_speed_squared: int = 0
var _shot_active: bool = false
var _max_extent: int = 0


func _init(config: BalanceConfig) -> void:
	_config = config
	_grid = SpatialGrid.new(config.board_width, config.board_height)
	bucket = Bucket.new(config)
	_gravity_step = FixedMath.div_round(config.gravity, TICKS_PER_SECOND)
	_stuck_speed_squared = config.stuck_speed * config.stuck_speed
	var width: int = config.board_width
	var height: int = config.board_height
	add_wall(0, height, 0, 0)
	add_wall(width, 0, width, height)
	add_wall(0, 0, width, 0)


## Adds a round peg. With a [param group] index the peg moves with that group; its position is
## then the base pose, where it sits when the group's phase is zero.
func add_round_peg(x: int, y: int, group: int = -1) -> int:
	return _add_peg(SimPeg.create_round(x, y, _config.peg_radius), group)


func add_rect_peg(
	x: int, y: int, half_width: int, half_height: int, angle_cd: int, group: int = -1
) -> int:
	return _add_peg(SimPeg.create_rect(x, y, half_width, half_height, angle_cd), group)


## Adds a one-sided wall; see [SimWall] for which side is playable.
func add_wall(ax: int, ay: int, bx: int, by: int) -> int:
	walls.append(SimWall.new(ax, ay, bx, by))
	return walls.size() - 1


## Adds a circular zone and returns its index; it brakes nothing until its drag is set.
func add_zone(x: int, y: int, radius: int) -> int:
	zones.append(SimZone.new(x, y, radius))
	return zones.size() - 1


## Index of the first zone containing ([param x], [param y]), or -1.
func zone_at(x: int, y: int) -> int:
	for index: int in zones.size():
		if zones[index].contains(x, y):
			return index
	return -1


## Adds an empty moving group and returns its index. [param pivot_x] and [param pivot_y] only
## matter for rotation, [param travel_x] and [param travel_y] only for oscillation.
func add_moving_group(
	motion: MovingGroup.Motion,
	pivot_x: int,
	pivot_y: int,
	travel_x: int,
	travel_y: int,
	period: int,
	clockwise: bool,
	phase_offset: int
) -> int:
	var group: MovingGroup = MovingGroup.new()
	group.motion = motion
	group.pivot_x = pivot_x
	group.pivot_y = pivot_y
	group.travel_x = travel_x
	group.travel_y = travel_y
	group.period = maxi(1, period)
	group.clockwise = clockwise
	group.phase_offset = phase_offset
	groups.append(group)
	return groups.size() - 1


func is_shot_active() -> bool:
	return _shot_active


## Launches a ball from the launcher. Returns false while a shot is still in progress.
func launch(input: ShotInput) -> bool:
	if _shot_active:
		return false
	clock = input.board_clock
	bucket.set_phase(clock)
	_place_groups()
	launched_ball = spawn_ball(_config.launcher_x, _config.launcher_y, 0, 0)
	_aim_ball(balls[launched_ball], input.aim)
	_shot_active = true
	return true


## Puts a ball in flight, reusing a lost one when possible, and returns its index. Ball effects
## such as Splitter add balls this way during a shot.
func spawn_ball(x: int, y: int, vx: int, vy: int) -> int:
	var index: int = balls.size()
	for candidate: int in balls.size():
		if not balls[candidate].active:
			index = candidate
			break
	if index == balls.size():
		balls.append(SimBall.new())
	var ball: SimBall = balls[index]
	ball.x = x
	ball.y = y
	ball.vx = vx
	ball.vy = vy
	ball.radius = _config.ball_radius
	ball.active = true
	ball.slow_ticks = 0
	ball.clear_modifiers()
	return index


## Advances the board between shots: the bucket and the moving groups keep going while the
## player aims.
func idle_step() -> void:
	if _shot_active:
		return
	_advance_clock()


func step() -> void:
	if not _shot_active:
		return
	tick += 1
	_advance_clock()
	var any_active: bool = false
	var stuck: bool = false
	for index: int in balls.size():
		var ball: SimBall = balls[index]
		if not ball.active:
			continue
		_attract(ball)
		_drag(ball)
		_integrate(ball)
		_collide_with_walls(index, ball)
		_collide_with_pegs(index, ball)
		_collide_with_rims(ball)
		if bucket.catches(ball.x, ball.y):
			ball.active = false
			events.push(SimEvent.Kind.BUCKET_CATCH, tick, index, -1, ball.x, ball.y)
		elif ball.floor_bounces > 0 and ball.y + ball.radius >= _config.board_height:
			ball.floor_bounces -= 1
			ball.y = _config.board_height - ball.radius
			ball.vy = -FixedMath.div_round(absi(ball.vy) * _wall_restitution(ball), _PERMILLE)
			events.push(SimEvent.Kind.FLOOR_BOUNCE, tick, index, -1, ball.x, ball.y)
			any_active = true
		elif ball.y - ball.radius > _config.board_height:
			ball.active = false
			events.push(SimEvent.Kind.BALL_LOST, tick, index, -1, ball.x, ball.y)
		else:
			any_active = true
			stuck = _track_slowness(ball) or stuck
	if stuck:
		_clear_stuck()
	if not any_active:
		_resolve_shot()


## Flies a ghost ball along [param aim] until its [param contacts]-th contact or until it leaves
## the board, without changing any state. Past the first contact the ghost bounces off walls,
## pegs and rims as a plain ball would. Moving pegs are taken where they are now. Writes x, y
## pairs (milli-pixels) every [param sample_ticks] ticks and at every contact into
## [param out_points], always ending with the last position, and returns the point count.
func predict_path(
	aim: int, sample_ticks: int, out_points: PackedInt32Array, contacts: int = 1
) -> int:
	var capacity: int = out_points.size() / 2
	if capacity == 0:
		return 0
	var ghost: SimBall = _ghost
	ghost.x = _config.launcher_x
	ghost.y = _config.launcher_y
	ghost.radius = _config.ball_radius
	_aim_ball(ghost, aim)
	var count: int = _write_point(out_points, 0, ghost)
	var touched: int = 0
	for flight_tick: int in range(1, PREDICTION_TICKS + 1):
		_drag(ghost)
		_integrate(ghost)
		var left: bool = ghost.y - ghost.radius > _config.board_height
		var contact: bool = false
		if not left:
			contact = _touches_anything(ghost) if touched + 1 >= contacts else _bounce_ghost(ghost)
		if contact:
			touched += 1
		var ended: bool = left or touched >= contacts
		if ended or contact or flight_tick % sample_ticks == 0:
			count = _write_point(out_points, mini(count, capacity - 1), ghost)
		if ended:
			break
	return count


## Writes into [param out] the pegs still on the board whose surface lies within [param radius]
## of ([param x], [param y]), in a stable order, and returns how many there are. [param out] must
## have room for every peg.
func pegs_within(x: int, y: int, radius: int, out: PackedInt32Array) -> int:
	var count: int = 0
	var reach: int = radius + _max_extent
	_grid.query(x - reach, y - reach, x + reach, y + reach)
	for result: int in _grid.result_count:
		var index: int = _grid.results[result]
		if _surface_within(pegs[index], x, y, radius):
			out[count] = index
			count += 1
	for group: MovingGroup in groups:
		if not group.overlaps(x - reach, y - reach, x + reach, y + reach):
			continue
		for index: int in group.pegs:
			var peg: SimPeg = pegs[index]
			if not peg.removed and _surface_within(peg, x, y, radius):
				out[count] = index
				count += 1
	return count


## Takes [param peg] off the board at once, as a vanished illusion or a layer out of play.
func remove_peg(peg: int) -> void:
	var removed: SimPeg = pegs[peg]
	removed.removed = true
	removed.lit = false
	if removed.group < 0:
		_grid.remove(peg)


## Puts a peg taken off by [method remove_peg] back on the board, unlit.
func restore_peg(peg: int) -> void:
	var restored: SimPeg = pegs[peg]
	restored.removed = false
	restored.lit = false
	if restored.group < 0:
		_grid.restore(peg)


## Lights [param peg] as if a ball had touched it, without a [constant SimEvent.Kind.PEG_HIT].
func mark_hit(peg: int) -> void:
	pegs[peg].lit = true


## Clears the lit pegs from the board; persistent pegs only go dark.
func remove_lit_pegs() -> void:
	for peg_index: int in pegs.size():
		var peg: SimPeg = pegs[peg_index]
		if not peg.lit or peg.removed:
			continue
		if peg.persistent:
			peg.lit = false
			continue
		peg.removed = true
		if peg.group < 0:
			_grid.remove(peg_index)


## Order-sensitive hash of the full simulation state, for golden tests and desync checks.
## The clock is covered through the bucket phase and the positions of moving pegs.
func state_hash() -> int:
	var result: int = _mix(0, tick)
	result = _mix(result, bucket.phase)
	for ball: SimBall in balls:
		result = _mix(result, 1 if ball.active else 0)
		result = _mix(result, ball.x)
		result = _mix(result, ball.y)
		result = _mix(result, ball.vx)
		result = _mix(result, ball.vy)
		result = _mix(result, ball.slow_ticks)
	for peg: SimPeg in pegs:
		var flags: int = (1 if peg.lit else 0) + (2 if peg.removed else 0)
		result = _mix(result, flags + (4 if peg.illusion else 0))
		if peg.group >= 0:
			result = _mix(result, peg.x)
			result = _mix(result, peg.y)
	return result


func _add_peg(peg: SimPeg, group: int) -> int:
	var index: int = pegs.size()
	pegs.append(peg)
	_max_extent = maxi(_max_extent, peg.extent)
	if group < 0:
		_grid.insert(index, peg.min_x, peg.min_y, peg.max_x, peg.max_y)
		return index
	var moving: MovingGroup = groups[group]
	peg.group = group
	moving.pegs.append(index)
	moving.cover(peg)
	_move_group(moving, clock - 1, false)
	_move_group(moving, clock, true)
	return index


func _advance_clock() -> void:
	clock += 1
	bucket.set_phase(clock)
	for group: MovingGroup in groups:
		_move_group(group, clock, true)


## Puts every group where the clock says, with velocities from the tick before.
func _place_groups() -> void:
	for group: MovingGroup in groups:
		_move_group(group, clock - 1, false)
		_move_group(group, clock, true)


## Places the pegs of [param group] at [param at_clock]. One sine and cosine per group; member
## pegs only multiply, including rectangles, whose angle uses the angle-addition formulas.
func _move_group(group: MovingGroup, at_clock: int, track_velocity: bool) -> void:
	var angle: int = group.angle_at(at_clock)
	var sine: int = Trig.sin_cd(angle)
	if group.motion == MovingGroup.Motion.OSCILLATE:
		var dx: int = FixedMath.div_round(group.travel_x * sine, _UNIT)
		var dy: int = FixedMath.div_round(group.travel_y * sine, _UNIT)
		for peg_index: int in group.pegs:
			var peg: SimPeg = pegs[peg_index]
			_place_peg(peg, peg.base_x + dx, peg.base_y + dy, track_velocity)
		return
	var cosine: int = Trig.cos_cd(angle)
	for peg_index: int in group.pegs:
		var peg: SimPeg = pegs[peg_index]
		var offset_x: int = peg.base_x - group.pivot_x
		var offset_y: int = peg.base_y - group.pivot_y
		var x: int = group.pivot_x + FixedMath.div_round(offset_x * cosine - offset_y * sine, _UNIT)
		var y: int = group.pivot_y + FixedMath.div_round(offset_x * sine + offset_y * cosine, _UNIT)
		_place_peg(peg, x, y, track_velocity)
		if peg.shape == SimPeg.Shape.RECT:
			peg.angle_cd = peg.base_angle + angle
			peg.cos_angle = FixedMath.div_round(peg.base_cos * cosine - peg.base_sin * sine, _UNIT)
			peg.sin_angle = FixedMath.div_round(peg.base_sin * cosine + peg.base_cos * sine, _UNIT)


func _place_peg(peg: SimPeg, x: int, y: int, track_velocity: bool) -> void:
	peg.vx = (x - peg.x) * TICKS_PER_SECOND if track_velocity else 0
	peg.vy = (y - peg.y) * TICKS_PER_SECOND if track_velocity else 0
	peg.x = x
	peg.y = y


func _aim_ball(ball: SimBall, aim: int) -> void:
	var clamped: int = clampi(aim, -_config.aim_limit, _config.aim_limit)
	var speed: int = _config.launch_speed
	ball.vx = FixedMath.div_round(speed * Trig.sin_cd(clamped), _UNIT)
	ball.vy = FixedMath.div_round(speed * Trig.cos_cd(clamped), _UNIT)


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
		if _resolve_contact(ball, _wall_restitution(ball), 0, 0):
			events.push(SimEvent.Kind.WALL_BOUNCE, tick, ball_index, wall_index, ball.x, ball.y)


func _collide_with_pegs(ball_index: int, ball: SimBall) -> void:
	var radius: int = ball.radius
	var left: int = ball.x - radius
	var top: int = ball.y - radius
	var right: int = ball.x + radius
	var bottom: int = ball.y + radius
	_grid.query(left, top, right, bottom)
	for result: int in _grid.result_count:
		_hit_peg(ball_index, ball, _grid.results[result])
	for group: MovingGroup in groups:
		if not group.overlaps(left, top, right, bottom):
			continue
		for peg_index: int in group.pegs:
			var peg: SimPeg = pegs[peg_index]
			var limit: int = radius + peg.extent
			# Cheap reject before the exact test; most members are far from the ball.
			if peg.removed or absi(peg.x - ball.x) >= limit or absi(peg.y - ball.y) >= limit:
				continue
			_hit_peg(ball_index, ball, peg_index)


func _hit_peg(ball_index: int, ball: SimBall, peg_index: int) -> void:
	var peg: SimPeg = pegs[peg_index]
	if ball.ghost_count > 0 and ball.has_ghosted(peg_index):
		return
	if not _touches_peg(ball, peg):
		return
	if peg.illusion:
		# Nothing to bounce off; the board makes the illusion vanish when it sees the hit.
		events.push(SimEvent.Kind.PEG_HIT, tick, ball_index, peg_index, ball.x, ball.y)
		return
	if ball.ghost_hits > 0 and ball.ghost_count < SimBall.GHOST_CAPACITY:
		# Passes through, hitting the peg without bouncing.
		ball.ghost_hits -= 1
		ball.ghosted[ball.ghost_count] = peg_index
		ball.ghost_count += 1
		peg.lit = true
		events.push(SimEvent.Kind.PEG_HIT, tick, ball_index, peg_index, ball.x, ball.y)
		return
	var restitution: int = peg.restitution
	if restitution < 0:
		restitution = ball.restitution if ball.restitution >= 0 else _config.peg_restitution
	var impact: bool = _resolve_contact(ball, restitution, peg.vx, peg.vy)
	if impact:
		_nudge_head_on(ball, peg.vx, peg.vy)
	# Any touch lights a peg; after that only real impacts are reported.
	if impact or not peg.lit:
		peg.lit = true
		events.push(SimEvent.Kind.PEG_HIT, tick, ball_index, peg_index, ball.x, ball.y)


func _collide_with_rims(ball: SimBall) -> void:
	if ball.y + ball.radius + bucket.rim_radius <= bucket.y:
		return
	if _touches_rim(ball, -1):
		_resolve_contact(ball, _wall_restitution(ball), 0, 0)
	if _touches_rim(ball, 1):
		_resolve_contact(ball, _wall_restitution(ball), 0, 0)


## [param side] is -1 for the left rim and 1 for the right one.
func _touches_rim(ball: SimBall, side: int) -> bool:
	var rim_x: int = bucket.x + side * bucket.half_width
	return Collision.circle_vs_circle(
		ball.x, ball.y, ball.radius, rim_x, bucket.y, bucket.rim_radius, _contact
	)


func _touches_peg(ball: SimBall, peg: SimPeg) -> bool:
	if peg.shape == SimPeg.Shape.ROUND:
		return Collision.circle_vs_circle(
			ball.x, ball.y, ball.radius, peg.x, peg.y, peg.radius, _contact
		)
	return Collision.circle_vs_box(ball.x, ball.y, ball.radius, peg, _contact)


func _touches_anything(ball: SimBall) -> bool:
	for wall: SimWall in walls:
		if Collision.circle_vs_wall(ball.x, ball.y, ball.radius, wall, _contact):
			return true
	var radius: int = ball.radius
	var left: int = ball.x - radius
	var top: int = ball.y - radius
	var right: int = ball.x + radius
	var bottom: int = ball.y + radius
	_grid.query(left, top, right, bottom)
	for result: int in _grid.result_count:
		if _touches_peg(ball, pegs[_grid.results[result]]):
			return true
	for group: MovingGroup in groups:
		if not group.overlaps(left, top, right, bottom):
			continue
		for peg_index: int in group.pegs:
			var peg: SimPeg = pegs[peg_index]
			if not peg.removed and _touches_peg(ball, peg):
				return true
	return _touches_rim(ball, -1) or _touches_rim(ball, 1)


## Bounces the prediction ghost off whatever it touches, without events or lighting anything.
## Returns whether it hit something this tick.
func _bounce_ghost(ghost: SimBall) -> bool:
	var hit: bool = false
	for wall: SimWall in walls:
		if Collision.circle_vs_wall(ghost.x, ghost.y, ghost.radius, wall, _contact):
			hit = _resolve_contact(ghost, _config.wall_restitution, 0, 0) or hit
	var radius: int = ghost.radius
	var left: int = ghost.x - radius
	var top: int = ghost.y - radius
	var right: int = ghost.x + radius
	var bottom: int = ghost.y + radius
	_grid.query(left, top, right, bottom)
	for result: int in _grid.result_count:
		hit = _bounce_ghost_off(ghost, pegs[_grid.results[result]]) or hit
	for group: MovingGroup in groups:
		if not group.overlaps(left, top, right, bottom):
			continue
		for peg_index: int in group.pegs:
			var peg: SimPeg = pegs[peg_index]
			if not peg.removed:
				hit = _bounce_ghost_off(ghost, peg) or hit
	if _touches_rim(ghost, -1):
		hit = _resolve_contact(ghost, _config.wall_restitution, 0, 0) or hit
	if _touches_rim(ghost, 1):
		hit = _resolve_contact(ghost, _config.wall_restitution, 0, 0) or hit
	return hit


func _bounce_ghost_off(ghost: SimBall, peg: SimPeg) -> bool:
	if not _touches_peg(ghost, peg):
		return false
	var restitution: int = peg.restitution if peg.restitution >= 0 else _config.peg_restitution
	if not _resolve_contact(ghost, restitution, peg.vx, peg.vy):
		return false
	_nudge_head_on(ghost, peg.vx, peg.vy)
	return true


## Brakes a ball whose centre lies in a zone with drag.
func _drag(ball: SimBall) -> void:
	for zone: SimZone in zones:
		if zone.drag > 0 and zone.contains(ball.x, ball.y):
			var keep: int = _PERMILLE - zone.drag
			ball.vx = FixedMath.div_round(ball.vx * keep, _PERMILLE)
			ball.vy = FixedMath.div_round(ball.vy * keep, _PERMILLE)
			return


func _wall_restitution(ball: SimBall) -> int:
	return ball.restitution if ball.restitution >= 0 else _config.wall_restitution


## Accelerates a ball with an attraction towards the nearest attractor peg in range.
func _attract(ball: SimBall) -> void:
	var radius: int = ball.attraction_radius
	if radius <= 0:
		return
	var best: int = -1
	var best_squared: int = radius * radius
	_grid.query(ball.x - radius, ball.y - radius, ball.x + radius, ball.y + radius)
	for result: int in _grid.result_count:
		var index: int = _grid.results[result]
		var candidate: SimPeg = pegs[index]
		if candidate.attractor:
			var squared: int = _distance_squared(candidate, ball.x, ball.y)
			if squared < best_squared or (squared == best_squared and index < best):
				best = index
				best_squared = squared
	for group: MovingGroup in groups:
		if not group.overlaps(ball.x - radius, ball.y - radius, ball.x + radius, ball.y + radius):
			continue
		for index: int in group.pegs:
			var member: SimPeg = pegs[index]
			if member.attractor and not member.removed:
				var squared: int = _distance_squared(member, ball.x, ball.y)
				if squared < best_squared or (squared == best_squared and index < best):
					best = index
					best_squared = squared
	if best < 0:
		return
	var distance: int = FixedMath.isqrt(best_squared)
	if distance == 0:
		return
	var pull: int = FixedMath.div_round(ball.attraction_strength, TICKS_PER_SECOND)
	ball.vx += FixedMath.div_round((pegs[best].x - ball.x) * pull, distance)
	ball.vy += FixedMath.div_round((pegs[best].y - ball.y) * pull, distance)


static func _distance_squared(peg: SimPeg, x: int, y: int) -> int:
	var dx: int = peg.x - x
	var dy: int = peg.y - y
	return dx * dx + dy * dy


static func _surface_within(peg: SimPeg, x: int, y: int, radius: int) -> bool:
	var reach: int = radius + peg.extent
	return _distance_squared(peg, x, y) <= reach * reach


## Pushes the ball out along the contact normal and reflects its velocity relative to the
## obstacle, so a moving peg carries the ball along. Returns true when they were closing in.
func _resolve_contact(ball: SimBall, restitution: int, obstacle_vx: int, obstacle_vy: int) -> bool:
	var contact: Contact = _contact
	ball.x += FixedMath.div_round(contact.nx * contact.depth, _UNIT)
	ball.y += FixedMath.div_round(contact.ny * contact.depth, _UNIT)
	var relative_x: int = ball.vx - obstacle_vx
	var relative_y: int = ball.vy - obstacle_vy
	var approach: int = FixedMath.div_round(
		relative_x * contact.nx + relative_y * contact.ny, _UNIT
	)
	if approach >= 0:
		return false
	var impulse: int = FixedMath.div_round(approach * (_PERMILLE + restitution), _PERMILLE)
	ball.vx -= FixedMath.div_round(impulse * contact.nx, _UNIT)
	ball.vy -= FixedMath.div_round(impulse * contact.ny, _UNIT)
	return true


## After a head-on rebound, pushes the ball slightly sideways, alternating sides by tick parity.
func _nudge_head_on(ball: SimBall, obstacle_vx: int, obstacle_vy: int) -> void:
	var contact: Contact = _contact
	var relative_x: int = ball.vx - obstacle_vx
	var relative_y: int = ball.vy - obstacle_vy
	var sideways: int = FixedMath.div_round(
		relative_y * contact.nx - relative_x * contact.ny, _UNIT
	)
	if absi(sideways) >= _config.head_on_tolerance:
		return
	var rebound: int = FixedMath.div_round(relative_x * contact.nx + relative_y * contact.ny, _UNIT)
	var push: int = FixedMath.div_round(rebound * _config.head_on_nudge, _PERMILLE)
	if tick % 2 == 1:
		push = -push
	ball.vx -= FixedMath.div_round(push * contact.ny, _UNIT)
	ball.vy += FixedMath.div_round(push * contact.nx, _UNIT)


## Counts ticks spent below the stuck speed. Returns true once the ball has been slow too long.
func _track_slowness(ball: SimBall) -> bool:
	if ball.vx * ball.vx + ball.vy * ball.vy < _stuck_speed_squared:
		ball.slow_ticks += 1
	else:
		ball.slow_ticks = 0
	return ball.slow_ticks >= _config.stuck_ticks


## GDD rule: a ball slow for too long removes the lit pegs, which frees it.
func _clear_stuck() -> void:
	remove_lit_pegs()
	for ball: SimBall in balls:
		ball.slow_ticks = 0
	events.push(SimEvent.Kind.STUCK_CLEARED, tick, -1, -1, 0, 0)


func _resolve_shot() -> void:
	remove_lit_pegs()
	_shot_active = false
	events.push(SimEvent.Kind.SHOT_RESOLVED, tick, -1, -1, 0, 0)


static func _write_point(out_points: PackedInt32Array, index: int, ball: SimBall) -> int:
	out_points[2 * index] = ball.x
	out_points[2 * index + 1] = ball.y
	return index + 1


static func _mix(current: int, value: int) -> int:
	return (current * _HASH_MULTIPLIER + posmod(value, _HASH_MODULUS)) % _HASH_MODULUS
