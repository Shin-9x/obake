extends GdUnitTestSuite
## Hard mode raises targets and takes a shot from every board; chosen seeds count for nothing.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const PROGRESSION: String = "res://data/progression.tres"


func test_hard_targets_are_a_quarter_higher() -> void:
	var config: BalanceConfig = Fixtures.config()
	config.first_board_target = 800
	config.board_target_growth = 1350
	config.hard_target_factor = 1250
	var boss: BossDefinition = BossDefinition.new()
	boss.target_factor = 1800
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOARD, 0, true)).is_equal(1000)
	# 1080 x 1.25 = 1350.
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOARD, 1, true)).is_equal(1350)
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOSS, 0, true, boss)).is_equal(1800)


func test_a_hard_run_plays_harder_boards() -> void:
	var options: RunOptions = RunOptions.new()
	options.hard = true
	var run: Run = _run(options)
	assert_int(run.state.shot_delta).is_equal(-1)
	run.choose_node(run.reachable_nodes()[0])
	assert_int(run.board.rules.target).is_equal(1000)
	assert_int(run.game.shots_left).is_equal(run.config.shots_per_board - 1)


func test_winning_on_hard_earns_the_hard_mark() -> void:
	var options: RunOptions = RunOptions.new()
	options.hard = true
	var run: Run = _run(options)
	run.phase = Run.Phase.VICTORY
	var marks: Array[Profile.Mark] = Progression.finish_run(load(PROGRESSION), Profile.new(), run)
	assert_array(marks).is_equal([Profile.Mark.SHUTEN, Profile.Mark.HARD])


func test_a_chosen_seed_earns_no_feat_and_no_mark() -> void:
	var options: RunOptions = RunOptions.new()
	options.custom_seed = true
	var run: Run = _run(options)
	run.choose_node(run.reachable_nodes()[0])
	var result: BoardResult = BoardResult.new()
	result.outcome = BoardGame.Outcome.MATSURI
	result.best_shot_pegs = 40
	run.game.outcome = result.outcome
	run.game.result = result
	run.finish_board()
	var profile: Profile = Profile.new()
	var definition: ProgressionDefinition = load(PROGRESSION)
	assert_array(Progression.check_board(definition, profile, run)).is_empty()
	assert_bool(profile.discovered.has(&"hitodama")).is_true()
	run.phase = Run.Phase.VICTORY
	assert_array(Progression.finish_run(definition, profile, run)).is_empty()
	assert_int(profile.runs).is_equal(1)
	assert_int(profile.wins_by_character[&"yamabushi"]).is_equal(1)


func test_options_are_saved_with_the_run() -> void:
	var options: RunOptions = RunOptions.new()
	options.hard = true
	options.custom_seed = true
	var save: Dictionary = JSON.parse_string(JSON.stringify(_run(options).to_save()))
	var resumed: Run = Run.resume(
		save, Fixtures.config(), Fixtures.content(), LayoutLibrary.load_from(), Fixtures.base_pegs()
	)
	assert_bool(resumed.run_log.options.hard).is_true()
	assert_bool(resumed.run_log.options.custom_seed).is_true()
	assert_int(resumed.state.shot_delta).is_equal(-1)


func _run(options: RunOptions) -> Run:
	return Run.start(
		Fixtures.config(),
		Fixtures.content(),
		LayoutLibrary.load_from(),
		Fixtures.base_pegs(),
		Fixtures.character(),
		Fixtures.SEED,
		options
	)
