extends GdUnitTestSuite
## Illusions and layout layers: board actions that boss rules are built on.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const Probe: GDScript = preload("res://tests/sim/support/probe_effect.gd")
const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const TestLayouts: GDScript = preload("res://tests/run/support/test_layouts.gd")
const PX: int = FixedMath.PX
## Pegs of the sample layout; the second layer follows them.
const FIRST_LAYER: int = 9
const SECOND_LAYER: int = 12


func before_test() -> void:
	Probe.journal.clear()


func test_illusions_are_drawn_from_unlit_blue_lanterns() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	game.roles[1] = BoardGame.Role.GREEN
	Harness.shoot(game)
	game.score_hit(0)
	assert_int(game.scatter_illusions(10)).is_equal(3)
	for peg: int in game.roles.size():
		assert_bool(game.simulation.pegs[peg].illusion).is_equal(peg in [2, 3, 4])


func test_scattering_again_replaces_the_previous_illusions() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	for attempt: int in 5:
		game.scatter_illusions(1)
		var illusions: int = 0
		for peg: SimPeg in game.simulation.pegs:
			illusions += 1 if peg.illusion else 0
		assert_int(illusions).is_equal(1)


func test_a_touched_illusion_vanishes_without_scoring_or_effects() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.loadout([], [Harness.probe_omamori()]))
	Harness.all_blue(game)
	Harness.shoot(game)
	Probe.journal.clear()
	game.simulation.pegs[2].illusion = true
	game.score_hit(2)
	assert_int(game.shot_points).is_equal(0)
	assert_int(game.shot_pegs_hit).is_equal(0)
	assert_array(Probe.journal).is_empty()
	assert_bool(game.simulation.pegs[2].removed).is_true()
	assert_bool(game.simulation.pegs[2].illusion).is_false()
	assert_array(Harness.events_of(game, SimEvent.Kind.PEG_VANISHED)).has_size(1)


func test_explosions_make_illusions_vanish_too() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	Harness.shoot(game)
	game.simulation.pegs[1].illusion = true
	game.hit_pegs_near(80 * PX, 200 * PX, 40 * PX, PegHit.Source.AREA)
	assert_int(game.shot_points).is_equal(20)
	assert_bool(game.simulation.pegs[1].removed).is_true()


func test_a_second_layer_waits_out_of_play() -> void:
	var game: BoardGame = _layered().game
	assert_int(game.pegs_in_play()).is_equal(FIRST_LAYER)
	var reds: int = 0
	for peg: int in range(FIRST_LAYER, FIRST_LAYER + SECOND_LAYER):
		assert_int(game.simulation.pegs[peg].layer).is_equal(1)
		assert_bool(game.simulation.pegs[peg].removed).is_true()
		assert_int(game.roles[peg]).is_equal(BoardGame.Role.BLUE)
	for peg: int in FIRST_LAYER:
		reds += 1 if game.roles[peg] == BoardGame.Role.RED else 0
	# 22% of the nine pegs in play.
	assert_int(reds).is_equal(2)


func test_switching_layer_brings_new_pegs_coloured_like_a_new_board() -> void:
	var game: BoardGame = _layered().game
	game.switch_layer(1)
	var counts: Dictionary[int, int] = {}
	for peg: int in game.roles.size():
		var in_play: bool = not game.simulation.pegs[peg].removed
		assert_bool(in_play).is_equal(peg >= FIRST_LAYER)
		if in_play:
			counts[game.roles[peg]] = counts.get(game.roles[peg], 0) + 1
	# 22% of twelve rounds to three reds; two greens, one gold, one purchased peg, five blues.
	assert_int(counts.get(BoardGame.Role.RED, 0)).is_equal(3)
	assert_int(counts.get(BoardGame.Role.GREEN, 0)).is_equal(2)
	assert_int(counts.get(BoardGame.Role.GOLD, 0)).is_equal(1)
	assert_int(counts.get(BoardGame.Role.SPECIAL, 0)).is_equal(1)
	assert_int(game.red_remaining()).is_equal(3)
	var changed: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.LAYOUT_CHANGED)
	assert_array(changed).has_size(1)
	assert_int(changed[0].amount).is_equal(1)


func _layered() -> PlacedBoard:
	return BoardSetup.create_board(
		TestBoards.gdd_config(),
		TestBoards.gdd_pegs(),
		TestLayouts.sample(),
		3,
		Harness.loadout([], [], [Harness.probe_peg()]),
		null,
		null,
		TestLayouts.second_layer()
	)
