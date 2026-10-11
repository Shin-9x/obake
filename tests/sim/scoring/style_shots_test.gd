extends GdUnitTestSuite
## Long shots and slides, ball by ball, on the GDD numbers: long from 120 px, super long from
## 200 px, a slide at 5 rectangular pegs in a row and an extreme slide at 10.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const PX: int = FixedMath.PX


func test_a_red_lantern_lit_far_from_the_last_touch_is_a_long_shot() -> void:
	var style: StyleShots = _style()
	assert_int(style.long_shot(0, 40 * PX, 200 * PX, false)).is_equal(StyleShots.Style.NONE)
	assert_int(style.long_shot(0, 160 * PX, 200 * PX, true)).is_equal(StyleShots.Style.LONG_SHOT)
	assert_int(style.long_shot(0, 160 * PX, 0, true)).is_equal(StyleShots.Style.SUPER_LONG_SHOT)
	assert_int(style.long_shot(0, 160 * PX, 119 * PX, true)).is_equal(StyleShots.Style.NONE)


func test_the_distance_is_measured_in_a_straight_line() -> void:
	var style: StyleShots = _style()
	style.long_shot(0, 0, 0, false)
	# 90 px across and 80 px down are just over 120 px apart.
	assert_int(style.long_shot(0, 90 * PX, 80 * PX, true)).is_equal(StyleShots.Style.LONG_SHOT)
	style.long_shot(0, 0, 0, false)
	assert_int(style.long_shot(0, 84 * PX, 84 * PX, true)).is_equal(StyleShots.Style.NONE)


func test_only_a_red_lantern_lit_by_the_touch_counts() -> void:
	var style: StyleShots = _style()
	style.long_shot(0, 0, 0, false)
	assert_int(style.long_shot(0, 300 * PX, 0, false)).is_equal(StyleShots.Style.NONE)
	# The touch still moved the starting point.
	assert_int(style.long_shot(0, 310 * PX, 0, true)).is_equal(StyleShots.Style.NONE)


func test_the_flight_from_the_launcher_does_not_count() -> void:
	var style: StyleShots = _style()
	assert_int(style.long_shot(0, 180 * PX, 340 * PX, true)).is_equal(StyleShots.Style.NONE)


func test_every_ball_and_every_shot_starts_afresh() -> void:
	var style: StyleShots = _style()
	style.long_shot(0, 0, 0, false)
	assert_int(style.long_shot(3, 300 * PX, 0, true)).is_equal(StyleShots.Style.NONE)
	style.start_shot()
	assert_int(style.long_shot(0, 300 * PX, 0, true)).is_equal(StyleShots.Style.NONE)


func test_five_bricks_lit_in_a_row_are_a_slide_and_ten_an_extreme_one() -> void:
	var style: StyleShots = _style()
	var styles: Array[int] = []
	for brick: int in 10:
		styles.append(style.slide(0, true, true, brick * 10))
	assert_int(styles[3]).is_equal(StyleShots.Style.NONE)
	assert_int(styles[4]).is_equal(StyleShots.Style.SLIDE)
	assert_int(styles[8]).is_equal(StyleShots.Style.NONE)
	assert_int(styles[9]).is_equal(StyleShots.Style.EXTREME_SLIDE)
	assert_int(style.slide(0, true, true, 100)).is_equal(StyleShots.Style.NONE)


func test_touching_a_lit_brick_again_keeps_the_slide_going() -> void:
	var style: StyleShots = _style()
	for brick: int in 4:
		style.slide(0, true, true, brick * 10)
	assert_int(style.slide(0, true, false, 45)).is_equal(StyleShots.Style.NONE)
	assert_int(style.slide(0, true, true, 70)).is_equal(StyleShots.Style.SLIDE)


func test_a_round_peg_or_a_long_pause_breaks_the_slide() -> void:
	var style: StyleShots = _style()
	for brick: int in 4:
		style.slide(0, true, true, brick * 10)
	style.slide(0, false, true, 35)
	assert_int(style.slide(0, true, true, 40)).is_equal(StyleShots.Style.NONE)
	style.start_shot()
	for brick: int in 4:
		style.slide(1, true, true, brick * 10)
	# 31 ticks after the fourth brick.
	assert_int(style.slide(1, true, true, 61)).is_equal(StyleShots.Style.NONE)


func test_each_style_has_its_points() -> void:
	var style: StyleShots = _style()
	assert_int(style.points_of(StyleShots.Style.NONE)).is_equal(0)
	assert_int(style.points_of(StyleShots.Style.LONG_SHOT)).is_equal(20)
	assert_int(style.points_of(StyleShots.Style.SUPER_LONG_SHOT)).is_equal(50)
	assert_int(style.points_of(StyleShots.Style.SLIDE)).is_equal(20)
	assert_int(style.points_of(StyleShots.Style.EXTREME_SLIDE)).is_equal(50)


func _style() -> StyleShots:
	return StyleShots.new(TestBoards.gdd_config())
