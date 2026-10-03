extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const EMA: String = "res://data/omamori/ema.tres"


func test_a_matsuri_makes_blue_lanterns_worth_more_for_the_run() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(EMA))
	Harness.shoot(game)
	game.score_hit(Harness.ROW.size())
	Harness.finish(game)
	assert_int(game.outcome).is_equal(BoardGame.Outcome.MATSURI)
	assert_int(game.carry.role_bonus_points[BoardGame.Role.BLUE]).is_equal(2)
	var next_board: BoardGame = BoardGame.new(
		_row_board(),
		Harness.config(),
		Harness.TestBoards.gdd_pegs(),
		Pcg32.new(1, 0),
		null,
		game.carry
	)
	Harness.all_blue(next_board)
	Harness.shoot(next_board)
	next_board.score_hit(0)
	assert_int(next_board.shot_points).is_equal(12)


func test_other_outcomes_change_nothing() -> void:
	var settings: BalanceConfig = Harness.config()
	settings.shots_per_board = 1
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(EMA), settings)
	Harness.shoot(game)
	Harness.finish(game)
	assert_int(game.outcome).is_equal(BoardGame.Outcome.FAILED)
	assert_int(game.carry.role_bonus_points[BoardGame.Role.BLUE]).is_equal(0)


func _row_board() -> BoardSimulation:
	var simulation: BoardSimulation = BoardSimulation.new(Harness.config())
	for position: Vector2i in Harness.ROW:
		simulation.add_round_peg(position.x * 1000, position.y * 1000)
	simulation.add_round_peg(Harness.SPARE.x * 1000, Harness.SPARE.y * 1000)
	return simulation
