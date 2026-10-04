extends GdUnitTestSuite

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const TestLayouts: GDScript = preload("res://tests/run/support/test_layouts.gd")
const PX: int = FixedMath.PX

var _config: BalanceConfig


func before_test() -> void:
	_config = TestBoards.gdd_config()


func test_sample_layout_is_clean() -> void:
	assert_array(LayoutChecks.find_problems(TestLayouts.sample(), _config)).is_empty()


func test_overlapping_pegs_are_reported() -> void:
	var layout: BoardLayout = TestLayouts.sample()
	layout.pegs.append(LayoutPeg.round_at(46 * PX, 62 * PX))
	_assert_problem(layout, "overlap")


func test_pegs_outside_the_board_or_in_the_bucket_lane_are_reported() -> void:
	var layout: BoardLayout = TestLayouts.sample()
	layout.pegs.append(LayoutPeg.round_at(2 * PX, 150 * PX))
	_assert_problem(layout, "leaves the board")
	layout = TestLayouts.sample()
	layout.pegs.append(LayoutPeg.round_at(180 * PX, 345 * PX))
	_assert_problem(layout, "bucket lane")


func test_thin_rectangles_are_reported() -> void:
	var layout: BoardLayout = TestLayouts.sample()
	layout.pegs.append(LayoutPeg.rect_at(250 * PX, 60 * PX, 10 * PX, 500, 0))
	_assert_problem(layout, "thinner")


func test_moving_pegs_that_sweep_into_a_static_peg_are_reported() -> void:
	var layout: BoardLayout = TestLayouts.sample()
	# On the ring's path: 30 px from its pivot, at the top.
	layout.pegs.append(LayoutPeg.round_at(200 * PX, 170 * PX))
	_assert_problem(layout, "overlap")


func test_crossing_rectangles_overlap() -> void:
	var a: SimPeg = SimPeg.create_rect(100 * PX, 100 * PX, 12 * PX, 2 * PX, 0)
	var b: SimPeg = SimPeg.create_rect(100 * PX, 100 * PX, 12 * PX, 2 * PX, 9000)
	var apart: SimPeg = SimPeg.create_rect(140 * PX, 100 * PX, 12 * PX, 2 * PX, 9000)
	assert_bool(LayoutChecks.overlap(a, b)).is_true()
	assert_bool(LayoutChecks.overlap(a, apart)).is_false()


func test_zones_outside_the_board_are_reported() -> void:
	var layout: BoardLayout = TestLayouts.sample()
	layout.zones.append(LayoutZone.new(20 * PX, 200 * PX, 30 * PX))
	_assert_problem(layout, "zone at (20, 200) leaves the board")


func _assert_problem(layout: BoardLayout, expected: String) -> void:
	var problems: Array[String] = LayoutChecks.find_problems(layout, _config)
	assert_str("\n".join(problems)).contains(expected)
