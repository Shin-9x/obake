extends GdUnitTestSuite
## A log replays the run it came from, and a save resumes it exactly, even halfway through a
## board.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const RunBot: GDScript = preload("res://tests/run/support/run_bot.gd")


func test_replaying_the_log_from_nothing_rebuilds_the_run() -> void:
	var config: BalanceConfig = _easy()
	var bot: RefCounted = RunBot.new(Fixtures.run("tanuki", config), 9)
	bot.play(2)
	var played: Run = bot.run
	var replayed: Run = RunReplay.replay(
		played.run_log, config, Fixtures.content(), LayoutLibrary.load_from(), Fixtures.base_pegs()
	)
	assert_object(replayed).is_not_null()
	assert_int(replayed.phase).is_equal(played.phase)
	assert_dict(RunCodec.encode(replayed.state)).is_equal(RunCodec.encode(played.state))
	assert_array(replayed.run_log.actions).is_equal(played.run_log.actions)


func test_a_save_resumes_halfway_through_a_board() -> void:
	var config: BalanceConfig = Fixtures.config()
	var played: Run = Fixtures.run("kitsune", config)
	var node: int = played.reachable_nodes()[0]
	played.choose_node(node)
	for aim: int in [1500, -2200]:
		played.shoot(aim, played.game.simulation.clock + 37)
		RunReplay.play_out(played.game)
	var resumed: Run = _resume(played, config)
	assert_object(resumed).is_not_null()
	assert_int(resumed.phase).is_equal(Run.Phase.BOARD)
	assert_int(resumed.game.simulation.state_hash()).is_equal(played.game.simulation.state_hash())
	assert_int(resumed.game.total).is_equal(played.game.total)
	assert_int(resumed.game.shots_left).is_equal(played.game.shots_left)
	for run: Run in [played, resumed]:
		run.shoot(700, run.game.simulation.clock)
		RunReplay.play_out(run.game)
	assert_int(resumed.game.total).is_equal(played.game.total)
	assert_array(resumed.run_log.actions).is_equal(played.run_log.actions)


func test_a_save_on_the_map_resumes_from_its_snapshot() -> void:
	var config: BalanceConfig = _easy()
	var bot: RefCounted = RunBot.new(Fixtures.run("yamabushi", config), 3)
	for action: int in 12:
		bot.act()
	while bot.run.phase != Run.Phase.MAP:
		bot.act()
	var played: Run = bot.run
	assert_int(played.snapshot_at).is_equal(played.run_log.size())
	var resumed: Run = _resume(played, config)
	assert_dict(RunCodec.encode(resumed.state)).is_equal(RunCodec.encode(played.state))
	assert_array(resumed.reachable_nodes()).is_equal(played.reachable_nodes())


func test_broken_saves_are_refused() -> void:
	var library: LayoutLibrary = LayoutLibrary.load_from()
	var content: RunContent = Fixtures.content()
	var config: BalanceConfig = Fixtures.config()
	assert_object(Run.resume({}, config, content, library, Fixtures.base_pegs())).is_null()
	var save: Dictionary = Fixtures.run().to_save()
	save["snapshot"] = "nothing"
	assert_object(Run.resume(save, config, content, library, Fixtures.base_pegs())).is_null()


func _resume(played: Run, config: BalanceConfig) -> Run:
	var save: Dictionary = JSON.parse_string(JSON.stringify(played.to_save()))
	return Run.resume(
		save, config, Fixtures.content(), LayoutLibrary.load_from(), Fixtures.base_pegs()
	)


func _easy() -> BalanceConfig:
	var config: BalanceConfig = Fixtures.config()
	config.first_board_target = 1
	config.target_rounding = 1
	return config
