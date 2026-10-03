extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const HYOTAN: String = "res://data/omamori/hyotan.tres"


func test_adds_a_shot_to_every_board() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(HYOTAN))
	assert_int(game.shots_left).is_equal(Harness.config().shots_per_board + 1)
