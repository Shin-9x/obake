extends GdUnitTestSuite
## Order, staging and actions of the effect pipeline, with probe effects.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const Probe: GDScript = preload("res://tests/sim/support/probe_effect.gd")
const PX: int = FixedMath.PX


func before_test() -> void:
	Probe.journal.clear()


func test_hooks_run_for_the_ball_then_the_peg_then_omamori_by_slot() -> void:
	var loadout: LoadoutDefinition = Harness.loadout(
		[Harness.probe_ball()], [Harness.probe_omamori(), Harness.probe_omamori()]
	)
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	game.place_special(0, Harness.probe_peg())
	assert_array(Probe.journal).is_equal(["-1:board_start", "0:board_start", "1:board_start"])
	Probe.journal.clear()
	Harness.shoot(game)
	game.score_hit(0)
	assert_array(Probe.journal).is_equal(
		[
			"-1:shot_start",
			"0:shot_start",
			"1:shot_start",
			"-1:peg_hit",
			"-2:peg_hit",
			"0:peg_hit",
			"1:peg_hit"
		]
	)


func test_additions_come_before_multiplications_whatever_the_slot_order() -> void:
	var doubler: OmamoriDefinition = Harness.probe_omamori({&"points_factor": 2000})
	var adder: OmamoriDefinition = Harness.probe_omamori({&"bonus_points": 5})
	for order: Array in [[doubler, adder], [adder, doubler]]:
		var game: BoardGame = Harness.board(Harness.ROW, Harness.loadout([], order))
		Harness.all_blue(game)
		Harness.shoot(game)
		game.score_hit(0)
		assert_int(game.shot_points).is_equal(30)


func test_final_mult_factor_applies_after_end_of_shot_additions() -> void:
	var doubler: OmamoriDefinition = Harness.probe_omamori({&"final_factor": 2000})
	var adder: OmamoriDefinition = Harness.probe_omamori({&"mult_add": 3000})
	for order: Array in [[doubler, adder], [adder, doubler]]:
		var game: BoardGame = Harness.board(Harness.ROW, Harness.loadout([], order))
		Harness.all_blue(game)
		Harness.shoot(game)
		game.score_hit(0)
		Harness.finish(game)
		# (10 points) x ((1 + 3) x 2) mult.
		assert_int(game.total).is_equal(80)


func test_an_explosion_waits_for_the_hit_that_caused_it() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	game.place_special(
		1, Harness.probe_peg(preload("res://tests/sim/support/area_probe_effect.gd"))
	)
	Harness.shoot(game)
	game.score_hit(1)
	var scored: Array[int] = []
	for event: SimEvent in Harness.events_of(game, SimEvent.Kind.SCORE_POINTS):
		scored.append(event.target)
	# The probe peg scores first; its blast then reaches both neighbours 40 px away.
	assert_array(scored).is_equal([1, 0, 2])
	assert_bool(game.simulation.pegs[0].lit).is_true()
	assert_array(Harness.events_of(game, SimEvent.Kind.AREA_HIT)).has_size(1)


func test_fire_hits_the_nearest_pegs_after_its_delay() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(1)
	game.burn_neighbours(1, 2, 50 * PX, 10)
	assert_bool(game.is_burning(0)).is_true()
	assert_bool(game.is_burning(2)).is_true()
	assert_bool(game.is_burning(3)).is_false()
	for i: int in 9:
		game.step()
	assert_int(game.shot_pegs_hit).is_equal(1)
	game.step()
	assert_int(game.shot_pegs_hit).is_equal(3)
	assert_bool(game.is_burning(0)).is_false()


func test_pending_fire_lands_before_the_shot_is_scored() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(1)
	game.burn_neighbours(1, 1, 50 * PX, 100_000)
	Harness.finish(game)
	assert_int(game.total).is_equal(20)
	assert_bool(game.simulation.pegs[0].removed).is_true()


func test_split_balls_fan_out_from_the_parent() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.shoot(game)
	game.step()
	var parent: SimBall = game.launched_ball()
	game.split_ball(game.simulation.launched_ball, 3, 1500)
	var active: Array[SimBall] = []
	for ball: SimBall in game.simulation.balls:
		if ball.active:
			active.append(ball)
	assert_array(active).has_size(3)
	assert_int(active[1].vx).is_equal(-active[2].vx)
	assert_int(active[1].x).is_equal(parent.x)
	assert_array(Harness.events_of(game, SimEvent.Kind.BALL_SPLIT)).has_size(2)


func test_caught_balls_return_to_the_bag_and_kept_balls_go_on_top() -> void:
	var balls: Array[BallDefinition] = []
	for i: int in 5:
		balls.append(Harness.probe_ball())
	var game: BoardGame = Harness.board(Harness.ROW, Harness.loadout(balls))
	Harness.shoot(game)
	var kept: BagBall = game.shot_ball
	game.keep_ball_on_top()
	Harness.finish(game)
	assert_object(game.bag.peek(0)).is_same(kept)
	assert_int(game.bag.size()).is_equal(5)


func test_purchased_pegs_replace_blue_lanterns() -> void:
	var settings: BalanceConfig = Harness.config()
	var game: BoardGame = Harness.board(Harness.ROW, Harness.loadout([], [], [Harness.probe_peg()]))
	var special: int = 0
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.SPECIAL:
			special += 1
			assert_str(game.definition_of(peg).id).is_equal("probe_peg")
	assert_int(special).is_equal(1)
	assert_int(settings.shots_per_board).is_equal(game.shots_left)


func test_next_shot_bonus_starts_the_mult() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	game.next_shot_mult_bonus = 3000
	Harness.shoot(game)
	assert_int(game.shot_mult).is_equal(4000)
	assert_int(game.next_shot_mult_bonus).is_equal(0)


func test_board_end_reports_result_to_effects() -> void:
	var settings: BalanceConfig = Harness.config()
	settings.shots_per_board = 1
	var game: BoardGame = Harness.board(
		Harness.ROW, Harness.loadout([], [Harness.probe_omamori()]), settings
	)
	Harness.shoot(game)
	game.add_mon(3, 0, 0)
	Harness.finish(game)
	assert_object(game.result).is_not_null()
	assert_int(game.result.mon_earned).is_equal(3)
	assert_int(game.result.interest_cap).is_equal(settings.interest_cap)
	assert_array(Probe.journal).contains(["0:board_end"])


func test_character_and_boss_hooks_run_between_the_peg_and_omamori() -> void:
	var loadout: LoadoutDefinition = Harness.loadout(
		[Harness.probe_ball()], [Harness.probe_omamori()]
	)
	loadout.character = Harness.probe_character()
	var rules: BoardRules = BoardRules.new(0, 0, Harness.probe_boss())
	var game: BoardGame = Harness.board(Harness.ROW, loadout, null, Harness.SEED, rules)
	game.place_special(0, Harness.probe_peg())
	assert_array(Probe.journal).is_equal(
		["-1:board_start", "-3:board_start", "-4:board_start", "0:board_start"]
	)
	Probe.journal.clear()
	Harness.shoot(game)
	game.score_hit(0)
	assert_array(Probe.journal).is_equal(
		[
			"-1:shot_start",
			"-3:shot_start",
			"-4:shot_start",
			"0:shot_start",
			"-1:peg_hit",
			"-2:peg_hit",
			"-3:peg_hit",
			"-4:peg_hit",
			"0:peg_hit"
		]
	)


func test_the_power_acts_when_a_green_lantern_scores() -> void:
	var loadout: LoadoutDefinition = Harness.loadout()
	loadout.character = Harness.probe_character()
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	Harness.all_blue(game)
	game.roles[1] = BoardGame.Role.GREEN
	Harness.shoot(game)
	Probe.journal.clear()
	game.score_hit(0)
	assert_array(Probe.journal).is_equal(["-3:peg_hit"])
	game.score_hit(1)
	assert_array(Probe.journal).is_equal(["-3:peg_hit", "-3:peg_hit", "-3:power"])
	assert_int(game.shot_points).is_equal(20)


func test_shot_scored_runs_only_while_the_board_goes_on() -> void:
	var loadout: LoadoutDefinition = Harness.loadout()
	loadout.character = Harness.probe_character()
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	Harness.shoot(game)
	Harness.finish(game)
	assert_array(Probe.journal).contains(["-3:shot_scored"])
	Probe.journal.clear()
	var last: BoardGame = Harness.board(
		Harness.ROW, loadout, null, Harness.SEED, BoardRules.new(0, -7)
	)
	Probe.journal.clear()
	Harness.shoot(last)
	Harness.finish(last)
	assert_int(last.outcome).is_equal(BoardGame.Outcome.FAILED)
	assert_array(Probe.journal).not_contains(["-3:shot_scored"])
	assert_array(Probe.journal).contains(["-3:board_end"])
