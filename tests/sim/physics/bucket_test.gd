extends GdUnitTestSuite

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")

var _config: BalanceConfig
var _bucket: Bucket


func before_test() -> void:
	_config = TestBoards.gdd_config()
	_bucket = Bucket.new(_config)


func test_starts_centred_and_is_periodic() -> void:
	var period: int = _bucket.period()
	assert_int(_bucket.x_at(0)).is_equal(_config.board_width / 2)
	for phase: int in [1, 77, 239, 479]:
		assert_int(_bucket.x_at(phase + period)).is_equal(_bucket.x_at(phase))
		assert_int(_bucket.x_at(phase - 3 * period)).is_equal(_bucket.x_at(phase))


func test_swings_symmetrically_and_stays_inside_the_board() -> void:
	var period: int = _bucket.period()
	var centre: int = _config.board_width / 2
	var right: int = _bucket.x_at(period / 4)
	var left: int = _bucket.x_at(3 * period / 4)
	assert_int(right - centre).is_equal(centre - left)
	var margin: int = _bucket.half_width + _bucket.rim_radius
	for phase: int in period:
		var x: int = _bucket.x_at(phase)
		assert_int(x).is_between(margin, _config.board_width - margin)


func test_advance_wraps_the_phase() -> void:
	_bucket.set_phase(_bucket.period() - 1)
	_bucket.advance()
	assert_int(_bucket.phase).is_equal(0)
	assert_int(_bucket.x).is_equal(_bucket.x_at(0))


func test_catches_only_between_the_rims_below_their_line() -> void:
	var x: int = _bucket.x
	assert_bool(_bucket.catches(x, _bucket.y)).is_true()
	assert_bool(_bucket.catches(x + _bucket.half_width - 1, _bucket.y + 1000)).is_true()
	assert_bool(_bucket.catches(x, _bucket.y - 1)).is_false()
	assert_bool(_bucket.catches(x + _bucket.half_width, _bucket.y)).is_false()
