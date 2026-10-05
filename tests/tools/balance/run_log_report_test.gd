extends GdUnitTestSuite
## The balance report's sums: runs by outcome, floor and character, and boards by their place in
## the run, with Normal and Hard kept apart.


func test_runs_are_counted_by_outcome_floor_and_character() -> void:
	var report: RunLogReport = RunLogReport.new()
	report.add(_run("victory", 4, "kitsune"))
	report.add(_run("defeat", 2, "kitsune"))
	report.add(_run("abandoned", 2, "tanuki"))
	report.add(_run("defeat", 1, "tanuki", true))
	var normal: RunLogReport.ModeStats = report.mode(false)
	assert_int(normal.runs).is_equal(3)
	assert_int(normal.outcomes["victory"]).is_equal(1)
	assert_int(normal.losses_by_floor[2]).is_equal(2)
	assert_bool(normal.losses_by_floor.has(4)).is_false()
	assert_int(normal.runs_by_character["kitsune"]).is_equal(2)
	assert_int(normal.wins_by_character["kitsune"]).is_equal(1)
	assert_bool(normal.wins_by_character.has("tanuki")).is_false()
	assert_int(report.mode(true).runs).is_equal(1)


func test_boards_are_summed_by_their_place_in_the_run() -> void:
	var report: RunLogReport = RunLogReport.new()
	report.add(_board(1, "target", 900, 800, 3, 10))
	report.add(_board(1, "matsuri", 1600, 800, 5, 20))
	report.add(_board(1, "failed", 400, 800, 0, 4))
	report.add(_board(2, "target", 1100, 1000, 1, 12))
	var first: RunLogReport.BoardStats = report.mode(false).boards[1]
	assert_int(first.reached).is_equal(3)
	assert_int(first.won).is_equal(2)
	assert_int(first.matsuri).is_equal(1)
	assert_int(first.shots_left_when_won).is_equal(8)
	assert_int(first.mon).is_equal(34)
	assert_float(first.median_ratio()).is_equal_approx(1.125, 0.001)
	assert_float(report.mode(false).boards[2].median_ratio()).is_equal_approx(1.1, 0.001)
	var first_floor: Dictionary = report.mode(false).nodes[1]
	assert_int((first_floor["board"] as RunLogReport.BoardStats).reached).is_equal(4)


func test_the_text_shows_each_mode_and_board() -> void:
	var report: RunLogReport = RunLogReport.new()
	report.add(_run("victory", 4, "yamabushi"))
	report.add(_board(1, "target", 900, 800, 3, 10))
	report.add(_board(1, "failed", 100, 800, 0, 4, true))
	var text: String = report.text()
	assert_str(text).contains("Normal: 1 runs, 1 won (100%)")
	assert_str(text).contains("Hard: 0 runs")
	assert_str(text).contains("yamabushi 1/1")
	assert_bool(text.find("Normal") < text.find("Hard")).is_true()


func test_unknown_lines_are_ignored() -> void:
	var report: RunLogReport = RunLogReport.new()
	report.add({"kind": "settings"})
	assert_int(report.mode(false).runs).is_equal(0)
	assert_bool(report.mode(false).boards.is_empty()).is_true()


func _run(outcome: String, floor_number: int, character: String, hard: bool = false) -> Dictionary:
	return {
		"kind": "run",
		"outcome": outcome,
		"floor": floor_number,
		"character": character,
		"hard": hard,
	}


func _board(
	index: int,
	outcome: String,
	score: int,
	target: int,
	shots_left: int,
	mon: int,
	hard: bool = false
) -> Dictionary:
	return {
		"kind": "board",
		"board": index,
		"floor": 1,
		"node": "board",
		"outcome": outcome,
		"score": score,
		"target": target,
		"shots_left": shots_left,
		"mon": mon,
		"hard": hard,
	}
