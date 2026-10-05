extends GdUnitTestSuite
## The balance bot plays real runs and records them as the game would, marked as its own.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_the_bot_plays_boards_and_records_them() -> void:
	var run: Run = Fixtures.run("kitsune")
	var record: RunRecord = RunRecord.new(1, "test", RunRecord.BOT)
	var bot: BalanceBot = BalanceBot.new(run, Fixtures.base_pegs(), 3, record, 5)
	bot.play(2)
	assert_int(run.state.boards_played).is_between(1, 2)
	assert_str(bot.lines[0]["kind"]).is_equal("board")
	assert_str(bot.lines[0]["source"]).is_equal(RunRecord.BOT)
	assert_str(bot.lines[0]["character"]).is_equal("kitsune")
	if run.is_over():
		assert_str(bot.lines[bot.lines.size() - 1]["kind"]).is_equal("run")


func test_the_chosen_aim_scores_on_the_real_board_what_its_copy_predicted() -> void:
	var run: Run = Fixtures.run()
	run.choose_node(run.reachable_nodes()[0])
	var bot: BalanceBot = BalanceBot.new(run, Fixtures.base_pegs(), 4, RunRecord.new(1, ""), 9)
	var aim: int = bot._best_aim()
	assert_int(aim).is_between(-run.config.aim_limit, run.config.aim_limit)
	assert_int(run.run_log.size()).is_equal(1)
	run.shoot(aim, run.game.simulation.clock)
	RunReplay.play_out(run.game)
	assert_int(run.game.total).is_equal(bot.predicted_total)
