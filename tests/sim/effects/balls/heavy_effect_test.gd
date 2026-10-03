extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const HEAVY: String = "res://data/balls/heavy.tres"


func test_hit_pegs_score_multiplied_points_by_level() -> void:
	var definition: BallDefinition = load(HEAVY)
	for level: int in [1, 2, 3]:
		var game: BoardGame = Harness.board(Harness.ROW, Harness.with_ball(HEAVY, level))
		Harness.all_blue(game)
		Harness.shoot(game)
		game.score_hit(0)
		assert_int(game.shot_points).is_equal(10 * definition.level_values[level - 1] / 1000)


func test_ball_bounces_softly() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_ball(HEAVY))
	Harness.shoot(game)
	var definition: BallDefinition = load(HEAVY)
	assert_int(game.launched_ball().restitution).is_equal(definition.params[&"restitution"])
