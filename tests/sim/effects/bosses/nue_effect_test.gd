extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const TestLayouts: GDScript = preload("res://tests/run/support/test_layouts.gd")
const NUE: String = "res://data/bosses/nue.tres"
const TARGET: int = 10_000
## Pegs of the sample layout; the second form follows them.
const FIRST_FORM: int = 9


func test_the_board_transforms_once_half_the_target_is_reached() -> void:
	var game: BoardGame = _game()
	game.total = TARGET / 2
	Harness.shoot(game)
	Harness.finish(game)
	assert_int(game.outcome).is_equal(BoardGame.Outcome.PLAYING)
	assert_array(Harness.events_of(game, SimEvent.Kind.LAYOUT_CHANGED)).has_size(1)
	for peg: int in game.roles.size():
		assert_bool(game.simulation.pegs[peg].removed).is_equal(peg < FIRST_FORM)
	game.events.clear()
	Harness.shoot(game)
	Harness.finish(game)
	assert_array(Harness.events_of(game, SimEvent.Kind.LAYOUT_CHANGED)).is_empty()


func test_the_board_keeps_its_first_form_below_half_the_target() -> void:
	var game: BoardGame = _game()
	Harness.shoot(game)
	Harness.finish(game)
	assert_int(game.total).is_less(TARGET / 2)
	assert_array(Harness.events_of(game, SimEvent.Kind.LAYOUT_CHANGED)).is_empty()
	assert_int(game.pegs_in_play()).is_less_equal(FIRST_FORM)


## Coloured like a real board, so the first form has red lanterns and no early Matsuri.
func _game() -> BoardGame:
	var config: BalanceConfig = TestBoards.gdd_config()
	TestBoards.freeze_bucket(config)
	return (
		BoardSetup
		. create_board(
			config,
			TestBoards.gdd_pegs(),
			TestLayouts.sample(),
			Harness.SEED,
			null,
			null,
			BoardRules.new(TARGET, 0, load(NUE)),
			TestLayouts.second_layer()
		)
		. game
	)
