extends GdUnitTestSuite

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const PX: int = FixedMath.PX
const PERIOD: int = 480
## Rounding tolerance on positions, in milli-pixels.
const SLACK: int = 2

var _sim: BoardSimulation


func before_test() -> void:
	var config: BalanceConfig = TestBoards.gdd_config()
	TestBoards.freeze_bucket(config)
	_sim = BoardSimulation.new(config)


func test_clockwise_ring_turns_right_then_down() -> void:
	var peg: SimPeg = _ring_peg(true, 0)
	_idle(PERIOD / 4)
	_assert_at(peg, 180 * PX, 250 * PX)
	_idle(PERIOD / 4)
	_assert_at(peg, 130 * PX, 200 * PX)
	_idle(PERIOD / 2)
	assert_int(peg.x).is_equal(230 * PX)
	assert_int(peg.y).is_equal(200 * PX)


func test_counterclockwise_ring_turns_up() -> void:
	var peg: SimPeg = _ring_peg(false, 0)
	_idle(PERIOD / 4)
	_assert_at(peg, 180 * PX, 150 * PX)


func test_phase_offset_shifts_the_motion() -> void:
	var early: SimPeg = _ring_peg(true, PERIOD / 4)
	_assert_at(early, 180 * PX, 250 * PX)


func test_oscillating_group_slides_within_its_travel() -> void:
	var group: int = _sim.add_moving_group(
		MovingGroup.Motion.OSCILLATE, 0, 0, 40 * PX, 0, PERIOD, true, 0
	)
	var peg: SimPeg = _sim.pegs[_sim.add_round_peg(180 * PX, 100 * PX, group)]
	_idle(PERIOD / 4)
	_assert_at(peg, 220 * PX, 100 * PX)
	_idle(PERIOD / 2)
	_assert_at(peg, 140 * PX, 100 * PX)


func test_peg_velocity_follows_its_motion() -> void:
	var group: int = _sim.add_moving_group(
		MovingGroup.Motion.OSCILLATE, 0, 0, 40 * PX, 0, PERIOD, true, 0
	)
	var peg: SimPeg = _sim.pegs[_sim.add_round_peg(180 * PX, 100 * PX, group)]
	_idle(1)
	# Peak speed of a 40 px sine travel over 4 s: 2 * pi * 40 / 4, about 62.8 px/s.
	assert_int(peg.vx).is_between(61_000, 64_000)
	assert_int(peg.vy).is_equal(0)
	var before: int = peg.x
	_idle(1)
	assert_int(peg.vx).is_equal((peg.x - before) * BoardSimulation.TICKS_PER_SECOND)


func test_rectangles_turn_with_their_ring() -> void:
	var group: int = _sim.add_moving_group(
		MovingGroup.Motion.ROTATE, 180 * PX, 200 * PX, 0, 0, PERIOD, true, 0
	)
	var peg: SimPeg = _sim.pegs[_sim.add_rect_peg(230 * PX, 200 * PX, 8 * PX, 2 * PX, 0, group)]
	_idle(PERIOD / 4)
	assert_int(peg.angle_cd).is_equal(9000)
	assert_int(peg.cos_angle).is_between(-SLACK, SLACK)
	assert_int(peg.sin_angle).is_between(FixedMath.UNIT - SLACK, FixedMath.UNIT)


func test_bounds_cover_every_position() -> void:
	var ring: int = _sim.add_moving_group(
		MovingGroup.Motion.ROTATE, 180 * PX, 200 * PX, 0, 0, PERIOD, true, 0
	)
	var slide: int = _sim.add_moving_group(
		MovingGroup.Motion.OSCILLATE, 0, 0, 0, 30 * PX, PERIOD, true, 0
	)
	_sim.add_rect_peg(240 * PX, 210 * PX, 10 * PX, 3 * PX, 1500, ring)
	_sim.add_round_peg(100 * PX, 100 * PX, slide)
	for i: int in PERIOD:
		_idle(1)
		for peg: SimPeg in _sim.pegs:
			var group: MovingGroup = _sim.groups[peg.group]
			var reach: int = peg.extent
			assert_int(peg.x - reach).is_greater_equal(group.min_x)
			assert_int(peg.x + reach).is_less_equal(group.max_x)
			assert_int(peg.y - reach).is_greater_equal(group.min_y)
			assert_int(peg.y + reach).is_less_equal(group.max_y)


func _ring_peg(clockwise: bool, offset: int) -> SimPeg:
	var group: int = _sim.add_moving_group(
		MovingGroup.Motion.ROTATE, 180 * PX, 200 * PX, 0, 0, PERIOD, clockwise, offset
	)
	return _sim.pegs[_sim.add_round_peg(230 * PX, 200 * PX, group)]


func _idle(ticks: int) -> void:
	for i: int in ticks:
		_sim.idle_step()


func _assert_at(peg: SimPeg, x: int, y: int) -> void:
	assert_int(peg.x).is_between(x - SLACK, x + SLACK)
	assert_int(peg.y).is_between(y - SLACK, y + SLACK)
