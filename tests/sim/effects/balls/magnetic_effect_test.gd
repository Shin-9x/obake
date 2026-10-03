extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const MAGNETIC: String = "res://data/balls/magnetic.tres"


func test_ball_is_set_to_pull_towards_red_lanterns() -> void:
	var definition: BallDefinition = load(MAGNETIC)
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_ball(MAGNETIC))
	Harness.shoot(game)
	assert_int(game.launched_ball().attraction_radius).is_equal(definition.level_values[0])
	assert_int(game.launched_ball().attraction_strength).is_equal(definition.params[&"strength"])


func test_red_lanterns_attract_the_ball() -> void:
	var game: BoardGame = Harness.board([Vector2i(195, 35)], Harness.with_ball(MAGNETIC))
	game.roles[0] = BoardGame.Role.RED
	game.simulation.pegs[0].attractor = true
	Harness.shoot(game)
	game.step()
	assert_int(game.launched_ball().vx).is_greater(0)
