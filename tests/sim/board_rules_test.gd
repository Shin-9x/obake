extends GdUnitTestSuite
## Board rules from the run, and the board-wide actions characters and bosses rely on.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const PX: int = FixedMath.PX


func test_rules_set_the_target_and_change_the_shots() -> void:
	var settings: BalanceConfig = Harness.config()
	var plain: BoardGame = Harness.board(Harness.ROW)
	assert_int(plain.target).is_equal(settings.first_board_target)
	assert_int(plain.shots_left).is_equal(settings.shots_per_board)
	var ruled: BoardGame = Harness.board(
		Harness.ROW, null, null, Harness.SEED, BoardRules.new(2500, -1)
	)
	assert_int(ruled.target).is_equal(2500)
	assert_int(ruled.shots_left).is_equal(settings.shots_per_board - 1)


func test_shots_never_drop_below_one() -> void:
	var game: BoardGame = Harness.board(
		Harness.ROW, null, null, Harness.SEED, BoardRules.new(0, -20)
	)
	assert_int(game.shots_left).is_equal(1)


func test_transform_turns_only_unlit_pegs_of_the_role() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(0)
	var coin: PegDefinition = load("res://data/pegs/coin_peg.tres")
	var turned: int = game.transform_random(BoardGame.Role.BLUE, 10, coin)
	# Five row pegs, one of them already lit; the spare red is not blue.
	assert_int(turned).is_equal(4)
	assert_int(game.roles[0]).is_equal(BoardGame.Role.BLUE)
	assert_int(game.roles[Harness.ROW.size()]).is_equal(BoardGame.Role.RED)
	for peg: int in range(1, Harness.ROW.size()):
		assert_int(game.roles[peg]).is_equal(BoardGame.Role.SPECIAL)
		assert_object(game.definition_of(peg)).is_same(coin)
	assert_array(Harness.events_of(game, SimEvent.Kind.PEG_TRANSFORMED)).has_size(4)


func test_transform_picks_the_same_pegs_for_the_same_seed() -> void:
	var picks: Array[PackedInt32Array] = []
	for attempt: int in 2:
		var game: BoardGame = Harness.board(Harness.ROW)
		Harness.all_blue(game)
		game.transform_random(BoardGame.Role.BLUE, 2, load("res://data/pegs/bell.tres"))
		var turned: PackedInt32Array = PackedInt32Array()
		for event: SimEvent in Harness.events_of(game, SimEvent.Kind.PEG_TRANSFORMED):
			turned.append(event.target)
		picks.append(turned)
	assert_int(picks[0].size()).is_equal(2)
	assert_array(picks[1]).is_equal(picks[0])


func test_the_mult_floor_holds_against_negative_mult() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	var draining: PegDefinition = PegDefinition.new()
	draining.mult_add = -1000
	game.place_special(0, draining)
	game.mult_floor = 1000
	Harness.shoot(game)
	game.add_mult(1000, 0, 0)
	game.score_hit(0)
	assert_int(game.shot_mult).is_equal(1000)
	game.add_mult(-3000, 0, 0)
	assert_int(game.shot_mult).is_equal(1000)


func test_multiplying_points_scales_the_shot_so_far() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(0)
	game.score_hit(1)
	game.score_hit(2)
	game.multiply_points(500, 0, 0)
	assert_int(game.shot_points).is_equal(15)
	assert_array(Harness.events_of(game, SimEvent.Kind.SCORE_POINTS_TIMES)).has_size(1)


func test_the_extended_guide_lasts_for_the_next_shots_and_stacks() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	assert_int(game.guide_contacts()).is_equal(1)
	Harness.shoot(game)
	game.extend_guide(2, 3)
	Harness.finish(game)
	for remaining: int in [2, 1]:
		assert_int(game.extended_guide_shots).is_equal(remaining)
		assert_int(game.guide_contacts()).is_equal(3)
		Harness.shoot(game)
		Harness.finish(game)
	assert_int(game.guide_contacts()).is_equal(1)
	game.extend_guide(2, 3)
	game.extend_guide(2, 3)
	assert_int(game.extended_guide_shots).is_equal(4)
