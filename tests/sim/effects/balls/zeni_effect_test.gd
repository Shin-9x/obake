extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const ZENI: String = "res://data/balls/zeni.tres"


func test_pays_mon_every_few_pegs_in_a_shot() -> void:
	var definition: BallDefinition = load(ZENI)
	var every: int = definition.level_values[0]
	var row: Array[Vector2i] = []
	for index: int in every + 2:
		row.append(Vector2i(20 + index * 12 + (60 if index >= 12 else 0), 300))
	var game: BoardGame = Harness.board(row, Harness.with_ball(ZENI))
	Harness.shoot(game)
	for peg: int in every - 1:
		game.score_hit(peg)
	assert_int(game.mon_earned).is_equal(0)
	game.score_hit(every - 1)
	assert_int(game.mon_earned).is_equal(definition.params[&"mon"])


func test_counting_restarts_every_shot() -> void:
	var definition: BallDefinition = load(ZENI)
	var every: int = definition.level_values[0]
	var row: Array[Vector2i] = []
	for index: int in 2 * every:
		row.append(Vector2i(10 + index * 8 + (40 if index >= 20 else 0), 300))
	var game: BoardGame = Harness.board(row, Harness.with_ball(ZENI))
	Harness.shoot(game)
	for peg: int in every - 1:
		game.score_hit(peg)
	Harness.finish(game)
	Harness.shoot(game)
	game.score_hit(every)
	assert_int(game.mon_earned).is_equal(0)
