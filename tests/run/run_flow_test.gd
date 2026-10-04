extends GdUnitTestSuite
## Whole runs played by the test bot with real boards: from the character to the last boss, to
## a lost board, and a golden first floor that locks maps, shops, rewards and boards together.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const RunBot: GDScript = preload("res://tests/run/support/run_bot.gd")
const AIM_SEED: int = 31
## Mon, boards played and hash chain after the bot plays the first floor, boss included. Its
## random aim cannot keep up with the real targets, so the first target is lowered; everything
## else uses the real numbers. If a deliberate change alters them, update them in the same commit
## and say why.
const GOLDEN_FIRST_TARGET: int = 150
const GOLDEN_FLOOR_MON: int = 57
const GOLDEN_FLOOR_BOARDS: int = 4
const GOLDEN_FLOOR_CHAIN: int = 971667653


func test_a_run_plays_from_the_start_to_victory() -> void:
	var config: BalanceConfig = Fixtures.config()
	config.first_board_target = 1
	config.target_rounding = 1
	for character: CharacterDefinition in Fixtures.content().characters:
		var bot: RefCounted = RunBot.new(_run(config, character), AIM_SEED)
		bot.play()
		var run: Run = bot.run
		assert_int(run.phase).override_failure_message(String(character.id)).is_equal(
			Run.Phase.VICTORY
		)
		assert_int(run.state.floor_index).is_equal(config.floors - 1)
		assert_int(run.state.boards_won).is_equal(run.state.boards_played)
		assert_int(run.state.boards_played).is_greater_equal(2 * config.floors)


func test_a_lost_board_ends_the_run() -> void:
	var config: BalanceConfig = Fixtures.config()
	config.first_board_target = 1_000_000_000
	var bot: RefCounted = RunBot.new(_run(config, Fixtures.character()), AIM_SEED)
	bot.play()
	assert_int(bot.run.phase).is_equal(Run.Phase.DEFEAT)
	assert_int(bot.run.state.boards_played).is_equal(1)


func test_the_first_floor_matches_its_golden_result() -> void:
	var config: BalanceConfig = Fixtures.config()
	config.first_board_target = GOLDEN_FIRST_TARGET
	var bot: RefCounted = RunBot.new(_run(config, Fixtures.character()), AIM_SEED)
	bot.play(1)
	var run: Run = bot.run
	assert_int(run.phase).is_equal(Run.Phase.MAP)
	assert_int(run.state.floor_index).is_equal(1)
	assert_int(run.state.mon).is_equal(GOLDEN_FLOOR_MON)
	assert_int(run.state.boards_played).is_equal(GOLDEN_FLOOR_BOARDS)
	assert_int(bot.chain).is_equal(GOLDEN_FLOOR_CHAIN)


func _run(config: BalanceConfig, character: CharacterDefinition) -> Run:
	return Run.start(
		config,
		Fixtures.content(),
		LayoutLibrary.load_from(),
		Fixtures.base_pegs(),
		character,
		Fixtures.SEED
	)
