extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const SPLITTER: String = "res://data/balls/splitter.tres"
const PEGS: Array[Vector2i] = [Vector2i(181, 100), Vector2i(100, 250), Vector2i(260, 250)]


func test_first_impact_splits_the_ball() -> void:
	var definition: BallDefinition = load(SPLITTER)
	var game: BoardGame = Harness.board(PEGS, Harness.with_ball(SPLITTER, 2))
	Harness.shoot(game)
	while Harness.events_of(game, SimEvent.Kind.PEG_HIT).is_empty():
		game.step()
	var active: int = 0
	for ball: SimBall in game.simulation.balls:
		if ball.active:
			active += 1
	assert_int(active).is_equal(definition.level_values[1])


func test_only_the_first_impact_splits() -> void:
	var definition: BallDefinition = load(SPLITTER)
	var game: BoardGame = Harness.board(PEGS, Harness.with_ball(SPLITTER))
	Harness.shoot(game)
	Harness.finish(game)
	var splits: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.BALL_SPLIT)
	assert_array(splits).has_size(definition.level_values[0] - 1)
