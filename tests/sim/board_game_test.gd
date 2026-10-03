extends GdUnitTestSuite

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const PX: int = FixedMath.PX
const STRAIGHT_DOWN: int = 0
const SEED: int = 4242


func test_colouring_follows_the_gdd_counts() -> void:
	var game: BoardGame = TestBoards.staggered_game(SEED)
	assert_int(game.roles.size()).is_equal(64)
	assert_int(_count(game, BoardGame.Role.RED)).is_equal(14)
	assert_int(_count(game, BoardGame.Role.GREEN)).is_equal(2)
	assert_int(_count(game, BoardGame.Role.GOLD)).is_equal(1)
	assert_int(game.red_remaining()).is_equal(14)


func test_colouring_depends_only_on_the_seed() -> void:
	var a: BoardGame = TestBoards.staggered_game(SEED)
	var b: BoardGame = TestBoards.staggered_game(SEED)
	var c: BoardGame = TestBoards.staggered_game(SEED + 1)
	assert_array(b.roles).is_equal(a.roles)
	assert_array(c.roles).is_not_equal(a.roles)


func test_each_lantern_scores_once_per_shot() -> void:
	var game: BoardGame = _two_peg_game(BoardGame.Role.BLUE, BoardGame.Role.RED)
	game.shoot(_shot())
	game.score_hit(0)
	game.score_hit(0)
	game.score_hit(1)
	game.score_hit(1)
	assert_int(game.shot_points).is_equal(10)
	assert_int(game.shot_mult).is_equal(2000)


func test_gold_doubles_the_mult_reached_so_far() -> void:
	var red_first: BoardGame = _two_peg_game(BoardGame.Role.RED, BoardGame.Role.GOLD)
	red_first.shoot(_shot())
	red_first.score_hit(0)
	red_first.score_hit(1)
	assert_int(red_first.shot_mult).is_equal(4000)
	var gold_first: BoardGame = _two_peg_game(BoardGame.Role.RED, BoardGame.Role.GOLD)
	gold_first.shoot(_shot())
	gold_first.score_hit(1)
	gold_first.score_hit(0)
	assert_int(gold_first.shot_mult).is_equal(3000)


func test_shot_scores_points_times_mult_and_resets_for_the_next_shot() -> void:
	var game: BoardGame = _two_peg_game(BoardGame.Role.BLUE, BoardGame.Role.RED)
	game.shoot(_shot())
	game.score_hit(0)
	game.score_hit(1)
	_finish_shot(game)
	assert_int(game.total).is_equal(20)
	assert_array(_scoring_amounts(game, SimEvent.Kind.SHOT_SCORED)).contains_exactly([20])
	game.shoot(_shot())
	assert_int(game.shot_points).is_equal(0)
	assert_int(game.shot_mult).is_equal(FixedMath.PERMILLE)


func test_scoring_events_carry_peg_and_amount() -> void:
	var game: BoardGame = _two_peg_game(BoardGame.Role.BLUE, BoardGame.Role.GOLD)
	game.shoot(_shot())
	game.score_hit(0)
	game.score_hit(1)
	assert_array(_scoring_amounts(game, SimEvent.Kind.SCORE_POINTS)).contains_exactly([10])
	assert_array(_scoring_amounts(game, SimEvent.Kind.SCORE_MULT_TIMES)).contains_exactly([2000])


func test_bucket_catch_makes_the_shot_free() -> void:
	var config: BalanceConfig = TestBoards.gdd_config()
	TestBoards.freeze_bucket(config)
	var game: BoardGame = _game_with_pegs(config, [Vector2i(20, 300)])
	var shots: int = game.shots_left
	TestBoards.play_shot(game, STRAIGHT_DOWN, 0)
	assert_array(_kinds(game)).contains([SimEvent.Kind.BUCKET_CATCH])
	assert_int(game.shots_left).is_equal(shots)


func test_matsuri_doubles_the_total_and_ends_the_board() -> void:
	var config: BalanceConfig = TestBoards.gdd_config()
	TestBoards.freeze_bucket(config)
	# Peg 0 sits in the ball's path; peg 1 is out of reach.
	var game: BoardGame = _game_with_pegs(config, [Vector2i(183, 100), Vector2i(20, 300)])
	game.roles[0] = BoardGame.Role.RED
	game.roles[1] = BoardGame.Role.BLUE
	game.shoot(_shot(TestBoards.bucket_right(config)))
	game.score_hit(1)
	_finish_shot(game)
	assert_int(game.outcome).is_equal(BoardGame.Outcome.MATSURI)
	assert_int(game.total).is_equal(40)
	assert_array(_scoring_amounts(game, SimEvent.Kind.BOARD_ENDED)).contains_exactly(
		[BoardGame.Outcome.MATSURI]
	)
	assert_bool(game.shoot(_shot())).is_false()


func test_reaching_the_target_wins_the_board() -> void:
	var config: BalanceConfig = TestBoards.gdd_config()
	config.first_board_target = 10
	var game: BoardGame = _game_with_pegs(config, [Vector2i(20, 300), Vector2i(340, 300)])
	game.roles[0] = BoardGame.Role.BLUE
	game.roles[1] = BoardGame.Role.RED
	game.shoot(_shot())
	game.score_hit(0)
	_finish_shot(game)
	assert_int(game.outcome).is_equal(BoardGame.Outcome.TARGET_REACHED)


func test_running_out_of_shots_fails_the_board() -> void:
	var config: BalanceConfig = TestBoards.gdd_config()
	TestBoards.freeze_bucket(config)
	config.shots_per_board = 1
	var game: BoardGame = _game_with_pegs(config, [Vector2i(20, 300), Vector2i(340, 300)])
	game.roles[1] = BoardGame.Role.RED
	TestBoards.play_shot(game, STRAIGHT_DOWN, TestBoards.bucket_right(config))
	assert_int(game.shots_left).is_equal(0)
	assert_int(game.outcome).is_equal(BoardGame.Outcome.FAILED)


func test_gold_moves_every_shot_and_stays_unique() -> void:
	var game: BoardGame = TestBoards.staggered_game(SEED)
	var golds: Array[int] = [_gold_peg(game)]
	for aim: int in [-2500, 1234, 4321]:
		TestBoards.play_shot(game, aim)
		assert_int(_count(game, BoardGame.Role.GOLD)).is_equal(1)
		golds.append(_gold_peg(game))
	for index: int in range(1, golds.size()):
		assert_int(golds[index]).is_not_equal(golds[index - 1])
	var replay: BoardGame = TestBoards.staggered_game(SEED)
	for aim: int in [-2500, 1234, 4321]:
		TestBoards.play_shot(replay, aim)
	assert_int(_gold_peg(replay)).is_equal(golds.back())


func _shot(board_clock: int = 0) -> ShotInput:
	return ShotInput.new(STRAIGHT_DOWN, board_clock)


## Two pegs far from the ball's straight drop, with explicit roles, plus a red lantern out of
## every path so that hitting both never ends the board by Matsuri.
func _two_peg_game(first: BoardGame.Role, second: BoardGame.Role) -> BoardGame:
	var config: BalanceConfig = TestBoards.gdd_config()
	var game: BoardGame = _game_with_pegs(
		config, [Vector2i(20, 300), Vector2i(340, 300), Vector2i(340, 40)]
	)
	game.roles[0] = first
	game.roles[1] = second
	game.roles[2] = BoardGame.Role.RED
	return game


## Builds a game whose round pegs sit at [param positions], given in pixels.
func _game_with_pegs(config: BalanceConfig, positions: Array[Vector2i]) -> BoardGame:
	var sim: BoardSimulation = BoardSimulation.new(config)
	for position: Vector2i in positions:
		sim.add_round_peg(position.x * PX, position.y * PX)
	return BoardGame.new(sim, config, TestBoards.gdd_pegs(), Pcg32.new(SEED, 0))


func _finish_shot(game: BoardGame) -> void:
	for i: int in TestBoards.MAX_SHOT_TICKS:
		if not game.simulation.is_shot_active():
			return
		game.step()


## Pegs still on the board with [param role].
func _count(game: BoardGame, role: BoardGame.Role) -> int:
	var count: int = 0
	for peg: int in game.roles.size():
		if game.roles[peg] == role and not game.simulation.pegs[peg].removed:
			count += 1
	return count


func _gold_peg(game: BoardGame) -> int:
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.GOLD and not game.simulation.pegs[peg].removed:
			return peg
	return -1


func _kinds(game: BoardGame) -> Array[int]:
	var kinds: Array[int] = []
	for index: int in game.events.size():
		kinds.append(game.events.at(index).kind)
	return kinds


func _scoring_amounts(game: BoardGame, kind: SimEvent.Kind) -> Array[int]:
	var amounts: Array[int] = []
	for index: int in game.events.size():
		var event: SimEvent = game.events.at(index)
		if event.kind == kind:
			amounts.append(event.amount)
	return amounts


func test_reds_are_shared_between_zones_in_proportion() -> void:
	# A uniform 9 x 9 grid puts 9 pegs in each of the 3 x 3 zones; 22% of 81 is 18 reds, 2 each.
	var config: BalanceConfig = TestBoards.gdd_config()
	var positions: Array[Vector2i] = []
	for row: int in 9:
		for column: int in 9:
			positions.append(Vector2i(20 + column * 40, 20 + row * 40))
	var game: BoardGame = _game_with_pegs(config, positions)
	var per_zone: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.RED:
			var position: Vector2i = positions[peg]
			per_zone[(position.y / 120) * 3 + position.x / 120] += 1
	assert_array(per_zone).is_equal([2, 2, 2, 2, 2, 2, 2, 2, 2])


func test_leftover_reds_go_to_the_largest_remainders() -> void:
	# 10 pegs in the top-left zone and 1 in the centre: 22% of 11 is 2 reds, both top-left.
	var config: BalanceConfig = TestBoards.gdd_config()
	var positions: Array[Vector2i] = [Vector2i(180, 180)]
	for index: int in 10:
		positions.append(Vector2i(10 + index * 10, 60))
	var game: BoardGame = _game_with_pegs(config, positions)
	assert_int(game.roles[0]).is_not_equal(BoardGame.Role.RED)
	assert_int(_count(game, BoardGame.Role.RED)).is_equal(2)
