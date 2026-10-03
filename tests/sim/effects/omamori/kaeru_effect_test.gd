extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const KAERU: String = "res://data/omamori/kaeru.tres"


func test_bucket_catches_pay_mon() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(KAERU))
	Harness.shoot_into_bucket(game)
	Harness.finish(game)
	assert_bool(game.shot_caught).is_true()
	assert_int(game.mon_earned).is_equal(2)


func test_lost_balls_pay_nothing() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(KAERU))
	Harness.shoot(game)
	Harness.finish(game)
	assert_int(game.mon_earned).is_equal(0)
