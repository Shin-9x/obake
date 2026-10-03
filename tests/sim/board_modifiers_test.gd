extends GdUnitTestSuite
## Generic ball and peg modifiers that item effects set.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const PX: int = FixedMath.PX

var _config: BalanceConfig
var _sim: BoardSimulation


func before_test() -> void:
	_config = TestBoards.gdd_config()
	TestBoards.freeze_bucket(_config)
	_sim = BoardSimulation.new(_config)


func test_ghost_ball_passes_through_and_still_hits() -> void:
	var peg: int = _sim.add_round_peg(_config.launcher_x, 100 * PX)
	_launch()
	_sim.balls[0].ghost_hits = 1
	var hits: int = 0
	while _sim.is_shot_active():
		_sim.step()
	for index: int in _sim.events.size():
		if _sim.events.at(index).kind == SimEvent.Kind.PEG_HIT:
			hits += 1
	assert_int(hits).is_equal(1)
	assert_bool(_sim.pegs[peg].removed).is_true()
	assert_int(_sim.balls[0].x).is_equal(_config.launcher_x)


func test_attraction_pulls_towards_attractor_pegs_in_range() -> void:
	var magnet: int = _sim.add_round_peg(_config.launcher_x + 15 * PX, 40 * PX)
	_sim.pegs[magnet].attractor = true
	_launch()
	_sim.balls[0].attraction_radius = 50 * PX
	_sim.balls[0].attraction_strength = 400 * PX
	_sim.step()
	assert_int(_sim.balls[0].vx).is_greater(0)
	_sim.pegs[magnet].attractor = false
	var before: int = _sim.balls[0].vx
	_sim.step()
	assert_int(_sim.balls[0].vx).is_equal(before)


func test_floor_bounce_saves_the_ball_once() -> void:
	_launch()
	_sim.balls[0].floor_bounces = 1
	var bounced: bool = false
	while _sim.is_shot_active():
		_sim.step()
	for index: int in _sim.events.size():
		bounced = bounced or _sim.events.at(index).kind == SimEvent.Kind.FLOOR_BOUNCE
	assert_bool(bounced).is_true()
	assert_int(_sim.balls[0].floor_bounces).is_equal(0)


func test_ball_restitution_overrides_the_board_and_peg_restitution_overrides_the_ball() -> void:
	var soft: Array[int] = _bounce_speeds(500, -1)
	assert_int(soft[1]).is_between(-soft[0] * 500 / 1000 - 3, -soft[0] * 500 / 1000 + 3)
	var springy: Array[int] = _bounce_speeds(500, 1300)
	assert_int(springy[1]).is_between(-springy[0] * 1300 / 1000 - 3, -springy[0] * 1300 / 1000 + 3)


func test_persistent_pegs_go_dark_instead_of_leaving() -> void:
	var peg: int = _sim.add_round_peg(_config.launcher_x + 3 * PX, 100 * PX)
	_sim.pegs[peg].persistent = true
	_launch()
	while _sim.is_shot_active():
		_sim.step()
	assert_bool(_sim.pegs[peg].removed).is_false()
	assert_bool(_sim.pegs[peg].lit).is_false()


func test_pegs_within_measures_to_the_peg_surface() -> void:
	var near: int = _sim.add_round_peg(100 * PX, 100 * PX)
	var edge: int = _sim.add_round_peg(120 * PX, 100 * PX)
	_sim.add_round_peg(140 * PX, 100 * PX)
	var found: PackedInt32Array = PackedInt32Array()
	found.resize(_sim.pegs.size())
	var count: int = _sim.pegs_within(100 * PX, 100 * PX, 15 * PX, found)
	assert_int(count).is_equal(2)
	assert_array(Array(found.slice(0, count))).contains_exactly_in_any_order([near, edge])


func test_bucket_width_can_change() -> void:
	_sim.bucket.set_width(60 * PX)
	assert_int(_sim.bucket.half_width).is_equal(30 * PX)
	assert_bool(_sim.bucket.catches(_sim.bucket.x + 25 * PX, _sim.bucket.y)).is_true()


func _launch() -> void:
	_sim.launch(ShotInput.new(0, TestBoards.bucket_right(_config)))


## Vertical speed just before and just after the first bounce off a peg dead below.
func _bounce_speeds(ball_restitution: int, peg_restitution: int) -> Array[int]:
	var sim: BoardSimulation = BoardSimulation.new(_config)
	var peg: int = sim.add_round_peg(_config.launcher_x, 100 * PX)
	sim.pegs[peg].restitution = peg_restitution
	sim.launch(ShotInput.new(0, TestBoards.bucket_right(_config)))
	sim.balls[0].restitution = ball_restitution
	var before: int = 0
	while sim.events.size() == 0:
		before = (
			sim.balls[0].vy + FixedMath.div_round(_config.gravity, BoardSimulation.TICKS_PER_SECOND)
		)
		sim.step()
	return [before, sim.balls[0].vy]
