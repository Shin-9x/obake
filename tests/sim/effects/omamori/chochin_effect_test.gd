extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const CHOCHIN: String = "res://data/omamori/chochin.tres"


func test_blue_lanterns_give_extra_points() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(CHOCHIN))
	Harness.all_blue(game)
	game.roles[1] = BoardGame.Role.GREEN
	Harness.shoot(game)
	game.score_hit(0)
	assert_int(game.shot_points).is_equal(15)
	game.score_hit(1)
	assert_int(game.shot_points).is_equal(25)
