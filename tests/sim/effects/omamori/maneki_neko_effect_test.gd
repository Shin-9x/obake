extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const MANEKI: String = "res://data/omamori/maneki_neko.tres"


func test_raises_the_interest_cap() -> void:
	var settings: BalanceConfig = Harness.config()
	settings.shots_per_board = 1
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(MANEKI), settings)
	Harness.shoot(game)
	Harness.finish(game)
	assert_int(game.result.interest_cap).is_equal(settings.interest_cap + 2)
