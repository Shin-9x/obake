extends GdUnitTestSuite
## Run log lines for balancing: what a settled board and the end of a run record.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const VERSION: String = "9.9.9"


func test_a_won_board_records_its_score_shots_and_loadout() -> void:
	var run: Run = _on_first_board()
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED, 3)
	var line: Dictionary[String, Variant] = RunRecord.new(4, VERSION).board(run)
	assert_str(line["kind"]).is_equal("board")
	assert_str(line["version"]).is_equal(VERSION)
	assert_str(line["source"]).is_equal(RunRecord.PLAYER)
	assert_int(line["run"]).is_equal(4)
	assert_str(line["seed"]).is_equal("%x" % Fixtures.SEED)
	assert_str(line["character"]).is_equal("yamabushi")
	assert_bool(line["hard"]).is_false()
	assert_int(line["floor"]).is_equal(1)
	assert_int(line["step"]).is_equal(1)
	assert_str(line["node"]).is_equal("board")
	assert_int(line["board"]).is_equal(1)
	assert_str(line["layout"]).is_equal(run.board.layout.id)
	assert_str(line["boss"]).is_empty()
	assert_int(line["target"]).is_equal(run.game.target)
	assert_str(line["outcome"]).is_equal("target")
	assert_int(line["shots_left"]).is_equal(3)
	assert_int(line["payout"]).is_equal(run.payout.total())
	assert_int(line["mon"]).is_equal(run.state.mon)
	var balls: Array = line["balls"]
	assert_int(balls.size()).is_equal(run.state.inventory.ball_count())
	assert_array(line["ball_levels"]).has_size(balls.size())


func test_board_outcomes_are_named() -> void:
	var run: Run = _on_first_board()
	Fixtures.finish(run, BoardGame.Outcome.MATSURI)
	assert_str(RunRecord.new(1, VERSION).board(run)["outcome"]).is_equal("matsuri")
	run = _on_first_board()
	Fixtures.finish(run, BoardGame.Outcome.FAILED)
	assert_str(RunRecord.new(1, VERSION).board(run)["outcome"]).is_equal("failed")


func test_a_lost_run_records_its_progress_and_its_log() -> void:
	var run: Run = _on_first_board()
	Fixtures.finish(run, BoardGame.Outcome.FAILED)
	var line: Dictionary[String, Variant] = RunRecord.new(2, VERSION, RunRecord.BOT).ending(run)
	assert_str(line["kind"]).is_equal("run")
	assert_str(line["source"]).is_equal(RunRecord.BOT)
	assert_str(line["outcome"]).is_equal("defeat")
	assert_int(line["floor"]).is_equal(1)
	assert_int(line["boards_played"]).is_equal(1)
	assert_int(line["boards_won"]).is_equal(0)
	var log: RunLog = RunLog.from_dictionary(line["log"])
	assert_object(log).is_not_null()
	assert_int(log.size()).is_equal(run.run_log.size())


func test_an_abandoned_run_and_a_won_one_are_told_apart() -> void:
	var run: Run = _on_first_board()
	run.abandon()
	assert_str(RunRecord.new(1, VERSION).ending(run)["outcome"]).is_equal("abandoned")
	run = _on_first_board()
	run.phase = Run.Phase.VICTORY
	assert_str(RunRecord.new(1, VERSION).ending(run)["outcome"]).is_equal("victory")


func test_lines_survive_json() -> void:
	var run: Run = _on_first_board()
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED)
	var line: Dictionary[String, Variant] = RunRecord.new(1, VERSION).board(run)
	var parsed: Variant = JSON.parse_string(JSON.stringify(line))
	assert_dict(parsed).contains_keys(line.keys())


func _on_first_board() -> Run:
	var run: Run = Fixtures.run()
	run.choose_node(run.reachable_nodes()[0])
	assert_int(run.phase).is_equal(Run.Phase.BOARD)
	return run
