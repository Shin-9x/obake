extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const TERU: String = "res://data/omamori/teru_teru_bozu.tres"


func test_a_shot_without_reds_powers_the_next_one() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(TERU))
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(0)
	Harness.finish(game)
	Harness.shoot(game)
	assert_int(game.shot_mult).is_equal(4000)


func test_hitting_a_red_lantern_earns_nothing() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(TERU))
	Harness.all_blue(game)
	game.roles[0] = BoardGame.Role.RED
	Harness.shoot(game)
	game.score_hit(0)
	Harness.finish(game)
	Harness.shoot(game)
	assert_int(game.shot_mult).is_equal(1000)
