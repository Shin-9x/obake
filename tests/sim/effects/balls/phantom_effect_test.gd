extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const PHANTOM: String = "res://data/balls/phantom.tres"
const COLUMN: Array[Vector2i] = [
	Vector2i(181, 60),
	Vector2i(181, 100),
	Vector2i(181, 140),
	Vector2i(181, 180),
	Vector2i(181, 220)
]


func test_passes_through_its_first_pegs() -> void:
	var definition: BallDefinition = load(PHANTOM)
	var passes: int = definition.level_values[0]
	var game: BoardGame = Harness.board(COLUMN, Harness.with_ball(PHANTOM))
	Harness.shoot(game)
	Harness.finish(game)
	var ball: SimBall = game.simulation.balls[game.simulation.launched_ball]
	assert_int(ball.ghost_count).is_equal(passes)
	for peg: int in passes:
		assert_bool(ball.has_ghosted(peg)).is_true()
		assert_bool(game.simulation.pegs[peg].removed).is_true()
