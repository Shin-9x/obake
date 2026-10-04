extends GdUnitTestSuite
## Board records that feats check: best shot by pegs, reds and mult, bucket catches and special
## balls, copied into the result when the board ends.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")


func test_the_best_shot_is_kept_by_pegs_reds_and_mult() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	game.roles[4] = BoardGame.Role.RED
	Harness.shoot(game)
	game.score_hit(0)
	game.score_hit(4)
	Harness.finish(game)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(1)
	game.score_hit(2)
	game.score_hit(3)
	Harness.finish(game)
	assert_int(game.best_shot_pegs).is_equal(3)
	assert_int(game.best_shot_reds).is_equal(1)
	assert_int(game.best_shot_mult).is_equal(2000)
	assert_int(game.best_shot).is_equal(30)


func test_special_balls_and_bucket_catches_are_counted() -> void:
	var loadout: LoadoutDefinition = Harness.loadout(
		[load("res://data/balls/hitodama.tres"), load("res://data/balls/heavy.tres")]
	)
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	for shot: int in 2:
		Harness.shoot_into_bucket(game)
		Harness.finish(game)
	assert_int(game.special_balls_fired).is_equal(1)
	assert_int(game.bucket_catches).is_equal(2)


func test_the_result_carries_the_records() -> void:
	var settings: BalanceConfig = Harness.config()
	settings.shots_per_board = 1
	settings.first_board_target = 10
	var game: BoardGame = Harness.board(Harness.ROW, null, settings)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(0)
	Harness.finish(game)
	var result: BoardResult = game.result
	assert_int(result.outcome).is_equal(BoardGame.Outcome.TARGET_REACHED)
	assert_int(result.best_shot_pegs).is_equal(1)
	assert_int(result.shots_fired).is_equal(1)
	assert_bool(result.won()).is_true()
	assert_bool(result.won_on_last_shot()).is_true()
