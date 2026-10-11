extends GdUnitTestSuite
## Style bonuses on a real board: the points join the shot and an event tells the screen.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const PX: int = FixedMath.PX


func test_a_long_shot_adds_its_points_to_the_shot_and_says_so() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	game.roles[3] = BoardGame.Role.RED
	Harness.shoot(game)
	var ball: int = game.simulation.launched_ball
	game.events.clear()
	game.touch(1, ball)
	assert_array(Harness.events_of(game, SimEvent.Kind.STYLE_BONUS)).is_empty()
	# Lanterns 1 and 3 of the row stand 160 px apart.
	game.touch(3, ball)
	var bonuses: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.STYLE_BONUS)
	assert_array(bonuses).has_size(1)
	assert_int(bonuses[0].target).is_equal(StyleShots.Style.LONG_SHOT)
	assert_int(bonuses[0].amount).is_equal(20)
	assert_int(bonuses[0].ball).is_equal(ball)
	# The blue lantern's 10 points and the bonus; the red one gave mult.
	assert_int(game.shot_points).is_equal(30)
	assert_int(game.shot_mult).is_equal(2000)


func test_a_super_long_shot_pays_more() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	game.roles[4] = BoardGame.Role.RED
	Harness.shoot(game)
	var ball: int = game.simulation.launched_ball
	game.touch(0, ball)
	game.events.clear()
	game.touch(4, ball)
	var bonuses: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.STYLE_BONUS)
	assert_int(bonuses[0].target).is_equal(StyleShots.Style.SUPER_LONG_SHOT)
	assert_int(game.shot_points).is_equal(60)


func test_a_lantern_already_lit_gives_no_long_shot() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	game.roles[4] = BoardGame.Role.RED
	Harness.shoot(game)
	var ball: int = game.simulation.launched_ball
	game.touch(4, ball)
	game.touch(0, ball)
	game.events.clear()
	game.touch(4, ball)
	assert_array(Harness.events_of(game, SimEvent.Kind.STYLE_BONUS)).is_empty()


func test_bricks_lit_in_a_row_are_a_slide() -> void:
	var settings: BalanceConfig = Harness.config()
	var simulation: BoardSimulation = BoardSimulation.new(settings)
	for brick: int in 6:
		simulation.add_rect_peg((60 + brick * 24) * PX, 200 * PX, 12 * PX, 3 * PX, 0)
	simulation.add_round_peg(340 * PX, 40 * PX)
	var rng: Pcg32 = Pcg32.new(Harness.SEED, RngStreams.Domain.BOARD)
	var game: BoardGame = BoardGame.new(simulation, settings, Harness.TestBoards.gdd_pegs(), rng)
	for peg: int in 6:
		game.roles[peg] = BoardGame.Role.BLUE
	game.roles[6] = BoardGame.Role.RED
	Harness.shoot(game)
	var ball: int = game.simulation.launched_ball
	game.events.clear()
	for peg: int in 3:
		game.touch(peg, ball)
	assert_array(Harness.events_of(game, SimEvent.Kind.STYLE_BONUS)).is_empty()
	game.touch(3, ball)
	var bonuses: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.STYLE_BONUS)
	assert_array(bonuses).has_size(1)
	assert_int(bonuses[0].target).is_equal(StyleShots.Style.SLIDE)
	# Four bricks at 10 points and the bonus.
	assert_int(game.shot_points).is_equal(60)
