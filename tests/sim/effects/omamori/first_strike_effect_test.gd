extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const FIRST_STRIKE: String = "res://data/omamori/first_strike.tres"


func test_only_the_first_peg_of_a_shot_is_multiplied() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(FIRST_STRIKE))
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(0)
	assert_int(game.shot_points).is_equal(50)
	game.score_hit(1)
	assert_int(game.shot_points).is_equal(60)
	Harness.finish(game)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(2)
	assert_int(game.shot_points).is_equal(50)
