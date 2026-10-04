extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const SHUTEN: String = "res://data/bosses/shuten_doji.tres"
const PX: int = FixedMath.PX


func test_oni_replace_blue_lanterns_at_the_start() -> void:
	var config: BalanceConfig = TestBoards.gdd_config()
	var simulation: BoardSimulation = BoardSimulation.new(config)
	TestBoards.add_staggered_pegs(simulation)
	var boss: BossDefinition = load(SHUTEN)
	var game: BoardGame = BoardGame.new(
		simulation,
		config,
		TestBoards.gdd_pegs(),
		Pcg32.new(Harness.SEED, RngStreams.Domain.BOARD),
		null,
		null,
		BoardRules.new(0, 0, boss)
	)
	assert_int(_oni(game).size()).is_equal(boss.params[&"oni"])
	assert_int(game.mult_floor).is_equal(1000)


func test_each_oni_takes_mult_away_but_never_below_one() -> void:
	var game: BoardGame = Harness.boss_board(SHUTEN, _row(12))
	var oni: Array[int] = _oni(game)
	Harness.shoot(game)
	game.score_hit(oni[0])
	assert_int(game.shot_mult).is_equal(1000)
	game.add_mult(2000, 0, 0)
	game.score_hit(oni[1])
	assert_int(game.shot_mult).is_equal(2000)


func test_three_oni_in_one_shot_halve_its_points() -> void:
	for hits: int in [2, 3]:
		var game: BoardGame = Harness.boss_board(SHUTEN, _row(12))
		var oni: Array[int] = _oni(game)
		Harness.shoot(game)
		game.add_points(40, 0, 0)
		for index: int in hits:
			game.score_hit(oni[index])
		Harness.finish(game)
		assert_int(game.total).is_equal(40 if hits == 2 else 20)


func _oni(game: BoardGame) -> Array[int]:
	var found: Array[int] = []
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.SPECIAL and game.definition_of(peg).id == &"oni":
			found.append(peg)
	return found


## [param count] pegs in two rows, away from the straight drop.
func _row(count: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for index: int in count:
		var column: int = index % 6
		positions.append(Vector2i(30 + column * 25, 150 + (index / 6) * 40))
	return positions
