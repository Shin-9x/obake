extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const SAKE: String = "res://data/omamori/shuten_sake.tres"


func test_doubles_the_final_mult_and_costs_shots() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(SAKE))
	assert_int(game.shots_left).is_equal(Harness.config().shots_per_board - 2)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(0)
	Harness.finish(game)
	assert_int(game.total).is_equal(20)


func test_never_leaves_fewer_than_one_shot() -> void:
	var settings: BalanceConfig = Harness.config()
	settings.shots_per_board = 2
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(SAKE), settings)
	assert_int(game.shots_left).is_equal(1)
