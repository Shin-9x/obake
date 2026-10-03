extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const DRUM: String = "res://data/omamori/drum.tres"


func test_wall_bounces_add_points() -> void:
	var game: BoardGame = Harness.board([], Harness.with_omamori(DRUM))
	Harness.shoot(game, 8500)
	Harness.finish(game)
	assert_int(game.shot_wall_bounces).is_greater(0)
	assert_int(game.shot_points).is_equal(5 * game.shot_wall_bounces)
