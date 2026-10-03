extends GdUnitTestSuite
## Bucket, board clock, moving pegs, stuck-ball rule and aim prediction.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const PX: int = FixedMath.PX
const STRAIGHT_DOWN: int = 0

var _config: BalanceConfig
var _sim: BoardSimulation


func before_test() -> void:
	_config = TestBoards.gdd_config()
	TestBoards.freeze_bucket(_config)
	_sim = BoardSimulation.new(_config)


func test_bucket_catches_a_ball_dropping_between_its_rims() -> void:
	_sim.launch(ShotInput.new(STRAIGHT_DOWN, 0))
	var caught: SimEvent = _step_until(SimEvent.Kind.BUCKET_CATCH)
	assert_object(caught).is_not_null()
	assert_array(_event_kinds()).not_contains([SimEvent.Kind.BALL_LOST])
	assert_int(_event_kinds().back()).is_equal(SimEvent.Kind.SHOT_RESOLVED)


func test_ball_bounces_off_a_bucket_rim() -> void:
	_config.launcher_x = _sim.bucket.x - _sim.bucket.half_width
	var sim: BoardSimulation = BoardSimulation.new(_config)
	sim.launch(ShotInput.new(STRAIGHT_DOWN, 0))
	var bounced: bool = false
	for i: int in TestBoards.MAX_SHOT_TICKS:
		sim.step()
		if sim.balls[0].vy < 0:
			bounced = true
			break
	assert_bool(bounced).is_true()
	assert_int(sim.balls[0].y).is_less(_config.bucket_y)


func test_bucket_follows_the_shot_phase() -> void:
	var phase: int = 1234
	_sim.launch(ShotInput.new(STRAIGHT_DOWN, phase))
	_sim.step()
	assert_int(_sim.bucket.phase).is_equal(phase + 1)
	assert_int(_sim.bucket.x).is_equal(_sim.bucket.x_at(phase + 1))


func test_stuck_ball_clears_the_lit_pegs() -> void:
	# Two pegs closer than the ball's diameter form a pocket; the ball starts at rest inside it.
	var left: int = _sim.add_round_peg(_config.launcher_x - 6 * PX, 100 * PX)
	var right: int = _sim.add_round_peg(_config.launcher_x + 6 * PX, 100 * PX)
	_sim.launch(_aimed(STRAIGHT_DOWN))
	var ball: SimBall = _sim.balls[0]
	ball.y = 93 * PX
	ball.vx = 0
	ball.vy = 0
	var cleared: SimEvent = _step_until(SimEvent.Kind.STUCK_CLEARED)
	assert_object(cleared).is_not_null()
	assert_int(cleared.tick).is_greater_equal(_config.stuck_ticks)
	assert_bool(_sim.pegs[left].removed).is_true()
	assert_bool(_sim.pegs[right].removed).is_true()
	assert_object(_step_until(SimEvent.Kind.SHOT_RESOLVED)).is_not_null()


func test_prediction_ends_at_the_first_real_contact() -> void:
	_sim.add_round_peg(200 * PX, 150 * PX)
	_sim.add_round_peg(120 * PX, 220 * PX)
	var aim: int = 700
	var points: PackedInt32Array = PackedInt32Array()
	points.resize(2 * (BoardSimulation.PREDICTION_TICKS + 1))
	var state_before: int = _sim.state_hash()
	var count: int = _sim.predict_path(aim, 1, points)
	assert_int(_sim.state_hash()).is_equal(state_before)
	assert_int(points[0]).is_equal(_config.launcher_x)
	_sim.launch(_aimed(aim))
	var hit: SimEvent = _step_until(SimEvent.Kind.PEG_HIT)
	assert_object(hit).is_not_null()
	# One point per tick plus the launcher: the last point is the tick of the first contact.
	assert_int(count - 1).is_equal(hit.tick)


func test_prediction_is_capped_by_its_buffer() -> void:
	var points: PackedInt32Array = PackedInt32Array()
	points.resize(2 * 5)
	assert_int(_sim.predict_path(0, 1, points)).is_equal(5)


func test_idle_steps_advance_the_board_clock() -> void:
	for i: int in 10:
		_sim.idle_step()
	assert_int(_sim.clock).is_equal(10)
	assert_int(_sim.bucket.phase).is_equal(10)
	assert_int(_sim.tick).is_equal(0)


func test_time_spent_aiming_never_changes_the_shot() -> void:
	var patient: BoardSimulation = _board_with_moving_pegs()
	var hasty: BoardSimulation = _board_with_moving_pegs()
	for i: int in 500:
		patient.idle_step()
	for i: int in 37:
		hasty.idle_step()
	var input: ShotInput = ShotInput.new(-1200, 1000)
	patient.launch(input)
	hasty.launch(input)
	while patient.is_shot_active() or hasty.is_shot_active():
		patient.step()
		hasty.step()
		assert_int(hasty.state_hash()).is_equal(patient.state_hash())


func test_moving_peg_pushes_the_ball() -> void:
	var group: int = _sim.add_moving_group(
		MovingGroup.Motion.OSCILLATE, 0, 0, 40 * PX, 0, 480, true, 0
	)
	var peg: int = _sim.add_round_peg(100 * PX, 200 * PX, group)
	_sim.launch(ShotInput.new(STRAIGHT_DOWN, 0))
	# A ball at rest just touching the right side of a peg that is sliding right.
	var ball: SimBall = _sim.balls[0]
	ball.x = 108_500
	ball.y = 200 * PX
	ball.vx = 0
	ball.vy = 0
	_sim.step()
	assert_array(_event_kinds()).contains([SimEvent.Kind.PEG_HIT])
	assert_int(_sim.events.at(0).target).is_equal(peg)
	assert_int(ball.vx).is_greater(_sim.pegs[peg].vx)


func _board_with_moving_pegs() -> BoardSimulation:
	var sim: BoardSimulation = BoardSimulation.new(_config)
	TestBoards.add_moving_pegs(sim)
	return sim


func _aimed(aim: int) -> ShotInput:
	return ShotInput.new(aim, _away())


## Phase that keeps the frozen bucket far from the launcher, so falling balls are lost.
func _away() -> int:
	return TestBoards.bucket_right(_config)


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
