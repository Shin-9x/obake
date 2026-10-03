extends GdUnitTestSuite

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const PX: int = FixedMath.PX
const STRAIGHT_DOWN: int = 0
const RIGHT_WALL: int = 1

var _config: BalanceConfig
var _sim: BoardSimulation


func before_test() -> void:
	_config = TestBoards.gdd_config()
	TestBoards.freeze_bucket(_config)
	_sim = BoardSimulation.new(_config)


func test_free_fall_follows_gravity() -> void:
	_sim.launch(_aimed(STRAIGHT_DOWN))
	var ticks: int = 60
	for i: int in ticks:
		_sim.step()
	var ball: SimBall = _sim.balls[0]
	# y = y0 + v0 t + g t^2 / 2 at t = 0.5 s: 12 + 140 + 37.5 px.
	assert_int(ball.y).is_between(188_500, 190_500)
	assert_int(ball.x).is_equal(_config.launcher_x)
	assert_int(ball.vx).is_equal(0)
	assert_int(_sim.tick).is_equal(ticks)


func test_ball_bounces_off_a_peg_with_restitution() -> void:
	var peg: int = _sim.add_round_peg(_config.launcher_x, 100 * PX)
	_sim.launch(_aimed(STRAIGHT_DOWN))
	var incoming: int = 0
	while _sim.events.size() == 0:
		incoming = _sim.balls[0].vy + _expected_gravity_step()
		_sim.step()
	var event: SimEvent = _sim.events.at(0)
	assert_int(event.kind).is_equal(SimEvent.Kind.PEG_HIT)
	assert_int(event.target).is_equal(peg)
	assert_bool(_sim.pegs[peg].lit).is_true()
	var expected: int = -incoming * _config.peg_restitution / FixedMath.PERMILLE
	assert_int(_sim.balls[0].vy).is_between(expected - 2, expected + 2)


func test_ball_bounces_off_the_right_wall() -> void:
	_sim.launch(_aimed(_config.aim_limit))
	var bounce: SimEvent = _step_until(SimEvent.Kind.WALL_BOUNCE)
	assert_object(bounce).is_not_null()
	assert_int(bounce.target).is_equal(RIGHT_WALL)
	var ball: SimBall = _sim.balls[0]
	assert_int(ball.vx).is_less(0)
	assert_int(ball.x + ball.radius).is_less_equal(_config.board_width)


func test_aim_is_clamped_to_the_limit() -> void:
	var clamped: BoardSimulation = BoardSimulation.new(_config)
	_sim.launch(_aimed(-_config.aim_limit))
	clamped.launch(_aimed(-3 * _config.aim_limit))
	for i: int in 30:
		_sim.step()
		clamped.step()
	assert_int(clamped.state_hash()).is_equal(_sim.state_hash())
	assert_int(_sim.balls[0].vx).is_less(0)


func test_speed_never_exceeds_the_maximum() -> void:
	_config.gravity = 10 * _config.gravity
	var fast: BoardSimulation = BoardSimulation.new(_config)
	fast.launch(_aimed(STRAIGHT_DOWN))
	while fast.is_shot_active():
		fast.step()
		var ball: SimBall = fast.balls[0]
		var speed: int = FixedMath.length(ball.vx, ball.vy)
		assert_int(speed).is_less_equal(_config.max_speed + 1)


func test_shot_resolves_when_the_ball_leaves_the_bottom() -> void:
	_sim.launch(_aimed(STRAIGHT_DOWN))
	assert_bool(_sim.launch(_aimed(STRAIGHT_DOWN))).is_false()
	var lost: SimEvent = _step_until(SimEvent.Kind.BALL_LOST)
	assert_object(lost).is_not_null()
	assert_int(lost.y).is_greater(_config.board_height)
	var kinds: Array[int] = _event_kinds()
	assert_int(kinds.back()).is_equal(SimEvent.Kind.SHOT_RESOLVED)
	assert_bool(_sim.is_shot_active()).is_false()
	assert_bool(_sim.launch(_aimed(STRAIGHT_DOWN))).is_true()


func test_lit_pegs_are_removed_when_the_shot_ends() -> void:
	var peg: int = _sim.add_round_peg(_config.launcher_x + 3 * PX, 100 * PX)
	TestBoards.run_shot(_sim, STRAIGHT_DOWN, _away())
	assert_bool(_sim.pegs[peg].removed).is_true()
	_sim.events.clear()
	TestBoards.run_shot(_sim, STRAIGHT_DOWN, _away())
	assert_array(_event_kinds()).not_contains([SimEvent.Kind.PEG_HIT])


func test_untouched_pegs_stay() -> void:
	var far: int = _sim.add_round_peg(20 * PX, 300 * PX)
	TestBoards.run_shot(_sim, STRAIGHT_DOWN, _away())
	assert_bool(_sim.pegs[far].lit).is_false()
	assert_bool(_sim.pegs[far].removed).is_false()


func test_rotated_rect_peg_deflects_the_ball() -> void:
	var peg: int = _sim.add_rect_peg(_config.launcher_x, 100 * PX, 20 * PX, 3 * PX, 3000)
	_sim.launch(_aimed(STRAIGHT_DOWN))
	var hit: SimEvent = _step_until(SimEvent.Kind.PEG_HIT)
	assert_object(hit).is_not_null()
	assert_int(hit.target).is_equal(peg)
	# Rotated clockwise on screen, the bar slopes down to the right.
	assert_int(_sim.balls[0].vx).is_greater(0)


func test_shot_waits_for_every_ball_and_balls_pass_through_each_other() -> void:
	_sim.launch(_aimed(STRAIGHT_DOWN))
	_sim.step()
	var first: SimBall = _sim.balls[0]
	# A second ball on top of the first, moving the opposite way horizontally.
	_sim.spawn_ball(first.x, first.y, 50 * PX, first.vy)
	_sim.balls[0].vx = -50 * PX
	_sim.step()
	assert_int(_sim.balls[0].x).is_less(_sim.balls[1].x)
	assert_array(_event_kinds()).is_empty()
	while _sim.is_shot_active():
		_sim.step()
	var lost: int = 0
	for kind: int in _event_kinds():
		if kind == SimEvent.Kind.BALL_LOST:
			lost += 1
	assert_int(lost).is_equal(2)
	assert_int(_event_kinds().back()).is_equal(SimEvent.Kind.SHOT_RESOLVED)


func test_head_on_hit_is_nudged_sideways() -> void:
	var peg: int = _sim.add_round_peg(_config.launcher_x, 100 * PX)
	_sim.launch(_aimed(STRAIGHT_DOWN))
	var hit: SimEvent = _step_until(SimEvent.Kind.PEG_HIT)
	assert_int(hit.target).is_equal(peg)
	assert_int(_sim.balls[0].vx).is_not_equal(0)
	assert_object(_step_until(SimEvent.Kind.SHOT_RESOLVED)).is_not_null()
	assert_array(_event_kinds()).not_contains([SimEvent.Kind.STUCK_CLEARED])


func _aimed(aim: int) -> ShotInput:
	return ShotInput.new(aim, _away())


## Phase that keeps the frozen bucket far from the launcher, so falling balls are lost.
func _away() -> int:
	return TestBoards.bucket_right(_config)


func _expected_gravity_step() -> int:
	return FixedMath.div_round(_config.gravity, BoardSimulation.TICKS_PER_SECOND)


func _step_until(kind: SimEvent.Kind) -> SimEvent:
	for i: int in TestBoards.MAX_SHOT_TICKS:
		var first_new: int = _sim.events.size()
		_sim.step()
		for index: int in range(first_new, _sim.events.size()):
			if _sim.events.at(index).kind == kind:
				return _sim.events.at(index)
	return null


func _event_kinds() -> Array[int]:
	var kinds: Array[int] = []
	for index: int in _sim.events.size():
		kinds.append(_sim.events.at(index).kind)
	return kinds
