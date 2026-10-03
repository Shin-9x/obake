extends GdUnitTestSuite

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const SEED: int = 7


func test_placeholder_board_matches_the_gdd_lantern_mix() -> void:
	var game: BoardGame = _board(SEED)
	var pegs: int = game.simulation.pegs.size()
	assert_int(pegs).is_between(60, 70)
	var counts: Array[int] = [0, 0, 0, 0]
	for peg: int in pegs:
		counts[game.roles[peg]] += 1
	assert_int(counts[BoardGame.Role.RED]).is_equal(FixedMath.div_round(pegs * 220, 1000))
	assert_int(counts[BoardGame.Role.GREEN]).is_equal(2)
	assert_int(counts[BoardGame.Role.GOLD]).is_equal(1)


func test_placeholder_board_is_reproducible() -> void:
	var a: BoardGame = _board(SEED)
	var b: BoardGame = _board(SEED)
	assert_array(b.roles).is_equal(a.roles)
	assert_int(b.simulation.state_hash()).is_equal(a.simulation.state_hash())
	for peg: int in a.simulation.pegs.size():
		assert_int(b.simulation.pegs[peg].x).is_equal(a.simulation.pegs[peg].x)
		assert_int(b.simulation.pegs[peg].y).is_equal(a.simulation.pegs[peg].y)


func test_pegs_fit_inside_the_board_without_overlapping() -> void:
	var config: BalanceConfig = TestBoards.gdd_config()
	var pegs: Array[SimPeg] = _board(SEED).simulation.pegs
	for peg: SimPeg in pegs:
		assert_int(peg.min_x).is_greater_equal(0)
		assert_int(peg.max_x).is_less_equal(config.board_width)
		assert_int(peg.min_y).is_greater_equal(0)
		assert_int(peg.max_y).is_less(config.bucket_y)
	for a: int in pegs.size():
		for b: int in range(a + 1, pegs.size()):
			var overlap_x: bool = pegs[a].max_x > pegs[b].min_x and pegs[b].max_x > pegs[a].min_x
			var overlap_y: bool = pegs[a].max_y > pegs[b].min_y and pegs[b].max_y > pegs[a].min_y
			assert_bool(overlap_x and overlap_y).is_false()


func _board(board_seed: int) -> BoardGame:
	return BoardSetup.create_placeholder_board(
		TestBoards.gdd_config(), TestBoards.gdd_pegs(), board_seed
	)
