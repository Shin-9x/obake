extends GdUnitTestSuite
## GDD income: win by board kind, unused shots, Matsuri bonus and capped interest.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_a_standard_win_pays_the_win_shots_and_interest() -> void:
	var result: BoardResult = _result(BoardGame.Outcome.TARGET_REACHED, 3, 2)
	var payout: Payout = Payout.settle(Fixtures.config(), result, MapNode.Kind.BOARD, 11)
	assert_int(payout.win).is_equal(4)
	assert_int(payout.unused_shots).is_equal(3)
	assert_int(payout.items).is_equal(2)
	# 11 held plus 2 earned on the board: two lots of five.
	assert_int(payout.interest).is_equal(2)
	assert_int(payout.matsuri).is_equal(0)
	assert_int(payout.total()).is_equal(11)


func test_matsuri_elite_and_boss_wins_pay_more() -> void:
	var config: BalanceConfig = Fixtures.config()
	var matsuri: BoardResult = _result(BoardGame.Outcome.MATSURI, 0, 0)
	assert_int(Payout.settle(config, matsuri, MapNode.Kind.BOARD, 0).matsuri).is_equal(5)
	assert_int(Payout.settle(config, matsuri, MapNode.Kind.ELITE, 0).win).is_equal(7)
	assert_int(Payout.settle(config, matsuri, MapNode.Kind.BOSS, 0).win).is_equal(10)


func test_interest_stops_at_the_cap_of_the_board() -> void:
	var config: BalanceConfig = Fixtures.config()
	var result: BoardResult = _result(BoardGame.Outcome.TARGET_REACHED, 0, 0)
	assert_int(Payout.settle(config, result, MapNode.Kind.BOARD, 60).interest).is_equal(5)
	result.interest_cap = 7
	assert_int(Payout.settle(config, result, MapNode.Kind.BOARD, 60).interest).is_equal(7)


func test_a_lost_board_pays_only_what_items_earned() -> void:
	var result: BoardResult = _result(BoardGame.Outcome.FAILED, 0, 3)
	var payout: Payout = Payout.settle(Fixtures.config(), result, MapNode.Kind.BOARD, 40)
	assert_int(payout.total()).is_equal(3)


func _result(outcome: BoardGame.Outcome, shots: int, earned: int) -> BoardResult:
	var result: BoardResult = BoardResult.new()
	result.outcome = outcome
	result.shots_left = shots
	result.mon_earned = earned
	result.interest_cap = 5
	return result
