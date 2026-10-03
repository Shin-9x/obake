extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const YATA: String = "res://data/omamori/yata_mirror.tres"


func test_gold_lanterns_triple_the_mult() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(YATA))
	Harness.all_blue(game)
	game.roles[0] = BoardGame.Role.GOLD
	Harness.shoot(game)
	game.add_mult(1000, 0, 0)
	game.score_hit(0)
	assert_int(game.shot_mult).is_equal(6000)
	game.score_hit(1)
	assert_int(game.shot_mult).is_equal(6000)
